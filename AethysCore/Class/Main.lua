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
  


--- ============================ CONTENT ============================
--- ======= PSEUDO-CLASS =======
  -- Defines a Class.
  local function NewInstance ( self, ... )
    local Object = {};
    setmetatable( Object, self );
    Object:Constructor( ... );
    return Object;
  end
  function AC.Class ()
    local Class = {};
    Class.__index = Class;
    setmetatable( Class, { __call = NewInstance } );
    return Class;
  end
  local Class = AC.Class;

--- ======= UNIT =======
  -- Defines the Unit Class.
  AC.Unit = Class();
  local Unit = AC.Unit;
  -- Unit Constructor
  function Unit:Constructor ( UnitID )
    if type( UnitID ) ~= "string" then error( "Invalid UnitID." ); end
    self.UnitID = UnitID;
  end
  -- Defines Unit Objects.
  -- Unique Units
  Unit.Player = Unit( "Player" );
  Unit.Pet = Unit( "Pet" );
  Unit.Target = Unit( "Target" );
  Unit.Focus = Unit( "Focus" );
  Unit.MouseOver = Unit( "MouseOver" );
  Unit.Vehicle = Unit( "Vehicle" );
  -- Iterable Units
  local UnitIDs = {
    { "Arena", 5 },
    { "Boss", 4 },
    { "Nameplate", AC.MAXIMUM },
    { "Party", 5 },
    { "Raid", 40 }
  };
  for _, UnitID in pairs( UnitIDs ) do
    local UnitType = UnitID[1];
    local UnitCount = UnitID[2];
    Unit[ UnitType ] = {};
    for i = 1, UnitCount do
      Unit[ UnitType ][ i ] = Unit( stringformat( "%s%d", UnitType, i) );
    end
  end
  UnitIDs = nil;

--- ======= SPELL =======
  -- Defines the Spell Class.
  AC.Spell = Class();
  local Spell = AC.Spell;
  -- Spell Constructor
  function Spell:Constructor ( SpellID, SpellType )
    if type( SpellID ) ~= "number" then error( "Invalid SpellID." ); end
    if SpellType and type( SpellType ) ~= "string" then error( "Invalid Spell Type." ); end
    self.SpellID = SpellID;
    self.SpellType = SpellType or "Player"; -- For Pet, put "Pet". Default is "Player".
    self.LastCastTime = 0;
    self.LastDisplayTime = 0;
    self.LastHitTime = 0;
    self.LastBuffTime = 0;
  end

--- ======= ITEM =======
  -- Defines the Item Class.
  AC.Item = Class();
  local Item = AC.Item;
  -- Item Constructor
  function Item:Constructor ( ItemID, ItemSlotID )
    if type( ItemID ) ~= "number" then error( "Invalid ItemID." ); end
    if ItemSlotID and type( ItemSlotID ) ~= "table" then error( "Invalid ItemSlotID." ); end
    self.ItemID = ItemID;
    self.ItemSlotID = ItemSlotID or {0};
    self.LastCastTime = 0;
    self.LastDisplayTime = 0;
    self.LastHitTime = 0;
  end
