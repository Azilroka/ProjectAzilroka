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

function EC:Initialize()
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

	local ConfigButton = CreateFrame('Button', 'Enhanced_ConfigButton', GameMenuFrame, 'GameMenuButtonTemplate')
	ConfigButton:SetSize(GameMenuButtonUIOptions:GetWidth(), GameMenuButtonUIOptions:GetHeight())
	ConfigButton:SetPoint('TOP', GameMenuButtonUIOptions, 'BOTTOM', 0 , -1)
	ConfigButton:SetText(EC.Title)
	ConfigButton:SetScript('OnClick', function() EC:ToggleConfig() HideUIPanel(GameMenuFrame) end)
	GameMenuFrame:HookScript('OnShow', function(self) self:SetHeight(self:GetHeight() + GameMenuButtonUIOptions:GetHeight()) end)
	GameMenuButtonKeybindings:ClearAllPoints()
	GameMenuButtonKeybindings:SetPoint("TOP", ConfigButton, "BOTTOM", 0, -1)

	PA.AC:RegisterOptionsTable('Enhanced_Config', EC.Options)
	PA.ACD:SetDefaultSize('Enhanced_Config', 1200, 800)
	EC:RegisterChatCommand('ec', 'ToggleConfig')
end

EC:RegisterEvent('PLAYER_LOGIN', 'Initialize')
