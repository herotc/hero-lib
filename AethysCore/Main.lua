--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = HeroCache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local mathmax = math.max;
  local mathmin = math.min;
  -- File Locals
  


--- ============================ CONTENT ============================
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
      -- And add the Reduce CPU Load offset (default 50ms) in case it's enabled.
      --AC.Timer.PulseOffset = mathmax(10, mathmin(50, AC.Latency()))/1000 + (AC.GUISettings.General.ReduceCPULoad and AC.GUISettings.General.ReduceCPULoadOffset or 0);
      -- Until further performance improvements, we'll use 66ms (i.e. 15Hz) as baseline. Offset (positive or negative) can still be added from Settings.lua
      AC.Timer.PulseOffset = 0.066 + (AC.GUISettings.General.ReduceCPULoad and AC.GUISettings.General.ReduceCPULoadOffset or 0);
      AC.Timer.Pulse = AC.GetTime() + AC.Timer.PulseOffset;

      Cache.HasBeenReset = false;
      Cache.Reset();

      if AC.GetTime() > AC.Timer.TTD then
        AC.Timer.TTD = AC.GetTime() + AC.TTD.Settings.Refresh;
        AC.TTDRefresh();
      end
    end
  end

  -- Register the Pulse
  AC.MainFrame:SetScript("OnUpdate", AC.Pulse);
