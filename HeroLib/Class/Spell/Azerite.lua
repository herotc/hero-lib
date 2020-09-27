--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid = Unit.Party, Unit.Raid
local Spell = HL.Spell
-- Lua
local C_AzeriteEmpoweredItem = C_AzeriteEmpoweredItem
local C_AzeriteEssence = C_AzeriteEssence
local GetAllTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo
local GetEssenceInfo = C_AzeriteEssence.GetEssenceInfo
local GetMilestoneEssence = C_AzeriteEssence.GetMilestoneEssence
local GetMilestones = C_AzeriteEssence.GetMilestones
local GetPowerInfo = C_AzeriteEmpoweredItem.GetPowerInfo
local IsAzeriteEmpoweredItem =C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem
local IsPowerSelected = C_AzeriteEmpoweredItem.IsPowerSelected
local Item = Item
local mathmax = math.max
local mathmin = math.min
local pairs = pairs
local wipe = table.wipe
-- File Locals
local AzeritePowers = {}
local AzeriteEssences = {}
local AzeriteNeckItemLevel
local AzeriteEssenceScaling = DBC.AzeriteEssenceScaling

--- ============================ CONTENT ============================
-- Get every traits informations and stores them.
do
  local AzeriteItemSlotIDs    = { 1,3,5 }
  local AzeriteItems          = {}
  for _, ID in pairs(AzeriteItemSlotIDs) do
    AzeriteItems[ID] = Item:CreateFromEquipmentSlot(ID)
  end
  local HeartOfAzerothItem = Item:CreateFromEquipmentSlot(2)

  function Spell:AzeriteScan()
    AzeritePowers = {}
    for _, item in pairs(AzeriteItems) do
      if not item:IsItemEmpty() then
        local itemLoc = item:GetItemLocation()
        if IsAzeriteEmpoweredItem(itemLoc) then
          local tierInfos = GetAllTierInfo(itemLoc)
          for _, tierInfo in pairs(tierInfos) do
            for _, powerId in pairs(tierInfo.azeritePowerIDs) do
              if IsPowerSelected(itemLoc, powerId) then
                local spellID = GetPowerInfo(powerId).spellID
                if AzeritePowers[spellID] then
                  AzeritePowers[spellID] = AzeritePowers[spellID] + 1
                else
                  AzeritePowers[spellID] = 1
                end
              end
            end
          end
        end
      end
    end
    AzeriteNeckItemLevel = HeartOfAzerothItem:GetCurrentItemLevel()
  end
end

-- azerite.foo.rank
function Spell:AzeriteRank()
  local Power = AzeritePowers[self.SpellID]
  return Power and Power or 0
end

-- azerite.foo.enabled
function Spell:AzeriteEnabled()
  return self:AzeriteRank() > 0
end

-- Build a table of equipped Azerite Essences
function Spell:AzeriteEssenceScan()
  AzeriteEssences = {}
  local milestones = GetMilestones()
  if not milestones then return end
  for _, milestone in pairs(milestones) do
    if milestone.unlocked then
      local slotID = milestone.slot
      if slotID ~= nil then
        local essenceID = GetMilestoneEssence(milestone.ID)
        if essenceID ~= nil and essenceID ~= "" then
          local essenceInfo = GetEssenceInfo(essenceID)
          AzeriteEssences[slotID] = essenceInfo
        end
      end
    end
  end
end

-- Return Azerite Essence data to profiles when requested
function Spell:MajorEssence()
  return AzeriteEssences[0]
end

function Spell:MajorEssenceID()
  return AzeriteEssences[0].ID
end

function Spell:MajorEssenceName()
  return AzeriteEssences[0].Name
end

function Spell:MinorEssences()
  local returnTable = {}
  for essenceSlot, essenceInfo in pairs(AzeriteEssences) do
    if (essenceSlot ~= 0 and essenceInfo ~= nil) then
      table.insert(returnTable, essenceInfo)
    end
  end
  return returnTable and returnTable or 0
end

function Spell:EssenceEnabled(ID, major)
  if major then
    if AzeriteEssences[0] and AzeriteEssences[0].ID == ID then return true end
  else
    for _, essenceInfo in pairs(AzeriteEssences) do
      for k, v in pairs(essenceInfo) do
        if k == "ID" and v == ID then
          return true
        end
      end
    end
  end
  return false
end

function Spell:MajorEssenceEnabled(ID)
  return Spell:EssenceEnabled(ID, true)
end

function Spell:EssenceRank(ID)
  for essenceSlot, essenceInfo in pairs(AzeriteEssences) do
    for k, v in pairs(essenceInfo) do
      if k == "ID" and v == ID then
        return AzeriteEssences[essenceSlot].rank
      end
    end
  end
  return 0
end

function Spell:EssenceScaling()
  -- Cap between neck levels to a reasonable value
  local AzeriteNeckItemLevel = mathmax(mathmin(AzeriteNeckItemLevel, 523), 483)
  local ScaleFactor = AzeriteEssenceScaling[AzeriteNeckItemLevel]
  if not ScaleFactor then
    ScaleFactor = AzeriteEssenceScaling[483]
  end
  return ScaleFactor
end
