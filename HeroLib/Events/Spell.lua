--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL          = ...
-- HeroLib
local Cache                  = HeroCache
local Unit                   = HL.Unit
local Player                 = Unit.Player
local Pet                    = Unit.Pet
local Target                 = Unit.Target
local Spell                  = HL.Spell
local MultiSpell             = HL.MultiSpell
local Item                   = HL.Item

-- Lua locals
local pairs                  = pairs
local ipairs                 = ipairs
local tableinsert            = table.insert
local GetTime                = GetTime

-- File Locals
local PlayerSpecs            = {}
local ListenedSpells         = {}
local ListenedItemSpells     = {}
local ListenedSpecItemSpells = {}
local MultiSpells            = {}
local Custom = {
  Whitelist = {},
  Blacklist = {}
}


--- ============================ CONTENT ============================

-- Player On Cast Success Listener
do
  local ListenedSpell
  HL:RegisterForSelfCombatEvent(
    function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID]
        if ListenedSpell then
          ListenedSpell.LastCastTime = GetTime()
          ListenedSpell.LastHitTime = GetTime() + ListenedSpell:TravelTime()
        end
      end
      ListenedSpell = ListenedItemSpells[SpellID]
      if ListenedSpell then
        ListenedSpell.LastCastTime = GetTime()
      end
      ListenedSpell = ListenedSpecItemSpells[SpellID]
      if ListenedSpell then
        ListenedSpell.LastCastTime = GetTime()
      end
    end,
    "SPELL_CAST_SUCCESS"
  )
end

-- Pet On Cast Success Listener
do
  local ListenedSpell
  HL:RegisterForPetCombatEvent(
    function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID]
        if ListenedSpell then
          ListenedSpell.LastCastTime = GetTime()
          ListenedSpell.LastHitTime = GetTime() + ListenedSpell:TravelTime()
        end
      end
    end,
    "SPELL_CAST_SUCCESS"
  )
end

-- Player Aura Applied Listener
do
  local ListenedSpell
  HL:RegisterForSelfCombatEvent(
    function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID]
        if ListenedSpell then
          ListenedSpell.LastAppliedOnPlayerTime = GetTime()
        end
      end
    end,
    "SPELL_AURA_APPLIED"
  )
end

-- Player Aura Removed Listener
do
  local ListenedSpell
  HL:RegisterForSelfCombatEvent(
    function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID]
        if ListenedSpell then
          ListenedSpell.LastRemovedFromPlayerTime = GetTime()
        end
      end
    end,
    "SPELL_AURA_REMOVED"
  )
end

-- Add spells in the Listened Spells Whitelist
function Player:RegisterListenedItemSpells()
  ListenedItemSpells = {}
  local UsableItems = self:GetOnUseItems()
  for _, Item in ipairs(UsableItems) do
    local Spell = Item:OnUseSpell()
    if Spell then
      -- HL.Print("Listening to spell " .. Spell:ID() .. " for item " .. TrinketItem:Name() )
      ListenedItemSpells[Spell:ID()] = Spell
    end
  end
end

-- Register spells to listen for a given class (based on SpecID).
function Player:RegisterListenedSpells(SpecID)
  PlayerSpecs = {}
  ListenedSpells = {}
  ListenedSpecItemSpells = {}
  local PlayerClass = HL.SpecID_ClassesSpecs[SpecID][1]
  -- Fetch registered spells during the init
  for Spec, Spells in pairs(HL.Spell[PlayerClass]) do
    tableinsert(PlayerSpecs, Spec)
    ListenedSpells[Spec] = {}
    for _, Spell in pairs(Spells) do
      ListenedSpells[Spec][Spell:ID()] = Spell
    end
  end
  -- Add Spells based on the Whitelist
  for SpellID, Spell in pairs(Custom.Whitelist) do
    for i = 1, #PlayerSpecs do
      ListenedSpells[PlayerSpecs[i]][SpellID] = Spell
    end
  end
  -- Remove Spells based on the Blacklist
  for i = 1, #Custom.Blacklist do
    local SpellID = Custom.Blacklist[i]
    for k = 1, #PlayerSpecs do
      local Spec = PlayerSpecs[k]
      if ListenedSpells[Spec][SpellID] then
        ListenedSpells[Spec][SpellID] = nil
      end
    end
  end
  -- Re-scan equipped Item spells after module initialization
  if HL.Item[PlayerClass] then
    for Spec, Items in pairs(HL.Item[PlayerClass]) do
      for _, Item in pairs(Items) do
        local Spell = Item:OnUseSpell()
        if Spell then
          -- HL.Print("Listening to spell " .. Spell:ID() .. " for spec item " .. Item:Name() )
          ListenedSpecItemSpells[Spell:ID()] = Spell
        end
      end
    end
  end
end

-- Add spells in the Listened Spells Whitelist
function Spell:AddToListenedSpells()
  Custom.Whitelist[self.SpellID] = self
end

-- Add spells in the Listened Spells Blacklist
function Spell:RemoveFromListenedSpells()
  tableinsert(Custom.Blacklist, self.SpellID)
end

function MultiSpell:AddToMultiSpells()
  tableinsert(MultiSpells, self)
end

HL:RegisterForEvent(
  function(Event, Arg1)
    for _, ThisMultiSpell in pairs(MultiSpells) do
      ThisMultiSpell:Update()
    end
  end,
  "PLAYER_LOGIN", "SPELLS_CHANGED"
)
