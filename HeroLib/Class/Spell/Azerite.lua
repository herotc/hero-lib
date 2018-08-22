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
-- Lua
local pairs = pairs
local wipe = table.wipe
-- File Locals
local AzeritePowers = {}


--- ============================ CONTENT ============================
-- Get every traits informations and stores them.
do
  local AzeriteItemSlotIDs    = {1,3,5}
  local AzeriteEmpoweredItem  = _G.C_AzeriteEmpoweredItem
  local AzeriteItems          = {}
  local Item                  = Item
  for _, ID in pairs(AzeriteItemSlotIDs) do
    AzeriteItems[ID] = Item:CreateFromEquipmentSlot(ID)
  end
  function Spell:AzeriteScan()
    AzeritePowers = {}
    for _, item in pairs(AzeriteItems) do
      if not item:IsItemEmpty() then
        local itemLoc = item:GetItemLocation()
        if AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) then
          local tierInfos = AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
          for _, tierInfo in pairs(tierInfos) do
            for _, powerId in pairs(tierInfo.azeritePowerIDs) do
              if AzeriteEmpoweredItem.IsPowerSelected(itemLoc, powerId) then
                local spellID = C_AzeriteEmpoweredItem.GetPowerInfo(powerId).spellID
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
