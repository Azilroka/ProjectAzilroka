local PA = _G.ProjectAzilroka
local stAM = PA:NewModule('stAddonManager', 'AceEvent-3.0')
PA.stAM, _G.stAddonManager = stAM, stAM

_G.stAddonManagerProfilesDB = {}
_G.stAddonManagerServerDB = {}

stAM.Title = PA.ACL['|cFF16C3F2st|r|cFFFFFFFFAddonManager|r']
stAM.Description = PA.ACL['A simple and minimalistic addon to disable/enabled addons without logging out.']
stAM.Authors = 'Azilroka    Safturento'
stAM.isEnabled = false

local _G = _G
local unpack = unpack
local tinsert = tinsert
local wipe = wipe
local pairs = pairs
local sort = sort
local format = format
local strlen = strlen
local strlower = strlower
local strfind = strfind
local min = min
local max = max
local concat = table.concat
local select = select
local gsub = gsub

local GetNumAddOns = GetNumAddOns
local GetAddOnInfo = GetAddOnInfo
local GetAddOnDependencies = GetAddOnDependencies
local GetAddOnOptionalDependencies = GetAddOnOptionalDependencies
local DisableAddOn = DisableAddOn
local EnableAddOn = EnableAddOn
local GetAddOnMetadata = GetAddOnMetadata
local DisableAllAddOns = DisableAllAddOns
local EnableAllAddOns = EnableAllAddOns

local CreateFrame = CreateFrame
local UIParent = UIParent
local GameTooltip = GameTooltip

local IsShiftKeyDown = IsShiftKeyDown

_G.StaticPopupDialogs.STADDONMANAGER_OVERWRITEPROFILE = {
	button1 = PA.ACL['Overwrite'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

_G.StaticPopupDialogs.STADDONMANAGER_NEWPROFILE = {
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

_G.StaticPopupDialogs.STADDONMANAGER_RENAMEPROFILE = {
	text = PA.ACL['Enter a name for your AddOn Profile:'],
	button1 = PA.ACL['Update'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	hasEditBox = 1,
	whileDead = 1,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

_G.StaticPopupDialogs.STADDONMANAGER_DELETECONFIRMATION = {
	button1 = PA.ACL['Delete'],
	button2 = PA.ACL['Cancel'],
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

local function strtrim(str)
	return gsub(str, '^%s*(.-)%s*$', '%1')
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
	local font, fontSize, fontFlag = PA.LSM:Fetch('font', stAM.db.Font), stAM.db.FontSize, stAM.db.FontFlag
	local Texture = PA.LSM:Fetch('statusbar', stAM.db.CheckTexture)
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
	Reload.Text:SetText(PA.ACL['Reload'])
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
		GameTooltip:AddLine(PA.ACL['Enable Required AddOns'], 1, 1, 1)
		GameTooltip:AddLine(PA.ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'], 1, 1, 1)
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
	RequiredAddons.Text:SetText(PA.ACL['Required'])

	RequiredAddons:SetChecked(stAM.db.EnableRequiredAddons)

	CharacterSelect:SetPoint('TOPRIGHT', AddOns, 'BOTTOMRIGHT', 0, -10)
	CharacterSelect.DropDown = CreateFrame('Frame', 'stAMCharacterSelectDropDown', CharacterSelect, 'UIDropDownMenuTemplate')
	CharacterSelect:SetSize(150, 20)
	PA:SetTemplate(CharacterSelect)
	CharacterSelect:SetScript('OnEnter', function() CharacterSelect:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
	CharacterSelect:SetScript('OnLeave', function() PA:SetTemplate(CharacterSelect) end)
	CharacterSelect:SetScript('OnClick', function() _G.EasyMenu(stAM.Menu, CharacterSelect.DropDown, CharacterSelect, 0, 38 + (stAM.MenuOffset * 16), 'MENU', 5) end)
	CharacterSelect.Text = CharacterSelect:CreateFontString(nil, 'OVERLAY')
	CharacterSelect.Text:SetFont(font, 12, fontFlag)
	CharacterSelect.Text:SetText(PA.ACL['Character Select'])
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
	Profiles.Text:SetText(PA.ACL['Profiles'])
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
	Slider:SetThumbTexture(PA.LSM:Fetch('background', 'Solid'))
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

	for i = 1, 30 do
		local CheckButton = CreateFrame('CheckButton', 'stAMCheckButton_'..i, AddOns)
		CheckButton:Hide()
		PA:SetTemplate(CheckButton)
		CheckButton:SetSize(Width, Height)
		CheckButton:SetPoint(unpack(i == 1 and {'TOPLEFT', AddOns, 'TOPLEFT', 10, -10} or {'TOP', AddOns.Buttons[i-1], 'BOTTOM', 0, -5}))
		CheckButton:SetScript('OnClick', function()
			if CheckButton.name then
				if PA:IsAddOnEnabled(CheckButton.name, stAM.SelectedCharacter) then
					DisableAddOn(CheckButton.name, stAM.SelectedCharacter)
				else
					EnableAddOn(CheckButton.name, stAM.SelectedCharacter)
					if stAM.db.EnableRequiredAddons and CheckButton.required then
						for _, AddOn in pairs(CheckButton.required) do
							EnableAddOn(AddOn)
						end
					end
				end
				stAM:UpdateAddonList()
			end
		end)
		CheckButton:SetScript('OnEnter', function()
			GameTooltip:SetOwner(CheckButton, 'ANCHOR_TOPRIGHT', 0, 4)
			GameTooltip:ClearLines()
			GameTooltip:AddDoubleLine('AddOn:', CheckButton.title, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine(PA.ACL['Authors:'], CheckButton.authors, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine(PA.ACL['Version:'], CheckButton.version, 1, 1, 1, 1, 1, 1)
			if CheckButton.notes ~= nil then
				GameTooltip:AddDoubleLine('Notes:', CheckButton.notes, 1, 1, 1, 1, 1, 1)
			end
			if CheckButton.required or CheckButton.optional then
				GameTooltip:AddLine(' ')
			end
			if CheckButton.required then
				GameTooltip:AddDoubleLine('Required Dependencies:', concat(CheckButton.required, ', '), 1, 1, 1, 1, 1, 1)
			end
			if CheckButton.optional then
				GameTooltip:AddDoubleLine('Optional Dependencies:', concat(CheckButton.optional, ', '), 1, 1, 1, 1, 1, 1)
			end
			GameTooltip:Show()
			CheckButton:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor))
		end)
		CheckButton:SetScript('OnLeave', function() PA:SetTemplate(CheckButton) GameTooltip:Hide() end)

		local Checked = CheckButton:CreateTexture(nil, 'OVERLAY', nil, 1)
		Checked:SetTexture(Texture)
		Checked:SetVertexColor(unpack(Color))
		PA:SetInside(Checked, CheckButton)

		CheckButton.CheckTexture = Checked
		CheckButton:SetCheckedTexture(Checked)

		CheckButton:SetHighlightTexture('')

		local Text = CheckButton:CreateFontString(nil, 'OVERLAY')
		Text:SetFont(font, fontSize, fontFlag)
		Text:SetText('')
		Text:SetJustifyH('CENTER')
		Text:ClearAllPoints()
		Text:SetPoint('LEFT', CheckButton, 'RIGHT', 10, 0)
		Text:SetPoint('TOP', CheckButton, 'TOP')
		Text:SetPoint('BOTTOM', CheckButton, 'BOTTOM')
		Text:SetPoint('RIGHT', AddOns, 'CENTER', 0, 0)
		Text:SetJustifyH('LEFT')

		CheckButton.Text = Text

		local StatusText = CheckButton:CreateFontString(nil, 'OVERLAY')
		StatusText:SetFont(font, fontSize, fontFlag)
		StatusText:SetText('')
		StatusText:SetJustifyH('CENTER')
		StatusText:ClearAllPoints()
		StatusText:SetPoint('LEFT', Text, 'RIGHT', 0, 0)
		StatusText:SetPoint('TOP', CheckButton, 'TOP')
		StatusText:SetPoint('BOTTOM', CheckButton, 'BOTTOM')
		StatusText:SetPoint('RIGHT', AddOns, 'RIGHT', -10, 0)
		StatusText:SetJustifyH('LEFT')

		CheckButton.StatusText = StatusText

		local Icon = CheckButton:CreateTexture(nil, 'OVERLAY')
		Icon:SetTexture('Interface/AddOns/ProjectAzilroka/Media/Textures/QuestBang')
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

	Frame.AddOns:SetHeight(stAM.db.NumAddOns * (stAM.db.ButtonHeight + 5) + 15)
	Frame:SetSize(stAM.db.FrameWidth, Frame.Title:GetHeight() + Frame.Search:GetHeight() + Frame.AddOns:GetHeight() + Frame.Profiles:GetHeight() + 40)

	stAM.Frame = Frame

	tinsert(_G.UISpecialFrames, stAM.Frame:GetName())

	_G.GameMenuButtonAddons:SetScript('OnClick', function() stAM.Frame:Show() _G.HideUIPanel(_G.GameMenuFrame) end)
end

function stAM:NewAddOnProfile(name, overwrite)
	if _G.stAddonManagerProfilesDB[name] and (not overwrite) then
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].text = format(PA.ACL['There is already a profile named %s. Do you want to overwrite it?'], name)
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].OnAccept = function() stAM:NewAddOnProfile(name, true) end
		_G.StaticPopup_Show('STADDONMANAGER_OVERWRITEPROFILE')
		return
	end

	_G.stAddonManagerProfilesDB[name] = {}

	for i = 1, #stAM.AddOnInfo do
		local AddOn, isEnabled = stAM.AddOnInfo[i].Name, PA:IsAddOnEnabled(i, stAM.SelectedCharacter)
		if isEnabled then
			tinsert(_G.stAddonManagerProfilesDB[name], AddOn)
		end
	end

	stAM:UpdateProfiles()
end

function stAM:InitProfiles()
	local ProfileMenu = CreateFrame('Frame', 'stAMProfileMenu', stAM.Frame)
	ProfileMenu:SetPoint('TOPLEFT', stAM.Frame, 'TOPRIGHT', 3, 0)
	ProfileMenu:SetSize(250, 50)
	PA:SetTemplate(ProfileMenu)
	ProfileMenu:Hide()

	for _, name in pairs({'EnableAll', 'DisableAll', 'NewButton'}) do
		local Button = CreateFrame('Button', nil, ProfileMenu)
		PA:SetTemplate(Button)
		Button:SetSize(stAM.db.ButtonWidth, stAM.db.ButtonHeight)
		Button:SetScript('OnEnter', function() Button:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
		Button:SetScript('OnLeave', function() PA:SetTemplate(Button) end)

		Button.Text = Button:CreateFontString(nil, 'OVERLAY')
		Button.Text:SetFont(PA.LSM:Fetch('font', stAM.db.Font), 12, 'OUTLINE')
		Button.Text:SetPoint('CENTER', 0, 0)
		Button.Text:SetJustifyH('CENTER')

		ProfileMenu[name] = Button
	end

	ProfileMenu.EnableAll.Text:SetText(PA.ACL['Enable All'])
	ProfileMenu.EnableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOPLEFT', 10, -10)
	ProfileMenu.EnableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOP', -3, -10)
	ProfileMenu.EnableAll:SetScript('OnClick', function() EnableAllAddOns(stAM.SelectedCharacter) stAM:UpdateAddonList() end)

	ProfileMenu.DisableAll.Text:SetText(PA.ACL['Disable All'])
	ProfileMenu.DisableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOPRIGHT', -10, -10)
	ProfileMenu.DisableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOP', 2, -10)
	ProfileMenu.DisableAll:SetScript('OnClick', function() DisableAllAddOns(stAM.SelectedCharacter) stAM:UpdateAddonList() end)

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
			Button:SetScript('OnEnter', function() Button:SetBackdropBorderColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor)) end)
			Button:SetScript('OnLeave', function() PA:SetTemplate(Button) end)

			Button.Text = Button:CreateFontString(nil, 'OVERLAY')
			Button.Text:SetFont(PA.LSM:Fetch('font', stAM.db.Font), 12, 'OUTLINE')
			Button.Text:SetPoint('CENTER', 0, 0)
			Button.Text:SetJustifyH('CENTER')

			Pullout[Frame] = Button
		end

		Pullout.Load:SetPoint('LEFT', Pullout, 0, 0)
		Pullout.Load.Text:SetText('Load')
		Pullout.Load:SetScript('OnClick', function(_, btn)
			if btn == 'RightButton' then
				local Dialog = _G.StaticPopupDialogs.STADDONMANAGER_RENAMEPROFILE
				Dialog.OnAccept = function()
					_G.stAddonManagerProfilesDB[Pullout.Name] = nil
					stAM:NewAddOnProfile(Dialog.editBox:GetText())
					stAM:UpdateProfiles()
				end
				Dialog.EditBoxOnEnterPressed = function()
					_G.stAddonManagerProfilesDB[Pullout.Name] = nil
					stAM:NewAddOnProfile(Dialog:GetText())
					stAM:UpdateProfiles()
					Dialog:GetParent():Hide()
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
		Pullout.Update:SetScript('OnClick', function() stAM:NewAddOnProfile(Pullout.Name, true) end)

		Pullout.Delete:SetPoint('LEFT', Pullout.Update, 'RIGHT', 5, 0)
		Pullout.Delete.Text:SetText(PA.ACL['Delete'])
		Pullout.Delete:SetScript('OnClick', function()
			local dialog = _G.StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION']

			dialog.text = format(PA.ACL['Are you sure you want to delete %s?'], Pullout.Name)
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
	for name, _ in pairs(_G.stAddonManagerProfilesDB) do tinsert(stAM.Profiles, name) end
	sort(stAM.Profiles)

	local PreviousButton
	for i, Button in ipairs(ProfileMenu.Buttons) do
		local isShown = i <= #stAM.Profiles
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

	ProfileMenu:SetHeight((#stAM.Profiles + 2) * (stAM.db.ButtonHeight + 5) + 15)
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

			if strfind(strlower(name), query) or strfind(strlower(title), query) or (authors and strfind(strlower(authors), query)) then
				tinsert(stAM.Frame.Search.AddOns, i)
			end
		end
	end

	for i, button in ipairs(stAM.Frame.AddOns.Buttons) do
		local addonIndex = (not stAM.searchQuery and (stAM.scrollOffset + i)) or stAM.Frame.Search.AddOns[stAM.scrollOffset + i]
		local info = stAM.AddOnInfo[addonIndex]

		if addonIndex and addonIndex <= #stAM.AddOnInfo then
			button.name, button.title, button.authors, button.version, button.notes, button.required, button.optional = info.Name, info.Title, info.Authors, info.Version, info.Notes, info.Required, info.Optional
			button.Text:SetText(button.title)
			button.Icon:SetShown(info.Missing or info.Disabled)
			button.StatusText:SetShown(info.Missing or info.Disabled)

			if info.Missing or info.Disabled then
				if info.Missing then
					button.Icon:SetVertexColor(.77, .12, .24)
					button.StatusText:SetVertexColor(.77, .12, .24)
					button.StatusText:SetText(PA.ACL['Missing: ']..concat(info.Missing, ', '))
				else
					button.Icon:SetVertexColor(1, .8, .1)
					button.StatusText:SetVertexColor(1, .8, .1)
					button.StatusText:SetText(PA.ACL['Disabled: ']..concat(info.Disabled, ', '))
				end

				button.Text:SetPoint('LEFT', button.Icon, 'CENTER', 5, 0)
				button.Text:SetPoint('RIGHT', stAM.Frame.AddOns, 'CENTER', 0, 0)
			else
				button.Text:SetPoint('LEFT', button, 'RIGHT', 5, 0)
				button.Text:SetPoint('RIGHT', stAM.Frame.AddOns, 'RIGHT', -10, 0)
			end

			button:SetChecked(PA:IsAddOnPartiallyEnabled(addonIndex, stAM.SelectedCharacter) or PA:IsAddOnEnabled(addonIndex, stAM.SelectedCharacter))
			button.CheckTexture:SetVertexColor(unpack(PA:IsAddOnPartiallyEnabled(addonIndex, stAM.SelectedCharacter) and {.6, .6, .6} or stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor))
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

	local font, fontSize, fontFlag = PA.LSM:Fetch('font', stAM.db.Font), stAM.db.FontSize, stAM.db.FontFlag

	for _, CheckButton in ipairs(stAM.Frame.AddOns.Buttons) do
		CheckButton:SetSize(stAM.db.ButtonWidth, stAM.db.ButtonHeight)
		CheckButton.Text:SetFont(font, fontSize, fontFlag)
		CheckButton.StatusText:SetFont(font, fontSize, fontFlag)
		CheckButton.CheckTexture:SetTexture(PA.LSM:Fetch('statusbar', stAM.db.CheckTexture))
		CheckButton.CheckTexture:SetVertexColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor))
		CheckButton:SetCheckedTexture(CheckButton.CheckTexture)
	end

	stAM.Frame.AddOns.ScrollBar:GetThumbTexture():SetVertexColor(unpack(stAM.db.ClassColor and PA.ClassColor or stAM.db.CheckColor))
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
	local stAddonManager = PA.ACH:Group(stAM.Title, stAM.Description, nil, nil, function(info) return stAM.db[info[#info]] end, function(info, value) stAM.db[info[#info]] = value stAM:Update() end)
	PA.Options.args.stAddonManager = stAddonManager

	stAddonManager.args.Description = PA.ACH:Description(stAM.Description, 0)
	stAddonManager.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) stAM.db[info[#info]] = value if not stAM.isEnabled then stAM:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	stAddonManager.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	stAddonManager.args.General.inline = true

	stAddonManager.args.General.args.NumAddOns = PA.ACH:Range(PA.ACL['# Shown AddOns'], nil, 1, { min = 3, max = 30, step = 1 })
	stAddonManager.args.General.args.FrameWidth = PA.ACH:Range(PA.ACL['Frame Width'], nil, 2, { min = 250, max = 2048, step = 2 })
	stAddonManager.args.General.args.ButtonHeight = PA.ACH:Range(PA.ACL['Button Height'], nil, 3, { min = 3, max = 30, step = 1 })
	stAddonManager.args.General.args.ButtonWidth = PA.ACH:Range(PA.ACL['Button Width'], nil, 4, { min = 3, max = 30, step = 1 })
	stAddonManager.args.General.args.EnableRequiredAddons = PA.ACH:Toggle(PA.ACL['Enable Required AddOns'], PA.ACL['This will attempt to enable all the "Required" AddOns for the selected AddOn.'], 5)
	stAddonManager.args.General.args.CheckTexture = PA.ACH:SharedMediaStatusbar(PA.ACL['Texture'], nil, 6)
	stAddonManager.args.General.args.CheckColor = PA.ACH:Color(COLOR_PICKER, nil, 2, true, nil, function(info) return unpack(stAM.db[info[#info]]) end, function(info, r, g, b, a) stAM.db[info[#info]] = { r, g, b, a} stAM:Update() end, function() return stAM.db.ClassColor end)
	stAddonManager.args.General.args.ClassColor = PA.ACH:Toggle(PA.ACL['Class Color Check Texture'], nil, 8)

	stAddonManager.args.General.args.FontSettings = PA.ACH:Group(PA.ACL['Font Settings'], nil, -1)
	stAddonManager.args.General.args.FontSettings.inline = true
	stAddonManager.args.General.args.FontSettings.args.Font = PA.ACH:SharedMediaFont(PA.ACL['Font'], nil, 1)
	stAddonManager.args.General.args.FontSettings.args.FontSize = PA.ACH:Range(FONT_SIZE, nil, 2, { min = 6, max = 22, step = 1 })
	stAddonManager.args.General.args.FontSettings.args.FontFlag = PA.ACH:FontFlags(PA.ACL['Font Outline'], nil, 3)

	stAddonManager.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	stAddonManager.args.Authors = PA.ACH:Description(stAM.Authors, -1, 'large')
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
	stAM:UpdateSettings()

	if stAM.db.Enable ~= true then
		return
	end

	stAM.isEnabled = true

	stAM.AddOnInfo = {}
	stAM.Profiles = {}

	for i = 1, GetNumAddOns() do
		local Name, Title, Notes = GetAddOnInfo(i)
		local Required, Optional = nil, nil
		local MissingAddons, DisabledAddons

		local HasRequired, HasOptional = GetAddOnDependencies(i), GetAddOnOptionalDependencies(i)

		if HasRequired then
			Required = { HasRequired }
			for _, addon in pairs(Required) do
				local Reason = select(5, GetAddOnInfo(addon))
				if Reason == 'MISSING' then
					MissingAddons = MissingAddons or {}
					tinsert(MissingAddons, addon)
				elseif Reason == 'DISABLED' then
					DisabledAddons = DisabledAddons or {}
					tinsert(DisabledAddons, addon)
				end
			end
		end

		if HasOptional then
			Optional = { HasOptional }
		end

		local Authors = GetAddOnMetadata(i, 'Author')
		local Version = GetAddOnMetadata(i, 'Version')

		stAM.AddOnInfo[i] = { Name = Name, Title = Title, Authors = Authors, Version = Version, Notes = Notes, Required = Required, Optional = Optional, Missing = MissingAddons, Disabled = DisabledAddons }
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
	stAM:Update()
end
