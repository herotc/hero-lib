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
do
  local ActiveMitigationSpells = {
    Buff = {
      -- PR Legion
      Spell(191941), -- Darkstrikes (VotW - 1st)
      Spell(204151), -- Darkstrikes (VotW - 1st)
      -- T20 ToS
      Spell(239932) -- Felclaws (KJ)
    },
    Debuff = {}, -- TODO ?
    Cast = {
      -- PR Legion
      197810, -- Wicked Slam (ARC - 3rd)
      197418, -- Vengeful Shear (BRH - 2nd)
      198079, -- Hateful Gaze (BRH - 3rd)
      214003, -- Coup de Grace (BRH - Trash)
      235751, -- Timber Smash (CotEN - 1st)
      193668, -- Savage Blade (HoV - 4th)
      227493, -- Mortal Strike (LOWR - 4th)
      228852, -- Shared Suffering (LOWR - 4th)
      193211, -- Dark Slash (MoS - 1st)
      200732, -- Molten Crash (NL - 4th)
      -- T20 ToS
      241635, -- Hammer of Creation (Maiden)
      241636, -- Hammer of Obliteration (Maiden)
      236494, -- Desolate (Avatar)
      239932, -- Felclaws (KJ)
      -- T21 Antorus
      254919, -- Forging Strike (Kin'garoth)
      244899, -- Fiery Strike (Coven)
      245458, -- Foe Breaker (Aggramar)
      248499, -- Sweeping Scythe (Argus)
      258039, -- Deadly Scythe (Argus)
      -- T29 VotI
      376279, -- Concussive Slam (Terros)
      372056, -- Crush (Primal Council)
      375580, -- Zephyr Slam (Dathea)
      390548, -- Sundering Strike (Kurog)
      375870, -- Mortal Stoneclaws (Broodkeeper)
      377658, -- Electrified Jaws (Raszageth)
      -- T30 Aberrus
      404744, -- Terror Claws (Kazzara)
      403699, -- Shadow Spike (Amalgamation)
      403203, -- Flame Slash (Amalgamation)
      405914, -- Withering Vulnerability (Amalgamation)
      406783, -- Shadowflame Burst (Amalgamation)
      401258, -- Heavy Cudgel (Assault)
      410351, -- Flaming Cudgel (Assault)
      407547, -- Flaming Slash (Rashok)
      407597, -- Earthen Crush (Rashok)
      401348, -- Incinerating Maws (Magmorax)
      401022, -- Calamitous Strike (Echo)
      407790, -- Sunder Shadow (Echo)
      401325, -- Burning Claws (Sarkareth)
      411236, -- Void Claws (Sarkareth)
      408422, -- Void Slash (Sarkareth)
      -- T31 Amirdrassil
      424352, -- Dreadfire Barrage (Gnarlroot)
      421020, -- Agonizing Claws (Council)
      418637, -- Furious Charge (Larodar)
      421343, -- Brand of Damnation (Smolderon)
      417431, -- Fyr'alath's Bite (Fyrakk)
      425492, -- Infernal Maw (Fyrakk)
    },
    Channel = {} -- TODO ?
  }
  function Player:ActiveMitigationNeeded()
    if not Player:IsTanking(Target) then return false end

    -- Check casts
    if ActiveMitigationSpells.Cast[Target:CastSpellID()] then
      return true
    end

    -- Check buffs
    for _, Buff in pairs(ActiveMitigationSpells.Buff) do
      if Target:BuffUp(Buff, true) then
        return true
      end
    end

    return false
  end
end

do
  local HealingAbsorbedSpells = {
    Debuff = {
      -- T21 Antorus
      Spell(243961) -- Misery (Varimathras)
    }
  }
  function Player:HealingAbsorbed()
    for _, Debuff in pairs(HealingAbsorbedSpells.Debuff) do
      if Player:DebuffUp(Debuff, true) then
        return true
      end
    end

    return false
  end
end
