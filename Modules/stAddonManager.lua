local _G = _G
local PA = _G.ProjectAzilroka

local stAM = PA:NewModule('stAddonManager', 'AceEvent-3.0')
_G.stAddonManager = stAM
_G.stAddonManagerProfilesDB = {}

stAM.Title = '|cff00aaffst|rAddonManager'
stAM.Description = 'A simple and minimalistic addon to disable/enabled addons without logging out.'
stAM.Authors = 'Safturento    Azilroka'

local unpack, tinsert, wipe, pairs, sort = unpack, tinsert, wipe, pairs, sort
local strlen, strlower, strfind = strlen, strlower, strfind
local min, max = min, max

local CreateFrame, UIParent, GameTooltip = CreateFrame, UIParent, GameTooltip

local GetNumAddOns, GetAddOnInfo, GetAddOnDependencies, GetAddOnOptionalDependencies, GetAddOnEnableState = GetNumAddOns, GetAddOnInfo, GetAddOnDependencies, GetAddOnOptionalDependencies, GetAddOnEnableState
local DisableAddOn, EnableAddOn = DisableAddOn, EnableAddOn

local IsShiftKeyDown = IsShiftKeyDown

function stAM:IsAddOnEnabled(addon)
	return GetAddOnEnableState(PA.MyName, addon) == 2
end

StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'] = {
	button1 = 'Overwrite',
	button2 = 'Cancel',
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs['STADDONMANAGER_NEWPROFILE'] = {
	text = "Enter a name for your new Addon Profile:",
	button1 = 'Create',
	button2 = 'Cancel',
	timeout = 0,
	hasEditBox = 1,
	whileDead = 1,
	OnAccept = function(self) stAM:NewAddOnProfile(self.editBox:GetText()) end,
	EditBoxOnEnterPressed = function(self) stAM:NewAddOnProfile(self:GetText()) self:GetParent():Hide() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
}

StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION'] = {
	button1 = 'Delete',
	button2 = 'Cancel',
	timeout = 0,
	whileDead = 1,
	enterClicksFirstButton = 1,
	hideOnEscape = 1,
}

local function strtrim(string)
	return string:gsub("^%s*(.-)%s*$", "%1")
end

function stAM:GetOptions()
	local Options = {
		type = 'group',
		name = stAM.Title,
		desc = stAM.Description,
		order = 219,
		get = function(info) return stAM.db[info[#info]] end,
		set = function(info, value) stAM.db[info[#info]] = value end,
		args = {
			NumAddOns = {
				order = 0,
				type = 'range',
				name = '# Shown AddOns',
				min = 3, max = 30, step = 1,
			},
			FrameWidth = {
				order = 1,
				type = 'range',
				name = 'Frame Width',
				min = 225, max = 1024, step = 1,
			},
			ButtonHeight = {
				order = 2,
				type = 'range',
				name = 'Button Height',
				min = 3, max = 30, step = 1,
			},
			ButtonWidth = {
				order = 3,
				type = 'range',
				name = 'Button Width',
				min = 3, max = 30, step = 1,
			},
			Font = {
				type = 'select', dialogControl = 'LSM30_Font',
				order = 4,
				name = 'Font',
				values = PA.LSM:HashTable('font'),
			},
			FontSize = {
				order = 5,
				name = 'Font Size',
				type = 'range',
				min = 6, max = 22, step = 1,
			},
			FontFlag = {
				order = 6,
				name = 'Font Outline',
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
				order = 7,
				type = 'select', dialogControl = 'LSM30_Statusbar',
				name = 'Texture',
				desc = 'The texture to use.',
				values = PA.LSM:HashTable('statusbar'),
			},
			CheckColor = {
				order = 8,
				type = 'color',
				name = COLOR_PICKER,
				hasAlpha = true,
				get = function(info) return unpack(stAM.db[info[#info]]) end,
				set = function(info, r, g, b, a) stAM.db[info[#info]] = { r, g, b, a} end,
			},
			AuthorHeader = {
				order = 9,
				type = 'header',
				name = 'Authors:',
			},
			Authors = {
				order = 10,
				type = 'description',
				name = stAM.Authors,
				fontSize = 'large',
			},
		},
	}

	PA.Options.args.stAM = Options
end

function stAM:SetupProfile()
	self.db = self.data.profile
end

function stAM:BuildFrame()
	local Frame = CreateFrame("Frame", 'stAMFrame', UIParent)
	Frame:SetSize(self.db['FrameWidth'], 10 + self.db['NumAddOns'] * 25 + 40)
	Frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	Frame:SetTemplate("Transparent")
	Frame:SetFrameStrata('HIGH')
	Frame:SetClampedToScreen(true)
	Frame:SetMovable(true)
	Frame:EnableMouse(true)
	Frame:SetScript("OnMouseDown", function(self) self:StartMoving() end)
	Frame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	local Title = Frame:CreateFontString(nil, 'OVERLAY')
	Title:SetPoint('TOPLEFT', 0, -5)
	Title:SetPoint('TOPRIGHT', 0, -5)
	Title:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
	Title:SetText(stAM.Title)
	Title:SetJustifyH('CENTER')
	Title:SetJustifyV('MIDDLE')
	Frame.Title = Title

	local Close = CreateFrame('Button', nil, Frame)
	Close:SetTemplate()
	Close:SetPoint('TOPRIGHT', -3, -3)
	Close:SetSize(16, 16)
	Close:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) end)
	Close:SetScript('OnLeave', function(self) self:SetTemplate() end)
	Close:SetScript('OnClick', function(self) Frame:Hide() end)
	Close.Text = Close:CreateFontString(nil, 'OVERLAY')
	Close.Text:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
	Close.Text:SetJustifyH('CENTER')
	Close.Text:SetJustifyV('MIDDLE')
	Close.Text:SetText('x')
	Close.Text:SetPoint('CENTER', 1, 1)

	Frame.Close = Close

	local Search = CreateFrame('EditBox', nil, Frame)
	Search:SetSize(1, 20)
	Search:SetTemplate()
	Search:SetAutoFocus(false)
	Search:SetTextInsets(5, 5, 0, 0)
	Search:SetTextColor(1, 1, 1)
	Search:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
	Search:SetShadowOffset(0,0)
	Search:SetText("Search")

	Search:HookScript("OnEnterPressed", function(self)
		if strlen(strtrim(self:GetText())) == 0 then
			stAM:UpdateAddonList()
			self:SetText("Search")
			stAM.searchQuery = false
		end
		self:ClearFocus()
	end)

	Search:HookScript('OnEscapePressed', function(self) stAM:UpdateAddonList() self:SetText("Search") self:ClearFocus()end)
	Search:HookScript("OnTextChanged", function(self, userInput) stAM.scrollOffset = 0 stAM.searchQuery = userInput stAM:UpdateAddonList() end)
	Search:HookScript('OnEditFocusGained', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) self:HighlightText() end)
	Search:HookScript('OnEditFocusLost', function(self) self:SetTemplate() self:HighlightText(0, 0) end)

	Frame.Search = Search
	Frame.Search.AddOns = {}

	local Reload = CreateFrame('Button', nil, Frame)
	Reload:SetTemplate()
	Reload:SetSize(70, 20)
	Reload:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) end)
	Reload:SetScript('OnLeave', function(self) self:SetTemplate() end)
	Reload:SetScript('OnClick', _G.ReloadUI)
	Reload.Text = Reload:CreateFontString(nil, 'OVERLAY')
	Reload.Text:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
	Reload.Text:SetText('Reload')
	Reload.Text:SetPoint('CENTER', 0, 0)
	Reload.Text:SetJustifyH('CENTER')
	Frame.Reload = Reload

	local Profiles = CreateFrame('Button', nil, Frame)
	Profiles:SetTemplate()
	Profiles:SetSize(70, 20)
	Profiles:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) end)
	Profiles:SetScript('OnLeave', function(self) self:SetTemplate() end)
	Profiles:SetScript('OnClick', function() stAM:ToggleProfiles() end)
	Profiles.Text = Profiles:CreateFontString(nil, 'OVERLAY')
	Profiles.Text:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
	Profiles.Text:SetText('Profiles')
	Profiles.Text:SetPoint('CENTER', 0, 0)
	Profiles.Text:SetJustifyH('CENTER')
	Frame.Profiles = Profiles

	--Frame used to display addons list
	local AddOns = CreateFrame("ScrollFrame", nil, Frame)
	AddOns:SetHeight(self.db['NumAddOns'] * (self.db['ButtonHeight'] + 5) + 15)
	AddOns:SetTemplate()
	AddOns.Buttons = {}
	AddOns:EnableMouse(true)
	AddOns:EnableMouseWheel(true)

	AddOns:SetScript('OnMouseWheel', function(self, delta)
		local numAddons = stAM.searchQuery and #Search.AddOns or #stAM.AddOnInfo
		if IsShiftKeyDown() then
			if delta == 1 then
				stAM.scrollOffset = max(0, stAM.scrollOffset - stAM.db['NumAddOns'])
			elseif delta == -1 then
				stAM.scrollOffset = min(#stAM.AddOnInfo - stAM.db['NumAddOns'], stAM.scrollOffset + stAM.db['NumAddOns'])
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
		stAM:UpdateAddonList()
	end)

	for i = 1, 30 do
		local CheckButton = CreateFrame('CheckButton', nil, AddOns)
		CheckButton:SetTemplate()
		CheckButton:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		CheckButton:SetPoint(unpack(i == 1 and {"TOPLEFT", AddOns, "TOPLEFT", 10, -10} or {"TOP", AddOns.Buttons[i-1], "BOTTOM", 0, -5}))
		CheckButton:SetScript('OnClick', function(self)
			if self.name then
				if stAM:IsAddOnEnabled(self.name) then
					DisableAddOn(self.name, PA.MyName)
				else
					EnableAddOn(self.name, PA.MyName)
				end
				stAM:UpdateAddonList()
			end
		end)
		CheckButton:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
			GameTooltip:ClearLines()
			GameTooltip:AddLine(self.title, 1, 1, 1)
			GameTooltip:AddLine(self.author, 1, 1, 1)
			GameTooltip:AddLine(self.notes, 1, 1, 1)
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
		end)
		CheckButton:SetScript('OnLeave', function() GameTooltip:Hide() end)

		local checked = CheckButton:CreateTexture(nil, 'OVERLAY', nil, 1)
		checked:SetTexture(PA.LSM:Fetch('statusbar', self.db['CheckTexture']))
		checked:SetVertexColor(unpack(stAM.db['CheckColor']))
		checked:SetInside(CheckButton)

		CheckButton:SetCheckedTexture(checked)

		local hover = CheckButton:CreateTexture(nil, 'OVERLAY', nil, 2)
		hover:SetColorTexture(1, 1, 1, 0.3)
		hover:SetInside(CheckButton)

		CheckButton:SetHighlightTexture(hover)

		local text = CheckButton:CreateFontString(nil, 'OVERLAY')
		text:SetPoint('LEFT', 5, 0)
		text:SetFont(PA.LSM:Fetch('font', self.db['Font']), self.db['FontSize'], self.db['FontFlag'])
		text:SetText('')
		text:SetJustifyH('CENTER')
		text:ClearAllPoints()
		text:SetPoint("LEFT", CheckButton, "RIGHT", 10, 0)
		text:SetPoint("TOP", CheckButton, "TOP")
		text:SetPoint("BOTTOM", CheckButton, "BOTTOM")
		text:SetPoint("RIGHT", AddOns, "RIGHT", -10, 0)
		text:SetJustifyH("LEFT")

		CheckButton.text = text

		AddOns.Buttons[i] = CheckButton
	end

	Reload:SetPoint('TOPLEFT', AddOns, 'BOTTOMLEFT', 0, -10)
	Profiles:SetPoint('TOPRIGHT', Title, 'BOTTOMRIGHT', -10, -10)

	Search:SetPoint('TOPLEFT', Title, 'BOTTOMLEFT', 10, -10)
	Search:SetPoint('BOTTOMRIGHT', Profiles, 'BOTTOMLEFT', -5, 0)

	AddOns:SetPoint('TOPLEFT', Search, 'BOTTOMLEFT', 0, -5)
	AddOns:SetPoint('TOPRIGHT', Profiles, 'BOTTOMRIGHT', 0, -5)

	Frame.AddOns = AddOns

	self.Frame = Frame

	tinsert(_G.UISpecialFrames, self.Frame:GetName())

	_G.GameMenuButtonAddons:SetScript("OnClick", function() self.Frame:Show() _G.HideUIPanel(_G.GameMenuFrame) end)
end

function stAM:NewAddOnProfile(name, overwrite)
	if _G.stAddonManagerProfilesDB[name] and (not overwrite) then
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].text = 'There is already a profile named ' .. name .. '. Do you want to overwrite it?'
		_G.StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'].OnAccept = function(self) stAM:NewAddOnProfile(name, true) end
		_G.StaticPopup_Show('STADDONMANAGER_OVERWRITEPROFILE')
		return
	end

	_G.stAddonManagerProfilesDB[name] = {}

	for i = 1, #self.AddOnInfo do
		local AddOn, isEnabled = unpack(self.AddOnInfo[i]), stAM:IsAddOnEnabled(i)
		if isEnabled then
			tinsert(_G.stAddonManagerProfilesDB[name], AddOn)
		end
	end

	self:UpdateProfiles()
end

function stAM:InitProfiles()
	local ProfileMenu = CreateFrame('Frame', nil, self.Frame)
	ProfileMenu:SetPoint('TOPLEFT', self.Frame, 'TOPRIGHT', 3, 0)
	ProfileMenu:SetSize(250, 50)
	ProfileMenu:SetTemplate('Transparent')
	ProfileMenu:Hide()

	for _, name in pairs({'Enable All', 'Disable All'}) do
		local Button = CreateFrame('Button', nil, ProfileMenu)
		Button:SetTemplate()
		Button:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
		Button:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) end)
		Button:SetScript('OnLeave', function(self) self:SetTemplate() end)

		Button.Text = Button:CreateFontString(nil, 'OVERLAY')
		Button.Text:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
		Button.Text:SetPoint('CENTER', 0, 0)
		Button.Text:SetJustifyH('CENTER')
		Button.Text:SetText(name)

		ProfileMenu[name:gsub(' ', '')] = Button
	end

	ProfileMenu.EnableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOPLEFT', 10, -10)
	ProfileMenu.EnableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOP', -3, -10)
	ProfileMenu.EnableAll:SetScript('OnClick', function(self)
		for i = 1, #stAM.AddOnInfo do
			EnableAddOn(i, PA.MyName)
		end

		stAM:UpdateAddonList()
	end)

	ProfileMenu.DisableAll:SetPoint('TOPRIGHT', ProfileMenu, 'TOPRIGHT', -10, -10)
	ProfileMenu.DisableAll:SetPoint('TOPLEFT', ProfileMenu, 'TOP', 2, -10)
	ProfileMenu.DisableAll:SetScript('OnClick', function(self)
		for i = 1, #stAM.AddOnInfo do
			DisableAddOn(i, PA.MyName)
		end

		stAM:UpdateAddonList()
	end)

	local NewButton = CreateFrame('Button', nil, ProfileMenu)
	NewButton:SetTemplate()
	NewButton:SetSize(self.db['ButtonWidth'], self.db['ButtonHeight'])
	NewButton:SetPoint('TOPLEFT', ProfileMenu.EnableAll, 'BOTTOMLEFT', 0, -5)
	NewButton:SetPoint('TOPRIGHT', ProfileMenu.DisableAll, 'BOTTOMRIGHT', 0, -5)
	NewButton:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) end)
	NewButton:SetScript('OnLeave', function(self) self:SetTemplate() end)
	NewButton:SetScript('OnClick', function() StaticPopup_Show('STADDONMANAGER_NEWPROFILE') end)
	NewButton.Text = NewButton:CreateFontString(nil, 'OVERLAY')
	NewButton.Text:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
	NewButton.Text:SetPoint('CENTER', 0, 0)
	NewButton.Text:SetJustifyH('CENTER')
	NewButton.Text:SetText('New Profile')

	ProfileMenu.NewButton = NewButton

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
			Button:SetScript('OnEnter', function(self) self:SetBackdropBorderColor(unpack(stAM.db['CheckColor'])) end)
			Button:SetScript('OnLeave', function(self) self:SetTemplate() end)
			Button.Text = Button:CreateFontString(nil, 'OVERLAY')
			Button.Text:SetFont(PA.LSM:Fetch('font', 'PT Sans Narrow'), 12, 'OUTLINE')
			Button.Text:SetPoint('CENTER', 0, 0)
			Button.Text:SetJustifyH('CENTER')

			Pullout[Frame] = Button
		end

		Pullout.Load:SetPoint('LEFT', Pullout, 0, 0)
		Pullout.Load.Text:SetText('Load')
		Pullout.Load:SetScript('OnClick', function(self)
			for _, AddOn in pairs(_G.stAddonManagerProfilesDB[Pullout.Name]) do
				EnableAddOn(AddOn, PA.MyName)
			end

			stAM:UpdateAddonList()
		end)

		Pullout.Update:SetPoint('LEFT', Pullout.Load, 'RIGHT', 5, 0)
		Pullout.Update.Text:SetText('Update')
		Pullout.Update:SetScript('OnClick', function(self)
			stAM:NewAddOnProfile(Pullout.Name, true)
		end)

		Pullout.Delete:SetPoint('LEFT', Pullout.Update, 'RIGHT', 5, 0)
		Pullout.Delete.Text:SetText('Delete')
		Pullout.Delete:SetScript('OnClick', function(self)
			local dialog = StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION']

			dialog.text = format("Are you sure you want to delete %s?", Pullout.Name)
			dialog.OnAccept = function(self)
				_G.stAddonManagerProfilesDB[Pullout.Name] = nil
				stAM:UpdateProfiles()
			end

			StaticPopup_Show('STADDONMANAGER_DELETECONFIRMATION')
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
	ToggleFrame(self.ProfileMenu)
	self:UpdateProfiles()
end

function stAM:Initialize()
	self.data = PA.ADB:New('stAddonManagerDB', {
		profile = {
			['NumAddOns'] = 15,
			['FrameWidth'] = 550,
			['Font'] = 'PT Sans Narrow',
			['FontSize'] = 16,
			['FontFlag'] = 'OUTLINE',
			['ButtonHeight'] = 18,
			['ButtonWidth'] = 22,
			['CheckColor'] = { 0, .66, 1},
			['CheckTexture'] = 'Blizzard Raid Bar'
		},
	}, true)
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')

	self:SetupProfile()
	self:GetOptions()

	self.AddOnInfo = {}
	self.AddOnProfile = {}
	self.Profiles = {}

	for i = 1, GetNumAddOns() do
		local name, title, notes = GetAddOnInfo(i)
		local requireddeps, optionaldeps = GetAddOnDependencies(i), GetAddOnOptionalDependencies(i)
		local author = GetAddOnMetadata(i, "Author")
		self.AddOnInfo[i] = { name, title, author, notes, requireddeps, optionaldeps }
	end

	self:BuildFrame()
	self:InitProfiles()
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
			button.text:SetText(button.title)
			button:SetChecked(stAM:IsAddOnEnabled(addonIndex))
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