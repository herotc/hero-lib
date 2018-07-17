--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache, Utils = HeroCache, AC.Utils;
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
  -- Get if the player is stealthed or not
  do
    local IsStealthedBuff = {
      -- Normal Stealth
      { -- Rogue
        Spell(1784),    -- Stealth
        Spell(115191),  -- Stealth w/ Subterfuge Talent
        -- Feral
        Spell(5215)     -- Prowl
      },
      -- Combat Stealth
      { -- Rogue
        Spell(11327),   -- Vanish
        Spell(115193),  -- Vanish w/ Subterfuge Talent
        Spell(115192),  -- Subterfuge Buff
        Spell(185422),  -- Stealth from Shadow Dance
        -- Druid
        Spell(102543)   -- Incarnation: King of the Jungle
      },
      -- Special Stealth
      { -- Night Elf
        Spell(58984)    -- Shadowmeld
      }
    };
    local ThisUnit, _Abilities, _Special, _Remains;
    local function _IsStealthed ()
      if Spell.Rogue then
        local Assassination, Outlaw, Subtlety = Spell.Rogue.Assassination, Spell.Rogue.Outlaw, Spell.Rogue.Subtlety;
        if Assassination then
          if (Abilities and Assassination.Vanish:TimeSinceLastCast() < 0.3) or
            (Special and Assassination.Shadowmeld:TimeSinceLastCast() < 0.3) then
            return _Remains and 1 or true;
          end
        end
        if Outlaw then
          if (Abilities and Outlaw.Vanish:TimeSinceLastCast() < 0.3) or
            (Special and Outlaw.Shadowmeld:TimeSinceLastCast() < 0.3) then
            return _Remains and 1 or true;
          end
        end
        if Subtlety then
          if (Abilities and (Subtlety.Vanish:TimeSinceLastCast() < 0.3
              or Subtlety.ShadowDance:TimeSinceLastCast() < 0.3))
            or (Special and Subtlety.Shadowmeld:TimeSinceLastCast() < 0.3) then
            return _Remains and 1 or true;
          end
        end
      end
      if Spell.Druid then
        local Feral = Spell.Druid.Feral;
        if Feral then
          if (Abilities and Feral.Incarnation:TimeSinceLastCast() < 0.3) or
            (Special and Feral.Shadowmeld:TimeSinceLastCast() < 0.3) then
            return _Remains and 1 or true;
          end
        end
      end
      for i = 1, #IsStealthedBuff do
        if i == 1 or (i == 2 and _Abilities) or (i == 3 and _Special) then
          local Buffs = IsStealthedBuff[i];
          for j = 1, #Buffs do
            local Buff = Buffs[j];
            if ThisUnit:Buff(Buff) then
              return _Remains and (ThisUnit:BuffRemainsP(Buff) >= 0 and ThisUnit:BuffRemainsP(Buff) or 60) or true;
            end
          end
        end
      end
      return false;
    end
    function Player:IsStealthed (Abilities, Special, Remains)
      local Key = tostring(Abilites).."-"..tostring(Special).."-"..tostring(Remains);
      ThisUnit, _Abilities, _Special, _Remains = self, Abilities, Special, Remains;
      return Cache.Get("MiscInfo", "IsStealthed", Key, _IsStealthed);
    end
  end
  function Player:IsStealthedRemains (Abilities, Special)
    return self:IsStealthed(Abilities, Special, true);
  end
