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
local SpellBookSpellBank = Enum.SpellBookSpellBank
local FindSpellBookSlotForSpell = C_SpellBook.FindSpellBookSlotForSpell
-- File Locals



--- ============================ CONTENT ============================
local function FindBookIndex(SpellID)
  -- FindSpellBookSlotForSpell(spellIdentifier, includeHidden, includeFlyouts, includeFutureSpells, includeOffSpec)
  return FindSpellBookSlotForSpell(SpellID, false, true, false, false)
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
  return SpellBookSpellBank[SpellType]
end
