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

EC.Options = PA.ACH:Group(EC.Title, nil, 4)
EC.Options.args.credits = PA.ACH:Group('Credits', nil, -1)
EC.Options.args.credits.args.text = PA.ACH:Description('Coding:\n'..DEVELOPER_STRING, 1, 'medium')

function EC:PositionGameMenuButton()
	_G.GameMenuFrame:SetHeight(_G.GameMenuFrame:GetHeight() + _G.GameMenuButtonLogout:GetHeight() - 4)

	if PA.Tukui and _G.Tukui[1].Miscellaneous.GameMenu.Tukui then
		_G.GameMenuFrame:SetHeight(_G.GameMenuFrame:GetHeight() + _G.GameMenuButtonLogout:GetHeight() - 4)
	end

	local _, relTo, _, _, offY = _G.GameMenuButtonLogout:GetPoint()
	if relTo ~= _G.GameMenuFrame['EC'] then
		_G.GameMenuFrame['EC']:ClearAllPoints()
		_G.GameMenuFrame['EC']:SetPoint("TOPLEFT", PA.Tukui and _G.Tukui[1].Miscellaneous.GameMenu.Tukui or relTo, "BOTTOMLEFT", 0, -1)
		_G.GameMenuButtonLogout:ClearAllPoints()
		_G.GameMenuButtonLogout:SetPoint("TOPLEFT", _G.GameMenuFrame['EC'], "BOTTOMLEFT", 0, offY)
	end
end

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
	local GameMenuButton = _G.CreateFrame("Button", nil, _G.GameMenuFrame, "GameMenuButtonTemplate")
	GameMenuButton:SetText(EC.Title)
	GameMenuButton:SetScript("OnClick", function()
		EC:ToggleConfig()
		_G.HideUIPanel(_G.GameMenuFrame)
	end)
	_G.GameMenuFrame['EC'] = GameMenuButton

	if PA.Tukui then
		_G.Tukui[1].Miscellaneous.GameMenu.EnableTukuiConfig = function() end
		_G.Tukui[1].Miscellaneous.GameMenu.AddHooks = function() end
	end

	if not _G.IsAddOnLoaded("ConsolePortUI_Menu") then
		GameMenuButton:SetSize(_G.GameMenuButtonLogout:GetWidth(), _G.GameMenuButtonLogout:GetHeight())
		GameMenuButton:SetPoint("TOPLEFT", _G.GameMenuButtonAddons, "BOTTOMLEFT", 0, -1)
		_G.hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', EC.PositionGameMenuButton)
	end

	PA.AC:RegisterOptionsTable('Enhanced_Config', EC.Options)
	PA.ACD:SetDefaultSize('Enhanced_Config', 1200, 800)
	EC:RegisterChatCommand('ec', 'ToggleConfig')

	EC:RegisterChatCommand('rl', ReloadUI)
	EC:RegisterChatCommand('reloadui', ReloadUI)
end
