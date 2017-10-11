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
  local UnitIDs = {
    "Arena",
    "Boss",
    "Nameplate"
  };


--- ============================ CONTENT ============================
  -- Fill the Enemies Cache table.
  function AC.GetEnemies (Distance, SpellIDStr)
    local Identifier = type(Distance) == "number" and Distance or SpellIDStr;
    -- Prevent building the same table if it's already cached.
    if Cache.Enemies[Identifier] then return; end
    -- Init the Variables used to build the table.
    Cache.Enemies[Identifier] = {};
    -- Check if there is another Enemies table with a greater Distance to filter from it.
    if #Cache.Enemies >= 1 and type(Distance) == "number" then
      local DistanceValues = {};
      for Key, UnitTable in pairs(Cache.Enemies) do
        if type(Key) == "number" and Key > Distance then
          tableinsert(DistanceValues, Key);
        end
      end
      -- Check if we have caught a table that we can use.
      if #DistanceValues >= 1 then
        if #DistanceValues >= 2 then
          tablesort(DistanceValues, function(a, b) return a < b; end);
        end
        for Key, Unit in pairs(Cache.Enemies[DistanceValues[1]]) do
          if Unit:IsInRange(Distance) then
            tableinsert(Cache.Enemies[Identifier], Unit);
          end
        end
        return;
      end
    end
    -- Else build from all the available units.
    local ThisUnit;
    for _, UnitID in pairs(UnitIDs) do
      local Units = Unit[UnitID];
      for _, ThisUnit in pairs(Units) do
        if ThisUnit:Exists() and
          not ThisUnit:IsBlacklisted() and
          not ThisUnit:IsUserBlacklisted() and
          not ThisUnit:IsDeadOrGhost() and
          Player:CanAttack(ThisUnit) and
          ThisUnit:IsInRange(Distance, SpellIDStr) then
          tableinsert(Cache.Enemies[Identifier], ThisUnit);
        end
      end
    end
    -- Cache the count of enemies
    Cache.EnemiesCount[Identifier] = #Cache.Enemies[Identifier];
  end
