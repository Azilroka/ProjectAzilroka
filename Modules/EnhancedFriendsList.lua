local PA = _G.ProjectAzilroka
local EFL = PA:NewModule('EnhancedFriendsList', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
PA.EFL, _G.EnhancedFriendsList = EFL, EFL

EFL.Title = 'Enhanced Friends List'
EFL.Header = PA.ACL['|cFF16C3F2Enhanced|r |cFFFFFFFFFriends List|r']
EFL.Description = PA.ACL['Provides Friends List Customization']
EFL.Authors = 'Azilroka'
EFL.Credits = 'Marotheit    Merathilis'
EFL.isEnabled = false

local pairs = pairs
local format = format
local unpack = unpack
local time = time
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

local GetQuestDifficultyColor = GetQuestDifficultyColor
local WrapTextInColorCode = WrapTextInColorCode
local _G = _G

local MediaPath = 'Interface/AddOns/ProjectAzilroka/Media/EnhancedFriendsList/'
local ONE_MINUTE = 60;
local ONE_HOUR = 60 * ONE_MINUTE;
local ONE_DAY = 24 * ONE_HOUR;
local ONE_MONTH = 30 * ONE_DAY;
local ONE_YEAR = 12 * ONE_MONTH;

local isBNConnected = _G.BNConnected()
local LEVEL = LEVEL

--[[
/run for i,v in pairs(_G) do if type(v)=="string" and v:match("Honorable") then print(i,"=",v) end end
]]

EFL.Icons = {
	Game = {
		Alliance = {
			Name = _G.FACTION_ALLIANCE,
			Order = 1,
			Default = "Interface/FriendsFrame/Battlenet-WoWicon",
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-WoW',
			Flat = MediaPath..'GameIcons/Flat/Alliance',
			Gloss = MediaPath..'GameIcons/Gloss/Alliance',
			Launcher = MediaPath..'GameIcons/Launcher/Alliance',
		},
		Horde = {
			Name = _G.FACTION_HORDE,
			Order = 2,
			Default = 'Interface/FriendsFrame/Battlenet-WoWicon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-WoW',
			Flat = MediaPath..'GameIcons/Flat/Horde',
			Gloss = MediaPath..'GameIcons/Gloss/Horde',
			Launcher = MediaPath..'GameIcons/Launcher/Horde',
		},
		Neutral = {
			Name = _G.FACTION_STANDING_LABEL4,
			Order = 3,
			Default = 'Interface/FriendsFrame/Battlenet-WoWicon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-WoW',
			Flat = MediaPath..'GameIcons/Flat/WoW',
			Gloss = MediaPath..'GameIcons/Gloss/WoW',
			Launcher = MediaPath..'GameIcons/Launcher/WoW',
		},
		App = {
			Name = PA.ACL['App'],
			Order = 4,
			Color = '82C5FF',
			Default = 'Interface/FriendsFrame/Battlenet-Battleneticon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-Battlenet',
			Flat = MediaPath..'GameIcons/Flat/BattleNet',
			Gloss = MediaPath..'GameIcons/Gloss/BattleNet',
			Launcher = MediaPath..'GameIcons/Launcher/BattleNet',
			Animated = MediaPath..'GameIcons/Bnet',
		},
		BSAp = {
			Name = PA.ACL['Mobile'],
			Order = 5,
			Color = '82C5FF',
			Default = 'Interface/FriendsFrame/Battlenet-Battleneticon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-Battlenet',
			Flat = MediaPath..'GameIcons/Flat/BattleNet',
			Gloss = MediaPath..'GameIcons/Gloss/BattleNet',
			Launcher = MediaPath..'GameIcons/Launcher/BattleNet',
			Animated = MediaPath..'GameIcons/Bnet',
		},
		[_G.BNET_CLIENT_D3 or 'D3'] = {
			Name = PA.ACL['Diablo 3'],
			Color = 'C41F3B',
			Default = 'Interface/FriendsFrame/Battlenet-D3icon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-D3',
			Flat = MediaPath..'GameIcons/Flat/D3',
			Gloss = MediaPath..'GameIcons/Gloss/D3',
			Launcher = MediaPath..'GameIcons/Launcher/D3',
		},
		[_G.BNET_CLIENT_WTCG or 'WTCG'] = {
			Name = PA.ACL['Hearthstone'],
			Color = 'FFB100',
			Default = 'Interface/FriendsFrame/Battlenet-WTCGicon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-WTCG',
			Flat = MediaPath..'GameIcons/Flat/Hearthstone',
			Gloss = MediaPath..'GameIcons/Gloss/Hearthstone',
			Launcher = MediaPath..'GameIcons/Launcher/Hearthstone',
		},
		[_G.BNET_CLIENT_SC or 'S1'] = {
			Name = PA.ACL['Starcraft'],
			Color = 'C495DD',
			Default = 'Interface/FriendsFrame/Battlenet-Sc2icon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-SC',
			Flat = MediaPath..'GameIcons/Flat/SC',
			Gloss = MediaPath..'GameIcons/Gloss/SC',
			Launcher = MediaPath..'GameIcons/Launcher/SC',
		},
		[_G.BNET_CLIENT_SC2 or 'S2'] = {
			Name = PA.ACL['Starcraft 2'],
			Color = 'C495DD',
			Default = "Interface/ChatFrame/UI-ChatIcon-SC2",
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-SC2',
			Flat = MediaPath..'GameIcons/Flat/SC2',
			Gloss = MediaPath..'GameIcons/Gloss/SC2',
			Launcher = MediaPath..'GameIcons/Launcher/SC2',
		},
		[_G.BNET_CLIENT_HEROES or 'Hero'] = {
			Name = PA.ACL['Hero of the Storm'],
			Color = '00CCFF',
			Default = 'Interface/FriendsFrame/Battlenet-HotSicon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-HotS',
			Flat = MediaPath..'GameIcons/Flat/Heroes',
			Gloss = MediaPath..'GameIcons/Gloss/Heroes',
			Launcher = MediaPath..'GameIcons/Launcher/Heroes',
		},
		[_G.BNET_CLIENT_OVERWATCH or 'Pro'] = {
			Name = PA.ACL['Overwatch'],
			Color = 'FFFFFF',
			Default = 'Interface/FriendsFrame/Battlenet-Overwatchicon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-Overwatch',
			Flat = MediaPath..'GameIcons/Flat/Overwatch',
			Gloss = MediaPath..'GameIcons/Gloss/Overwatch',
			Launcher = MediaPath..'GameIcons/Launcher/Overwatch',
		},
		[_G.BNET_CLIENT_COD or 'VIPR'] = {
			Name = PA.ACL['Call of Duty 4'],
			Color = 'FFFFFF',
			Default = 'Interface/FriendsFrame/Battlenet-CallOfDutyBlackOps4icon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-CallOfDutyBlackOps4',
			Flat = MediaPath..'GameIcons/Launcher/COD4',
			Gloss = MediaPath..'GameIcons/Launcher/COD4',
			Launcher = MediaPath..'GameIcons/Launcher/COD4',
		},
		[_G.BNET_CLIENT_COD_MW or 'ODIN'] = {
			Name = PA.ACL['Call of Duty Modern Warfare'],
			Color = 'FFFFFF',
			Default = 'Interface/FriendsFrame/Battlenet-CallOfDutyMWicon',
			BlizzardChat = 'Interface/ChatFrame/UI-ChatIcon-CallOfDutyMWicon',
			Flat = MediaPath..'GameIcons/Launcher/CODMW',
			Gloss = MediaPath..'GameIcons/Launcher/CODMW',
			Launcher = MediaPath..'GameIcons/Launcher/CODMW',
		},
		[_G.BNET_CLIENT_WC3 or 'W3'] = {
			Name = PA.ACL['Warcraft 3 Reforged'],
			Color = 'FFFFFF',
			Default = "Interface/FriendsFrame/Battlenet-Warcraft3Reforged",
			BlizzardChat = 'Interface/FriendsFrame/Battlenet-Warcraft3Reforged',
			Flat = MediaPath..'GameIcons/Launcher/WC3R',
			Gloss = MediaPath..'GameIcons/Launcher/WC3R',
			Launcher = MediaPath..'GameIcons/Launcher/WC3R',
		},
	},
	Status = {
		Online = {
			Name = _G.FRIENDS_LIST_ONLINE,
			Order = 1,
			Default = _G.FRIENDS_TEXTURE_ONLINE,
			Square = MediaPath..'StatusIcons/Square/Online',
			D3 = MediaPath..'StatusIcons/D3/Online',
			Color = {.243, .57, 1},
		},
		Offline = {
			Name = _G.FRIENDS_LIST_OFFLINE,
			Order = 2,
			Default = _G.FRIENDS_TEXTURE_OFFLINE,
			Square = MediaPath..'StatusIcons/Square/Offline',
			D3 = MediaPath..'StatusIcons/D3/Offline',
			Color = {.486, .518, .541},
		},
		DND = {
			Name = _G.DEFAULT_DND_MESSAGE,
			Order = 3,
			Default = _G.FRIENDS_TEXTURE_DND,
			Square = MediaPath..'StatusIcons/Square/DND',
			D3 = MediaPath..'StatusIcons/D3/DND',
			Color = {1, 0, 0},
		},
		AFK = {
			Name = _G.DEFAULT_AFK_MESSAGE,
			Order = 4,
			Default = _G.FRIENDS_TEXTURE_AFK,
			Square = MediaPath..'StatusIcons/Square/AFK',
			D3 = MediaPath..'StatusIcons/D3/AFK',
			Color = {1, 1, 0},
		},
	}
}

function EFL:CreateTexture(button, type, layer)
	if button.efl and button.efl[type] then
		button.efl[type].Left:SetTexture(PA.LSM:Fetch('statusbar', self.db['Texture']))
		button.efl[type].Right:SetTexture(PA.LSM:Fetch('statusbar', self.db['Texture']))
		return
	end

	button.efl = button.efl or {}
	button.efl[type] = {}

	button.efl[type].Left = button:CreateTexture(nil, layer)
	button.efl[type].Left:SetWidth(button:GetWidth() / 2)
	button.efl[type].Left:SetHeight(32)
	button.efl[type].Left:SetPoint("LEFT", button, "CENTER")
	button.efl[type].Left:SetTexture('Interface/Buttons/WHITE8X8')

	button.efl[type].Right = button:CreateTexture(nil, layer)
	button.efl[type].Right:SetWidth(button:GetWidth() / 2)
	button.efl[type].Right:SetHeight(32)
	button.efl[type].Right:SetPoint("RIGHT", button, "CENTER")
	button.efl[type].Right:SetTexture('Interface/Buttons/WHITE8X8')
end

function EFL:UpdateFriends(button)
	local nameText, infoText
	local status = 'Offline'
	if button.buttonType == _G.FRIENDS_BUTTON_TYPE_WOW then
		local info = _G.C_FriendList.GetFriendInfoByIndex(button.id)
		if info.connected then
			local name, level, class = info.name, info.level, info.className
			local classcolor = PA:ClassColorCode(class)
			status = info.dnd and 'DND' or info.afk and 'AFK' or 'Online'
			if EFL.db.ShowLevel then
				if EFL.db.DiffLevel then
					local diff = level ~= 0 and format('FF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or 'FFFFFFFF'
					nameText = format('%s |cFFFFFFFF(|r%s - %s %s|cFFFFFFFF)|r', WrapTextInColorCode(name, classcolor), class, LEVEL, WrapTextInColorCode(level, diff))
				else
					nameText = format('%s |cFFFFFFFF(|r%s - %s %s|cFFFFFFFF)|r', WrapTextInColorCode(name, classcolor), class, LEVEL, WrapTextInColorCode(level, 'FFFFE519'))
				end
			else
				nameText = format('%s |cFFFFFFFF(|r%s|cFFFFFFFF)|r', WrapTextInColorCode(name, classcolor), class)
			end
			infoText = info.area

			button.gameIcon:Show()
			button.gameIcon:SetTexture('Interface/WorldStateFrame/Icons-Classes')
			button.gameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[PA:GetClassName(class)]))
		else
			nameText = info.name
		end
		button.status:SetTexture(EFL.Icons.Status[status][EFL.db.StatusIconPack])
	elseif button.buttonType == _G.FRIENDS_BUTTON_TYPE_BNET and isBNConnected then
		local info = PA:GetBattleNetInfo(button.id);
		if info then
			nameText = info.accountName
			infoText = info.gameAccountInfo.richPresence
			if info.gameAccountInfo.isOnline then
				local client = info.gameAccountInfo.clientProgram
				status = info.isDND and 'DND' or info.isAFK and 'AFK' or 'Online'

				if client == _G.BNET_CLIENT_WOW then
					local level = info.gameAccountInfo.characterLevel
					local characterName = info.gameAccountInfo.characterName
					local classcolor = PA:ClassColorCode(info.gameAccountInfo.className)
					if characterName then
						if EFL.db.ShowLevel then
							if EFL.db.DiffLevel then
								local diff = level ~= 0 and format('FF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or 'FFFFFFFF'
								nameText = format('%s (%s - %s %s)', nameText, WrapTextInColorCode(characterName, classcolor), LEVEL, WrapTextInColorCode(level, diff))
							else
								nameText = format('%s (%s - %s %s)', nameText, WrapTextInColorCode(characterName, classcolor), LEVEL, WrapTextInColorCode(level, 'FFFFE519'))
							end
						else
							nameText = format('%s (%s)', nameText, WrapTextInColorCode(characterName, classcolor))
						end
					end

					if info.gameAccountInfo.wowProjectID == _G.WOW_PROJECT_CLASSIC and info.gameAccountInfo.realmDisplayName ~= PA.MyRealm then
						infoText = format('%s - %s - %s', info.gameAccountInfo.areaName, info.gameAccountInfo.realmDisplayName, infoText)
					elseif info.gameAccountInfo.realmDisplayName == PA.MyRealm then
						infoText = info.gameAccountInfo.areaName
					end

					local faction = info.gameAccountInfo.factionName
					button.gameIcon:SetTexture(faction and EFL.Icons.Game[faction][EFL.db[faction]] or EFL.Icons.Game.Neutral.Launcher)
				else
					if not EFL.Icons.Game[client] then client = 'BSAp' end
					nameText = format('|cFF%s%s|r', EFL.Icons.Game[client].Color or 'FFFFFF', nameText)
					button.gameIcon:SetTexture(EFL.Icons.Game[client][EFL.db[client]])
				end

				button.gameIcon:SetTexCoord(0, 1, 0, 1)
				button.gameIcon:SetDrawLayer('ARTWORK')
				button.gameIcon:SetAlpha(1)
			else
				local lastOnline = info.lastOnlineTime
				infoText = (not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR) and _G.FRIENDS_LIST_OFFLINE or format(_G.BNET_LAST_ONLINE_TIME, _G.FriendsFrame_GetLastOnline(lastOnline))
			end
			button.status:SetTexture(EFL.Icons.Status[status][EFL.db.StatusIconPack])
		end
	end

	if button.summonButton:IsShown() then
		button.gameIcon:SetPoint('TOPRIGHT', -50, -2)
	else
		button.gameIcon:SetPoint('TOPRIGHT', -21, -2)
	end

	if not button.isUpdateHooked then
		button:HookScript("OnUpdate", function(_, elapsed)
			if button.gameIcon:GetTexture() == MediaPath..'GameIcons/Bnet' then
				_G.AnimateTexCoords(button.gameIcon, 512, 256, 64, 64, 25, elapsed, 0.02)
			end
		end)
		button.isUpdateHooked = true
	end

	if nameText then button.name:SetText(nameText) end
	if infoText then button.info:SetText(infoText) end

	local r, g, b = unpack(EFL.Icons.Status[status].Color)
	if EFL.db.ShowStatusBackground then
		EFL:CreateTexture(button, 'background', 'BACKGROUND')

		button.efl.background.Left:SetGradientAlpha("Horizontal", r, g, b, .15, r, g, b, 0)
		button.efl.background.Right:SetGradientAlpha("Horizontal", r, g, b, .0, r, g, b, .15)

		button.background:Hide()
	end

	if EFL.db.ShowStatusHighlight then
		EFL:CreateTexture(button, 'highlight', 'HIGHLIGHT')

		button.efl.highlight.Left:SetGradientAlpha("Horizontal", r, g, b, .25, r, g, b, 0)
		button.efl.highlight.Right:SetGradientAlpha("Horizontal", r, g, b, .0, r, g, b, .25)

		button.highlight:SetVertexColor(0, 0, 0, 0)
	end

	button.name:SetFont(PA.LSM:Fetch('font', EFL.db.NameFont), EFL.db.NameFontSize, EFL.db.NameFontFlag)
	button.info:SetFont(PA.LSM:Fetch('font', EFL.db.InfoFont), EFL.db.InfoFontSize, EFL.db.InfoFontFlag)

	if button.Favorite and button.Favorite:IsShown() then
		button.Favorite:ClearAllPoints()
		button.Favorite:SetPoint("TOPLEFT", button.name, "TOPLEFT", button.name:GetStringWidth(), 0);
	end
end

function EFL:GetOptions()
	local Options = {
		type = 'group',
		name = EFL.Title,
		desc = EFL.Description,
		get = function(info) return EFL.db[info[#info]] end,
		set = function(info, value) EFL.db[info[#info]] = value _G.FriendsFrame_Update() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = EFL.Header
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					EFL.db[info[#info]] = value
					if (not EFL.isEnabled) then
						EFL:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				args = {
					NameSettings = {
						type = 'group',
						order = 1,
						name = PA.ACL['Name Settings'],
						guiInline = true,
						args = {
							NameFont = {
								type = 'select', dialogControl = 'LSM30_Font',
								order = 1,
								name = PA.ACL['Name Font'],
								desc = PA.ACL['The font that the RealID / Character Name / Level uses.'],
								values = PA.LSM:HashTable('font'),
							},
							NameFontSize = {
								order = 2,
								name = PA.ACL['Name Font Size'],
								desc = PA.ACL['The font size that the RealID / Character Name / Level uses.'],
								type = 'range',
								min = 6, max = 22, step = 1,
							},
							NameFontFlag = {
								name = PA.ACL['Name Font Flag'],
								desc = PA.ACL['The font flag that the RealID / Character Name / Level uses.'],
								order = 3,
								type = 'select',
								values = PA.FontFlags,
							},
							ShowLevel = {
								type = 'toggle',
								order = 4,
								name = PA.ACL['Show Level'],
							},
							DiffLevel = {
								type = 'toggle',
								order = 5,
								name = PA.ACL['Level by Difficulty'],
								disabled = function() return (not EFL.db.ShowLevel) end,
							},
						},
					},
					InfoSettings = {
						type = 'group',
						order = 2,
						name = PA.ACL['Info Settings'],
						guiInline = true,
						args = {
							InfoFont = {
								type = 'select', dialogControl = 'LSM30_Font',
								order = 1,
								name = PA.ACL['Info Font'],
								desc = PA.ACL['The font that the Zone / Server uses.'],
								values = PA.LSM:HashTable('font'),
							},
							InfoFontSize = {
								order = 2,
								name = PA.ACL['Info Font Size'],
								desc = PA.ACL['The font size that the Zone / Server uses.'],
								type = 'range',
								min = 6, max = 22, step = 1,
							},
							InfoFontFlag = {
								order = 3,
								name = PA.ACL['Info Font Outline'],
								desc = PA.ACL['The font flag that the Zone / Server uses.'],
								type = 'select',
								values = PA.FontFlags,
							},
							StatusIconPack = {
								name = PA.ACL['Status Icon Pack'],
								desc = PA.ACL['Different Status Icons.'],
								order = 4,
								type = 'select',
								values = {
									['Default'] = 'Default',
									['Square'] = 'Square',
									['D3'] = 'Diablo 3',
								},
							},
							ShowStatusBackground = {
								type = 'toggle',
								order = 5,
								name = PA.ACL['Show Status Background'],
							},
							ShowStatusHighlight = {
								type = 'toggle',
								order = 6,
								name = PA.ACL['Show Status Highlight'],
							},
							Texture = {
								order = 7,
								type = 'select', dialogControl = 'LSM30_Statusbar',
								name = PA.ACL['Texture'],
								values = PA.LSM:HashTable('statusbar'),
							},
						},
					},
				},
			},
			GameIcons = {
				order = 3,
				type = 'group',
				name = PA.ACL['Game Icons'],
				guiInline = true,
				args = {},
			},
			GameIconsPreview = {
				order = 4,
				type = 'group',
				name = PA.ACL['Game Icon Preview'],
				guiInline = true,
				args = {},
			},
			StatusIcons = {
				order = 5,
				type = 'group',
				name = PA.ACL['Status Icon Preview'],
				guiInline = true,
				args = {},
			},
			AuthorHeader = {
				order = -4,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -3,
				type = 'description',
				name = EFL.Authors,
				fontSize = 'large',
			},
			CreditsHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Credits:'],
			},
			Credits = {
				order = -1,
				type = 'description',
				name = EFL.Credits,
				fontSize = 'large',
			},
		},
	}

	for Key, Value in pairs(EFL.Icons.Game) do
		Options.args.GameIcons.args[Key] = {
			name = Value.Name..PA.ACL[' Icon'],
			order = Value.Order,
			type = 'select',
			values = {
				Default = 'Default',
				BlizzardChat = 'Blizzard Chat',
				Flat = 'Flat Style',
				Gloss = 'Glossy',
				Launcher = 'Launcher',
			},
		}
		Options.args.GameIconsPreview.args[Key] = {
			order = Value.Order,
			type = 'execute',
			name = Value.Name,
			func = function() return end,
			image = function(info) return EFL.Icons.Game[info[#info]][EFL.db[Key]], 32, 32 end,
		}
	end

	Options.args.GameIcons.args.App.values.Animated = 'Animated'
	Options.args.GameIcons.args.BSAp.values.Animated = 'Animated'

	for Key, Value in pairs(EFL.Icons.Status) do
		Options.args.StatusIcons.args[Key] = {
			order = Value.Order,
			type = 'execute',
			name = Value.Name,
			func = function() return end,
			image = function(info) return EFL.Icons.Status[info[#info]][EFL.db.StatusIconPack], 16, 16 end,
		}
	end

	PA.Options.args.EnhancedFriendsList = Options
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
		DiffLevel = true,
		ShowStatusHighlight = true,
		ShowStatusBackground = false,
		Texture = 'Solid',
	}

	for GameIcon in pairs(EFL.Icons.Game) do
		PA.Defaults.profile.EnhancedFriendsList[GameIcon] = 'Launcher'
	end

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

function EFL:Initialize()
	EFL.db = PA.db.EnhancedFriendsList

	if EFL.db.Enable ~= true then
		return
	end

	EFL.isEnabled = true

	EFL:RegisterEvent("BN_CONNECTED", 'HandleBN')
	EFL:RegisterEvent("BN_DISCONNECTED", 'HandleBN')

	--if PA.db.FG then
	--	EFL:SecureHook(PA.FG, 'FriendGroups_UpdateFriendButton', function(self, button) EFL:UpdateFriends(button) end)
	--else
		EFL:SecureHook("FriendsFrame_UpdateFriendButton", 'UpdateFriends')
	--end
end
