--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Utils = HL.Utils
-- Lua
local stringformat = string.format
local strsplit = strsplit
-- File Locals
HL.GUI = {}
local GUI = HL.GUI
local StringToNumberIfPossible = Utils.StringToNumberIfPossible
local SubStringCount = Utils.SubStringCount


--- ============================ CONTENT ============================
--- ======= PRIVATE PANELS FUNCTIONS =======
-- Find a setting recursively
local function FindSetting(InitialKey, ...)
  local Keys = { ... }
  local SettingTable = InitialKey
  for i = 1, #Keys - 1 do
    SettingTable = SettingTable[Keys[i]]
  end
  -- Check if the final key is a string or a number (the case for table values with numeric index)
  local ParsedKey = StringToNumberIfPossible(Keys[#Keys])
  return SettingTable, ParsedKey
end

-- Filter tooltips based on Optionals input
local function FilterTooltip(Tooltip, Optionals)
  local Tooltip = Tooltip
  if Optionals then
    if Optionals["ReloadRequired"] then
      Tooltip = Tooltip .. "\n\n|cFFFF0000This option requires a reload to take effect.|r"
    end
  end
  return Tooltip
end

-- Anchor a tooltip to a frame
local function AnchorTooltip(Frame, Tooltip)
  Frame:SetScript("OnEnter",
    function(self)
      Mixin(GameTooltip, BackdropTemplateMixin)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:ClearLines()
      GameTooltip:SetBackdropColor(0, 0, 0, 1)
      GameTooltip:SetText(Tooltip, nil, nil, nil, 1, true)
      GameTooltip:Show()
    end)
  Frame:SetScript("OnLeave",
    function(self)
      GameTooltip:Hide()
    end)
end

local LastOptionAttached = {}
-- Make a check button
local function CreateCheckButton(Parent, Setting, Text, Tooltip, Optionals)
  -- Constructor
  local CheckButton = CreateFrame("CheckButton", "$parent_" .. Setting, Parent, "InterfaceOptionsCheckButtonTemplate")
  Parent[Setting] = CheckButton
  CheckButton.SettingTable, CheckButton.SettingKey = FindSetting(Parent.SettingsTable, strsplit(".", Setting))
  CheckButton.SavedVariablesTable, CheckButton.SavedVariablesKey = Parent.SavedVariablesTable, Setting

  -- Frame init
  if not LastOptionAttached[Parent.usedName] then
    CheckButton:SetPoint("TOPLEFT", 15, -10)
  else
    CheckButton:SetPoint("TOPLEFT", LastOptionAttached[Parent.usedName][1], "BOTTOMLEFT", LastOptionAttached[Parent.usedName][2], LastOptionAttached[Parent.usedName][3])
  end
  LastOptionAttached[Parent.usedName] = { CheckButton, 0, 0 }

  CheckButton:SetChecked(CheckButton.SettingTable[CheckButton.SettingKey])

  _G[CheckButton:GetName() .. "Text"]:SetText("|c00dfb802" .. Text .. "|r")

  AnchorTooltip(CheckButton, FilterTooltip(Tooltip, Optionals))

  -- Setting update
  local UpdateSetting
  if Optionals and Optionals["ReloadRequired"] then
    UpdateSetting = function(self)
      self.SavedVariablesTable[self.SavedVariablesKey] = not self.SettingTable[self.SettingKey]
    end
  else
    UpdateSetting = function(self)
      local NewValue = not self.SettingTable[self.SettingKey]
      self.SettingTable[self.SettingKey] = NewValue
      self.SavedVariablesTable[self.SavedVariablesKey] = NewValue
    end
  end
  CheckButton:SetScript("onClick", UpdateSetting)
end

-- Make a dropdown
local function CreateDropdown(Parent, Setting, Values, Text, Tooltip, Optionals)
  -- Constructor
  local Dropdown = CreateFrame("Frame", "$parent_" .. Setting, Parent, "UIDropDownMenuTemplate")
  Parent[Setting] = Dropdown
  Dropdown.SettingTable, Dropdown.SettingKey = FindSetting(Parent.SettingsTable, strsplit(".", Setting))
  Dropdown.SavedVariablesTable, Dropdown.SavedVariablesKey = Parent.SavedVariablesTable, Setting

  -- Setting update
  local UpdateSetting
  if Optionals and Optionals["ReloadRequired"] then
    UpdateSetting = function(self)
      UIDropDownMenu_SetSelectedID(Dropdown, self:GetID())
      Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey] = UIDropDownMenu_GetText(Dropdown)
    end
  else
    UpdateSetting = function(self)
      UIDropDownMenu_SetSelectedID(Dropdown, self:GetID())
      local SettingValue = UIDropDownMenu_GetText(Dropdown)
      Dropdown.SettingTable[Dropdown.SettingKey] = SettingValue
      Dropdown.SavedVariablesTable[Dropdown.SavedVariablesKey] = SettingValue
    end
  end

  -- Frame init
  if not LastOptionAttached[Parent.usedName] then
    Dropdown:SetPoint("TOPLEFT", 0, -30)
  else
    Dropdown:SetPoint("TOPLEFT", LastOptionAttached[Parent.usedName][1], "BOTTOMLEFT", LastOptionAttached[Parent.usedName][2] - 15, LastOptionAttached[Parent.usedName][3] - 20)
  end
  LastOptionAttached[Parent.usedName] = { Dropdown, 15, 0 }

  local function Initialize(Self, Level)
    local Info = UIDropDownMenu_CreateInfo()
    for Key, Value in pairs(Values) do
      Info = UIDropDownMenu_CreateInfo()
      Info.text = Value
      Info.value = Value
      Info.func = UpdateSetting
      UIDropDownMenu_AddButton(Info, Level)
    end
  end

  UIDropDownMenu_Initialize(Dropdown, Initialize)
  UIDropDownMenu_SetSelectedValue(Dropdown, Dropdown.SettingTable[Dropdown.SettingKey])
  UIDropDownMenu_JustifyText(Dropdown, "LEFT")

  local Title = Dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  Parent[Setting .. "DropdownTitle"] = Title
  Title:SetPoint("BOTTOMLEFT", Dropdown, "TOPLEFT", 20, 5)
  --Title:SetWidth(InterfaceOptionsFramePanelContainer:GetRight() - InterfaceOptionsFramePanelContainer:GetLeft() - 30)
  Title:SetJustifyH("LEFT")
  Title:SetText("|c00dfb802" .. Text .. "|r")

  AnchorTooltip(Dropdown, FilterTooltip(Tooltip, Optionals))
end

-- Make a Slider
local function CreateSlider(Parent, Setting, Values, Text, Tooltip, Action, Optionals)
  -- Constructor
  local Slider = CreateFrame("Slider", "$parent_" .. Setting, Parent, "OptionsSliderTemplate")
  Parent[Setting] = Slider
  Slider.SettingTable, Slider.SettingKey = FindSetting(Parent.SettingsTable, strsplit(".", Setting))
  Slider.SavedVariablesTable, Slider.SavedVariablesKey = Parent.SavedVariablesTable, Setting

  -- Frame init
  if not LastOptionAttached[Parent.usedName] then
    Slider:SetPoint("TOPLEFT", 20, -25)
  else
    Slider:SetPoint("TOPLEFT", LastOptionAttached[Parent.usedName][1], "BOTTOMLEFT", LastOptionAttached[Parent.usedName][2] + 5, LastOptionAttached[Parent.usedName][3] - 20)
  end
  LastOptionAttached[Parent.usedName] = { Slider, -5, -20 }

  Slider:SetMinMaxValues(Values[1], Values[2])
  Slider.minValue, Slider.maxValue = Slider:GetMinMaxValues()
  Slider:SetValue(Slider.SettingTable[Slider.SettingKey])
  Slider:SetValueStep(Values[3])
  Slider:SetObeyStepOnDrag(true)

  local Name = Slider:GetName()
  _G[Name .. "Low"]:SetText(Slider.minValue)
  _G[Name .. "High"]:SetText(Slider.maxValue)

  AnchorTooltip(Slider, FilterTooltip(Tooltip, Optionals))

  -- Setting update
  local ShowValue = Slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  Parent[Setting .. "SliderShowValue"] = ShowValue
  ShowValue:SetPoint("TOP", Slider, "BOTTOM", 0, 0)
  ShowValue:SetWidth(50)
  ShowValue:SetJustifyH("CENTER")
  ShowValue:SetText(stringformat("%.2f", Slider.SettingTable[Slider.SettingKey]))

  local Label = Slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Label:SetPoint("BOTTOMLEFT", Slider, "TOPLEFT")
  Label:SetJustifyH("LEFT")
  Label:SetText("|c00dfb802" .. Text .. "|r")

  local UpdateSetting
  if Optionals and Optionals["ReloadRequired"] then
    UpdateSetting = function(self)
      local Value = self:GetValue()
      self.SavedVariablesTable[self.SavedVariablesKey] = Value
      ShowValue:SetText(stringformat("%.2f", Value))
      if Action then
        Action(self:GetValue())
      end
    end
  else
    UpdateSetting = function(self)
      local Value = self:GetValue()
      self.SettingTable[self.SettingKey] = Value
      self.SavedVariablesTable[self.SavedVariablesKey] = Value
      if Action then
        Action(self:GetValue())
      end
      ShowValue:SetText(stringformat("%.2f", Value))
    end
  end
  Slider:SetScript("OnValueChanged", UpdateSetting)
end

local function CreateButton(Parent, Setting, Text, Tooltip, Action, Width, Height, Optionals)
  local Button = CreateFrame("Button", "$parent_" .. Setting, Parent, "UIPanelButtonTemplate")
  Parent[Setting] = Button

  if Width then
    Button:SetWidth(Width)
  else
    Button:SetWidth(150)
  end
  if Height then
    Button:SetHeight(Height)
  else
    Button:SetHeight(20)
  end

  -- Frame init
  if not LastOptionAttached[Parent.usedName] then
    Button:SetPoint("TOPLEFT", 15, -10)
  else
    Button:SetPoint("TOPLEFT", LastOptionAttached[Parent.usedName][1], "BOTTOMLEFT", LastOptionAttached[Parent.usedName][2], LastOptionAttached[Parent.usedName][3])
  end
  LastOptionAttached[Parent.usedName] = { Button, 0, 0 }

  _G[Button:GetName() .. "Text"]:SetText("|c00dfb802" .. Text .. "|r")

  AnchorTooltip(Button, FilterTooltip(Tooltip, Optionals))

  Button:SetScript("onClick", Action)
end

--- ======= PUBLIC PANELS FUNCTIONS =======
GUI.PanelsTable = {}
-- Make a panel
function GUI.CreatePanel(Parent, Addon, PName, SettingsTable, SavedVariablesTable)
  local Panel = CreateFrame("Frame", Addon .. "_" .. PName, UIParent)
  Parent.Panel = Panel
  Parent.Panel.Children = {}
  Parent.Panel.SettingsTable = SettingsTable
  Parent.Panel.SavedVariablesTable = SavedVariablesTable
  Panel.name = Addon
  Panel.usedName = Addon:gsub(" ", "")
  local category = Settings.RegisterCanvasLayoutCategory(Panel, Addon)
  Settings.RegisterAddOnCategory(category)
  Panel.category = category
  GUI.PanelsTable[Panel.usedName] = Panel
  GUI.PanelsTable[Panel.category] = category
  return Panel
end

-- Make a child panel
function GUI.CreateChildPanel(Parent, CName)
  -- Indent the child if needed
  local ParentName = Parent:GetName()
  local CLevel = SubStringCount(ParentName, "_ChildPanel_")
  local CName = CName
  for i = 0, CLevel do
    -- Leaving this in and commented out. I don't think it's necessary with the new settings system.
    --CName = "   " .. CName
  end

  local CP = CreateFrame("Frame", ParentName .. "_ChildPanel_" .. CName, Parent)
  Parent.Children[CName] = CP
  CP.Children = {}
  CP.SettingsTable = Parent.SettingsTable
  CP.SavedVariablesTable = Parent.SavedVariablesTable
  CP.name = CName
  CP.parent = Parent.name
  CP.usedName = ParentName .. "_ChildPanel_" .. CName:gsub(" ", "")
  local category = Settings.RegisterCanvasLayoutSubcategory(Parent.category, CP, CName)
  Settings.RegisterAddOnCategory(category)
  CP.category = category
--[[   if Parent.collapsed then
    GUI.TogglePanel(Parent) -- TODO: check if this has any impact, commented this part to collapse the options by default
  end ]]
  GUI.PanelsTable[CP.usedName] = CP
  GUI.PanelsTable[CP.category] = category
  return CP
end

-- Toggle a panel
function GUI.TogglePanel(Panel)
  local Table = {}
  Table.element = Panel
  InterfaceOptionsListButton_ToggleSubCategories(Table)
end

-- Make a panel option
local CreatePanelOption = {
  CheckButton = CreateCheckButton,
  Dropdown = CreateDropdown,
  Slider = CreateSlider,
  Button = CreateButton
}
function GUI.CreatePanelOption(Type, ...)
  CreatePanelOption[Type](...)
end

function GUI.GetPanelByName(PanelName)
  return GUI.PanelsTable[PanelName]
end

function GUI.LoadSettingsRecursively (Table, KeyChain)
  local KeyChain = KeyChain or ""
  for Key, Value in pairs(Table) do
    -- Generate the NewKeyChain
    local NewKeyChain
    if KeyChain ~= "" then
      NewKeyChain = KeyChain .. "." .. Key
    else
      NewKeyChain = Key
    end
    -- Continue the table browsing
    if type(Value) == "Table" then
      GUI.LoadSettingsRecursively(Value, NewKeyChain)
    -- Update teh value
    else
      -- Check if the final key is a string or a number (the case for table values with numeric index)
      local ParsedKey = StringToNumberIfPossible(Key);
      -- Load the saved value
      local DBSetting = HeroLibDB.GUISettings[NewKeyChain];
      -- If the saved value exists, take it
      if DBSetting ~= nil then
        Table[ParsedKey] = DBSetting;
      -- Else, save the default value
      else
        HeroLibDB.GUISettings[NewKeyChain] = Value;
      end
    end
  end
end
