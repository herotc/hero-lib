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


--- ======= GLOBALIZE =======
  -- Addon
  AethysCore = AC;
  AC.Enum = {}; -- Constant Infos Enum
  AC.MAXIMUM = 40; -- Max # Buffs and Max # Nameplates.


--- ============================ CONTENT ============================
  --- Build Infos
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

  do
    local Setting = AC.GUISettings.General;
    -- Debug print with AC Prefix
    function AC.Debug (...)
      if Setting.DebugMode then
        print("[|cFFFF6600AC Debug|r]", ...);
      end
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
