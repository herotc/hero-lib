--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL          = ...
-- HeroLib
local Cache, Utils           = HeroCache, HL.Utils
local Unit                   = HL.Unit
local Player, Pet, Target    = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver       = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid            = Unit.Party, Unit.Raid
local Spell                  = HL.Spell
local Item                   = HL.Item

-- Lua locals
local pairs                  = pairs
local tableinsert            = table.insert
local tablesort              = table.sort

-- File Locals
local ItemActionEnemies      = Cache.Enemies.ItemAction
local MeleeEnemies           = Cache.Enemies.Melee
local RangedEnemies          = Cache.Enemies.Ranged
local SpellActionEnemies     = Cache.Enemies.SpellAction
local SpellEnemies           = Cache.Enemies.Spell
local UnitIDs = {
  "Arena",
  "Boss",
  "Nameplate"
}


--- ============================ CONTENT ============================
local function InsertAvailableUnits(EnemiesTable, RangeCheck)
  local InsertedUnits = {} -- Avoid inserting multiple times the unit (ex: if it's both a Boss unit and a Nameplate unit).
  for _, UnitID in pairs(UnitIDs) do
    local Units = Unit[UnitID]
    for _, ThisUnit in pairs(Units) do
      local GUID = ThisUnit:GUID()
      if not InsertedUnits[GUID] and ThisUnit:Exists() and not ThisUnit:IsBlacklisted() and not ThisUnit:IsUserBlacklisted()
        and not ThisUnit:IsDeadOrGhost() and Player:CanAttack(ThisUnit) and RangeCheck(ThisUnit) then
        tableinsert(EnemiesTable, ThisUnit)
        InsertedUnits[GUID] = true
      end
    end
  end
end

-- Get the enemies in given range of the player.
do
  -- Memoize RangeCheck functions.
  local RangeCheckByRadius = {}

  function Player:GetEnemiesInRange(Radius)
    local Enemies = RangedEnemies

    -- Prevent building the same table if it's already cached.
    if Enemies[Radius] then return Enemies[Radius] end

    -- Init the Variables used to build the table.
    local EnemiesTable = {}
    Enemies[Radius] = EnemiesTable

    -- Check if there is another Enemies table with a greater Radius to filter from it.
    if #Enemies >= 1 then
      local Radiuses = {}
      -- Iterate over the existing enemies table in order to save the tables with a greater radius
      for Key, _ in pairs(Enemies) do
        if Key >= Radius then tableinsert(Radiuses, Key) end
      end
      -- Check if we have caught a table that we can use.
      if #Radiuses >= 1 then
        -- Sort the ranges in ASC order.
        if #Radiuses >= 2 then tablesort(Radiuses, Utils.SortASC) end
        -- Take the closest range from the Radius and filter from it
        for _, ThisUnit in pairs(Enemies[Radiuses[1]]) do
          if ThisUnit:IsInRange(Radius) then tableinsert(EnemiesTable, Unit) end
        end

        return EnemiesTable
      end
    end

    -- Else build from all the available units.
    local RangeCheck = RangeCheckByRadius[Radius]
    if not RangeCheck then
      RangeCheck = function (ThisUnit) return ThisUnit:IsInRange(Radius) end
      RangeCheckByRadius[Radius] = RangeCheck
    end
    InsertAvailableUnits(EnemiesTable, RangeCheck)

    return EnemiesTable
  end
end

-- Get the enemies in melee range of the player.
do
  -- Memoize RangeCheck functions.
  local RangeCheckByRadius = {}

  function Player:GetEnemiesInMeleeRange(Radius)
    local Enemies = MeleeEnemies

    -- Prevent building the same table if it's already cached.
    if Enemies[Radius] then return Enemies[Radius] end

    -- Init the Variables used to build the table.
    local EnemiesTable = {}
    Enemies[Radius] = EnemiesTable

    -- Build from all the available units.
    local RangeCheck = RangeCheckByRadius[Radius]
    if not RangeCheck then
      RangeCheck = function (ThisUnit) return ThisUnit:IsInMeleeRange(Radius) end
      RangeCheckByRadius[Radius] = RangeCheck
    end
    InsertAvailableUnits(EnemiesTable, RangeCheck)

    return EnemiesTable
  end
end

-- Get the enemies in spell's range of the player (works only for targeted spells).
do
  -- Memoize RangeCheck functions.
  local RangeCheckByIdentifier = {}

  function Player:GetEnemiesInSpellRange(ThisSpell)
    local Identifier = ThisSpell.SpellID
    local Enemies = SpellEnemies

    -- Prevent building the same table if it's already cached.
    if Enemies[Identifier] then return Enemies[Identifier] end

    -- Init the Variables used to build the table.
    local EnemiesTable = {}
    Enemies[Identifier] = EnemiesTable

    -- Build from all the available units.
    local RangeCheck = RangeCheckByIdentifier[Identifier]
    if not RangeCheck then
      RangeCheck = function (ThisUnit) return ThisUnit:IsSpellInRange(ThisSpell) end
      RangeCheckByIdentifier[Identifier] = RangeCheck
    end
    InsertAvailableUnits(EnemiesTable, RangeCheck)

    return EnemiesTable
  end
end

-- Get the enemies in action's range of the player (works only for targeted items).
-- Note: The item has to be in the action bars.
do
  -- Memoize RangeCheck functions.
  local RangeCheckByIdentifier = {}

  function Player:GetEnemiesInItemActionRange(ThisItem)
    local Identifier = ThisItem.ItemID
    local Enemies = ItemActionEnemies

    -- Prevent building the same table if it's already cached.
    if Enemies[Identifier] then return Enemies[Identifier] end

    -- Init the Variables used to build the table.
    local EnemiesTable = {}
    Enemies[Identifier] = EnemiesTable

    -- Build from all the available units.
    local RangeCheck = RangeCheckByIdentifier[Identifier]
    if not RangeCheck then
      RangeCheck = function (ThisUnit) return ThisUnit:IsItemInActionRange(ThisItem) end
      RangeCheckByIdentifier[Identifier] = RangeCheck
    end
    InsertAvailableUnits(EnemiesTable, RangeCheck)

    return EnemiesTable
  end
end

-- Get the enemies in action's range of the player (works only for targeted spells).
-- Note: The spell has to be in the action bars.
do
  -- Memoize RangeCheck functions.
  local RangeCheckByIdentifier = {}

  function Player:GetEnemiesInSpellActionRange(ThisSpell)
    local Identifier = ThisSpell.SpellID
    local Enemies = SpellActionEnemies

    -- Prevent building the same table if it's already cached.
    if Enemies[Identifier] then return Enemies[Identifier] end

    -- Init the Variables used to build the table.
    local EnemiesTable = {}
    Enemies[Identifier] = EnemiesTable

    -- Build from all the available units.
    local RangeCheck = RangeCheckByIdentifier[Identifier]
    if not RangeCheck then
      RangeCheck = function (ThisUnit) return ThisUnit:IsSpellInActionRange(ThisSpell) end
      RangeCheckByIdentifier[Identifier] = RangeCheck
    end
    InsertAvailableUnits(EnemiesTable, RangeCheck)

    return EnemiesTable
  end
end
