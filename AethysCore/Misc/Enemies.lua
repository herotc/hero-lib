--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local pairs = pairs;
  local tableinsert = table.insert;
  local wipe = table.wipe;
  -- File Locals
  local _T = { -- Temporary Vars
    ThisUnit,                 -- GetEnemies
    DistanceValues = {}       -- GetEnemies
  };


--- ============================ CONTENT ============================
  -- Fill the Enemies Cache table.
  function AC.GetEnemies (Distance)
    -- Prevent building the same table if it's already cached.
    if Cache.Enemies[Distance] then return; end
    -- Init the Variables used to build the table.
    Cache.Enemies[Distance] = {};
    -- Check if there is another Enemies table with a greater Distance to filter from it.
    if #Cache.Enemies >= 1 then
      wipe(_T.DistanceValues);
      for Key, Value in pairs(Cache.Enemies) do
        if Key > Distance then
          tableinsert(_T.DistanceValues, Key);
        end
      end
      -- Check if we have caught a table that we can use.
      if #_T.DistanceValues >= 1 then
        if #_T.DistanceValues >= 2 then
          table.sort(_T.DistanceValues, function(a, b) return a < b; end);
        end
        for Key, Value in pairs(Cache.Enemies[_T.DistanceValues[1]]) do
          if Value:IsInRange(Distance) then
            tableinsert(Cache.Enemies[Distance], Value);
          end
        end
        return;
      end
    end
    -- Else build from all the nameplates.
    for i = 1, AC.MAXIMUM do
      _T.ThisUnit = Unit["Nameplate"..tostring(i)];
      if _T.ThisUnit:Exists() and
        not _T.ThisUnit:IsBlacklisted() and
        not _T.ThisUnit:IsUserBlacklisted() and
        not _T.ThisUnit:IsDeadOrGhost() and
        Player:CanAttack(_T.ThisUnit) and
        _T.ThisUnit:IsInRange(Distance) then
        tableinsert(Cache.Enemies[Distance], _T.ThisUnit);
      end
    end
    -- Cache the count of enemies
    Cache.EnemiesCount[Distance] = #Cache.Enemies[Distance];
  end
