local PA = _G.ProjectAzilroka
local stAM = PA:NewModule('stAddonManager', 'AceEvent-3.0')
PA.stAM, _G.stAddonManager = stAM, stAM

_G.stAddonManagerProfilesDB = {}
_G.stAddonManagerServerDB = {}

stAM.Title = '|cFF16C3F2st|r|cFFFFFFFFAddonManager|r'
stAM.Description = 'A simple and minimalistic addon to disable/enabled addons without logging out.'
stAM.Authors = 'Azilroka    Safturento'

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
	local Search = CreateFrame('EditBox', 'stAMSearchBox', Frame)

	local Profiles = CreateFrame('Button', 'stAMProfiles', Frame)
	local AddOns = CreateFrame("Frame", 'stAMAddOns', Frame)
	local Slider = CreateFrame("Slider", nil, AddOns)

	local Reload = CreateFrame('Button', 'stAMReload', Frame)
	local RequiredAddons = CreateFrame('CheckButton', nil, Frame)
	local OptionalAddons = CreateFrame('CheckButton', nil, Frame)
	local CharacterSelect = CreateFrame('Button', nil, Frame)

	local Title = Frame:CreateFontString(nil, 'OVERLAY')

	-- Defines
	local font, fontSize, fontFlag = PA.LSM:Fetch('font', self.db['Font']), self.db['FontSize'], self.db['FontFlag']

	Frame:SetSize(self.db['FrameWidth'], 10 + self.db['NumAddOns'] * 25 + 40)
	Frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	PA:SetTemplate(Frame)
	Frame:SetFrameStrata('HIGH')
	Frame:SetClampedToScreen(true)
	Frame:SetMovable(true)
	Frame:EnableMouse(true)
	Frame:SetScript("OnMouseDown", function(self) self:StartMoving() end)
	Frame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	Title:SetPoint('TOPLEFT', 0, -5)
	Title:SetPoint('TOPRIGHT', 0, -5)
	Title:SetFont(font, 14, fontFlag)
	Title:SetText(stAM.Title)
	Title:SetJustifyH('CENTER')
	Title:SetJustifyV('MIDDLE')

	PA:SetTemplate(Close)
	Close:SetPoint('TOPRIGHT', -3, -3)
	Close:SetSize(16, 16)
	Close:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	Close:SetScript('OnLeave', function(self) PA:SetTemplate(self) end)
	Close:SetScript('OnClick', function(self) Frame:Hide() end)

	local Mask = Close:CreateMaskTexture()
	Mask:SetTexture([[Interface\AddOns\ProjectAzilroka\Media\Textures\Close]], 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
	Mask:SetSize(10, 10)
	Mask:SetPoint('CENTER')

	Close.Mask = Mask

	Close:SetNormalTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
	Close:SetPushedTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))

	local Normal, Pushed = Close:GetNormalTexture(), Close:GetPushedTexture()

	PA:SetInside(Normal, Close)
	Normal:SetVertexColor(1, 1, 1)
	Normal:AddMaskTexture(Mask)

	PA:SetInside(Pushed, Close)
	Pushed:SetVertexColor(1, .2, .2)
	Pushed:AddMaskTexture(Mask)

	Search:SetPoint('TOPLEFT', Title, 'BOTTOMLEFT', 10, -10)
	Search:SetPoint('BOTTOMRIGHT', Profiles, 'BOTTOMLEFT', -5, 0)
	Search:SetSize(1, 20)
	PA:SetTemplate(Search)
	Search:SetAutoFocus(false)
	Search:SetTextInsets(5, 5, 0, 0)
	Search:SetTextColor(1, 1, 1)
	Search:SetFont(font, 12, fontFlag)
	Search:SetShadowOffset(0,0)
	Search:SetText(PA.ACL['Search'])
	Search.AddOns = {}
	Search:HookScript('OnEscapePressed', function(self) stAM:UpdateAddonList() self:SetText("Search") self:ClearFocus()end)
	Search:HookScript('OnTextChanged', function(self, userInput) stAM.scrollOffset = 0 stAM.searchQuery = userInput stAM:UpdateAddonList() end)
	Search:HookScript('OnEditFocusGained', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) self:HighlightText() end)
	Search:HookScript('OnEditFocusLost', function(self) PA:SetTemplate(self) self:HighlightText(0, 0) end)
	Search:HookScript('OnEnterPressed', function(self)
		if strlen(strtrim(self:GetText())) == 0 then
			stAM:UpdateAddonList()
			self:SetText("Search")
			stAM.searchQuery = false
		end
		self:ClearFocus()
	end)

	PA:SetTemplate(Reload)
	Reload:SetSize(70, 20)
	Reload:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	Reload:SetScript('OnLeave', function(self) PA:SetTemplate(self) end)
	Reload:SetScript('OnClick', _G.ReloadUI)
	Reload.Text = Reload:CreateFontString(nil, 'OVERLAY')
	Reload.Text:SetFont(font, 12, fontFlag)
	Reload.Text:SetText(PA.ACL['Reload'])
	Reload.Text:SetPoint('CENTER', 0, 0)
	Reload.Text:SetJustifyH('CENTER')
	Reload:SetPoint('TOPLEFT', AddOns, 'BOTTOMLEFT', 0, -10)

	RequiredAddons:SetPoint('LEFT', Reload, 'RIGHT', 50, 0)
	PA:SetTemplate(RequiredAddons)
	RequiredAddons:SetSize(20, 20)
	RequiredAddons:SetScript('OnClick', function(self)
		stAM.db.EnableRequiredAddons = not stAM.db.EnableRequiredAddons
	end)
	RequiredAddons:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(PA.ACL['Enable Required AddOns'], 1, 1, 1)
		GameTooltip:AddLine(PA.ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'], 1, 1, 1)
		GameTooltip:Show()
	end)
	RequiredAddons:SetScript('OnLeave', function(self) PA:SetTemplate(self) GameTooltip:Hide() end)

	RequiredAddons.CheckTexture = RequiredAddons:CreateTexture(nil, 'OVERLAY', nil, 1)
	RequiredAddons.CheckTexture:SetTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
	RequiredAddons.CheckTexture:SetVertexColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
	PA:SetInside(RequiredAddons.CheckTexture, RequiredAddons)

	RequiredAddons:SetCheckedTexture(RequiredAddons.CheckTexture)
	RequiredAddons:SetHighlightTexture('')

	RequiredAddons.Text = RequiredAddons:CreateFontString(nil, 'OVERLAY')
	RequiredAddons.Text:SetPoint('LEFT', RequiredAddons, 'RIGHT', 5, 0)
	RequiredAddons.Text:SetFont(font, 12, fontFlag)
	RequiredAddons.Text:SetText(PA.ACL['Required'])

	RequiredAddons:SetChecked(stAM.db.EnableRequiredAddons)

	CharacterSelect:SetPoint('TOPRIGHT', AddOns, 'BOTTOMRIGHT', 0, -10)
	CharacterSelect.DropDown = CreateFrame('Frame', 'stAMCharacterSelectDropDown', CharacterSelect, 'UIDropDownMenuTemplate')
	CharacterSelect:SetSize(150, 20)
	PA:SetTemplate(CharacterSelect)
	CharacterSelect:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	CharacterSelect:SetScript('OnLeave', function(self) PA:SetTemplate(self) end)
	CharacterSelect:SetScript('OnClick', function(self) EasyMenu(stAM.Menu, self.DropDown, self, 0, 38 + (stAM.MenuOffset * 16), "MENU", 5) end)
	CharacterSelect.Text = CharacterSelect:CreateFontString(nil, 'OVERLAY')
	CharacterSelect.Text:SetFont(font, 12, fontFlag)
	CharacterSelect.Text:SetText(PA.ACL['Character Select'])
	CharacterSelect.Text:SetPoint('CENTER', 0, 0)
	CharacterSelect.Text:SetJustifyH('CENTER')

	Profiles:SetPoint('TOPRIGHT', Title, 'BOTTOMRIGHT', -10, -10)
	PA:SetTemplate(Profiles)
	Profiles:SetSize(70, 20)
	Profiles:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
	Profiles:SetScript('OnLeave', function(self) PA:SetTemplate(self) end)
	Profiles:SetScript('OnClick', function() stAM:ToggleProfiles() end)

	Profiles.Text = Profiles:CreateFontString(nil, 'OVERLAY')
	Profiles.Text:SetFont(font, 12, fontFlag)
	Profiles.Text:SetText(PA.ACL['Profiles'])
	Profiles.Text:SetPoint('CENTER', 0, 0)
	Profiles.Text:SetJustifyH('CENTER')

	AddOns:SetPoint('TOPLEFT', Search, 'BOTTOMLEFT', 0, -5)
	AddOns:SetPoint('TOPRIGHT', Profiles, 'BOTTOMRIGHT', 0, -5)
	AddOns:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 15)
	PA:SetTemplate(AddOns)
	AddOns.Buttons = {}
	AddOns:EnableMouse(true)
	AddOns:EnableMouseWheel(true)

	Slider:SetPoint("RIGHT", -2, 0)
	Slider:SetWidth(12)
	Slider:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 11)
	Slider:SetThumbTexture(PA.LSM:Fetch('background', 'Solid'))
	Slider:SetOrientation("VERTICAL")
	Slider:SetValueStep(1)
	PA:SetTemplate(Slider)
	Slider:SetMinMaxValues(0, 1)
	Slider:SetValue(0)
	Slider:EnableMouse(true)
	Slider:EnableMouseWheel(true)

	local Thumb = Slider:GetThumbTexture()
	Thumb:SetSize(8, 16)
	Thumb:SetVertexColor(Slider:GetBackdropBorderColor())

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
		PA:SetTemplate(CheckButton)
		CheckButton:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		CheckButton:SetPoint(unpack(i == 1 and {"TOPLEFT", AddOns, "TOPLEFT", 10, -10} or {"TOP", AddOns.Buttons[i-1], "BOTTOM", 0, -5}))
		CheckButton:SetScript('OnClick', function(self)
			if self.name then
				if PA:IsAddOnEnabled(self.name, stAM.SelectedCharacter) then
					DisableAddOn(self.name, stAM.SelectedCharacter)
				else
					EnableAddOn(self.name, stAM.SelectedCharacter)
					if stAM.db.EnableRequiredAddons and self.required then
						for _, AddOn in pairs(self.required) do
							EnableAddOn(AddOn)
						end
					end
				end
				stAM:UpdateAddonList()
			end
		end)
		CheckButton:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 0, 4)
			GameTooltip:ClearLines()
			GameTooltip:AddDoubleLine('AddOn:', self.title, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine(PA.ACL['Authors:'], self.authors, 1, 1, 1, 1, 1, 1)
			if self.notes ~= nil then
				GameTooltip:AddDoubleLine('Notes:', self.notes, 1, 1, 1, 1, 1, 1)
			end
			if self.required or self.optional then
				GameTooltip:AddLine(' ')
			end
			if self.required then
				GameTooltip:AddDoubleLine('Required Dependencies:', table.concat(self.required, ", "), 1, 1, 1, 1, 1, 1)
			end
			if self.optional then
				GameTooltip:AddDoubleLine('Optional Dependencies:', table.concat(self.optional, ", "), 1, 1, 1, 1, 1, 1)
			end
			GameTooltip:Show()
			self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
		end)
		CheckButton:SetScript('OnLeave', function(self) PA:SetTemplate(self) GameTooltip:Hide() end)

		local Checked = CheckButton:CreateTexture(nil, 'OVERLAY', nil, 1)
		Checked:SetTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
		Checked:SetVertexColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
		PA:SetInside(Checked, CheckButton)

		CheckButton.CheckTexture = Checked
		CheckButton:SetCheckedTexture(Checked)

		CheckButton:SetHighlightTexture('')

		local Text = CheckButton:CreateFontString(nil, 'OVERLAY')
		Text:SetFont(font, fontSize, fontFlag)
		Text:SetText('')
		Text:SetJustifyH('CENTER')
		Text:ClearAllPoints()
		Text:SetPoint("LEFT", CheckButton, "RIGHT", 10, 0)
		Text:SetPoint("TOP", CheckButton, "TOP")
		Text:SetPoint("BOTTOM", CheckButton, "BOTTOM")
		Text:SetPoint("RIGHT", AddOns, "CENTER", 0, 0)
		Text:SetJustifyH("LEFT")

		CheckButton.Text = Text

		local StatusText = CheckButton:CreateFontString(nil, 'OVERLAY')
		StatusText:SetFont(font, fontSize, fontFlag)
		StatusText:SetText('')
		StatusText:SetJustifyH('CENTER')
		StatusText:ClearAllPoints()
		StatusText:SetPoint("LEFT", Text, "RIGHT", 0, 0)
		StatusText:SetPoint("TOP", CheckButton, "TOP")
		StatusText:SetPoint("BOTTOM", CheckButton, "BOTTOM")
		StatusText:SetPoint("RIGHT", AddOns, "RIGHT", -10, 0)
		StatusText:SetJustifyH("LEFT")

		CheckButton.StatusText = StatusText

		local Icon = CheckButton:CreateTexture(nil, 'OVERLAY')
		Icon:SetTexture([[Interface\AddOns\ProjectAzilroka\Media\Textures\QuestBang]])
		Icon:SetPoint('CENTER', CheckButton, 'RIGHT', 10, 0)
		Icon:SetSize(32, 32)

		CheckButton.Icon = Icon

		AddOns.Buttons[i] = CheckButton
	end

	Frame.Title = Title
	Frame.Close = Close
	Frame.Reload = Reload
	Frame.RequiredAddons = RequiredAddons
	Frame.OptionalAddons = OptionalAddons
	Frame.Search = Search
	Frame.CharacterSelect = CharacterSelect
	Frame.Profiles = Profiles
	Frame.AddOns = AddOns

	Frame.AddOns:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 15)
	Frame:SetSize(self.db['FrameWidth'], Frame.Title:GetHeight() + 5 + Frame.Search:GetHeight() + 5  + Frame.AddOns:GetHeight() + 10 + Frame.Profiles:GetHeight() + 20)

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
	PA:SetTemplate(ProfileMenu)
	ProfileMenu:Hide()

	for _, name in pairs({'EnableAll', 'DisableAll', 'NewButton'}) do
		local Button = CreateFrame('Button', nil, ProfileMenu)
		PA:SetTemplate(Button)
		Button:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		Button:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
		Button:SetScript('OnLeave', function(self) PA:SetTemplate(self) end)

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

	ProfileMenu.NewButton.Text:SetText(PA.ACL['New Profile'])
	ProfileMenu.NewButton:SetPoint('TOPLEFT', ProfileMenu.EnableAll, 'BOTTOMLEFT', 0, -5)
	ProfileMenu.NewButton:SetPoint('TOPRIGHT', ProfileMenu.DisableAll, 'BOTTOMRIGHT', 0, -5)
	ProfileMenu.NewButton:SetScript('OnClick', function() _G.StaticPopup_Show('STADDONMANAGER_NEWPROFILE') end)

	ProfileMenu.Buttons = {}

	for i = 1, 10 do
		local Pullout = CreateFrame('Frame', nil, ProfileMenu)
		Pullout:SetWidth(210)
		Pullout:SetHeight(stAM.db.ButtonHeight)
		Pullout:Hide()

		for _, Frame in pairs({'Load', 'Delete', 'Update'}) do
			local Button = CreateFrame('Button', nil, Pullout)
			PA:SetTemplate(Button)
			Button:SetSize(73, stAM.db.ButtonHeight)
			Button:RegisterForClicks('AnyDown')
			Button:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor'])) end)
			Button:SetScript('OnLeave', function(self) PA:SetTemplate(self) end)

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
			local name, title, authors = self.AddOnInfo[i]['Name'], self.AddOnInfo[i]['Title'], self.AddOnInfo[i]['Authors']

			if strfind(strlower(name), query) or strfind(strlower(title), query) or (authors and strfind(strlower(authors), query)) then
				tinsert(self.Frame.Search.AddOns, i)
			end
		end
	end

	for i = 1, self.db['NumAddOns'] do
		local addonIndex = (not self.searchQuery and (stAM.scrollOffset + i)) or self.Frame.Search.AddOns[stAM.scrollOffset + i]
		local button = self.Frame.AddOns.Buttons[i]
		local info = self.AddOnInfo[addonIndex]
		if addonIndex and addonIndex <= #self.AddOnInfo then
			button.name, button.title, button.authors, button.notes, button.required, button.optional = info.Name, info.Title, info.Authors, info.Notes, info.Required, info.Optional
			button.Text:SetText(button.title)
			if info.Missing then
				button.Icon:SetVertexColor(.77, .12, .24)
				button.StatusText:SetVertexColor(.77, .12, .24)

				button.Icon:Show()
				button.Text:SetPoint('LEFT', button.Icon, 'CENTER', 5, 0)
				button.Text:SetPoint("RIGHT", self.Frame.AddOns, "CENTER", 0, 0)
				button.StatusText:SetText(PA.ACL['Missing: ']..table.concat(info.Missing, ', '))
			elseif info.Disabled then
				button.Icon:SetVertexColor(1, .8, .1)
				button.StatusText:SetVertexColor(1, .8, .1)

				button.Icon:Show()
				button.Text:SetPoint('LEFT', button.Icon, 'CENTER', 5, 0)
				button.Text:SetPoint("RIGHT", self.Frame.AddOns, "CENTER", 0, 0)
				button.StatusText:SetText(PA.ACL['Disabled: ']..table.concat(info.Disabled, ', '))
			else
				button.Icon:Hide()
				button.Text:SetPoint('LEFT', button, 'RIGHT', 5, 0)
				button.Text:SetPoint("RIGHT", self.Frame.AddOns, "RIGHT", -10, 0)
				button.StatusText:SetText('')
			end
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
end

function stAM:Update()
	self.Frame.AddOns:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 15)
	self.Frame:SetSize(self.db['FrameWidth'], self.Frame.Title:GetHeight() + 5 + self.Frame.Search:GetHeight() + 5  + self.Frame.AddOns:GetHeight() + 10 + self.Frame.Profiles:GetHeight() + 20)

	local font, fontSize, fontFlag = PA.LSM:Fetch('font', self.db['Font']), self.db['FontSize'], self.db['FontFlag']

	for i in pairs(self.Frame.AddOns.Buttons) do
		local CheckButton = self.Frame.AddOns.Buttons[i]

		CheckButton:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		CheckButton.Text:SetFont(font, fontSize, fontFlag)
		CheckButton.StatusText:SetFont(font, fontSize, fontFlag)
		CheckButton.CheckTexture:SetTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
		CheckButton.CheckTexture:SetVertexColor(unpack(stAM.db['ClassColor'] and PA.ClassColor or stAM.db['CheckColor']))
		CheckButton:SetCheckedTexture(CheckButton.CheckTexture)
	end

	self.Frame.Title:SetFont(font, 14, fontFlag)
	self.Frame.Search:SetFont(font, 12, fontFlag)
	self.Frame.Reload.Text:SetFont(font, 12, fontFlag)
	self.Frame.Profiles.Text:SetFont(font, 12, fontFlag)
	self.Frame.CharacterSelect.Text:SetFont(font, 12, fontFlag)
	self.Frame.RequiredAddons.Text:SetFont(font, 12, fontFlag)

	self.Frame.RequiredAddons:SetChecked(stAM.db.EnableRequiredAddons)
	self.Frame.OptionalAddons:SetChecked(stAM.db.EnableOptionalAddons)

	self.ProfileMenu.EnableAll.Text:SetFont(font, 12, fontFlag)
	self.ProfileMenu.DisableAll.Text:SetFont(font, 12, fontFlag)
	self.ProfileMenu.NewButton.Text:SetFont(font, 12, fontFlag)

	for i in pairs(self.ProfileMenu.Buttons) do
		local Button = self.ProfileMenu.Buttons[i]

		Button.Load.Text:SetFont(font, 12, fontFlag)
		Button.Update.Text:SetFont(font, 12, fontFlag)
		Button.Delete.Text:SetFont(font, 12, fontFlag)
	end

	stAM:UpdateAddonList()
end

function stAM:GetOptions()
	local Options = {
		type = 'group',
		name = stAM.Title,
		desc = stAM.Description,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(stAM.Title),
			},
			General = {
				order = 1,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				get = function(info) return stAM.db[info[#info]] end,
				set = function(info, value) stAM.db[info[#info]] = value stAM:Update() end,
				args = {
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
					EnableRequiredAddons ={
						order = 5,
						type = 'toggle',
						name = PA.ACL['Enable Required AddOns'],
						desc = PA.ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.']
					},
					CheckTexture = {
						order = 6,
						type = 'select', dialogControl = 'LSM30_Statusbar',
						name = PA.ACL['Texture'],
						values = PA.LSM:HashTable('statusbar'),
					},
					CheckColor = {
						order = 7,
						type = 'color',
						name = COLOR_PICKER,
						hasAlpha = true,
						get = function(info) return unpack(stAM.db[info[#info]]) end,
						set = function(info, r, g, b, a) stAM.db[info[#info]] = { r, g, b, a} stAM:Update() end,
						disabled = function() return stAM.db['ClassColor'] end,
					},
					ClassColor = {
						order = 8,
						type = 'toggle',
						name = PA.ACL['Class Color Check Texture'],
					},
				},
			},
			FontSettings = {
				order = 2,
				type = 'group',
				name = PA.ACL['Font Settings'],
				guiInline = true,
				get = function(info) return stAM.db[info[#info]] end,
				set = function(info, value) stAM.db[info[#info]] = value stAM:Update() end,
				args = {
					Font = {
						type = 'select', dialogControl = 'LSM30_Font',
						order = 1,
						name = PA.ACL['Font'],
						values = PA.LSM:HashTable('font'),
					},
					FontSize = {
						order = 2,
						name = FONT_SIZE,
						type = 'range',
						min = 6, max = 22, step = 1,
					},
					FontFlag = {
						order = 3,
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
				},
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

	PA.Options.args.stAM = Options
end

function stAM:BuildProfile()
	PA.Defaults.profile['stAddonManager'] = {
		['Enable'] = true,
		['NumAddOns'] = 30,
		['FrameWidth'] = 550,
		['Font'] = 'PT Sans Narrow Bold',
		['FontSize'] = 16,
		['FontFlag'] = 'OUTLINE',
		['ButtonHeight'] = 18,
		['ButtonWidth'] = 22,
		['CheckColor'] = { 0, .66, 1},
		['ClassColor'] = false,
		['CheckTexture'] = 'Solid',
		['EnableRequiredAddons'] = true,
		['EnableOptionalAddons'] = false,
	}

	PA.Options.args.general.args.stAddonManager = {
		type = 'toggle',
		name = stAM.Title,
		desc = stAM.Description,
	}
end

function stAM:Initialize()
	stAM.db = PA.db['stAddonManager']

	if stAM.db.Enable ~= true then
		return
	end

	stAM:GetOptions()

	stAM.AddOnInfo = {}
	stAM.Profiles = {}

	for i = 1, GetNumAddOns() do
		local Name, Title, Notes = GetAddOnInfo(i)
		local Required, Optional = nil, nil
		local MissingAddons, DisabledAddons

		if GetAddOnDependencies(i) ~= nil then
			Required = { GetAddOnDependencies(i) }
			for _, addon in pairs(Required) do
				if select(5, GetAddOnInfo(addon)) == 'MISSING' then
					MissingAddons = MissingAddons or {}
					tinsert(MissingAddons, addon)
				elseif select(5, GetAddOnInfo(addon)) == 'DISABLED' then
					DisabledAddons = DisabledAddons or {}
					tinsert(DisabledAddons, addon)
				end
			end
		end

		if GetAddOnOptionalDependencies(i) then
			Optional = { GetAddOnOptionalDependencies(i) }
		end

		local Authors = GetAddOnMetadata(i, "Author")

		stAM.AddOnInfo[i] = { ['Name'] = Name, ['Title'] = Title, ['Authors'] = Authors, ['Notes'] = Notes, ['Required'] = Required, ['Optional'] = Optional, ['Missing'] = MissingAddons, ['Disabled'] = DisabledAddons }
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