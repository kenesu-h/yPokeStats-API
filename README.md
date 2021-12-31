# yPokeStats-API
From yPokeStats: "yPokeStats is a LUA script that can display a lot of
information about Pokemon games".

yPokeStats-API is meant to make this information available to applications 
outside of Lua-compatible emulators. In the process, it also allows
applications to automate emulator inputs in a more accessible way.

# Why
This is mainly a project for fun, but it was also developed with the intent of
enabling the remote play of DS games - although mainly Pokemon games.

I also kinda wanted an excuse to practice React and web app development.

# How
The API builds upon a modified yPokeStats by exposing the available data using a
TCP stream. JSON is used in the rudimentary protocol developed for communication
on this stream.

First, I had to modify yPokeStats' data tables since it wouldn't recognize my
Black and White 2 region. Its other scripts were reformatted too since the
original formatting was... very rough, to say the least. I believe I edited one
of the files to fix a crash, though I don't remember which file that was - the
Git log will probably tell you. A lot of data is still missing - specifically
for Gen 5 moves and abilities - but this fork of yPokeStats should still
function like the original. Probably not for Gen 3 and prior though.

TCP and raw socket capabilities were introduced by forcibly loading a
[LuaSocket](https://github.com/diegonehab/luasocket) dll
[compiled by Paul Kulchenko](https://github.com/pkulchenko/ZeroBraneStudio/issues/816),
the main developer of ZeroBrane Studio. There's probably a simpler way to do
this, but I was kinda frustrated by the fact that emulators dynamically loaded
Lua, again through a dll - this meant to me that I had to load libraries by
directly loading a Lua script or dll. LuaSocket had no Lua script, so I needed a
dll that was compiled in a 64-bit environment. Luckily, Paul came in clutch.

JSON was parsed and encoded using [json.lua](https://github.com/rxi/json.lua),
which has a loadable Lua script. However, it had to be modified to account for
the fact that yPokeStats stored Pokemon game data in a variable called "table",
which json.lua happens to use because it uses Lua's built-in table library. As a
band-aid solution, I had to modify json.lua to reference Lua's table library as
"table\_lib".

# Usage
1. Clone the repo.
2. Grab Kulchenko's compiled LuaSocket dll and put it in the root of the repo
   (where ylingstats.lua is).
3. With your Lua-compatible emulator, launch the script while running Pokemon.
  - This step assumes that you've setup your emulator for Lua. This usually
    entails lua51.dll being in the same folder as your emulator's executable.

# Examples
A working example of a web app communicating with the API can be found in
`app-example`. It's very rough, but it's able to show a live preview of your
current party. It also has some buttons for remote control. I honestly can't see
myself finishing and polishing it. At minimum, it should be a basic example of
what can be done using the API.

The example uses Rust for the backend and TypeScript + React for the frontend,
so you'll need to install Rust and Node.js respectively in order to run the
whole web app. I'd write directions, but I'm currently pretty cooked.

# Can I contribute and/or fork this?
Yeah, of course. All of this work is unpolished, undocumented, and quite rushed
compared to my usual projects anyway. I just hope this is a good enough
foundation to build something major.
