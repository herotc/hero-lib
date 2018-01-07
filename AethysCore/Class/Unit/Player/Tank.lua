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
  
  -- File Locals
  


--- ============================ CONTENT ============================
  do
    local ActiveMitigationSpells = {
      Buff = {
        Spell(239932) -- Felclaws (KJ)
      },
      Debuff = {

      },
      Cast = {
        -- PR Legion
        193211, -- Dark Slash (MoS - 1st)
        -- T20 ToS
        241635, -- Hammer of Creation (Maiden)
        241636, -- Hammer of Obliteration (Maiden)
        236494, -- Desolate (Avatar)
        239932, -- Felclaws (KJ)
        -- T21 Antorus
        254919, -- Forging Strike (Kin'garoth)
        245458, -- Foe Breaker (Aggramar)
        248499, -- Sweeping Scythe (Argus)
        258039 -- Deadly Scythe (Argus)
      },
      Channel = {

      }
    }
    function Player:ActiveMitigationNeeded ()
      if Player:IsTanking(Target) then
        if ActiveMitigationSpells.Cast[Target:CastID()] then
          return true;
        end
        for _, Buff in pairs(ActiveMitigationSpells.Buff) do
          if Target:Buff(Buff, nil, true) then
            return true;
          end
        end
      end
      return false;
    end
  end

  do
    local HealingAbsorbedSpells = {
      Debuff = {
        -- T21 Antorus
        Spell(243961) -- Misery (Varimathras)
      }
    };
    function Player:HealingAbsorbed ()
      for _, Debuff in pairs(HealingAbsorbedSpells.Debuff) do
        if Player:Debuff(Debuff, nil, true) then
          return true;
        end
      end
      return false;
    end
  end
