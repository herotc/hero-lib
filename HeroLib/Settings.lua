--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- File Locals
local GUI = HL.GUI
local CreatePanel = GUI.CreatePanel
local CreateChildPanel = GUI.CreateChildPanel
local CreatePanelOption = GUI.CreatePanelOption


--- ============================ CONTENT ============================
-- All settings here should be moved into the GUI someday
HL.GUISettings = {
  General = {
    -- Debug Mode
    DebugMode = false,
    -- Reduce CPU Usage (decrease a little bit Rotation potential performance but saves FPS)
    ReduceCPULoad = false,
    ReduceCPULoadOffset = 0.034, -- Default:34ms | It'll be added to the default 66ms, can be positive or negative
    -- Blacklist Settings
    Blacklist = {
      -- During how many times the GCD time you want to blacklist an unit from Cycling
      -- when you got an error when trying to cast on it
      NotFacingExpireMultiplier = 3,
      -- Custom List (User Defined), must be a valid Lua Boolean or Function as Value and have the NPCID as Key
      UserDefined = {-- Example with fake NPCID:
        -- [123456] = true
        -- [123456] = function (self) return self:HealthPercentage() <= 80 and true or false end
      },
      -- Custom Cycle List (User Defined), must be a valid Lua Boolean or Function as Value and have the NPCID as Key
      CycleUserDefined = {
        -- Example with fake NPCID:
        -- [123456] = true
        -- [123456] = function (self) return self:HealthPercentage() <= 80 and true or false end

        --- Legion
        ----- Trial of Valor (T19 - 7.1 Patch) -----
        --- Helya
        -- Bilewater Slime
        [114553] = function(self) return self:HealthPercentage() >= 65 and true or false end,
        -- Decaying Minion
        [114568] = true,
        -- Helarjar Mistwatcher
        [116335] = true,
        ----- Nighthold (T19 - 7.1.5 Patch) -----
        --- Trilliax
        -- Scrubber
        [104596] = true,
        --- Spellblade Aluriel
        -- Fel Soul
        [115905] = true,
        --- Botanist Tel'Arn (Mythic Only)
        -- Naturalist Tel'Arn
        [109041] = function() return HL.GetInstanceDifficulty() == 16 and true or false end,
        -- Arcanist Tel'Arn
        [109040] = function() return HL.GetInstanceDifficulty() == 16 and true or false end,
        -- Solarist Tel'Arn
        [109038] = function() return HL.GetInstanceDifficulty() == 16 and true or false end,
        --- Star Augur Etraeus
        -- Voidling
        [104688] = true,
        ----- Tomb of Sargeras (T20 - 7.2.5 Patch) -----
        --- Mistress Sassz'ine
        -- Abyss Stalker
        [115795] = true,
        -- Razorjaw Waverunner
        [115902] = true,
        --- Fallen Avatar
        -- Maiden of Valor
        [120437] = true,
        ----- BfA Dungeons -----
        -- Mechagon Workshop - Shield Generator
        [151579] = true,
        ----- Ny'alotha (T25 - 8.3 Patch) -----
        --- Shad'har
        -- Living Miasma
        [157229] = true,
        ----- Corrupted Gear (8.3 Patch) -----
        -- Thing From Beyond
        [160966] = true,
        ----- SL Dungeons -----
        -- Mists of Tirna Scythe - Illusionary Vulpin (Mistcaller)
        [165251] = true,
        -- Sanguine Depths - Animated Weapon (Noble Skirmisher)
        [166589] = true,
      },
      -- Custom Use Trinket Ignore List
      ItemUserDefined = {
        --- Shadowlands
        ----- PvP -----
        --- Rated
        -- Sinful Gladiator's Medallion
        [181333] = true,
        -- Corrupted Gladiator's Medallion
        [184055] = true,
        -- Unchained Gladiator's Medallion
        [185304] = true,
        --- Unrated
        -- Sinful Aspirant's Medallion
        [184052] = true,
        -- Corrupted Aspirant's Medallion
        [184058] = true,
        -- Unchained Aspirant's Medallion
        [185309] = true,
        --- Battle for Azeroth
        ----- Raid -----
        --- Ny'alotha, The Waking City
        -- Humming Black Dragonscale
        [174044] = true
      }
    }
  }
}

function HL.GUI.CorePanelSettingsInit()
  -- GUI
  local HLPanel = CreatePanel(HL.GUI, "HeroLib", "PanelFrame", HL.GUISettings, HeroLibDB.GUISettings)
  -- Child Panel
  local CP_HLGeneral = CreateChildPanel(HLPanel, "HLGeneral")
  -- Debug
  CreatePanelOption("CheckButton", CP_HLGeneral, "General.DebugMode", "Enable Debug Mode", "Enable if you want HeroLib to output debug messages.")
  -- ReduceCPULoad
  CreatePanelOption("CheckButton", CP_HLGeneral, "General.ReduceCPULoad", "Reduce CPU Load", "Enable if you would like to increase the cycle time of the addon, causing the addon to use less CPU.")
  CreatePanelOption("Slider", CP_HLGeneral, "General.ReduceCPULoadOffset", {0, 1, 0.01}, "Reduce CPU Load Offset", "Set this value to tell the addon how many more milliseconds to add to its cycle time. For example: 0.03 is 30ms.")
end
