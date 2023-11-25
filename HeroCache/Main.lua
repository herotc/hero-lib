--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, Cache = ...;
-- Lua
local wipe = wipe
-- File Locals
if not HeroCacheDB then
  _G.HeroCacheDB = {};
  HeroCacheDB.Enabled = true;
end
--- ======= GLOBALIZE =======
-- Addon
HeroCache = Cache;


--- ============================ CONTENT ============================
-- Defines our cached tables.
-- Temporary
Cache.APLVar = {};
Cache.Enemies = { ItemAction = {}, Melee = {}, Ranged = {}, Spell = {}, SpellAction = {} };
Cache.GUIDInfo = {};
Cache.MiscInfo = {};
Cache.SpellInfo = {};
Cache.ItemInfo = {};
Cache.UnitInfo = {};
-- Persistent
Cache.Persistent = {
  Equipment = {},
  TierSets = {},
  Player = {
    Class = { UnitClass("player") },
    Spec = {}
  },
  BookIndex = { Pet = {}, Player = {} },
  SpellLearned = { Pet = {}, Player = {} },
  RangeSpells = { HostileIndex = {}, FriendlyIndex = {}, HostileSpells = {}, MinRangeSpells = {}, FriendlySpells = {} },
  Texture = { Spell = {}, Item = {}, Custom = {} },
  ElvUIPaging = { PagingString, PagingStrings = {}, PagingBars = {} },
  Talents = { Rank }
};

-- Reset the cache.
Cache.HasBeenReset = false;
function Cache.Reset()
  if not Cache.HasBeenReset then
    wipe(Cache.APLVar);
    wipe(Cache.Enemies.ItemAction);
    wipe(Cache.Enemies.Melee);
    wipe(Cache.Enemies.Ranged);
    wipe(Cache.Enemies.Spell);
    wipe(Cache.Enemies.SpellAction);
    wipe(Cache.GUIDInfo);
    wipe(Cache.MiscInfo);
    wipe(Cache.SpellInfo);
    wipe(Cache.ItemInfo);
    wipe(Cache.UnitInfo);

    Cache.HasBeenReset = true;
  end
end

local MakeCache
do
  local select = select

  local function makeArgs(n)
    local args = {}
    for i = 1, n do
      args[i] = string.format("a%d", i)
    end
    return args
  end

  local function makeInitString(args, start)
    local n = #args
    local t = {}
    for i = start, n - 1 do
      t[#t + 1] = '[' .. args[i] .. '] = { '
    end
    t[#t + 1] = '[' .. args[n] .. '] = val'
    for i = start, n - 1 do
      t[#t + 1] = ' }'
    end
    return table.concat(t)
  end

  local function makeGetter(n)
    -- special case for 1 depth args
    if n == 1 then
      return "return function(arg) return cache[arg] end"
    end

    local args = makeArgs(n)
    local checks = {}
    for i = 1, n - 1 do
      checks[i] = string.format("local c%d = c%d[%s] if not c%d then return nil end",
        i, i - 1, args[i], i)
    end

    return string.format([=[
return function(%s)
  local c0 = cache
  %s
  return c%d[%s]
end]=],
      table.concat(args, ','),
      table.concat(checks, '\n  '),
      n - 1, args[#args])
  end

  local function makeSetter(n)
    -- special case for 1 depth args
    if n == 1 then
      return "return function(val, arg) cache[arg] = val return val end"
    end

    local args = makeArgs(n)
    local initializers = {}
    for i = 1, n - 1 do
      initializers[i] = string.format("local c%d = c%d[%s] if not c%d then c%d[%s] = { %s } return val end",
        i, i - 1, args[i], i, i - 1, args[i], makeInitString(args, i + 1))
    end

    return string.format([=[
return function(val, %s)
  local c0 = cache
  %s
  c%d[%s] = val
  return val
end]=],
      table.concat(args, ','),
      table.concat(initializers, '\n  '),
      n - 1, args[#args])
  end

  local function makeGetSetter(n)
    local args = makeArgs(n)
    local initializers = {}
    for i = 1, n - 1 do
      initializers[i] = string.format("local c%d = c%d[%s] if not c%d then local val = func() c%d[%s] = { %s } return val end",
        i, i - 1, args[i], i, i - 1, args[i], makeInitString(args, i + 1))
    end

    return string.format([=[
return function(func, %s)
  local c0 = cache
  %s
  local val = c%d[%s]
  if val == nil then
    val = func()
    c%d[%s] = val
  end
  return val
end]=],
      table.concat(args, ','),
      table.concat(initializers, '\n  '),
      n - 1, args[#args], n - 1, args[#args])
  end

  local function initGlobal(func)
    return setmetatable({}, {
      __index = function(tbl, key)
        tbl[key] = loadstring(func(key))
        return tbl[key]
      end
    })
  end

  -- 'global' arrays containing laodstring()ed functions
  local cacheGetters = initGlobal(makeGetter)
  local cacheSetters = initGlobal(makeSetter)
  local cacheGetSetters = initGlobal(makeGetSetter)

  --[[
    Main cache creation function
    Returns a table with 3 functions:

      Get(...)
        Returns the value or nil if it's not cached

      Set(..., val)
        Sets the value at given path to @val, returns @val

      GetSet(..., [func])
        Special getter that can also *set* the value if it's nil, calling @func in the process (lazily)
        The behavior is triggered only if the last argument to it is a function, works as Get otherwise

    Calling
      .Set('A', 'B', 2, 'C', 42)
    is basically equivalent to
      cache['A']['B'][2]['C'] = 42
    which creates tables as needed

    Typical usage is:
      .GetSet('A', 53, 'B',
              function() return GetSpellPowerCost(53)[1] end)
    which will return the value if it's cached and lazily initialize it if it's not
  ]]
  MakeCache = function(cache)
    local function init(proto)
      local function makeFunc(n)
        local func = proto[n]
        setfenv(func, { ['cache'] = cache })
        return select(2, pcall(func))
      end

      local map = {}
      -- prepopulate the map with the first 7 integer keys so they go
      -- into the array part of the table
      for i = 1, 7 do
        map[#map + 1] = makeFunc(i)
      end
      return setmetatable(map, {
        __index = function(tbl, key)
          tbl[key] = makeFunc(key)
          return tbl[key]
        end
      })
    end

    local getters = init(cacheGetters)
    local setters = init(cacheSetters)
    local getsetters = init(cacheGetSetters)
    return {
      Get = function(...)
        return getters[select('#', ...)](...)
      end,
      Set = function(...)
        local n = select('#', ...)
        assert(n > 1, "setter expects at least 2 parameters")
        return setters[n - 1](select(n, ...), ...)
      end,
      GetSet = function(...)
        local n = select('#', ...)
        local last = select(n, ...)
        if n > 1 and type(last) == 'function' then
          return getsetters[n - 1](last, ...)
        else
          return getters[n](...)
        end
      end,
    }
  end
end

local CacheImpl = MakeCache(Cache)

-- Public function to try to get a value from the cache from a given path.
-- Returns the value or nil if it's not cached.
-- If the last argument is a function then the value is set to its return if it's nil.
-- Typical usage is:
--    return Cache.Get("SpellInfo", 53, "CostTable") -- if you need only the cached value
--    return Cache.Get("SpellInfo", 53, "CostTable",
--                     function() return GetSpellPowerCost(53)[1] end) -- if you have a "fallback" value
function Cache.Get(...)
  if HeroCacheDB.Enabled then
    return CacheImpl.GetSet(...)
  else
    local last = select(select('#', ...), ...)
    if type(last) == 'function' then
      return last()
    else
      return nil
    end
  end
end

-- Public function to assign a value in the cache from a given path.
-- Always returns the UncachedValue (but cache it for future usage with Cache.Get).
-- Typical usage is : return Cache.Set("SpellInfo", 53, "CostTable", GetSpellPowerCost(53)[1]);
function Cache.Set(...)
  return HeroCacheDB.Enabled and CacheImpl.Set(...) or select(select('#', ...), ...)
end
