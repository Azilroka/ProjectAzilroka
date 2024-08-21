local AddOnName, Engine = ...
local _G, _ = _G
local LibStub = _G.LibStub

local PA = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

_G.ProjectAzilroka = Engine

local min, max = min, max
local select = select
local next = next
local sort = sort
local gsub = gsub
local tinsert = tinsert
local print = print
local format = format
local strsplit, strmatch, strlen, strsub = strsplit, strmatch, strlen, strsub

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local GetAddOnEnableState = C_AddOns.GetAddOnEnableState
local UnitName = UnitName
local UnitClass = UnitClass
local GetRealmName = GetRealmName
local UIParent = UIParent
local CreateFrame = CreateFrame

PA.Libs = {
	-- Ace Libraries
	AC = LibStub('AceConfig-3.0'),
	GUI = LibStub('AceGUI-3.0'),
	ACR = LibStub('AceConfigRegistry-3.0'),
	ACD = LibStub('AceConfigDialog-3.0'),
	ACL = LibStub('AceLocale-3.0'):GetLocale(AddOnName, false),
	ADB = LibStub('AceDB-3.0'),

	-- Extra Libraries
	LSM = LibStub('LibSharedMedia-3.0'),
	LDB = LibStub('LibDataBroker-1.1'),
	LCG = LibStub("LibCustomGlow-1.0"),
	LAB = LibStub('LibActionButton-1.0'),
	ACH = LibStub('LibAceConfigHelper'),

	-- External Libraries
	Masque = LibStub("Masque", true),
	LCD = LibStub("LibClassicDurations", true),
}

local ACL, ACH = PA.Libs.ACL, PA.Libs.ACH

Engine[1] = PA
Engine[2] = ACL
Engine[3] = ACH


if PA.Libs.LCD then
	PA.Libs.LCD:Register(AddOnName) 	-- Register LibClassicDurations
end

-- WoW Data
_, PA.MyClass = UnitClass('player')
PA.MyName = UnitName('player')
_, PA.MyRace = UnitRace("player")
PA.MyRealm = GetRealmName()
PA.Locale = GetLocale()
PA.Noop = function() end

do
	local modifier, left, right, top, bottom

	function PA:TexCoords(pack)
		if not modifier then
			modifier = .04 * (ElvUI and _G.ElvUI[1].db.general.cropIcon or 2)
			left, right, top, bottom = modifier, 1 - modifier, modifier, 1 - modifier
		end
		if pack then return { left, right, top, bottom } end
		return left, right, top, bottom
	end
end

PA.UIScale = UIParent:GetScale()
PA.MyFaction = UnitFactionGroup('player')

PA.Retail = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
PA.Classic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
PA.TBC = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
PA.Wrath = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC

-- Pixel Perfect
PA.ScreenWidth, PA.ScreenHeight = GetPhysicalScreenSize()
PA.Multiple = 1
PA.Solid = PA.Libs.LSM:Fetch('background', 'Solid')

-- Project Data
function PA:IsAddOnEnabled(addon, character)
	if (type(character) == 'boolean' and character == true) then
		character = nil
	end

	return GetAddOnEnableState(addon, character) == 2
end

function PA:IsAddOnPartiallyEnabled(addon, character)
	if (type(character) == 'boolean' and character == true) then
		character = nil
	end

	return GetAddOnEnableState(addon, character) == 1
end

PA.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
PA.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(', ', '    ')

PA.AllPoints = { CENTER = 'CENTER', BOTTOM = 'BOTTOM', TOP = 'TOP', LEFT = 'LEFT', RIGHT = 'RIGHT', BOTTOMLEFT = 'BOTTOMLEFT', BOTTOMRIGHT = 'BOTTOMRIGHT', TOPLEFT = 'TOPLEFT', TOPRIGHT = 'TOPRIGHT' }
PA.GrowthDirection = {
	DOWN_RIGHT = format(ACL["%s and then %s"], ACL["Down"], ACL["Right"]),
	DOWN_LEFT = format(ACL["%s and then %s"], ACL["Down"], ACL["Left"]),
	UP_RIGHT = format(ACL["%s and then %s"], ACL["Up"], ACL["Right"]),
	UP_LEFT = format(ACL["%s and then %s"], ACL["Up"], ACL["Left"]),
	RIGHT_DOWN = format(ACL["%s and then %s"], ACL["Right"], ACL["Down"]),
	RIGHT_UP = format(ACL["%s and then %s"], ACL["Right"], ACL["Up"]),
	LEFT_DOWN = format(ACL["%s and then %s"], ACL["Left"], ACL["Down"]),
	LEFT_UP = format(ACL["%s and then %s"], ACL["Left"], ACL["Up"]),
}

PA.ElvUI = PA:IsAddOnEnabled('ElvUI', PA.MyName)
PA.SLE = PA:IsAddOnEnabled('ElvUI_SLE', PA.MyName)
PA.NUI = PA:IsAddOnEnabled('ElvUI_NihilistzscheUI', PA.MyName)
PA.Tukui = PA:IsAddOnEnabled('Tukui', PA.MyName)
PA.SpartanUI = PA:IsAddOnEnabled('SpartanUI', PA.MyName)
PA.AddOnSkins = PA:IsAddOnEnabled('AddOnSkins', PA.MyName)

-- Setup oUF for pbuf
local function GetoUF()
	local key = PA.ElvUI and "ElvUI_Libraries" or PA.Tukui and "Tukui" or PA.SpartanUI and "SpartanUI"
	if not key then return end
	return _G[GetAddOnMetadata(key, 'X-oUF')]
end
PA.oUF = GetoUF()

PA.Classes = {}
for k, v in next, _G.LOCALIZED_CLASS_NAMES_MALE do PA.Classes[v] = k end
for k, v in next, _G.LOCALIZED_CLASS_NAMES_FEMALE do PA.Classes[v] = k end

function PA:ClassColorCode(class)
	local color = PA:GetClassColor(PA.Classes[class])
	return format('FF%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

function PA:GetClassColor(class)
	return _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class] or _G.RAID_CLASS_COLORS[class or 'PRIEST']
end

local Color = PA:GetClassColor(PA.MyClass)
PA.ClassColor = { Color.r, Color.g, Color.b }

PA.ScanTooltip = CreateFrame('GameTooltip', 'PAScanTooltip', UIParent, 'GameTooltipTemplate')
PA.ScanTooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")

PA.PetBattleFrameHider = CreateFrame('Frame', 'PA_PetBattleFrameHider', UIParent, 'SecureHandlerStateTemplate')
PA.PetBattleFrameHider:SetAllPoints()
PA.PetBattleFrameHider:SetFrameStrata('LOW')
_G.RegisterStateDriver(PA.PetBattleFrameHider, 'visibility', '[petbattle] hide; show')

function PA:GetUIScale()
	local effectiveScale = _G.UIParent:GetEffectiveScale()
	local magic = effectiveScale

	local scale = max(.64, min(1.15, magic))

	if strlen(scale) > 6 then
		scale = tonumber(strsub(scale, 0, 6))
	end

	return magic/scale
end

function PA:GetClassName(class)
	return PA.Classes[class]
end

function PA:Color(name)
	return format('|cFF16C3F2%s|r', name)
end

function PA:Print(...)
	print(PA:Color(PA.Title..':'), ...)
end

function PA:ShortValue(value)
	if (value >= 1e6) then
		return gsub(format("%.1fm", value / 1e6), "%.?0+([km])$", "%1")
	elseif (value >= 1e3 or value <= -1e3) then
		return gsub(format("%.1fk", value / 1e3), "%.?0+([km])$", "%1")
	else
		return value
	end
end

local function clamp(v, min, max)
	min, max = min or 0, max or 1
	return v > max and max or v < min or v
end

function PA:RGBToHex(r, g, b, header, ending)
	return format('%s%02x%02x%02x%s', header or '|cff', clamp(r) * 255, clamp(g) * 255, clamp(b) * 255, ending or '')
end

function PA:HexToRGB(hex)
	local a, r, g, b = strmatch(hex, '^|?c?(%x%x)(%x%x)(%x%x)(%x?%x?)|?r?$')
	if not a then return 0, 0, 0, 0 end
	if b == '' then r, g, b, a = a, r, g, 'ff' end

	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)
end

function PA:ConflictAddOn(AddOns)
	for AddOn in next, AddOns do
		if PA:IsAddOnEnabled(AddOn, PA.MyName) then
			return true
		end
	end
	return false
end

function PA:CountTable(t)
	local n = 0
	for _ in next, t do n = n + 1 end
	return n
end

function PA:PairsByKeys(t, f)
	local a = {}
	for n in next, t do tinsert(a, n) end
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

function PA:AddKeysToTable(current, tbl)
	if type(current) ~= 'table' then return end

	for key, value in next, tbl do
		if current[key] == nil then
			current[key] = value
		end
	end
end

function PA:SetTemplate(frame)
	if PA.AddOnSkins then
		_G.AddOnSkins[1]:SetTemplate(frame)
	else
		if not frame.SetBackdrop then _G.Mixin(frame,  _G.BackdropTemplateMixin) end
		if frame.SetTemplate then
			frame:SetTemplate('Transparent', true)
		else
			frame:SetBackdrop({ bgFile = PA.Solid, edgeFile = PA.Solid, edgeSize = 1 })
			frame:SetBackdropColor(.08, .08, .08, .8)
			frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
		end
	end
end

function PA:CreateBackdrop(frame)
	if PA.AddOnSkins then
		_G.AddOnSkins[1]:CreateBackdrop(frame)
	else
		local parent = frame.IsObjectType and frame:IsObjectType('Texture') and frame:GetParent() or frame

		local backdrop = CreateFrame('Frame', nil, parent)
		if not backdrop.SetBackdrop then _G.Mixin(backdrop, _G.BackdropTemplateMixin) end
		if (parent:GetFrameLevel() - 1) >= 0 then
			backdrop:SetFrameLevel(parent:GetFrameLevel() - 1)
		else
			backdrop:SetFrameLevel(0)
		end

		PA:SetOutside(backdrop, frame)
		PA:SetTemplate(backdrop)

		frame.backdrop = backdrop
	end
end

function PA:CreateShadow(frame)
	if PA.AddOnSkins then
		_G.AddOnSkins[1]:CreateShadow(frame)
	elseif frame.CreateShadow then
		frame:CreateShadow()
		if not PA.SLE then
			PA.ES:RegisterFrameShadows(frame)
		end
	end
end

function PA:CopyTable(current, default)
	if type(current) ~= 'table' then
		current = {}
	end

	if type(default) == 'table' then
		for option, value in next, default do
			current[option] = (type(value) == 'table' and PA:CopyTable(current[option], value)) or value
		end
	end

	return current
end

function PA:SetInside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset, yOffset, anchor = xOffset or 1, yOffset or 1, anchor or obj:GetParent()

	if obj:GetPoint() then obj:ClearAllPoints() end
	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', xOffset, -yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -xOffset, yOffset)
end

function PA:SetOutside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset, yOffset, anchor = xOffset or 1, yOffset or 1, anchor or obj:GetParent()

	if obj:GetPoint() then obj:ClearAllPoints() end
	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -xOffset, yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', xOffset, -yOffset)
end

-- backwards compatibility
do
	-- Unit Aura
	local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex

	function PA:GetAuraData(unitToken, index, filter)
		local auraData = GetAuraDataByIndex(unitToken, index, filter)
		if PA.Classic and PA.Libs.LCD and not UnitIsUnit('player', unitToken) then
			local durationNew, expirationTimeNew
			if spellID then durationNew, expirationTimeNew = PA.Libs.LCD:GetAuraDurationByUnit(unit, auraData.spellId, caster, name) end
			if durationNew and durationNew > 0 then auraData.duration, auraData.expirationTime = durationNew, expirationTimeNew end
		end

		return auraData
	end

	-- GetMouseFocus
	local GetMouseFocus = GetMouseFocus
	local GetMouseFoci = GetMouseFoci
	function PA:GetMouseFocus()
		if GetMouseFoci then
			local frames = GetMouseFoci()
			return frames and frames[1]
		else
			return GetMouseFocus()
		end
	end

	-- EasyMenu
	local HandleMenuList
	HandleMenuList = function(root, menuList, submenu, depth)
		if submenu then root = submenu end

		for _, list in next, menuList do
			local previous
			if list.isTitle then
				root:CreateTitle(list.text)
			elseif list.func or list.hasArrow then
				local name = list.text or ('test'..depth)

				local func = (list.arg1 or list.arg2) and (function() list.func(nil, list.arg1, list.arg2) end) or list.func
				local checked = list.checked and (not list.notCheckable and function() return list.checked(list) end or PA.Noop)
				if checked then
					previous = root:CreateCheckbox(list.text or name, checked, func)
				else
					previous = root:CreateButton(list.text or name, func)
				end
			end

			if list.menuList then -- loop it
				HandleMenuList(root, list.menuList, list.hasArrow and previous, depth + 1)
			end
		end
	end

	function PA:EasyMenu(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
		if _G.EasyMenu then
			_G.EasyMenu(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
		else
			_G.MenuUtil.CreateContextMenu(menuFrame, function(_, root) HandleMenuList(root, menuList, nil, 1) end)
		end
	end

	-- Spell Book 
	local BOOKTYPE_SPELL = (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or BOOKTYPE_SPELL
	local BOOKTYPE_PET = (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or BOOKTYPE_PET
	local GetSpellBookItemName = C_SpellBook.GetSpellBookItemName or GetSpellBookItemName
	local HasPetSpells = C_SpellBook.HasPetSpells or HasPetSpells

	local GetSpellCooldown = C_Spell.GetSpellCooldown or function(info, bookType)
		local info = {}
		if bookType then
			info.startTime, info.duration, info.isEnabled, info.modRate = _G.GetSpellCooldown(info, bookType)
		else
			info.startTime, info.duration, info.isEnabled, info.modRate = _G.GetSpellCooldown(info)
		end
		return info
	end

	local GetSpellCharges = C_Spell.GetSpellCharges or function(index, bookType)
		local info = {}
		info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration, info.chargeModRate = GetSpellCharges(info, bookType)
		return info
	end

	local bookTypes = { SPELL = 1, FUTURESPELL = 2, PETACTION = 3, FLYOUT = 4 }
	local GetSpellBookItemInfo = C_SpellBook.GetSpellBookItemInfo or function(index, bookType)
		local info, _ = { isPassive = false, isOffSpec = false, skillLineIndex = index }
		info.itemType, info.actionID = GetSpellBookItemInfo(index, bookType)
		_, info.subName = GetSpellBookItemName(index, bookType)
		info.name, _, info.iconID, _, _, _, info.spellID = GetSpellInfo(index, bookType)
		info.itemType = bookTypes[info.itemType]
		return info
	end

	local GetSpellInfo = C_Spell.GetSpellInfo or function(index, bookType)
		local info, _ = {}
		info.name, _, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIcon = GetSpellInfo(index, bookType)
		return info
	end

	local GetNumSpellBookSkillLines = C_SpellBook.GetNumSpellBookSkillLines or GetNumSpellTabs
	local GetSpellBookSkillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo or function(index)
		local info = { shouldHide = false }
		info.name, info.iconID, info.itemIndexOffset, info.numSpellBookItems, info.isGuild, info.offspecID = GetSpellTabInfo(index)
		return info
	end

	-- Need for modules
	PA.GetSpellInfo = GetSpellInfo
	PA.GetSpellCooldown = GetSpellCooldown
	PA.GetSpellCharges = GetSpellCharges

	PA.SpellBook = { Complete = {}, Spells = {} }

	-- Simpy Magic
	local t = {}
	for _, name in next, { 'SPELL_RECAST_TIME_SEC', 'SPELL_RECAST_TIME_MIN', 'SPELL_RECAST_TIME_CHARGES_SEC', 'SPELL_RECAST_TIME_CHARGES_MIN' } do
		t[name] = _G[name]:gsub('%%%.%dg','[%%d%%.]-'):gsub('%.$','%%.'):gsub('^(.-)$','^%1$')
	end

	local function scanTooltip(spellID)
		PA.ScanTooltip:SetOwner(_G.UIParent, 'ANCHOR_NONE')
		PA.ScanTooltip:SetSpellByID(spellID)
		PA.ScanTooltip:Show()

		for i = 2, 4 do
			local str = _G['PAScanTooltipTextRight'..i]
			local text = str and str:GetText()
			if text then
				for _, matchtext in next, t do
					if strmatch(text, matchtext) then return true end
				end
			end
		end
	end

	local function ScanSpellBook(bookType, numSpells, offset)
		offset = offset or 0

		for index = offset + 1, offset + numSpells do
			local info = GetSpellBookItemInfo(index, bookType)

			if (info.itemType == 1 or info.itemType == 3) and info.spellID then
				local spellName = PA.Classic and info.subName and format('%s %s', info.name, info.subName or '')
				PA.SpellBook.Complete[info.spellID] = info
				if scanTooltip(info.spellID) then PA.SpellBook.Spells[info.spellID] = spellName or true end
			elseif info.itemType == 4 then
				local _, _, numSlots, isKnown = GetFlyoutInfo(info.actionID)
				if numSlots > 0 then
					for flyoutIndex = 1, numSlots do
						local flyoutSpellID, overrideId = GetFlyoutSlotInfo(info.actionID, flyoutIndex)
						local spellID = overrideId or flyoutSpellID

						PA.SpellBook.Complete[spellID] = GetSpellInfo(spellID)
						if scanTooltip(spellID) then PA.SpellBook.Spells[spellID] = true end
					end
				end
			end
		end

		PA.ScanTooltip:Hide()
	end

	local SpellOptions = {}
	function PA:GenerateSpellOptions(db)
		for SpellID, SpellName in next, db do
			local spellData = PA.SpellBook.Complete[SpellID]
			local tblID = tostring(SpellID)
	
			if spellData.name and not SpellOptions[tblID] then
				SpellOptions[tblID] = {
					type = 'toggle',
					image = spellData.iconID,
					imageCoords = PA:TexCoords(true),
					name = ' '..spellData.name,
					desc = 'Spell ID: '..SpellID,
				}
			end
		end
	
		return SpellOptions
	end
	
	function PA:ScanSpellBook(event)
		for tab = 1, GetNumSpellBookSkillLines() do
			local info = GetSpellBookSkillLineInfo(tab)
			ScanSpellBook(BOOKTYPE_SPELL, info.numSpellBookItems, info.itemIndexOffset)
		end

		local numPetSpells = HasPetSpells()
		if numPetSpells then
			ScanSpellBook(BOOKTYPE_PET, numPetSpells)
		end

		if event then
			-- Process Modules Event
			for _, module in PA:IterateModules() do
				if module.isEnabled and module.SPELLS_CHANGED then PA:ProtectedCall(module, module.SPELLS_CHANGED) end
			end
		end
	end
end

_G.StaticPopupDialogs["PROJECTAZILROKA"] = {
	text = ACL["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."],
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	OnAccept = _G.ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
}

_G.StaticPopupDialogs["PROJECTAZILROKA_RL"] = {
	text = ACL["This setting requires that you reload your User Interface."],
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	OnAccept = _G.ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
}

PA.Defaults = {
	profile = {
		Cooldown = {
			Enable = true,
			threshold = 3,
			hideBlizzard = false,
			useIndicatorColor = false,
			expiringColor = { r = 1, g = 0, b = 0 },
			secondsColor = { r = 1, g = 1, b = 0 },
			minutesColor = { r = 1, g = 1, b = 1 },
			hoursColor = { r = 0.4, g = 1, b = 1 },
			daysColor = { r = 0.4, g = 0.4, b = 1 },
			expireIndicator = { r = 1, g = 1, b = 1 },
			secondsIndicator = { r = 1, g = 1, b = 1 },
			minutesIndicator = { r = 1, g = 1, b = 1 },
			hoursIndicator = { r = 1, g = 1, b = 1 },
			daysIndicator = { r = 1, g = 1, b = 1 },
			hhmmColorIndicator = { r = 1, g = 1, b = 1 },
			mmssColorIndicator = { r = 1, g = 1, b = 1 },

			checkSeconds = false,
			hhmmColor = { r = 0.43, g = 0.43, b = 0.43 },
			mmssColor = { r = 0.56, g = 0.56, b = 0.56 },
			hhmmThreshold = -1,
			mmssThreshold = -1,

			fonts = {
				enable = false,
				font = 'PT Sans Narrow',
				fontOutline = 'OUTLINE',
				fontSize = 18,
			},
		}
	}
}

PA.Options = ACH:Group(PA:Color(PA.Title), nil, 6)

function PA:GetOptions()
	if _G.ElvUI then _G.ElvUI[1].Options.args.ProjectAzilroka = PA.Options end
end

function PA:BuildProfile()
	for _, module in PA:IterateModules() do
		if module.BuildProfile then PA:ProtectedCall(module, module.BuildProfile) end
	end

	PA.data = PA.Libs.ADB:New('ProjectAzilrokaDB', PA.Defaults, true)

	PA.data.RegisterCallback(PA, 'OnProfileChanged', 'SetupProfile')
	PA.data.RegisterCallback(PA, 'OnProfileCopied', 'SetupProfile')

	PA.Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(PA.data)
	PA.Options.args.profiles.order = -2

	PA:SetupProfile()
end

function PA:SetupProfile()
	PA.db = PA.data.profile

	for _, module in PA:IterateModules() do
		if module.UpdateSettings then module:UpdateSettings() end
	end
end

function PA:ProtectedCall(module, func)
	local pass, err = pcall(func, module)
	if not pass and PA.Debug then
		error(err)
	end
end

function PA:PLAYER_LOGIN()
	PA.Multiple = PA:GetUIScale()

	PA.AS = _G.AddOnSkins and _G.AddOnSkins[1]
	PA.Libs.EP = LibStub('LibElvUIPlugin-1.0', true)

	PA:ProtectedCall(PA, PA.ScanSpellBook)
	PA:BuildProfile()

	if PA.Libs.EP then
		PA.Libs.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	else
		PA.Libs.AC:RegisterOptionsTable('ProjectAzilroka', PA.Options)
		PA.Libs.ACD:AddToBlizOptions('ProjectAzilroka', 'ProjectAzilroka')
	end

	PA:UpdateCooldownSettings('all')

	for _, module in PA:IterateModules() do
		if module.GetOptions then PA:ProtectedCall(module, module.GetOptions) end
		if module.Initialize then PA:ProtectedCall(module, module.Initialize) end
	end

	if PA.Retail then
		PA:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'ScanSpellBook')
		PA:RegisterEvent('TRAIT_CONFIG_UPDATED', 'ScanSpellBook')
	else
		PA:RegisterEvent('SPELLS_CHANGED', 'ScanSpellBook')
	end
end

PA:RegisterEvent('PLAYER_LOGIN')
