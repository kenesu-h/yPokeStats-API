Pokemon = {
  national_id = 0,
  species = "",
  ot_id = "",
  ot_sid = "",
  xp = 0,
  item = "",
  pokerus = false,
  friendship = 0,
  ability = "",
  -- nature = "",
  moves = {},
  ivs = {},
  evs = {},
  stats = {},
  current_hp = 0
}

function Pokemon:new(
  national_id, species, ot_id, ot_sid,
  xp, item, pokerus, friendship, ability,
  -- nature,
  moves, ivs, evs, stats, current_hp
)
  local pokemon = {}
  pokemon.national_id = national_id
  pokemon.species = species
  pokemon.ot_id = ot_id
  pokemon.ot_sid = ot_sid
  pokemon.xp = xp
  pokemon.item = item
  pokemon.pokerus = pokerus
  pokemon.friendship = friendship
  pokemon.ability = ability
  -- pokemon.nature = nature
  pokemon.moves = moves
  pokemon.ivs = ivs
  pokemon.evs = evs
  pokemon.stats = stats
  pokemon.current_hp = current_hp
  return pokemon
end

--[[
-- A StatSet is a StatSet = {
--   hp: number,
--   attack: number,
--   defense: number,
--   special_attack: number,
--   special_defense: number,
--   speed: number
-- }
--
-- In essence, this is a collection of values representing the values a Pokemon
-- has for each individual stats. For example, this could represent the IVs that
-- a Pokemon was generated with, the EVs that it's accumulated over the course
-- of gameplay, or their actual stats after IVs, EVs, nature, and levels are
-- factored in.
--]]
StatSet = {
  hp = 0,
  attack = 0,
  defense = 0,
  special_attack = 0,
  special_defense = 0,
  speed = 0
}

function StatSet:new(
  hp, attack, defense, special_attack, special_defense, speed
)
  local stat_set = {}
  stat_set.hp = hp
  stat_set.attack = attack
  stat_set.defense = defense
  stat_set.special_attack = special_attack
  stat_set.special_defense = special_defense
  stat_set.speed = speed
  return stat_set
end
