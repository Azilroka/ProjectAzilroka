local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local EFL = PA:NewModule('EnhancedFriendsList', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
local LSM = PA.Libs.LSM

PA.EFL, _G.EnhancedFriendsList = EFL, EFL

EFL.Title, EFL.Description, EFL.Authors, EFL.Credits, EFL.isEnabled = 'Enhanced Friends List', ACL['Provides Friends List Customization'], 'Azilroka', 'Marotheit    Merathilis', false

local next, format, unpack, time = next, format, unpack, time

local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

local BNet_GetClientTexture = BNet_GetClientTexture or BNet_GetBattlenetClientAtlas
local GetQuestDifficultyColor = GetQuestDifficultyColor
local WrapTextInColorCode = WrapTextInColorCode

local _G = _G

local MediaPath = 'Interface/AddOns/ProjectAzilroka/Media/EnhancedFriendsList/'

local isBNConnected = _G.BNConnected()
local LEVEL = LEVEL

local BNET_CLIENT_WOW = BNET_CLIENT_WOW

--[[
/run for i,v in pairs(_G) do if type(v)=='string' and i:match('BNET_CLIENT_') then print(i,'=',v) end end
]]

EFL.Icons = {
	Game = {
		Alliance = { Name = _G.FACTION_ALLIANCE, Order = 1, Default = BNet_GetClientTexture(BNET_CLIENT_WOW), Launcher = MediaPath..'GameIcons/Launcher/Alliance' },
		Horde = { Name = _G.FACTION_HORDE, Order = 2, Default = BNet_GetClientTexture(BNET_CLIENT_WOW), Launcher = MediaPath..'GameIcons/Launcher/Horde' },
		Neutral = { Name = _G.FACTION_STANDING_LABEL4, Order = 3, Default = BNet_GetClientTexture(BNET_CLIENT_WOW), Launcher = MediaPath..'GameIcons/Launcher/WoW' },
		App = { Name = ACL['App'], Order = 4, Color = 'FF82C5FF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_APP), Launcher = MediaPath..'GameIcons/Launcher/BattleNet' },
		BSAp = { Name = ACL['Mobile'], Order = 5, Color = 'FF82C5FF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_APP), Launcher = MediaPath..'GameIcons/Launcher/Mobile' },
		D3 = { Name = ACL['Diablo 3'], Color = 'FFC41F3B', Default = BNet_GetClientTexture(_G.BNET_CLIENT_D3), Launcher = MediaPath..'GameIcons/Launcher/D3' },
		Fen = { Name = ACL['Diablo 4'], Color = 'FFC41F3B', Default = BNet_GetClientTexture(_G.BNET_CLIENT_FEN), Launcher = MediaPath..'GameIcons/Launcher/D4' },
		WTCG = { Name = ACL['Hearthstone'], Color = 'FFFFB100', Default = BNet_GetClientTexture(_G.BNET_CLIENT_WTCG), Launcher = MediaPath..'GameIcons/Launcher/Hearthstone' },
		S1 = { Name = ACL['Starcraft'], Color = 'FFC495DD', Default = BNet_GetClientTexture(_G.BNET_CLIENT_SC), Launcher = MediaPath..'GameIcons/Launcher/SC' },
		S2 = { Name = ACL['Starcraft 2'], Color = 'FFC495DD', Default = BNet_GetClientTexture(_G.BNET_CLIENT_SC2), Launcher = MediaPath..'GameIcons/Launcher/SC2' },
		Hero = { Name = ACL['Hero of the Storm'], Color = 'FF00CCFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_HEROES), Launcher = MediaPath..'GameIcons/Launcher/Heroes' },
		Pro = { Name = ACL['Overwatch'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_OVERWATCH), Launcher = MediaPath..'GameIcons/Launcher/Overwatch' },
		VIPR = { Name = ACL['Call of Duty 4'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD), Launcher = MediaPath..'GameIcons/Launcher/COD4' },
		ODIN = { Name = ACL['Call of Duty Modern Warfare'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_MW), Launcher = MediaPath..'GameIcons/Launcher/CODMW' },
		W3 = { Name = ACL['Warcraft 3 Reforged'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_WC3), Launcher = MediaPath..'GameIcons/Launcher/WC3R' },
		LAZR = { Name = ACL['Call of Duty Modern Warfare 2'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_MW2), Launcher = MediaPath..'GameIcons/Launcher/CODMW2' },
		ZEUS = { Name = ACL['Call of Duty Cold War'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_BOCW), Launcher = MediaPath..'GameIcons/Launcher/CODCW' },
		WLBY = { Name = ACL['Crash Bandicoot 4'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_CRASH4), Launcher = MediaPath..'GameIcons/Launcher/CB4' },
		OSI = { Name = ACL['Diablo II Resurrected'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_D2), Launcher = MediaPath..'GameIcons/Launcher/D2' },
		FORE = { Name = ACL['Call of Duty Vanguard'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_VANGUARD), Launcher = MediaPath..'GameIcons/Launcher/CODVanguard' },
		RTRO = { Name = ACL['Arcade Collection'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_ARCADE), Launcher = MediaPath..'GameIcons/Launcher/Arcade' },
		ANBS = { Name = ACL['Diablo Immortal'], Color = 'FFC41F3B', Default = BNet_GetClientTexture(_G.BNET_CLIENT_DI), Launcher = MediaPath..'GameIcons/Launcher/DI' },
		GRY = { Name = ACL['Warcraft Arclight Rumble'], Color = 'FFFFFFFF', Default = BNet_GetClientTexture(_G.BNET_CLIENT_ARCLIGHT), Launcher = MediaPath..'GameIcons/Launcher/Arclight' },
	},
	Status = {
		Online = { Name = _G.FRIENDS_LIST_ONLINE, Order = 1, Default = _G.FRIENDS_TEXTURE_ONLINE, Square = MediaPath..'StatusIcons/Square/Online', D3 = MediaPath..'StatusIcons/D3/Online', Color = {.243, .57, 1} },
		Offline = { Name = _G.FRIENDS_LIST_OFFLINE, Order = 2, Default = _G.FRIENDS_TEXTURE_OFFLINE, Square = MediaPath..'StatusIcons/Square/Offline', D3 = MediaPath..'StatusIcons/D3/Offline', Color = {.486, .518, .541} },
		DND = { Name = _G.DEFAULT_DND_MESSAGE, Order = 3, Default = _G.FRIENDS_TEXTURE_DND, Square = MediaPath..'StatusIcons/Square/DND', D3 = MediaPath..'StatusIcons/D3/DND', Color = {1, 0, 0} },
		AFK = { Name = _G.DEFAULT_AFK_MESSAGE, Order = 4, Default = _G.FRIENDS_TEXTURE_AFK, Square = MediaPath..'StatusIcons/Square/AFK', D3 = MediaPath..'StatusIcons/D3/AFK', Color = {1, 1, 0} },
	}
}

local StatusColor = {}
for name, info in next, EFL.Icons.Status do
	local r, g, b = unpack(info.Color)
	StatusColor[name] = { Inside = CreateColor(r, g, b, .15), Outside = CreateColor(r, g, b, .0)}
end

function EFL:SetGradientColor(button, color1, color2)
	button.Left:SetGradient('Horizontal', color1, color2)
	button.Right:SetGradient('Horizontal', color2, color1)
end

function EFL:CreateTexture(button, type, layer)
	if button.efl and button.efl[type] then
		button.efl[type].Left:SetTexture(LSM:Fetch('statusbar', EFL.db['Texture']))
		button.efl[type].Right:SetTexture(LSM:Fetch('statusbar', EFL.db['Texture']))
		return
	end

	button.efl = button.efl or {}
	button.efl[type] = {}

	button.efl[type].Left = button:CreateTexture(nil, layer)
	button.efl[type].Left:SetHeight(32)
	button.efl[type].Left:SetPoint('LEFT', button, 'CENTER')
	button.efl[type].Left:SetPoint('TOPLEFT', button, 'TOPLEFT')
	button.efl[type].Left:SetTexture('Interface/Buttons/WHITE8X8')

	button.efl[type].Right = button:CreateTexture(nil, layer)
	button.efl[type].Right:SetHeight(32)
	button.efl[type].Right:SetPoint('RIGHT', button, 'CENTER')
	button.efl[type].Right:SetPoint('TOPRIGHT', button, 'TOPRIGHT')
	button.efl[type].Right:SetTexture('Interface/Buttons/WHITE8X8')
end

function EFL:UpdateFriends(button)
	local nameText, infoText
	local status = 'Offline'
	if button.buttonType == _G.FRIENDS_BUTTON_TYPE_WOW then
		local info = _G.C_FriendList.GetFriendInfoByIndex(button.id)
		if info.connected then
			local name, level, class = info.name, info.level, info.className
			local classTag, color, diff = PA:GetClassName(class), PA:ClassColorCode(class), 'FFFFE519'
			status = info.dnd and 'DND' or info.afk and 'AFK' or 'Online'
			if EFL.db.ShowLevel then
				if EFL.db.DiffLevel then
					local diffColor = GetQuestDifficultyColor(level)
					diff = level ~= 0 and format('FF%02x%02x%02x', diffColor.r * 255, diffColor.g * 255, diffColor.b * 255) or 'FFFFFFFF'
				end
				nameText = format('%s |cFFFFFFFF(|r%s - %s %s|cFFFFFFFF)|r', WrapTextInColorCode(name, color), class, LEVEL, WrapTextInColorCode(level, diff))
			else
				nameText = format('%s |cFFFFFFFF(|r%s|cFFFFFFFF)|r', WrapTextInColorCode(name, color), class)
			end
			infoText = info.area

			if classTag then
				button.gameIcon:Show()
				button.gameIcon:SetTexture('Interface/WorldStateFrame/Icons-Classes')
				button.gameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classTag]))
			end
		else
			nameText = info.name
		end
		button.status:SetTexture(EFL.Icons.Status[status][EFL.db.StatusIconPack])
	elseif button.buttonType == _G.FRIENDS_BUTTON_TYPE_BNET and isBNConnected then
		local info = _G.C_BattleNet.GetFriendAccountInfo(button.id)
		if info then
			nameText = info.accountName
			infoText = info.gameAccountInfo.richPresence
			if info.gameAccountInfo.isOnline then
				local client = info.gameAccountInfo.clientProgram
				status = info.isDND and 'DND' or info.isAFK and 'AFK' or 'Online'

				if client == BNET_CLIENT_WOW then
					local level = info.gameAccountInfo.characterLevel
					local characterName = info.gameAccountInfo.characterName
					local classcolor = PA:ClassColorCode(info.gameAccountInfo.className)
					if characterName then
						if EFL.db.ShowLevel then
							local diffColor = GetQuestDifficultyColor(level)
							local diff = EFL.db.DiffLevel and (level ~= 0 and format('FF%02x%02x%02x', diffColor.r * 255, diffColor.g * 255, diffColor.b * 255) or 'FFFFFFFF') or 'FFFFE519'
							nameText = format('%s (%s - %s %s)', nameText, WrapTextInColorCode(characterName, classcolor), LEVEL, WrapTextInColorCode(level, diff))
						else
							nameText = format('%s (%s)', nameText, WrapTextInColorCode(characterName, classcolor))
						end
					end

					if info.gameAccountInfo.wowProjectID == _G.WOW_PROJECT_CLASSIC and info.gameAccountInfo.realmDisplayName ~= PA.MyRealm then
						infoText = format('%s - %s', info.gameAccountInfo.areaName or _G.UNKNOWN, infoText)
					elseif info.gameAccountInfo.realmDisplayName == PA.MyRealm then
						infoText = info.gameAccountInfo.areaName
					end

					local faction = info.gameAccountInfo.factionName
					button.gameIcon:SetTexture(faction and EFL.Icons.Game[faction][EFL.db.GameIconPack or 'Default'] or EFL.Icons.Game.Neutral.Launcher)
				else
					if not EFL.Icons.Game[client] then client = 'BSAp' end
					if EFL.db.ColorByGame then
						nameText = format('|c%s%s|r', EFL.Icons.Game[client].Color or 'FFFFFFFF', nameText)
					end
					button.gameIcon:SetTexture(EFL.Icons.Game[client][EFL.db.GameIconPack or 'Default'])
				end

				button.gameIcon:SetTexCoord(0, 1, 0, 1)
				button.gameIcon:SetDrawLayer('ARTWORK')
				button.gameIcon:SetAlpha(1)
			else
				local lastOnline = info.lastOnlineTime
				infoText = (not lastOnline or lastOnline == 0 or time() - lastOnline >= 31536000) and _G.FRIENDS_LIST_OFFLINE or format(_G.BNET_LAST_ONLINE_TIME, _G.FriendsFrame_GetLastOnline(lastOnline))
			end
			button.status:SetTexture(EFL.Icons.Status[status][EFL.db.StatusIconPack])
		end
	end

	--button.gameIcon:SetPoint('TOPRIGHT', button.summonButton:IsShown() and -50 or -21, -2)

	if nameText then button.name:SetText(nameText) end
	if infoText then button.info:SetText(infoText) end

	if EFL.db.ShowStatusBackground then
		button.background:Hide()

		EFL:CreateTexture(button, 'background', 'BACKGROUND')
		EFL:SetGradientColor(button.efl.background, StatusColor[status].Inside, StatusColor[status].Outside)
	end

	if EFL.db.ShowStatusHighlight then
		button.highlight:SetVertexColor(0, 0, 0, 0)

		EFL:CreateTexture(button, 'highlight', 'HIGHLIGHT')
		EFL:SetGradientColor(button.efl.highlight, StatusColor[status].Inside, StatusColor[status].Outside)
	end

	button.name:SetFont(LSM:Fetch('font', EFL.db.NameFont), EFL.db.NameFontSize, EFL.db.NameFontFlag)
	button.info:SetFont(LSM:Fetch('font', EFL.db.InfoFont), EFL.db.InfoFontSize, EFL.db.InfoFontFlag)

	if button.Favorite and button.Favorite:IsShown() then
		button.Favorite:ClearAllPoints()
		button.Favorite:SetPoint('TOPLEFT', button.name, 'TOPLEFT', button.name:GetStringWidth(), 0)
	end
end

function EFL:GetOptions()
	local EnhancedFriendsList = ACH:Group(EFL.Title, EFL.Description, nil, nil, function(info) return EFL.db[info[#info]] end, function(info, value) EFL.db[info[#info]] = value _G.FriendsFrame_Update() end)
	PA.Options.args.EnhancedFriendsList = EnhancedFriendsList

	EnhancedFriendsList.args.Description = ACH:Description(EFL.Description, 0)
	EnhancedFriendsList.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) EFL.db[info[#info]] = value if not EFL.isEnabled then EFL:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	EnhancedFriendsList.args.General = ACH:Group(ACL['General'], nil, 2)
	EnhancedFriendsList.args.General.inline = true

	EnhancedFriendsList.args.General.args.NameSettings = ACH:Group(ACL['Name Settings'], nil, 1)
	EnhancedFriendsList.args.General.args.NameSettings.inline = true
	EnhancedFriendsList.args.General.args.NameSettings.args.NameFont = ACH:SharedMediaFont(ACL['Name Font'], ACL['The font that the RealID / Character Name / Level uses.'], 1)
	EnhancedFriendsList.args.General.args.NameSettings.args.NameFontSize = ACH:Range(ACL['Name Font Size'], ACL['The font that the RealID / Character Name / Level uses.'], 2, { min = 6, max = 22, step = 1 })
	EnhancedFriendsList.args.General.args.NameSettings.args.NameFontFlag = ACH:FontFlags(ACL['Name Font Flag'], ACL['The font that the RealID / Character Name / Level uses.'], 3)
	EnhancedFriendsList.args.General.args.NameSettings.args.ColorByGame = ACH:Toggle(ACL['Color By Game'], nil, 4)
	EnhancedFriendsList.args.General.args.NameSettings.args.ShowLevel = ACH:Toggle(ACL['Show Level'], nil, 5)
	EnhancedFriendsList.args.General.args.NameSettings.args.DiffLevel = ACH:Toggle(ACL['Level by Difficulty'], nil, 6, nil, nil, nil, nil, nil, function() return (not EFL.db.ShowLevel) end)

	EnhancedFriendsList.args.General.args.InfoSettings = ACH:Group(ACL['Info Settings'], nil, 2)
	EnhancedFriendsList.args.General.args.InfoSettings.inline = true
	EnhancedFriendsList.args.General.args.InfoSettings.args.InfoFont = ACH:SharedMediaFont(ACL['Info Font'], ACL['The font that the Zone / Server uses.'], 1)
	EnhancedFriendsList.args.General.args.InfoSettings.args.InfoFontSize = ACH:Range(ACL['Info Font Size'], ACL['The font size that the Zone / Server uses.'], 2, { min = 6, max = 22, step = 1 })
	EnhancedFriendsList.args.General.args.InfoSettings.args.InfoFontFlag = ACH:FontFlags(ACL['Info Font Outline'], ACL['The font flag that the Zone / Server uses.'], 3)
	EnhancedFriendsList.args.General.args.InfoSettings.args.ShowStatusBackground = ACH:Toggle(ACL['Show Status Background'], nil, 4)
	EnhancedFriendsList.args.General.args.InfoSettings.args.ShowStatusHighlight = ACH:Toggle(ACL['Show Status Highlight'], nil, 5)
	EnhancedFriendsList.args.General.args.InfoSettings.args.Texture = ACH:SharedMediaStatusbar(ACL['Texture'], nil, 6)

	EnhancedFriendsList.args.General.args.IconSettings = ACH:Group(ACL['Icon Settings'], nil, 3)
	EnhancedFriendsList.args.General.args.IconSettings.inline = true
	EnhancedFriendsList.args.General.args.IconSettings.args.GameIconPack = ACH:Select(ACL['Game Icon Pack'], nil, 1, { Default = 'Default', Launcher = 'Launcher' })
	EnhancedFriendsList.args.General.args.IconSettings.args.StatusIconPack = ACH:Select(ACL['Status Icon Pack'], ACL['Different Status Icons.'], 2, { Default = 'Default', Square = 'Square', D3 = 'Diablo 3' })

	EnhancedFriendsList.args.GameIconsPreview = ACH:Group(ACL['Game Icon Preview'], nil, 4)
	EnhancedFriendsList.args.GameIconsPreview.inline = true

	EnhancedFriendsList.args.StatusIcons = ACH:Group(ACL['Status Icon Preview'], nil, 5)
	EnhancedFriendsList.args.StatusIcons.inline = true

	for Key, Value in next, EFL.Icons.Game do
		EnhancedFriendsList.args.GameIconsPreview.args[Key] = ACH:Execute(Value.Name, nil, Value.Order, nil, function(info) return EFL.Icons.Game[info[#info]][EFL.db.GameIconPack], 32, 32 end)
	end

	for Key, Value in next, EFL.Icons.Status do
		EnhancedFriendsList.args.StatusIcons.args[Key] = ACH:Execute(Value.Name, nil, Value.Order, nil, function(info) return EFL.Icons.Status[info[#info]][EFL.db.StatusIconPack], 16, 16 end)
	end

	EnhancedFriendsList.args.AuthorHeader = ACH:Header(ACL['Authors:'], -4)
	EnhancedFriendsList.args.Authors = ACH:Description(EFL.Authors, -3, 'large')
	EnhancedFriendsList.args.CreditsHeader = ACH:Header(ACL['Image Credits:'], -2)
	EnhancedFriendsList.args.Credits = ACH:Description(EFL.Credits, -1, 'large')
end

function EFL:BuildProfile()
	PA.Defaults.profile.EnhancedFriendsList = {
		Enable = true,
		NameFont = 'Arial Narrow',
		NameFontSize = 12,
		NameFontFlag = 'OUTLINE',
		InfoFont = 'Arial Narrow',
		InfoFontSize = 12,
		InfoFontFlag = 'OUTLINE',
		StatusIconPack = 'Default',
		ShowLevel = true,
		ColorByGame = true,
		DiffLevel = true,
		ShowStatusHighlight = true,
		ShowStatusBackground = false,
		Texture = 'Solid',
		GameIconPack = 'Launcher'
	}

	if PA.ElvUI then
		PA.Defaults.profile.EnhancedFriendsList.NameFont = _G.ElvUI[1].db.general.font
		PA.Defaults.profile.EnhancedFriendsList.InfoFont = _G.ElvUI[1].db.general.font
	elseif PA.Tukui then
		PA.Defaults.profile.EnhancedFriendsList.NameFont = 'Tukui Pixel'
		PA.Defaults.profile.EnhancedFriendsList.InfoFont = 'Tukui Pixel'
		PA.Defaults.profile.EnhancedFriendsList.NameFontFlag = 'MONOCHROMEOUTLINE'
		PA.Defaults.profile.EnhancedFriendsList.InfoFontFlag = 'MONOCHROMEOUTLINE'
	end
end

function EFL:HandleBN()
	isBNConnected = _G.BNConnected()
end

function EFL:UpdateSettings()
	EFL.db = PA.db.EnhancedFriendsList
end

function EFL:Initialize()
	if EFL.db.Enable ~= true then
		return
	end

	EFL.isEnabled = true

	EFL:RegisterEvent('BN_CONNECTED', 'HandleBN')
	EFL:RegisterEvent('BN_DISCONNECTED', 'HandleBN')

	if PA.db.FriendGroups and PA.db.FriendGroups.Enable then
		EFL:SecureHook(_G.FriendGroups, 'FriendGroups_UpdateFriendButton', function(_, button) EFL:UpdateFriends(button) end)
	else
		EFL:SecureHook('FriendsFrame_UpdateFriendButton', 'UpdateFriends')
	end
end
