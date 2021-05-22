local AddOnName = ...
local _G = _G
local LibStub = LibStub

local PA = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0', 'AceTimer-3.0')

_G.ProjectAzilroka = PA

local select = select
local pairs = pairs
local sort = sort
local tinsert = tinsert
local print = print
local format = format
local strsplit = strsplit

local GetAddOnMetadata = GetAddOnMetadata
local GetAddOnEnableState = GetAddOnEnableState
local UnitName = UnitName
local UnitClass = UnitClass
local GetRealmName = GetRealmName
local UIParent = UIParent
local BNGetFriendInfo = BNGetFriendInfo
local BNGetGameAccountInfo = BNGetGameAccountInfo

-- Ace Libraries
PA.AC = LibStub('AceConfig-3.0')
PA.GUI = LibStub('AceGUI-3.0')
PA.ACR = LibStub('AceConfigRegistry-3.0')
PA.ACD = LibStub('AceConfigDialog-3.0')
PA.ACL = LibStub('AceLocale-3.0'):GetLocale(AddOnName, false)
PA.ADB = LibStub('AceDB-3.0')

-- Extra Libraries
PA.LSM = LibStub('LibSharedMedia-3.0')
PA.LDB = LibStub('LibDataBroker-1.1')
PA.LCG = LibStub("LibCustomGlow-1.0")
PA.LAB = LibStub('LibActionButton-1.0')
PA.ACH = LibStub('LibAceConfigHelper')

-- External Libraries
PA.Masque = LibStub("Masque", true)
PA.LCD = LibStub("LibClassicDurations", true)

if PA.LCD then
	PA.LCD:Register(AddOnName) 	-- Register LibClassicDurations
end

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

PA.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
PA.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
PA.BCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- Pixel Perfect
PA.ScreenWidth, PA.ScreenHeight = GetPhysicalScreenSize()
PA.Multiple = 1
PA.Solid = PA.LSM:Fetch('background', 'Solid')

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
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(', ', '    ')

PA.AllPoints = { CENTER = 'CENTER', BOTTOM = 'BOTTOM', TOP = 'TOP', LEFT = 'LEFT', RIGHT = 'RIGHT', BOTTOMLEFT = 'BOTTOMLEFT', BOTTOMRIGHT = 'BOTTOMRIGHT', TOPLEFT = 'TOPLEFT', TOPRIGHT = 'TOPRIGHT' }
PA.GrowthDirection = {
	DOWN_RIGHT = format(PA.ACL["%s and then %s"], PA.ACL["Down"], PA.ACL["Right"]),
	DOWN_LEFT = format(PA.ACL["%s and then %s"], PA.ACL["Down"], PA.ACL["Left"]),
	UP_RIGHT = format(PA.ACL["%s and then %s"], PA.ACL["Up"], PA.ACL["Right"]),
	UP_LEFT = format(PA.ACL["%s and then %s"], PA.ACL["Up"], PA.ACL["Left"]),
	RIGHT_DOWN = format(PA.ACL["%s and then %s"], PA.ACL["Right"], PA.ACL["Down"]),
	RIGHT_UP = format(PA.ACL["%s and then %s"], PA.ACL["Right"], PA.ACL["Up"]),
	LEFT_DOWN = format(PA.ACL["%s and then %s"], PA.ACL["Left"], PA.ACL["Down"]),
	LEFT_UP = format(PA.ACL["%s and then %s"], PA.ACL["Left"], PA.ACL["Up"]),
}

PA.ElvUI = PA:IsAddOnEnabled('ElvUI', PA.MyName)
PA.SLE = PA:IsAddOnEnabled('ElvUI_SLE', PA.MyName)
PA.NUI = PA:IsAddOnEnabled('ElvUI_NihilistUI', PA.MyName)
PA.Tukui = PA:IsAddOnEnabled('Tukui', PA.MyName)
PA.AzilUI = PA:IsAddOnEnabled('AzilUI', PA.MyName)
PA.AddOnSkins = PA:IsAddOnEnabled('AddOnSkins', PA.MyName)

-- Setup oUF for pbuf
local function GetoUF()
	local key = PA.ElvUI and "ElvUI" or PA.Tukui and "Tukui"
	if not key then return end
	return _G[_G.GetAddOnMetadata(key, 'X-oUF')]
end
PA.oUF = GetoUF()

PA.Classes = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do PA.Classes[v] = k end
for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do PA.Classes[v] = k end

function PA:ClassColorCode(class)
	local color = PA:GetClassColor(PA.Classes[class])
	return format('FF%02x%02x%02x', color.r * 255, color.g * 255, color.b * 255)
end

function PA:GetClassColor(class)
	return _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class] or _G.RAID_CLASS_COLORS[class or 'PRIEST']
end

local Color = PA:GetClassColor(PA.MyClass)
PA.ClassColor = { Color.r, Color.g, Color.b }

PA.ScanTooltip = CreateFrame('GameTooltip', 'PAScanTooltip', _G.UIParent, 'GameTooltipTemplate')
PA.ScanTooltip:SetOwner(_G.UIParent, "ANCHOR_NONE")

PA.PetBattleFrameHider = CreateFrame('Frame', 'PA_PetBattleFrameHider', UIParent, 'SecureHandlerStateTemplate')
PA.PetBattleFrameHider:SetAllPoints()
PA.PetBattleFrameHider:SetFrameStrata('LOW')
RegisterStateDriver(PA.PetBattleFrameHider, 'visibility', '[petbattle] hide; show')

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
	local color = '|cFF16C3F2%s|r'
	return (color):format(name)
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

function PA:RGBToHex(r, g, b, header, ending)
	r = r <= 1 and r >= 0 and r or 1
	g = g <= 1 and g >= 0 and g or 1
	b = b <= 1 and b >= 0 and b or 1
	return format('%s%02x%02x%02x%s', header or '|cff', r*255, g*255, b*255, ending or '')
end

function PA:HexToRGB(hex)
	local a, r, g, b = strmatch(hex, '^|?c?(%x%x)(%x%x)(%x%x)(%x?%x?)|?r?$')
	if not a then return 0, 0, 0, 0 end
	if b == '' then r, g, b, a = a, r, g, 'ff' end

	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)
end

function PA:ConflictAddOn(AddOns)
	for AddOn in pairs(AddOns) do
		if PA:IsAddOnEnabled(AddOn, PA.MyName) then
			return true
		end
	end
	return false
end

function PA:CountTable(T)
	local n = 0
	for _ in pairs(T) do n = n + 1 end
	return n
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

function PA:AddKeysToTable(current, tbl)
	if type(current) ~= 'table' then return end

	for key, value in pairs(tbl) do
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
		end
		frame:SetBackdropColor(.08, .08, .08, .8)
		frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
	end
end

function PA:CreateBackdrop(frame)
	if PA.AddOnSkins then
		_G.AddOnSkins[1]:CreateBackdrop(frame)
	else
		frame.Backdrop = CreateFrame('Frame', nil, frame)
		frame.Backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)
		PA:SetOutside(frame.Backdrop, frame)
		PA:SetTemplate(frame.Backdrop)
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
		for option, value in pairs(default) do
			current[option] = (type(value) == 'table' and PA:CopyTable(current[option], value)) or value
		end
	end

	return current
end

function PA:SetInside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset, yOffset, anchor = xOffset or 1, yOffset or 1, anchor or obj:GetParent()

	assert(anchor)

	if obj:GetPoint() then obj:ClearAllPoints() end
	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', xOffset, -yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -xOffset, yOffset)
end

function PA:SetOutside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset, yOffset, anchor = xOffset or 1, yOffset or 1, anchor or obj:GetParent()

	assert(anchor)

	if obj:GetPoint() then obj:ClearAllPoints() end
	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -xOffset, yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', xOffset, -yOffset)
end

PA.ClassicServerNameByID = {
	[4703] = 'Amnennar',
	[4715] = 'Anathema',
	[4716] = 'Arcanite Reaper',
	[4742] = 'Ashbringer',
	[4387] = 'Ashkandi',
	[4372] = 'Atiesh',
	[4669] = 'Arugal',
	[4441] = 'Auberdine',
	[4376] = 'Azuresong',
	[4728] = 'Benediction',
	[4398] = 'Bigglesworth',
	[4397] = 'Blaumeux',
	[4746] = 'Bloodfang',
	[4648] = 'Bloodsail Buccaneers',
	[4386] = 'Deviate Delight',
	[4751] = 'Dragonfang',
	[4756] = "Dragon's Call",
	[4755] = 'Dreadmist',
	[4731] = 'Earthfury',
	[4749] = 'Earthshaker',
	[4440] = 'Everlook',
	[4408] = 'Faerlina',
	[4396] = 'Fairbanks',
	[4739] = 'Felstriker',
	[4744] = 'Finkle',
	[4467] = 'Firemaw',
	[4706] = 'Flamelash',
	[4702] = 'Gandling',
	[4476] = 'Gehennas',
	[4465] = 'Golemagg',
	[4647] = 'Grobbulus',
	[4732] = 'Heartseeker',
	[4763] = 'Heartstriker',
	[4406] = 'Herod',
	[4678] = 'Hydraxian Waterlords',
	[4698] = 'Incendius',
	[4758] = 'Judgement',
	[4700] = 'Kirtonos',
	[4699] = 'Kromcrush',
	[4399] = 'Kurinnaxx',
	[4442] = 'Lakeshire',
	[4801] = 'Loatheb',
	[4463] = 'Lucifron',
	[4813] = 'Mandokir',
	[4384] = 'Mankrik',
	[4454] = 'Mirage Raceway',
	[4701] = 'Mograine',
	[4373] = 'Myzrael',
	[4456] = 'Nethergarde Keep',
	[4729] = 'Netherwind',
	[4741] = 'Noggenfogger',
	[4374] = 'Old Blanchy',
	[4385] = 'Pagle',
	[4466] = 'Patchwerk',
	[4453] = 'Pyrewood Village',
	[4695] = 'Rattlegore',
	[4455] = 'Razorfen',
	[4478] = 'Razorgore',
	[4667] = 'Remulos',
	[4475] = 'Shazzrah',
	[4410] = 'Skeram',
	[4743] = 'Skullflame',
	[4696] = 'Smolderweb',
	[4409] = 'Stalagg',
	[4705] = 'Stonespine',
	[4726] = 'Sulfuras',
	[4464] = 'Sulfuron',
	[4737] = "Sul'thraze",
	[4757] = 'Ten Storms',
	[4407] = 'Thalnos',
	[4714] = 'Thunderfury',
	[4745] = 'Transcendence',
	[4477] = 'Venoxis',
	[4388] = 'Westfall',
	[4395] = 'Whitemane',
	[4727] = 'Windseeker',
	[4670] = 'Yojamba',
	[4676] = 'Zandalar Tribe',
	[4452] = 'Хроми',
	[4704] = 'Змейталак',
	[4754] = 'Рок-Делар',
	[4766] = 'Вестник Рока',
	[4474] = 'Пламегор',
}

local accountInfo = { gameAccountInfo = {} }
function PA:GetBattleNetInfo(friendIndex)
	if PA.Retail then
		accountInfo = _G.C_BattleNet.GetFriendAccountInfo(friendIndex)

		if accountInfo and accountInfo.gameAccountInfo.wowProjectID == _G.WOW_PROJECT_CLASSIC then
			accountInfo.gameAccountInfo.realmDisplayName = PA.ClassicServerNameByID[accountInfo.gameAccountInfo.realmID] or accountInfo.gameAccountInfo.realmID
		end

		return accountInfo
	else
		local bnetIDAccount, accountName, battleTag, isBattleTag, _, bnetIDGameAccount, _, isOnline, lastOnline, isBnetAFK, isBnetDND, messageText, noteText, _, messageTime, _, isReferAFriend, canSummonFriend, isFavorite = BNGetFriendInfo(friendIndex)

		if not bnetIDGameAccount then return end

		local hasFocus, characterName, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText, broadcastText, broadcastTime, _, toonID, _, isGameAFK, isGameBusy, guid, wowProjectID, mobile  = BNGetGameAccountInfo(bnetIDGameAccount)

		accountInfo.bnetAccountID = bnetIDAccount
		accountInfo.accountName = accountName
		accountInfo.battleTag = battleTag
		accountInfo.isBattleTagFriend = isBattleTag
		accountInfo.isDND = isBnetDND
		accountInfo.isAFK = isBnetAFK
		accountInfo.isFriend = true
		accountInfo.isFavorite = isFavorite
		accountInfo.note = noteText
		accountInfo.rafLinkType = 0
		accountInfo.appearOffline = false
		accountInfo.customMessage = messageText
		accountInfo.lastOnlineTime = lastOnline
		accountInfo.customMessageTime = messageTime

		accountInfo.gameAccountInfo.clientProgram = client or "App"
		accountInfo.gameAccountInfo.richPresence = gameText ~= '' and gameText or PA.ACL["Mobile"]
		accountInfo.gameAccountInfo.gameAccountID = bnetIDGameAccount
		accountInfo.gameAccountInfo.isOnline = isOnline
		accountInfo.gameAccountInfo.isGameAFK = isGameAFK
		accountInfo.gameAccountInfo.isGameBusy = isGameBusy
		accountInfo.gameAccountInfo.isWowMobile = mobile
		accountInfo.gameAccountInfo.hasFocus = hasFocus
		accountInfo.gameAccountInfo.canSummon = canSummonFriend

		if wowProjectID == _G.WOW_PROJECT_MAINLINE then
			zoneName, realmName = strsplit("-", gameText)
		end

		if client == _G.BNET_CLIENT_WOW then
			accountInfo.gameAccountInfo.characterName = characterName
			accountInfo.gameAccountInfo.factionName = faction ~= '' and faction or nil
			accountInfo.gameAccountInfo.playerGuid = guid
			accountInfo.gameAccountInfo.wowProjectID = wowProjectID
			accountInfo.gameAccountInfo.realmID = realmID
			accountInfo.gameAccountInfo.realmDisplayName = realmName
			accountInfo.gameAccountInfo.realmName = realmName
			accountInfo.gameAccountInfo.areaName = zoneName
			accountInfo.gameAccountInfo.className = class
			accountInfo.gameAccountInfo.characterLevel = level
			accountInfo.gameAccountInfo.raceName = race
		else
			accountInfo.gameAccountInfo.characterName = nil
			accountInfo.gameAccountInfo.factionName = nil
			accountInfo.gameAccountInfo.playerGuid = nil
			accountInfo.gameAccountInfo.wowProjectID = nil
			accountInfo.gameAccountInfo.realmID = nil
			accountInfo.gameAccountInfo.realmDisplayName = nil
			accountInfo.gameAccountInfo.realmName = nil
			accountInfo.gameAccountInfo.areaName = nil
			accountInfo.gameAccountInfo.className = nil
			accountInfo.gameAccountInfo.characterLevel = nil
			accountInfo.gameAccountInfo.raceName = nil
		end

		return accountInfo
	end
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

StaticPopupDialogs["PROJECTAZILROKA_RL"] = {
	text = PA.ACL["This setting requires that you reload your User Interface."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
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

PA.Options = PA.ACH:Group(PA:Color(PA.Title), nil, 6)

function PA:GetOptions()
	if _G.ElvUI then
		PA.AceOptionsPanel.Options.args.ProjectAzilroka = PA.Options
	else
		PA.AceOptionsPanel.Options.args = PA:CopyTable(PA.Options.args, PA.AceOptionsPanel.Options.args)
	end
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
		if module.UpdateSettings then module:UpdateSettings() end
	end
end

function PA:CallModuleFunction(module, func)
	local pass, err = pcall(func, module)
	if not pass and PA.Debug then
		error(err)
	end
end

function PA:PLAYER_LOGIN()
	PA.Multiple = PA:GetUIScale()

	PA.AS = _G.AddOnSkins and _G.AddOnSkins[1]
	PA.EP = LibStub('LibElvUIPlugin-1.0', true)
	PA.AceOptionsPanel = PA.ElvUI and _G.ElvUI[1] or PA.EC

	PA.Options.childGroups = PA.EC and 'tab' or 'tree'

	for _, module in PA:IterateModules() do
		if module.BuildProfile then PA:CallModuleFunction(module, module.BuildProfile) end
	end

	PA:BuildProfile()

	if PA.EP then
		PA.EP:RegisterPlugin('ProjectAzilroka', PA.GetOptions)
	end

	PA:UpdateCooldownSettings('all')

	for _, module in PA:IterateModules() do
		if module.GetOptions then
			PA:CallModuleFunction(module, module.GetOptions)
		end
		if module.Initialize then
			PA:CallModuleFunction(module, module.Initialize)
		end
	end
end

PA:RegisterEvent('PLAYER_LOGIN')
