local PA = _G.ProjectAzilroka
if PA.ElvUI then return end

if PA.Tukui then
	Tukui[1].Miscellaneous.GameMenu.EnableTukuiConfig = function() end
	Tukui[1].Miscellaneous.GameMenu.AddHooks = function() end
end

local EC = PA:NewModule("EnhancedConfig", 'AceConsole-3.0', 'AceEvent-3.0')
PA.EC, _G.Enhanced_Config = EC, EC

EC.Title = PA.ACL["|cff1784d1Enhanced Config|r"]
EC.Authors = "Azilroka"

local DEVELOPERS = {
	'Elv',
	'Tukz',
	'Hydrazine',
	'Whiro',
}

local DEVELOPER_STRING = ''

sort(DEVELOPERS, function(a,b) return a < b end)
for _, devName in pairs(DEVELOPERS) do
	DEVELOPER_STRING = DEVELOPER_STRING..'\n'..devName
end

EC.Options = {
	type = 'group',
	name = EC.Title,
	order = 205,
	args = {
		credits = {
			type = 'group',
			name = 'Credits',
			order = -1,
			args = {
				text = {
					order = 1,
					type = 'description',
					fontSize = 'medium',
					name = 'Coding:\n'..DEVELOPER_STRING,
				},
			},
		},
	},
}

function EC:PositionGameMenuButton()
	GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + GameMenuButtonLogout:GetHeight() - 4)

	if PA.Tukui and Tukui[1].Miscellaneous.GameMenu.Tukui then
		GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + GameMenuButtonLogout:GetHeight() - 4)
	end

	local _, relTo, _, _, offY = GameMenuButtonLogout:GetPoint()
	if relTo ~= GameMenuFrame['EC'] then
		GameMenuFrame['EC']:ClearAllPoints()
		GameMenuFrame['EC']:SetPoint("TOPLEFT", PA.Tukui and Tukui[1].Miscellaneous.GameMenu.Tukui or relTo, "BOTTOMLEFT", 0, -1)
		GameMenuButtonLogout:ClearAllPoints()
		GameMenuButtonLogout:SetPoint("TOPLEFT", GameMenuFrame['EC'], "BOTTOMLEFT", 0, offY)
	end
end

function EC.OnConfigClosed(widget, event)
	PA.ACD.OpenFrames['Enhanced_Config'] = nil
	PA.GUI:Release(widget)
end

function EC:ToggleConfig()
	if not PA.ACD.OpenFrames['Enhanced_Config'] then
		local Container = PA.GUI:Create('Frame')
		if PA.AS then
			PA.AS:CreateShadow(Container.frame)
		end
		PA.ACD.OpenFrames['Enhanced_Config'] = Container
		Container:SetCallback('OnClose', EC.OnConfigClosed)
		PA.ACD:Open('Enhanced_Config', Container)
	end

	GameTooltip:Hide()
end

function EC:Initialize()
	local GameMenuButton = CreateFrame("Button", nil, GameMenuFrame, "GameMenuButtonTemplate")
	GameMenuButton:SetText(EC.Title)
	GameMenuButton:SetScript("OnClick", function()
		EC:ToggleConfig()
		HideUIPanel(GameMenuFrame)
	end)
	GameMenuFrame['EC'] = GameMenuButton

	if not IsAddOnLoaded("ConsolePortUI_Menu") then
		GameMenuButton:SetSize(GameMenuButtonLogout:GetWidth(), GameMenuButtonLogout:GetHeight())
		GameMenuButton:SetPoint("TOPLEFT", GameMenuButtonAddons, "BOTTOMLEFT", 0, -1)
		hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', self.PositionGameMenuButton)
	end

	PA.AC:RegisterOptionsTable('Enhanced_Config', EC.Options)
	PA.ACD:SetDefaultSize('Enhanced_Config', 1200, 800)
	EC:RegisterChatCommand('ec', 'ToggleConfig')
end
