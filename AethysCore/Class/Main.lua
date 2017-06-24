--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCache;
  -- Lua
  local error = error;
  local setmetatable = setmetatable;
  local stringformat = string.format;
  -- File Locals
  local Table, MetaTable;
  local Object;


--- ============================ CONTENT ============================
--- ======= PSEUDO-CLASS =======
  -- Defines a Class.
  function AC.Class ()
    Table, MetaTable = {}, {};
    Table.__index = Table;
    MetaTable.__call = function (self, ...)
      Object = {};
      setmetatable(Object, self);
      if Object.Constructor then Object:Constructor(...); end
      return Object;
    end;
    setmetatable(Table, MetaTable);
    return Table;
  end

--- ======= UNIT =======
  -- Defines the Unit Class.
  AC.Unit = AC.Class();
  local Unit = AC.Unit;
  -- Unit Constructor
  function Unit:Constructor (UnitID)
    if type(UnitID) ~= "string" then error("Invalid UnitID."); end
    self.UnitID = UnitID;
  end
  -- Defines Unit Objects.
  -- Unique Units
  Unit.Player = Unit("Player");
  Unit.Pet = Unit("Pet");
  Unit.Target = Unit("Target");
  Unit.Focus = Unit("Focus");
  Unit.MouseOver = Unit("MouseOver");
  Unit.Vehicle = Unit("Vehicle");
  -- Iterable Units
  local UnitIDMap = {
    {"Arena", 5},
    {"Boss", 4},
    {"Nameplate", AC.MAXIMUM},
    {"Party", 5},
    {"Raid", 40}
  };
  for Key, Value in pairs(UnitIDMap) do
    Unit[Value[1]] = {};
    for i = 1, Value[2] do
      Unit[Value[1]][i] = Unit(stringformat("%s%d", Value[1], i));
    end
  end
  UnitIDMap = nil;

--- ======= SPELL =======
  -- Defines the Spell Class.
  AC.Spell = AC.Class();
  local Spell = AC.Spell;
  -- Spell Constructor
  function Spell:Constructor (SpellID, SpellType)
    if type(SpellID) ~= "number" then error("Invalid SpellID."); end
    if SpellType and type(SpellType) ~= "string" then error("Invalid Spell Type."); end
    self.SpellID = SpellID;
    self.SpellType = SpellType or "Player"; -- For Pet, put "Pet". Default is "Player".
    self.LastCastTime = 0;
    self.LastDisplayTime = 0;
    self.LastHitTime = 0;
  end

--- ======= ITEM =======
  -- Defines the Item Class.
  AC.Item = AC.Class();
  local Item = AC.Item;
  -- Item Constructor
  function Item:Constructor (ItemID, ItemSlotID)
    if type(ItemID) ~= "number" then error("Invalid ItemID."); end
    if ItemSlotID and type(ItemSlotID) ~= "table" then error("Invalid ItemSlotID."); end
    self.ItemID = ItemID;
    self.ItemSlotID = ItemSlotID or {0};
    self.LastCastTime = 0;
    self.LastDisplayTime = 0;
    self.LastHitTime = 0;
  end
