--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCore_Cache;
  -- Lua
  local error = error;
  local setmetatable = setmetatable;
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
  Unit.Player = Unit("Player");
  Unit.Pet = Unit("Pet");
  Unit.Target = Unit("Target");
  Unit.Focus = Unit("Focus");
  Unit.MouseOver = Unit("MouseOver");
  Unit.Vehicle = Unit("Vehicle");
  -- TODO: Make a map containing all UnitId that have multiple possiblites + the possibilites then a master for loop checking this
  -- Something like { {"Nameplate", 40}, {"Boss", 4}, {"Arena", 5}, ....}
  for i = 1, AC.MAXIMUM do
    Unit["Nameplate"..tostring(i)] = Unit("Nameplate"..tostring(i));
  end
  for i = 1, 4 do
    Unit["Boss"..tostring(i)] = Unit("Boss"..tostring(i));
  end

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
  end
