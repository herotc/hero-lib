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
  local SBDSpells = {
    Shadowlands = {
      R_CoN_SinsoulBulwarkKaal = Spell(343126),
      R_CoN_SinsoulBulwarkGrashaal = Spell(343135),
      R_CoN_HardenedStoneFormKaal = Spell(329636),
      R_CoN_HardenedStoneFormGrashaal = Spell(329808),
      R_CoN_UnyieldingShield = Spell(346694),
      R_CoN_BloodShroud = Spell(328921),
      R_SoD_EternalTorment = Spell(355790),
      R_SotFO_GenesisBulwark = Spell(367573),
      R_SotFO_DominationsGrasp = Spell(362505),
      R_SotFO_IncompleteForm = Spell(361934),
      R_SotFO_NebularCloud = Spell(365381),
      R_SotFO_BurnedOut = Spell(369571),
    },
    BattleforAzeroth = {
      R_Nya_VoidInfusedIchor = Spell(308377),
    },
    Legion = {
      D_DHT_Submerged = Spell(220519),
      R_ToS_SpiritRealm = Spell(235621),
    },
  }
  local SpecialBlacklistData = {
    --- Dragonflight
    ----- Vault of the Incarnates -----
    --- Raszageth
    -- Volatile Sparks despawn when interrupted, damage to them is irrelevant
    [194999] = true,
    
    --- Shadowlands
    ----- Castle Nathria -----
    --- Stone Legion Generals
    -- General Kaal can't be hit while Sinsoul Bulwark is present and takes 95% reduced damage when Hardened Stone Form is present.
    [168112] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_CoN_SinsoulBulwarkKaal, true)
      or self:BuffUp(SBDSpells.Shadowlands.R_CoN_HardenedStoneFormKaal, true) end,
    -- General Grashaal can't be hit while Sinsoul Bulwark is present and takes 95% reduced damage when Hardened Stone Form is present.
    [168113] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_CoN_SinsoulBulwarkGrashaal, true)
      or self:BuffUp(SBDSpells.Shadowlands.R_CoN_HardenedStoneFormGrashaal, true) end,
    --- The Council of Blood
    -- Stavros, Frieda and Niklaus can't be hit while this buff is present.
    [166970] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_CoN_UnyieldingShield, true) end,
    [166969] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_CoN_UnyieldingShield, true) end,
    [166971] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_CoN_UnyieldingShield, true) end,
    -- Afterimages despawn immediately and shouldn't be damaged
    [172803] = true,
    [173053] = true,
    --- Shriekwing
    -- Shriekwing can't be hit while this buff is present.
    [164406] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_CoN_BloodShroud, true) end,
    ----- Sanctum of Domination -----
    --- Remnant of Ner'zhul
    -- Orb of torment take 99% reduced damage while they have their buff
    [177117] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_SoD_EternalTorment, true) end,
    --- The Nine
    -- Secondary RP units that use scripted attacks
    [177222] = true, -- Aradne
    [177098] = true, -- Arthura
    [177101] = true, -- Brynja
    [177099] = true, -- Daschla
    [178737] = true, -- Kyra (P2)
    [178736] = true, -- Signe (P2)
    --- Painsmith Raznal
    -- Spiked Balls
    [176581] = true,
    --- Sylvannas Windrunner
    -- Friendly RP Units (Bolvar/Jaina/Thrall)
    [178081] = true,
    [176533] = true,
    [176532] = true,
    -- Anduin Wrynn and The Jailer (P3 RP characters in the center platform)
    [178072] = true,
    [178079] = true,
    --- Trash
    -- Condemned Soul Remnant
    [180385] = true,
    ----- Sepulcher of the First Ones -----
    --- Prototype Pantheon
    -- Wild Stampede NPC IDs
    [185456] = true, -- Wild Walkie
    [185460] = true, -- Wild Walkie
    [185480] = true, -- Wild Zoomie
    [185481] = true, -- Wild Sleepy
    --- Artificer Xy'mox
    -- Xy'mox takes 99% reduced damage while they have their buff
    [183501] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_SotFO_GenesisBulwark, true) end,
    --- Anduin Wrynn
    -- Anduin takes no damage directly within intermission phases
    [181854] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_SotFO_DominationsGrasp, true) end,
    [184830] = true, -- Beacon of Hope
    --- Lords of Shadow
    -- Inchoate Shadow enemies should not be attacked until they transform into Corporeal Shadow
    [183138] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_SotFO_IncompleteForm, true) end,
    [181825] = true, -- Slumber Cloud
    --- Rygelon
    -- Cosmic Core enemies do not take damage directly
    [182823] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_SotFO_NebularCloud, true) end,
    -- Unstable Matter enemies are immune to damage for 5s after being brought to 0 HP before healing
    [183945] = function(self) return self:BuffUp(SBDSpells.Shadowlands.R_SotFO_BurnedOut, true) end,
    ----- Dungeons -----
    --- De Other Side
    -- Atal'ai Deathwalker's Spirit cannot be hit.
    [170483] = true,

    --- BfA
    ----- Corruptions -----
    -- Thing From Beyond (Appears to have 2 IDs)
    [160966] = true,
    [161895] = true,
    ----- Ny'alotha -----
    -- Drestagath heals all damage unless you have the Void Infused Ichor debuff
    [157602] = function(self) return not (Player:IsTanking(self) or Player:DebuffUp(SBDSpells.BattleforAzeroth.R_Nya_VoidInfusedIchor)) end,

    --- Legion
    ----- Dungeons -----
    --- Mythic+ Affixes
    -- Fel Explosives
    [120651] = true,
    --- Darkheart Thicket
    -- Strangling roots can't be hit while this buff is present.
    [100991] = function(self) return self:BuffUp(SBDSpells.Legion.D_DHT_Submerged, true) end,
    ----- Trial of Valor -----
    --- Helya
    -- Striking Tentacle cannot be hit.
    [114881] = true,
    ----- Tomb of Sargeras -----
    --- Desolate Host
    -- Engine of Eradication cannot be hit in Spirit Realm.
    [118460] = function(self) return Player:DebuffUp(SBDSpells.Legion.R_ToS_SpiritRealm, nil, true) end,
    -- Soul Queen Dejahna cannot be hit outside of Spirit Realm.
    [118462] = function(self) return not Player:DebuffUp(SBDSpells.Legion.R_ToS_SpiritRealm, nil, true) end,
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
