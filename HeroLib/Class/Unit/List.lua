--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid = Unit.Party, Unit.Raid
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local GetTime = GetTime
local type = type
-- File Locals



--- ============================ CONTENT ============================
-- Check if the unit is coded as blacklisted or not.
do
  local SpecialBlacklistDataSpells = {
    D_DHT_Submerged = Spell(220519),
    R_TOS_SpiritRealm = Spell(235621),
    R_NYA_VoidInfusedIchor = Spell(308377)
  }
  local SpecialBlacklistData = {
    --- BfA
    ----- Corruptions -----
    -- Thing From Beyond (Appears to have 2 IDs)
    [160966] = true,
    [161895] = true,
    --- Legion
    ----- Dungeons (7.0 Patch) -----
    --- Darkheart Thicket
    -- Strangling roots can't be hit while this buff is present
    [100991] = function(self) return self:BuffUp(SpecialBlacklistDataSpells.D_DHT_Submerged, true) end,
    --- Mythic+ Affixes
    -- Fel Explosives (7.2 Patch)
    [120651] = true,
    ----- Trial of Valor (T19 - 7.1 Patch) -----
    --- Helya
    -- Striking Tentacle cannot be hit.
    [114881] = true,
    ----- Tomb of Sargeras (T20 - 7.2 Patch) -----
    --- Desolate Host
    -- Engine of Eradication cannot be hit in Spirit Realm.
    [118460] = function(self) return Player:DebuffUp(SpecialBlacklistDataSpells.R_TOS_SpiritRealm, nil, true) end,
    -- Soul Queen Dejahna cannot be hit outside Spirit Realm.
    [118462] = function(self) return not Player:DebuffUp(SpecialBlacklistDataSpells.R_TOS_SpiritRealm, nil, true) end,
    ----- Ny'alotha (8.3 Patch) -----
    -- Drestagath heals all damage unless you have the Void Infused Ichor debuff
    [157602] = function(self) return not (Player:IsTanking(self) or Player:DebuffUp(SpecialBlacklistDataSpells.R_NYA_VoidInfusedIchor)) end,
  }

  function Unit:IsBlacklisted()
    local NPCID = self:NPCID()

    local BlacklistEntry = SpecialBlacklistData[NPCID]
    if BlacklistEntry then
      if type(BlacklistEntry) == "boolean" then
        return true
      else
        return BlacklistEntry(self)
      end
    end

    return false
  end
end

-- Check if the unit is coded as blacklisted by the user or not.
do
  local UserDefined = HL.GUISettings.General.Blacklist.UserDefined

  function Unit:IsUserBlacklisted()
    local NPCID = self:NPCID()

    local BlacklistEntry = UserDefined[NPCID]
    if BlacklistEntry then
      if type(BlacklistEntry) == "boolean" then
        return true
      else
        return BlacklistEntry(self)
      end
    end

    return false
  end
end

-- Check if the unit is coded as blacklisted for cycling by the user or not.
do
  local CycleUserDefined = HL.GUISettings.General.Blacklist.CycleUserDefined

  function Unit:IsUserCycleBlacklisted()
    local NPCID = self:NPCID()

    local BlacklistEntry = CycleUserDefined[NPCID]
    if BlacklistEntry then
      if type(BlacklistEntry) == "boolean" then
        return true
      else
        return BlacklistEntry(self)
      end
    end

    return false
  end
end

--- Check if the unit is coded as blacklisted for Marked for Death (Rogue) or not.
-- Most of the time if the unit doesn't really die and isn't the last unit of an instance.
do
  local SpecialMfDBlacklistData = {
    --- Legion
    ----- Dungeons (7.0 Patch) -----
    --- Halls of Valor
    -- Hymdall leaves the fight at 10%.
    [94960] = true,
    -- Solsten and Olmyr doesn't "really" die
    [102558] = true,
    [97202] = true,
    -- Fenryr leaves the fight at 60%. We take 50% as check value since it doesn't get immune at 60%.
    [95674] = function(self) return self:HealthPercentage() > 50 and true or false end,

    ----- Trial of Valor (T19 - 7.1 Patch) -----
    --- Odyn
    -- Hyrja & Hymdall leaves the fight at 25% during first stage and 85%/90% during second stage (HM/MM)
    [114360] = true,
    [114361] = true,

    --- Warlord of Draenor (WoD)
    ----- HellFire Citadel (T18 - 6.2 Patch) -----
    --- Hellfire Assault
    -- Mar'Tak doesn't die and leave fight at 50% (blocked at 1hp anyway).
    [93023] = true,

    ----- Dungeons (6.0 Patch) -----
    --- Shadowmoon Burial Grounds
    -- Carrion Worm : They doesn't die but leave the area at 10%.
    [88769] = true,
    [76057] = true,
  }
  function Unit:IsMfDBlacklisted()
    local NPCID = self:NPCID()

    local BlacklistEntry = SpecialMfDBlacklistData[NPCID]
    if BlacklistEntry then
      if type(BlacklistEntry) == "boolean" then
        return true
      else
        return BlacklistEntry(self)
      end
    end

    return false
  end
end

do
  local NotFacingExpireMultiplier = HL.GUISettings.General.Blacklist.NotFacingExpireMultiplier

  function Unit:IsFacingBlacklisted()
    if self:IsUnit(HL.UnitNotInFront) and GetTime() - HL.UnitNotInFrontTime <= Player:GCD() * NotFacingExpireMultiplier then
      return true
    end
    return false
  end
end
