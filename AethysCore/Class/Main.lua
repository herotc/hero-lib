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
  local function Class ()
    local Class = {};
    Class.__index = Class;
    setmetatable( Class, { __call =
      function ( self, ... )
        local Object = {};
        setmetatable( Object, self );
        Object:New( ... );
        return Object;
      end
    } );
    return Class;
  end

--- ======= UNIT =======
do
  local Unit = Class();
  AC.Unit = Unit;
  function Unit:New ( UnitID )
    if type( UnitID ) ~= "string" then error( "Invalid UnitID." ); end
    self.UnitID = UnitID;
  end
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
    local UnitType = UnitID[ 1 ];
    local UnitCount = UnitID[ 2 ];
    Unit[ UnitType ] = {};
    for i = 1, UnitCount do
      Unit[ UnitType ][ i ] = Unit( stringformat( "%s%d", UnitType, i ) );
    end
  end
end

--- ======= SPELL =======
do
  local Spell = Class();
  AC.Spell = Spell;
  function Spell:New ( SpellID, SpellType )
    if type( SpellID ) ~= "number" then error( "Invalid SpellID." ); end
    if SpellType and type( SpellType ) ~= "string" then error( "Invalid Spell Type." ); end
    self.SpellID = SpellID;
    self.SpellType = SpellType or "Player"; -- For Pet, put "Pet". Default is "Player".
    self.LastCastTime = 0;
    self.LastDisplayTime = 0;
    self.LastHitTime = 0;
    self.LastBuffTime = 0;
  end
end

--- ======= ITEM =======
do
  local Item = Class();
  AC.Item = Item;
  function Item:New ( ItemID, ItemSlotID )
    if type( ItemID ) ~= "number" then error( "Invalid ItemID." ); end
    if ItemSlotID and type( ItemSlotID ) ~= "table" then error( "Invalid ItemSlotID." ); end
    self.ItemID = ItemID;
    self.ItemSlotID = ItemSlotID or { 0 };
    self.LastCastTime = 0;
    self.LastDisplayTime = 0;
    self.LastHitTime = 0;
  end
end
