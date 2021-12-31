-- yPokeStats 
-- by YliNG
-- v0.1
-- https://github.com/yling

dofile "data/tables.lua" -- Tables with games data, and various data - including names
dofile "data/memory.lua" -- Functions and Pokemon table generation
local json = require "json"
require "struct.option"
require "struct.result"
require "struct.pokemon"

local gamedata = getGameInfo() -- Gets game info
version, lan, gen, sel = gamedata[1],gamedata[2],gamedata[3],gamedata[4]

settings={}
settings["pos"]={} -- Fixed blocks coordinates {x,y}{x,y}
settings["pos"][1]={2,2}
settings["pos"][2]={10,sel[2]/6}
settings["pos"][3]={2,sel[2]/64*61}
settings["key"]={	"J", -- Switch mode (EV,IV,Stats)
                    "K", -- Switch status (Enemy / player)
                    "L",  -- Sub Status + (Pokemon Slot)
                    "M", -- Toggle + display
                    "H" } -- Toggle help


print("Welcome to yPokeStats Unified ")

print("Attempting to get games[", version, "][", lan, "]:", games[version][lan])

local string = require("string")
local table_lib = require("table")
local bit = require("bit")
local socket = package.loadlib("./socket.dll", "luaopen_socket_core")()
local clients = {}
local buffer = ""

--[[
-- Attempts to bind a socket to localhost:50404.
--
-- Returns:
-- The result of the binding, where:
-- - An Ok holds the newly bound socket.
-- - An Err holds the resulting error message.
--]]
local function try_bind_sock()
  local sock = socket.tcp()
  local status, e = sock:bind("127.0.0.1", "50404")
  -- http://lua-users.org/lists/lua-l/2011-08/msg00216.html
  if status ~= nil then
    sock:settimeout(0)
    sock:listen()
    return Ok(sock)
  else
    return Err(e)
  end
end

--[[
-- Returns:
-- The result of the binding if try_bind_sock() successfully did so.
--
-- Errors:
-- If the binding was unsuccessful.
--]]
local function init_sock()
  local bind_result = try_bind_sock()
  if bind_result.is_ok then
    return bind_result.val
  else
    error(bind_result.val)
  end
end

local connection = init_sock()
local ip, port = connection:getsockname()
print("Socket opened at "..ip..":"..port)

--[[
-- Receives data sent by a client and stores it into a buffer.
--
-- Argument:
-- client: tcp{client}, the client whose connection is accepted
--
-- Returns:
-- The buffered data.
--]]
-- https://stackoverflow.com/questions/154672/what-can-i-do-to-increase-the-performance-of-a-lua-program
local function recv_all(client)
  local buffered = {}
  local full, _, partial = client:receive("*a")
  while true do
    if full == nil then
      if partial == "" then
        break
      else
        table_lib.insert(buffered, partial)
      end
    else
      table_lib.insert(buffered, full)
    end
  end
  return buffered
end

local function decode_all(client, buffered)
  local decoded = {}
  for i = 1, #buffered, 1 do
    local current = {}
    if pcall(function () current = json.decode(buffered[i]) end) then
      table_lib.insert(decoded, current)
    else
      client:send(
        json.encode(Err("A message could not be decoded to JSON."))
      )
    end
  end
  return decoded
end

-- https://stackoverflow.com/questions/1426954/split-string-in-lua
local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table_lib.insert(t, str)
  end
  return t
end

-- https://stackoverflow.com/questions/11152220/counting-number-of-string-occurrences
local function count(base, pattern)
  return select(2, string.gsub(base, pattern, ""))
end

local function get_team()
  local team = {}
  for i = 1, 6, 1 do
    substatus[1] = i
    start = games[version][lan][2]+games[version][lan][4]*(substatus[1]-1)
    pokemon = fetchPokemon(start)
    helditem = pokemon["helditem"] == 0 and "none" or table["items"][gen][pokemon["helditem"]]
    -- Fetching held item name (if there's one)
    pokerus = pokemon["pokerus"] == 0 and "no" or "yes" -- Jolly little yes or no for Pokerus
    ability = gen == 3 and table["gen3ability"][pokemon["species"]][pokemon["ability"]+1] or pokemon["ability"] -- Fetching proper ability id for Gen 3

    local ivs = StatSet:new(
      pokemon[table["modesorder"][1]][1],
      pokemon[table["modesorder"][1]][2],
      pokemon[table["modesorder"][1]][3],
      pokemon[table["modesorder"][1]][4],
      pokemon[table["modesorder"][1]][5],
      pokemon[table["modesorder"][1]][6]
    )
    local evs = StatSet:new(
      pokemon[table["modesorder"][2]][1],
      pokemon[table["modesorder"][2]][2],
      pokemon[table["modesorder"][2]][3],
      pokemon[table["modesorder"][2]][4],
      pokemon[table["modesorder"][2]][5],
      pokemon[table["modesorder"][2]][6]
    )
    local stats = StatSet:new(
      pokemon[table["modesorder"][3]][1],
      pokemon[table["modesorder"][3]][2],
      pokemon[table["modesorder"][3]][3],
      pokemon[table["modesorder"][3]][4],
      pokemon[table["modesorder"][3]][5],
      pokemon[table["modesorder"][3]][6]
    )

    local moves = {}
    for j = 1, 4, 1 do -- For each move
      if table["move"][pokemon["move"][j]] ~= nil then
        table_lib.insert(
          moves,
          table["move"][pokemon["move"][j]].." - "..pokemon["pp"][j].."PP"
        )
      end
    end

    local pokestruct = Pokemon:new(
      pokemon["species"],
      pokemon["speciesname"],
      pokemon["OTTID"],
      pokemon["OTSID"],
      pokemon["xp"],
      helditem,
      pokerus,
      pokemon["friendship"],
      table["ability"][ability],
      -- table["nature"][pokemon["nature"]],
      moves,
      ivs,
      evs,
      stats,
      pokemon["hp"]["current"]
    )
    table_lib.insert(team, pokestruct)
  end
  return team
end

ApiButtons = {
  R = false,
  L = false,
  X = false,
  Y = false,
  A = false,
  B = false,
  start = false,
  select = false,
  up = false,
  down = false,
  left = false,
  right = false
}

local function boolean_to_number(boolean)
  return boolean == true and 1 or 0
end

local function apply_api_buttons()
  for button, pressed in pairs(ApiButtons) do
    local button_table = {}
    button_table[button] = 1
    if pressed then joypad.set(1, button_table) end
  end
end

local function parse_message(client, message)
  if message["method"] == "team" then
    client:send(json.encode(Ok(get_team())).."\r\n")
  elseif message["method"] == "press" then
    if message["args"] == nil then
      client:send(
        json.encode(Err("Message must have a \"args\" field.")).."\r\n"
      )
    else
      if #message["args"] <= 0 then
        client:send(
          json.encode(
            Err(
              "Args must be an array with a length of greater than 0."
            )
          ).."\r\n"
        )
      else
        if ApiButtons[message["args"][1]] == nil then
          client:send(
            json.encode(
              "An invalid button name was given for the first argument."
            ).."\r\n"
          )
        else
          ApiButtons[message["args"][1]] = true
          client:send(json.encode(Ok("Pressing "..message["args"][1])).."\r\n")
        end
      end
    end
  elseif message["method"] == "release" then
    if message["args"] == nil then
      client:send(
        json.encode(Err("Message must have a \"args\" field.")).."\r\n"
      )
    else
      if #message["args"] <= 0 then
        client:send(
          json.encode(
            Err(
              "Args must be an array with a length of greater than 0."
            )
          ).."\r\n"
        )
      else
        if ApiButtons[message["args"][1]] == nil then
          client:send(
            json.encode(
              Err("An invalid button name was given for the first argument.")
            ).."\r\n"
          )
        else
          ApiButtons[message["args"][1]] = false
          client:send(json.encode(Ok("Released "..message["args"][1])).."\r\n")
        end
      end
    end
  else
    if message["method"] == nil then
      client:send(
        json.encode(Err("Message must have a \"method\" field.")).."\r\n"
      )
    else
      client:send(
        json.encode(
          Err("Invalid method \""..message["method"].."\" given.")
        ).."\r\n"
      )
    end
  end
end

if version ~= 0 and games[version][lan] ~= nil then
  print("Game :", games[version][lan][1])

	status, mode, help = 1, 1, 1 -- Default status and substatus - 1,1,1 is Player's first Pokémon
	substatus={1,1,1}
	lastpid,lastchecksum=0,0 -- Will be useful to avoid re-loading the same pokemon over and over again
	count,clockcount,totalclocktime,lastclocktime,highestclocktime,yling=0,0,0,0,0,0 -- Monitoring - useless

  local prev={} -- Preparing the input tables - allows to check if a key has been pressed
  prev = input.get()

  function Main() -- Main function - display (check memory.lua for calculations) 
    local nClock = os.clock() -- Set the clock (for performance monitoring -- useless)
    statusChange(input.get()) -- Check for key input and changes status

		if help==1 then -- Help screen display
			gui.box(settings["pos"][2][1]-5,settings["pos"][2][2]-5,sel[1]-5,settings["pos"][2][2]+sel[2]/2,"#ffffcc","#ffcc33")
			gui.text(settings["pos"][2][1],settings["pos"][2][2],"yPokemonStats","#ee82ee")
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16,"http://github.com/yling","#87cefa")
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*2,"-+-+-+-+-","#ffcc33")
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*3,settings["key"][1]..": IVs, EVs, Stats and Contest stats",table["colors"][5])
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*4,settings["key"][2]..": Player team / Enemy team",table["colors"][4])
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*5,settings["key"][3]..": Pokemon slot (1-6)",table["colors"][3])
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*6,settings["key"][4]..": Show more data",table["colors"][2])
			gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*7,settings["key"][5]..": Toggle this menu",table["colors"][1])
    end

    local start = status==1 and games[version][lan][2]+games[version][lan][4]*(substatus[1]-1) or games[version][lan][3]+games[version][lan][4]*(substatus[2]-1) -- Set the pokemon start adress

	  if memory.readdwordunsigned(start) ~= 0 or memory.readbyteunsigned(start) ~= 0 then -- If there's a PID
	    if checkLast(lastpid,lastchecksum,start,gen) == 0 or pokemon["species"] == nil then
        -- If it's not the last loaded PID (cause you know) or if the pokemon data is empty
        pokemon = fetchPokemon(start) -- Fetch pokemon data at adress start
        count=count+1 -- Times data has been fetched from memory (for monitoring - useless)
        lastpid = gen >= 3 and pokemon["pid"] or pokemon["species"] -- Update last loaded PID
        lastchecksum = gen >= 3 and pokemon["checksum"] or pokemon["ivs"]
      end

      -- Permanent display --
      local labels = mode == 4 and table["contests"] or table["labels"] -- Load contests labels or stats labels
      local tmpcolor = status == 1 and "green" or "red" -- Dirty tmp var for status and substatus color for player of enemy
      local tmpletter = status == 1 and "P" or "E" -- Dirty tmp var for status and substatus letter for player of enemy
      local tmptext = tmpletter..substatus[1].." ("..table["modes"][mode]..")" -- Dirty tmp var for current mode
      helditem = pokemon["helditem"] == 0 and "none" or table["items"][gen][pokemon["helditem"]]

      -- GEN 1 & 2
      if gen <= 2 then
        for i=1,5 do -- For each DV
          gui.text(settings["pos"][1][1]+(i-1)*sel[1]/5,settings["pos"][1][2],table["gen1labels"][i], table["colors"][i]) -- Display label
          gui.text(settings["pos"][1][1]+sel[1]/5/4+(i-1)*sel[1]/5,settings["pos"][1][2], pokemon[table["modesorder"][mode]][i], table["colors"][i])
          gui.text(settings["pos"][1][1]+sel[1]*4/10,settings["pos"][3][2], tmptext, tmpcolor) -- Display current status (using previously defined dirty temp vars)
          local shiny = pokemon["shiny"] == 1 and "Shiny" or "Not shiny"
          local shinycolor = pokemon["shiny"] == 1 and "green" or "red"
          gui.text(settings["pos"][1][1]+sel[1]*7/10,settings["pos"][3][2],shiny,shinycolor)
        end
      -- GEN 3, 4 and 5
			else
        for i=1,6 do -- For each IV
          gui.text(
            settings["pos"][1][1]+(i+1)*sel[1]/8,settings["pos"][1][2],
            labels[i],
            table["colors"][i]
          ) -- Display label
          gui.text(settings["pos"][1][1]+sel[1]/8/2+(i+1)*sel[1]/8,settings["pos"][1][2], pokemon[table["modesorder"][mode]][i], table["colors"][i]) -- Display current mode stat
          if mode ~= 4 then -- If not in contest mode
            if pokemon["nature"]["inc"]~=pokemon["nature"]["dec"] then -- If nature changes stats
              if i==table["statsorder"][pokemon["nature"]["inc"]+2] then -- If the nature increases current IV
                gui.text(settings["pos"][1][1]+sel[1]/8/2+sel[1]/8*(i+1),settings["pos"][1][2]+3, "__", "green") -- Display a green underline
                elseif i==table["statsorder"][pokemon["nature"]["dec"]+2] then -- If the nature decreases current IV
                gui.text(settings["pos"][1][1]+sel[1]/8/2+sel[1]/8*(i+1),settings["pos"][1][2]+3, "__", "red") -- Display a red underline
              end
            else -- If neutral nature
              if i==table["statsorder"][pokemon["nature"]["inc"]+1] then -- If current IV is HP
                gui.text(settings["pos"][1][1]+sel[1]/8/2+sel[1]/8*(i+1),settings["pos"][1][2]+3, "__", "grey") -- Display grey underline
              end
            end
          end
        end
        gui.text(settings["pos"][1][1],settings["pos"][1][2], tmptext, tmpcolor) -- Display current status (using previously defined dirty temp vars)
        gui.text(settings["pos"][1][1]+sel[1]*4/10,settings["pos"][3][2], "PID: "..bit.tohex(lastpid)) -- Last PID
      end

      -- All gens
      gui.text(settings["pos"][1][1], settings["pos"][1][2]+sel[2]/16, pokemon["species"]..": "..pokemon["speciesname"].." - "..pokemon["hp"]["current"].."/"..pokemon["hp"]["max"], tmpcolor) -- Pkmn National Number, Species name and HP
              frame = version == "POKEMON EMER" and "F. E/R: "..emu.framecount().."/"..memory.readdwordunsigned(0x020249C0) or "F. E: "..emu.framecount()
              gui.text(settings["pos"][3][1],settings["pos"][3][2], frame) -- Emu frame counter
				
      -- "More" menu --
			if more == 1 then
				gui.box(settings["pos"][2][1]-5,settings["pos"][2][2]-5,sel[1]-5,settings["pos"][2][2]+sel[2]/2,"#ffffcc","#ffcc33") -- Cute box 
        -- For gen 3, 4, 5
        if gen >= 3 then 
          local naturen = pokemon["nature"]["nature"] > 16 and pokemon["nature"]["nature"]-16 or pokemon["nature"]["nature"] -- Dirty trick to use types colors for natures
          local naturecolor = table["typecolor"][naturen] -- Loading the tricked color
          gui.text(settings["pos"][2][1],settings["pos"][2][2], "Nature")
          gui.text(settings["pos"][2][1]+sel[2]/4,settings["pos"][2][2],table["nature"][pokemon["nature"]["nature"]+1],naturecolor)
          -- Fetching held item name (if there's one)
          pokerus = pokemon["pokerus"] == 0 and "no" or "yes" -- Jolly little yes or no for Pokerus
          ability = gen == 3 and table["gen3ability"][pokemon["species"]][pokemon["ability"]+1] or pokemon["ability"] -- Fetching proper ability id for Gen 3

          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2], "OT ID : "..pokemon["OTTID"])
          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2]+sel[2]/16, "OT SID : "..pokemon["OTSID"])
          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2]+2*sel[2]/16, "XP : "..pokemon["xp"])
          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2]+3*sel[2]/16, "Item : "..helditem)
          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2]+4*sel[2]/16, "Pokerus : "..pokerus)
          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2]+5*sel[2]/16, "Friendship : "..pokemon["friendship"])
          gui.text(settings["pos"][2][1]+sel[1]/2,settings["pos"][2][2]+6*sel[2]/16, "Ability : "..table["ability"][ability])

        -- For gen 1 & 2
        else
          gui.text(settings["pos"][2][1],settings["pos"][2][2], "TID: "..pokemon["TID"].." / Item: "..helditem)
          if version == "POKEMON YELL" and status == 1 and pokemon["species"] == 25 or gen == 2 then
            gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16*2, "Friendship : "..pokemon["friendship"])
          end
        end

        -- For all gens
        gui.text(settings["pos"][2][1],settings["pos"][2][2]+sel[2]/16, "H.Power")
        gui.text(settings["pos"][2][1]+sel[2]/4,settings["pos"][2][2]+sel[2]/16, table["type"][pokemon["hiddenpower"]["type"]+1].." "..pokemon["hiddenpower"]["base"], table["typecolor"][pokemon["hiddenpower"]["type"]+1])
        gui.text(settings["pos"][2][1],settings["pos"][2][2]+3*sel[2]/16, "Moves:")
        for i=1,4 do -- For each move
          if table["move"][pokemon["move"][i]] ~= nil then 
            gui.text(settings["pos"][2][1],settings["pos"][2][2]+(i+3)*sel[2]/16, table["move"][pokemon["move"][i]].." - "..pokemon["pp"][i].."PP") -- Display name and PP
          end
        end
			end
    else -- No PID found
      if status == 1 then -- If player team just decrement n
        substatus[1] = 1
      elseif status == 2 then -- If enemy
        if substatus[2] == 1 then -- If was trying first enemy go back to player team
          status = 1
        else -- Else decrement n
          substatus[2] = 1
        end
      else -- Shouldn't happen but hey, warn me if it does
        print("Something's wrong.")
      end
      gui.text(settings["pos"][1][1],settings["pos"][1][2],"No Pokemon", "red") -- Beautiful red warning
    end

    -- Script performance (useless)
    local clocktime = os.clock()-nClock
    clockcount = clockcount + 1
    totalclocktime = totalclocktime+clocktime
    lastclocktime = clocktime ~= 0 and clocktime or lastclocktime
    highestclocktime = clocktime > highestclocktime and clocktime or highestclocktime
    local meanclocktime = totalclocktime/clockcount
    if yling==1 then -- I lied, there's a secret key to display script performance, but who cares besides me? (It's Y)
      gui.text(settings["pos"][2][1],2*settings["pos"][2][2],"Last clock time: "..numTruncate(lastclocktime*1000,2).."ms")
      gui.text(settings["pos"][2][1],2*settings["pos"][2][2]+sel[2]/16,"Mean clock time: "..numTruncate(meanclocktime*1000,2).."ms")
      gui.text(settings["pos"][2][1],2*settings["pos"][2][2]+2*sel[2]/16,"Most clock time: "..numTruncate(highestclocktime*1000,2).."ms")
      gui.text(settings["pos"][2][1],2*settings["pos"][2][2]+3*sel[2]/16,"Data fetched: "..count.."x")
    end

    apply_api_buttons()

    -- Try to accept a client connection. This will provide the bulk of the
    -- script later, where the client can start making API calls to our socket. 
    while true do  
      local function read_all()
        local ready, ready_w, err = socket.select(clients, {}, 0)
        for i = 1, #ready, 1 do
          -- https://stackoverflow.com/questions/67825653/how-can-i-properly-receive-data-with-a-tcp-python-socket-until-a-delimiter-is-fo
          local function read_line()
            while string.find(buffer, "\r\n") == nil do
              local data, err, partial = ready[i]:receive(4096)
              if data ~= nil then
                buffer = buffer..data
              else
                if partial ~= "" then
                  buffer = buffer..partial
                else
                  break
                end
              end
            end

            local partitions = split(buffer, "\r\n")
            buffer = ""
            if #partitions > 1 then
              local rest = {}
              for i = 2, #partitions, 1 do
                table_lib.insert(rest, partitions[i])
              end
              buffer = buffer..table_lib.concat(rest, "\r\n")
            end
            return partitions[1]
          end 

          local total = nil -- Not best practice but we need to make them unequal
          local seen = 0

          while seen ~= total do
            local message = {}
            local line = read_line()
            if line ~= nil then
              if (
                pcall(function ()
                  message = json.decode(line)
                end)
              ) then
                if message["method"] ~= nil then
                  if message["method"] == "header" then
                    total = tonumber(message["args"][1])
                  else
                    seen = seen + 1
                    parse_message(ready[i], message)
                  end
                end
              else
                ready[i]:send(
                  json.encode(Err("A message could not be decoded to JSON.")).."\r\n"
                )
              end
            end
          end
        end
      end

      local client = connection:accept() 
      if client ~= nil then
        client:settimeout(0)
        table_lib.insert(clients, client)
        read_all()
      else
        read_all()
        break
      end
    end
  end
else -- Game not in the data table
    if games[version]["E"] ~= nil then
        print("This version is supported, but not in this language. Check gamesdata.lua to add it.")
    else
        print("This game isn't supported. Is it a hackrom ? It might work but you'll have to add it yourself. Check gamesdata.lua")
    end
    print("Version: "..version)
    print("Language: "..bit.tohex(lan))
end

--[[
-- Cleans up work done by the script. Specifically, this will close the given
-- connection, or at least attempt to.
--
-- Argument:
-- sock: tcp{server}, the server socket to close.
--]]
local function cleanup(sock)
  sock:close()
  for i = 1, #clients, 1 do
    clients[i]:close()
  end
  return Ok("Socket successfully closed.")
end

gui.register(Main)

-- Close the active connection when the script is stopped.
emu.registerexit((function ()
  print(cleanup(connection).val)
end))
