--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Pet = Unit.Pet
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local pairs = pairs
local tableinsert = table.insert
-- File Locals
local ListenedSpells = {}
local ListenedAuras = {}


--- ============================ CONTENT ============================

-- PMultiplier Calculator
local function ComputePMultiplier(ListenedSpell)
  local PMultiplier = 1
  for j = 1, #ListenedSpell.Buffs do
    local Buff = ListenedSpell.Buffs[j]
    local Spell = Buff[1]
    local Modifier = Buff[2]
    -- Check if we did registered a Buff to check + a modifier (as a number or through a function).
    if Modifier then
      if Player:Buff(Spell) or Spell:TimeSinceLastRemovedOnPlayer() < 0.1 then
        local ModifierType = type(Modifier)
        if ModifierType == "number" then
          PMultiplier = PMultiplier * Modifier
        elseif ModifierType == "function" then
          PMultiplier = PMultiplier * Modifier()
        end
      end
    else
      -- If there is only one element, then check if it's an AIO function and call it.
      if type(Spell) == "function" then
        PMultiplier = PMultiplier * Spell()
      end
    end
  end
  return PMultiplier
end

-- PMultiplier OnCast Listener
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
  local ListenedSpell = ListenedSpells[SpellID]
  if ListenedSpell then
    local PMultiplier = ComputePMultiplier(ListenedSpell)
    ListenedSpell.PMultiplier[DestGUID] = { PMultiplier = PMultiplier, Time = HL.GetTime(), Applied = false }
  end
end, "SPELL_CAST_SUCCESS")
-- PMultiplier OnApply/OnRefresh Listener
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
  local ListenedAura = ListenedAuras[SpellID]
  if ListenedAura then
    local ListenedSpell = ListenedSpells[ListenedAura]
    if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
      ListenedSpell.PMultiplier[DestGUID].Applied = true
    end
  end
end, "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH")
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
  local ListenedAura = ListenedAuras[SpellID]
  if ListenedAura then
    local ListenedSpell = ListenedSpells[ListenedAura]
    if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
      ListenedSpell.PMultiplier[DestGUID] = nil
    end
  end
end, "SPELL_AURA_REMOVED")
-- PMultiplier OnRemove & OnUnitDeath Listener
HL:RegisterForCombatEvent(function(_, _, _, _, _, _, _, DestGUID)
  for SpellID, Spell in pairs(ListenedSpells) do
    if Spell.PMultiplier[DestGUID] then
      Spell.PMultiplier[DestGUID] = nil
    end
  end
end, "UNIT_DIED", "UNIT_DESTROYED")

-- Register a spell to watch and his multipliers.
-- Examples:
--- Buff + Modifier as a function
-- S.Nightblade:RegisterPMultiplier({S.FinalityNightblade,
-- function ()
-- return Player:Buff(S.FinalityNightblade, 17) and 1 + Player:Buff(S.FinalityNightblade, 17)/100 or 1
-- end}
-- )
--- 3x Buffs & Modifier as a number
-- S.Rip:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15})
-- S.Thrash:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15})
--- Different SpellCast & SpellAura + AIO function + 3x Buffs & Modifier as a number
-- S.Rake:RegisterPMultiplier(
-- S.RakeDebuff,
-- {function ()
-- return Player:IsStealthed(true, true) and 2 or 1
-- end},
-- {S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15}
-- )
function Spell:RegisterPMultiplier(...)
  local Args = { ... }

  -- Get the SpellID to check on AURA_APPLIED/AURA_REFRESH, should be specified as first arg or it'll take the current spell object.
  local SpellAura = self.SpellID
  if Args[1].SpellID then
    SpellAura = table.remove(Args, 1)
  end

  ListenedAuras[SpellAura] = self.SpellID
  ListenedSpells[self.SpellID] = { Buffs = Args, PMultiplier = {} }
end

local function SpellRegisterError(Spell)
  local SpellName = Spell:Name()
  if SpellName then
    return "You forgot to register the spell: " .. SpellName .. " in PMultiplier handler."
  else
    return "You forgot to register the spell object."
  end
end

-- dot.foo.pmultiplier
function Unit:PMultiplier(Spell)
  if ListenedSpells[Spell.SpellID].PMultiplier then
    local UnitDot = ListenedSpells[Spell.SpellID].PMultiplier[self:GUID()]
    return UnitDot and UnitDot.Applied and UnitDot.PMultiplier or 0
  else
    error(SpellRegisterError(Spell))
  end
end

-- action.foo.persistent_multiplier
function Player:PMultiplier(Spell)
  local ListenedSpell = ListenedSpells[Spell.SpellID]
  if ListenedSpell then
    return ComputePMultiplier(ListenedSpell)
  else
    error(SpellRegisterError(Spell))
  end
end
