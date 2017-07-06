--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  local Cache = AethysCache;
  -- Lua
  local pairs = pairs;
  local print = print;
  local tableinsert = table.insert;
  local tonumber = tonumber;
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
  -- Constant Infos Enum
  AC.Enum = {};

  -- Build Infos
  local LiveVersion, PTRVersion, BetaVersion = "7.2.5", "7.2.5", "7.2.5";
  -- version, build, date, tocversion
  AC.BuildInfo = {GetBuildInfo()};
  -- Get the current build version.
  function AC.BuildVersion ()
    return AC.BuildInfo[1];
  end
  -- Get if we are on the Live or not.
  function AC.LiveRealm ()
    return AC.BuildVersion() == LiveVersion;
  end
  -- Get if we are on the PTR or not.
  function AC.PTRRealm ()
    return AC.BuildVersion() == PTRVersion;
  end
  -- Get if we are on the Beta or not.
  function AC.BetaRealm ()
    return AC.BuildVersion() == BetaVersion;
  end

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

  -- Merge two tables
  function AC.MergeTable(T1, T2)
    for _, Value in pairs(T2) do
      tableinsert(T1, Value);
    end
    return T1;
  end

  -- Compare two values
  local CompareThisTable = {
    [">"] = function (A, B) return A > B; end,
    ["<"] = function (A, B) return A < B; end,
    [">="] = function (A, B) return A >= B; end,
    ["<="] = function (A, B) return A <= B; end,
    ["=="] = function (A, B) return A == B; end
  };
  function AC.CompareThis (Operator, A, B)
    return CompareThisTable[Operator](A, B);
  end

  -- Convert a string to a number if possible, or return the string.
  -- If the conversion is nil, it means it's not a number, then return the string.
  function AC.StringToNumberIfPossible (String)
    local Converted = tonumber(String);
    return Converted ~= nil and Converted or String;
  end
