local EFL = unpack(select(2,...))

local pairs, tonumber = pairs, tonumber
local format = format
local Locale = GetLocale()
local GetFriendInfo, BNGetFriendInfo, BNGetGameAccountInfo, BNConnected, GetQuestDifficultyColor, CanCooperateWithGameAccount = GetFriendInfo, BNGetFriendInfo, BNGetGameAccountInfo, BNConnected, GetQuestDifficultyColor, CanCooperateWithGameAccount

local LSM = LibStub('LibSharedMedia-3.0', true)

local CLASS_NAMES = (Locale == 'enUS' and LOCALIZED_CLASS_NAMES_MALE or LOCALIZED_CLASS_NAMES_FEMALE) 

local ClientColor = {
	S1 = 'C495DD',
	S2 = 'C495DD',
	D3 = 'C41F3B',
	Pro = 'FFFFFF',
	WTCG = 'FFB100',
	Hero = '00CCFF',
	App = '82C5FF',
}

local Defaults = {
	["NameFont"] = IsAddOnLoaded("ElvUI") and ElvUI[1].db.general.font or IsAddOnLoaded("Tukui") and "Tukui Pixel" or "Arial Narrow",
	["NameFontSize"] = 12,
	["NameFontFlag"] = IsAddOnLoaded("Tukui") and "MONOCHROMEOUTLINE" or "OUTLINE",
	["InfoFont"] = IsAddOnLoaded("ElvUI") and ElvUI[1].db.general.font or IsAddOnLoaded("Tukui") and "Tukui Pixel" or "Arial Narrow",
	["InfoFontSize"] = 12,
	["InfoFontFlag"] = IsAddOnLoaded("Tukui") and "MONOCHROMEOUTLINE" or "OUTLINE",
	["GameIconPack"] = "Default",
	["StatusIconPack"] = "Default",
}

EnhancedFriendsListOptions = CopyTable(Defaults)

function EFL:GetOptions()
	local Options = {
		type = "group",
		name = EFL.Title,
		order = 10,
		args = {
			header = {
				order = 1,
				type = "header",
				name = "Friends List Customization",
			},
			general = {
				order = 2,
				type = "group",
				name = "General",
				guiInline = true,
				get = function(info) return EnhancedFriendsListOptions[info[#info]] end,
				set = function(info, value) EnhancedFriendsListOptions[info[#info]] = value FriendsFrame_UpdateFriends() end, 
				args = {
					NameFont = {
						type = "select", dialogControl = 'LSM30_Font',
						order = 1,
						name = "Name Font",
						desc = "The font that the RealID / Character Name / Level uses.",
						values = AceGUIWidgetLSMlists.font,	
					},
					NameFontSize = {
						order = 2,
						name = "Name Font Size",
						desc = "The font size that the RealID / Character Name / Level uses.",
						type = "range",
						min = 6, max = 22, step = 1,
					},
					NameFontFlag = {
						name = 'Name Font Flag',
						desc = "The font flag that the RealID / Character Name / Level uses.",
						order = 3,
						type = "select",
						values = {
							['NONE'] = 'None',
							['OUTLINE'] = 'OUTLINE',
							['MONOCHROME'] = 'MONOCHROME',
							['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
							['THICKOUTLINE'] = 'THICKOUTLINE',
						},
					},
					InfoFont = {
						type = "select", dialogControl = 'LSM30_Font',
						order = 4,
						name = "Info Font",
						desc = "The font that the Zone / Server uses.",
						values = AceGUIWidgetLSMlists.font,	
					},
					InfoFontSize = {
						order = 5,
						name = "Info Font Size",
						desc = "The font size that the Zone / Server uses.",
						type = "range",
						min = 6, max = 22, step = 1,
					},
					InfoFontFlag = {
						order = 6,
						name = "Info Font Outline",
						desc = "The font flag that the Zone / Server uses.",
						type = "select",
						values = {
							['NONE'] = 'None',
							['OUTLINE'] = 'OUTLINE',
							['MONOCHROME'] = 'MONOCHROME',
							['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
							['THICKOUTLINE'] = 'THICKOUTLINE',
						},
					},
					InfoFontFlag = {
						order = 6,
						name = "Info Font Outline",
						desc = "The font flag that the Zone / Server uses.",
						type = "select",
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
						desc = "Different Game Icons.",
						order = 7,
						type = "select",
						values = {
							['Default'] = 'Default',
							['BlizzardChat'] = 'Blizzard Chat',
							['Flat'] = 'Flat Style',
							['Gloss'] = 'Glossy',
						},
					},
					StatusIconPack = {
						name = 'Status Icon Pack',
						desc = "Different Status Icons.",
						order = 8,
						type = "select",
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
				type = "group",
				name = "Game Icon Preview",
				guiInline = true,
				args = {
					Alliance = {
						order = 1,
						type = "execute",
						name = 'Alliance',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					Horde = {
						order = 2,
						type = "execute",
						name = 'Horde',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					Neutral = {
						order = 3,
						type = "execute",
						name = 'Neutral',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					D3 = {
						order = 4,
						type = "execute",
						name = 'Diablo 3',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					WTCG = {
						order = 5,
						type = "execute",
						name = 'Hearthstone',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					S1 = {
						order = 6,
						type = "execute",
						name = 'Starcraft',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					S2 = {
						order = 6,
						type = "execute",
						name = 'Starcraft 2',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					App = {
						order = 7,
						type = "execute",
						name = 'App',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					Hero = {
						order = 8,
						type = "execute",
						name = 'Hero of the Storm',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					Pro = {
						order = 9,
						type = "execute",
						name = 'Overwatch',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
					DST2 = {
						order = 9,
						type = "execute",
						name = 'Destiny 2',
						func = function() return end,
						image = function(info) return EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][info[#info]], 24, 24 end,
					},
				},
			},
			StatusIcons = {
				order = 5,
				type = "group",
				name = "Status Icon Preview",
				guiInline = true,
				args = {
					Online = {
						order = 1,
						type = "execute",
						name = 'Online',
						func = function() return end,
						image = function(info) return EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]][info[#info]], 16, 16 end,
					},
					Offline = {
						order = 2,
						type = "execute",
						name = 'Offline',
						func = function() return end,
						image = function(info) return EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]][info[#info]], 16, 16 end,
					},
					DND = {
						order = 3,
						type = "execute",
						name = 'DND',
						func = function() return end,
						image = function(info) return EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]][info[#info]], 16, 16 end,
					},
					AFK = {
						order = 4,
						type = "execute",
						name = 'AFK',
						func = function() return end,
						image = function(info) return EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]][info[#info]], 16, 16 end,
					},
				},
			},
		},
	}
	if EP then
		local Ace3OptionsPanel = IsAddOnLoaded("ElvUI") and ElvUI[1] or Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.enhancedfriendslist = Options
	else
		local ACR, ACD = LibStub("AceConfigRegistry-3.0", true), LibStub("AceConfigDialog-3.0", true)
		if not (ACR or ACD) then return end
		ACR:RegisterOptionsTable("EnhancedFriendsList", Options)
		ACD:AddToBlizOptions("EnhancedFriendsList", "EnhancedFriendsList", nil, "general")
	end
end

function EFL:ClassColorCode(class)
	for k, v in pairs(CLASS_NAMES) do
		if class == v then
			class = k
		end
	end

	local color = class and RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }

	return format('|cFF%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

function EFL:BasicUpdateFriends(button)
	local nameText, nameColor, infoText, broadcastText, _
	if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
		local name, level, class, area, connected, status, note = GetFriendInfo(button.id)
		broadcastText = nil
		if connected then
			button.status:SetTexture(EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]][(status == CHAT_FLAG_DND and 'DND' or status == CHAT_FLAG_AFK and 'AFK' or 'Online')])
			nameText = format('%s%s - (%s - %s %s)', EFL:ClassColorCode(class), name, class, LEVEL, level)
			nameColor = FRIENDS_WOW_NAME_COLOR
			Cooperate = true
		else
			button.status:SetTexture(EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]].Offline)
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
		elseif givenName then
			nameText = givenName
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
			button.status:SetTexture(EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]][(status == CHAT_FLAG_DND and 'DND' or status == CHAT_FLAG_AFK and 'AFK' or 'Online')])
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
				button.gameIcon:SetTexture(EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][faction])
			else
				infoText = gameText
				button.gameIcon:SetTexture(EFL.GameIcons[EnhancedFriendsListOptions["GameIconPack"]][client])
			end
			nameColor = FRIENDS_BNET_NAME_COLOR
		else
			button.status:SetTexture(EFL.StatusIcons[EnhancedFriendsListOptions["StatusIconPack"]].Offline)
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
		if LSM then
			button.name:SetFont(LSM:Fetch('font', EnhancedFriendsListOptions.NameFont), EnhancedFriendsListOptions.NameFontSize, EnhancedFriendsListOptions.NameFontFlag)
			button.info:SetFont(LSM:Fetch('font', EnhancedFriendsListOptions.InfoFont), EnhancedFriendsListOptions.InfoFontSize, EnhancedFriendsListOptions.InfoFontFlag)
		end
	end
end

function EFL:Basic()
	hooksecurefunc('FriendsFrame_UpdateFriendButton', function(button) EFL:BasicUpdateFriends(button) end)
end