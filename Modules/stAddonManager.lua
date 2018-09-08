local PA = _G.ProjectAzilroka
local stAM = PA:NewModule('stAddonManager', 'AceEvent-3.0')
PA.stAM, _G.stAddonManager = stAM, stAM

_G.stAddonManagerProfilesDB = {}
_G.stAddonManagerServerDB = {}

stAM.Title = '|cFF16C3F2st|r|cFFFFFFFFAddonManager|r'
stAM.Description = 'A simple and minimalistic addon to disable/enabled addons without logging out.'
stAM.Authors = 'Safturento    Azilroka'

local _G = _G
local unpack, tinsert, wipe, pairs, sort, format = unpack, tinsert, wipe, pairs, sort, format
local strlen, strlower, strfind = strlen, strlower, strfind
local min, max = min, max

local CreateFrame, UIParent, GameTooltip = CreateFrame, UIParent, GameTooltip

local GetNumAddOns, GetAddOnInfo, GetAddOnDependencies, GetAddOnOptionalDependencies, GetAddOnEnableState = GetNumAddOns, GetAddOnInfo, GetAddOnDependencies, GetAddOnOptionalDependencies, GetAddOnEnableState
local DisableAddOn, EnableAddOn, GetAddOnMetadata, DisableAllAddOns, EnableAllAddOns = DisableAddOn, EnableAddOn, GetAddOnMetadata, DisableAllAddOns, EnableAllAddOns

local IsShiftKeyDown = IsShiftKeyDown

_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'] = {
	button1 = PA.ACL['Overwrite'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

_G.StaticPopupDialogs['STADDONMANAGER_NEWPROFILE'] = {
	text = PA.ACL['Enter a name for your new Addon Profile:'],
	button1 = PA.ACL['Create'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	hasEditBox = 1,
	whileDead = 1,
	OnAccept = function(self) stAM:NewAddOnProfile(self.editBox:GetText()) end,
	EditBoxOnEnterPressed = function(self) stAM:NewAddOnProfile(self:GetText()) self:GetParent():Hide() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

_G.StaticPopupDialogs['STADDONMANAGER_RENAMEPROFILE'] = {
	text = PA.ACL['Enter a name for your AddOn Profile:'],
	button1 = PA.ACL['Update'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	hasEditBox = 1,
	whileDead = 1,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

_G.StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION'] = {
	button1 = PA.ACL['Delete'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

local function strtrim(string)
	return string:gsub("^%s*(.-)%s*$", "%1")
end

function stAM:BuildFrame()
	local Frame = CreateFrame("Frame", 'stAMFrame', UIParent)
	local Close = CreateFrame('Button', 'stAMCloseButton', Frame)
	local Reload = CreateFrame('Button', 'stAMReload', Frame)
	local Search = CreateFrame('EditBox', 'stAMSearchBox', Frame)
	local CharacterSelect = CreateFrame('Button', nil, Frame)
	local Profiles = CreateFrame('Button', 'stAMProfiles', Frame)
	local AddOns = CreateFrame("Frame", 'stAMAddOns', Frame)
	local Slider = CreateFrame("Slider", nil, AddOns)

	local Title = Frame:CreateFontString(nil, 'OVERLAY')

	Frame:SetSize(self.db['FrameWidth'], 10 + self.db['NumAddOns'] * 25 + 40)
	Frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	Frame:SetTemplate("Transparent")
	Frame:SetFrameStrata('HIGH')
	Frame:SetClampedToScreen(true)
	Frame:SetMovable(true)
	Frame:EnableMouse(true)
	Frame:SetScript("OnMouseDown", function(self) self:StartMoving() end)
	Frame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	Title:SetPoint('TOPLEFT', 0, -5)
	Title:SetPoint('TOPRIGHT', 0, -5)
	Title:SetFont(PA.LSM:Fetch('font', self.db['Font']), 14, self.db['FontFlag'])
	Title:SetText(stAM.Title)
	Title:SetJustifyH('CENTER')
	Title:SetJustifyV('MIDDLE')

	Close:SetTemplate()
	Close:SetPoint('TOPRIGHT', -3, -3)
	Close:SetSize(16, 16)
	Close:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	Close:SetScript('OnLeave', function(self) self:SetTemplate() end)
	Close:SetScript('OnClick', function(self) Frame:Hide() end)

	Close.Text = Close:CreateFontString(nil, 'OVERLAY')
	Close.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	Close.Text:SetJustifyH('CENTER')
	Close.Text:SetText('x')
	Close.Text:SetPoint('CENTER', 1, 1)

	Search:SetPoint('TOPLEFT', Title, 'BOTTOMLEFT', 10, -10)
	Search:SetPoint('BOTTOMRIGHT', Profiles, 'BOTTOMLEFT', -5, 0)
	Search:SetSize(1, 20)
	Search:SetTemplate()
	Search:SetAutoFocus(false)
	Search:SetTextInsets(5, 5, 0, 0)
	Search:SetTextColor(1, 1, 1)
	Search:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	Search:SetShadowOffset(0,0)
	Search:SetText(PA.ACL['Search'])
	Search.AddOns = {}
	Search:HookScript('OnEscapePressed', function(self) stAM:UpdateAddonList() self:SetText("Search") self:ClearFocus()end)
	Search:HookScript('OnTextChanged', function(self, userInput) stAM.scrollOffset = 0 stAM.searchQuery = userInput stAM:UpdateAddonList() end)
	Search:HookScript('OnEditFocusGained', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) self:HighlightText() end)
	Search:HookScript('OnEditFocusLost', function(self) self:SetTemplate() self:HighlightText(0, 0) end)
	Search:HookScript('OnEnterPressed', function(self)
		if strlen(strtrim(self:GetText())) == 0 then
			stAM:UpdateAddonList()
			self:SetText("Search")
			stAM.searchQuery = false
		end
		self:ClearFocus()
	end)

	Reload:SetTemplate()
	Reload:SetSize(70, 20)
	Reload:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	Reload:SetScript('OnLeave', function(self) self:SetTemplate() end)
	Reload:SetScript('OnClick', _G.ReloadUI)
	Reload.Text = Reload:CreateFontString(nil, 'OVERLAY')
	Reload.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	Reload.Text:SetText(PA.ACL['Reload'])
	Reload.Text:SetPoint('CENTER', 0, 0)
	Reload.Text:SetJustifyH('CENTER')
	Reload:SetPoint('TOPLEFT', AddOns, 'BOTTOMLEFT', 0, -10)

	CharacterSelect:SetPoint('TOPRIGHT', AddOns, 'BOTTOMRIGHT', 0, -10)
	CharacterSelect.DropDown = CreateFrame('Frame', 'stAMCharacterSelectDropDown', CharacterSelect, 'UIDropDownMenuTemplate')
	CharacterSelect:SetSize(150, 20)
	CharacterSelect:SetTemplate()
	CharacterSelect:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	CharacterSelect:SetScript('OnLeave', function(self) self:SetTemplate() end)
	CharacterSelect:SetScript('OnClick', function(self) EasyMenu(stAM.Menu, self.DropDown, self, 0, 38 + (stAM.MenuOffset * 16), "MENU", 5) end)
	CharacterSelect.Text = CharacterSelect:CreateFontString(nil, 'OVERLAY')
	CharacterSelect.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	CharacterSelect.Text:SetText(PA.ACL['Character Select'])
	CharacterSelect.Text:SetPoint('CENTER', 0, 0)
	CharacterSelect.Text:SetJustifyH('CENTER')

	Profiles:SetPoint('TOPRIGHT', Title, 'BOTTOMRIGHT', -10, -10)
	Profiles:SetTemplate()
	Profiles:SetSize(70, 20)
	Profiles:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	Profiles:SetScript('OnLeave', function(self) self:SetTemplate() end)
	Profiles:SetScript('OnClick', function() stAM:ToggleProfiles() end)

	Profiles.Text = Profiles:CreateFontString(nil, 'OVERLAY')
	Profiles.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	Profiles.Text:SetText(PA.ACL['Profiles'])
	Profiles.Text:SetPoint('CENTER', 0, 0)
	Profiles.Text:SetJustifyH('CENTER')

	AddOns:SetPoint('TOPLEFT', Search, 'BOTTOMLEFT', 0, -5)
	AddOns:SetPoint('TOPRIGHT', Profiles, 'BOTTOMRIGHT', 0, -5)
	AddOns:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 15)
	AddOns:SetTemplate()
	AddOns.Buttons = {}
	AddOns:EnableMouse(true)
	AddOns:EnableMouseWheel(true)

	Slider:SetPoint("RIGHT", -2, 0)
	Slider:SetWidth(12)
	Slider:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 11)
	Slider:SetThumbTexture(PA.LSM:Fetch('background', 'Solid'))
	Slider:SetOrientation("VERTICAL")
	Slider:SetValueStep(1)
	Slider:SetTemplate()
	Slider:SetMinMaxValues(0, 1)
	Slider:SetValue(0)
	Slider:EnableMouse(true)
	Slider:EnableMouseWheel(true)

	local Thumb = Slider:GetThumbTexture()
	Thumb:Width(8)
	Thumb:Height(16)
	Thumb:SetVertexColor(AddOns:GetBackdropBorderColor())

	AddOns.ScrollBar = Slider

	local OnScroll = function(self, delta)
		local numAddons = stAM.searchQuery and #Search.AddOns or #stAM.AddOnInfo
		if IsShiftKeyDown() then
			if delta == 1 then
				stAM.scrollOffset = max(0, stAM.scrollOffset - stAM.db['NumAddOns'])
			elseif delta == -1 then
				stAM.scrollOffset = min(numAddons - stAM.db['NumAddOns'], stAM.scrollOffset + stAM.db['NumAddOns'])
			end
		else
			if delta == 1 and stAM.scrollOffset > 0 then
				stAM.scrollOffset = stAM.scrollOffset - 1
			elseif delta == -1 then
				if stAM.scrollOffset < numAddons - stAM.db['NumAddOns'] then
					stAM.scrollOffset = stAM.scrollOffset + 1
				end
			end
		end
		Slider:SetMinMaxValues(0, (numAddons - stAM.db['NumAddOns']))
		Slider:SetValue(stAM.scrollOffset)
		stAM:UpdateAddonList()
	end

	AddOns:SetScript('OnMouseWheel', OnScroll)
	Slider:SetScript('OnMouseWheel', OnScroll)
	Slider:SetScript('OnValueChanged', function(self, value)
		stAM.scrollOffset = value
		OnScroll()
	end)

	for i = 1, 30 do
		local CheckButton = CreateFrame('CheckButton', 'stAMCheckButton_'..i, AddOns)
		CheckButton:SetTemplate()
		CheckButton:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		CheckButton:SetPoint(unpack(i == 1 and {"TOPLEFT", AddOns, "TOPLEFT", 10, -10} or {"TOP", AddOns.Buttons[i-1], "BOTTOM", 0, -5}))
		CheckButton:SetScript('OnClick', function(self)
			if self.name then
				if PA:IsAddOnEnabled(self.name, stAM.SelectedCharacter) then
					DisableAddOn(self.name, stAM.SelectedCharacter)
				else
					EnableAddOn(self.name, stAM.SelectedCharacter)
				end
				stAM:UpdateAddonList()
			end
		end)
		CheckButton:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 0, 4)
			GameTooltip:ClearLines()
			GameTooltip:AddDoubleLine('AddOn:', self.title, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine(PA.ACL['Authors:'], self.author, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine('Notes:', self.notes, 1, 1, 1, 1, 1, 1)
			if self.requireddeps or self.optionaldeps then
				GameTooltip:AddLine(' ')
			end
			if self.requireddeps then
				GameTooltip:AddDoubleLine('Required Dependencies:', self.requireddeps, 1, 1, 1, 1, 1, 1)
			end
			if self.optionaldeps then
				GameTooltip:AddDoubleLine('Optional Dependencies:', self.optionaldeps, 1, 1, 1, 1, 1, 1)
			end
			GameTooltip:Show()
			self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
		end)
		CheckButton:SetScript('OnLeave', function(self) self:SetTemplate() GameTooltip:Hide() end)

		local Checked = CheckButton:CreateTexture(nil, 'OVERLAY', nil, 1)
		Checked:SetTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
		Checked:SetVertexColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
		Checked:SetInside(CheckButton)

		CheckButton.CheckTexture = Checked
		CheckButton:SetCheckedTexture(Checked)

		CheckButton:SetHighlightTexture('')

		local Text = CheckButton:CreateFontString(nil, 'OVERLAY')
		Text:SetPoint('LEFT', 5, 0)
		Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), self.db['FontSize'], self.db['FontFlag'])
		Text:SetText('')
		Text:SetJustifyH('CENTER')
		Text:ClearAllPoints()
		Text:SetPoint("LEFT", CheckButton, "RIGHT", 10, 0)
		Text:SetPoint("TOP", CheckButton, "TOP")
		Text:SetPoint("BOTTOM", CheckButton, "BOTTOM")
		Text:SetPoint("RIGHT", AddOns, "RIGHT", -10, 0)
		Text:SetJustifyH("LEFT")

		CheckButton.Text = Text

		AddOns.Buttons[i] = CheckButton
	end

	Frame.Title = Title
	Frame.Close = Close
	Frame.Reload = Reload
	Frame.Search = Search
	Frame.CharacterSelect = CharacterSelect
	Frame.Profiles = Profiles
	Frame.AddOns = AddOns
	self.Frame = Frame

	tinsert(_G.UISpecialFrames, self.Frame:GetName())

	_G.GameMenuButtonAddons:SetScript("OnClick", function() self.Frame:Show() _G.HideUIPanel(_G.GameMenuFrame) end)
end

function stAM:NewAddOnProfile(name, overwrite)
	if _G.stAddonManagerProfilesDB[name] and (not overwrite) then
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].text = format(PA.ACL['There is already a profile named %s. Do you want to overwrite it?'], name)
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].OnAccept = function(self) stAM:NewAddOnProfile(name, true) end
		_G.StaticPopup_Show('STADDONMANAGER_OVERWRITEPROFILE')
		return
	end

	_G.stAddonManagerProfilesDB[name] = {}

	for i = 1, #self.AddOnInfo do
		local AddOn, isEnabled = unpack(self.AddOnInfo[i]), PA:IsAddOnEnabled(i, stAM.SelectedCharacter)
		if isEnabled then
			tinsert(_G.stAddonManagerProfilesDB[name], AddOn)
		end
	end

	self:UpdateProfiles()
end

function stAM:InitProfiles()
	local ProfileMenu = CreateFrame('Frame', 'stAMProfileMenu', self.Frame)
	ProfileMenu:SetPoint('TOPLEFT', self.Frame, 'TOPRIGHT', 3, 0)
	ProfileMenu:SetSize(250, 50)
	ProfileMenu:SetTemplate('Transparent')
	ProfileMenu:Hide()

	for _, name in pairs({'EnableAll', 'DisableAll', 'NewButton'}) do
		local Button = CreateFrame('Button', nil, ProfileMenu)
		Button:SetTemplate()
		Button:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		Button:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
		Button:SetScript('OnLeave', function(self) self:SetTemplate() end)

		Button.Text = Button:CreateFontString(nil, 'OVERLAY')
		Button.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, 'OUTLINE')
		Button.Text:SetPoint('CENTER', 0, 0)
		Button.Text:SetJustifyH('CENTER')

		ProfileMenu[name] = Button
	end

	ProfileMenu.EnableAll.Text:SetText(PA.ACL['Enable All'])
	ProfileMenu.EnableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOPLEFT', 10, -10)
	ProfileMenu.EnableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOP', -3, -10)
	ProfileMenu.EnableAll:SetScript('OnClick', function(self)
		EnableAllAddOns(stAM.SelectedCharacter)
		stAM:UpdateAddonList()
	end)

	ProfileMenu.DisableAll.Text:SetText(PA.ACL['Disable All'])
	ProfileMenu.DisableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOPRIGHT', -10, -10)
	ProfileMenu.DisableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOP', 2, -10)
	ProfileMenu.DisableAll:SetScript('OnClick', function(self)
		DisableAllAddOns(stAM.SelectedCharacter)
		stAM:UpdateAddonList()
	end)

	ProfileMenu.NewButton:SetPoint('TOPLEFT', ProfileMenu.EnableAll, 'BOTTOMLEFT', 0, -5)
	ProfileMenu.NewButton:SetPoint('TOPRIGHT', ProfileMenu.DisableAll, 'BOTTOMRIGHT', 0, -5)
	ProfileMenu.NewButton:SetScript('OnClick', function() _G.StaticPopup_Show('STADDONMANAGER_NEWPROFILE') end)
	ProfileMenu.NewButton.Text:SetText(PA.ACL['New Profile'])

	ProfileMenu.Buttons = {}

	for i = 1, 10 do
		local Pullout = CreateFrame('Frame', nil, ProfileMenu)
		Pullout:SetWidth(210)
		Pullout:SetHeight(stAM.db.ButtonHeight)
		Pullout:Hide()

		for _, Frame in pairs({'Load', 'Delete', 'Update'}) do
			local Button = CreateFrame('Button', nil, Pullout)
			Button:SetTemplate()
			Button:SetSize(73, stAM.db.ButtonHeight)
			Button:RegisterForClicks('AnyDown')
			Button:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
			Button:SetScript('OnLeave', function(self) self:SetTemplate() end)

			Button.Text = Button:CreateFontString(nil, 'OVERLAY')
			Button.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, 'OUTLINE')
			Button.Text:SetPoint('CENTER', 0, 0)
			Button.Text:SetJustifyH('CENTER')

			Pullout[Frame] = Button
		end

		Pullout.Load:SetPoint('LEFT', Pullout, 0, 0)
		Pullout.Load.Text:SetText('Load')
		Pullout.Load:SetScript('OnClick', function(self, btn)
			if btn == 'RightButton' then
				local Dialog = _G.StaticPopupDialogs['STADDONMANAGER_RENAMEPROFILE']
				Dialog.OnAccept = function(self)
					_G.stAddonManagerProfilesDB[Pullout.Name] = nil
					stAM:NewAddOnProfile(self.editBox:GetText())
					stAM:UpdateProfiles()
				end
				Dialog.EditBoxOnEnterPressed = function(self)
					_G.stAddonManagerProfilesDB[Pullout.Name] = nil
					stAM:NewAddOnProfile(self:GetText())
					stAM:UpdateProfiles()
					self:GetParent():Hide()
				end
				_G.StaticPopup_Show('STADDONMANAGER_RENAMEPROFILE')
			else
				if not IsShiftKeyDown() then
					DisableAllAddOns(stAM.SelectedCharacter)
				end
				for _, AddOn in pairs(_G.stAddonManagerProfilesDB[Pullout.Name]) do
					EnableAddOn(AddOn, stAM.SelectedCharacter)
				end

				stAM:UpdateAddonList()
			end
		end)

		Pullout.Update:SetPoint('LEFT', Pullout.Load, 'RIGHT', 5, 0)
		Pullout.Update.Text:SetText(PA.ACL['Update'])
		Pullout.Update:SetScript('OnClick', function(self)
			stAM:NewAddOnProfile(Pullout.Name, true)
		end)

		Pullout.Delete:SetPoint('LEFT', Pullout.Update, 'RIGHT', 5, 0)
		Pullout.Delete.Text:SetText(PA.ACL['Delete'])
		Pullout.Delete:SetScript('OnClick', function(self)
			local dialog = _G.StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION']

			dialog.text = format(PA.ACL['Are you sure you want to delete %s?'], Pullout.Name)
			dialog.OnAccept = function(self)
				_G.stAddonManagerProfilesDB[Pullout.Name] = nil
				stAM:UpdateProfiles()
			end

			_G.StaticPopup_Show('STADDONMANAGER_DELETECONFIRMATION')
		end)

		ProfileMenu.Buttons[i] = Pullout
	end

	self.ProfileMenu = ProfileMenu
end

function stAM:UpdateProfiles()
	local ProfileMenu = self.ProfileMenu
	local Buttons = self.ProfileMenu.Buttons

	wipe(self.Profiles)

	for name, _ in pairs(_G.stAddonManagerProfilesDB) do
		tinsert(self.Profiles, name)
	end

	sort(self.Profiles)

	for i = 1, #Buttons do
		Buttons[i]:Hide()
		Buttons[i].Name = nil
	end

	for i = 1, #self.Profiles do
		if i == 1 then
			Buttons[i]:SetPoint("TOPLEFT", ProfileMenu.NewButton, "BOTTOMLEFT", 0, -5)
		else
			Buttons[i]:SetPoint("TOP", Buttons[i-1], "BOTTOM", 0, -5)
		end

		Buttons[i]:Show()
		Buttons[i].Load.Text:SetText(self.Profiles[i])
		Buttons[i].Name = self.Profiles[i]
	end

	ProfileMenu:SetHeight((#self.Profiles+2)*(stAM.db.ButtonHeight+5) + 15)
end

function stAM:ToggleProfiles()
	_G.ToggleFrame(self.ProfileMenu)
	self:UpdateProfiles()
end

function stAM:UpdateAddonList()
	if self.searchQuery then
		local query = strlower(strtrim(self.Frame.Search:GetText()))

		if (strlen(query) == 0) then
			self.searchQuery = false
		end

		wipe(self.Frame.Search.AddOns)

		for i = 1, #self.AddOnInfo do
			local name, title = unpack(self.AddOnInfo[i])

			if strfind(strlower(name), query) or strfind(strlower(title), query) then
				tinsert(self.Frame.Search.AddOns, i)
			end
		end
	end

	for i = 1, self.db['NumAddOns'] do
		local addonIndex = (not self.searchQuery and (stAM.scrollOffset + i)) or self.Frame.Search.AddOns[stAM.scrollOffset + i]
		local button = self.Frame.AddOns.Buttons[i]
		if addonIndex and addonIndex <= #self.AddOnInfo then
			button.name, button.title, button.author, button.notes, button.requireddeps, button.optionaldeps = unpack(self.AddOnInfo[addonIndex])
			button.Text:SetText(button.title)
			button:SetChecked(PA:IsAddOnPartiallyEnabled(addonIndex, stAM.SelectedCharacter) or PA:IsAddOnEnabled(addonIndex, stAM.SelectedCharacter))
			button.CheckTexture:SetVertexColor(unpack(PA:IsAddOnPartiallyEnabled(addonIndex, stAM.SelectedCharacter) and {.6, .6, .6} or stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
			button:Show()
		else
			button:Hide()
		end
	end

	for i = self.db['NumAddOns'] + 1, #self.Frame.AddOns.Buttons do
		self.Frame.AddOns.Buttons[i]:Hide()
	end

	self.Frame.AddOns:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 15)
	self.Frame:SetSize(self.db['FrameWidth'], self.Frame.Title:GetHeight() + 5 + self.Frame.Search:GetHeight() + 5  + self.Frame.AddOns:GetHeight() + 10 + self.Frame.Profiles:GetHeight() + 20)
end

function stAM:Update()
	for i = 1, 30 do
		local CheckButton = self.Frame.AddOns.Buttons[i]

		CheckButton:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		CheckButton.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), self.db['FontSize'], self.db['FontFlag'])
		CheckButton.CheckTexture:SetTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
		CheckButton.CheckTexture:SetVertexColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
		CheckButton:SetCheckedTexture(CheckButton.CheckTexture)
	end

	-- Frame fonts
	self.Frame.Title:SetFont(PA.LSM:Fetch('font', self.db['Font']), 14, self.db['FontFlag'])
	self.Frame.Close.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	self.Frame.Search:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	self.Frame.Reload.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	self.Frame.Profiles.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])
	self.Frame.CharacterSelect.Text:SetFont(PA.LSM:Fetch('font', self.db['Font']), 12, self.db['FontFlag'])

	stAM:UpdateAddonList()
end

function stAM:GetOptions()
	local Options = {
		type = 'group',
		name = stAM.Title,
		desc = stAM.Description,
		order = 219,
		get = function(info) return stAM.db[info[#info]] end,
		set = function(info, value) stAM.db[info[#info]] = value stAM:Update() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(stAM.Title),
			},
			NumAddOns = {
				order = 1,
				type = 'range',
				name = PA.ACL['# Shown AddOns'],
				min = 3, max = 30, step = 1,
			},
			FrameWidth = {
				order = 2,
				type = 'range',
				name = PA.ACL['Frame Width'],
				min = 225, max = 1024, step = 1,
			},
			ButtonHeight = {
				order = 3,
				type = 'range',
				name = PA.ACL['Button Height'],
				min = 3, max = 30, step = 1,
			},
			ButtonWidth = {
				order = 4,
				type = 'range',
				name = PA.ACL['Button Width'],
				min = 3, max = 30, step = 1,
			},
			Font = {
				type = 'select', dialogControl = 'LSM30_Font',
				order = 5,
				name = PA.ACL['Font'],
				values = PA.LSM:HashTable('font'),
			},
			FontSize = {
				order = 6,
				name = FONT_SIZE,
				type = 'range',
				min = 6, max = 22, step = 1,
			},
			FontFlag = {
				order = 7,
				name = PA.ACL['Font Outline'],
				type = 'select',
				values = {
					['NONE'] = 'None',
					['OUTLINE'] = 'OUTLINE',
					['MONOCHROME'] = 'MONOCHROME',
					['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
					['THICKOUTLINE'] = 'THICKOUTLINE',
				},
			},
			CheckTexture = {
				order = 8,
				type = 'select', dialogControl = 'LSM30_Statusbar',
				name = PA.ACL['Texture'],
				values = PA.LSM:HashTable('statusbar'),
			},
			CheckColor = {
				order = 9,
				type = 'color',
				name = COLOR_PICKER,
				hasAlpha = true,
				get = function(info) return unpack(stAM.db[info[#info]]) end,
				set = function(info, r, g, b, a) stAM.db[info[#info]] = { r, g, b, a} stAM:Update() end,
				disabled = function() return stAM.db['ClassColor'] end,
			},
			ClassColor = {
				order = 10,
				type = 'toggle',
				name = PA.ACL['Class Color Check Texture'],
			},
			AuthorHeader = {
				order = 11,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = 12,
				type = 'description',
				name = stAM.Authors,
				fontSize = 'large',
			},
		},
	}

	Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(stAM.data)
	Options.args.profiles.order = -2

	PA.Options.args.stAM = Options
end

function stAM:BuildProfile()
	self.data = PA.ADB:New('stAddonManagerDB', {
		profile = {
			['NumAddOns'] = 30,
			['FrameWidth'] = 550,
			['Font'] = 'PT Sans Narrow',
			['FontSize'] = 16,
			['FontFlag'] = 'OUTLINE',
			['ButtonHeight'] = 18,
			['ButtonWidth'] = 22,
			['CheckColor'] = { 0, .66, 1},
			['ClassColor'] = false,
			['CheckTexture'] = 'Blizzard Raid Bar'
		},
	}, true)
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function stAM:SetupProfile()
	self.db = self.data.profile
end

function stAM:Initialize()
	stAM:BuildProfile()
	stAM:GetOptions()

	stAM.AddOnInfo = {}
	stAM.Profiles = {}

	for i = 1, GetNumAddOns() do
		local name, title, notes = GetAddOnInfo(i)
		local requireddeps, optionaldeps = GetAddOnDependencies(i), GetAddOnOptionalDependencies(i)
		local author = GetAddOnMetadata(i, "Author")
		stAM.AddOnInfo[i] = { name, title, author, notes, requireddeps, optionaldeps }
	end

	stAM.SelectedCharacter = PA.MyName

	stAM.Menu = {
		{ text = 'All', checked = function() return stAM.SelectedCharacter == true end, func = function() stAM.SelectedCharacter = true stAM:UpdateAddonList() end}
	}

	_G.stAddonManagerServerDB[PA.MyRealm] = _G.stAddonManagerServerDB[PA.MyRealm] or {}
	_G.stAddonManagerServerDB[PA.MyRealm][PA.MyName] = true

	local index = 2
	for Character in PA:PairsByKeys(_G.stAddonManagerServerDB[PA.MyRealm]) do
		stAM.Menu[index] = { text = Character, checked = function() return stAM.SelectedCharacter == Character end, func = function() stAM.SelectedCharacter = Character stAM:UpdateAddonList() end }
		index = index + 1
	end

	stAM.MenuOffset = index

	stAM.scrollOffset = 0

	stAM:BuildFrame()
	stAM:InitProfiles()
end
