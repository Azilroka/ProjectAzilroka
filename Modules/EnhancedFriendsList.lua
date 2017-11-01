local PA = _G.ProjectAzilroka
local EFL = LibStub('AceAddon-3.0'):NewAddon('EnhancedFriendsList', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
_G.EnhancedFriendsList = EFL

EFL.Title = 'Enhanced Friends List'
EFL.Author = 'Azilroka'

local pairs, tonumber = pairs, tonumber
local format = format
local Locale = GetLocale()
local GetFriendInfo, BNGetFriendInfo, BNGetGameAccountInfo, BNConnected, GetQuestDifficultyColor, CanCooperateWithGameAccount = GetFriendInfo, BNGetFriendInfo, BNGetGameAccountInfo, BNConnected, GetQuestDifficultyColor, CanCooperateWithGameAccount

local MediaPath = 'Interface\\AddOns\\ProjectAzilroka\\Media\\EnhancedFriendsList\\'
-- Marotheit
--[[
BNET_CLIENT_APP
BNET_CLIENT_WOW
BNET_CLIENT_SC2
BNET_CLIENT_D3
BNET_CLIENT_WTCG
BNET_CLIENT_HEROES
BNET_CLIENT_OVERWATCH
BNET_CLIENT_SC
BNET_CLIENT_DESTINY2
]]

local GameIcons = {
	Default = {
		Alliance = BNet_GetClientTexture(BNET_CLIENT_WOW ),
		Horde = BNet_GetClientTexture(BNET_CLIENT_WOW ),
		Neutral = BNet_GetClientTexture(BNET_CLIENT_WOW ),
		D3 = BNet_GetClientTexture(BNET_CLIENT_D3),
		WTCG = BNet_GetClientTexture(BNET_CLIENT_WTCG),
		S1 = BNet_GetClientTexture(BNET_CLIENT_SC),
		S2 = BNet_GetClientTexture(BNET_CLIENT_SC2),
		App = BNet_GetClientTexture(BNET_CLIENT_APP),
		BSAp = BNet_GetClientTexture(BNET_CLIENT_APP),
		Hero = BNet_GetClientTexture(BNET_CLIENT_HEROES),
		Pro = BNet_GetClientTexture(BNET_CLIENT_OVERWATCH),
		DST2 = BNet_GetClientTexture(BNET_CLIENT_DESTINY2),
	},
	BlizzardChat = {
		Alliance = 'Interface\\ChatFrame\\UI-ChatIcon-WoW',
		Horde = 'Interface\\ChatFrame\\UI-ChatIcon-WoW',
		Neutral = 'Interface\\ChatFrame\\UI-ChatIcon-WoW',
		D3 = 'Interface\\ChatFrame\\UI-ChatIcon-D3',
		WTCG = 'Interface\\ChatFrame\\UI-ChatIcon-WTCG',
		S1 = 'Interface\\ChatFrame\\UI-ChatIcon-SC',
		S2 = 'Interface\\ChatFrame\\UI-ChatIcon-SC2',
		App = 'Interface\\ChatFrame\\UI-ChatIcon-Battlenet',
		BSAp = 'Interface\\ChatFrame\\UI-ChatIcon-Battlenet',
		Hero = 'Interface\\ChatFrame\\UI-ChatIcon-HotS',
		Pro = 'Interface\\ChatFrame\\UI-ChatIcon-Overwatch',
		DST2 = 'Interface\\ChatFrame\\UI-ChatIcon-Destiny2',
	},
	Flat = {
		Alliance = MediaPath..'GameIcons\\Flat\\Alliance',
		Horde = MediaPath..'GameIcons\\Flat\\Horde',
		Neutral = MediaPath..'GameIcons\\Flat\\Neutral',
		D3 = MediaPath..'GameIcons\\Flat\\D3',
		WTCG = MediaPath..'GameIcons\\Flat\\Hearthstone',
		S1 = 'Interface\\ChatFrame\\UI-ChatIcon-SC',
		S2 = MediaPath..'GameIcons\\Flat\\SC2',
		App = MediaPath..'GameIcons\\Flat\\BattleNet',
		BSAp = MediaPath..'GameIcons\\Flat\\BattleNet',
		Hero = MediaPath..'GameIcons\\Flat\\Heroes',
		Pro = MediaPath..'GameIcons\\Flat\\Overwatch',
		DST2 = 'Interface\\ChatFrame\\UI-ChatIcon-Destiny2',
	},
	Gloss = {
		Alliance = MediaPath..'GameIcons\\Gloss\\Alliance',
		Horde = MediaPath..'GameIcons\\Gloss\\Horde',
		Neutral = MediaPath..'GameIcons\\Gloss\\Neutral',
		D3 = MediaPath..'GameIcons\\Gloss\\D3',
		WTCG = MediaPath..'GameIcons\\Gloss\\Hearthstone',
		S1 = 'Interface\\ChatFrame\\UI-ChatIcon-SC',
		S2 = MediaPath..'GameIcons\\Gloss\\SC2',
		App = MediaPath..'GameIcons\\Gloss\\BattleNet',
		BSAp = MediaPath..'GameIcons\\Gloss\\BattleNet',
		Hero = MediaPath..'GameIcons\\Gloss\\Heroes',
		Pro = MediaPath..'GameIcons\\Gloss\\Overwatch',
		DST2 = 'Interface\\ChatFrame\\UI-ChatIcon-Destiny2',
	},
	Launcher = {
		Alliance = MediaPath..'GameIcons\\Launcher\\Alliance',
		Horde = MediaPath..'GameIcons\\Launcher\\Horde',
		Neutral = MediaPath..'GameIcons\\Launcher\\WoW',
		D3 = MediaPath..'GameIcons\\Launcher\\D3',
		WTCG = MediaPath..'GameIcons\\Launcher\\Hearthstone',
		S1 = MediaPath..'GameIcons\\Launcher\\SC',
		S2 = MediaPath..'GameIcons\\Launcher\\SC2',
		App = MediaPath..'GameIcons\\Launcher\\BattleNet',
		BSAp = MediaPath..'GameIcons\\Launcher\\BattleNet',
		Hero = MediaPath..'GameIcons\\Launcher\\Heroes',
		Pro = MediaPath..'GameIcons\\Launcher\\Overwatch',
		DST2 = MediaPath..'GameIcons\\Launcher\\Destiny2',
	},
}

local StatusIcons = {
	Default = {
		Online = FRIENDS_TEXTURE_ONLINE,
		Offline = FRIENDS_TEXTURE_OFFLINE,
		DND = FRIENDS_TEXTURE_DND,
		AFK = FRIENDS_TEXTURE_AFK,
	},
	Square = {
		Online = MediaPath..'StatusIcons\\Square\\Online',
		Offline = MediaPath..'StatusIcons\\Square\\Offline',
		DND = MediaPath..'StatusIcons\\Square\\DND',
		AFK = MediaPath..'StatusIcons\\Square\\AFK',
	},
	D3 = {
		Online = MediaPath..'StatusIcons\\D3\\Online',
		Offline = MediaPath..'StatusIcons\\D3\\Offline',
		DND = MediaPath..'StatusIcons\\D3\\DND',
		AFK = MediaPath..'StatusIcons\\D3\\AFK',
	},
}

local ClientColor = {
	S1 = 'C495DD',
	S2 = 'C495DD',
	D3 = 'C41F3B',
	Pro = 'FFFFFF',
	WTCG = 'FFB100',
	Hero = '00CCFF',
	App = '82C5FF',
	BSAp = '82C5FF',
}

function EFL:GetOptions()
	local Options = {
		type = 'group',
		name = EFL.Title,
		order = 206,
		args = {
			header = {
				order = 1,
				type = 'header',
				name = 'Friends List Customization',
			},
			general = {
				order = 2,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return EFL.db[info[#info]] end,
				set = function(info, value) EFL.db[info[#info]] = value FriendsFrame_Update() end,
				args = {
					NameFont = {
						type = 'select', dialogControl = 'LSM30_Font',
						order = 1,
						name = 'Name Font',
						desc = 'The font that the RealID / Character Name / Level uses.',
						values = AceGUIWidgetLSMlists.font,
					},
					NameFontSize = {
						order = 2,
						name = 'Name Font Size',
						desc = 'The font size that the RealID / Character Name / Level uses.',
						type = 'range',
						min = 6, max = 22, step = 1,
					},
					NameFontFlag = {
						name = 'Name Font Flag',
						desc = 'The font flag that the RealID / Character Name / Level uses.',
						order = 3,
						type = 'select',
						values = {
							['NONE'] = 'None',
							['OUTLINE'] = 'OUTLINE',
							['MONOCHROME'] = 'MONOCHROME',
							['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
							['THICKOUTLINE'] = 'THICKOUTLINE',
						},
					},
					InfoFont = {
						type = 'select', dialogControl = 'LSM30_Font',
						order = 4,
						name = 'Info Font',
						desc = 'The font that the Zone / Server uses.',
						values = AceGUIWidgetLSMlists.font,
					},
					InfoFontSize = {
						order = 5,
						name = 'Info Font Size',
						desc = 'The font size that the Zone / Server uses.',
						type = 'range',
						min = 6, max = 22, step = 1,
					},
					InfoFontFlag = {
						order = 6,
						name = 'Info Font Outline',
						desc = 'The font flag that the Zone / Server uses.',
						type = 'select',
						values = {
							['NONE'] = 'None',
							['OUTLINE'] = 'OUTLINE',
							['MONOCHROME'] = 'MONOCHROME',
							['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
							['THICKOUTLINE'] = 'THICKOUTLINE',
						},
					},
					GameIconPack = {
						name = 'Game Icon Pack',
						desc = 'Different Game Icons.',
						order = 7,
						type = 'select',
						values = {
							['Default'] = 'Default',
							['BlizzardChat'] = 'Blizzard Chat',
							['Flat'] = 'Flat Style',
							['Gloss'] = 'Glossy',
							['Launcher'] = 'Launcher',
						},
					},
					StatusIconPack = {
						name = 'Status Icon Pack',
						desc = 'Different Status Icons.',
						order = 8,
						type = 'select',
						values = {
							['Default'] = 'Default',
							['Square'] = 'Square',
							['D3'] = 'Diablo 3',
						},
					},
				},
			},
			GameIcons = {
				order = 3,
				type = 'group',
				name = 'Game Icon Preview',
				guiInline = true,
				args = {},
			},
			StatusIcons = {
				order = 5,
				type = 'group',
				name = 'Status Icon Preview',
				guiInline = true,
				args = {},
			},
		},
	}

	local GameIconsOptions = {
		Alliance = FACTION_ALLIANCE,
		Horde = FACTION_HORDE,
		Neutral = FACTION_STANDING_LABEL4,
		D3 = 'Diablo 3',
		WTCG = 'Hearthstone',
		S1 = 'Starcraft',
		S2 = 'Starcraft 2',
		App = 'App',
		BSAp = 'Mobile',
		Hero = 'Hero of the Storm',
		Pro = 'Overwatch',
		DST2 = 'Destiny 2',
	}

	local GameIconOrder = {
		Alliance = 1,
		Horde = 2,
		Neutral = 3,
		D3 = 4,
		WTCG = 5,
		S1 = 6,
		S2 = 7,
		App = 8,
		BSAp = 9,
		Hero = 10,
		Pro = 11,
		DST2 = 12,
	}

	for Key, Value in pairs(GameIconsOptions) do
		Options.args.GameIcons.args[Key] = {
			order = GameIconOrder[Key],
			type = 'execute',
			name = Value,
			func = function() return end,
			image = function(info) return GameIcons[EFL.db.GameIconPack][info[#info]], 32, 32 end,
		}
	end

	local StatusIconsOptions = {
		Online = FRIENDS_LIST_ONLINE,
		Offline = FRIENDS_LIST_OFFLINE,
		DND = DEFAULT_DND_MESSAGE,
		AFK = DEFAULT_AFK_MESSAGE,
	}

	local StatusIconsOrder = {
		Online = 1,
		Offline = 2,
		DND = 3,
		AFK = 4,
	}

	for Key, Value in pairs(StatusIconsOptions) do
		Options.args.StatusIcons.args[Key] = {
			order = StatusIconsOrder[Key],
			type = 'execute',
			name = Value,
			func = function() return end,
			image = function(info) return StatusIcons[EFL.db.StatusIconPack][info[#info]], 16, 16 end,
		}
	end

	PA.AceOptionsPanel.Options.args.EnhancedFriendsList = Options
end

local Defaults
function EFL:SetupProfile()
	if not Defaults then
		Defaults = {
			profile = {
				['NameFont'] = 'Arial Narrow',
				['NameFontSize'] = 12,
				['NameFontFlag'] = 'OUTLINE',
				['InfoFont'] = 'Arial Narrow',
				['InfoFontSize'] = 12,
				['InfoFontFlag'] = 'OUTLINE',
				['GameIconPack'] = 'Default',
				['StatusIconPack'] = 'Default',
			}
		}
		if self.ElvUI then
			Defaults.profile['NameFont'] = ElvUI[1].db.general.font
			Defaults.profile['InfoFont'] = ElvUI[1].db.general.font
		elseif self.Tukui then
			Defaults.profile['NameFont'] = 'Tukui Pixel'
			Defaults.profile['InfoFont'] = 'Tukui Pixel'
			Defaults.profile['NameFontFlag'] = 'MONOCHROMEOUTLINE'
			Defaults.profile['InfoFontFlag'] = 'MONOCHROMEOUTLINE'
		end
	end

	self.data = LibStub('AceDB-3.0'):New('EnhancedFriendsListDB', Defaults)
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function EFL:ClassColorCode(class)
	for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		if class == v then
			class = k
		end
	end

	if Locale ~= 'enUS' then
		for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
			if class == v then
				class = k
			end
		end
	end

	local color = class and RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }

	return format('|cFF%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

function EFL:BasicUpdateFriends(button)
	local nameText, nameColor, infoText, broadcastText, _, Cooperate
	if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
		local name, level, class, area, connected, status = GetFriendInfo(button.id)
		broadcastText = nil
		if connected then
			button.status:SetTexture(StatusIcons[self.db.StatusIconPack][(status == CHAT_FLAG_DND and 'DND' or status == CHAT_FLAG_AFK and 'AFK' or 'Online')])
			nameText = format('%s%s - (%s - %s %s)', EFL:ClassColorCode(class), name, class, LEVEL, level)
			nameColor = FRIENDS_WOW_NAME_COLOR
			Cooperate = true
		else
			button.status:SetTexture(StatusIcons[self.db.StatusIconPack].Offline)
			nameText = name
			nameColor = FRIENDS_GRAY_COLOR
		end
		infoText = area
	elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET and BNConnected() then
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, messageTime, canSoR = BNGetFriendInfo(button.id)
		local realmName, realmID, faction, race, class, zoneName, level, gameText
		broadcastText = messageText
		local characterName = toonName
		if presenceName then
			nameText = presenceName
			if isOnline and not characterName and battleTag then
				characterName = battleTag
			end
		else
			nameText = UNKNOWN
		end

		if characterName then
			_, _, _, realmName, realmID, faction, race, class, _, zoneName, level, gameText = BNGetGameAccountInfo(toonID)
			if client == BNET_CLIENT_WOW then
				if (level == nil or tonumber(level) == nil) then level = 0 end
				local classcolor = EFL:ClassColorCode(class)
				local diff = level ~= 0 and format('|cFF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or '|cFFFFFFFF'
				nameText = format('%s |cFFFFFFFF(|r%s%s|r - %s %s%s|r|cFFFFFFFF)|r', nameText, classcolor, characterName, LEVEL, diff, level)
				Cooperate = CanCooperateWithGameAccount(toonID)
			else
				nameText = format('|cFF%s%s|r', ClientColor[client] or 'FFFFFF', nameText)
			end
		end

		if isOnline then
			button.status:SetTexture(StatusIcons[self.db.StatusIconPack][(status == CHAT_FLAG_DND and 'DND' or status == CHAT_FLAG_AFK and 'AFK' or 'Online')])
			if client == BNET_CLIENT_WOW then
				if not zoneName or zoneName == '' then
					infoText = UNKNOWN
				else
					if realmName == EFL.MyRealm then
						infoText = zoneName
					else
						infoText = format('%s - %s', zoneName, realmName)
					end
				end
				button.gameIcon:SetTexture(GameIcons[self.db.GameIconPack][faction])
			else
				infoText = gameText
				button.gameIcon:SetTexture(GameIcons[self.db.GameIconPack][client])
			end
			nameColor = FRIENDS_BNET_NAME_COLOR
		else
			button.status:SetTexture(StatusIcons[self.db.StatusIconPack].Offline)
			nameColor = FRIENDS_GRAY_COLOR
			infoText = lastOnline == 0 and FRIENDS_LIST_OFFLINE or format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline))
		end
	end

	if button.summonButton:IsShown() then
		button.gameIcon:SetPoint('TOPRIGHT', -50, -2)
	else
		button.gameIcon:SetPoint('TOPRIGHT', -21, -2)
	end

	if nameText then
		button.name:SetText(nameText)
		button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
		button.info:SetText(infoText)
		button.info:SetTextColor(.49, .52, .54)
		if Cooperate then
			button.info:SetTextColor(1, .96, .45)
		end
		button.name:SetFont(PA.LSM:Fetch('font', self.db.NameFont), self.db.NameFontSize, self.db.NameFontFlag)
		button.info:SetFont(PA.LSM:Fetch('font', self.db.InfoFont), self.db.InfoFontSize, self.db.InfoFontFlag)
	end
end

function EFL:Initialize()
	self:SetupProfile()
	hooksecurefunc('FriendsFrame_UpdateFriendButton', function(button) EFL:BasicUpdateFriends(button) end)
end
