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
  local select = select;
  -- WoW API
  local GetSpellInfo, GetSpellTabInfo = GetSpellInfo, GetSpellTabInfo;
  local BOOKTYPE_PET, BOOKTYPE_SPELL = BOOKTYPE_PET, BOOKTYPE_SPELL;
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Get the spell BookIndex along with BookType.
  function Spell:BookIndex ()
    -- Pet Book
    do
      local NumPetSpells = HasPetSpells();
      if NumPetSpells then
        for i = 1, NumPetSpells do
          local CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET));
          if CurrentSpellID and CurrentSpellID == self:ID() then
            return i, BOOKTYPE_PET;
          end
        end
      end
    end
    -- Player Book
    for i = 1, GetNumSpellTabs() do
      local Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i));
      -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
      -- If the OffSpec ID is set to 0, then it's the Main Spec.
      if OffSpec == 0 then
        for j = 1, (Offset + NumSpells) do
          local CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL));
          if CurrentSpellID and CurrentSpellID == self:ID() then
            return j, BOOKTYPE_SPELL;
          end
        end
      end
    end
  end

  -- Scan the Book to cache every Spell Learned.
  function Spell:BookScan (BlankScan)
    local SpellLearned = Cache.Persistent.SpellLearned;

    -- Pet Book
    do
      local NumPetSpells = HasPetSpells();
      if NumPetSpells then
        local SpellLearned = SpellLearned.Pet;
        local IsTalentSpell = IsTalentSpell;
        for i = 1, NumPetSpells do
          local CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET))
          if CurrentSpellID then
            local CurrentSpell = Spell(CurrentSpellID, "Pet");
            if CurrentSpell:IsAvailable(true) and (CurrentSpell:IsKnown(true) or IsTalentSpell(i, BOOKTYPE_PET)) then
              if not BlankScan then
                SpellLearned[CurrentSpell:ID()] = true;
              end
            end
          end
        end
      end
    end
    -- Player Book
    do
      local SpellLearned = SpellLearned.Player;

      local GetSpellBookItemInfo = GetSpellBookItemInfo;
      for i = 1, GetNumSpellTabs() do
        local Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i));
        -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
        -- If the OffSpec ID is set to 0, then it's the Main Spec.
        if OffSpec == 0 then
          for j = 1, (Offset + NumSpells) do
            local CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL))
            if CurrentSpellID and GetSpellBookItemInfo(j, BOOKTYPE_SPELL) == "SPELL" then
              if not BlankScan then
                SpellLearned[CurrentSpellID] = true;
              end
            end
          end
        end
      end

      -- Flyout Spells
      local GetFlyoutInfo, GetFlyoutSlotInfo = GetFlyoutInfo, GetFlyoutSlotInfo;
      for i = 1, GetNumFlyouts() do
        local FlyoutID = GetFlyoutID(i);
        local NumSlots, IsKnown = select(3, GetFlyoutInfo(FlyoutID));
        if IsKnown and NumSlots > 0 then
          for j = 1, NumSlots do
            local CurrentSpellID, _, IsKnownSpell = GetFlyoutSlotInfo(FlyoutID, j);
            if CurrentSpellID and IsKnownSpell then
              SpellLearned[CurrentSpellID] = true;
            end
          end
        end
      end
    end
  end
