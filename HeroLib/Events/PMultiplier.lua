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
local GetTime = GetTime
-- File Locals
local ListenedSpells = {}
local ListenedAuras = {}


--- ============================ CONTENT ============================
-- Register a spell to watch and his multipliers.
-- Examples:
--
--- Buff + Modifier as a function
-- S.Nightblade:RegisterPMultiplier(
--   {
--     S.FinalityNightblade,
--     function ()
--       if not Player:BuffUp(S.FinalityNightblade) then return 1 end
--       local Multiplier = select(17, Player:BuffInfo(S.FinalityNightblade, nil, true))
--
--       return 1 + Multiplier/100
--     end
--   }
-- )
--
--- 3x Buffs & Modifier as a number
-- S.Rip:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15})
-- S.Thrash:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15})
--
--- Different SpellCast & SpellAura + AIO function + 3x Buffs & Modifier as a number
-- S.Rake:RegisterPMultiplier(
--   S.RakeDebuff,
--   function () return Player:StealthUp(true, true) and 2 or 1 end,
--   {S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15}
-- )
function Spell:RegisterPMultiplier(...)
  local Args = { ... }

  -- Get the SpellID to check on AURA_APPLIED/AURA_REFRESH, should be specified as first arg or it'll take the current spell object.
  local SpellAura = self:ID()
  local FirstArg = Args[1]
  if type(FirstArg) == "table" and FirstArg.SpellID then
    SpellAura = table.remove(Args, 1).SpellID
  end

  ListenedAuras[SpellAura] = self.SpellID
  ListenedSpells[self.SpellID] = { Buffs = Args, Units = {} }
end

local function SpellRegisterError(Spell)
  local SpellName = Spell:Name()
  if SpellName then
    return "You forgot to register the spell: " .. SpellName .. " in PMultiplier handler."
  else
    return "You forgot to register the spell object."
  end
end

-- PMultiplier Calculator
local function ComputePMultiplier(ListenedSpell)
  local PMultiplier = 1
  for j = 1, #ListenedSpell.Buffs do
    local Buff = ListenedSpell.Buffs[j]
    -- Check if it's an AIO function and call it.
    if type(Buff) == "function" then
      PMultiplier = PMultiplier * Buff()
    else
      -- Check if we did registered a Buff to check + a modifier (as a number or through a function).
      local ThisSpell = Buff[1]
      local Modifier = Buff[2]

      if Player:BuffUp(ThisSpell) or ThisSpell:TimeSinceLastRemovedOnPlayer() < 0.1 then
        local ModifierType = type(Modifier)

        if ModifierType == "number" then
          PMultiplier = PMultiplier * Modifier
        elseif ModifierType == "function" then
          PMultiplier = PMultiplier * Modifier()
        end
      end
    end
  end

  return PMultiplier
end

-- PMultiplier OnCast Listener
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local ListenedSpell = ListenedSpells[SpellID]
    if not ListenedSpell then return end

    local PMultiplier = ComputePMultiplier(ListenedSpell)
    local Dot = ListenedSpell.Units[DestGUID]
    if Dot then
      Dot.PMultiplier = PMultiplier
      Dot.Time = GetTime()
    else
      ListenedSpell.Units[DestGUID] = { PMultiplier = PMultiplier, Time = GetTime(), Applied = false }
    end
  end,
  "SPELL_CAST_SUCCESS"
)
-- PMultiplier OnApply/OnRefresh Listener
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local ListenedAura = ListenedAuras[SpellID]
    if not ListenedAura then return end

    local ListenedSpell = ListenedSpells[ListenedAura]
    if not ListenedSpell then return end

    local Dot = ListenedSpell.Units[DestGUID]
    if Dot then
      Dot.Applied = true
    else
      ListenedSpell.Units[DestGUID] = { PMultiplier = 0, Time = GetTime(), Applied = true }
    end
  end,
  "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH"
)
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local ListenedAura = ListenedAuras[SpellID]
    if not ListenedAura then return end

    local ListenedSpell = ListenedSpells[ListenedAura]
    if not ListenedSpell then return end

    local Dot = ListenedSpell.Units[DestGUID]
    if Dot then
      Dot.Applied = false
    end
  end,
  "SPELL_AURA_REMOVED"
)
-- PMultiplier OnRemove & OnUnitDeath Listener
HL:RegisterForCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID)
    for _, ListenedSpell in pairs(ListenedSpells) do
      if ListenedSpell.Units[DestGUID] then
        ListenedSpell.Units[DestGUID] = nil
      end
    end
  end,
  "UNIT_DIED", "UNIT_DESTROYED"
)

-- dot.foo.pmultiplier
function Unit:PMultiplier(ThisSpell)
  local ListenedSpell = ListenedSpells[ThisSpell:ID()]
  if not ListenedSpell then error(SpellRegisterError(ThisSpell)) end

  local Units = ListenedSpell.Units
  local Dot = Units[self:GUID()]

  return (Dot and Dot.Applied and Dot.PMultiplier) or 0
end

-- action.foo.persistent_multiplier
function Player:PMultiplier(ThisSpell)
  local ListenedSpell = ListenedSpells[ThisSpell:ID()]
  if not ListenedSpell then error(SpellRegisterError(ThisSpell)) end

  return ComputePMultiplier(ListenedSpell)
end
