--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Pet = Unit.Pet;
  local Target = Unit.Target;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local stringgsub = string.gsub;
  -- File Locals
  local KeyBindings = {};
  local BarNames = {};

--- ============================ CONTENT ============================
  -- Parse a given ActionBar for HotKeys
  local function ParseBar ( Bar, Override )
    local Button;
    local ButtonTexture;
    local ButtonHotKey = "";
    for i = 1, Bar[2] do
      ButtonName = Bar[1] .. i
      Button = _G[ButtonName];
      if Button and Button.icon and Button.HotKey then
        ButtonTexture = Button.icon:GetTexture();
        ButtonHotKey = Button.HotKey:GetText();
        if _G.Bartender4 and Button.config.hideElements.hotkey then
          ButtonHotKey = Button.config.keyBoundTarget and GetBindingKey(Button.config.keyBoundTarget) or GetBindingKey("CLICK " .. ButtonName .. ":LeftButton")
        end
        if Button.icon:IsShown() and ButtonTexture and ButtonHotKey and strbyte(ButtonHotKey) ~= 226 then
            --If button is a macro check that the macro casts a spell else ignore
            local buttonActionType, buttonActionId = GetActionInfo(ActionButton_GetPagedID(Button))
            if buttonActionType == "macro" then
                --Item is a macro so check it plans to cast a spell
                local _, _, macrospellid = GetMacroSpell(buttonActionId);
                --If it casts a spell change buttonTexture to that spell texture else to nil
                if macrospellid ~= nil then
                    ButtonTexture = GetSpellTexture(macrospellid);
                else
                    ButtonTexture = nil;
                end
            end
            if not KeyBindings[ButtonTexture] or Override then
                if ButtonTexture ~= nil then
                    -- Numpad isn't shortened, so we have to do it manually
                    KeyBindings[ButtonTexture] = stringgsub( ButtonHotKey, "Num Pad ", "N" );
                end
            end
        end
      end
    end
  end

  --[[*
    * @function FindKeyBindings
    * @desc Populate KeyBindings table with <TextureID> = <HotKey> data.
    *]]
  local function FindKeyBindings ()
    -- SlotIndex      ActionFrame                     CommandName                 Page
    -- 1..12        = ActionButton (Primary Bar)      ACTIONBUTTON..Slot          1
    -- 13..24       = ActionButton (Secondary Bar)    ACTIONBUTTON..Slot          2
    -- 25..36       = MultiBarRightButton             MULTIACTIONBAR3BUTTON..j    3
    -- 37..48       = MultiBarLeftButton              MULTIACTIONBAR4BUTTON..j    4
    -- 49..60       = MultiBarBottomRightButton       MULTIACTIONBAR2BUTTON..j    5
    -- 61..72       = MultiBarBottomLeftButton        MULTIACTIONBAR1BUTTON..j    6
    -- 72..132      = ?                               ACTIONBUTTON..Slot          1
    -- Where Slot is the SlotIndex in 1..132
    -- and j is the bar index in 1..12 for MULTIACTIONBARs
    -- See: http://wowwiki.wikia.com/wiki/ActionSlot
    -- BT stands for Bartender, it needs a special handling.

    --- Populate Bar Names
    do
      if _G.Bartender4 then
        -- Bartender
        BarNames = {
          [1] = {"BT4Button", 120},
        }
      elseif _G.LUI and _G.LUI.db.children.Bars.profile.General.Enable then
        -- LUI
        BarNames = {
          [1] = {"LUIBarBottom1Button", _G.LUI.db.children.Bars.profile.Bottombar1.NumButtons},
          [2] = {"LUIBarBottom2Button", _G.LUI.db.children.Bars.profile.Bottombar2.NumButtons},
          [3] = {"LUIBarBottom3Button", _G.LUI.db.children.Bars.profile.Bottombar3.NumButtons},
          [4] = {"LUIBarBottom4Button", _G.LUI.db.children.Bars.profile.Bottombar4.NumButtons},
          [5] = {"LUIBarBottom5Button", _G.LUI.db.children.Bars.profile.Bottombar5.NumButtons},
          [6] = {"LUIBarBottom6Button", _G.LUI.db.children.Bars.profile.Bottombar6.NumButtons},
          [7] = {"LUIBarLeft1Button", 12},
          [8] = {"LUIBarLeft2Button", 12},
          [9] = {"LUIBarRight1Button", 12},
          [10] = {"LUIBarRight2Button", 12},
        }
      elseif _G.ElvUI and _G.ElvUI[1].ActionBars then
        -- ElvUI
        BarNames = {
          [1] = {"ElvUI_Bar1Button", _G.ElvUI[1].ActionBars.db.bar1.buttons},
          [2] = {"ElvUI_Bar2Button", _G.ElvUI[1].ActionBars.db.bar2.buttons},
          [3] = {"ElvUI_Bar3Button", _G.ElvUI[1].ActionBars.db.bar3.buttons},
          [4] = {"ElvUI_Bar4Button", _G.ElvUI[1].ActionBars.db.bar4.buttons},
          [5] = {"ElvUI_Bar5Button", _G.ElvUI[1].ActionBars.db.bar5.buttons},
          [6] = {"ElvUI_Bar6Button", _G.ElvUI[1].ActionBars.db.bar6.buttons},
        }
      else
        -- Default UI
        BarNames = {
          [1] = {"ActionButton", 12},
          [2] = {"ActionButton", 12},
          [3] = {"MultiBarRightButton", 12},
          [4] = {"MultiBarLeftButton", 12},
          [5] = {"MultiBarBottomRightButton", 12},
          [6] = {"MultiBarBottomLeftButton", 12},
        };
      end
    end
    --- Parse Bars
    for i = 1, #BarNames do
      ParseBar(BarNames[i], true);
    end
  end

  AC:RegisterForEvent(
    function ()
      C_Timer.After(0.001, 
        function() 
          FindKeyBindings(); 
        end
      ); -- on a timer, because of Bar Update Delay
    end
    , "UPDATE_SHAPESHIFT_FORM"
  );
  
  AC:RegisterForEvent(
    function ()
      FindKeyBindings();
    end
    , "ZONE_CHANGED_NEW_AREA"
    , "PLAYER_SPECIALIZATION_CHANGED"
    , "PLAYER_TALENT_UPDATE"
    , "ACTIONBAR_SLOT_CHANGED"
    , "UPDATE_BINDINGS"
    , "LEARNED_SPELL_IN_TAB"
  );

  do
    local KeyBindingsWhitelist = {};
    function AC.WhitelistKeyBinding (TextureID, KeyBinding)
      KeyBindingsWhitelist[TextureID] = KeyBinding;
    end

    function AC.FindKeyBinding (TextureID)
      return KeyBindingsWhitelist[TextureID] or KeyBindings[TextureID] or false;
    end
  end
