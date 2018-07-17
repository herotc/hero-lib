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
  local type = type;
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Check if the unit is coded as blacklisted or not.
  local SpecialBlacklistDataSpells = {
    D_DHT_Submerged = Spell(220519),
    R_TOS_SpiritRealm = Spell(235621)
  }
  local SpecialBlacklistData = {
    --- Legion
      ----- Dungeons (7.0 Patch) -----
      --- Darkheart Thicket
        -- Strangling roots can't be hit while this buff is present
        [100991] = function (self) return self:Buff(SpecialBlacklistDataSpells.D_DHT_Submerged, nil, true); end,
      --- Mythic+ Affixes
        -- Fel Explosives (7.2 Patch)
        [120651] = true,
      ----- Trial of Valor (T19 - 7.1 Patch) -----
      --- Helya
        -- Striking Tentacle cannot be hit.
        [114881] = true,
      ----- Tomb of Sargeras (T20 - 7.2 Patch) -----
      --- Desolate Host
        -- Engine of Eradication cannot be hit in Spirit Realm.
        [118460] = function (self) return Player:Debuff(SpecialBlacklistDataSpells.R_TOS_SpiritRealm, nil, true); end,
        -- Soul Queen Dejahna cannot be hit outside Spirit Realm.
        [118462] = function (self) return not Player:Debuff(SpecialBlacklistDataSpells.R_TOS_SpiritRealm, nil, true); end,
  }
  function Unit:IsBlacklisted ()
    local npcid = self:NPCID()
    if SpecialBlacklistData[npcid] then
      if type(SpecialBlacklistData[npcid]) == "boolean" then
        return true;
      else
        return SpecialBlacklistData[npcid](self);
      end
    end
    return false;
  end

  -- Check if the unit is coded as blacklisted by the user or not.
  function Unit:IsUserBlacklisted ()
    local npcid = self:NPCID()
    if AC.GUISettings.General.Blacklist.UserDefined[npcid] then
      if type(AC.GUISettings.General.Blacklist.UserDefined[npcid]) == "boolean" then
        return true;
      else
        return AC.GUISettings.General.Blacklist.UserDefined[npcid](self);
      end
    end
    return false;
  end

  -- Check if the unit is coded as blacklisted for cycling by the user or not.
  function Unit:IsUserCycleBlacklisted ()
    local npcid = self:NPCID()
    if AC.GUISettings.General.Blacklist.CycleUserDefined[npcid] then
      if type(AC.GUISettings.General.Blacklist.CycleUserDefined[npcid]) == "boolean" then
        return true;
      else
        return AC.GUISettings.General.Blacklist.CycleUserDefined[npcid](self);
      end
    end
    return false;
  end

  --- Check if the unit is coded as blacklisted for Marked for Death (Rogue) or not.
  -- Most of the time if the unit doesn't really die and isn't the last unit of an instance.
  local SpecialMfdBlacklistData = {
    --- Legion
      ----- Dungeons (7.0 Patch) -----
      --- Halls of Valor
        -- Hymdall leaves the fight at 10%.
        [94960] = true,
        -- Solsten and Olmyr doesn't "really" die
        [102558] = true,
        [97202] = true,
        -- Fenryr leaves the fight at 60%. We take 50% as check value since it doesn't get immune at 60%.
        [95674] = function (self) return self:HealthPercentage() > 50 and true or false; end,

      ----- Trial of Valor (T19 - 7.1 Patch) -----
      --- Odyn
        -- Hyrja & Hymdall leaves the fight at 25% during first stage and 85%/90% during second stage (HM/MM)
        [114360] = true,
        [114361] = true,

    --- Warlord of Draenor (WoD)
      ----- HellFire Citadel (T18 - 6.2 Patch) -----
      --- Hellfire Assault
        -- Mar'Tak doesn't die and leave fight at 50% (blocked at 1hp anyway).
        [93023] = true,

      ----- Dungeons (6.0 Patch) -----
      --- Shadowmoon Burial Grounds
        -- Carrion Worm : They doesn't die but leave the area at 10%.
        [88769] = true,
        [76057] = true
  };
  function Unit:IsMfdBlacklisted ()
    local npcid = self:NPCID()
    if SpecialMfdBlacklistData[npcid] then
      if type(SpecialMfdBlacklistData[npcid]) == "boolean" then
        return true;
      else
        return SpecialMfdBlacklistData[npcid](self);
      end
    end
    return false;
  end

  function Unit:IsFacingBlacklisted ()
    if self:IsUnit(AC.UnitNotInFront) and AC.GetTime()-AC.UnitNotInFrontTime <= Player:GCD()*AC.GUISettings.General.Blacklist.NotFacingExpireMultiplier then
      return true;
    end
    return false;
  end
