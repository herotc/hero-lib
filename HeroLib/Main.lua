--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, HL = ...
  -- HeroLib
  local Cache = HeroCache
  local Unit = HL.Unit
  local Player = Unit.Player
  local Target = Unit.Target
  local Spell = HL.Spell
  local Item = HL.Item
  -- Lua
  local mathmax = math.max
  local mathmin = math.min
  -- File Locals



--- ============================ CONTENT ============================
  -- Create the MainFrame
  HL.MainFrame = CreateFrame("Frame", "HeroLib_MainFrame", UIParent)

  -- Main
  HL.Timer = {
    Pulse = 0,
    PulseOffset = 0,
    TTD = 0
  }
  function HL.Pulse ()
    if HL.GetTime(true) > HL.Timer.Pulse then
      -- Put a 10ms min and 50ms max limiter to save FPS (depending on World Latency).
      -- And add the Reduce CPU Load offset (default 50ms) in case it's enabled.
      --HL.Timer.PulseOffset = mathmax(10, mathmin(50, HL.Latency()))/1000 + (HL.GUISettings.General.ReduceCPULoad and HL.GUISettings.General.ReduceCPULoadOffset or 0)
      -- Until further performance improvements, we'll use 66ms (i.e. 15Hz) as baseline. Offset (positive or negative) can still be added from Settings.lua
      HL.Timer.PulseOffset = 0.066 + (HL.GUISettings.General.ReduceCPULoad and HL.GUISettings.General.ReduceCPULoadOffset or 0)
      HL.Timer.Pulse = HL.GetTime() + HL.Timer.PulseOffset

      Cache.HasBeenReset = false
      Cache.Reset()

      if HL.GetTime() > HL.Timer.TTD then
        HL.Timer.TTD = HL.GetTime() + HL.TTD.Settings.Refresh
        HL.TTDRefresh()
      end
    end
  end

  -- Register the Pulse
  HL.MainFrame:SetScript("OnUpdate", HL.Pulse)
