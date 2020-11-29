local PA = _G.ProjectAzilroka
if PA.Classic then return end

local BB = PA:NewModule('BigButtons', 'AceEvent-3.0')
PA.BB, _G.BigButtons = BB, BB

BB.Title = PA.ACL['|cFF16C3F2Big|r |cFFFFFFFFButtons|r']
BB.Description = PA.ACL['A farm tool for Sunsong Ranch.']
BB.Authors = 'Azilroka    NihilisticPandemonium'
BB.isEnabled = false

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

BB.Ranch, BB.Market = Locales[Locale].Ranch, Locales[Locale].Market

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
	if not BB.Bar then return end

	local PrevButton, NumShown = nil, 0
	for _, Button in pairs(BB.Bar.Buttons) do
		if Button:IsShown() then
			Button:ClearAllPoints()
			Button:SetPoint(unpack(PrevButton and {'LEFT', PrevButton, 'RIGHT', (PA.ElvUI and _G.ElvUI[1].PixelMode and 1 or 3), 0} or {'LEFT', BB.Bar, 'LEFT', 0, 0}))
			PrevButton = Button
			NumShown = NumShown + 1
		end
	end

	if NumShown == 0 then NumShown = 1 end

	BB.Bar:SetSize(NumShown * (50 + (PA.ElvUI and _G.ElvUI[1].PixelMode and 1 or 3)), 50)
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
	local Button = CreateFrame('Button', nil, BB.Bar, 'SecureActionButtonTemplate, ActionButtonTemplate')
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

	for _, event in pairs(BB.Events) do
		Button:RegisterEvent(event)
	end

	Button:SetScript('OnShow', function()
		if Button:GetAttribute('item') ~= GetItemInfo(ItemID) then
			Button:SetAttribute('item', GetItemInfo(ItemID))
		end
	end)

	Button:SetScript('OnEvent', function()
		if not InCombatLockdown() then
			if BB:InFarmZone() and GetItemCount(ItemID) == 1 then
				Button:Show()
				BB:Update()
			end
			Button:UnregisterEvent('PLAYER_REGEN_ENABLED')
		else
			Button:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
	end)

	tinsert(BB.Bar.Buttons, Button)
end

local SeedX, SeedY = 0, 1
function BB:CreateSeedButton(ItemID)
	SeedX = SeedX + 1
	if SeedX > 10 then
		SeedX, SeedY = 1, 2
	end

	local Button = CreateFrame('Button', nil, BB.Bar.SeedsFrame, 'SecureActionButtonTemplate, ActionButtonTemplate')
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

	Button:ClearAllPoints()
	Button:SetPoint(yTable[SeedY].point, xOffset, yTable[SeedY].offset)

	PA:CreateShadow(Button)

	tinsert(BB.Bar.SeedsFrame.Buttons, Button)
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
	local BigButtons = PA.ACH:Group(BB.Title, BB.Description, nil, nil, function(info) return BB.db[info[#info]] end)
	PA.Options.args.BigButtons = BigButtons

	BigButtons.args.Description = PA.ACH:Description(BB.Description, 0)
	BigButtons.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) BB.db[info[#info]] = value if not BB.isEnabled then BB:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	BigButtons.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, nil, function(info, value) BB.db[info[#info]] = value BB:Update() end)
	BigButtons.args.General.inline = true
	BigButtons.args.General.args.DropTools = PA.ACH:Toggle(PA.ACL['Drop Farm Tools'], nil, 1)
	BigButtons.args.General.args.ToolSize = PA.ACH:Range(PA.ACL['Farm Tool Size'], nil, 2, { min = 16, max = 64, step = 1 })
	BigButtons.args.General.args.SeedSize = PA.ACH:Range(PA.ACL['Seed Size'], nil, 3, { min = 16, max = 64, step = 1 })

	BigButtons.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	BigButtons.args.Authors = PA.ACH:Description(BB.Authors, -1, 'large')
end

function BB:BuildProfile()
	PA.Defaults.profile.BigButtons = { Enable = true, DropTools = false, ToolSize = 50, SeedSize = 30 }
end

function BB:UpdateSettings()
	BB.db = PA.db.BigButtons
end

function BB:Initialize()
	BB:UpdateSettings()

	if BB.db.Enable ~= true then
		return
	end

	BB.isEnabled = true

	local Bar = CreateFrame('Frame', 'BigButtonsBar', _G.UIParent, "SecureHandlerStateTemplate")
	BB.Bar = Bar
	Bar:Hide()
	Bar:SetFrameStrata('MEDIUM')
	Bar:SetFrameLevel(0)
	Bar:SetSize(50, 50)
	Bar:ClearAllPoints()
	Bar:SetPoint('TOP', _G.UIParent, 'TOP', 0, -250)
	Bar.Buttons = {}

	Bar.SeedsFrame = CreateFrame('Frame', 'BigButtonsSeedBar', _G.UIParent)
	Bar.SeedsFrame:SetFrameStrata('MEDIUM')
	Bar.SeedsFrame:SetFrameLevel(0)
	Bar.SeedsFrame:SetSize(344, 72)
	Bar.SeedsFrame:SetPoint('TOP', _G.UIParent, 'TOP', 0, -300)
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

	Bar:SetScript('OnEvent', function(frame)
		if not InCombatLockdown() then
			if BB:InFarmZone() then
				frame:Show()
				UIFrameFadeIn(frame, 0.5, 0, 1)
			else
				BB:DropTools()
				frame:Hide()
			end
		end
	end)

	Bar.SeedsFrame:SetScript('OnEvent', function(frame)
		if not InCombatLockdown() then
			if BB:InSeedZone() then
				frame:Show()
				UIFrameFadeIn(frame, 0.5, 0, 1)
			else
				frame:Hide()
			end
		end
	end)

	if PA.Tukui then
		_G.Tukui[1]['Movers']:RegisterFrame(BB.Bar)
		_G.Tukui[1]['Movers']:RegisterFrame(BB.Bar.SeedsFrame)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(BB.Bar, 'BigButtonsFarmBar', 'BigButtons Farm Bar Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,BigButtons')
		_G.ElvUI[1]:CreateMover(BB.Bar.SeedsFrame, 'BigButtonsSeedBarMover', 'BigButtons Seed Bar Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,BigButtons')
	end

	PA:CreateShadow(Bar.SeedsFrame)
	PA:SetTemplate(Bar.SeedsFrame)

	Bar.SeedsFrame.BorderColor = { Bar.SeedsFrame:GetBackdropBorderColor() }
end
