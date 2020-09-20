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
local GetPowerRegen = GetPowerRegen
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
-- File Locals



--- ============================ CONTENT ============================
-- Get the unit's power type
function Unit:PowerType()
  local UnitID = self:ID()

  return UnitPowerType(UnitID)
end

-- power.max
function Unit:PowerMax()
  local UnitID = self:ID()

  return UnitPowerMax(UnitID, self:PowerType())
end

-- power
function Unit:Power()
  local UnitID = self:ID()

  return UnitPower(UnitID, self:PowerType())
end

-- power.regen
function Unit:PowerRegen()
  local UnitID = self:ID()

  return GetPowerRegen(UnitID)
end

-- power.pct
function Unit:PowerPercentage()
  return (self:Power() / self:PowerMax()) * 100
end

-- power.deficit
function Unit:PowerDeficit()
  return self:PowerMax() - self:Power()
end

-- "power.deficit.pct"
function Unit:PowerDeficitPercentage()
  return (self:PowerDeficit() / self:PowerMax()) * 100
end

-- "power.regen.pct"
function Unit:PowerRegenPercentage()
  return (self:PowerRegen() / self:PowerMax()) * 100
end

-- power.time_to_max
function Unit:PowerTimeToMax()
  if self:PowerRegen() == 0 then return -1 end
  return self:PowerDeficit() / self:PowerRegen()
end

-- "power.time_to_x"
function Unit:PowerTimeToX(Amount, Offset)
  if self:PowerRegen() == 0 then return -1 end
  return Amount > self:Power() and (Amount - self:Power()) / (self:PowerRegen() * (1 - (Offset or 0))) or 0
end

-- "power.time_to_x.pct"
function Unit:PowerTimeToXPercentage(Amount)
  if self:PowerRegen() == 0 then return -1 end
  return Amount > self:PowerPercentage() and (Amount - self:PowerPercentage()) / self:PowerRegenPercentage() or 0
end
