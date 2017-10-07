local AddOnName, Engine = ...
local ES, AS, BorderColor
local GetSpellInfo, GetItemInfo, select, GetSubZoneText, GetItemCount = GetSpellInfo, GetItemInfo, select, GetSubZoneText, GetItemCount

local SubZoneName = {
	['enUS'] = 'Sunsong Ranch',
	['esES'] = 'Rancho Cantosol',
	['esMX'] = 'Rancho Cantosol',
	['ptBR'] = 'Fazenda Sol Cantante',
	['frFR'] = 'Ferme Chant du Soleil',
	['deDE'] = 'Gehöft Sonnensang',
	['itIT'] = 'Tenuta Cantasole',
	['koKR'] = '태양노래 농장',
	['zhCN'] = '日歌农场',
	['zhTW'] = '日歌農莊',
	['ruRU'] = 'Ферма Солнечной Песни',
}

local RanchName = SubZoneName[GetLocale()]

local numBigButtons = 0
local buttons = {}

local BigButtons = CreateFrame('Frame', 'BigButtons', UIParent)
BigButtons:SetMovable(true)
BigButtons:SetFrameStrata('MEDIUM')
BigButtons:SetFrameLevel(0)
BigButtons:SetSize(50, 50)
BigButtons:Point('TOP', UIParent, 'TOP', 0, -250)
function BigButtons:Update()
	self:SetSize(numBigButtons * (50 + (ElvUI and ElvUI[1].PixelMode and 1 or 3)), 50)
end

BigButtons.SeedsFrame = CreateFrame('Frame', 'SeedsFrame', UIParent)
BigButtons.SeedsFrame:SetMovable(true)
BigButtons.SeedsFrame:SetFrameStrata('MEDIUM')
BigButtons.SeedsFrame:SetFrameLevel(0)
BigButtons.SeedsFrame:SetSize(344, 72)
BigButtons.SeedsFrame:Point('TOP', UIParent, 'TOP', 0, -300)

function BigButtons:CreateBigButton(name, id, type, check, ...)
	local func = type == 'spell' and _G['GetSpellInfo'] or _G['GetItemInfo']
	local index = type == 'spell' and 3 or 10
	local Button = CreateFrame('Button', name..'Button', self, 'SecureActionButtonTemplate, ActionButtonTemplate')
	Button:Hide()
	Button:Size(50)
	Button:SetFrameLevel(1)
	if AS then
		AS:SkinButton(Button)
		Button:CreateShadow()
		if ES then
			ES:RegisterShadow(Button.shadow)
		end
	end
	Button:SetAttribute('type', type)
	Button:SetAttribute(type, func(id))
	if AS then
		Button:GetNormalTexture():SetInside()
		Button:GetNormalTexture():SetTexCoord(.1, .9, .1, .9)
		Button:GetPushedTexture():SetTexCoord(.1, .9, .1, .9)
	end
	for i = 1, select('#', ...) do
		local event = select(i, ...)
		Button:RegisterEvent(event)
	end
	Button:RegisterForDrag('LeftButton')
	Button:SetScript('OnDragStart', function(self) self:GetParent():StartMoving() end)
	Button:SetScript('OnDragStop', function(self) self:GetParent():StopMovingOrSizing() end)
	buttons[name] = false
	Button:SetScript('OnEvent', function(self, event)
		local Texture = select(index, func(id))
		self:SetNormalTexture(Texture or nil)
		self:SetPushedTexture(Texture or nil)
		if not InCombatLockdown() then
			if check() then
				self:Show()
				if not buttons[name] then buttons[name] = true; numBigButtons = numBigButtons + 1 end
				UIFrameFadeIn(self, 0.5, self:GetAlpha(), 1)
				self:SetPoint('LEFT', BigButtons, 'LEFT', (numBigButtons - 1) * (self:GetWidth() + (ElvUI and ElvUI[1].PixelMode and 1 or 3)), 0)
			else
				if buttons[name] then buttons[name] = false; numBigButtons = numBigButtons - 1 end
				self:Hide()
			end
			self:GetParent():Update()
		else
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
		if event == 'PLAYER_REGEN_ENABLED' then self:UnregisterEvent(event) end
	end)
end

function BigButtons:CreateSeedButton(ButtonName, ItemID, x, y)
	local Button = CreateFrame('Button', ButtonName, BigButtons.SeedsFrame, 'SecureActionButtonTemplate, ActionButtonTemplate')
	local yTable = {
		[1] = { point = 'TOPLEFT', offset = -4 },
		[2] = { point = 'BOTTOMLEFT', offset = 4 },
	}
	local xOffset = 4 + (34*(x-1))

	Button:Point(yTable[y].point, xOffset, yTable[y].offset)
	Button:Size(30)
	if AS then
		AS:SkinButton(Button)
	end
	Button:SetAttribute('type', 'item')
	Button:SetAttribute('item', GetItemInfo(ItemID))
	Button:HookScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 2, 4)
		GameTooltip:ClearLines()
		GameTooltip:SetItemByID(ItemID)
		GameTooltip:Show()
	end)
	Button:HookScript('OnLeave', GameTooltip_Hide)
	if AS then
		Button:GetNormalTexture():SetInside()
		Button:GetNormalTexture():SetTexCoord(.1, .9, .1, .9)
		Button:GetPushedTexture():SetTexCoord(.1, .9, .1, .9)
	end
	Button:RegisterEvent('PLAYER_ENTERING_WORLD')
	Button:RegisterEvent('BAG_UPDATE')
	function Button:Update()
		local Count = GetItemCount(ItemID)
		local Texture = select(10, GetItemInfo(ItemID))
		self:SetNormalTexture(Texture or nil)
		self:SetPushedTexture(Texture or nil)
		if Count > 0 then
			self:EnableMouse(true)
			_G[ButtonName..'Count']:SetText(Count)
			if self:GetNormalTexture() then
				self:GetNormalTexture():SetDesaturated(false)
			end
		elseif Count == 0 then
			self:EnableMouse(false)
			_G[ButtonName..'Count']:SetText()
			if self:GetNormalTexture() then
				self:GetNormalTexture():SetDesaturated(true)
			end
		end
	end
	Button:RegisterForDrag('LeftButton')
	Button:SetScript('OnDragStart', function(self)
		self:GetParent():StartMoving()
	end)
	Button:SetScript('OnDragStop', function(self)
		self:GetParent():StopMovingOrSizing()
	end)
	Button:SetScript('OnShow', function(self) self:Update() end)
	Button:SetScript('OnEvent', function(self) self:Update() end)
end

BigButtons:RegisterEvent('PLAYER_LOGIN')
BigButtons:RegisterEvent('ZONE_CHANGED')
BigButtons:RegisterEvent('PLAYER_ENTERING_WORLD')
BigButtons:SetScript('OnEvent', function(self, event, addon)
	if event == 'PLAYER_LOGIN' then
		ES = IsAddOnLoaded('ElvUI') and ElvUI[1]:GetModule("EnhancedShadows", true)
		AS = AddOnSkins and AddOnSkins[1]
		if AS then
			BigButtons.SeedsFrame:CreateShadow()
			BigButtons.SeedsFrame:SetTemplate('Transparent')
			BorderColor = { BigButtons.SeedsFrame:GetBackdropBorderColor() }
		end
		if ES then
			ES:RegisterShadow(BigButtons.SeedsFrame.shadow)
		end

		self:CreateBigButton('RustyWateringCan', 79104, 'item', function() return GetSubZoneText() == RanchName and GetItemCount(79104) == 1 end, 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'UNIT_INVENTORY_CHANGED')
		self:CreateBigButton('VintageBugSprayer', 80513, 'item', function() return GetSubZoneText() == RanchName and GetItemCount(80513) == 1 end, 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'UNIT_INVENTORY_CHANGED')
		self:CreateBigButton('DentedShovel', 89880, 'item', function() return GetSubZoneText() == RanchName and GetItemCount(89880) == 1 end, 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'UNIT_INVENTORY_CHANGED')
		self:CreateBigButton('MasterPlow', 89815, 'item', function() return GetSubZoneText() == RanchName and GetItemCount(89815) == 1 end, 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'UNIT_INVENTORY_CHANGED')

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
	end
end)