--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, HL = ...;
  local Cache = HeroCache;
  -- Lua
  
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Based on Deprecated_7_2_5.lua from Blizzard Interface.
  -- All SPELL_POWER_TYPE are changed on 7.2.5 to use Enum table instead.
  -- Since it's not live yet, we create it on the live.
  if HL.BuildVersion() == "7.2.0" then
    Enum.PowerType = {
      -- Classes
      Mana = SPELL_POWER_MANA;
      Rage = SPELL_POWER_RAGE;
      Focus = SPELL_POWER_FOCUS;
      Energy = SPELL_POWER_ENERGY;
      ComboPoints = SPELL_POWER_COMBO_POINTS;
      Runes = SPELL_POWER_RUNES;
      RunicPower = SPELL_POWER_RUNIC_POWER;
      SoulShards = SPELL_POWER_SOUL_SHARDS;
      LunarPower = SPELL_POWER_LUNAR_POWER;
      HolyPower = SPELL_POWER_HOLY_POWER;
      Alternate = SPELL_POWER_ALTERNATE_POWER;
      Maelstrom = SPELL_POWER_MAELSTROM;
      Chi = SPELL_POWER_CHI;
      Insanity = SPELL_POWER_INSANITY;
      ArcaneCharges = SPELL_POWER_ARCANE_CHARGES;
      Fury = SPELL_POWER_FURY;
      Pain = SPELL_POWER_PAIN;

      -- Obsolete
      Obsolete = SPELL_POWER_OBSOLETE;
      Obsolete2 = SPELL_POWER_OBSOLETE2;
    }
  end
