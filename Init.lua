local AddOnName = ...
local _G = _G
local LibStub = LibStub

local PA = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0')

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
PA.ACL = LibStub('AceLocale-3.0'):GetLocale(AddOnName, false);
PA.ADB = LibStub('AceDB-3.0')

PA.LSM = LibStub('LibSharedMedia-3.0')
PA.LDB = LibStub('LibDataBroker-1.1')
PA.LAB = LibStub('LibActionButton-1.0')

-- WoW Data
PA.MyClass = select(2, UnitClass('player'))
PA.MyName = UnitName('player')
PA.MyRealm = GetRealmName()
PA.Noop = function() end
PA.TexCoords = {.08, .92, .08, .92}
PA.UIScale = UIParent:GetScale()

-- Pixel Perfect
PA.ScreenWidth, PA.ScreenHeight = GetPhysicalScreenSize()
PA.Multiple = 768 / PA.ScreenHeight / UIParent:GetScale()

local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- Project Data
function PA:IsAddOnEnabled(addon)
	return GetAddOnEnableState(PA.MyName, addon) == 2
end

PA.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
PA.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(", ", "    ")
local Color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[PA.MyClass] or RAID_CLASS_COLORS[PA.MyClass]
PA.ClassColor = { Color.r, Color.g, Color.b }

PA.ElvUI = PA:IsAddOnEnabled('ElvUI')
PA.SLE = PA:IsAddOnEnabled('ElvUI_SLE')
PA.NUI = PA:IsAddOnEnabled('ElvUI_NenaUI')
PA.Tukui = PA:IsAddOnEnabled('Tukui')
PA.AzilUI = PA:IsAddOnEnabled('AzilUI')

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
		if GetAddOnEnableState(PA.MyName, AddOn) > 0 then
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

function PA:Reload()
	if PA.ElvUI then
		ElvUI[1]:StaticPopup_Show("PRIVATE_RL")
	end
end

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
			get = function(info) return PA.db[info[#info]] end,
			set = function(info, value) PA.db[info[#info]] = value; PA:Reload() end,
			args = {
				BB = {
					order = 0,
					type = 'toggle',
					name = PA.ACL['BigButtons'],
				},
				BrokerLDB = {
					order = 1,
					type = 'toggle',
					name = 'BrokerLDB',
				},
				DO = {
					order = 2,
					type = 'toggle',
					name = PA.ACL['Dragon Overlay'],
				},
				EFL = {
					order = 3,
					type = 'toggle',
					name = PA.ACL['Enhanced Friends List'],
				},
				ES = {
					order = 4,
					type = 'toggle',
					name = PA.ACL['Enhanced Shadows'],
					disabled = function() return (PA.SLE or PA.NUI) end,
				},
				FG = {
					order = 4,
					type = 'toggle',
					name = 'Friend Groups',
				},
				LC = {
					order = 6,
					type = 'toggle',
					name = PA.ACL['Loot Confirm'],
				},
				MF = {
					order = 7,
					type = 'toggle',
					name = PA.ACL['MovableFrames'],
				},
				SMB = {
					order = 8,
					type = 'toggle',
					name = PA.ACL['Square Minimap Buttons / Bar'],
				},
				stAM = {
					order = 9,
					type = 'toggle',
					name = PA.ACL['stAddOnManager'],
				},
			},
		},
	},
}

function PA:GetOptions()
	PA.AceOptionsPanel.Options.args.ProjectAzilroka = PA.Options
end

function PA:UpdateProfile()
	local Defaults = {
		profile = {
			['BB'] = true,
			['BrokerLDB'] = true,
			['DO'] = true,
			['EFL'] = true,
			['ES'] = true,
			['FG'] = true,
			['LC'] = true,
			['MF'] = true,
			['SMB'] = true,
			['stAM'] = true,
		},
	}

	if (PA.SLE or PA.NUI) then
		Defaults.profile.ES = false
	end

	PA.data = PA.ADB:New('ProjectAzilrokaDB', Defaults)
	PA.db = PA.data.profile
end

function PA:ADDON_LOADED(event, addon)
	if addon == AddOnName then
		PA.EP = LibStub('LibElvUIPlugin-1.0', true)
		PA.AceOptionsPanel = PA.ElvUI and _G.ElvUI[1] or _G.Enhanced_Config
		PA:UpdateProfile()
		PA:UnregisterEvent(event)
	end
end

function PA:PLAYER_LOGIN()
	PA.Multiple = 768 / PA.ScreenHeight / UIParent:GetScale()

	if PA.EP then
		PA.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	end
	if not (PA.SLE or PA.NUI) and PA.db['ES'] then
		pcall(_G.EnhancedShadows.Initialize, self)
	end
	if PA.db['BB'] then
		_G.BigButtons:Initialize()
	end
	if PA.db['BrokerLDB'] then
		_G.BrokerLDB:Initialize()
	end
	if PA.db['DO'] then
		_G.DragonOverlay:Initialize()
	end
	if PA.db['FG'] then -- Has to be before EFL
	end
	if PA.db['EFL'] then
		_G.EnhancedFriendsList:Initialize()
	end
	if PA.db['LC'] then
		_G.LootConfirm:Initialize()
	end
	if PA.db['MF'] then
		_G.MovableFrames:Initialize()
	end
	if PA.db['SMB'] and not PA.SLE then
		_G.SquareMinimapButtons:Initialize()
	end
	if PA.db['stAM'] then
		_G.stAddonManager:Initialize()
	end
	if PA.Tukui and GetAddOnEnableState(PA.MyName, 'Tukui_Config') > 0 then
		PA:TukuiOptions()
	end
end

PA:RegisterEvent('ADDON_LOADED')
PA:RegisterEvent('PLAYER_LOGIN')