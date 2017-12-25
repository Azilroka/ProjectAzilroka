local AddOnName = ...
local _G = _G
local LibStub = LibStub

local PA = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0')

_G.ProjectAzilroka = PA

local GetAddOnMetadata = GetAddOnMetadata
local GetAddOnEnableState = GetAddOnEnableState
local select, pairs, sort, tinsert = select, pairs, sort, tinsert
local UnitName, UnitClass, GetRealmName = UnitName, UnitClass, GetRealmName
local UIParent = UIParent

-- Libraries
PA.AC = LibStub('AceConfig-3.0')
PA.GUI = LibStub('AceGUI-3.0')
PA.ACR = LibStub('AceConfigRegistry-3.0')
PA.ACD = LibStub('AceConfigDialog-3.0')
PA.ACL = LibStub('AceLocale-3.0')
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
PA.Multiple = 768/PA.ScreenHeight

-- Project Data
PA.Locales = {}

PA.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
PA.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(", ", "    ")
PA.Color = '|cFF16C3F2'
PA.ModuleColor = '|cFFFF8000'

PA.ElvUI = GetAddOnEnableState(PA.MyName, 'ElvUI') > 0
PA.SLE = GetAddOnEnableState(PA.MyName, 'ElvUI_SLE') > 0
PA.NUI = GetAddOnEnableState(PA.MyName, 'ElvUI_NenaUI') > 0
PA.Tukui = GetAddOnEnableState(PA.MyName, 'Tukui') > 0

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

PA.Options = {
	type = 'group',
	name = PA.Color..PA.Title,
	order = 212,
	args = {
		header = {
			order = 1,
			type = 'header',
			name = 'Controls AddOns in this package',
		},
		general = {
			order = 2,
			type = 'group',
			name = 'AddOns',
			guiInline = true,
			get = function(info) return PA.db[info[#info]] end,
			set = function(info, value) PA.db[info[#info]] = value end,
			args = {
				DO = {
					order = 0,
					type = 'toggle',
					name = 'Dragon Overlay',
				},
				ES = {
					order = 1,
					type = 'toggle',
					name = 'Enhanced Shadows',
					disabled = function() return (PA.SLE or PA.NUI) end,
				},
				EFL = {
					order = 2,
					type = 'toggle',
					name = 'Enhanced Friends List',
				},
				LC = {
					order = 3,
					type = 'toggle',
					name = 'Loot Confirm',
				},
				MF = {
					order = 4,
					type = 'toggle',
					name = 'MovableFrames',
				},
				SMB = {
					order = 5,
					type = 'toggle',
					name = 'Square Minimap Buttons / Bar',
				},
				BB = {
					order = 6,
					type = 'toggle',
					name = 'BigButtons',
				},
				stAM = {
					order = 7,
					type = 'toggle',
					name = 'stAddOnManager',
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
			['DO'] = true,
			['ES'] = true,
			['EFL'] = true,
			['LC'] = true,
			['MF'] = true,
			['SMB'] = true,
			['BB'] = true,
			['stAM'] = true,
		},
	}

	if (PA.SLE or PA.NUI) then
		Defaults.profile.ES = false
	end

	PA.data = PA.ADB:New("ProjectAzilrokaDB", Defaults)
	PA.db = PA.data.profile
end

function PA:ADDON_LOADED(event, addon)
	if addon == AddOnName then
		PA.EP = LibStub('LibElvUIPlugin-1.0', true)
		PA.AceOptionsPanel = PA.ElvUI and ElvUI[1] or Enhanced_Config
		PA:UpdateProfile()
		PA:UnregisterEvent(event)
	end
end

function PA:PLAYER_LOGIN()
	if PA.EP then
		PA.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	end
	if not (PA.SLE or PA.NUI) and PA.db['ES'] then
		_G.EnhancedShadows:Initialize()
	end
	if PA.db['SMB'] and not PA.SLE then
		_G.SquareMinimapButtons:Initialize()
	end
	if PA.db['BB'] then
		_G.BigButtons:Initialize()
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
	if PA.db['DO'] then
		_G.DragonOverlay:Initialize()
	end
	if PA.db['stAM'] then
		_G.stAddonManager:Initialize()
	end
	if PA.Tukui and GetAddOnEnableState(PA.MyName, 'Tukui_Config') > 0 then
		PA:TukuiOptions()
	end
end

PA:RegisterEvent("ADDON_LOADED")
PA:RegisterEvent("PLAYER_LOGIN")