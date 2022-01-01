local PA = _G.ProjectAzilroka
local MF = PA:NewModule('MovableFrames', 'AceEvent-3.0', 'AceHook-3.0')
PA.MF, _G.MovableFrames = MF, MF

MF.Title = PA.ACL['|cFF16C3F2Movable|r |cFFFFFFFFFrames|r']
MF.Description = PA.ACL['Make Blizzard Frames Movable']
MF.Authors = 'Azilroka    Simpy'
MF.isEnabled = false

local next = next

local _G = _G
local IsAddOnLoaded = IsAddOnLoaded
local IsShiftKeyDown = IsShiftKeyDown

local Frames = {
	'AddonList',
	'BankFrame',
	'CharacterFrame',
	'DressUpFrame',
	'FriendsFrame',
	'FriendsFriendsFrame',
	'GameMenuFrame',
	'GhostFrame',
	'GossipFrame',
	'GuildInviteFrame',
	'GuildRegistrarFrame',
	'HelpFrame',
	'InterfaceOptionsFrame',
	'ItemTextFrame',
	'LFGDungeonReadyDialog',
	'LootFrame',
	'LossOfControlFrame',
	'MailFrame',
	'MerchantFrame',
	'PetitionFrame',
	'PetStableFrame',
	'PVEFrame',
	'QuestFrame',
	'QuestLogFrame',
	'QuestLogPopupDetailFrame',
	'RaidBrowserFrame',
	'RaidParentFrame',
	'ReadyCheckFrame',
	'ScrollOfResurrectionSelectionFrame',
	'SpellBookFrame',
	'SplashFrame',
	'StaticPopup1',
	'StaticPopup2',
	'StaticPopup3',
	'StaticPopup4',
	'TabardFrame',
	'TaxiFrame',
	'TimeManagerFrame',
	'TradeFrame',
	'VideoOptionsFrame',
	'WorldMapFrame',
	'WorldStateScoreFrame',
}

local AddOnFrames = {
	Blizzard_AchievementUI = { 'AchievementFrame' },
	Blizzard_AnimaDiversionUI = { 'AnimaDiversionFrame' },
	Blizzard_ArchaeologyUI = { 'ArchaeologyFrame' },
	Blizzard_AuctionUI = { 'AuctionFrame' },
	Blizzard_AuctionHouseUI = { 'AuctionHouseFrame' },
	Blizzard_BarbershopUI = { 'BarberShopFrame' },
	Blizzard_BindingUI = { 'KeyBindingFrame' },
	Blizzard_BlackMarketUI = { 'BlackMarketFrame' },
	Blizzard_Calendar = { 'CalendarCreateEventFrame', 'CalendarFrame', 'CalendarViewEventFrame', 'CalendarViewHolidayFrame'	},
	Blizzard_ChallengesUI = { 'ChallengesKeystoneFrame' },
	Blizzard_Channels = { 'ChannelFrame' },
	Blizzard_Collections = { 'CollectionsJournal' },
	Blizzard_Communities = { 'CommunitiesFrame'	},
	Blizzard_CovenantPreviewUI = { 'CovenantPreviewFrame' },
	Blizzard_CovenantSanctum = { 'CovenantSanctumFrame' },
	Blizzard_CraftUI = { 'CraftFrame' },
	Blizzard_EncounterJournal = { 'EncounterJournal' },
	Blizzard_GarrisonUI = { 'GarrisonBuildingFrame', 'GarrisonCapacitiveDisplayFrame', 'GarrisonLandingPage', 'GarrisonMissionFrame', 'GarrisonRecruiterFrame', 'GarrisonRecruitSelectFrame', 'GarrisonShipyardFrame' },
	Blizzard_GuildBankUI = { 'GuildBankFrame' },
	Blizzard_GuildControlUI = { 'GuildControlUI' },
	Blizzard_InspectUI = { 'InspectFrame' },
	Blizzard_ItemSocketingUI = { 'ItemSocketingFrame' },
	Blizzard_ItemUpgradeUI = { 'ItemUpgradeFrame' },
	Blizzard_LookingForGuildUI = { 'LookingForGuildFrame' },
	Blizzard_MacroUI = { 'MacroFrame' },
	Blizzard_OrderHallUI = { 'OrderHallTalentFrame' },
	Blizzard_QuestChoice = { 'QuestChoiceFrame' },
	Blizzard_TalentUI = { 'PlayerTalentFrame', 'TalentFrame' },
	Blizzard_Soulbinds = { 'SoulbindViewer' },
	Blizzard_ScrappingMachineUI = { 'ScrappingMachineFrame' },
	Blizzard_TalkingHeadUI = { 'TalkingHeadFrame' },
	Blizzard_TradeSkillUI = { 'TradeSkillFrame' },
	Blizzard_TrainerUI = { 'ClassTrainerFrame' },
	Blizzard_VoidStorageUI = { 'VoidStorageFrame' },
	Blizzard_WeeklyRewards = { 'WeeklyRewardsFrame' },
}

function MF:OnDragStart(frame)
	local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint()

	frame:StartMoving()

	if point and not frame:GetPoint() then
		frame:SetUserPlaced(false)
		frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	else
		frame:SetUserPlaced(true)
	end

	return point, relativeTo, relativePoint, xOffset, yOffset
end

function MF:OnDragStop(frame)
	frame:StopMovingOrSizing()
end

function MF:OnMouseWheel(frame, delta)
	if frame:IsMouseOver() and IsShiftKeyDown() then
		local oldScale = frame:GetScale() or 1
		local newScale = oldScale + (0.01 * delta)

		if newScale > 1.5 then newScale = 1.5 end
		if newScale < 0.75 then newScale = 0.75 end

		frame:SetScale(newScale)
	end
end

function MF:MakeMovable(name)
	local frame = _G[name]
	if not frame then
		return
	end

	if name == 'AchievementFrame' then
		_G.AchievementFrameHeader:EnableMouse(false)
	end

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag('LeftButton')
	frame:SetClampedToScreen(true)

	MF:HookScript(frame, 'OnDragStart', 'OnDragStart')
	MF:HookScript(frame, 'OnDragStop', 'OnDragStop')

	-- frame:EnableMouseWheel(true)
	-- MF:SecureHookScript(Frame, 'OnMouseWheel', 'OnMouseWheel')
end

function MF:ADDON_LOADED(_, addon)
	if AddOnFrames[addon] then
		for _, frame in next, AddOnFrames[addon] do
			MF:MakeMovable(frame)
		end
	end
end

function MF:GetOptions()
	PA.Options.args.MovableFrames = PA.ACH:Group(MF.Title, MF.Description, nil, nil, function(info) return MF.db[info[#info]] end, function(info, value) MF.db[info[#info]] = value MF:Update() end)
	PA.Options.args.MovableFrames.args.Header = PA.ACH:Description(MF.Description, 0)
	PA.Options.args.MovableFrames.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) MF.db[info[#info]] = value if (not MF.isEnabled) then MF:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	PA.Options.args.MovableFrames.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	PA.Options.args.MovableFrames.args.Authors = PA.ACH:Description(MF.Authors, -1, 'large')
end

function MF:BuildProfile()
	PA.Defaults.profile.MovableFrames = { Enable = true }
end

function MF:UpdateSettings()
	MF.db = PA.db.MovableFrames
end

function MF:Initialize()
	MF:UpdateSettings()

	if MF.db.Enable ~= true then
		return
	end

	if PA.ElvUI and PA.SLE then
		if (not _G.ElvUI[1].private.sle.module) or (_G.ElvUI[1].private.sle.module.blizzmove and _G.ElvUI[1].private.sle.module.blizzmove.enable) then
			_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'Shadow & Light Blizz Move and Movable Frames will not work together. Which one do you want to disable?'
			_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'S&L Blizz Move'
			_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Movable Frames'
			_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function()
				_G.ElvUI[1].private.sle.module.blizzmove.enable = false
				_G.ReloadUI()
			end
			_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() MF.db.Enable = false end
			_G.StaticPopup_Show("PROJECTAZILROKA")
			return
		end
	end

	MF.isEnabled = true

	if PA:IsAddOnEnabled('WorldQuestTracker') or PA:IsAddOnEnabled('Leatrix_Maps') then
		Frames.WorldMapFrame = nil
	end

	if PA.ElvUI then
		AddOnFrames.LossOfControlFrame = nil
		AddOnFrames.Blizzard_TalkingHeadUI = nil
	end

	for _, frame in next, Frames do
		MF:MakeMovable(frame)
	end

	-- Check Forced Loaded AddOns
	for addon, frames in next, AddOnFrames do
		if IsAddOnLoaded(addon) then
			for _, frame in next, frames do
				MF:MakeMovable(frame)
			end
		end
	end

	MF:RegisterEvent('ADDON_LOADED')
end
