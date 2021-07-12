local PA = _G.ProjectAzilroka
if PA.ElvUI then return end

local EC = PA:NewModule("EnhancedConfig", 'AceConsole-3.0', 'AceEvent-3.0')
PA.EC, _G.Enhanced_Config = EC, EC

EC.Title = PA.ACL["|cff1784d1Enhanced Config|r"]
EC.Authors = "Azilroka"

local DEVELOPERS = { 'Elv', 'Tukz', 'Hydrazine', 'Nihilistzsche' }
local DEVELOPER_STRING = ''

sort(DEVELOPERS, function(a,b) return a < b end)
for _, devName in pairs(DEVELOPERS) do
	DEVELOPER_STRING = DEVELOPER_STRING..'|n'..devName
end

EC.Options = PA.ACH:Group('', nil, 4)
EC.Options.args.credits = PA.ACH:Group('Credits', nil, -1)
EC.Options.args.credits.args.text = PA.ACH:Description('Coding:\n'..DEVELOPER_STRING, 1, 'medium')

function EC.OnConfigClosed(widget)
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

	_G.GameTooltip:Hide()
end

function EC:Initialize()
	PA.AC:RegisterOptionsTable('Enhanced_Config', EC.Options)
	PA.ACD:SetDefaultSize('Enhanced_Config', 1200, 800)
	EC:RegisterChatCommand('pa', 'ToggleConfig')

	PA.ACD:AddToBlizOptions('Enhanced_Config', 'ProjectAzilroka')

	EC:RegisterChatCommand('rl', ReloadUI)
	EC:RegisterChatCommand('reloadui', ReloadUI)
end
