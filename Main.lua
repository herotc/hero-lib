--- Localize Vars
-- Addon
local addonName, AC = ...;
-- AethysCore
local Cache = AethysCore_Cache;
local Unit = AC.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = AC.Spell;
local Item = AC.Item;
-- Lua
local mathmax = math.max;
local mathmin = math.min;


-- Create the MainFrame
AC.MainFrame = CreateFrame("Frame", "AethysCore_MainFrame", UIParent);

-- Main
AC.Timer = {
  Pulse = 0,
  PulseOffset = 0,
  TTD = 0
};
function AC.Pulse ()
  if AC.GetTime(true) > AC.Timer.Pulse then
    -- Put a 10ms min and 50ms max limiter to save FPS (depending on World Latency).
    AC.Timer.PulseOffset = mathmax(10, mathmin(50, AC.Latency()))/1000;
    AC.Timer.Pulse = AC.GetTime() + AC.Timer.PulseOffset;

    AC.CacheHasBeenReset = false;
    AC.CacheReset();

    if AC.GetTime() > AC.Timer.TTD then
      AC.Timer.TTD = AC.GetTime() + AC.TTD.Settings.Refresh;
      AC.TTDRefresh();
    end
  end
end

-- Register the Pulse
AC.MainFrame:SetScript("OnUpdate", AC.Pulse);