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
  local wipe = table.wipe
  -- File Locals
  local PowerTableByPowerID, PowerTableBySpellID = {}, {}


--- ============================ CONTENT ============================
  -- Get every traits informations and stores them.
  do
    local GetPowers, GetPowerInfo, Clear = C_ArtifactUI.GetPowers, C_ArtifactUI.GetPowerInfo, C_ArtifactUI.Clear
    local HasArtifactEquipped, SocketInventoryItem = HasArtifactEquipped, SocketInventoryItem
    local UIParent = UIParent
    --local PowerTable = {} -- Uncomment for debug purpose in case they changes the Artifact API
    function Spell:ArtifactScan ()
      local ArtifactFrame = ArtifactFrame
      -- Does the scan only if the artifact is equipped and the artifact frame not opened.
      if HasArtifactEquipped() and not (ArtifactFrame and ArtifactFrame:IsShown()) then
        -- Unregister the event to prevent unwanted call(s).
        UIParent:UnregisterEvent("ARTIFACT_UPDATE")
        SocketInventoryItem(INVSLOT_MAINHAND)
        local Powers = GetPowers()
        if Powers then
          wipe(PowerTableByPowerID)
          wipe(PowerTableBySpellID)
          for _, Power in pairs(Powers) do
            -- GetPowerInfo() returns a table and not multiple values unlike most WoW API.
            -- offset, prereqsMet, cost, bonusRanks, maxRanks, linearIndex, position, isFinal, numMaxRankBonusFromTier, tier, isGoldMedal, isStart, currentRank, spellID
            local PowerInfo = GetPowerInfo(Power)
            PowerTableByPowerID[Power] = PowerInfo
            PowerTableBySpellID[PowerInfo.spellID] = PowerInfo
          end
        end
        Clear()
        -- Register back the event.
        UIParent:RegisterEvent("ARTIFACT_UPDATE")
      end
    end
  end

  -- artifact.foo.rank
  function Spell:ArtifactRank ()
    local Power = PowerTableBySpellID[self.SpellID]
    return Power and Power.currentRank or 0
  end
  function Spell:ArtifactRankPowerID ()
    local Power = PowerTableByPowerID[self.SpellID]
    return Power and Power.currentRank or 0
  end

  -- artifact.foo.enabled
  function Spell:ArtifactEnabled ()
    return self:ArtifactRank() > 0
  end
  function Spell:ArtifactEnabledPowerID ()
    return self:ArtifactRankPowerID() > 0
  end
