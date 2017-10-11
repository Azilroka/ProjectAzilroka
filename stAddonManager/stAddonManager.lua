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

local function strtrim(string)
	return string:gsub("^%s*(.-)%s*$", "%1")
end

function stAM.Initialize(self, event, ...)
	--Only run this function once
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	if self.INITIALIZED then return end

	--If saved variables don't exist, create them
	if not stAM_Profiles then stAM_Profiles = {} end
	if not stAM_Config then stAM_Config = {} end

	-- Make sure all config variables are successfully created if missing
	--This table (stAM.defaultConfig) is located at the top of config.lua
	for conf, val in pairs(stAM.defaultConfig) do
		if stAM_Config[conf] == nil then
			stAM_Config[conf] = val
		end
	end

	--localize the game menu buttons
	local menu = _G.GameMenuFrame
	local macros = _G.GameMenuButtonMacros
	local ratings = _G.GameMenuButtonRatings
	local logout = _G.GameMenuButtonLogout
--[[
	--create the new game menu button
	local addons = CreateFrame("Button", "GameMenuButtonAddons", menu, "GameMenuButtonTemplate")
	addons:SetText("Addons")

	-- If Tukui's skin button function is available, skin it
	if Tukui then
		addons:SkinButton(true)
	end
	
	if ElvUI then
		local E, L, V, P, G, _ = unpack(ElvUI) --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
		local S = E:GetModule('Skins')
		S:HandleButton(addons)
	end

	if Aurora then
		local F, C = unpack(Aurora)
		F.Reskin(addons)
	end

	addons:SetPoint('TOP', GameMenuButtonStore, 'BOTTOM', 0, -1)
	GameMenuButtonOptions:ClearAllPoints()
	GameMenuButtonOptions:SetPoint('TOP', addons, 'BOTTOM', 0, -1)
	GameMenuButtonOptions.SetPoint = function() end

	GameMenuButtonContinue:ClearAllPoints()
	GameMenuButtonContinue:SetPoint('TOP', GameMenuButtonQuit, 'BOTTOM', 0, -1)

	--Set it to load up the addon window on click
	addons:SetScript("OnClick", function() self:LoadWindow() end)
]]
	GameMenuButtonAddons:SetScript("OnClick", function() self:LoadWindow() end)
	self.INITIALIZED = true
end

function stAM.UpdateAddonList(self)
	--Loop through however many buttons there should be
	for i = 1, stAM_Config['numAddonsShown'] do
		local addonIndex = stAM.scrollOffset + i --adjust the scroll offset to get the right addon
		local button = self.addons.buttons[i] 	 --localize the button

		if not button then
			local name = format('%sPage%d', self:GetName(), i)
			local point = i == 1 and {"TOPLEFT", self.addons, "TOPLEFT", 10, -10} or {"TOP", self.addons.buttons[i-1], "BOTTOM", 0, -5}
			local btn = st.CreateCheckBox(name, self.addons, stAM.buttonWidth, stAM.buttonHeight, point, function(self)
				if not GetAddOnInfo(self.addonName) then return end
				
				local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(self.addonName)
				local enabled = GetAddOnEnableState(playerName, self.addonName)
				
				if enabled then
					DisableAddOn(name, playerName)
				else
					EnableAddOn(name, playerName)
				end
				stAM:UpdateAddonList()
			end)

			btn.text:ClearAllPoints()
			btn.text:SetPoint("LEFT", btn, "RIGHT", 10, 0)
			btn.text:SetPoint("TOP", btn, "TOP")
			btn.text:SetPoint("BOTTOM", btn, "BOTTOM")
			btn.text:SetPoint("RIGHT", self.addons, "RIGHT", -10, 0)
			btn.text:SetJustifyH("LEFT")

			self.addons.buttons[i] = btn
			button = self.addons.buttons[i]
		end
		--Check if an addon actually exists to place on this button (and hide the button if there isn't an addon to show)
		if addonIndex <= GetNumAddOns() then
			local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(addonIndex)
			local enabled = GetAddOnEnableState(playerName, addonIndex)
			local requireddeps, optionaldeps = GetAddOnDependencies(addonIndex), GetAddOnOptionalDependencies(addonIndex)
			button.text:SetText(title)
			button:Show()
			button:SetChecked(enabled)
			button:SetScript('OnEnter', function()
				GameTooltip:SetOwner(button, 'ANCHOR_CURSOR')
				GameTooltip:ClearLines()
				GameTooltip:AddLine(title)
				GameTooltip:AddLine(notes)
				if requireddeps then
					GameTooltip:AddDoubleLine('Required Dependencies', requireddeps)
				end
				if optionaldeps then
					GameTooltip:AddDoubleLine('Optional Dependencies', optionaldeps)
				end
				GameTooltip:Show()
			end)
			if not button.hooked_OnLeave then
				button.hooked_OnLeave = true
				button:HookScript('OnLeave', function() GameTooltip:Hide() end)
			end
			button:SetScript("OnClick", function()
				if enabled then
					DisableAddOn(name, playerName)
				else
					EnableAddOn(name, playerName)
				end
				self:UpdateAddonList()
			end)
		else
			button:Hide()
		end
	end

	for i=stAM_Config['numAddonsShown']+1, #self.addons.buttons do
		self.addons.buttons[i]:Hide()
	end

	self.addons:SetHeight(stAM_Config['numAddonsShown']*(stAM.buttonHeight+5) + 15)
	self:SetHeight(self.title:GetHeight() + 5 + self.search:GetHeight() + 5  + self.addons:GetHeight() + 10 + self.profiles:GetHeight() + 10) --Really sketchy, but it's the cleanest way to do this
end

function stAM.UpdateSearchQuery(self, search, userInput)
	local query = strlower(strtrim(search:GetText()))

	--Revert to regular addon list if:
	-- 1) Query text was not input by a user (e.g. text was changed by search:SetText())
	-- 2) The query text contains nothing but spaces
	if (not userInput) or (strlen(query) == 0) then
		self:UpdateAddonList()
		self.searchQuery = false -- make sure scroll bar is using the correct update function
		return
	end

	self.searchQuery = true

	search.addons = {}
	--store all addons that match the query in here
	for i = 1, GetNumAddOns() do
		local name, title = GetAddOnInfo(i)
		name = strlower(name)
		title = strlower(title)

		if strfind(name, query) or strfind(title, query) then
			tinsert(search.addons, i)
		end
	end


	--Loop through however many buttons there should be
	for i = 1, stAM_Config['numAddonsShown'] do
		local addonIndex = search.addons[stAM.scrollOffset + i] --adjust the scroll offset to get the right addon
		local button = self.addons.buttons[i] 	 --localize the button

		--Check if an addon actually exists to place on this button (and hide the button if there isn't an addon to show)
		if addonIndex and addonIndex <= GetNumAddOns() then
			local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(addonIndex)
			local enabled = GetAddOnEnableState(playerName, addonIndex)
			button.text:SetText(title)
			button:Show()

			button:SetChecked(enabled)
			button:SetScript("OnClick", function()
				if enabled then
					DisableAddOn(name, playerName)
				else
					EnableAddOn(name, playerName)
				end
				self:UpdateSearchQuery(search, userInput)
			end)
		else
			button:Hide()
		end
	end
end

function stAM.LoadWindow(self)
	if GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
	if self.LOADED then ToggleFrame(self) return end

	--Hide the extra panels when hiding the main one
	self:SetScript('OnHide', function()
		if stAM.profileMenu and stAM.profileMenu:IsShown() then
			stAM.profileMenu:Hide()
		end
		if stAM.configMenu and stAM.configMenu:IsShown() then
			stAM.configMenu:Hide()
		end
	end)

	--General Skinning
	self:SetSize(stAM_Config['frameWidth'], 10 + stAM_Config['numAddonsShown'] * 25 + 40)
	self:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	self:SetTemplate("Transparent")
	self:SetFrameStrata('HIGH')

	--Some dragging stuff
	self:SetClampedToScreen(true)
	self:SetMovable(true)
	self:EnableMouse(true)
	self:SetScript("OnMouseDown", function(self) self:StartMoving() end)
	self:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	--Title frame
	local title = CreateFrame("Frame", self:GetName()..'_TitleBar', self)
	title:SetPoint('TOPLEFT')
	title:SetPoint('TOPRIGHT')
	title:SetHeight(20)
	title.text = st.CreateFontString(title, nil, "OVERLAY", 'stAddonManager', {'CENTER'}, 'CENTER', st.FontStringTable)
	self.title = title

	--Close button
	self.close = st.CreateButton(title:GetName()..'_CloseButton', title, 18, 18, {'TOPRIGHT', -2, -2}, 'x', function() stAM:Hide() end)

	--Profiles button
	self.profiles = st.CreateButton(self:GetName()..'ProfilesButton', self, 70, 20, {'TOPRIGHT', title, 'BOTTOMRIGHT', -10, -5}, 'Profiles', function() stAM:ToggleProfiles() end)

	--Search Bar
	local search = st.CreateEditBox(self:GetName()..'_SearchBar', self, 1, 20)
	search:SetPoint('TOPLEFT', self.title, 'BOTTOMLEFT', 10, -5)
	search:SetPoint('BOTTOMRIGHT', self.profiles, 'BOTTOMLEFT', -5, 0)
	search:SetText("Search")
	search:SetScript("OnEnterPressed", function(self)
		if strlen(strtrim(self:GetText())) == 0 then
			stAM:UpdateAddonList()
			self:SetText("Search")
		end
	end)
	search:HookScript('OnEscapePressed', function(self) stAM:UpdateAddonList() self:SetText("Search") end)
	search:HookScript("OnTextChanged", function(self, userInput) stAM.scrollOffset = 0 stAM:UpdateSearchQuery(self, userInput) end)
	self.search = search
	self.search.addons = {} -- used to hold addons that fit the search query

	--Frame used to display addons list
	local addons = CreateFrame("Frame", nil, self)
	addons:SetHeight(stAM_Config['numAddonsShown']*(stAM.buttonHeight+5) + 15)
	addons:SetPoint('TOPLEFT', self.search, 'BOTTOMLEFT', 0, -5)
	addons:SetPoint('TOPRIGHT', self.profiles, 'BOTTOMRIGHT', 0, -5)
	addons:SetTemplate()
	addons.buttons = {}

	--Allow the ability to scroll through addons
	-- Much cleaner both code wise and visually than
	-- an actual scroll bar
	addons:EnableMouseWheel(true)
	addons:SetScript('OnMouseWheel', function(self, delta)
		local numAddons = stAM.searchQuery and #stAM.search.addons or GetNumAddOns() 

		--If shift ke is pressed, scroll to the top or bottom
		if IsShiftKeyDown() then
			if delta == 1 then
				stAM.scrollOffset = max(0, stAM.scrollOffset - stAM_Config['numAddonsShown'])
			elseif delta == -1 then
				stAM.scrollOffset = min(GetNumAddOns()-stAM_Config['numAddonsShown'], stAM.scrollOffset + stAM_Config['numAddonsShown'])
			end
		else
			if delta == 1 and stAM.scrollOffset > 0 then
				stAM.scrollOffset = stAM.scrollOffset - 1
			elseif delta == -1 then
				if stAM.scrollOffset < numAddons - stAM_Config['numAddonsShown'] then
					stAM.scrollOffset = stAM.scrollOffset + 1
				end
			end
		end
		if stAM.searchQuery then
			stAM:UpdateSearchQuery(stAM.search, true) -- emulate userInput
		else
			stAM:UpdateAddonList()
		end
	end)
	self.addons = addons

	self.reload = st.CreateButton(self:GetName()..'ReloadButton', self, 70, 20, {'TOPLEFT', addons, 'BOTTOMLEFT', 0, -10}, 'Reload', ReloadUI)
	self.config = st.CreateButton(self:GetName()..'_ConfigButton', title, 70, 20, {'TOPRIGHT', addons, 'BOTTOMRIGHT', 0, -10}, 'Config', function() stAM:ToggleConfig() end)
		
	self:UpdateConfig()

	tinsert(UISpecialFrames, self:GetName())
	self.LOADED = true
end

stAM:RegisterEvent("PLAYER_ENTERING_WORLD")
stAM:SetScript("OnEvent", function(self, event, ...) self:Initialize(event, ...) end)

SLASH_STADDONMANAGER1, SLASH_STADDONMANAGER2, SLASH_STADDONMANAGER3 = "/staddonmanager", "/stAM", "/staddon"
SlashCmdList["STADDONMANAGER"] = function() stAM:LoadWindow() end