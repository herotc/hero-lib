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
local select = select
-- WoW API
local BOOKTYPE_PET, BOOKTYPE_SPELL = BOOKTYPE_PET, BOOKTYPE_SPELL
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellInfo, GetSpellTabInfo = GetSpellInfo, GetSpellTabInfo
local HasPetSpells = HasPetSpells
-- File Locals



--- ============================ CONTENT ============================
local function FindBookIndex(SpellID, SpellType)
  if SpellType == "Player" then
    -- Player Book
    for i = 1, GetNumSpellTabs() do
      local Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i))
      -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
      -- If the OffSpec ID is set to 0, then it's the Main Spec.
      if OffSpec == 0 then
        for j = 1, (Offset + NumSpells) do
          local CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL))
          if CurrentSpellID and CurrentSpellID == SpellID then
            return j
          end
        end
      end
    end
  elseif SpellType == "Pet" then
    -- Pet Book
    local NumPetSpells = HasPetSpells()
    if NumPetSpells then
      for i = 1, NumPetSpells do
        local CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET))
        if CurrentSpellID and CurrentSpellID == SpellID then
          return i
        end
      end
    end
  else
    error("Incorrect SpellType.")
  end
end

-- Get the spell BookIndex.
function Spell:BookIndex()
  local SpellID = self.SpellID
  local SpellType = self.SpellType

  local BookIndex = Cache.Persistent.BookIndex[SpellType][SpellID]
  if not BookIndex then
    BookIndex = FindBookIndex(SpellID, SpellType)
    Cache.Persistent.BookIndex[SpellType][SpellID] = BookIndex
  end

  return BookIndex
end

function Spell:BookType()
  local SpellType = self.SpellType
  if SpellType == "Player" then
    return BOOKTYPE_SPELL
  elseif SpellType == "Pet" then
    return BOOKTYPE_PET
  else
    error("Incorrect SpellType.")
  end
end
