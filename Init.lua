local AddOnName = ...
local _G = _G
local LibStub = LibStub

local PA = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0')

_G.ProjectAzilroka = PA

local GetAddOnMetadata = GetAddOnMetadata
local GetAddOnEnableState = GetAddOnEnableState
local select = select
local UnitName, UnitClass, GetRealmName = UnitName, UnitClass, GetRealmName
local UIParent = UIParent

-- Libraries
PA.AC = LibStub('AceConfig-3.0')
PA.GUI = LibStub('AceGUI-3.0')
PA.LSM = LibStub('LibSharedMedia-3.0')
PA.LDB = LibStub('LibDataBroker-1.1')
PA.LAB = LibStub('LibActionButton-1.0')
PA.ACR = LibStub('AceConfigRegistry-3.0')
PA.ACD = LibStub('AceConfigDialog-3.0')

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
PA.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
PA.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(", ", "    ")
PA.Color = '|cFF16C3F2'
PA.ModuleColor = '|cFFFFFFFF'

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

function PA:GetOptions()
	local Options = {
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
						order = 4,
						type = 'toggle',
						name = 'Square Minimap Buttons / Bar',
					},
				},
			},
		},
	}

	if PA.EP then
		PA.AceOptionsPanel.Options.args.ProjectAzilroka = Options
	end
end

local Defaults
function PA:UpdateProfile()
	if not Defaults then
		Defaults = {
			profile = {
				['DO'] = true,
				['ES'] = true,
				['EFL'] = true,
				['LC'] = true,
				['MF'] = true,
				['SMB'] = true,
			},
		}
		if (PA.SLE or PA.NUI) then
			Defaults.profile.ES = false
		end
	end

	self.data = LibStub("AceDB-3.0"):New("ProjectAzilrokaDB", Defaults)

	self.data.RegisterCallback(self, "OnProfileChanged", "UpdateProfile")
	self.data.RegisterCallback(self, "OnProfileCopied", "UpdateProfile")
	self.db = self.data.profile
end

function PA:ADDON_LOADED(event, addon)
	if addon == AddOnName then
		self.EP = LibStub('LibElvUIPlugin-1.0', true)
		self.AceOptionsPanel = PA.ElvUI and ElvUI[1] or Enhanced_Config
		self:UpdateProfile()
	end
	if addon == 'ElvUI_Config' then
		self:LoadConfig()
	end
end

function PA:LoadConfig()
	if not (self.SLE or self.NUI) and self.db['ES'] then
		_G.EnhancedShadows:GetOptions()
	end
	if self.db['EFL'] then
		_G.EnhancedFriendsList:GetOptions()
	end
	if self.db['LC'] then
		_G.LootConfirm:GetOptions()
	end
	if self.db['MF'] then
		_G.MovableFrames:GetOptions()
	end
	if self.db['SMB'] and not self.SLE then
		_G.SquareMinimapButtons:GetOptions()
	end
	if self.db['DO'] then
		_G.DragonOverlay:GetOptions()
	end
	self:UnregisterEvent("ADDON_LOADED")
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function PA:PLAYER_LOGIN()
	if self.EP then
		self.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	end
	if not (self.SLE or self.NUI) and self.db['ES'] then
		_G.EnhancedShadows:Initialize()
	end
	if self.db['EFL'] then
		_G.EnhancedFriendsList:Initialize()
	end
	if self.db['LC'] then
		_G.LootConfirm:Initialize()
	end
	if self.db['MF'] then
		_G.MovableFrames:Initialize()
	end
	if self.db['SMB'] and not self.SLE then
		_G.SquareMinimapButtons:Initialize()
	end
	if self.db['DO'] then
		_G.DragonOverlay:Initialize()
	end

	if not self.ElvUI then
		self:RegisterEvent('PLAYER_ENTERING_WORLD', 'LoadConfig')
	end
end

PA:RegisterEvent("ADDON_LOADED")
PA:RegisterEvent("PLAYER_LOGIN")