--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
local Cache = HeroCache
-- Lua
local gmatch = gmatch
local pairs = pairs
local print = print
local stringupper = string.upper
local tableinsert = table.insert
local tonumber = tonumber
local type = type
local wipe = table.wipe
-- File Locals


--- ======= GLOBALIZE =======
HeroLib = HL
HL.MAXIMUM = 40 -- Max # Buffs and Max # Nameplates.


--- ============================ CONTENT ============================
--- Build Infos
local LiveVersion, PTRVersion, BetaVersion = "9.1.0", "9.1.0", "9.1.0"
-- version, build, date, tocversion
HL.BuildInfo = { GetBuildInfo() }
-- Get the current build version.
function HL.BuildVersion()
  return HL.BuildInfo[1]
end

-- Get if we are on the Live or not.
function HL.LiveRealm()
  return HL.BuildVersion() == LiveVersion
end

-- Get if we are on the PTR or not.
function HL.PTRRealm()
  return HL.BuildVersion() == PTRVersion
end

-- Get if we are on the Beta or not.
function HL.BetaRealm()
  return HL.BuildVersion() == BetaVersion
end

-- Print with HL Prefix
function HL.Print(...)
  print("[|cFFFF6600Hero Lib|r]", ...)
end

do
  local Setting = HL.GUISettings.General
  -- Debug print with HL Prefix
  function HL.Debug(...)
    if Setting.DebugMode then
      print("[|cFFFF6600Hero Lib Debug|r]", ...)
    end
  end
end

HL.SpecID_ClassesSpecs = {
  -- Death Knight
  [250] = { "DeathKnight", "Blood" },
  [251] = { "DeathKnight", "Frost" },
  [252] = { "DeathKnight", "Unholy" },
  -- Demon Hunter
  [577] = { "DemonHunter", "Havoc" },
  [581] = { "DemonHunter", "Vengeance" },
  -- Druid
  [102] = { "Druid", "Balance" },
  [103] = { "Druid", "Feral" },
  [104] = { "Druid", "Guardian" },
  [105] = { "Druid", "Restoration" },
  -- Evoker
  [1467] = { "Evoker", "Devastation" },
  --[1468] = { "Evoker", "Preservation" },
  -- Hunter
  [253] = { "Hunter", "Beast Mastery" },
  [254] = { "Hunter", "Marksmanship" },
  [255] = { "Hunter", "Survival" },
  -- Mage
  [62] = { "Mage", "Arcane" },
  [63] = { "Mage", "Fire" },
  [64] = { "Mage", "Frost" },
  -- Monk
  [268] = { "Monk", "Brewmaster" },
  [269] = { "Monk", "Windwalker" },
  [270] = { "Monk", "Mistweaver" },
  -- Paladin
  [65] = { "Paladin", "Holy" },
  [66] = { "Paladin", "Protection" },
  [70] = { "Paladin", "Retribution" },
  -- Priest
  [256] = { "Priest", "Discipline" },
  [257] = { "Priest", "Holy" },
  [258] = { "Priest", "Shadow" },
  -- Rogue
  [259] = { "Rogue", "Assassination" },
  [260] = { "Rogue", "Outlaw" },
  [261] = { "Rogue", "Subtlety" },
  -- Shaman
  [262] = { "Shaman", "Elemental" },
  [263] = { "Shaman", "Enhancement" },
  [264] = { "Shaman", "Restoration" },
  -- Warlock
  [265] = { "Warlock", "Affliction" },
  [266] = { "Warlock", "Demonology" },
  [267] = { "Warlock", "Destruction" },
  -- Warrior
  [71] = { "Warrior", "Arms" },
  [72] = { "Warrior", "Fury" },
  [73] = { "Warrior", "Protection" }
}
