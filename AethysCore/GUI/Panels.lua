--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- Lua
  local stringformat = string.format;
  local strsplit = strsplit;
  -- File Locals
  AC.GUI = {};
  local GUI = AC.GUI;


--- ============================ CONTENT ============================
  -- Make a panel
  function GUI.CreatePanel (Parent, Addon, PName, SettingsTable, SavedVariablesTable)
    local Panel = CreateFrame("Frame", Addon .. "_" .. PName, UIParent);
    Parent.Panel = Panel;
    Parent.Panel.Childs = {};
    Parent.Panel.SettingsTable = SettingsTable;
    Parent.Panel.SavedVariablesTable = SavedVariablesTable;
    Panel.name = Addon;
    InterfaceOptions_AddCategory(Panel);
    return Panel;
  end
  -- Make a child panel
  function GUI.CreateChildPanel (Parent, CName)
    local CP = CreateFrame("Frame", Parent:GetName() .. "_ChildPanel_" .. CName, Parent);
    Parent.Childs[CName] = CP;
    CP.Childs = {};
    CP.SettingsTable = Parent.SettingsTable;
    CP.SavedVariablesTable = Parent.SavedVariablesTable;
    CP.name = CName;
    CP.parent = Parent.name;
    InterfaceOptions_AddCategory(CP);
    return CP;
  end

  local LastOptionAttached = {};
  -- Make a check button
  function GUI.CreateCheckButton (Parent, Setting, BText, Tooltip)
    local CheckButton = CreateFrame("CheckButton", "$parent_"..Setting, Parent, "InterfaceOptionsCheckButtonTemplate");
    Parent[Setting] = CheckButton;
    CheckButton.SettingTable, CheckButton.SettingKey = GUI.FindSetting(Parent.SettingsTable, strsplit(".", Setting));
    CheckButton.SavedVariablesTable, CheckButton.SavedVariablesKey = Parent.SavedVariablesTable, Setting;

    if not LastOptionAttached[Parent.name] then
      CheckButton:SetPoint("TOPLEFT", 15, -15);
    else
      CheckButton:SetPoint("TOPLEFT", LastOptionAttached[Parent.name][1], "BOTTOMLEFT", LastOptionAttached[Parent.name][2], LastOptionAttached[Parent.name][3]-5);
    end
    LastOptionAttached[Parent.name] = {CheckButton, 0, 0};

    CheckButton:SetChecked(CheckButton.SettingTable[CheckButton.SettingKey]);

    _G[CheckButton:GetName().."Text"]:SetText("|c00dfb802" .. BText .. "|r");

    if Tooltip then
      CheckButton:SetScript("OnEnter",
        function (self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:ClearLines();
            GameTooltip:SetBackdropColor(0, 0, 0, 1);
            GameTooltip:SetText(Tooltip, nil, nil, nil, 1, true);
            GameTooltip:Show();
        end
      );
      CheckButton:SetScript("OnLeave",
        function (self)
          GameTooltip:Hide();
        end
      );
    end

    local function UpdateSetting(self)
      print(self.SettingTable[self.SettingKey], self.SavedVariablesTable[self.SavedVariablesKey]);
      self.SettingTable[self.SettingKey] = not self.SettingTable[self.SettingKey];
      self.SavedVariablesTable[self.SavedVariablesKey] = not self.SavedVariablesTable[self.SavedVariablesKey];
      print(self.SettingTable[self.SettingKey], self.SavedVariablesTable[self.SavedVariablesKey]);
    end
    CheckButton:SetScript("onClick", UpdateSetting);
  end
  -- Make a dropdown
  function GUI.CreateDropdown (Parent, Setting, Values, Text, Tooltip)
    local Dropdown = CreateFrame("Button", "$parent_"..Setting, Parent, "UIDropDownMenuTemplate")
    Parent[Setting] = Dropdown;
    Dropdown.SettingTable, Dropdown.SettingKey = GUI.FindSetting(Parent.SettingsTable, strsplit(".", Setting));
    Dropdown.SavedVariablesTable, Dropdown.SavedVariablesKey = Parent.SavedVariablesTable, Setting;

    local function UpdateSetting (self)
      UIDropDownMenu_SetSelectedID(Dropdown, self:GetID());
      local SettingValue = UIDropDownMenu_GetText(Dropdown);
      Dropdown.SettingTable[Dropdown.SettingKey] = SettingValue;
      Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey] = SettingValue;
    end

    local function Initialize (Self, Level)
      local Info = UIDropDownMenu_CreateInfo();
      for Key, Value in pairs(Values) do
        Info = UIDropDownMenu_CreateInfo();
        Info.text = Value;
        Info.value = Value;
        Info.func = UpdateSetting;
        UIDropDownMenu_AddButton(Info, Level);
      end
    end

    if not LastOptionAttached[Parent.name] then
      Dropdown:SetPoint("TOPLEFT", 0, -30);
    else
      Dropdown:SetPoint("TOPLEFT", LastOptionAttached[Parent.name][1], "BOTTOMLEFT", LastOptionAttached[Parent.name][2]-15, LastOptionAttached[Parent.name][3]-25);
    end
    LastOptionAttached[Parent.name] = {Dropdown, 15, 0};

    UIDropDownMenu_Initialize(Dropdown, Initialize);
    UIDropDownMenu_SetSelectedValue(Dropdown, Dropdown.SettingTable[Dropdown.SettingKey]);
    UIDropDownMenu_JustifyText(Dropdown, "LEFT");

    local Title = Dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    Parent[Setting .. "DropdownTitle"] = Title;
    Title:SetPoint("BOTTOMLEFT", Dropdown, "TOPLEFT", 20, 5)
    Title:SetWidth(InterfaceOptionsFramePanelContainer:GetRight() - InterfaceOptionsFramePanelContainer:GetLeft() - 30);
    Title:SetJustifyH("LEFT");
    Title:SetText("|c00dfb802" .. Text .. "|r");

    if Tooltip then
      Dropdown:SetScript("OnEnter",
        function (self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:ClearLines();
            GameTooltip:SetBackdropColor(0, 0, 0, 1);
            GameTooltip:SetText(Tooltip, nil, nil, nil, 1, true);
            GameTooltip:Show();
        end
      );
      Dropdown:SetScript("OnLeave",
        function (self)
          GameTooltip:Hide();
        end
      );
    end
  end
  -- Make a Slider
  function GUI.CreateSlider (Parent, Setting, Values, Text, Tooltip)
    local Slider = CreateFrame("Slider", "$parent_"..Setting, Parent, "OptionsSliderTemplate");
    Parent[Setting] = Slider;
    Slider.SettingTable, Slider.SettingKey = GUI.FindSetting(Parent.SettingsTable, strsplit(".", Setting));
    Slider.SavedVariablesTable, Slider.SavedVariablesKey = Parent.SavedVariablesTable, Setting;

    if not LastOptionAttached[Parent.name] then
      Slider:SetPoint("TOPLEFT", 20, -30);
    else
      Slider:SetPoint("TOPLEFT", LastOptionAttached[Parent.name][1], "BOTTOMLEFT", LastOptionAttached[Parent.name][2]+5, LastOptionAttached[Parent.name][3]-25);
    end
    LastOptionAttached[Parent.name] = {Slider, -5, -20};

    Slider:SetMinMaxValues(Values[1], Values[2]);
    Slider.minValue, Slider.maxValue = Slider:GetMinMaxValues() 
    Slider:SetValue(Slider.SettingTable[Slider.SettingKey]);
    Slider:SetValueStep(Values[3]);

    local Name = Slider:GetName();
    _G[Name .. "Low"]:SetText(Slider.minValue);
    _G[Name .. "High"]:SetText(Slider.maxValue);
    _G[Name .. "Text"]:SetText("|c00dfb802" .. Text .. "|r");

    if Tooltip then
      Slider:SetScript("OnEnter",
        function (self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:ClearLines();
            GameTooltip:SetBackdropColor(0, 0, 0, 1);
            GameTooltip:SetText(Tooltip, nil, nil, nil, 1, true);
            GameTooltip:Show();
        end
      );
      Slider:SetScript("OnLeave",
        function (self)
          GameTooltip:Hide();
        end
      );
    end

    local ShowValue = Slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    Parent[Setting .. "SliderShowValue"] = ShowValue;
    ShowValue:SetPoint("TOP", Slider, "BOTTOM", 0 , 0)
    ShowValue:SetWidth(50);
    ShowValue:SetJustifyH("CENTER");
    ShowValue:SetText(stringformat("%.2f", Slider.SettingTable[Slider.SettingKey]));

    local function UpdateSetting(self)
      local Value = self:GetValue();
      self.SettingTable[self.SettingKey] = Value;
      self.SavedVariablesTable[self.SavedVariablesKey] = Value;
      ShowValue:SetText(stringformat("%.2f", Value));
    end
    Slider:SetScript("OnValueChanged", UpdateSetting);
  end

  function GUI.FindSetting (InitialKey, ...)
    local Keys = {...};
    local SettingTable = InitialKey;
    for i = 1, #Keys-1 do
      SettingTable = SettingTable[Keys[i]];
    end
    return SettingTable, Keys[#Keys];
  end
