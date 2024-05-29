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

-- File Locals



--- ============================ CONTENT ============================
-- Get if the unit is stunned or not
local IsStunnedDebuffs = {
  -- Death Knight
  Spell(91797),  -- Monstrous Blow (pet)
  Spell(91800),  -- Gnaw (pet)
  Spell(221562), -- Asphyxiate
  -- Demon Hunter
  Spell(179057), -- Chaos Nova
  Spell(211881), -- Fel Eruption
  -- Druid
  Spell(5211),   -- Mighty Bash
  Spell(22570),  -- Maim
  Spell(163505), -- Rake
  -- Evoker
  Spell(372245), -- Terror of the Skies
  -- Hunter
  Spell(24394),  -- Intimidation (may be an old ID)
  Spell(117526), -- Binding Shot
  -- Monk
  Spell(119381), -- Leg Sweep
  -- Paladin
  Spell(853),    -- Hammer of Justice
  Spell(205290), -- Wake of Ashes
  -- Priest
  Spell(64044),  -- Psychic Horror
  -- Rogue
  Spell(408),    -- Kidney Shot
  Spell(1833),   -- Cheap Shot
  -- Warlock
  Spell(30283),  -- Shadowfury
  -- Warrior
  Spell(46968),  -- Shockwave
  Spell(107570), -- Storm Bolt
}
function Unit:IterateStunDebuffs()
  for i = 1, #IsStunnedDebuffs do
    local IsStunnedDebuff = IsStunnedDebuffs[i]
    if self:DebuffUp(IsStunnedDebuff, nil, true) then
      return true
    end
  end

  return false
end

function Unit:IsStunned()
  local GUID = self:GUID()
  if not GUID then return end

  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end

  local IsStunned = UnitInfo.IsStunned
  if IsStunned == nil then
    IsStunned = self:IterateStunDebuffs()
    UnitInfo.IsStunned = IsStunned
  end

  return IsStunned
end

-- Get if an unit is not immune to stuns
local IsStunnableClassification = {
  ["trivial"] = true,
  ["minus"] = true,
  ["normal"] = true,
  ["rare"] = true,
  ["rareelite"] = false,
  ["elite"] = false,
  ["worldboss"] = false,
  [""] = false
}
function Unit:IsStunnable()
  -- TODO: Add DR Check
  local GUID = self:GUID()
  if not GUID then return end

  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end

  local IsStunnable = UnitInfo.IsStunnable
  if IsStunnable == nil then
    IsStunnable = IsStunnableClassification[self:Classification()]
    UnitInfo.IsStunnable = IsStunnable
  end

  return IsStunnable
end

-- Get if an unit can be stunned or not
function Unit:CanBeStunned(IgnoreClassification)
  return ((IgnoreClassification or self:IsStunnable()) and not self:IsStunned()) or false
end
