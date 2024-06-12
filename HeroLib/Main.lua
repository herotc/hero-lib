--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache         = HeroCache
local Unit          = HL.Unit
local Player        = Unit.Player
local Target        = Unit.Target
local Spell         = HL.Spell
local Item          = HL.Item
-- Lua
local mathmax       = math.max
local mathmin       = math.min
-- File Locals
local OnRetail              = true
local PrintedClassicWarning = false


--- ============================ CONTENT ============================
-- Create the MainFrame
HL.MainFrame = CreateFrame("Frame", "HeroLib_MainFrame", UIParent)
HL.MainFrame:RegisterEvent("ADDON_LOADED")
HL.MainFrame:SetScript("OnEvent", function (self, Event, Arg1)
  if Event == "ADDON_LOADED" then
    if Arg1 == "HeroLib" then
      if type(HeroLibDB) ~= "table" then
        HeroLibDB = {}
      end
      if type(HeroLibDB.GUISettings) ~= "table" then
        HeroLibDB.GUISettings = {}
      end
      HL.GUI.LoadSettingsRecursively(HL.GUISettings)
      HL.GUI.CorePanelSettingsInit()

      C_Timer.After(2, function ()
        HL.MainFrame:UnregisterEvent("ADDON_LOADED")
      end)
    end
  end
end)

-- Main
HL.Timer = {
  Pulse = 0,
  PulseOffset = 0,
  TTD = 0
}

function HL.Pulse()
  if HL.BuildInfo[4] and HL.BuildInfo[4] < 110000 then
    OnRetail = false
  end
  if not OnRetail then
    if not PrintedClassicWarning then
      HL.Print("HeroRotation and HeroLib currently only support retail WoW (The War Within). Classic, Wrath of the Lich King, and Hardcore Classic are not supported.")
      PrintedClassicWarning = true
    end
    return
  end
  if GetTime(true) > HL.Timer.Pulse and OnRetail then
    -- Put a 10ms min and 50ms max limiter to save FPS (depending on World Latency).
    -- And add the Reduce CPU Load offset (default 50ms) in case it's enabled.
    --HL.Timer.PulseOffset = mathmax(10, mathmin(50, HL.Latency()))/1000 + (HL.GUISettings.General.ReduceCPULoad and HL.GUISettings.General.ReduceCPULoadOffset or 0)
    -- Until further performance improvements, we'll use 66ms (i.e. 15Hz) as baseline. Offset (positive or negative) can still be added from Settings.lua
    HL.Timer.PulseOffset = 0.066 + (HL.GUISettings.General.ReduceCPULoad and (HL.GUISettings.General.ReduceCPULoadOffset / 1000) or 0)
    HL.Timer.Pulse = GetTime() + HL.Timer.PulseOffset

    Cache.HasBeenReset = false
    Cache.Reset()

    if GetTime() > HL.Timer.TTD then
      HL.Timer.TTD = GetTime() + HL.TTD.Settings.Refresh
      HL.TTDRefresh()
    end
  end
end

-- Register the Pulse
HL.MainFrame:SetScript("OnUpdate", HL.Pulse)
