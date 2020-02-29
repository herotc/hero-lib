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
local pairs = pairs
local select = select
local tablesort = table.sort
-- WoW API
local UnitPower, UnitPowerMax, GetPowerRegen = UnitPower, UnitPowerMax, GetPowerRegen
-- File Locals



--- ============================ CONTENT ============================
--------------------------
--- 0 | Mana Functions ---
--------------------------
do
  local ManaPowerType = Enum.PowerType.Mana
  -- mana.max
  function Player:ManaMax()
    return UnitPowerMax(self.UnitID, ManaPowerType)
  end

  -- Mana
  function Player:Mana()
    return UnitPower(self.UnitID, ManaPowerType)
  end

  -- Mana.pct
  function Player:ManaPercentage()
    return (self:Mana() / self:ManaMax()) * 100
  end

  -- Mana.deficit
  function Player:ManaDeficit()
    return self:ManaMax() - self:Mana()
  end

  -- "Mana.deficit.pct"
  function Player:ManaDeficitPercentage()
    return (self:ManaDeficit() / self:ManaMax()) * 100
  end

  -- mana.regen
  function Player:ManaRegen()
    return GetPowerRegen(self.UnitID)
  end

  -- Mana regen in a cast
  function Player:ManaCastRegen(CastTime)
    if self:ManaRegen() == 0 then return -1 end
    return self:ManaRegen() * CastTime
  end

  -- "remaining_cast_regen"
  function Player:ManaRemainingCastRegen(Offset)
    if self:ManaRegen() == 0 then return -1 end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() then
      return self:ManaRegen() * (self:CastRemains() + (Offset or 0))
      -- Else we'll use the remaining GCD as "CastTime"
    else
      return self:ManaRegen() * (self:GCDRemains() + (Offset or 0))
    end
  end

  -- "mana.time_to_max"
  function Player:ManaTimeToMax()
    if self:ManaRegen() == 0 then return -1 end
    return self:ManaDeficit() / self:ManaRegen()
  end

  -- "mana.time_to_x"
  function Player:ManaTimeToX(Amount)
    if self:ManaRegen() == 0 then return -1 end
    return Amount > self:Mana() and (Amount - self:Mana()) / self:ManaRegen() or 0
  end

  -- Mana Predicted with current cast
  function Player:ManaP()
    local FutureMana = Player:Mana() - Player:CastCost()
    -- Add the mana tha we will regen during the remaining of the cast
    if Player:Mana() ~= Player:ManaMax() then FutureMana = FutureMana + Player:ManaRemainingCastRegen() end
    -- Cap the max
    if FutureMana > Player:ManaMax() then FutureMana = Player:ManaMax() end
    return FutureMana
  end

  -- Mana.pct Predicted with current cast
  function Player:ManaPercentageP()
    return (self:ManaP() / self:ManaMax()) * 100
  end

  -- Mana.deficit Predicted with current cast
  function Player:ManaDeficitP()
    return self:ManaMax() - self:ManaP()
  end

  -- "Mana.deficit.pct" Predicted with current cast
  function Player:ManaDeficitPercentageP()
    return (self:ManaDeficitP() / self:ManaMax()) * 100
  end
end

--------------------------
--- 1 | Rage Functions ---
--------------------------
do
  local RagePowerType = Enum.PowerType.Rage
  -- rage.max
  function Player:RageMax()
    return UnitPowerMax(self.UnitID, RagePowerType)
  end

  -- rage
  function Player:Rage()
    return UnitPower(self.UnitID, RagePowerType)
  end

  -- rage.pct
  function Player:RagePercentage()
    return (self:Rage() / self:RageMax()) * 100
  end

  -- rage.deficit
  function Player:RageDeficit()
    return self:RageMax() - self:Rage()
  end

  -- "rage.deficit.pct"
  function Player:RageDeficitPercentage()
    return (self:RageDeficit() / self:RageMax()) * 100
  end
end

---------------------------
--- 2 | Focus Functions ---
---------------------------
do
  local FocusPowerType = Enum.PowerType.Focus
  -- focus.max
  function Player:FocusMax()
    return UnitPowerMax(self.UnitID, FocusPowerType)
  end

  -- focus
  function Player:Focus()
    return UnitPower(self.UnitID, FocusPowerType)
  end

  -- focus.regen
  function Player:FocusRegen()
    return GetPowerRegen(self.UnitID)
  end

  -- focus.pct
  function Player:FocusPercentage()
    return (self:Focus() / self:FocusMax()) * 100
  end

  -- focus.deficit
  function Player:FocusDeficit()
    return self:FocusMax() - self:Focus()
  end

  -- "focus.deficit.pct"
  function Player:FocusDeficitPercentage()
    return (self:FocusDeficit() / self:FocusMax()) * 100
  end

  -- "focus.regen.pct"
  function Player:FocusRegenPercentage()
    return (self:FocusRegen() / self:FocusMax()) * 100
  end

  -- focus.time_to_max
  function Player:FocusTimeToMax()
    if self:FocusRegen() == 0 then return -1 end
    return self:FocusDeficit() / self:FocusRegen()
  end

  -- "focus.time_to_x"
  function Player:FocusTimeToX(Amount)
    if self:FocusRegen() == 0 then return -1 end
    return Amount > self:Focus() and (Amount - self:Focus()) / self:FocusRegen() or 0
  end

  -- "focus.time_to_x.pct"
  function Player:FocusTimeToXPercentage(Amount)
    if self:FocusRegen() == 0 then return -1 end
    return Amount > self:FocusPercentage() and (Amount - self:FocusPercentage()) / self:FocusRegenPercentage() or 0
  end

  -- cast_regen
  function Player:FocusCastRegen(CastTime)
    if self:FocusRegen() == 0 then return -1 end
    return self:FocusRegen() * CastTime
  end

  -- "remaining_cast_regen"
  function Player:FocusRemainingCastRegen(Offset)
    if self:FocusRegen() == 0 then return -1 end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() then
      return self:FocusRegen() * (self:CastRemains() + (Offset or 0))
      -- Else we'll use the remaining GCD as "CastTime"
    else
      return self:FocusRegen() * (self:GCDRemains() + (Offset or 0))
    end
  end

  -- Get the Focus we will loose when our cast will end, if we cast.
  function Player:FocusLossOnCastEnd()
    return self:IsCasting() and Spell(self:CastID()):Cost() or 0
  end

  -- Predict the expected Focus at the end of the Cast/GCD.
  function Player:FocusPredicted(Offset)
    if self:FocusRegen() == 0 then return -1 end
    return math.min(Player:FocusMax(), self:Focus() + self:FocusRemainingCastRegen(Offset) - self:FocusLossOnCastEnd())
  end

  -- Predict the expected Focus Deficit at the end of the Cast/GCD.
  function Player:FocusDeficitPredicted(Offset)
    if self:FocusRegen() == 0 then return -1 end
    return Player:FocusMax() - self:FocusPredicted(Offset);
  end

  -- Predict time to max Focus at the end of Cast/GCD
  function Player:FocusTimeToMaxPredicted()
    if self:FocusRegen() == 0 then return -1 end
    local FocusDeficitPredicted = self:FocusDeficitPredicted()
    if FocusDeficitPredicted <= 0 then
      return 0
    end
    return FocusDeficitPredicted / self:FocusRegen()
  end
end

----------------------------
--- 3 | Energy Functions ---
----------------------------
do
  local EnergyPowerType = Enum.PowerType.Energy
  -- energy.max
  function Player:EnergyMax()
    return UnitPowerMax(self.UnitID, EnergyPowerType)
  end

  -- energy
  function Player:Energy()
    return UnitPower(self.UnitID, EnergyPowerType)
  end

  -- energy.regen
  function Player:EnergyRegen()
    return GetPowerRegen(self.UnitID)
  end

  -- energy.pct
  function Player:EnergyPercentage()
    return (self:Energy() / self:EnergyMax()) * 100
  end

  -- energy.deficit
  function Player:EnergyDeficit()
    return self:EnergyMax() - self:Energy()
  end

  -- "energy.deficit.pct"
  function Player:EnergyDeficitPercentage()
    return (self:EnergyDeficit() / self:EnergyMax()) * 100
  end

  -- "energy.regen.pct"
  function Player:EnergyRegenPercentage()
    return (self:EnergyRegen() / self:EnergyMax()) * 100
  end

  -- energy.time_to_max
  function Player:EnergyTimeToMax()
    if self:EnergyRegen() == 0 then return -1 end
    return self:EnergyDeficit() / self:EnergyRegen()
  end

  -- "energy.time_to_x"
  function Player:EnergyTimeToX(Amount, Offset)
    if self:EnergyRegen() == 0 then return -1 end
    return Amount > self:Energy() and (Amount - self:Energy()) / (self:EnergyRegen() * (1 - (Offset or 0))) or 0
  end

  -- "energy.time_to_x.pct"
  function Player:EnergyTimeToXPercentage(Amount)
    if self:EnergyRegen() == 0 then return -1 end
    return Amount > self:EnergyPercentage() and (Amount - self:EnergyPercentage()) / self:EnergyRegenPercentage() or 0
  end

  -- "energy.cast_regen"
  function Player:EnergyRemainingCastRegen(Offset)
    if self:EnergyRegen() == 0 then return -1 end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() or self:IsChanneling() then
      return self:EnergyRegen() * (self:CastRemains() + (Offset or 0))
      -- Else we'll use the remaining GCD as "CastTime"
    else
      return self:EnergyRegen() * (self:GCDRemains() + (Offset or 0))
    end
  end

  -- Predict the expected Energy at the end of the Cast/GCD.
  function Player:EnergyPredicted(Offset)
    if self:EnergyRegen() == 0 then return -1 end
    return math.min(Player:EnergyMax(), self:Energy() + self:EnergyRemainingCastRegen(Offset))
  end

  -- Predict the expected Energy Deficit at the end of the Cast/GCD.
  function Player:EnergyDeficitPredicted(Offset)
    if self:EnergyRegen() == 0 then return -1 end
    return math.max(0, self:EnergyDeficit() - self:EnergyRemainingCastRegen(Offset))
  end

  -- Predict time to max energy at the end of Cast/GCD
  function Player:EnergyTimeToMaxPredicted()
    if self:EnergyRegen() == 0 then return -1 end
    local EnergyDeficitPredicted = self:EnergyDeficitPredicted()
    if EnergyDeficitPredicted <= 0 then
      return 0
    end
    return EnergyDeficitPredicted / self:EnergyRegen()
  end
end

----------------------------------
--- 4 | Combo Points Functions ---
----------------------------------
do
  local ComboPointsPowerType = Enum.PowerType.ComboPoints
  -- combo_points.max
  function Player:ComboPointsMax()
    return UnitPowerMax(self.UnitID, ComboPointsPowerType)
  end

  -- combo_points
  function Player:ComboPoints()
    return UnitPower(self.UnitID, ComboPointsPowerType)
  end

  -- combo_points.deficit
  function Player:ComboPointsDeficit()
    return self:ComboPointsMax() - self:ComboPoints()
  end
end

---------------------------------
--- 5 | Runic Power Functions ---
---------------------------------
do
  local RunicPowerPowerType = Enum.PowerType.RunicPower
  -- runicpower.max
  function Player:RunicPowerMax()
    return UnitPowerMax(self.UnitID, RunicPowerPowerType)
  end

  -- runicpower
  function Player:RunicPower()
    return UnitPower(self.UnitID, RunicPowerPowerType)
  end

  -- runicpower.pct
  function Player:RunicPowerPercentage()
    return (self:RunicPower() / self:RunicPowerMax()) * 100
  end

  -- runicpower.deficit
  function Player:RunicPowerDeficit()
    return self:RunicPowerMax() - self:RunicPower()
  end

  -- "runicpower.deficit.pct"
  function Player:RunicPowerDeficitPercentage()
    return (self:RunicPowerDeficit() / self:RunicPowerMax()) * 100
  end
end

---------------------------
--- 6 | Runes Functions ---
---------------------------
do
  local GetRuneCooldown = GetRuneCooldown
  -- Computes any rune cooldown.
  local function ComputeRuneCooldown(Slot, BypassRecovery)
    -- Get rune cooldown infos
    local CDTime, CDValue = GetRuneCooldown(Slot)
    -- Return 0 if the rune isn't in CD.
    if CDTime == 0 then return 0 end
    -- Compute the CD.
    local CD = CDTime + CDValue - HL.GetTime() - (BypassRecovery and 0 or HL.RecoveryOffset())
    -- Return the Rune CD
    return CD > 0 and CD or 0
  end

  -- rune
  function Player:Rune()
    local Count = 0
    for i = 1, 6 do
      if ComputeRuneCooldown(i) == 0 then
        Count = Count + 1
      end
    end
    return Count
  end

  -- rune.time_to_x
  function Player:RuneTimeToX(Value)
    if type(Value) ~= "number" then error("Value must be a number.") end
    if Value < 1 or Value > 6 then error("Value must be a number between 1 and 6.") end
    local Runes = {}
    for i = 1, 6 do
      Runes[i] = ComputeRuneCooldown(i)
    end
    tablesort(Runes, function(a, b) return a < b end)
    local Count = 1
    for _, CD in pairs(Runes) do
      if Count == Value then
        return CD
      end
      Count = Count + 1
    end
  end
end

------------------------
--- 7 | Soul Shards  ---
------------------------
do
  -- soul_shard.max
  local SoulShardsPowerType = Enum.PowerType.SoulShards
  function Player:SoulShardsMax()
    return UnitPowerMax(self.UnitID, SoulShardsPowerType)
  end

  -- soul_shard
  local WarlockPowerBar_UnitPower = WarlockPowerBar_UnitPower
  function Player:SoulShards()
    return WarlockPowerBar_UnitPower(self.UnitID)
  end

  -- soul shards predicted, customize in spec overrides
  function Player:SoulShardsP()
    return WarlockPowerBar_UnitPower(self.UnitID)
  end

  -- soul_shard.deficit
  function Player:SoulShardsDeficit()
    return self:SoulShardsMax() - self:SoulShards()
  end
end

------------------------
--- 8 | Astral Power ---
------------------------
do
  local LunarPowerPowerType = Enum.PowerType.LunarPower
  -- astral_power.max
  function Player:AstralPowerMax()
    return UnitPowerMax(self.UnitID, LunarPowerPowerType)
  end

  -- astral_power
  function Player:AstralPower(OverrideFutureAstralPower)
    return OverrideFutureAstralPower or UnitPower(self.UnitID, LunarPowerPowerType)
  end

  -- astral_power.pct
  function Player:AstralPowerPercentage(OverrideFutureAstralPower)
    return (self:AstralPower(OverrideFutureAstralPower) / self:AstralPowerMax()) * 100
  end

  -- astral_power.deficit
  function Player:AstralPowerDeficit(OverrideFutureAstralPower)
    local AstralPower = self:AstralPower(OverrideFutureAstralPower)
    return self:AstralPowerMax() - AstralPower
  end

  -- "astral_power.deficit.pct"
  function Player:AstralPowerDeficitPercentage(OverrideFutureAstralPower)
    return (self:AstralPowerDeficit(OverrideFutureAstralPower) / self:AstralPowerMax()) * 100
  end
end

--------------------------------
--- 9 | Holy Power Functions ---
--------------------------------
do
  local HolyPowerPowerType = Enum.PowerType.HolyPower
  -- holy_power.max
  function Player:HolyPowerMax()
    return UnitPowerMax(self.UnitID, HolyPowerPowerType)
  end

  -- holy_power
  function Player:HolyPower()
    return UnitPower(self.UnitID, HolyPowerPowerType)
  end

  -- holy_power.pct
  function Player:HolyPowerPercentage()
    return (self:HolyPower() / self:HolyPowerMax()) * 100
  end

  -- holy_power.deficit
  function Player:HolyPowerDeficit()
    return self:HolyPowerMax() - self:HolyPower()
  end

  -- "holy_power.deficit.pct"
  function Player:HolyPowerDeficitPercentage()
    return (self:HolyPowerDeficit() / self:HolyPowerMax()) * 100
  end
end

------------------------------
-- 11 | Maelstrom Functions --
------------------------------
-- maelstrom.max
function Player:MaelstromMax()
  return UnitPowerMax(self.UnitID, Enum.PowerType.Maelstrom)
end

-- maelstrom
function Player:Maelstrom()
  return UnitPower(self.UnitID, Enum.PowerType.Maelstrom)
end

-- maelstrom.pct
function Player:MaelstromPercentage()
  return (self:Maelstrom() / self:MaelstromMax()) * 100
end

-- maelstrom.deficit
function Player:MaelstromDeficit()
  return self:MaelstromMax() - self:Maelstrom()
end

-- "maelstrom.deficit.pct"
function Player:MaelstromDeficitPercentage()
  return (self:MaelstromDeficit() / self:MaelstromMax()) * 100
end

--------------------------------------
--- 12 | Chi Functions (& Stagger) ---
--------------------------------------
do
  local ChiPowerType = Enum.PowerType.Chi
  -- chi.max
  function Player:ChiMax()
    return UnitPowerMax(self.UnitID, ChiPowerType)
  end

  -- chi
  function Player:Chi()
    return UnitPower(self.UnitID, ChiPowerType)
  end

  -- chi.pct
  function Player:ChiPercentage()
    return (self:Chi() / self:ChiMax()) * 100
  end

  -- chi.deficit
  function Player:ChiDeficit()
    return self:ChiMax() - self:Chi()
  end

  -- "chi.deficit.pct"
  function Player:ChiDeficitPercentage()
    return (self:ChiDeficit() / self:ChiMax()) * 100
  end

  -- "stagger.max"
  function Player:StaggerMax()
    return self:MaxHealth()
  end

  -- stagger_amount
  function Player:Stagger()
    return UnitStagger(self.UnitID)
  end

  -- stagger_percent
  function Player:StaggerPercentage()
    return (self:Stagger() / self:StaggerMax()) * 100
  end
end

------------------------------
-- 13 | Insanity Functions ---
------------------------------
do
  local InsanityPowerType = Enum.PowerType.Insanity
  -- insanity.max
  function Player:InsanityMax()
    return UnitPowerMax(self.UnitID, InsanityPowerType)
  end

  -- insanity
  function Player:Insanity()
    return UnitPower(self.UnitID, InsanityPowerType)
  end

  -- insanity.pct
  function Player:InsanityPercentage()
    return (self:Insanity() / self:InsanityMax()) * 100
  end

  -- insanity.deficit
  function Player:InsanityDeficit()
    return self:InsanityMax() - self:Insanity()
  end

  -- "insanity.deficit.pct"
  function Player:InsanityDeficitPercentage()
    return (self:InsanityDeficit() / self:InsanityMax()) * 100
  end

  -- Insanity Drain
  function Player:Insanityrain()
    --TODO : calculate insanitydrain
    return 1
  end
end

-----------------------------------
-- 16 | Arcane Charges Functions --
-----------------------------------
do
  local ArcaneChargesPowerType = Enum.PowerType.ArcaneCharges
  -- arcanecharges.max
  function Player:ArcaneChargesMax()
    return UnitPowerMax(self.UnitID, ArcaneChargesPowerType)
  end

  -- arcanecharges
  function Player:ArcaneCharges()
    return UnitPower(self.UnitID, ArcaneChargesPowerType)
  end

  -- arcanecharges.pct
  function Player:ArcaneChargesPercentage()
    return (self:ArcaneCharges() / self:ArcaneChargesMax()) * 100
  end

  -- arcanecharges.deficit
  function Player:ArcaneChargesDeficit()
    return self:ArcaneChargesMax() - self:ArcaneCharges()
  end

  -- "arcanecharges.deficit.pct"
  function Player:ArcaneChargesDeficitPercentage()
    return (self:ArcaneChargesDeficit() / self:ArcaneChargesMax()) * 100
  end
end

---------------------------
--- 17 | Fury Functions ---
---------------------------
do
  local FuryPowerType = Enum.PowerType.Fury
  -- fury.max
  function Player:FuryMax()
    return UnitPowerMax(self.UnitID, FuryPowerType)
  end

  -- fury
  function Player:Fury()
    return UnitPower(self.UnitID, FuryPowerType)
  end

  -- fury.pct
  function Player:FuryPercentage()
    return (self:Fury() / self:FuryMax()) * 100
  end

  -- fury.deficit
  function Player:FuryDeficit()
    return self:FuryMax() - self:Fury()
  end

  -- "fury.deficit.pct"
  function Player:FuryDeficitPercentage()
    return (self:FuryDeficit() / self:FuryMax()) * 100
  end
end

---------------------------
--- 18 | Pain Functions ---
---------------------------
do
  local PainPowerType = Enum.PowerType.Pain
  -- pain.max
  function Player:PainMax()
    return UnitPowerMax(self.UnitID, PainPowerType)
  end

  -- pain
  function Player:Pain()
    return UnitPower(self.UnitID, PainPowerType)
  end

  -- pain.pct
  function Player:PainPercentage()
    return (self:Pain() / self:PainMax()) * 100
  end

  -- pain.deficit
  function Player:PainDeficit()
    return self:PainMax() - self:Pain()
  end

  -- "pain.deficit.pct"
  function Player:PainDeficitPercentage()
    return (self:PainDeficit() / self:PainMax()) * 100
  end
end

------------------------------
--- Predicted Resource Map ---
------------------------------

do
  Player.PredictedResourceMap = {
    -- Mana
    [0] = function() return Player:ManaP() end,
    -- Rage
    [1] = function() return Player:Rage() end,
    -- Focus
    [2] = function() return Player:FocusPredicted() end,
    -- Energy
    [3] = function() return Player:EnergyPredicted() end,
    -- ComboPoints
    [4] = function() return Player:ComboPoints() end,
    -- Runes
    [5] = function() return Player:Runes() end,
    -- Runic Power
    [6] = function() return Player:RunicPower() end,
    -- Soul Shards
    [7] = function() return Player:SoulShardsP() end,
    -- Astral Power
    [8] = function() return Player:AstralPower() end,
    -- Holy Power
    [9] = function() return Player:HolyPower() end,
    -- Maelstrom
    [11] = function() return Player:Maelstrom() end,
    -- Chi
    [12] = function() return Player:Chi() end,
    -- Insanity
    [13] = function() return Player:Insanity() end,
    -- Arcane Charges
    [16] = function() return Player:ArcaneCharges() end,
    -- Fury
    [17] = function() return Player:Fury() end,
    -- Pain
    [18] = function() return Player:Pain() end,
  }
end

------------------------------
--- Time To X Resource Map ---
------------------------------

do
  Player.TimeToXResourceMap = {
    -- Mana
    [0] = function(Value) return Player:ManaTimeToX(Value) end,
    -- Rage
    [1] = function() return nil end,
    -- Focus
    [2] = function(Value) return Player:FocusTimeToX(Value) end,
    -- Energy
    [3] = function(Value) return Player:EnergyTimeToX(Value) end,
    -- ComboPoints
    [4] = function() return nil end,
    -- Runes
    [5] = function() return nil end,
    -- Runic Power
    [6] = function(Value) return Player:RuneTimeToX(Value) end,
    -- Soul Shards
    [7] = function() return nil end,
    -- Astral Power
    [8] = function() return nil end,
    -- Holy Power
    [9] = function() return nil end,
    -- Maelstrom
    [11] = function() return nil end,
    -- Chi
    [12] = function() return nil end,
    -- Insanity
    [13] = function() return nil end,
    -- Arcane Charges
    [16] = function() return nil end,
    -- Fury
    [17] = function() return nil end,
    -- Pain
    [18] = function() return nil end,
  }
end
