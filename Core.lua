--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
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
  local Cache = {               -- Defines our cached tables.
    -- Temporary
    APLVar = {},
    Enemies = {},
    EnemiesCount = {},
    GUIDInfo = {},
    MiscInfo = {},
    SpellInfo = {},
    ItemInfo = {},
    UnitInfo = {},
    -- Persistent
    Persistent = {
      Equipment = {},
      Player = {
        Class = {UnitClass("player")},
        Spec = {}
      },
      SpellLearned = {Pet = {}, Player = {}},
      Texture = {Spell = {}, Item = {}, Custom = {}}
    }
  };

--- ======= GLOBALIZE =======
  -- Addon
  AethysCore = AC;
  AethysCore_Cache = Cache;


--- ============================ CONTENT ============================
  -- Wipe a table while keeping the structure
  -- i.e. wipe every sub-table as long it doesn't contain a table
  function AC.WipeTableRecursively (Table)
    for Key, Value in pairs(Table) do
      if type(Value) == "table" then
        AC.WipeTableRecursively(Value);
      else
        wipe(Table);
      end
    end
  end

  -- Reset the cache
  AC.CacheHasBeenReset = false;
  function AC.CacheReset ()
    if not AC.CacheHasBeenReset then
      --[[-- foreach method
      for Key, Value in pairs(AC.Cache) do
        wipe(AC.Cache[Key]);
      end]]

      wipe(Cache.APLVar);
      wipe(Cache.Enemies);
      wipe(Cache.EnemiesCount);
      wipe(Cache.GUIDInfo);
      wipe(Cache.MiscInfo);
      wipe(Cache.SpellInfo);
      wipe(Cache.ItemInfo);
      wipe(Cache.UnitInfo);

      AC.CacheHasBeenReset = true;
    end
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
