local AddOnName = ...
local _G = _G
local LibStub = LibStub

local PA = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0', 'AceTimer-3.0')

_G.ProjectAzilroka = PA

local GetAddOnMetadata = GetAddOnMetadata
local GetAddOnEnableState = GetAddOnEnableState
local select, pairs, sort, tinsert, print, format = select, pairs, sort, tinsert, print, format
local UnitName, UnitClass, GetRealmName = UnitName, UnitClass, GetRealmName
local UIParent = UIParent

-- Libraries
PA.AC = LibStub('AceConfig-3.0')
PA.GUI = LibStub('AceGUI-3.0')
PA.ACR = LibStub('AceConfigRegistry-3.0')
PA.ACD = LibStub('AceConfigDialog-3.0')
PA.ACL = LibStub('AceLocale-3.0'):GetLocale(AddOnName, false)
PA.ADB = LibStub('AceDB-3.0')

PA.LSM = LibStub('LibSharedMedia-3.0')
PA.LDB = LibStub('LibDataBroker-1.1')
PA.LAB = LibStub('LibActionButton-1.0')

-- WoW Data
PA.MyClass = select(2, UnitClass('player'))
PA.MyName = UnitName('player')
PA.MyRace = select(2, UnitRace("player"))
PA.MyRealm = GetRealmName()
PA.Locale = GetLocale()
PA.Noop = function() end
PA.TexCoords = {.08, .92, .08, .92}
PA.UIScale = UIParent:GetScale()
PA.MyFaction = UnitFactionGroup('player')

-- Pixel Perfect
PA.ScreenWidth, PA.ScreenHeight = GetPhysicalScreenSize()
PA.Multiple = 768 / PA.ScreenHeight / UIParent:GetScale()

local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- Project Data
function PA:IsAddOnEnabled(addon, character)
	if (type(character) == 'boolean' and character == true) then
		character = nil
	end
	return GetAddOnEnableState(character, addon) == 2
end

function PA:IsAddOnPartiallyEnabled(addon, character)
	if (type(character) == 'boolean' and character == true) then
		character = nil
	end
	return GetAddOnEnableState(character, addon) == 1
end

PA.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
PA.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(", ", "    ")
local Color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[PA.MyClass] or RAID_CLASS_COLORS[PA.MyClass]
PA.ClassColor = { Color.r, Color.g, Color.b }

PA.ElvUI = PA:IsAddOnEnabled('ElvUI', PA.MyName)
PA.SLE = PA:IsAddOnEnabled('ElvUI_SLE', PA.MyName)
PA.CUI = PA:IsAddOnEnabled('ElvUI_ChaoticUI', PA.MyName)
PA.Tukui = PA:IsAddOnEnabled('Tukui', PA.MyName)
PA.AzilUI = PA:IsAddOnEnabled('AzilUI', PA.MyName)
PA.AddOnSkins = PA:IsAddOnEnabled('AddOnSkins', PA.MyName)

PA.Classes = {}

for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do PA.Classes[v] = k end
for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do PA.Classes[v] = k end

function PA:ClassColorCode(class)
	local color = class and (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[PA.Classes[class]] or RAID_CLASS_COLORS[PA.Classes[class]]) or { r = 1, g = 1, b = 1 }

	return format('|cFF%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

function PA:Color(name)
	local color = '|cFF16C3F2%s|r'
	return (color):format(name)
end

function PA:Print(...)
	print(PA:Color(PA.Title..':'), ...)
end

function PA:ConflictAddOn(AddOns)
	for AddOn in pairs(AddOns) do
		if PA:IsAddOnEnabled(AddOn, PA.MyName) then
			return true
		end
	end
	return false
end

function PA:PairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do tinsert(a, n) end
	sort(a, f)
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then return nil
			else return a[i], t[a[i]]
		end
	end
	return iter
end

StaticPopupDialogs["PROJECTAZILROKA"] = {
	text = PA.ACL["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
}

PA.Options = {
	type = 'group',
	name = PA:Color(PA.Title),
	order = 212,
	args = {
		header = {
			order = 1,
			type = 'header',
			name = PA.ACL['Controls AddOns in this package'],
		},
		general = {
			order = 2,
			type = 'group',
			name = PA:Color(PA.ACL['AddOns']),
			guiInline = true,
			get = function(info) return PA.db[info[#info]]['Enable'] end,
			set = function(info, value) PA.db[info[#info]]['Enable'] = value StaticPopup_Show("PROJECTAZILROKA") end,
			args = {
				BigButtons = {
					order = 0,
					type = 'toggle',
					name = PA.ACL['BigButtons'],
				},
				BrokerLDB = {
					order = 1,
					type = 'toggle',
					name = 'BrokerLDB',
				},
				DragonOverlay = {
					order = 2,
					type = 'toggle',
					name = PA.ACL['Dragon Overlay'],
				},
				EnhancedFriendsList = {
					order = 3,
					type = 'toggle',
					name = PA.ACL['Enhanced Friends List'],
				},
				EnhancedShadows = {
					order = 4,
					type = 'toggle',
					name = PA.ACL['Enhanced Shadows'],
					disabled = function() return (PA.SLE or PA.CUI) end,
				},
				FriendGroups = {
					order = 5,
					type = 'toggle',
					name = 'Friend Groups',
				},
				FasterLoot = {
					order = 6,
					type = 'toggle',
					name = PA.ACL['Faster Loot'],
				},
				MovableFrames = {
					order = 7,
					type = 'toggle',
					name = PA.ACL['MovableFrames'],
				},
				SquareMinimapButtons = {
					order = 8,
					type = 'toggle',
					name = PA.ACL['Square Minimap Buttons / Bar'],
				},
				stAddonManager = {
					order = 9,
					type = 'toggle',
					name = PA.ACL['stAddOnManager'],
				},
				QuestSounds = {
					order = 9,
					type = 'toggle',
					name = 'Quest Sounds',
				},
				ReputationReward = {
					order = 9,
					type = 'toggle',
					name = 'Reputation Reward',
				},
			},
		},
	},
}

PA.Defaults = {
	profile = {
		['BigButtons'] = { ['Enable'] = false },
		['BrokerLDB'] = { ['Enable'] = false },
		['DragonOverlay'] = { ['Enable'] = true },
		['EnhancedFriendsList'] = { ['Enable'] = true },
		['EnhancedShadows'] = { ['Enable'] = true },
		['FriendGroups'] = { ['Enable'] = false },
		['FasterLoot'] = { ['Enable'] = false },
		['MovableFrames'] = { ['Enable'] = true },
		['SquareMinimapButtons'] = { ['Enable'] = true },
		['stAddonManager'] = { ['Enable'] = true },
		['QuestSounds'] = { ['Enable'] = false },
		['ReputationReward'] = { ['Enable'] = true },
	},
}

function PA:GetOptions()
	PA.AceOptionsPanel.Options.args.ProjectAzilroka = PA.Options
end

function PA:BuildProfile()
	if (PA.SLE or PA.CUI) then
		PA.Defaults.profile['EnhancedShadows']['Enable'] = false
	end

	PA.data = PA.ADB:New('ProjectAzilrokaDB', PA.Defaults)

	PA.data.RegisterCallback(PA, 'OnProfileChanged', 'SetupProfile')
	PA.data.RegisterCallback(PA, 'OnProfileCopied', 'SetupProfile')

	PA.Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(PA.data)
	PA.Options.args.profiles.order = -2

	PA.db = PA.data.profile
end

function PA:SetupProfile()
	PA.db = PA.data.profile
end

function PA:ADDON_LOADED(event, addon)
	if addon == AddOnName then
		PA.EP = LibStub('LibElvUIPlugin-1.0', true)
		PA.AceOptionsPanel = PA.ElvUI and _G.ElvUI[1] or PA.EC
		PA:BuildProfile()
		PA:UnregisterEvent(event)

		if PA.db and not PA.db.DBConverted then
			PA:DBConversion()
		end
	end
end

function PA:PLAYER_LOGIN()
	PA.Multiple = 768 / PA.ScreenHeight / UIParent:GetScale()
	PA.AS = AddOnSkins and unpack(AddOnSkins)

	local InitializeModules = {}

	if PA.EP then
		PA.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	end
	if not (PA.SLE or PA.CUI) and PA.db['EnhancedShadows']['Enable'] then
		tinsert(InitializeModules, 'ES')
	end
	if PA.db['BigButtons']['Enable'] then
		tinsert(InitializeModules, 'BB')
	end
	if PA.db['BrokerLDB']['Enable'] then
		tinsert(InitializeModules, 'BrokerLDB')
	end
	if PA.db['DragonOverlay']['Enable'] then
		tinsert(InitializeModules, 'DO')
	end
	if PA.db['FriendGroups']['Enable'] then -- Has to be before EFL
		--tinsert(InitializeModules, 'FG')
	end
	if PA.db['EnhancedFriendsList']['Enable'] then
		tinsert(InitializeModules, 'EFL')
	end
	if PA.db['FasterLoot']['Enable'] then
		tinsert(InitializeModules, 'FL')
	end
	if PA.db['MovableFrames']['Enable'] then
		tinsert(InitializeModules, 'MF')
	end
	if PA.db['SquareMinimapButtons']['Enable'] then
		tinsert(InitializeModules, 'SMB')
	end
	if PA.db['stAddonManager']['Enable'] then
		tinsert(InitializeModules, 'stAM')
	end
	if PA.db['QuestSounds']['Enable'] then
		tinsert(InitializeModules, 'QS')
	end
	if PA.db['ReputationReward']['Enable'] then
		tinsert(InitializeModules, 'RR')
	end

	for _, Module in pairs(InitializeModules) do
		if PA[Module] then
			pcall(PA[Module].Initialize)
		end
	end

	if PA.Tukui and PA:IsAddOnEnabled('Tukui_Config', PA.MyName) then
		PA:TukuiOptions()
	end
end

function PA:DBConversion()
	for _, DBEntry in pairs({'SquareMinimapButtons', 'MovableFrames', 'EnhancedFriendsList', 'EnhancedShadows', 'DragonOverlay', 'stAddonManager', 'BigButtons', 'FriendGroups', 'QuestSounds'}) do
		local DB = _G[DBEntry..'DB']
		if DB then
			local profileKeys = DB.profileKeys
			if profileKeys then
				local profile = DB.profileKeys[format("%s - %s", PA.MyName, PA.MyRealm)]
				local table = DB.profiles[profile]
				if table then
					for Key, Value in pairs(table) do
						PA.db[DBEntry][Key] = Value
					end
				end
			end
		end
	end

	PA.db.DBConverted = true
end

PA:RegisterEvent('ADDON_LOADED')
PA:RegisterEvent('PLAYER_LOGIN')