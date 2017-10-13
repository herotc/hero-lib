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
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Get the spell BookIndex along with BookType.
  function Spell:BookIndex ()
    local CurrentSpellID;
    -- Pet Book
    local NumPetSpells = HasPetSpells();
    if NumPetSpells then
      for i = 1, NumPetSpells do
        CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET));
        if CurrentSpellID and CurrentSpellID == self:ID() then
          return i, BOOKTYPE_PET;
        end
      end
    end
    -- Player Book
    local Offset, NumSpells, OffSpec;
    for i = 1, GetNumSpellTabs() do
      Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i));
      -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
      -- If the OffSpec ID is set to 0, then it's the Main Spec.
      if OffSpec == 0 then
        for j = 1, (Offset + NumSpells) do
          CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL));
          if CurrentSpellID and CurrentSpellID == self:ID() then
            return j, BOOKTYPE_SPELL;
          end
        end
      end
    end
  end

  -- Scan the Book to cache every Spell Learned.
  function Spell:BookScan (BlankScan)
    local CurrentSpellID, CurrentSpell;
    -- Pet Book
    local NumPetSpells = HasPetSpells();
    if NumPetSpells then
      for i = 1, NumPetSpells do
        CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET))
        if CurrentSpellID then
          CurrentSpell = Spell(CurrentSpellID, "Pet");
          if CurrentSpell:IsAvailable(true) and (CurrentSpell:IsKnown( true ) or IsTalentSpell(i, BOOKTYPE_PET)) then
            if not BlankScan then
              Cache.Persistent.SpellLearned.Pet[CurrentSpell:ID()] = true;
            end
          end
        end
      end
    end
    -- Player Book (except Flyout Spells)
    local Offset, NumSpells, OffSpec;
    for i = 1, GetNumSpellTabs() do
      Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i));
      -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
      -- If the OffSpec ID is set to 0, then it's the Main Spec.
      if OffSpec == 0 then
        for j = 1, (Offset + NumSpells) do
          CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL))
          if CurrentSpellID and GetSpellBookItemInfo(j, BOOKTYPE_SPELL) == "SPELL" then
            --[[ Debug Code
            CurrentSpell = Spell(CurrentSpellID);
            print(
              tostring(CurrentSpell:ID()) .. " | " .. 
              tostring(CurrentSpell:Name()) .. " | " .. 
              tostring(CurrentSpell:IsAvailable()) .. " | " .. 
              tostring(CurrentSpell:IsKnown()) .. " | " .. 
              tostring(IsTalentSpell(j, BOOKTYPE_SPELL)) .. " | " .. 
              tostring(GetSpellBookItemInfo(j, BOOKTYPE_SPELL)) .. " | " .. 
              tostring(GetSpellLevelLearned(CurrentSpell:ID()))
            );
            ]]
            if not BlankScan then
              Cache.Persistent.SpellLearned.Player[CurrentSpellID] = true;
            end
          end
        end
      end
    end
    -- Flyout Spells
    local FlyoutID, NumSlots, IsKnown, IsKnownSpell;
    for i = 1, GetNumFlyouts() do
      FlyoutID = GetFlyoutID(i);
      NumSlots, IsKnown = select(3, GetFlyoutInfo(FlyoutID));
      if IsKnown and NumSlots > 0 then
        for j = 1, NumSlots do
          CurrentSpellID, _, IsKnownSpell = GetFlyoutSlotInfo(FlyoutID, j);
          if CurrentSpellID and IsKnownSpell then
            Cache.Persistent.SpellLearned.Player[CurrentSpellID] = true;
          end
        end
      end
    end
  end
