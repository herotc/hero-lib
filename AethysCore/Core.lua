--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  local Cache = AethysCache;
  -- Lua
  local pairs = pairs;
  local print = print;
  local type = type;
  local wipe = table.wipe;
  -- File Locals
  local _T = {                  -- Temporary Vars
    Argument,                     -- CmdHandler
  };
  AC.MAXIMUM = 40;              -- Max # Buffs and Max # Nameplates.

--- ======= GLOBALIZE =======
  -- Addon
  AethysCore = AC;


--- ============================ CONTENT ============================
  -- Get the GetTime and cache it.
  function AC.GetTime (Reset)
    if not Cache.MiscInfo then Cache.MiscInfo = {}; end
    if not Cache.MiscInfo.GetTime or Reset then
      Cache.MiscInfo.GetTime = GetTime();
    end
    return Cache.MiscInfo.GetTime;
  end

  -- Print with AC Prefix
  function AC.Print (...)
    print("[|cFFFF6600Aethys Core|r]", ...);
  end
