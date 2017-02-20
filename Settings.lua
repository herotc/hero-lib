--- Localize Vars
-- Addon
local addonName, AC = ...;

-- All settings here should be moved into the GUI someday
AC.GUISettings = {
  General = {
    -- Recovery Timer
    RecoveryMode = "GCD"; -- "GCD" to always display the next ability, "Custom" for Custom RecoveryTimer
    RecoveryTimer = 950;
    -- Blacklist Settings
    Blacklist = {
      -- During how many times the GCD time you want to blacklist an unit from Cycling
      -- when you got an error when trying to cast on it
      NotFacingExpireMultiplier = 3,
      -- Custom List (User Defined), must be a valid Lua Boolean or Function as Value and have the NPCID as Key
      UserDefined = {
        -- Example with fake NPCID:
        -- [123456] = true;
        -- [123456] = function (self) return self:HealthPercentage() <= 80 and true or false; end
        -- Tito Pet Cows
        [71444] = true;
      },
      -- Custom Cycle List (User Defined), must be a valid Lua Boolean or Function as Value and have the NPCID as Key
      CycleUserDefined = {
        -- Example with fake NPCID:
        -- [123456] = true;
        -- [123456] = function (self) return self:HealthPercentage() <= 80 and true or false; end

        -- Bilewater Slime (Helya ToV)
        [114553] = function (self) return self:HealthPercentage() >= 65 and true or false; end,
        -- Decaying Minion
        [114568] = true,
        -- Helarjar Mistwatcher
        [116335] = true,
        -- Scrubber
        [104596] = true,
        -- Fel Soul (Aluriel)
        [115905] = true
      }
    }
  }
};
