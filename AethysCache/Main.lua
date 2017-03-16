--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, Cache = ...;
  -- Lua

  -- File Locals
  
--- ======= GLOBALIZE =======
  -- Addon
  AethysCache = Cache;


--- ============================ CONTENT ============================
  -- Defines our cached tables.
  -- Temporary
  Cache.APLVar = {};
  Cache.Enemies = {};
  Cache.EnemiesCount = {};
  Cache.GUIDInfo = {};
  Cache.MiscInfo = {};
  Cache.SpellInfo = {};
  Cache.ItemInfo = {};
  Cache.UnitInfo = {};
  -- Persistent
  Cache.Persistent = {
    Equipment = {},
    Player = {
      Class = {UnitClass("player")},
      Spec = {}
    },
    SpellLearned = {Pet = {}, Player = {}},
    Texture = {Spell = {}, Item = {}, Custom = {}}
  };

  -- Reset the cache
  Cache.HasBeenReset = false;
  function Cache.Reset ()
    if not Cache.HasBeenReset then
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

      Cache.HasBeenReset = true;
    end
  end

  -- Wipe a table while keeping the structure
  -- i.e. wipe every sub-table as long it doesn't contain a table
  function Cache.WipeTableRecursively (Table)
    for Key, Value in pairs(Table) do
      if type(Value) == "table" then
        Cache.WipeTableRecursively(Value);
      else
        wipe(Table);
      end
    end
  end
