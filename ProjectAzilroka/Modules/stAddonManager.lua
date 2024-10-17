local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local stAM = PA:NewModule('stAddonManager', 'AceEvent-3.0')
PA.stAM, _G.stAddonManager = stAM, stAM

stAddonManagerProfilesDB, stAddonManagerServerDB = {}, {}

stAM.Title, stAM.Description, stAM.Authors, stAM.isEnabled = 'stAddonManager', ACL['A simple and minimalistic addon to disable/enabled addons without logging out.'], 'Azilroka    Safturento', false

local _G = _G
local min, max = min, max
local next, ipairs, sort, unpack, wipe, tinsert, concat = next, ipairs, sort, unpack, wipe, tinsert, table.concat
local format, gsub, strlen, strlower, strfind = format, gsub, strlen, strlower, strfind

local GetNumAddOns = C_AddOns.GetNumAddOns
local GetAddOnInfo = C_AddOns.GetAddOnInfo
local GetAddOnDependencies = C_AddOns.GetAddOnDependencies
local GetAddOnOptionalDependencies = C_AddOns.GetAddOnOptionalDependencies
local DisableAddOn = C_AddOns.DisableAddOn
local EnableAddOn = C_AddOns.EnableAddOn
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local DisableAllAddOns = C_AddOns.DisableAllAddOns
local EnableAllAddOns = C_AddOns.EnableAllAddOns
local SaveAddOns = C_AddOns.SaveAddOns

local UIParent, CreateFrame, GameTooltip = UIParent, CreateFrame, GameTooltip

local IsShiftKeyDown = IsShiftKeyDown

local MAX_BUTTONS = 50

_G.StaticPopupDialogs.STADDONMANAGER_OVERWRITEPROFILE = {
	button1 = ACL['Overwrite'],
	button2 = ACL['Cancel'],
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

_G.StaticPopupDialogs.STADDONMANAGER_NEWPROFILE = {
	text = ACL['Enter a name for your new Addon Profile:'],
	button1 = ACL['Create'],
	button2 = ACL['Cancel'],
	timeout = 0,
	hasEditBox = 1,
	whileDead = 1,
	OnAccept = function(self) stAM:NewAddOnProfile(self.editBox:GetText()) end,
	EditBoxOnEnterPressed = function(self) stAM:NewAddOnProfile(self:GetText()) self:GetParent():Hide() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

_G.StaticPopupDialogs.STADDONMANAGER_RENAMEPROFILE = {
	text = ACL['Enter a name for your AddOn Profile:'],
	button1 = ACL['Update'],
	button2 = ACL['Cancel'],
	timeout = 0,
	hasEditBox = 1,
	whileDead = 1,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

_G.StaticPopupDialogs.STADDONMANAGER_DELETECONFIRMATION = {
	button1 = ACL['Delete'],
	button2 = ACL['Cancel'],
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

stAMCheckButtonMixin = {}

function stAMCheckButtonMixin:OnLoad()
	PA:SetTemplate(self)
end

function stAMCheckButtonMixin:OnClick()
	if self.addonInfo.Name then
		if PA:IsAddOnEnabled(self.addonInfo.Name, stAM.SelectedCharacter) then
			DisableAddOn(self.addonInfo.Name, stAM.SelectedCharacter)
		else
			EnableAddOn(self.addonInfo.Name, stAM.SelectedCharacter)
			if stAM.db.EnableRequiredAddons and self.addonInfo.Required then
				for _, AddOn in next, self.addonInfo.Required do
					EnableAddOn(AddOn)
				end
			end
		end
		stAM:UpdateAddonList()
		SaveAddOns()
	end
end

function stAMCheckButtonMixin:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 0, 4)
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine('AddOn:', self.addonInfo.Title, 1, 1, 1, 1, 1, 1)
	if self.addonInfo.Version then
		GameTooltip:AddDoubleLine(ACL['Version:'], self.addonInfo.Version, 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine(ACL['Authors:'], self.addonInfo.Authors, 1, 1, 1, 1, 1, 1)
	if self.addonInfo.Notes ~= nil then
		GameTooltip:AddDoubleLine('Notes:', self.addonInfo.Notes, 1, 1, 1, 1, 1, 1)
	end
	if self.addonInfo.Required or self.addonInfo.Optional then
		GameTooltip:AddLine(' ')
		if self.addonInfo.Required then
			GameTooltip:AddDoubleLine('Required Dependencies:', concat(self.addonInfo.Required, ', '), 1, 1, 1, 1, 1, 1)
		end
		if self.addonInfo.Optional then
			GameTooltip:AddDoubleLine('Optional Dependencies:', concat(self.addonInfo.Optional, ', '), 1, 1, 1, 1, 1, 1)
		end
	end
	GameTooltip:Show()

	self:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor))
end

function stAMCheckButtonMixin:OnLeave()
	PA:SetTemplate(self)
	GameTooltip:Hide()
end

local function strtrim(str)
	return gsub(str, '^%s*(.-)%s*$', '%1')
end

function stAM:OpenPanel()
	_G.PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	_G.HideUIPanel(_G.GameMenuFrame)
	_G.ShowUIPanel(stAM.Frame)
end

function stAM:BuildFrame()
	local Frame = CreateFrame('Frame', 'stAMFrame', UIParent)
	local Close = CreateFrame('Button', 'stAMCloseButton', Frame)
	local Search = CreateFrame('EditBox', 'stAMSearchBox', Frame, 'SearchBoxTemplate')

	local Profiles = CreateFrame('Button', 'stAMProfiles', Frame)
	local AddOns = CreateFrame('Frame', 'stAMAddOns', Frame)
	local Slider = CreateFrame('Slider', nil, AddOns)

	local Reload = CreateFrame('Button', 'stAMReload', Frame)
	local RequiredAddons = CreateFrame('CheckButton', nil, Frame)
	local OptionalAddons = CreateFrame('CheckButton', nil, Frame)
	local CharacterSelect = CreateFrame('Button', nil, Frame)

	local Title = Frame:CreateFontString(nil, 'OVERLAY')

	-- Defines
	local font, fontSize, fontFlag = PA:GetFont(stAM.db.Font, stAM.db.FontSize, stAM.db.FontFlag)
	local Texture = PA.Libs.LSM:Fetch('statusbar', stAM.db.CheckTexture)
	local FrameWidth = stAM.db.FrameWidth
	local NumAddOns = stAM.db.NumAddOns
	local Color = stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor
	local Width, Height = stAM.db.ButtonWidth, stAM.db.ButtonHeight

	Frame:SetSize(FrameWidth, 10 + NumAddOns * 25 + 40)
	Frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	PA:SetTemplate(Frame)
	Frame:Hide()
	Frame:SetFrameStrata('HIGH')
	Frame:SetClampedToScreen(true)
	Frame:SetMovable(true)
	Frame:EnableMouse(true)
	Frame:SetScript('OnMouseDown', Frame.StartMoving)
	Frame:SetScript('OnMouseUp', Frame.StopMovingOrSizing)

	Title:SetPoint('TOPLEFT', 0, -5)
	Title:SetPoint('TOPRIGHT', 0, -5)
	Title:SetFont(font, 14, fontFlag)
	Title:SetText(stAM.Title)
	Title:SetJustifyH('CENTER')
	Title:SetJustifyV('MIDDLE')

	PA:SetTemplate(Close)
	Close:SetPoint('TOPRIGHT', -3, -3)
	Close:SetSize(16, 16)
	Close:SetScript('OnEnter', function() Close:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
	Close:SetScript('OnLeave', function() PA:SetTemplate(Close) end)
	Close:SetScript('OnClick', function() Frame:Hide() end)

	local Mask = Close:CreateMaskTexture()
	Mask:SetTexture('Interface/AddOns/ProjectAzilroka/Media/Textures/Close', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
	Mask:SetSize(10, 10)
	Mask:SetPoint('CENTER')

	Close.Mask = Mask

	Close:SetNormalTexture(Texture)
	Close:SetPushedTexture(Texture)

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
	Search.Left:SetTexture()
	Search.Middle:SetTexture()
	Search.Right:SetTexture()
	PA:SetTemplate(Search)
	Search.AddOns = {}
	Search:HookScript('OnEscapePressed', function() stAM:UpdateAddonList() end)
	Search:HookScript('OnTextChanged', function(_, userInput) stAM.scrollOffset = 0 stAM.searchQuery = userInput stAM:UpdateAddonList() end)
	Search:HookScript('OnEditFocusGained', function() Search:SetBackdropBorderColor(unpack(stAM.db.CheckColor)) Search:HighlightText() end)
	Search:HookScript('OnEditFocusLost', function() PA:SetTemplate(Search) Search:HighlightText(0, 0) PA:SetTemplate(Search) end)
	Search.clearButton:HookScript('OnClick', stAM.UpdateAddonList)

	PA:SetTemplate(Reload)
	Reload:SetSize(70, 20)
	Reload:SetScript('OnEnter', function() Reload:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
	Reload:SetScript('OnLeave', function() PA:SetTemplate(Reload) end)
	Reload:SetScript('OnClick', _G.ReloadUI)
	Reload.Text = Reload:CreateFontString(nil, 'OVERLAY')
	Reload.Text:SetFont(font, 12, fontFlag)
	Reload.Text:SetText(ACL['Reload'])
	Reload.Text:SetPoint('CENTER', 0, 0)
	Reload.Text:SetJustifyH('CENTER')
	Reload:SetPoint('TOPLEFT', AddOns, 'BOTTOMLEFT', 0, -10)

	RequiredAddons:SetPoint('LEFT', Reload, 'RIGHT', 50, 0)
	PA:SetTemplate(RequiredAddons)
	RequiredAddons:SetSize(20, 20)
	RequiredAddons:SetScript('OnClick', function()
		stAM.db.EnableRequiredAddons = not stAM.db.EnableRequiredAddons
	end)
	RequiredAddons:SetScript('OnEnter', function()
		GameTooltip:SetOwner(RequiredAddons, 'ANCHOR_TOPRIGHT', 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(ACL['Enable Required AddOns'], 1, 1, 1)
		GameTooltip:AddLine(ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'], 1, 1, 1)
		GameTooltip:Show()
	end)
	RequiredAddons:SetScript('OnLeave', function() PA:SetTemplate(RequiredAddons) GameTooltip:Hide() end)

	RequiredAddons.CheckTexture = RequiredAddons:CreateTexture(nil, 'OVERLAY', nil, 1)
	RequiredAddons.CheckTexture:SetTexture(Texture)
	RequiredAddons.CheckTexture:SetVertexColor(unpack(Color))
	PA:SetInside(RequiredAddons.CheckTexture, RequiredAddons)

	RequiredAddons:SetCheckedTexture(RequiredAddons.CheckTexture)
	RequiredAddons:SetHighlightTexture('')

	RequiredAddons.Text = RequiredAddons:CreateFontString(nil, 'OVERLAY')
	RequiredAddons.Text:SetPoint('LEFT', RequiredAddons, 'RIGHT', 5, 0)
	RequiredAddons.Text:SetFont(font, 12, fontFlag)
	RequiredAddons.Text:SetText(ACL['Required'])

	RequiredAddons:SetChecked(stAM.db.EnableRequiredAddons)

	CharacterSelect:SetPoint('TOPRIGHT', AddOns, 'BOTTOMRIGHT', 0, -10)
	CharacterSelect.DropDown = CreateFrame('Frame', 'stAMCharacterSelectDropDown', CharacterSelect, 'UIDropDownMenuTemplate')
	CharacterSelect:SetSize(150, 20)
	PA:SetTemplate(CharacterSelect)

	CharacterSelect:SetScript('OnEnter', function() CharacterSelect:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
	CharacterSelect:SetScript('OnLeave', function() PA:SetTemplate(CharacterSelect) end)
	CharacterSelect:SetScript('OnClick', function() PA:EasyMenu(stAM.Menu, CharacterSelect.DropDown, CharacterSelect, 0, 38 + (stAM.MenuOffset * 16), 'MENU', 5) end)
	CharacterSelect.Text = CharacterSelect:CreateFontString(nil, 'OVERLAY')
	CharacterSelect.Text:SetFont(font, 12, fontFlag)
	CharacterSelect.Text:SetText(ACL['Character Select'])
	CharacterSelect.Text:SetPoint('CENTER', 0, 0)
	CharacterSelect.Text:SetJustifyH('CENTER')

	Profiles:SetPoint('TOPRIGHT', Title, 'BOTTOMRIGHT', -10, -10)
	PA:SetTemplate(Profiles)
	Profiles:SetSize(70, 20)
	Profiles:SetScript('OnEnter', function() Profiles:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
	Profiles:SetScript('OnLeave', function() PA:SetTemplate(Profiles) end)
	Profiles:SetScript('OnClick', function() stAM:ToggleProfiles() end)

	Profiles.Text = Profiles:CreateFontString(nil, 'OVERLAY')
	Profiles.Text:SetFont(font, 12, fontFlag)
	Profiles.Text:SetText(ACL['Profiles'])
	Profiles.Text:SetPoint('CENTER', 0, 0)
	Profiles.Text:SetJustifyH('CENTER')

	AddOns:SetPoint('TOPLEFT', Search, 'BOTTOMLEFT', 0, -5)
	AddOns:SetPoint('TOPRIGHT', Profiles, 'BOTTOMRIGHT', 0, -5)
	AddOns:SetHeight(NumAddOns * (Height + 5) + 15)
	PA:SetTemplate(AddOns)
	AddOns.Buttons = {}
	AddOns:EnableMouse(true)
	AddOns:EnableMouseWheel(true)

	Slider:SetPoint('RIGHT', -2, 0)
	Slider:SetWidth(12)
	Slider:SetHeight(NumAddOns * (Height + 5) + 11)
	Slider:SetThumbTexture(PA.Libs.LSM:Fetch('background', 'Solid'))
	Slider:SetOrientation('VERTICAL')
	Slider:SetValueStep(1)
	PA:SetTemplate(Slider)
	Slider:SetMinMaxValues(0, 1)
	Slider:SetValue(0)
	Slider:EnableMouse(true)
	Slider:EnableMouseWheel(true)

	local Thumb = Slider:GetThumbTexture()
	Thumb:SetSize(8, 16)
	Thumb:SetVertexColor(unpack(Color))

	AddOns.ScrollBar = Slider

	local OnScroll = function(_, delta)
		local numAddons = stAM.searchQuery and #Search.AddOns or #stAM.AddOnInfo
		if numAddons < stAM.db.NumAddOns then return end

		if IsShiftKeyDown() then
			if delta == 1 then
				stAM.scrollOffset = max(0, stAM.scrollOffset - stAM.db.NumAddOns)
			elseif delta == -1 then
				stAM.scrollOffset = min(numAddons - stAM.db.NumAddOns, stAM.scrollOffset + stAM.db.NumAddOns)
			end
		else
			if delta == 1 and stAM.scrollOffset > 0 then
				stAM.scrollOffset = stAM.scrollOffset - 1
			elseif delta == -1 then
				if stAM.scrollOffset < numAddons - stAM.db.NumAddOns then
					stAM.scrollOffset = stAM.scrollOffset + 1
				end
			end
		end

		Slider:SetMinMaxValues(0, (numAddons - stAM.db.NumAddOns))
		Slider:SetValue(stAM.scrollOffset)
		stAM:UpdateAddonList()
	end

	AddOns:SetScript('OnMouseWheel', OnScroll)
	Slider:SetScript('OnMouseWheel', OnScroll)
	Slider:SetScript('OnValueChanged', function(_, value)
		stAM.scrollOffset = value
		OnScroll()
	end)

	for i = 1, MAX_BUTTONS do
		local CheckButton = CreateFrame('CheckButton', 'stAMCheckButton_'..i, AddOns, 'stAMCheckButton')
		CheckButton:SetSize(Width, Height)
		CheckButton:SetPoint(unpack(i == 1 and {'TOPLEFT', AddOns, 'TOPLEFT', 10, -10} or {'TOP', AddOns.Buttons[i-1], 'BOTTOM', 0, -5}))
		CheckButton:SetCheckedTexture(Texture)
		local Checked = CheckButton:GetCheckedTexture()
		Checked:SetVertexColor(unpack(Color))
		PA:SetInside(Checked, CheckButton)

		CheckButton:SetHighlightTexture('')

		CheckButton.Text:SetFont(font, fontSize, fontFlag)
		CheckButton.StatusText:SetFont(font, fontSize, fontFlag)

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

	Frame.AddOns:SetHeight(stAM.db.NumAddOns * (stAM.db.ButtonHeight + 5) + 15)
	Frame:SetSize(stAM.db.FrameWidth, Frame.Title:GetHeight() + Frame.Search:GetHeight() + Frame.AddOns:GetHeight() + Frame.Profiles:GetHeight() + 40)

	stAM.Frame = Frame

	tinsert(_G.UISpecialFrames, stAM.Frame:GetName())

	if _G.GameMenuButtonAddons then
		_G.GameMenuButtonAddons:SetScript('OnClick', stAM.OpenPanel)
	else
		-- Game menu buttons are no longer persistent. Must be hooked every time the game menu is opened.
		hooksecurefunc(GameMenuFrame, 'Layout', function()
			for button in GameMenuFrame.buttonPool:EnumerateActive() do
				local text = button:GetText()

				if (text == _G["ADDONS"]) then
					button:SetScript("OnClick", stAM.OpenPanel)
				end
			end
		end)
	end
end

function stAM:NewAddOnProfile(name, overwrite)
	if _G.stAddonManagerProfilesDB[name] and (not overwrite) then
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].text = format(ACL['There is already a profile named %s. Do you want to overwrite it?'], name)
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].OnAccept = function() stAM:NewAddOnProfile(name, true) end
		_G.StaticPopup_Show('STADDONMANAGER_OVERWRITEPROFILE')
		return
	end

	_G.stAddonManagerProfilesDB[name] = {}

	for i in next, stAM.AddOnInfo do
		local AddOn, isEnabled = stAM.AddOnInfo[i].Name, PA:IsAddOnEnabled(i, stAM.SelectedCharacter)
		if isEnabled then
			tinsert(_G.stAddonManagerProfilesDB[name], AddOn)
		end
	end

	stAM:UpdateProfiles()
end

function stAM:LoadProfile(name)
	if not IsShiftKeyDown() then
		DisableAllAddOns(stAM.SelectedCharacter)
	end

	for _, AddOn in next, _G.stAddonManagerProfilesDB[name] do
		EnableAddOn(AddOn, stAM.SelectedCharacter)
	end

	stAM:UpdateAddonList()
end

function stAM:InitProfiles()
	local ProfileMenu = CreateFrame('Frame', 'stAMProfileMenu', stAM.Frame)
	ProfileMenu:SetPoint('TOPLEFT', stAM.Frame, 'TOPRIGHT', 3, 0)
	ProfileMenu:SetSize(250, 50)
	PA:SetTemplate(ProfileMenu)
	ProfileMenu:Hide()

	for _, name in next, {'EnableAll', 'DisableAll', 'NewButton'} do
		local Button = CreateFrame('Button', nil, ProfileMenu)
		PA:SetTemplate(Button)
		Button:SetSize(stAM.db.ButtonWidth, stAM.db.ButtonHeight)
		Button:SetScript('OnEnter', function() Button:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
		Button:SetScript('OnLeave', function() PA:SetTemplate(Button) end)

		Button.Text = Button:CreateFontString(nil, 'OVERLAY')
		Button.Text:SetFont(PA.Libs.LSM:Fetch('font', stAM.db.Font), 12, 'OUTLINE')
		Button.Text:SetPoint('CENTER', 0, 0)
		Button.Text:SetJustifyH('CENTER')

		ProfileMenu[name] = Button
	end

	ProfileMenu.EnableAll.Text:SetText(ACL['Enable All'])
	ProfileMenu.EnableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOPLEFT', 10, -10)
	ProfileMenu.EnableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOP', -3, -10)
	ProfileMenu.EnableAll:SetScript('OnClick', function() EnableAllAddOns(stAM.SelectedCharacter) stAM:UpdateAddonList() end)

	ProfileMenu.DisableAll.Text:SetText(ACL['Disable All'])
	ProfileMenu.DisableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOPRIGHT', -10, -10)
	ProfileMenu.DisableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOP', 2, -10)
	ProfileMenu.DisableAll:SetScript('OnClick', function() DisableAllAddOns(stAM.SelectedCharacter) stAM:UpdateAddonList() end)

	ProfileMenu.NewButton.Text:SetText(ACL['New Profile'])
	ProfileMenu.NewButton:SetPoint('TOPLEFT', ProfileMenu.EnableAll, 'BOTTOMLEFT', 0, -5)
	ProfileMenu.NewButton:SetPoint('TOPRIGHT', ProfileMenu.DisableAll, 'BOTTOMRIGHT', 0, -5)
	ProfileMenu.NewButton:SetScript('OnClick', function() _G.StaticPopup_Show('STADDONMANAGER_NEWPROFILE') end)

	ProfileMenu.Buttons = {}

	for i = 1, MAX_BUTTONS do
		local Pullout = CreateFrame('Frame', nil, ProfileMenu)
		Pullout:SetWidth(210)
		Pullout:SetHeight(stAM.db.ButtonHeight)
		Pullout:Hide()

		for _, Frame in next, {'Load', 'Delete', 'Update'} do
			local Button = CreateFrame('Button', nil, Pullout)
			PA:SetTemplate(Button)
			Button:SetSize(73, stAM.db.ButtonHeight)
			Button:RegisterForClicks('AnyDown')
			Button:SetScript('OnEnter', function() Button:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
			Button:SetScript('OnLeave', function() PA:SetTemplate(Button) end)

			Button.Text = Button:CreateFontString(nil, 'OVERLAY')
			Button.Text:SetFont(PA.Libs.LSM:Fetch('font', stAM.db.Font), 12, 'OUTLINE')
			Button.Text:SetPoint('CENTER', 0, 0)
			Button.Text:SetJustifyH('CENTER')

			Pullout[Frame] = Button
		end

		Pullout.Load:SetPoint('LEFT', Pullout, 0, 0)
		Pullout.Load.Text:SetText('Load')
		Pullout.Load:SetScript('OnClick', function(_, btn)
			if btn == 'RightButton' then
				local Dialog = _G.StaticPopupDialogs.STADDONMANAGER_RENAMEPROFILE
				Dialog.OnAccept = function(dialog)
					_G.stAddonManagerProfilesDB[Pullout.Name] = nil
					stAM:NewAddOnProfile(dialog.editBox:GetText())
					stAM:UpdateProfiles()
				end
				Dialog.EditBoxOnEnterPressed = function(editBox)
					_G.stAddonManagerProfilesDB[Pullout.Name] = nil
					stAM:NewAddOnProfile(editBox:GetText())
					stAM:UpdateProfiles()
					editBox:GetParent():Hide()
				end
				_G.StaticPopup_Show('STADDONMANAGER_RENAMEPROFILE')
			else
				stAM:LoadProfile(Pullout.Name)
			end
		end)

		Pullout.Update:SetPoint('LEFT', Pullout.Load, 'RIGHT', 5, 0)
		Pullout.Update.Text:SetText(ACL['Update'])
		Pullout.Update:SetScript('OnClick', function() stAM:NewAddOnProfile(Pullout.Name, true) end)

		Pullout.Delete:SetPoint('LEFT', Pullout.Update, 'RIGHT', 5, 0)
		Pullout.Delete.Text:SetText(ACL['Delete'])
		Pullout.Delete:SetScript('OnClick', function()
			local dialog = _G.StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION']

			dialog.text = format(ACL['Are you sure you want to delete %s?'], Pullout.Name)
			dialog.OnAccept = function() _G.stAddonManagerProfilesDB[Pullout.Name] = nil stAM:UpdateProfiles() end

			_G.StaticPopup_Show('STADDONMANAGER_DELETECONFIRMATION')
		end)

		ProfileMenu.Buttons[i] = Pullout
	end

	stAM.ProfileMenu = ProfileMenu
end

function stAM:UpdateProfiles()
	local ProfileMenu = stAM.ProfileMenu

	wipe(stAM.Profiles)
	for name, _ in next, _G.stAddonManagerProfilesDB do tinsert(stAM.Profiles, name) end
	sort(stAM.Profiles)

	local PreviousButton
	for i, Button in ipairs(ProfileMenu.Buttons) do
		local isShown = i <= min(#stAM.Profiles, MAX_BUTTONS)
		if isShown then
			Button.Load.Text:SetText(stAM.Profiles[i])
		end

		Button.Name = isShown and stAM.Profiles[i] or nil
		Button:SetShown(isShown)

		if i == 1 then
			Button:SetPoint('TOPLEFT', ProfileMenu.NewButton, 'BOTTOMLEFT', 0, -5)
		else
			Button:SetPoint('TOP', PreviousButton, 'BOTTOM', 0, -5)
		end

		PreviousButton = Button
	end

	ProfileMenu:SetHeight((min(#stAM.Profiles, MAX_BUTTONS) + 2) * (stAM.db.ButtonHeight + 5) + 15)
end

function stAM:ToggleProfiles()
	_G.ToggleFrame(stAM.ProfileMenu)
	stAM:UpdateProfiles()
end

function stAM:UpdateAddonList()
	wipe(stAM.Frame.Search.AddOns)

	if stAM.searchQuery then
		local query = strlower(strtrim(stAM.Frame.Search:GetText()))

		if (strlen(query) == 0) then
			stAM.searchQuery = false
		end

		for i, AddOn in ipairs(stAM.AddOnInfo) do
			local name, title, authors = AddOn.Name, AddOn.Title, AddOn.Authors

			if strfind(strlower(name), query, nil, true) or strfind(strlower(title), query, nil, true) or (authors and strfind(strlower(authors), query, nil, true)) then
				tinsert(stAM.Frame.Search.AddOns, i)
			end
		end
	end

	for i, button in ipairs(stAM.Frame.AddOns.Buttons) do
		local addonIndex = (not stAM.searchQuery and (stAM.scrollOffset + i)) or stAM.Frame.Search.AddOns[stAM.scrollOffset + i]
		local info = stAM.AddOnInfo[addonIndex]
		button.addonInfo = info

		if addonIndex and addonIndex <= #stAM.AddOnInfo then
			button.Text:SetFormattedText(info.Version and '%s (%s)' or '%s', info.Title, info.Version or '')

			if info.Icon then
				button.Icon:SetTexture(info.Icon)
				button.Icon:SetTexCoord(PA:TexCoords())
			elseif info.Atlas then
				button.Icon:SetAtlas(info.Atlas)
				button.Icon:SetTexCoord(0, 1, 0, 1)
			end

			button.Icon:SetShown(info.Icon or info.Atlas)
			button.StatusIcon:SetShown(info.Missing or info.Disabled)
			button.StatusText:SetShown(info.Missing or info.Disabled)

			if info.Missing or info.Disabled then
				if info.Missing then
					button.StatusIcon:SetVertexColor(.77, .12, .24)
					button.StatusText:SetVertexColor(.77, .12, .24)
					button.StatusText:SetText(ACL['Missing: ']..concat(info.Missing, ', '))
				else
					button.StatusIcon:SetVertexColor(1, .8, .1)
					button.StatusText:SetVertexColor(1, .8, .1)
					button.StatusText:SetText(ACL['Disabled: ']..concat(info.Disabled, ', '))
				end

				button.Icon:SetPoint('LEFT', button.StatusIcon, 'RIGHT', 5, 0)
				button.Text:SetPoint('LEFT', button.Icon, 'RIGHT', 5, 0)
				button.Text:SetPoint('RIGHT', stAM.Frame.AddOns, 'CENTER', 0, 0)
			elseif (info.Icon or info.Atlas) then
				button.Icon:SetPoint('LEFT', button, 'RIGHT', 5, 0)
				button.Text:SetPoint('LEFT', button.Icon, 'RIGHT', 5, 0)
				button.Text:SetPoint('RIGHT', stAM.Frame.AddOns, 'RIGHT', -10, 0)
			else
				button.Text:SetPoint('LEFT', button, 'RIGHT', 5, 0)
				button.Text:SetPoint('RIGHT', stAM.Frame.AddOns, 'RIGHT', -10, 0)
			end

			button:SetChecked(PA:IsAddOnPartiallyEnabled(addonIndex, stAM.SelectedCharacter) or PA:IsAddOnEnabled(addonIndex, stAM.SelectedCharacter))
			button:GetCheckedTexture():SetVertexColor(unpack(PA:IsAddOnPartiallyEnabled(addonIndex, stAM.SelectedCharacter) and {.6, .6, .6} or stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor))
			button:SetShown(i <= min(#stAM.Frame.Search.AddOns > 0 and #stAM.Frame.Search.AddOns or stAM.db.NumAddOns, stAM.db.NumAddOns))
		else
			button:SetShown(false)
		end
	end
end

function stAM:Update()
	if not stAM.Frame then return end

	stAM.Frame:SetSize(stAM.db.FrameWidth, stAM.Frame.Title:GetHeight() + 5 + stAM.Frame.Search:GetHeight() + 5 + stAM.Frame.AddOns:GetHeight() + 10 + stAM.Frame.Profiles:GetHeight() + 20)
	stAM.Frame.AddOns:SetHeight(stAM.db.NumAddOns * (stAM.db.ButtonHeight + 5) + 15)
	stAM.Frame.AddOns.ScrollBar:SetHeight(stAM.db.NumAddOns * (stAM.db.ButtonHeight + 5) + 11)

	local font, fontSize, fontFlag = PA:GetFont(stAM.db.Font, stAM.db.FontSize, stAM.db.FontFlag)
	local checkTexture = PA.Libs.LSM:Fetch('statusbar', stAM.db.CheckTexture)
	local r, g, b, a = unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)
	local iconSize = stAM.db.ButtonHeight

	for _, CheckButton in ipairs(stAM.Frame.AddOns.Buttons) do
		CheckButton:SetSize(stAM.db.ButtonWidth, stAM.db.ButtonHeight)
		CheckButton.Icon:SetSize(iconSize, iconSize)
		CheckButton.Text:SetFont(font, fontSize, fontFlag)
		CheckButton.StatusText:SetFont(font, fontSize, fontFlag)
		CheckButton:SetCheckedTexture(checkTexture)
		CheckButton:GetCheckedTexture():SetVertexColor(r, g, b, a)
	end

	stAM.Frame.AddOns.ScrollBar:GetThumbTexture():SetVertexColor(r, g, b, a)
	stAM.Frame.Title:SetFont(font, 14, fontFlag)
	stAM.Frame.Search:SetFont(font, 12, fontFlag)
	stAM.Frame.Reload.Text:SetFont(font, 12, fontFlag)
	stAM.Frame.Profiles.Text:SetFont(font, 12, fontFlag)
	stAM.Frame.CharacterSelect.Text:SetFont(font, 12, fontFlag)
	stAM.Frame.RequiredAddons.Text:SetFont(font, 12, fontFlag)

	stAM.Frame.RequiredAddons:SetChecked(stAM.db.EnableRequiredAddons)
	stAM.Frame.OptionalAddons:SetChecked(stAM.db.EnableOptionalAddons)

	stAM.ProfileMenu.EnableAll.Text:SetFont(font, 12, fontFlag)
	stAM.ProfileMenu.DisableAll.Text:SetFont(font, 12, fontFlag)
	stAM.ProfileMenu.NewButton.Text:SetFont(font, 12, fontFlag)

	for _, Button in ipairs(stAM.ProfileMenu.Buttons) do
		Button.Load.Text:SetFont(font, 12, fontFlag)
		Button.Update.Text:SetFont(font, 12, fontFlag)
		Button.Delete.Text:SetFont(font, 12, fontFlag)
	end

	stAM:UpdateAddonList()
end

function stAM:GetOptions()
	local stAddonManager = ACH:Group(stAM.Title, stAM.Description, nil, nil, function(info) return stAM.db[info[#info]] end, function(info, value) stAM.db[info[#info]] = value stAM:Update() end)
	PA.Options.args.stAddonManager = stAddonManager

	stAddonManager.args.Description = ACH:Description(stAM.Description, 0)
	stAddonManager.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) stAM.db[info[#info]] = value if not stAM.isEnabled then stAM:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	stAddonManager.args.General = ACH:Group(ACL['General'], nil, 2)
	stAddonManager.args.General.inline = true

	stAddonManager.args.General.args.NumAddOns = ACH:Range(ACL['# Shown AddOns'], nil, 1, { min = 3, max = MAX_BUTTONS, step = 1 })
	stAddonManager.args.General.args.FrameWidth = ACH:Range(ACL['Frame Width'], nil, 2, { min = 250, max = 2048, step = 2 })
	stAddonManager.args.General.args.ButtonHeight = ACH:Range(ACL['Button Height'], nil, 3, { min = 3, max = 30, step = 1 })
	stAddonManager.args.General.args.ButtonWidth = ACH:Range(ACL['Button Width'], nil, 4, { min = 3, max = 30, step = 1 })
	stAddonManager.args.General.args.EnableRequiredAddons = ACH:Toggle(ACL['Enable Required AddOns'], ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'], 5)
	stAddonManager.args.General.args.CheckTexture = ACH:SharedMediaStatusbar(ACL['Texture'], nil, 6)
	stAddonManager.args.General.args.CheckColor = ACH:Color(COLOR_PICKER, nil, 2, true, nil, function(info) return unpack(stAM.db[info[#info]]) end, function(info, r, g, b, a) stAM.db[info[#info]] = { r, g, b, a} stAM:Update() end, function() return stAM.db.ClassColor end)
	stAddonManager.args.General.args.ClassColor = ACH:Toggle(ACL['Class Color Check Texture'], nil, 8)

	stAddonManager.args.General.args.FontSettings = ACH:Group(ACL['Font Settings'], nil, -1)
	stAddonManager.args.General.args.FontSettings.inline = true
	stAddonManager.args.General.args.FontSettings.args.Font = ACH:SharedMediaFont(ACL['Font'], nil, 1)
	stAddonManager.args.General.args.FontSettings.args.FontSize = ACH:Range(FONT_SIZE, nil, 2, { min = 6, max = 22, step = 1 })
	stAddonManager.args.General.args.FontSettings.args.FontFlag = ACH:FontFlags(ACL['Font Outline'], nil, 3)

	stAddonManager.args.AuthorHeader = ACH:Header(ACL['Authors:'], -2)
	stAddonManager.args.Authors = ACH:Description(stAM.Authors, -1, 'large')
end

function stAM:BuildProfile()
	PA.Defaults.profile.stAddonManager = {
		Enable = true,
		NumAddOns = 30,
		FrameWidth = 550,
		Font = 'PT Sans Narrow Bold',
		FontSize = 16,
		FontFlag = 'OUTLINE',
		ButtonHeight = 18,
		ButtonWidth = 22,
		CheckColor = { 0, .66, 1},
		ClassColor = false,
		CheckTexture = 'Solid',
		EnableRequiredAddons = true,
		EnableOptionalAddons = false,
	}
end

function stAM:UpdateSettings()
	stAM.db = PA.db.stAddonManager
end

function stAM:Initialize()
	if stAM.db.Enable ~= true then
		return
	end

	stAM.isEnabled = true

	stAM.Menu = {
		{ order = 0, text = 'All', checked = function() return stAM.SelectedCharacter == true end, func = function() stAM.SelectedCharacter = true stAM:UpdateAddonList() end}
	}

	stAddonManagerServerDB[PA.MyRealm] = stAddonManagerServerDB[PA.MyRealm] or {}
	stAddonManagerServerDB[PA.MyRealm][PA.MyName] = true

	local function menuSort(a, b)
		if a.order and b.order and not (a.order == b.order) then
			return a.order < b.order
		end
		return a.text < b.text
	end

	for Character in next, stAddonManagerServerDB[PA.MyRealm] do
		tinsert(stAM.Menu, { text = Character, checked = function() return stAM.SelectedCharacter == Character end, func = function() stAM.SelectedCharacter = Character stAM:UpdateAddonList() end })
	end
	sort(stAM.Menu, menuSort)

	stAM.AddOnInfo, stAM.Profiles, stAM.SelectedCharacter, stAM.MenuOffset, stAM.scrollOffset = {}, {}, PA.MyName, #stAM.Menu, 0

	local addonCache, _ = {}
	for addonIndex = 1, GetNumAddOns() do
		local Name, Title, Notes = GetAddOnInfo(addonIndex)
		local Required, Optional = { GetAddOnDependencies(addonIndex) }, { GetAddOnOptionalDependencies(addonIndex) }
		local iconTexture = GetAddOnMetadata(addonIndex, "IconTexture")
		local iconAtlas = GetAddOnMetadata(addonIndex, "IconAtlas")
		local MissingAddons, DisabledAddons

		if not next(Required) then
			Required = nil
		else
			for num, addon in next, Required do
				local Reason = addonCache[addon]
				if not Reason then
					_, _, _, _, Reason = GetAddOnInfo(addon)
					addonCache[addon] = Reason
				end
				if Reason == 'MISSING' then
					MissingAddons = MissingAddons or {}
					tinsert(MissingAddons, addon)
				elseif Reason == 'DISABLED' then
					DisabledAddons = DisabledAddons or {}
					tinsert(DisabledAddons, addon)
				end
			end
		end

--		Notes = Notes and Notes:gsub('[|n\n]', '')

		if not next(Optional) then
			Optional = nil
		end

		stAM.AddOnInfo[addonIndex] = { Name = Name, Title = Title, Authors = GetAddOnMetadata(addonIndex, 'Author'), Version = GetAddOnMetadata(addonIndex, 'Version'), Notes = Notes, Required = Required, Optional = Optional, Missing = MissingAddons, Disabled = DisabledAddons, Icon = iconTexture, Atlas = iconAtlas }
	end

	stAM:BuildFrame()
	stAM:InitProfiles()
	stAM:Update()
end
