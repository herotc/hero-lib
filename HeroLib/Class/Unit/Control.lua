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
  -- Demon Hunter
  -- Druid
  -- General
  Spell(5211), -- Mighty Bash
  -- Feral
  Spell(203123), -- Maim
  Spell(163505), -- Rake
  -- Paladin
  -- General
  Spell(853), -- Hammer of Justice
  -- Retribution
  Spell(205290), -- Wake of Ashes
  -- Rogue
  -- General
  Spell(199804), -- Between the Eyes
  Spell(1833), -- Cheap Shot
  Spell(408), -- Kidney Shot
  Spell(196958), -- Strike from the Shadows
  -- Warrior
  -- General
  Spell(132168), -- Shockwave
  Spell(132169), -- Storm Bolt
}
function Unit:IterateStunDebuffs()
  for i = 1, #IsStunnedDebuffs do
    local IsStunnedDebuff = IsStunnedDebuffs[i]
    if self:Debuff(IsStunnedDebuff, nil, true) then
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
