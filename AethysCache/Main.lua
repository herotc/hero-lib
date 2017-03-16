--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, Cache = ...;
  -- Lua
  
  -- File Locals
  local CacheIsEnabled = true; -- TODO: Make a settings to disable it (currently not supported).
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

  -- Reset the cache.
  Cache.HasBeenReset = false;
  function Cache.Reset ()
    if not Cache.HasBeenReset then
      -- -- foreach method
      -- for Key, Value in pairs(AC.Cache) do
      --   wipe(AC.Cache[Key]);
      -- end

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

  -- Function to split a string into a table based on a given delimiter.
  local function Splitter (Delimiter, String)
    return {strsplit(Delimiter, String)};
  end
  -- Function to transfrom a string into a number if the string only contains numbers.
  local function TypeCorrecter (Table)
    for i=1, #Table do
      if not string.match(Table[i], "%D") then
        Table[i] = tonumber(Table[i]);
      end
    end
    return Table;
  end
  -- Internal function to fast retrieve a value from the cache (up to a depth level of 7 atm).
  -- It throws an Lua Error if Value doesn't exists (intended) or return the right value if it exists.
  -- Call it with pcall only !
  -- Ex: pcall(function () return CacheGetter(TypeCorrecter(Splitter(".", "SpellInfo.53.CostInfo"))); end)
  -- TODO: Optimize
  local function CacheGetter (Childs)
    local ChildsDepth = #Childs;
    if ChildsDepth == 1 then
      return Cache[Childs[1]];
    elseif ChildsDepth == 2 then
      return Cache[Childs[1]][Childs[2]];
    elseif ChildsDepth == 3 then
      return Cache[Childs[1]][Childs[2]][Childs[3]];
    elseif ChildsDepth == 4 then
      return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]];
    elseif ChildsDepth == 5 then
      return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]];
    elseif ChildsDepth == 6 then
      return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[6]];
    elseif ChildsDepth == 7 then
      return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[6]][Childs[7]];
    end
  end
  -- Internal function to assign a value in the cache (up to a depth level of 7 atm).
  -- TODO: Optimize
  local function CacheSetter (Path, UncachedValue)
    local Childs = TypeCorrecter(Splitter(".", Path));
    local ChildsDepth = #Childs;
    for i=1, ChildsDepth do
      if i == 1 then
        if not Cache[Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[i]] = UncachedValue;
            return Cache[Childs[i]];
          else
            Cache[Childs[i]] = {};
          end
        end
      elseif i == 2 then
        if not Cache[Childs[1]][Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[1]][Childs[i]] = UncachedValue;
            return Cache[Childs[1]][Childs[i]];
          else
            Cache[Childs[1]][Childs[i]] = {};
          end
        end
      elseif i == 3 then
        if not Cache[Childs[1]][Childs[2]][Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[1]][Childs[2]][Childs[i]] = UncachedValue;
            return Cache[Childs[1]][Childs[2]][Childs[i]];
          else
            Cache[Childs[1]][Childs[2]][Childs[i]] = {};
          end
        end
      elseif i == 4 then
        if not Cache[Childs[1]][Childs[2]][Childs[3]][Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[i]] = UncachedValue;
            return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[i]];
          else
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[i]] = {};
          end
        end
      elseif i == 5 then
        if not Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[i]] = UncachedValue;
            return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[i]];
          else
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[i]] = {};
          end
        end
      elseif i == 6 then
        if not Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[i]] = UncachedValue;
            return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[i]];
          else
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[i]] = {};
          end
        end
      elseif i == 7 then
        if not Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[6]][Childs[i]] then
          if i == ChildsDepth then
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[6]][Childs[i]] = UncachedValue;
            return Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[6]][Childs[i]];
          else
            Cache[Childs[1]][Childs[2]][Childs[3]][Childs[4]][Childs[5]][Childs[6]][Childs[i]] = {};
          end
        end
      end
    end
    error("Can't cache two times the same value.");
  end
  -- Public function to try to get a value from the cache from a given path.
  -- Returns the value or false if it's not cached.
  function Cache.Get (Path)
    if CacheIsEnabled then
      local CallSuccessful, Value = pcall(function () return CacheGetter(TypeCorrecter(Splitter(".", Path))); end);
      return CallSuccessful and Value or false;
    else
      return false;
    end
  end
  -- Public function to assign a value in the cache from a given path.
  -- Always returns the UncachedValue (but cache it for future usage with Cache.Get).
  -- Typical usage is : return Cache.Get("SpellInfo.53.CostInfo") or Cache.Set("SpellInfo.53.CostInfo", GetSpellPowerCost(53)[1]);
  function Cache.Set (Path, UncachedValue)
    return CacheIsEnabled and CacheSetter(Path, UncachedValue) or UncachedValue;
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
