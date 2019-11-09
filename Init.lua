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
if _G.ElvUI then
	PA.TexCoords = {0, 1, 0, 1}
	local modifier = 0.04 * _G.ElvUI[1].db.general.cropIcon
	for i, v in ipairs(PA.TexCoords) do
		if i % 2 == 0 then
			PA.TexCoords[i] = v - modifier
		else
			PA.TexCoords[i] = v + modifier
		end
	end
end

PA.UIScale = UIParent:GetScale()
PA.MyFaction = UnitFactionGroup('player')

PA.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
PA.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

-- Pixel Perfect
PA.ScreenWidth, PA.ScreenHeight = GetPhysicalScreenSize()
PA.Multiple = 1
PA.Solid = PA.LSM:Fetch('background', 'Solid')

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

function PA:GetUIScale()
	local effectiveScale = _G.UIParent:GetEffectiveScale()
	local magic = effectiveScale

	local scale = max(.64, min(1.15, magic))

	if strlen(scale) > 6 then
		scale = tonumber(strsub(scale, 0, 6))
	end

	return magic/scale
end

function PA:ClassColorCode(class)
	local color = class and (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[PA.Classes[class]] or RAID_CLASS_COLORS[PA.Classes[class]]) or { r = 1, g = 1, b = 1 }

	return format('FF%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

function PA:GetClassName(class)
	return PA.Classes[class]
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

function PA:SetTemplate(frame)
	if PA.AddOnSkins then
		AddOnSkins[1]:SetTemplate(frame)
	elseif frame.SetTemplate then
		frame:SetTemplate('Transparent', true)
	else
		frame:SetBackdrop({ bgFile = PA.Solid, edgeFile = PA.Solid, tile = false, tileSize = 0, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
		frame:SetBackdropColor(.08, .08, .08, .8)
		frame:SetBackdropBorderColor(0, 0, 0)
	end
end

function PA:CreateShadow(frame)
	if PA.AddOnSkins then
		AddOnSkins[1]:CreateShadow(frame)
	elseif frame.CreateShadow then
		frame:CreateShadow()
	end
end

function PA:SetInside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or 1
	yOffset = yOffset or 1
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', xOffset, -yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -xOffset, yOffset)
end

function PA:SetOutside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or 1
	yOffset = yOffset or 1
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -xOffset, yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', xOffset, -yOffset)
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

PA.Defaults = { profile = {} }

PA.Options = {
	type = 'group',
	name = PA:Color(PA.Title),
	order = 6,
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
			get = function(info) return (PA.db[info[#info]] and PA.db[info[#info]]['Enable']) end,
			set = function(info, value) PA.db[info[#info]]['Enable'] = value StaticPopup_Show("PROJECTAZILROKA") end,
			args = {},
		},
	},
}

function PA:GetOptions()
	PA.AceOptionsPanel.Options.args.ProjectAzilroka = PA.Options
end

function PA:BuildProfile()
	PA.data = PA.ADB:New('ProjectAzilrokaDB', PA.Defaults, true)

	PA.data.RegisterCallback(PA, 'OnProfileChanged', 'SetupProfile')
	PA.data.RegisterCallback(PA, 'OnProfileCopied', 'SetupProfile')

	PA.Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(PA.data)
	PA.Options.args.profiles.order = -2

	PA.db = PA.data.profile
end

function PA:SetupProfile()
	PA.db = PA.data.profile

	for _, module in PA:IterateModules() do
		if module.UpdateSettings then
			module:UpdateSettings()
		end
	end
end

function PA:ADDON_LOADED(event, addon)
	if addon == AddOnName then
		PA.EP = LibStub('LibElvUIPlugin-1.0', true)
		PA.AceOptionsPanel = PA.ElvUI and _G.ElvUI[1] or PA.EC
		PA:UnregisterEvent(event)
	end
end

function PA:PLAYER_LOGIN()
	PA.Multiple = PA:GetUIScale()

	PA.AS = AddOnSkins and unpack(AddOnSkins)

	for _, module in PA:IterateModules() do
		if module.BuildProfile then
			module:BuildProfile()
		end
	end

	PA:BuildProfile()

	if PA.Tukui and PA:IsAddOnEnabled('Tukui_Config', PA.MyName) then
		PA:TukuiOptions()
	end

	if PA.EP then
		PA.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	end

	for _, module in PA:IterateModules() do
		if module.Initialize then
			module:Initialize()
		end
	end
end

PA:RegisterEvent('ADDON_LOADED')
PA:RegisterEvent('PLAYER_LOGIN')
