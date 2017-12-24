local PA = _G.ProjectAzilroka
local BB = PA:NewModule('BigButtons', 'AceEvent-3.0')

_G.BigButtons = BB

local GetItemInfo, GetSubZoneText, GetItemCount = GetItemInfo, GetSubZoneText, GetItemCount
local _G = _G
local select, tinsert = select, tinsert
local AS, ES

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

BB.Ranch['esMX'] = BB.Ranch['esES']
BB.Ranch = BB.Ranch[GetLocale()]

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

BB.Market['esMX'] = BB.Market['esES']
BB.Market = BB.Market[GetLocale()]

BB.Events = {'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'ZONE_CHANGED_NEW_AREA', 'ZONE_CHANGED_INDOORS', 'BAG_UPDATE'}

function BB:Update()
	local PrevButton, NumShown = nil, 0
	for _, Button in pairs(self.Bar.Buttons) do
		if Button:IsShown() then
			Button:ClearAllPoints()
			Button:SetPoint(unpack(PrevButton and {'LEFT', PrevButton, 'RIGHT', (ElvUI and ElvUI[1].PixelMode and 1 or 3), 0} or {'LEFT', self.Bar, 'LEFT', 0, 0}))
			PrevButton = Button
			NumShown = NumShown + 1
		end
	end
	if NumShown == 0 then NumShown = 1 end
	self.Bar:SetSize(NumShown * (50 + (ElvUI and ElvUI[1].PixelMode and 1 or 3)), 50)
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

function BB:CreateBigButton(ButtonName, ItemID)
	local Button = CreateFrame('Button', ButtonName..'Button', self.Bar, 'SecureActionButtonTemplate, ActionButtonTemplate')
	Button:Hide()
	Button:SetTemplate()
	Button:Size(50)
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

	Button:SetScript('OnEvent', function(self, event)
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

function BB:CreateSeedButton(ButtonName, ItemID, x, y)
	local Button = CreateFrame('Button', ButtonName, self.Bar.SeedsFrame, 'SecureActionButtonTemplate, ActionButtonTemplate')
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
		local Count = GetItemCount(ItemID)
		self:EnableMouse(Count > 0)
		self.Count:SetText(Count > 0 and Count or '')
		self.icon:SetDesaturated(Count == 0)
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
	local xOffset = 4 + (34*(x-1))

	Button:SetPoint(yTable[y].point, xOffset, yTable[y].offset)

	if AS then
		AS:SkinButton(Button)
		AS:CreateShadow(Button)
		if ES then
			ES:RegisterShadow(Button.Shadow)
		end
	end

	tinsert(self.Bar.SeedsFrame.Buttons, Button)
end

function BB:Initialize()
	ES, AS = _G.EnhancedShadows, _G.AddOnSkins and _G.AddOnSkins[1]

	local Bar = CreateFrame('Frame', 'BigButtonsBar', UIParent, "SecureHandlerStateTemplate")
	self.Bar = Bar
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

	self:CreateBigButton('RustyWateringCan', 79104)
	self:CreateBigButton('VintageBugSprayer', 80513)
	self:CreateBigButton('DentedShovel', 89880)
	self:CreateBigButton('MasterPlow', 89815)

	self:CreateSeedButton('GreenCabbageSeeds', 79102, 1, 1)
	self:CreateSeedButton('JuicycrunchCarrotSeeds', 80590, 2, 1)
	self:CreateSeedButton('ScallionSeeds', 80591, 3, 1)
	self:CreateSeedButton('MoguPumpkinSeeds', 80592, 4, 1)
	self:CreateSeedButton('RedBlossomLeekSeeds', 80593, 5, 1)
	self:CreateSeedButton('PinkTurnipSeeds', 80594, 6, 1)
	self:CreateSeedButton('WhiteTurnipSeeds', 80595, 7, 1)
	self:CreateSeedButton('SnakerootSeed', 85215, 8, 1)
	self:CreateSeedButton('EnigmaSeed', 85216, 9, 1)
	self:CreateSeedButton('MagebulbSeed', 85217, 10, 1)
	self:CreateSeedButton('OminousSeed', 85219, 1, 2)
	self:CreateSeedButton('StripedMelonSeeds', 89329, 2, 2)
	self:CreateSeedButton('AutumnBlossomSapling', 85267, 3, 2)
	self:CreateSeedButton('SpringBlossomSapling', 85268, 4, 2)
	self:CreateSeedButton('WinterBlossomSapling', 85269, 5, 2)
	self:CreateSeedButton('WindshearCactusSeed', 89197, 6, 2)
	self:CreateSeedButton('RaptorleafSeed', 89202, 7, 2)
	self:CreateSeedButton('SongbellSeed', 89233, 8, 2)
	self:CreateSeedButton('WitchberrySeeds', 89326, 9, 2)
	self:CreateSeedButton('JadeSquashSeeds', 89328, 10, 2)

	for _, event in pairs(BB.Events) do
		Bar:RegisterEvent(event)
		Bar.SeedsFrame:RegisterEvent(event)
	end

	Bar:SetScript('OnEvent', function(self, event)
		if not InCombatLockdown() then
			if BB:InFarmZone() then
				self:Show()
				UIFrameFadeIn(self, 0.5, self:GetAlpha(), 1)
			else
				self:Hide()
			end
		end
	end)

	Bar.SeedsFrame:SetScript('OnEvent', function(self, event)
		if not InCombatLockdown() then
			if BB:InSeedZone() then
				self:Show()
				UIFrameFadeIn(self, 0.5, self:GetAlpha(), 1)
			else
				self:Hide()
			end
		end
	end)

	if IsAddOnLoaded('Tukui') then
		_G.Tukui[1]['Movers']:RegisterFrame(self.Bar)
		_G.Tukui[1]['Movers']:RegisterFrame(self.Bar.SeedsFrame)
	elseif IsAddOnLoaded('ElvUI') then
		_G.ElvUI[1]:CreateMover(self.Bar, 'BigButtonsFarmBar', 'BigButtons Farm Bar Anchor', nil, nil, nil, 'ALL,GENERAL')
		_G.ElvUI[1]:CreateMover(self.Bar.SeedsFrame, 'BigButtonsSeedBar', 'BigButtons Seed Bar Anchor', nil, nil, nil, 'ALL,GENERAL')
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

BB:RegisterEvent('PLAYER_LOGIN', 'Initialize')
