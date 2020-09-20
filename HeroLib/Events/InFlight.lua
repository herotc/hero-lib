--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
-- Lua
local pairs = pairs
local C_Timer = C_Timer
local mathmax = math.max
-- File Locals
local TrackedSpells = {}
local EffectMap = {}

--- ============================ CONTENT ============================

function Spell:RegisterInFlightEffect(EffectID)
  self.InFlightEffectID = EffectID
end

function Spell:InFlightEffect()
  return self.InFlightEffectID
end

function Spell:RegisterInFlight(...)
  local Args = { ... }
  local SpellID = self.SpellID

  local TrackedSpell = { Inflight = false, DestGUID = nil, Count = 0, Auras = {} }
  TrackedSpells[SpellID] = TrackedSpell
  for _, AuraSpell in pairs(Args) do
    if AuraSpell:ID() then
      TrackedSpell.Auras[AuraSpell] = false
    end
  end

  local InFlightEffectID = self:InFlightEffect()
  if InFlightEffectID then
    EffectMap[InFlightEffectID] = SpellID
  end
end

HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local TrackedSpell = TrackedSpells[SpellID]
    if not TrackedSpell then return end

    if DestGUID == "" then
      TrackedSpell.DestGUID = Target:GUID()
    else
      TrackedSpell.DestGUID = DestGUID
    end

    TrackedSpell.Inflight = true
    TrackedSpell.Count = TrackedSpell.Count + 1
    for AuraSpell, _ in pairs(TrackedSpell.Auras) do
      TrackedSpell.Auras[AuraSpell] = Player:BuffUp(AuraSpell) or AuraSpell:TimeSinceLastRemovedOnPlayer() < 0.1
    end
  end,
  "SPELL_CAST_SUCCESS"
)

HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local EffectSpellID = EffectMap[SpellID]
    local TrackedSpell = (EffectSpellID and TrackedSpells[EffectSpellID]) or TrackedSpells[SpellID]
    if not TrackedSpell then return end

    if TrackedSpell.DestGUID == DestGUID then
      TrackedSpell.Inflight = false
      TrackedSpell.Count = mathmax(0, TrackedSpell.Count - 1)
    end
  end,
  "SPELL_DAMAGE", "SPELL_MISSED", "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH"
)

-- Prevent InFlight getting stuck when target dies mid-flight
HL:RegisterForCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID)
    for SpellID, _ in pairs(TrackedSpells) do
      local TrackedSpell = TrackedSpells[SpellID]
      if TrackedSpell.DestGUID == DestGUID then
        TrackedSpell.Inflight = false
        TrackedSpell.Count = mathmax(0, TrackedSpell.Count - 1)
      end
    end
  end,
  "UNIT_DIED", "UNIT_DESTROYED"
)

function Spell:InFlight(Aura)
  local TrackedSpell = TrackedSpells[self:ID()]
  if not TrackedSpell then error("You forgot to register " .. self:Name() .. " for InFlight tracking.") end

  if Aura then
    return TrackedSpell.Inflight and TrackedSpell.Auras[Aura]
  end

  return TrackedSpell.Inflight
end
