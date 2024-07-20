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
local IsMounted              = IsMounted
-- Accepts: nil; Returns: mounted (bool)
local UnitInParty            = UnitInParty
-- Accepts: unitID; Returns: inParty (bool)
local UnitInRaid             = UnitInRaid
-- Accepts: unitID; Returns: index (number)
local UnitInVehicle          = UnitInVehicle
-- Accepts: unitID; Returns: inVehicle (bool)
local UnitRace               = UnitRace
-- Accepts: unitID; Returns: localizedRaceName (string), englishRaceName (string), raceID (number)

-- lua locals

-- File Locals


--- ============================ CONTENT ============================

-- Get if the player is mounted on a non-combat mount.
function Player:IsMounted()
  return IsMounted() and not self:IsOnCombatMount()
end

-- Get if the player is in a party.
function Player:IsInParty()
  return UnitInParty(self.UnitID)
end

-- Get if the player is in a raid.
function Player:IsInRaid()
  return UnitInRaid(self.UnitID)
end

-- Get the player race.
-- Dwarf, Draenei, Gnome, Human, NightElf, Worgen
-- BloodElf, Goblin, Orc, Tauren, Troll, Scourge
-- Pandaren
function Player:Race()
  local _, Race = UnitRace(self.UnitID)
  return Race
end

-- Test if the unit is of the given race.
function Player:IsRace(ThisRace)
  return ThisRace and self:Race() == ThisRace or false
end

-- Return the character's Hero Talent spec by name
function Player:HeroTree()
  return Cache.Persistent.Player.HeroTree
end

-- Return the character's Hero Talent spec by ID
function Player:HeroTreeID()
  return Cache.Persistent.Player.HeroTreeID
end

do
  -- Get if the player is on a combat mount or not.
  local CombatMountBuff = {
    --- Classes
    Spell(131347), -- Demon Hunter Glide
    Spell(783),    -- Druid Travel Form
    Spell(165962), -- Druid Flight Form
    Spell(220509), -- Paladin Divine Steed
    Spell(221883), -- Paladin Divine Steed
    Spell(221885), -- Paladin Divine Steed
    Spell(221886), -- Paladin Divine Steed
    Spell(221887), -- Paladin Divine Steed
    Spell(254471), -- Paladin Divine Steed
    Spell(254472), -- Paladin Divine Steed
    Spell(254473), -- Paladin Divine Steed
    Spell(254474), -- Paladin Divine Steed

    --- Legion
    -- Class Order Hall
    Spell(220480), -- Death Knight Ebon Blade Deathcharger
    Spell(220484), -- Death Knight Nazgrim's Deathcharger
    Spell(220488), -- Death Knight Trollbane's Deathcharger
    Spell(220489), -- Death Knight Whitemane's Deathcharger
    Spell(220491), -- Death Knight Mograine's Deathcharger
    Spell(220504), -- Paladin Silver Hand Charger
    Spell(220507), -- Paladin Silver Hand Charger
    -- Stormheim PVP Quest (Bareback Brawl)
    Spell(221595), -- Storm's Reach Cliffwalker
    Spell(221671), -- Storm's Reach Warbear
    Spell(221672), -- Storm's Reach Greatstag
    Spell(221673), -- Storm's Reach Worg
    Spell(218964), -- Stormtalon

    --- Warlord of Draenor
    -- Nagrand
    Spell(164222), -- Frostwolf War Wolf
    Spell(165803) -- Telaari Talbuk
  }
  function Player:IsOnCombatMount()
    for i = 1, #CombatMountBuff do
      if self:BuffUp(CombatMountBuff[i], true) then
        return true
      end
    end
    return false
  end
end

-- Get if the player is in a valid vehicle.
function Player:IsInVehicle()
  return UnitInVehicle(self.UnitID) and not self:IsInWhitelistedVehicle()
end

do
  -- Get if the player is in a vhehicle that is not really a vehicle.
  local InVehicleWhitelist = {
    Spells = {
      --- Dragonflight
      Spell(377222), -- Consume (Treemouth, Brackenhide Hollow)

      --- Shadowlands
      -- Plaguefall
      Spell(328429), -- Crushing Embrace (Slime Tentacle)
      -- The Maw
      Spell(346835), -- Soul Brand (Winged Abductors)

      --- Warlord of Draenor
      -- Hellfire Citadel
      Spell(187819), -- Crush (Kormrok's Hands)
      Spell(181345), -- Foul Crush (Kormrok's Tank Hand)
      -- Blackrock Foundry
      Spell(157059), -- Rune of Grasping Earth (Kromog's Hand)
    },
    PetMounts = {
      --- Legion
      -- Karazhan
      116802, -- Rodent of Usual Size

      --- Warlord of Draenor
      -- Garrison Stables Quest
      87082, -- Silverperlt
      87078, -- Icehoof
      87081, -- Rocktusk
      87080, -- Riverwallow
      87079, -- Meadowstomper
      87076, -- Snarler
    }
  }
  function Player:IsInWhitelistedVehicle()
    -- Spell
    local VehicleSpells = InVehicleWhitelist.Spells
    for i = 1, #VehicleSpells do
      local VehicleSpell = VehicleSpells[i]
      if self:DebuffUp(VehicleSpell, nil, true) then
        return true
      end
    end

    -- PetMount
    local PetMounts = InVehicleWhitelist.PetMounts
    if Pet:IsActive() then
      for i = 1, #PetMounts do
        local PetMount = PetMounts[i]
        if Pet:NPCID() == PetMount then
          return true
        end
      end
    end

    return false
  end
end

-- M+ Quaking was removed, but the code could be useful later.
-- Commenting the code out for now.
--[[ do
  local StopCast = {
    Debuffs = {
    }
  }
  function Player:ShouldStopCasting()
    local Debuffs = StopCast.Debuffs
    for i = 1, #Debuffs do
      local Record = Debuffs[i]
      local Debuff, Duration
      if type(Record) == "table" then
        Debuff, Duration = Record[1], Record[2]
      else
        Debuff = Record
      end
      if self:DebuffUp(Debuff, nil, true) and (not Duration or self:DebuffRemains(Debuff, nil, true) <= Duration) then
        return true
      end
    end
  end
end ]]
