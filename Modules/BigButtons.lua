local PA = _G.ProjectAzilroka
local BB = PA:NewModule('BigButtons', 'AceEvent-3.0')
PA.BB, _G.BigButtons = BB, BB

BB.Title = '|cFF16C3F2Big|r|cFFFFFFFFButtons|r'
BB.Description = 'A farm tool for Sunsong Ranch.'
BB.Authors = 'Azilroka    ChaoticVoid'

local GetItemInfo, GetItemInfoInstant, GetSubZoneText, GetItemCount, InCombatLockdown = GetItemInfo, GetItemInfoInstant, GetSubZoneText, GetItemCount, InCombatLockdown
local NUM_BAG_SLOTS, GetContainerNumSlots, GetContainerItemID, PickupContainerItem, DeleteCursorItem = NUM_BAG_SLOTS, GetContainerNumSlots, GetContainerItemID, PickupContainerItem, DeleteCursorItem
local _G = _G
local select, tinsert, unpack, pairs = select, tinsert, unpack, pairs
local AS, ES
local Locale = GetLocale()
if Locale == 'esMX' then Locale = 'esES' end
if Locale == 'enGB' then Locale = 'enUS' end

BB.Ranch = {
	['enUS'] = 'Sunsong Ranch',
	['esES'] = 'Rancho Cantosol',
	['ptBR'] = 'Fazenda Sol Cantante',
	['frFR'] = 'Ferme Chant du Soleil',
	['deDE'] = 'Gehöft Sonnensang',
	['itIT'] = 'Tenuta Cantasole',
	['koKR'] = '태양노래 농장',
	['zhCN'] = '日歌农场',
	['zhTW'] = '日歌農莊',
	['ruRU'] = 'Ферма Солнечной Песни',
}

BB.Ranch = BB.Ranch[Locale]

BB.Market = {
	['enUS'] = 'The Halfhill Market',
	['esES'] = 'El Mercado del Alcor',
	['ptBR'] = 'Mercado da Meia Colina',
	['frFR'] = 'Marché de Micolline',
	['deDE'] = 'Der Halbhügelmarkt',
	['itIT'] = 'Mercato di Mezzocolle',
	['koKR'] = '언덕골 시장',
	['zhCN'] = '半山市集',
	['zhTW'] = '半丘市集',
	['ruRU'] = 'Рынок Полугорья',
}

BB.Market = BB.Market[Locale]

BB.Events = {'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'ZONE_CHANGED_NEW_AREA', 'ZONE_CHANGED_INDOORS', 'BAG_UPDATE'}

BB.Tools = { 79104, 80513, 89880, 89815 }
BB.Seeds = {
	[1] = { Seed = 79102, Bag = 80809 }, -- Green Cabbage
	[2] = { Seed = 89328, Bag = 89848 }, -- Jade Squash
	[3] = { Seed = 80590, Bag = 84782 }, -- Juicycrunch Carrot
	[4] = { Seed = 80592, Bag = 85153 }, -- Mogu Pumpkin
	[5] = { Seed = 80594, Bag = 85162 }, -- Pink Turnip
	[6] = { Seed = 80593, Bag = 85158 }, -- Red Blossom Leek
	[7] = { Seed = 80591, Bag = 84783 }, -- Scallion
	[8] = { Seed = 89329, Bag = 89849 }, -- Striped Melon
	[9] = { Seed = 80595, Bag = 85163 }, -- White Turnip
	[10] = { Seed = 89326, Bag = 89847 }, -- Witchberry
	[11] = { Seed = 85216, Bag = 95449 }, -- Enigma
	[12] = { Seed = 85217, Bag = 95451 }, -- Magebulb
	[13] = { Seed = 89202, Bag = 95457 }, -- Raptorleaf
	[14] = { Seed = 85215, Bag = 95447 }, -- Snakeroot
	[15] = { Seed = 89233, Bag = 95445 }, -- Songbell
	[16] = { Seed = 89197, Bag = 95454 }, -- Windshear Cactus
	[17] = { Seed = 85219 }, -- Ominous
	[18] = { Seed = 85267 }, -- Autumn Blossom
	[19] = { Seed = 85268 }, -- Spring Blossom
	[20] = { Seed = 85269 }, -- Winter Blossom
}

function BB:Update()
	local PrevButton, NumShown = nil, 0
	for _, Button in pairs(self.Bar.Buttons) do
		if Button:IsShown() then
			Button:ClearAllPoints()
			Button:SetPoint(unpack(PrevButton and {'LEFT', PrevButton, 'RIGHT', (PA.ElvUI and ElvUI[1].PixelMode and 1 or 3), 0} or {'LEFT', self.Bar, 'LEFT', 0, 0}))
			PrevButton = Button
			NumShown = NumShown + 1
		end
	end
	if NumShown == 0 then NumShown = 1 end
	self.Bar:SetSize(NumShown * (50 + (PA.ElvUI and ElvUI[1].PixelMode and 1 or 3)), 50)
end

function BB:InSeedZone()
	local SubZone = GetSubZoneText()
	if SubZone == BB.Ranch or SubZone == BB.Market then
		return true
	else
		return false
	end
end

function BB:InFarmZone()
	return GetSubZoneText() == BB.Ranch
end

function BB:CreateBigButton(ItemID)
	local Button = CreateFrame('Button', nil, self.Bar, 'SecureActionButtonTemplate, ActionButtonTemplate')
	Button:Hide()
	Button:SetTemplate()
	Button:SetSize(50, 50)
	Button:SetFrameLevel(1)
	Button:SetAttribute('type', 'item')
	Button:SetAttribute('item', GetItemInfo(ItemID))
	Button.ItemID = ItemID

	Button.icon:SetTexture(select(5, GetItemInfoInstant(ItemID)))
	Button.icon:SetTexCoord(unpack(PA.TexCoords))
	Button.icon:SetInside()
	Button.icon:SetDrawLayer('ARTWORK')

	Button:SetNormalTexture('')
	Button:SetPushedTexture('')
	Button:SetHighlightTexture('')

	if AS then
		AS:SkinButton(Button)
		AS:CreateShadow(Button)
		if ES then
			ES:RegisterShadow(Button.Shadow)
		end
	end

	for _, event in pairs(BB.Events) do
		Button:RegisterEvent(event)
	end

	Button:SetScript('OnShow', function(self)
		if self:GetAttribute('item') ~= GetItemInfo(ItemID) then
			self:SetAttribute('item', GetItemInfo(ItemID))
		end
	end)

	Button:SetScript('OnEvent', function(self)
		if not InCombatLockdown() then
			if BB:InFarmZone() and GetItemCount(ItemID) == 1 then
				self:Show()
				BB:Update()
			end
			self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		else
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
	end)

	tinsert(self.Bar.Buttons, Button)
end

local SeedX, SeedY = 0, 1
function BB:CreateSeedButton(ItemID)
	SeedX = SeedX + 1
	if SeedX > 10 then
		SeedX, SeedY = 1, 2
	end

	local Button = CreateFrame('Button', nil, self.Bar.SeedsFrame, 'SecureActionButtonTemplate, ActionButtonTemplate')
	Button:SetTemplate()
	Button:SetSize(30, 30)
	Button:SetAttribute('type', 'item')
	Button:SetAttribute('item', GetItemInfo(ItemID))
	Button.ItemID = ItemID

	Button.icon:SetTexture(select(5, GetItemInfoInstant(ItemID)))
	Button.icon:SetTexCoord(unpack(PA.TexCoords))
	Button.icon:SetInside()
	Button.icon:SetDrawLayer('ARTWORK')

	Button:SetNormalTexture('')
	Button:SetPushedTexture('')
	Button:SetHighlightTexture('')

	Button:HookScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 2, 4)
		GameTooltip:ClearLines()
		GameTooltip:SetItemByID(ItemID)
		GameTooltip:Show()
	end)

	Button:HookScript('OnLeave', GameTooltip_Hide)

	local function Update(self)
		if not InCombatLockdown() then
			if self:GetAttribute('item') ~= GetItemInfo(ItemID) then
				self:SetAttribute('item', GetItemInfo(ItemID))
			end
			local Count = GetItemCount(ItemID)
			self:EnableMouse(Count > 0)
			self.Count:SetText(Count > 0 and Count or '')
			self.icon:SetDesaturated(Count == 0)
			self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		else
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
	end

	for _, event in pairs(BB.Events) do
		Button:RegisterEvent(event)
	end

	Button:SetScript('OnEvent', Update)
	Button:SetScript('OnShow', Update)

	local yTable = {
		[1] = { point = 'TOPLEFT', offset = -4 },
		[2] = { point = 'BOTTOMLEFT', offset = 4 },
	}
	local xOffset = 4 + (34*(SeedX-1))

	Button:SetPoint(yTable[SeedY].point, xOffset, yTable[SeedY].offset)

	if AS then
		AS:SkinButton(Button)
		AS:CreateShadow(Button)
		if ES then
			ES:RegisterShadow(Button.Shadow)
		end
	end

	tinsert(self.Bar.SeedsFrame.Buttons, Button)
end

function BB:DropTools()
	if not BB:InSeedZone() and BB.db.DropTools then
		for _, ItemID in pairs(BB.Tools) do
			for container = 0, NUM_BAG_SLOTS do
				for slot = 1, GetContainerNumSlots(container) do
					if ItemID == GetContainerItemID(container, slot) then
						PickupContainerItem(container, slot)
						DeleteCursorItem()
					end
				end
			end
		end
	end
end

function BB:GetOptions()
	local Options = {
		type = 'group',
		name = BB.Title,
		desc = BB.Description,
		order = 219,
		get = function(info) return BB.db[info[#info]] end,
		set = function(info, value) BB.db[info[#info]] = value BB:Update() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(BB.Title),
			},
			DropTools = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Drop Farm Tools'],
			},
			ToolSize = {
				order = 2,
				type = 'range',
				name = PA.ACL['Farm Tool Size'],
				min = 16, max = 64, step = 1,
			},
			SeedSize = {
				order = 3,
				type = 'range',
				name = PA.ACL['Seed Size'],
				min = 16, max = 64, step = 1,
			},
			AuthorHeader = {
				order = 11,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = 12,
				type = 'description',
				name = BB.Authors,
				fontSize = 'large',
			},
		},
	}

	Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(PA.data)
	Options.args.profiles.order = -2

	PA.Options.args.BigButtons = Options
end

function BB:BuildProfile()
	self.data = PA.ADB:New('BigButtonsDB', {
		profile = {
			['DropTools'] = false,
			['ToolSize'] = 50,
			['SeedSize'] = 30,
		},
	}, true)
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function BB:SetupProfile()
	self.db = self.data.profile
end

function BB:Initialize()
	BB:BuildProfile()
	BB:GetOptions()

	ES, AS = _G.EnhancedShadows, _G.AddOnSkins and _G.AddOnSkins[1]

	local Bar = CreateFrame('Frame', 'BigButtonsBar', UIParent, "SecureHandlerStateTemplate")
	BB.Bar = Bar
	Bar:Hide()
	Bar:SetFrameStrata('MEDIUM')
	Bar:SetFrameLevel(0)
	Bar:SetSize(50, 50)
	Bar:SetPoint('TOP', UIParent, 'TOP', 0, -250)
	Bar.Buttons = {}

	Bar.SeedsFrame = CreateFrame('Frame', 'BigButtonsSeedBar', UIParent)
	Bar.SeedsFrame:SetFrameStrata('MEDIUM')
	Bar.SeedsFrame:SetFrameLevel(0)
	Bar.SeedsFrame:SetSize(344, 72)
	Bar.SeedsFrame:SetPoint('TOP', UIParent, 'TOP', 0, -300)
	Bar.SeedsFrame.Buttons = {}

	for _, ItemID in pairs(BB.Tools) do
		BB:CreateBigButton(ItemID)
	end

	for i = 1, 20 do
		BB:CreateSeedButton(BB.Seeds[i].Seed)
	end

	for _, event in pairs(BB.Events) do
		Bar:RegisterEvent(event)
		Bar.SeedsFrame:RegisterEvent(event)
	end

	Bar:SetScript('OnEvent', function(self)
		if not InCombatLockdown() then
			if BB:InFarmZone() then
				self:Show()
				UIFrameFadeIn(self, 0.5, 0, 1)
			else
				BB:DropTools()
				self:Hide()
			end
		end
	end)

	Bar.SeedsFrame:SetScript('OnEvent', function(self)
		if not InCombatLockdown() then
			if BB:InSeedZone() then
				self:Show()
				UIFrameFadeIn(self, 0.5, 0, 1)
			else
				self:Hide()
			end
		end
	end)

	if PA.Tukui then
		_G.Tukui[1]['Movers']:RegisterFrame(BB.Bar)
		_G.Tukui[1]['Movers']:RegisterFrame(BB.Bar.SeedsFrame)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(BB.Bar, 'BigButtonsFarmBar', 'BigButtons Farm Bar Anchor', nil, nil, nil, 'ALL,GENERAL')
		_G.ElvUI[1]:CreateMover(BB.Bar.SeedsFrame, 'BigButtonsSeedBar', 'BigButtons Seed Bar Anchor', nil, nil, nil, 'ALL,GENERAL')
	end

	if AS then
		AS:CreateShadow(Bar.SeedsFrame)
		AS:SetTemplate(Bar.SeedsFrame, 'Transparent')
		Bar.SeedsFrame.BorderColor = { Bar.SeedsFrame:GetBackdropBorderColor() }
		if ES then
			ES:RegisterShadow(Bar.SeedsFrame.Shadow)
		end
	end
end