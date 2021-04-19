local PA = _G.ProjectAzilroka
if PA.Classic then return end

local SRF = PA:NewModule('SunsongRanchFarmer', 'AceEvent-3.0')
PA.SRF, _G.SunsongRanchFarmer = SRF, SRF

SRF.Title = PA.ACL['|cFF16C3F2Sunsong|r |cFFFFFFFFRanch Farmer|r']
SRF.Description = PA.ACL['A farm tool for Sunsong Ranch.']
SRF.Authors = 'Azilroka    Nihilistzsche'
SRF.isEnabled = false

local _G = _G

local select = select
local tinsert = tinsert
local unpack = unpack
local pairs = pairs
local GetItemInfo = GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant
local GetSubZoneText = GetSubZoneText
local GetItemCount = GetItemCount
local InCombatLockdown = InCombatLockdown
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemID = GetContainerItemID
local PickupContainerItem = PickupContainerItem
local DeleteCursorItem = DeleteCursorItem

local CreateFrame = CreateFrame
local Locale = PA.Locale

if Locale == 'esMX' then Locale = 'esES' end
if Locale == 'enGB' then Locale = 'enUS' end

local Locales = {
	enUS = { Ranch = 'Sunsong Ranch', Market = 'The Halfhill Market' },
	esES = { Ranch = 'Rancho Cantosol', Market = 'El Mercado del Alcor' },
	ptBR = { Ranch = 'Fazenda Sol Cantante', Market = 'Mercado da Meia Colina' },
	frFR = { Ranch = 'Ferme Chant du Soleil', Market = 'Marché de Micolline' },
	deDE = { Ranch = 'Gehöft Sonnensang', Market = 'Der Halbhügelmarkt' },
	itIT = { Ranch = 'Tenuta Cantasole', Market = 'Mercato di Mezzocolle' },
	koKR = { Ranch = '태양노래 농장', Market = '언덕골 시장' },
	zhCN = { Ranch = '日歌农场', Market = '半山市集' },
	zhTW = { Ranch = '日歌農莊', Market = '半丘市集' },
	ruRU = { Ranch = 'Ферма Солнечной Песни', Market = 'Рынок Полугорья' },
}

SRF.Ranch, SRF.Market = Locales[Locale].Ranch, Locales[Locale].Market

SRF.Events = {'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'ZONE_CHANGED_NEW_AREA', 'ZONE_CHANGED_INDOORS', 'BAG_UPDATE'}

SRF.Tools = { 79104, 80513, 89880, 89815 }

SRF.Seeds = {
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

SRF.Quests = {
	--Tillers counsil
	[31945] = { 80591, 84783}, -- Gina, Scallion
	[31946] = {80590, 84782}, -- Mung-Mung, Juicycrunch Carrot
	[31947] = {79102, 80809}, -- Farmer Fung, Green Cabbage
	[31949] = {89326, 89847}, -- Nana, Witchberry
	[30527] = {89329, 89849}, -- Haohan, Striped Melon

	--Farmer Yoon
	[31943] = {89326, 89847}, -- Witchberry
	[31942] = {89329, 89849}, -- Striped Melon
	[31941] = {89328, 89848}, -- Jade Squash
	[31669] = {79102, 80809}, -- Green Cabbage
	[31670] = {80590, 84782}, -- Juicycrunch Carrot
	[31672] = {80592, 85153}, -- Mogu Pumpkin
	[31673] = {80593, 85158}, -- Red Blossom Leek
	[31674] = {80594, 85162}, -- Pink Turnip
	[31675] = {80595, 85163}, -- White Turnip
	[31671] = {80591, 84783}, -- Scallion

	--Work Orders
	[32645] = {89326, 89847}, -- Witchberry (Alliance Only)
	[32653] = {89329, 89849}, -- Striped Melon
	--[31941] = {89328, 89848}, -- Jade Squash
	[32649] = {79102, 80809}, -- Green Cabbage
	--[31670] = {80590, 84782}, -- Juicycrunch Carrot
	[32658] = {80592, 85153}, -- Mogu Pumpkin
	[32642] = {80593, 85158}, -- Red Blossom Leek (Horde Only)
	--[31674] = {80594, 85162}, -- Pink Turnip
	[32647] = {80595, 85163}, -- White Turnip
	--[31671] = {80591, 84783}, -- Scallion
}

--local function QuestItems(itemID)
--	for i = 1, GetNumQuestLogEntries() do
--		for qid, sid in pairs(FarmQuests) do
--			if qid == select(9, GetQuestLogTitle(i)) then
--				if itemID == sid[1] or itemID == sid[2] then
--					return true
--				end
--			end
--		end
--	end

--	return false
--end

--	for i = 1, SeedAnchor.NumBars do
--		local seedBar = CreateFrame("Frame", SeedAnchor.BarsName..i, SeedAnchor)
--		seedBar:SetFrameStrata("BACKGROUND")

--		if i == 1 or i == 3 then
--			seedBar.Autotarget = function(button)
--				if not E.db.sle.legacy.farm.autotarget then return end
--				local container, slot = SLE:BagSearch(button.itemId)
--				if container and slot then
--					button:SetAttribute("type", "macro")
--					button:SetAttribute("macrotext", format("/targetexact %s \n/use %s %s", L["Tilled Soil"], container, slot))
--				end
--			end
--		end

function SRF:Update()
	if not SRF.Bar then return end

	local PrevButton, NumShown = nil, 0
	for _, Button in pairs(SRF.Bar.Buttons) do
		if Button:IsShown() then
			Button:ClearAllPoints()
			Button:SetPoint(unpack(PrevButton and {'LEFT', PrevButton, 'RIGHT', (PA.ElvUI and _G.ElvUI[1].PixelMode and 1 or 3), 0} or {'LEFT', SRF.Bar, 'LEFT', 0, 0}))
			PrevButton = Button
			NumShown = NumShown + 1
		end
	end

	if NumShown == 0 then NumShown = 1 end

	SRF.Bar:SetSize(NumShown * (50 + (PA.ElvUI and _G.ElvUI[1].PixelMode and 1 or 3)), 50)
end

function SRF:InSeedZone()
	local SubZone = GetSubZoneText()
	if SubZone == SRF.Ranch or SubZone == SRF.Market then
		return true
	else
		return false
	end
end

function SRF:InFarmZone()
	return GetSubZoneText() == SRF.Ranch
end

function SRF:CreateBigButton(ItemID)
	local Button = CreateFrame('Button', nil, SRF.Bar, 'SecureActionButtonTemplate, ActionButtonTemplate')
	Button:Hide()
	PA:SetTemplate(Button)
	Button:SetSize(50, 50)
	Button:SetFrameLevel(1)
	Button:SetAttribute('type', 'item')
	Button:SetAttribute('item', GetItemInfo(ItemID))
	Button.ItemID = ItemID

	Button.icon:SetTexture(select(5, GetItemInfoInstant(ItemID)))
	Button.icon:SetTexCoord(unpack(PA.TexCoords))
	PA:SetInside(Button.icon)
	Button.icon:SetDrawLayer('ARTWORK')

	Button:SetNormalTexture('')
	Button:SetPushedTexture('')
	Button:SetHighlightTexture('')

	PA:CreateShadow(Button)

	for _, event in pairs(SRF.Events) do
		Button:RegisterEvent(event)
	end

	Button:SetScript('OnShow', function()
		if Button:GetAttribute('item') ~= GetItemInfo(ItemID) then
			Button:SetAttribute('item', GetItemInfo(ItemID))
		end
	end)

	Button:SetScript('OnEvent', function()
		if not InCombatLockdown() then
			if SRF:InFarmZone() and GetItemCount(ItemID) == 1 then
				Button:Show()
				SRF:Update()
			end
			Button:UnregisterEvent('PLAYER_REGEN_ENABLED')
		else
			Button:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
	end)

	tinsert(SRF.Bar.Buttons, Button)
end

local SeedX, SeedY = 0, 1
function SRF:CreateSeedButton(ItemID)
	SeedX = SeedX + 1
	if SeedX > 10 then
		SeedX, SeedY = 1, 2
	end

	local Button = CreateFrame('Button', nil, SRF.Bar.SeedsFrame, 'SecureActionButtonTemplate, ActionButtonTemplate')
	PA:SetTemplate(Button)
	Button:SetSize(30, 30)
	Button:SetAttribute('type', 'item')
	Button:SetAttribute('item', GetItemInfo(ItemID))
	Button.ItemID = ItemID

	Button.icon:SetTexture(select(5, GetItemInfoInstant(ItemID)))
	Button.icon:SetTexCoord(unpack(PA.TexCoords))
	Button.icon:SetPoint('TOPLEFT', 1, -1)
	Button.icon:SetPoint('BOTTOMRIGHT', -1, 1)
	Button.icon:SetDrawLayer('ARTWORK')

	Button:SetNormalTexture('')
	Button:SetPushedTexture('')
	Button:SetHighlightTexture('')

	Button:HookScript('OnEnter', function(button)
		_G.GameTooltip:SetOwner(button, 'ANCHOR_TOPRIGHT', 2, 4)
		_G.GameTooltip:ClearLines()
		_G.GameTooltip:SetItemByID(ItemID)
		_G.GameTooltip:Show()
	end)

	Button:HookScript('OnLeave', _G.GameTooltip_Hide)

	local function Update(button)
		if not InCombatLockdown() then
			if button:GetAttribute('item') ~= GetItemInfo(button.ItemID) then
				button:SetAttribute('item', GetItemInfo(button.ItemID))
			end
			local Count = GetItemCount(button.ItemID)
			button:EnableMouse(Count > 0)
			button.Count:SetText(Count > 0 and Count or '')
			button.icon:SetDesaturated(Count == 0)
			button:UnregisterEvent('PLAYER_REGEN_ENABLED')
		else
			button:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
	end

	for _, event in pairs(SRF.Events) do
		Button:RegisterEvent(event)
	end

	Button:SetScript('OnEvent', Update)
	Button:SetScript('OnShow', Update)

	local yTable = {
		[1] = { point = 'TOPLEFT', offset = -4 },
		[2] = { point = 'BOTTOMLEFT', offset = 4 },
	}
	local xOffset = 4 + (34*(SeedX-1))

	Button:ClearAllPoints()
	Button:SetPoint(yTable[SeedY].point, xOffset, yTable[SeedY].offset)

	PA:CreateShadow(Button)

	tinsert(SRF.Bar.SeedsFrame.Buttons, Button)
end

function SRF:DropTools()
	if not SRF:InSeedZone() and SRF.db.DropTools then
		for _, ItemID in pairs(SRF.Tools) do
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

function SRF:GetOptions()
	local SunsongRanchFarmer = PA.ACH:Group(SRF.Title, SRF.Description, nil, nil, function(info) return SRF.db[info[#info]] end)
	PA.Options.args.SunsongRanchFarmer = SunsongRanchFarmer

	SunsongRanchFarmer.args.Description = PA.ACH:Description(SRF.Description, 0)
	SunsongRanchFarmer.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) SRF.db[info[#info]] = value if not SRF.isEnabled then SRF:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	SunsongRanchFarmer.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, nil, function(info, value) SRF.db[info[#info]] = value SRF:Update() end)
	SunsongRanchFarmer.args.General.inline = true
	SunsongRanchFarmer.args.General.args.DropTools = PA.ACH:Toggle(PA.ACL['Drop Farm Tools'], nil, 1)
	SunsongRanchFarmer.args.General.args.ToolSize = PA.ACH:Range(PA.ACL['Farm Tool Size'], nil, 2, { min = 16, max = 64, step = 1 })
	SunsongRanchFarmer.args.General.args.SeedSize = PA.ACH:Range(PA.ACL['Seed Size'], nil, 3, { min = 16, max = 64, step = 1 })

	SunsongRanchFarmer.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	SunsongRanchFarmer.args.Authors = PA.ACH:Description(SRF.Authors, -1, 'large')
end

function SRF:BuildProfile()
	PA.Defaults.profile.SunsongRanchFarmer = { Enable = true, DropTools = false, ToolSize = 36, SeedSize = 24 }
end

function SRF:UpdateSettings()
	SRF.db = PA.db.SunsongRanchFarmer
end

function SRF:Initialize()
	SRF:UpdateSettings()

	if SRF.db.Enable ~= true then
		return
	end

	SRF.isEnabled = true

	local Bar = CreateFrame('Frame', 'SunsongRanchFarmerBar', _G.UIParent, "SecureHandlerStateTemplate")
	SRF.Bar = Bar
	Bar:Hide()
	Bar:SetFrameStrata('MEDIUM')
	Bar:SetFrameLevel(0)
	Bar:SetSize(36, 36)
	Bar:ClearAllPoints()
	Bar:SetPoint('TOP', _G.UIParent, 'TOP', 0, -250)
	Bar.Buttons = {}

	Bar.SeedsFrame = CreateFrame('Frame', 'SunsongRanchFarmerSeedBar', _G.UIParent)
	Bar.SeedsFrame:SetFrameStrata('MEDIUM')
	Bar.SeedsFrame:SetFrameLevel(0)
	Bar.SeedsFrame:SetSize(344, 72)
	Bar.SeedsFrame:SetPoint('TOP', _G.UIParent, 'TOP', 0, -300)
	Bar.SeedsFrame.Buttons = {}

	for _, ItemID in pairs(SRF.Tools) do
		SRF:CreateBigButton(ItemID)
	end

	for i = 1, 20 do
		SRF:CreateSeedButton(SRF.Seeds[i].Seed)
	end

	for _, event in pairs(SRF.Events) do
		Bar:RegisterEvent(event)
		Bar.SeedsFrame:RegisterEvent(event)
	end

	Bar:SetScript('OnEvent', function(frame)
		if not InCombatLockdown() then
			if SRF:InFarmZone() then
				frame:Show()
				UIFrameFadeIn(frame, 0.5, 0, 1)
			else
				SRF:DropTools()
				frame:Hide()
			end
		end
	end)

	Bar.SeedsFrame:SetScript('OnEvent', function(frame)
		if not InCombatLockdown() then
			if SRF:InSeedZone() then
				frame:Show()
				UIFrameFadeIn(frame, 0.5, 0, 1)
			else
				frame:Hide()
			end
		end
	end)

	if PA.Tukui then
		_G.Tukui[1]['Movers']:RegisterFrame(SRF.Bar)
		_G.Tukui[1]['Movers']:RegisterFrame(SRF.Bar.SeedsFrame)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(SRF.Bar, 'SunsongRanchFarmerFarmBar', 'Sunsong Ranch Framer Farm Bar Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,SunsongRanchFarmer')
		_G.ElvUI[1]:CreateMover(SRF.Bar.SeedsFrame, 'SunsongRanchFarmerSeedBarMover', 'Sunsong Ranch Framer Seed Bar Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,SunsongRanchFarmer')
	end

	PA:CreateShadow(Bar.SeedsFrame)
	PA:SetTemplate(Bar.SeedsFrame)

	Bar.SeedsFrame.BorderColor = { Bar.SeedsFrame:GetBackdropBorderColor() }
end
