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
-- gcd
do
  local GCD_OneSecond = {
    [103] = true, -- Feral
    [259] = true, -- Assassination
    [260] = true, -- Outlaw
    [261] = true, -- Subtlety
    [268] = true, -- Brewmaster
    [269] = true -- Windwalker
  }
  function Player:GCD()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.GCD then
        if GCD_OneSecond[Cache.Persistent.Player.Spec[1]] then
          UnitInfo.GCD = 1
        else
          local GCD_Value = 1.5 / (1 + self:HastePct() / 100)
          UnitInfo.GCD = GCD_Value > 0.75 and GCD_Value or 0.75
        end
      end
      return UnitInfo.GCD
    end
  end
end

-- gcd.remains
do
  local GCDSpell = Spell(61304)
  function Player:GCDRemains()
    return GCDSpell:CooldownRemains(true)
  end
end

-- attack_power
function Player:AttackPower()
  return UnitAttackPower(self.UnitID)
end

function Player:AttackPowerDamageMod(offHand)
  local useOH = offHand or false
  local wdpsCoeff = 6
  local ap = Player:AttackPower()
  local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(self.UnitID)
  local speed, offhandSpeed = UnitAttackSpeed(self.UnitID)
  if useOH then
    local wSpeed = offhandSpeed * (1 + Player:HastePct() / 100)
    local wdps = (minOffHandDamage + maxOffHandDamage) / wSpeed / percent - ap / wdpsCoeff
    return (ap + wdps * wdpsCoeff) * 0.5
  else
    local wSpeed = speed * (1 + Player:HastePct() / 100)
    local wdps = (minDamage + maxDamage) / 2 / wSpeed / percent - ap / wdpsCoeff
    return ap + wdps * wdpsCoeff
  end
end

-- crit_chance
function Player:CritChancePct()
  return GetCritChance()
end

-- haste
function Player:HastePct()
  return GetHaste()
end

function Player:SpellHaste()
  return 1 / (1 + (Player:HastePct() / 100))
end

-- mastery
function Player:MasteryPct()
  return GetMasteryEffect()
end

-- versatility
function Player:VersatilityDmgPct()
  return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
end
