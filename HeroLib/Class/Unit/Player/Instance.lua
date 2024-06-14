--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL          = ...
-- HeroLib
local Cache, Utils           = HeroCache, HL.Utils
local Unit                   = HL.Unit
local Player, Pet, Target    = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver       = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid            = Unit.Party, Unit.Raid
local Spell                  = HL.Spell
local Item                   = HL.Item

-- Base API locals
local GetInstanceInfo        = GetInstanceInfo
-- Accepts: nil; Returns: name (string), instanceType (string), difficulty (number), difficultyName (string), maxPlayers (number),
-- playerDifficulty (number), isDynamicInstance (bool), instanceID (number), instanceGroupSize (number), lfgDungeonID (number)

-- lua locals

-- File Locals


--- ============================ CONTENT ============================
-- Get the instance information about the current area.
function Player:InstanceInfo(Index)
  return GetInstanceInfo()
end

-- Get the player instance type.
function Player:InstanceType()
  local _, InstanceType = self:InstanceInfo()

  return InstanceType
end

-- Get the player instance difficulty.
function Player:InstanceDifficulty()
  local _, _, Difficulty = self:InstanceInfo()

  return Difficulty
end

-- Get wether the player is in an instanced pvp area.
function Player:IsInInstancedPvP()
  local InstanceType = self:InstanceType()

  return (InstanceType == "arena" or InstanceType == "pvp") or false
end

-- Get wether the player is in a raid area.
function Player:IsInRaidArea()
  return self:InstanceType() == "raid" or false
end

-- Get wether the player is in a dungeon area.
function Player:IsInDungeonArea()
  return self:InstanceType() == "party" or false
end
