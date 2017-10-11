--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  local Cache = AethysCache;
  -- Lua
  local gmatch = gmatch;
  local pairs = pairs;
  local print = print;
  local stringupper = string.upper;
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
  local LiveVersion, PTRVersion, BetaVersion = "7.3.0", "7.3.0", "7.3.2";
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



-- TODO: Move all this into an utils table

  -- Uppercase the first letter in a string
  function AC.UpperCaseFirst (ThisString)
    return (ThisString:gsub("^%l", stringupper));
  end

  -- Merge two tables
  function AC.MergeTable(T1, T2)
    local Table = {};
    for _, Value in pairs(T1) do
      tableinsert(Table, Value);
    end
    for _, Value in pairs(T2) do
      tableinsert(Table, Value);
    end
    return Table;
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

  -- Count how many string occurances there is in a string.
  function AC.SubStringCount (String, SubString)
    local Count = 0;
    for _ in String:gmatch(SubString) do 
        Count = Count + 1;
    end
    return Count;
  end

  -- Revert a table index
  function AC.RevertTableIndex (Table)
    local NewTable = {};
    for i=#Table, 1, -1 do
      tableinsert(NewTable, Table[i]);
    end
    return NewTable;
  end

  -- Ascending sort function
  function AC.SortASC (a, b)
    return a < b;
  end

  -- Descending sort function
  function AC.SortDESC (a, b)
    return a > b;
  end

  -- Ascending sort function for string + number type
  function AC.SortMixedASC (a, b)
    if type(a) == "string" and type(b) == "number" then
      return a < tostring(b);
    elseif type(a) == "number" and type(b) == "string" then
      return b < tostring(a);
    else
      return a < b;
    end
  end

  AC.SpecID_ClassesSpecs = {
    -- Death Knight
      [250]   = {"DeathKnight", "Blood"},
      [251]   = {"DeathKnight", "Frost"},
      [252]   = {"DeathKnight", "Unholy"},
    -- Demon Hunter
      [577]   = {"DemonHunter", "Havoc"},
      [581]   = {"DemonHunter", "Vengeance"};
    -- Druid
      [102]   = {"Druid", "Balance"},
      [103]   = {"Druid", "Feral"},
      [104]   = {"Druid", "Guardian"},
      [105]   = {"Druid", "Restoration"},
    -- Hunter
      [253]   = {"Hunter", "Beast Mastery"},
      [254]   = {"Hunter", "Marksmanship"},
      [255]   = {"Hunter", "Survival"},
    -- Mage
      [62]    = {"Mage", "Arcane"},
      [63]    = {"Mage", "Fire"},
      [64]    = {"Mage", "Frost"},
    -- Monk
      [268]   = {"Monk", "Brewmaster"},
      [269]   = {"Monk", "Windwalker"},
      [270]   = {"Monk", "Mistweaver"},
    -- Paladin
      [65]    = {"Paladin", "Holy"},
      [66]    = {"Paladin", "Protection"},
      [70]    = {"Paladin", "Retribution"},
    -- Priest
      [256]   = {"Priest", "Discipline"},
      [257]   = {"Priest", "Holy"},
      [258]   = {"Priest", "Shadow"},
    -- Rogue
      [259]   = {"Rogue", "Assassination"},
      [260]   = {"Rogue", "Outlaw"},
      [261]   = {"Rogue", "Subtlety"},
    -- Shaman
      [262]   = {"Shaman", "Elemental"},
      [263]   = {"Shaman", "Enhancement"},
      [264]   = {"Shaman", "Restoration"},
    -- Warlock
      [265]   = {"Warlock", "Affliction"},
      [266]   = {"Warlock", "Demonology"},
      [267]   = {"Warlock", "Destruction"},
    -- Warrior
      [71]    = {"Warrior", "Arms"},
      [72]    = {"Warrior", "Fury"},
      [73]    = {"Warrior", "Protection"}
    };
