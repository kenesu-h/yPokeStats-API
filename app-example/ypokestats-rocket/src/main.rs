use std::{
    io::{Write, BufRead, BufReader, BufWriter},
    net::TcpStream,
    str,
    sync::Mutex
};
use rocket::{
    Request, Response, State,
    fairing::{Fairing, Info, Kind},
    http::Header
};

#[macro_use] extern crate rocket;

// https://stackoverflow.com/a/64904947 for CORS fairing implementation.
pub struct CORS;

#[rocket::async_trait]
impl Fairing for CORS {
    fn info(&self) -> Info {
        Info {
            name: "Add CORS headers to responses",
            kind: Kind::Response
        }
    }

    // It's excessive to allow all these methods but we can always change them.
    async fn on_response<'r>(&self, _: &'r Request<'_>, response: &mut Response<'r>) {
        response.set_header(Header::new("Access-Control-Allow-Origin", "*"));
        response.set_header(Header::new("Access-Control-Allow-Methods", "POST, GET, PATCH, OPTIONS"));
        response.set_header(Header::new("Access-Control-Allow-Headers", "*"));
        response.set_header(Header::new("Access-Control-Allow-Credentials", "true"));
    }
}

// A sort of container for TCP stream IO and a buffer for all data read.
// We need this so that Rocket can easily manage all three in a thread-safe way.
struct AppData {
    reader: Mutex<BufReader<TcpStream>>,
    writer: Mutex<BufWriter<TcpStream>>,
    buffer: Mutex<String>
}

// Really long-winded code for TCP stream IO.
// I'm sure this could be neater and more functional, but it does the job.
fn send_stream(app_data: &State<AppData>, msg: String) -> Result<(), String> {
    return match app_data.writer.lock() {
        Err(e) => Err(format!("Failed to lock writer: {}", e)),
        Ok(mut lock) => {
            match lock.write(msg.as_bytes()) {
                Err(e) => Err(format!("Failed to write to writer: {}", e)),
                Ok(_) => match lock.flush() {
                    Err(_) => Err(String::from("Failed to flush writer.")),
                    Ok(_) => Ok(())
                }
            }
        }
    }
}

fn recv_stream(app_data: &State<AppData>) -> Result<String, String> {
    return match app_data.reader.lock() {
        Err(e) => Err(format!("Failed to lock reader: {}", e)),
        Ok(mut reader_lock) => {
            match app_data.buffer.lock() {
                Err(e) => Err(format!("Failed to lock buffer: {}", e)),
                Ok(mut buffer_lock) => {
                    while !buffer_lock.contains("\r\n") {
                        match reader_lock.read_line(&mut buffer_lock) {
                            Err(_) => break,
                            Ok(n) => {
                                if n == 0 { break }
                            }
                        }
                    }
                    let buffer_lock_clone: String = buffer_lock.clone();
                    let partitions: Vec<&str> = buffer_lock_clone
                        .split("\r\n")
                        .collect();
                    buffer_lock.clear();
                    if partitions.len() > 1 {
                        buffer_lock.push_str(&partitions[1..].join("\r\n"))
                    }
                    return Ok(String::from(partitions[0]))
                }
            } 
        }
    }
}

#[get("/team")]
fn team(app_data: &State<AppData>) -> String {
    return match send_stream(
        app_data,
        String::from("{\"method\": \"header\", \"args\": [\"1\"]}\r\n")
    ) {
        Err(e) => e,
        Ok(_) => match send_stream(
            app_data, String::from("{\"method\": \"team\"}\r\n")
        ) {
            Err(e) => e,
            Ok(_) => match recv_stream(app_data) {
                Err(e) => e,
                Ok(o) => o
            }
        }
    }
}

#[get("/press/<button>")]
fn press(button: &str, app_data: &State<AppData>) -> String {
    return match send_stream(
        app_data,
        String::from("{\"method\": \"header\", \"args\": [\"1\"]}\r\n")
    ) {
        Err(e) => e,
        Ok(_) => match send_stream(
            app_data,
            format!("{{\"method\": \"press\", \"args\": [\"{}\"]}}\r\n", button)
        ) {
            Err(e) => e,
            Ok(_) => match recv_stream(app_data) {
                Err(e) => e,
                Ok(o) => o
            }
        }
    }
}

#[get("/release/<button>")]
fn release(button: &str, app_data: &State<AppData>) -> String {
    return match send_stream(
        app_data,
        String::from("{\"method\": \"header\", \"args\": [\"1\"]}\r\n")
    ) {
        Err(e) => e,
        Ok(_) => match send_stream(
            app_data,
            format!(
                "{{\"method\": \"release\", \"args\": [\"{}\"]}}\r\n",
                button
            )
        ) {
            Err(e) => e,
            Ok(_) => match recv_stream(app_data) {
                Err(e) => e,
                Ok(o) => o
            }
        }
    }
}

#[launch]
fn rocket() -> _ {
    let stream: TcpStream = match TcpStream::connect("127.0.0.1:50404") {
        Err(e) => panic!("TCP stream failed to connect: {}", e),
        Ok(stream) => stream
    };

    // Apparently you can clone TCP streams.
    let stream_clone: TcpStream = match stream.try_clone() {
        Err(_) => panic!("Unable to create a clone for the TCP stream."),
        Ok(stream) => stream
    };

    rocket::build()
        .mount("/api", routes![team, press, release])
        .manage(
            AppData {
                reader: Mutex::new(BufReader::new(stream)),
                writer: Mutex::new(BufWriter::new(stream_clone)),
                buffer: Mutex::new(String::new())
            }
        )
        .attach(CORS)
}
