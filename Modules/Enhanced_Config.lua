local PA = _G.ProjectAzilroka
if PA.ElvUI then return end

local EC = PA:NewModule("EnhancedConfig", 'AceConsole-3.0', 'AceEvent-3.0')
PA.EC, _G.Enhanced_Config = EC, EC

EC.Title = "|cff1784d1Enhanced Config|r"
EC.Authors = "Azilroka"

local DEVELOPERS = {
	'Elv',
	'Tukz',
	'Hydrazine',
	'Infinitron',
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

-- "legioninvasion-map-icon-portal-large"

function EC:Initialize()
	local Anchor = GameMenuButtonUIOptions -- IsAddOnLoaded('Tukui_ConfigUI') and GameMenuTukuiButtonOptions
	local ConfigButton = CreateFrame('Button', 'Enhanced_ConfigButton', GameMenuFrame, 'GameMenuButtonTemplate')
	ConfigButton:Size(Anchor:GetWidth(), Anchor:GetHeight())
	ConfigButton:Point('TOP', Anchor, 'BOTTOM', 0 , -1)
	ConfigButton:SetScript('OnClick', function() EC:ToggleConfig() HideUIPanel(GameMenuFrame) end)
	ConfigButton:SetText(EC.Title)
	GameMenuFrame:HookScript('OnShow', function(self) self:SetHeight(self:GetHeight() + Anchor:GetHeight()) end)
	GameMenuButtonKeybindings:ClearAllPoints()
	GameMenuButtonKeybindings:Point("TOP", ConfigButton, "BOTTOM", 0, -1)
	ConfigButton:SkinButton()

	PA.AC:RegisterOptionsTable('Enhanced_Config', EC.Options)
	PA.ACD:SetDefaultSize('Enhanced_Config', 1200, 800)
	EC:RegisterChatCommand('ec', 'ToggleConfig')

	function EC.OnConfigClosed(widget, event)
		PA.ACD.OpenFrames['Enhanced_Config'] = nil
		PA.GUI:Release(widget)
	end

	function EC:ToggleConfig()
		if not PA.ACD.OpenFrames['Enhanced_Config'] then
			local Container = PA.GUI:Create('Frame')
			PA.ACD.OpenFrames['Enhanced_Config'] = Container
			Container:SetCallback('OnClose', EC.OnConfigClosed)
			PA.ACD:Open('Enhanced_Config', Container)
		end
		GameTooltip:Hide()
	end
end

EC:RegisterEvent('PLAYER_LOGIN', 'Initialize')