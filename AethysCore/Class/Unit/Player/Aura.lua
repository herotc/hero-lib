--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache, Utils = AethysCache, AC.Utils;
  local Unit = AC.Unit;
  local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target;
  local Focus, MouseOver = Unit.Focus, Unit.MouseOver;
  local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate;
  local Party, Raid = Unit.Party, Unit.Raid;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local tostring = tostring;
  -- File Locals
  


--- ============================ CONTENT ============================
  -- buff.bloodlust.up
  local HeroismBuff = {
    Spell(90355),  -- Ancient Hysteria
    Spell(2825),   -- Bloodlust
    Spell(32182),  -- Heroism
    Spell(160452), -- Netherwinds
    Spell(80353)   -- Time Warp
  };
  function Player:HasHeroism (Duration)
    for i = 1, #HeroismBuff do
      if self:Buff(HeroismBuff[i], nil, true) then
        return Duration and self:BuffRemains(HeroismBuff[i], true) or true;
      end
    end
    return false;
  end

  -- Get if the player is stealthed or not
  local IsStealthedBuff = {
    -- Normal Stealth
    {
      -- Rogue
      Spell(1784),    -- Stealth
      Spell(115191),  -- Stealth w/ Subterfuge Talent
      -- Feral
      Spell(5215)     -- Prowl
    },
    -- Combat Stealth
    {
      -- Rogue
      Spell(11327),   -- Vanish
      Spell(115193),  -- Vanish w/ Subterfuge Talent
      Spell(115192),  -- Subterfuge Buff
      Spell(185422)   -- Stealth from Shadow Dance
    },
    -- Special Stealth
    {
      -- Night Elf
      Spell(58984)    -- Shadowmeld
    }
  };
  function Player:IterateStealthBuffs (Abilities, Special, Duration)
    -- TODO: Add Assassination Spells when it'll be done and improve code
    -- TODO: Add Feral if we do supports it some day
    if  Spell.Rogue.Outlaw.Vanish:TimeSinceLastCast() < 0.3 or
      Spell.Rogue.Subtlety.ShadowDance:TimeSinceLastCast() < 0.3 or
      Spell.Rogue.Subtlety.Vanish:TimeSinceLastCast() < 0.3 or
      (Special and (
        Spell.Rogue.Outlaw.Shadowmeld:TimeSinceLastCast() < 0.3 or
        Spell.Rogue.Subtlety.Shadowmeld:TimeSinceLastCast() < 0.3
      ))
    then
      return Duration and 1 or true;
    end
    -- Normal Stealth
    for i = 1, #IsStealthedBuff[1] do
      if self:Buff(IsStealthedBuff[1][i]) then
        return Duration and (self:BuffRemainsP(IsStealthedBuff[1][i]) >= 0 and self:BuffRemainsP(IsStealthedBuff[1][i]) or 60) or true;
      end
    end
    -- Combat Stealth
    if Abilities then
      for i = 1, #IsStealthedBuff[2] do
        if self:Buff(IsStealthedBuff[2][i]) then
          return Duration and (self:BuffRemainsP(IsStealthedBuff[2][i]) >= 0 and self:BuffRemainsP(IsStealthedBuff[2][i]) or 60) or true;
        end
      end
    end
    -- Special Stealth
    if Special then
      for i = 1, #IsStealthedBuff[3] do
        if self:Buff(IsStealthedBuff[3][i]) then
          return Duration and (self:BuffRemainsP(IsStealthedBuff[3][i]) >= 0 and self:BuffRemainsP(IsStealthedBuff[3][i]) or 60) or true;
        end
      end
    end
    return false;
  end

  function Player:IsStealthed (Abilities, Special, Duration)
    local IsStealthedKey = tostring(Abilites).."-"..tostring(Special).."-"..tostring(Duration);
    if not Cache.MiscInfo then Cache.MiscInfo = {}; end
    if not Cache.MiscInfo.IsStealthed then Cache.MiscInfo.IsStealthed = {}; end
    if Cache.MiscInfo.IsStealthed[IsStealthedKey] == nil then
      Cache.MiscInfo.IsStealthed[IsStealthedKey] = self:IterateStealthBuffs(Abilities, Special, Duration);
    end
    return Cache.MiscInfo.IsStealthed[IsStealthedKey];
  end

  function Player:IsStealthedRemains (Abilities, Special)
    return self:IsStealthed(Abilities, Special, true);
  end
