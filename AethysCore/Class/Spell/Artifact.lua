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
  local wipe = table.wipe;
  -- File Locals
  


--- ============================ CONTENT ============================
  --- Artifact Traits Scan
    -- Get every traits informations and stores them.
    local ArtifactUI = _G.C_ArtifactUI;
    local HasArtifactEquipped, SocketInventoryItem = _G.HasArtifactEquipped, _G.SocketInventoryItem;
    local ArtifactFrame = _G.ArtifactFrame;
    local Powers, PowerTableByPowerID, PowerTableBySpellID = {}, {}, {};
    --local PowerTable = {}; -- Uncomment for debug purpose in case they changes the Artifact API
    function Spell:ArtifactScan ()
      ArtifactFrame = _G.ArtifactFrame;
      -- Does the scan only if the artifact is equipped and the artifact frame not opened.
      if HasArtifactEquipped() and not (ArtifactFrame and ArtifactFrame:IsShown()) then
        -- Unregister the event to prevent unwanted call(s).
        UIParent:UnregisterEvent("ARTIFACT_UPDATE");
        SocketInventoryItem(INVSLOT_MAINHAND);
        Powers = ArtifactUI.GetPowers();
        if Powers then
          --wipe(PowerTable);
          wipe(PowerTableByPowerID);
          wipe(PowerTableBySpellID);
          local PowerInfo;
          for Index, Power in pairs(Powers) do
            -- GetPowerInfo() returns a table and not multiple values unlike most WoW API.
            -- offset, prereqsMet, cost, bonusRanks, maxRanks, linearIndex, position, isFinal, numMaxRankBonusFromTier, tier, isGoldMedal, isStart, currentRank, spellID
            PowerInfo = ArtifactUI.GetPowerInfo(Power);
            PowerTableByPowerID[Power] = PowerInfo;
            PowerTableBySpellID[PowerInfo.spellID] = PowerInfo;
          end
        end
        ArtifactUI.Clear();
        -- Register back the event.
        UIParent:RegisterEvent("ARTIFACT_UPDATE");
      end
    end

    -- artifact.foo.rank
    function Spell:ArtifactRank ()
      return PowerTableBySpellID[self.SpellID] and PowerTableBySpellID[self.SpellID].currentRank or 0;
    end
    function Spell:ArtifactRankPowerID ()
      return PowerTableByPowerID[self.SpellID] and PowerTableByPowerID[self.SpellID].currentRank or 0;
    end

    -- artifact.foo.enabled
    function Spell:ArtifactEnabled ()
      return self:ArtifactRank() > 0;
    end
    function Spell:ArtifactEnabledPowerID ()
      return self:ArtifactRankPowerID() > 0;
    end
