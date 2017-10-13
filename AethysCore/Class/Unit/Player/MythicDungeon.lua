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
  local pairs = pairs;
  local select = select;
  local tablesort = table.sort;
  local tostring = tostring;
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Mythic Dungeon Abilites
  local MDA = {
    PlayerBuff = {
    },
    PlayerDebuff = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Vault of the Wardens
          -- Inquisitor Tormentorum
          {Spell(200904), "Sapped Soul"}
    },
    EnemiesBuff = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Black Rook Hold
          -- Trashes
          {Spell(200291), "Blade Dance Buff"} -- Risen Scout
    },
    EnemiesCast = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Black Rook Hold
          -- Trashes
          {Spell(200291), "Blade Dance Cast"} -- Risen Scout
    },
    EnemiesDebuff = {
    }
  }
  function AC.MythicDungeon ()
    -- TODO: Optimize
    for Key, Value in pairs(MDA) do
      if Key == "PlayerBuff" then
        for i = 1, #Value do
          if Player:Buff(Value[i][1], nil, true) then
            return Value[i][2];
          end
        end
      elseif Key == "PlayerDebuff" then
        for i = 1, #Value do
          if Player:Debuff(Value[i][1], nil, true) then
            return Value[i][2];
          end
        end
      elseif Key == "EnemiesBuff" then

      elseif Key == "EnemiesCast" then

      elseif Key == "EnemiesDebuff" then

      end
    end
    return "";
  end
