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
  
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Get if there is a pet currently active or not
  -- TODO: Cache
  function Pet:IsActive ()
    return IsPetActive()
  end
