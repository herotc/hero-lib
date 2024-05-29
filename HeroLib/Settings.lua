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
    ReduceCPULoadOffset = 34, -- Default:34ms | It'll be added to the default 66ms, can be positive or negative
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
        --- Dragonflight
        ----- Dungeons -----
        [193757] = true, -- Ruby Whelp Shell
        ----- Raid -----
        --- Aberrus
        [202612] = true, -- Screaming Black Dragonscale
        [203729] = true, -- Ominous Chromatic Essence
        --- Amirdrassil
        [207783] = true, -- Cruel Dreamcarver
        ----- Open World Reward -----
        [195220] = true, -- Uncanny Pocketwatch
        [200563] = true, -- Primal Ritual Shell
        [201962] = true, -- Heat of Primal Winter
        [204388] = true, -- Draconic Cauterizing Magma
        ----- Engineering Items -----
        [198322] = true, -- Overengineered Sleeve Extenders
        [198323] = true, -- Lightweight Ocular Lenses
        [198324] = true, -- Peripheral Vision Projectors
        [198325] = true, -- Oscillating Wilderness Opticals
        [198326] = true, -- Battle-Ready Goggles
        [198327] = true, -- Needlessly Complex Wristguards
        [198328] = true, -- Quality Assured Optics
        [198329] = true, -- Milestone Magnifiers
        [198330] = true, -- Deadline Deadeyes
        [198331] = true, -- Sentrys Stabilized Specs
        [198332] = true, -- Complicated Cuffs
        [198333] = true, -- Difficult Wrist Protectors
        [205278] = true, -- Cloth Goggles
        [205279] = true, -- Leather Goggles
        [205280] = true, -- Mail Goggles
        [205281] = true, -- Plate Goggles
        ----- Other Crafted Items -----
        [193000] = true, -- Ring-Bound Hourglass
      }
    }
  }
}

function HL.GUI.CorePanelSettingsInit()
  -- GUI
  local HLPanel = CreatePanel(HL.GUI, "HeroLib", "PanelFrame", HL.GUISettings, HeroLibDB.GUISettings)
  -- Child Panel
  local CP_General = CreateChildPanel(HLPanel, "General")
  -- Debug
  CreatePanelOption("CheckButton", CP_General, "General.DebugMode", "Enable Debug Mode", "Enable if you want HeroLib to output debug messages.")
  -- ReduceCPULoad
  CreatePanelOption("CheckButton", CP_General, "General.ReduceCPULoad", "Reduce CPU Load", "Enable if you would like to increase the cycle time of the addon, causing HeroLib and HeroRotation to use less CPU by running through its cycles on a longer delay.")
  CreatePanelOption("Slider", CP_General, "General.ReduceCPULoadOffset", {0, 1000, 1}, "Reduce CPU Load Offset (|cffff0000WARNING|r)", "Set this value to tell the addon how many more milliseconds to add to HeroLib and HeroRotation's cycle time when the above 'Reduce CPU Load' option is checked. |cffff0000WARNING|r: High values are NOT recommended, as this will cause HeroRotation's suggestions to appear latent. By default, the addon will cycle 15 times per second (its built-in 66ms delay). When 'Reduce CPU Load' is checked, this value will be added to that 66ms. If this value is set to 434, for example, that will add 434ms. This would make HeroRotation only cycle twice per second.")
end
