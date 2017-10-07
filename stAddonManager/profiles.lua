local addon, st = ...
local stAM = st[1] --for local usage
local playerName = UnitName("player")
local old_GetAddOnEnableState = GetAddOnEnableState
local function GetAddOnEnableState(arg1, arg2)
	local t_arg1 = type(arg1)
	if not arg2 and (t_arg1 == "number" or t_arg1 == "string") then
		arg2 = arg1
		arg1 = playerName
	end
	local val = old_GetAddOnEnableState(arg1,arg2)
	return val == 2
end

--[[ "DELETE PROFILE" DIALOG ]]
StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE'] = {
	text = "There is already a profile named ??????, Do you want to overwrite it?",
	button1 = 'Overwrite',
	button2 = 'Cancel',
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self) end,
	preferredIndex = 3,
}

function stAM:NewAddonProfile(name, overwrite)
	if stAM_Profiles[name] and (not overwrite) then 
		local dialog = StaticPopupDialogs['STADDONMANAGER_OVERWRITEPROFILE']
		dialog.text = 'There is already a profile named ' .. name .. '. Do you want to overwrite it?'
		dialog.OnAccept = function(self) stAM:NewAddonProfile(name, true) end
		StaticPopup_Show('STADDONMANAGER_OVERWRITEPROFILE')	
	return end

	local addonList = {}
	for i = 1, GetNumAddOns() do
		local addonName = GetAddOnInfo(i)
		local isEnabled = GetAddOnEnableState(playerName, i)
		if isEnabled then
			tinsert(addonList, addonName)
		end
	end
	stAM_Profiles[name] = addonList

	self.profileMenu.pullout:Hide()
	self:UpdateProfiles()
end 

StaticPopupDialogs['STADDONMANAGER_NEWPROFILE'] = {
	text = "Enter a name for your new Addon Profile:",
	button1 = 'Create',
	button2 = 'Cancel',
	timeout = 0,
	hasEditBox = true,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self) stAM:NewAddonProfile(self.editBox:GetText()) end,
	preferredIndex = 3,
}

function stAM:InitProfiles()
	if self.profileMenu then return end

	local profileMenu = CreateFrame('Frame', self:GetName()..'_ProfileMenu', self)
	profileMenu:SetPoint('TOPLEFT', self.profiles, 'TOPRIGHT', 9, 0)
	profileMenu:SetSize(250, 50)
	profileMenu:SetTemplate()
	profileMenu:SetFrameLevel(self:GetFrameLevel()-1)

	----------------------------------------------------
	-- PULLOUT MENU ------------------------------------
	----------------------------------------------------
	local pullout = CreateFrame('Frame', profileMenu:GetName()..'_PulloutMenu', profileMenu)
	pullout:SetWidth(profileMenu:GetWidth() - stAM.buttonWidth - 40)
	pullout:SetHeight(stAM.buttonHeight)
	pullout:Hide()
	
	--[[ "SET TO" BUTTON ]]
	pullout.setTo = st.CreateButton(profileMenu:GetName()..'_SetToButton', pullout, pullout:GetWidth()/4, stAM.buttonHeight, {'LEFT', pullout, 0, 0}, 'Set To', function(self, btn)
		local profileName = self:GetParent():GetParent().text:GetText()
		--if shift key is pressed, don't disable current addons
		if not IsShiftKeyDown() then
			for i=1, GetNumAddOns() do DisableAddOn(i, playerName) end
		end
		for _,addonName in pairs(stAM_Profiles[profileName]) do
			EnableAddOn(addonName, playerName)
		end
		stAM:UpdateAddonList()
		pullout:Hide()
	end)

	--[[ "REMOVE FROM" BUTTON ]]
	pullout.removeFrom = st.CreateButton(profileMenu:GetName()..'_RemoveButton', pullout, pullout:GetWidth()/4, stAM.buttonHeight, {'LEFT', pullout.setTo, 'RIGHT', 5, 0}, 'Remove', function(self, btn)
		local profileName = self:GetParent():GetParent().text:GetText()
		for _,addonName in pairs(stAM_Profiles[profileName]) do
			DisableAddOn(addonName, playerName)
		end
		EnableAddOn(addon, playerName) --Make sure this addon stays enabled
		stAM:UpdateAddonList()
		pullout:Hide()
	end)

	--[[ "DELETE PROFILE" DIALOG ]]
	StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION'] = {
		text = "Are you sure you want to delete ???????",
		button1 = 'Delete',
		button2 = 'Cancel',
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnAccept = function(self, data, data2) end,
		preferredIndex = 3,
	}

	--[[ "DELETE PROFILE" BUTTON ]]
	pullout.deleteProfile = st.CreateButton(profileMenu:GetName().."_DeleteProfileButton", pullout, pullout:GetWidth()/4, stAM.buttonHeight, {'LEFT', pullout.removeFrom, 'RIGHT', 5, 0}, 'Delete', function(self, btn)
		local profileName = self:GetParent():GetParent().text:GetText()
		local dialog = StaticPopupDialogs['STADDONMANAGER_DELETECONFIRMATION']

		--Modify static popup information to specific button
		dialog.text = format("Are you sure you want to delete %s?", profileName)
		dialog.OnAccept = function(self, data, data2)
			stAM_Profiles[profileName] = nil
			stAM:UpdateProfiles()
		end
		StaticPopup_Show('STADDONMANAGER_DELETECONFIRMATION')
	end)

	pullout.updateprofile = st.CreateButton(profileMenu:GetName().."_UpdateProfileButton", pullout, pullout:GetWidth()/4, stAM.buttonHeight, {'LEFT', pullout.deleteProfile, 'RIGHT', 5, 0}, 'Update', function(self, btn)
		stAM:NewAddonProfile(self:GetParent():GetParent().text:GetText(), true)
	end)

	--[[ ANCHOR FUNCTION - Used to change which button the pullout is set to ]]
	pullout.AnchorToButton = function(self, button)
		local profileName = button.text:GetText()
		self:SetParent(button)
		self:SetPoint('LEFT', button, 'RIGHT', 5, 0)
		self:Show()
	end

	profileMenu.pullout = pullout


	----------------------------------------------------
	-- TOP MENU BUTTONS --------------------------------
	----------------------------------------------------
	for b,name in pairs({'Enable All', 'Disable All'}) do
		local button = st.CreateButton(profileMenu:GetName()..'_'..name, profileMenu, 1, stAM.buttonHeight, nil, name, function(self) 
			for i=1, GetNumAddOns() do
				if b == 1 then
					EnableAddOn(i, playerName)
				elseif not (GetAddOnInfo(i) == addon) then -- Disable all addons except this one
					DisableAddOn(i, playerName)
				end
			end
			stAM:UpdateAddonList()
		end)

		if b == 1 then
			button:SetPoint('TOPLEFT', profileMenu, 'TOPLEFT', 10, -10)
			button:SetPoint('TOPRIGHT', profileMenu, 'TOP', -3, -10)
		else
			button:SetPoint('TOPRIGHT', profileMenu, 'TOPRIGHT', -10, -10)
			button:SetPoint('TOPLEFT', profileMenu, 'TOP', 2, -10)
		end
		
		name = name:gsub(' ', '')
		profileMenu[name] = button
	end

	local newButton = st.CreateButton(profileMenu:GetName()..'_NewProfileButton', profileMenu, 1, stAM.buttonHeight, {'TOPLEFT', profileMenu.EnableAll, 'BOTTOMLEFT', 0, -5}, 'New Profile', function() StaticPopup_Show('STADDONMANAGER_NEWPROFILE') end)
	newButton:SetPoint('TOPRIGHT', profileMenu.DisableAll, 'BOTTOMRIGHT', 0, -5)
	profileMenu.newButton = newButton

	profileMenu.buttons = {} --Store only buttons in here

	self.profileMenu = profileMenu
end

function stAM:UpdateProfiles()
	local profiles = {}
	local profileMenu = self.profileMenu
	local buttons = self.profileMenu.buttons
	local pullout = profileMenu.pullout

	for name,_ in pairs(stAM_Profiles) do
		tinsert(profiles, name)
	end
	sort(profiles)

	for i = 1, #profiles do
		if not buttons[i] then
			local name = format('%s_button%d', self.profileMenu:GetName(), i)
			local button = st.CreateButton(name, profileMenu, stAM.buttonWidth, stAM.buttonHeight, nil, profiles[i], function(self) 
				if (pullout:GetParent() == self and pullout:IsShown()) then 
					pullout:Hide() 
				else 
					pullout:AnchorToButton(self) 
				end
			end)
			button.text:ClearAllPoints()
			button.text:SetPoint("LEFT", button, "RIGHT", 10, 0)
			button.text:SetPoint("RIGHT", self.profileMenu, "RIGHT", -10, 0)
			button.text:SetJustifyH("LEFT")

			if i == 1 then
				pullout:AnchorToButton(button)
				pullout:Hide()
				button:SetPoint("TOPLEFT", profileMenu.newButton, "BOTTOMLEFT", 0, -5)
			else
				button:SetPoint("TOP", profileMenu.buttons[i-1], "BOTTOM", 0, -5)
			end
			button.arrow = st.CreateFontString(button, nil, 'OVERLAY', '>', {'CENTER', 1, 1}, 'CENTER', st.FontStringTable)

			profileMenu.buttons[i] = button
		end

		buttons[i]:Show()
		buttons[i].text:SetText(profiles[i])
	end

	--Hide all buttons that arne't being used - These buttons only appear after profile deletion, and do not re-appear upon reloading the UI
	if #profiles < #buttons then
		for i=#profiles+1, #buttons do
			buttons[i]:Hide()
		end
	end

	-- Make sure this is hidden so that it's not accidentally shown on the wrong profile
	if self.profileMenu.pullout:IsShown() then
		self.profileMenu.pullout:Hide()
	end

	profileMenu:SetHeight((#profiles+2)*(stAM.buttonHeight+5) + 15)
end

function stAM:ToggleProfiles()
	if not self.profileMenu then
		self:InitProfiles()
	else
		ToggleFrame(self.profileMenu)
	end
	self:UpdateProfiles()
end