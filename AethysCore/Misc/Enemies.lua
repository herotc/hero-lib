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
  local tablesort = table.sort;
  local wipe = table.wipe;
  -- File Locals
  local NameplateUnits = Unit["Nameplate"];


--- ============================ CONTENT ============================
  -- Fill the Enemies Cache table.
  function AC.GetEnemies (Distance)
    -- Prevent building the same table if it's already cached.
    if Cache.Enemies[Distance] then return; end
    -- Init the Variables used to build the table.
    Cache.Enemies[Distance] = {};
    -- Check if there is another Enemies table with a greater Distance to filter from it.
    if #Cache.Enemies >= 1 then
      local DistanceValues = {};
      for Key, Value in pairs(Cache.Enemies) do
        if Key > Distance then
          tableinsert(DistanceValues, Key);
        end
      end
      -- Check if we have caught a table that we can use.
      if #DistanceValues >= 1 then
        if #DistanceValues >= 2 then
          tablesort(DistanceValues, function(a, b) return a < b; end);
        end
        for Key, Value in pairs(Cache.Enemies[DistanceValues[1]]) do
          if Value:IsInRange(Distance) then
            tableinsert(Cache.Enemies[Distance], Value);
          end
        end
        return;
      end
    end
    -- Else build from all the nameplates.
    local ThisUnit;
    for i = 1, #NameplateUnits do
      ThisUnit = NameplateUnits[i];
      if ThisUnit:Exists() and
        not ThisUnit:IsBlacklisted() and
        not ThisUnit:IsUserBlacklisted() and
        not ThisUnit:IsDeadOrGhost() and
        Player:CanAttack(ThisUnit) and
        ThisUnit:IsInRange(Distance) then
        tableinsert(Cache.Enemies[Distance], ThisUnit);
      end
    end
    -- Cache the count of enemies
    Cache.EnemiesCount[Distance] = #Cache.Enemies[Distance];
  end
