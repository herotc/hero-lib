--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid = Unit.Party, Unit.Raid
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local UnitAura = UnitAura -- name, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3, ..., value11
local GetTime = GetTime
-- File Locals



--- ============================ CONTENT ============================
-- Note: BypassRecovery is a common arg of this module because by default, in order to improve the prediction, we take in account the remaining time of the GCD or the current cast (whichever is higher).
--       Although sometimes we might want to ignore this and return the "raw" value, which this arg is for.

-- Get the AuraInfo (from UnitAura).
-- Only returns Stack, Duration, ExpirationTime, Index by default. Except if the Full argument is truthy then it is the UnitAura call that is returned.
function Unit:AuraInfo(ThisSpell, Filter, Full)
  local GUID = self:GUID()
  if not GUID then return end

  local UnitID = self:ID()
  local SpellID = ThisSpell:ID()

  local Index = 1
  while true do
    local _, _, AuraStack, _, AuraDuration, AuraExpirationTime, _, _, _, AuraSpellID = UnitAura(UnitID, Index, Filter)

    -- Returns no value if the aura was not found.
    if not AuraSpellID then return end

    -- Returns the info once we match the spell ids.
    if AuraSpellID == SpellID then
      return (Full and UnitAura(UnitID, Index, Filter)) or AuraStack, AuraDuration, AuraExpirationTime, Index
    end

    Index = Index + 1
  end
end

-- Get the BuffInfo (from AuraInfo).
function Unit:BuffInfo(ThisSpell, AnyCaster, Full)
  local Filter = AnyCaster and "HELPFUL" or "HELPFUL|PLAYER"

  return self:AuraInfo(ThisSpell, Filter, Full)
end

-- buff.foo.stack
function Unit:BuffStack(ThisSpell, AnyCaster, BypassRecovery)
  -- In the case we are using the prediction, we have to check if the buff will still be there before considering its stacks.
  if not BypassRecovery and self:BuffDown(ThisSpell, AnyCaster, BypassRecovery) then return 0 end

  local Stack = self:BuffInfo(ThisSpell, AnyCaster)

  return Stack or 0
end

-- buff.foo.duration
function Unit:BuffDuration(ThisSpell, AnyCaster)
  local _, Duration = self:BuffInfo(ThisSpell, AnyCaster)

  return Duration or 0
end

-- buff.foo.remains
function Unit:BuffRemains(ThisSpell, AnyCaster, BypassRecovery)
  local _, _, ExpirationTime = self:BuffInfo(ThisSpell, AnyCaster)
  if not ExpirationTime then return 0 end
  if ExpirationTime == 0 then return 9999 end

  -- TODO: Why this is here ?
  -- Stealth-like buffs (Subterfurge and Master Assassin) are delayed but within aura latency
  local SpellID = ThisSpell:ID()
  if SpellID == 115192 or SpellID == 256735 then
    ExpirationTime = ExpirationTime - 0.3
  end

  local Remains = ExpirationTime - GetTime() - HL.RecoveryOffset(BypassRecovery)

  return Remains >= 0 and Remains or 0
end

-- buff.foo.up
function Unit:BuffUp(ThisSpell, AnyCaster, BypassRecovery)
  return self:BuffRemains(ThisSpell, AnyCaster, BypassRecovery) > 0
end

-- buff.foo.down
function Unit:BuffDown(ThisSpell, AnyCaster, BypassRecovery)
  return not self:BuffUp(ThisSpell, AnyCaster, BypassRecovery)
end

-- "buff.foo.refreshable" (doesn't exists on SimC), automaticaly calculates the PandemicThreshold from HeroDBC spell data.
function Unit:BuffRefreshable(ThisSpell, AnyCaster, BypassRecovery)
  local PandemicThreshold = ThisSpell:PandemicThreshold()

  return self:BuffRemains(ThisSpell, AnyCaster, BypassRecovery) <= PandemicThreshold
end

-- hot.foo.ticks_remain
function Unit:BuffTicksRemain(ThisSpell, AnyCaster, BypassRecovery)
  local Remains = self:BuffRemains(ThisSpell, AnyCaster, BypassRecovery)
  if Remains == 0 then return 0 end

  return math.ceil(Remains / ThisSpell:TickTime())
end

-- Get the DebuffInfo (from AuraInfo).
function Unit:DebuffInfo(ThisSpell, AnyCaster, Full)
  local Filter = AnyCaster and "HARMFUL" or "HARMFUL|PLAYER"

  return self:AuraInfo(ThisSpell, Filter, Full)
end

-- debuff.foo.stack & dot.foo.stack
function Unit:DebuffStack(ThisSpell, AnyCaster, BypassRecovery)
  -- In the case we are using the prediction, we have to check if the debuff will still be there before considering its stacks.
  if not BypassRecovery and self:DebuffDown(ThisSpell, AnyCaster, BypassRecovery) then return 0 end

  local Stack = self:DebuffInfo(ThisSpell, AnyCaster)

  return Stack or 0
end

-- debuff.foo.duration & dot.foo.duration
function Unit:DebuffDuration(ThisSpell, AnyCaster)
  local _, Duration = self:DebuffInfo(ThisSpell, AnyCaster)

  return Duration or 0
end

-- debuff.foo.remains & dot.foo.remains
function Unit:DebuffRemains(ThisSpell, AnyCaster, BypassRecovery)
  local _, _, ExpirationTime = self:DebuffInfo(ThisSpell, AnyCaster)
  if not ExpirationTime then return 0 end
  if ExpirationTime == 0 then return 9999 end

  local Remains = ExpirationTime - GetTime() - HL.RecoveryOffset(BypassRecovery)

  return Remains >= 0 and Remains or 0
end

-- debuff.foo.up
function Unit:DebuffUp(ThisSpell, AnyCaster, BypassRecovery)
  return self:DebuffRemains(ThisSpell, AnyCaster, BypassRecovery) > 0
end

-- debuff.foo.down
function Unit:DebuffDown(ThisSpell, AnyCaster, BypassRecovery)
  return not self:DebuffUp(ThisSpell, AnyCaster, BypassRecovery)
end

-- debuff.foo.refreshable & dot.foo.refreshable, automaticaly calculates the PandemicThreshold from HeroDBC spell data.
function Unit:DebuffRefreshable(ThisSpell, AnyCaster, BypassRecovery)
  local PandemicThreshold = ThisSpell:PandemicThreshold()

  return self:DebuffRemains(ThisSpell, AnyCaster, BypassRecovery) <= PandemicThreshold
end

-- dot.foo.ticks_remain
function Unit:DebuffTicksRemain(ThisSpell, AnyCaster, BypassRecovery)
  local Remains = self:DebuffRemains(ThisSpell, AnyCaster, BypassRecovery)
  if Remains == 0 then return 0 end

  return math.ceil(Remains / ThisSpell:TickTime())
end


do
  local BloodlustSpells = {
    -- Abilities
    Spell(2825), -- Shaman: Bloodlust (Horde)
    Spell(32182), -- Shaman: Heroism (Alliance)
    Spell(80353), -- Mage:Time Warp
    Spell(90355), -- Hunter: Ancient Hysteria
    Spell(160452), -- Hunter: Netherwinds
    -- Drums
    Spell(35475), -- Drums of War
    Spell(35476), -- Drums of Battle
    Spell(146555), -- Drums of Rage
    Spell(178207), -- Drums of Fury
    Spell(230935), -- Drums of the Mountain
    Spell(256740), -- Drums of the Maelstrom
    Spell(309658), -- Drums of Deathly Ferocity
  }

  -- buff.bloodlust.remains
  function Unit:BloodlustRemains(BypassRecovery)
    local GUID = self:GUID()
    if not GUID then return false end

    for i = 1, #BloodlustSpells do
      local BloodlustSpell = BloodlustSpells[i]
      if self:BuffUp(BloodlustSpell, nil) then
        return self:BuffRemains(BloodlustSpell, nil, BypassRecovery)
      end
    end

    return 0
  end

  -- buff.bloodlust.up
  function Unit:BloodlustUp(BypassRecovery)
    return self:BloodlustRemains(BypassRecovery) > 0
  end

  -- buff.bloodlust.down
  function Unit:BloodlustDown(BypassRecovery)
    return not self:BloodlustUp(BypassRecovery)
  end
end
