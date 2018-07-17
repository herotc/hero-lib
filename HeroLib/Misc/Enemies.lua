--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, HL = ...;
  -- HeroLib
  local Cache, Utils = HeroCache, HL.Utils;
  local Unit = HL.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = HL.Spell;
  local Item = HL.Item;
  -- Lua
  local pairs = pairs;
  local tableinsert = table.insert;
  local tablesort = table.sort;
  local wipe = table.wipe;
  -- File Locals
  local Enemies = Cache.Enemies;
  local UnitIDs = {
    "Arena",
    "Boss",
    "Nameplate"
  };


--- ============================ CONTENT ============================
  -- Fill the Enemies Cache table.
  function HL.GetEnemies ( Distance, AoESpell )
    local DistanceType, Identifier = type(Distance), nil;
    -- Regular ranged distance check through IsItemInRange & Special distance check (like melee)
    if DistanceType == "number" or (DistanceType == "string" and Distance == 'Melee') then
      Identifier = Distance;
    -- Distance check through IsSpellInRange (works only for targeted spells only)
    elseif DistanceType == "table" then
      Identifier = tostring(Distance:ID());
    else
      error( "Invalid Distance." );
    end
    -- Prevent building the same table if it's already cached.
    if Enemies[Identifier] then return; end
    -- Init the Variables used to build the table.
    local EnemiesTable = {};
    Enemies[Identifier] = EnemiesTable;
    -- Check if there is another Enemies table with a greater Distance to filter from it.
    if #Enemies >= 1 and type(Distance) == "number" then
      local DistanceValues = {};
      for Key, UnitTable in pairs(Enemies) do
        if type(Key) == "number" and Key >= Distance then
          tableinsert(DistanceValues, Key);
        end
      end
      -- Check if we have caught a table that we can use.
      if #DistanceValues >= 1 then
        if #DistanceValues >= 2 then
          tablesort(DistanceValues, Utils.SortASC);
        end
        for Key, Unit in pairs(Enemies[DistanceValues[1]]) do
          if Unit:IsInRange(Distance, AoESpell) then
            tableinsert(EnemiesTable, Unit);
          end
        end
        return;
      end
    end
    -- Else build from all the available units.
    local ThisUnit;
    local InsertedUnits = {};
    for _, UnitID in pairs(UnitIDs) do
      local Units = Unit[UnitID];
      for _, ThisUnit in pairs(Units) do
        local GUID = ThisUnit:GUID();
        if not InsertedUnits[GUID] and ThisUnit:Exists() and not ThisUnit:IsBlacklisted()
          and not ThisUnit:IsUserBlacklisted() and not ThisUnit:IsDeadOrGhost() and Player:CanAttack(ThisUnit)
          and ThisUnit:IsInRange(Distance, AoESpell) then
          tableinsert(EnemiesTable, ThisUnit);
          InsertedUnits[GUID] = true;
        end
      end
    end
    -- Cache the count of enemies
    Cache.EnemiesCount[Identifier] = #EnemiesTable;
  end
