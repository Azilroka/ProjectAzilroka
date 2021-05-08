local PA = _G.ProjectAzilroka
local MF = PA:NewModule('MovableFrames', 'AceEvent-3.0', 'AceHook-3.0')
PA.MF, _G.MovableFrames = MF, MF

MF.Title = PA.ACL['|cFF16C3F2Movable|r |cFFFFFFFFFrames|r']
MF.Description = PA.ACL['Make Blizzard Frames Movable']
MF.Authors = 'Azilroka    Simpy'
MF.isEnabled = false

local pairs = pairs
local unpack = unpack

local _G = _G
local IsAddOnLoaded = IsAddOnLoaded
local InCombatLockdown = InCombatLockdown

local Frames = {
	AddonList = { "CENTER", "UIParent", "CENTER", 0, 24 },
	BankFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	CharacterFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	DressUpFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 70, -104 },
	FriendsFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	FriendsFriendsFrame = { "CENTER", "UIParent", "CENTER", 0, 50 },
	GameMenuFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	GhostFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, 0 },
	GossipFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	GuildInviteFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	GuildRegistrarFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	HelpFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	InterfaceOptionsFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	ItemTextFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	LFGDungeonReadyDialog = { "TOPLEFT", _G.LFGDungeonReadyPopup, "TOPLEFT", 0, 0 },
	LootFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	LossOfControlFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	MailFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	MerchantFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	PetitionFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	PetStableFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 },
	PVEFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 100, -84 },
	QuestFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	QuestLogFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	QuestLogPopupDetailFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, 0 },
	RaidBrowserFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	RaidParentFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	ReadyCheckFrame = { "CENTER", "UIParent", "CENTER", 0, -10 },
	ScrollOfResurrectionSelectionFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	SpellBookFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	SplashFrame = { "CENTER", "UIParent", "CENTER", 0, 60 },
	StaticPopup1 = { "TOP", "UIParent", "TOP", 0, -135 },
	StaticPopup2 = { "TOP", "UIParent", "TOP", 0, -135 },
	StaticPopup3 = { "TOP", "UIParent", "TOP", 0, -135 },
	StaticPopup4 = { "TOP", "UIParent", "TOP", 0, -135 },
	TabardFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	TaxiFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 },
	TimeManagerFrame = { "TOPRIGHT", "UIParent", "TOPRIGHT", -10, -190 },
	TradeFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	VideoOptionsFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	WorldMapFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	WorldStateScoreFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
}

local AddOnFrames = {
	Blizzard_AchievementUI = {
		AchievementFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 96, -116 }
	},
	Blizzard_AnimaDiversionUI = {
		AnimaDiversionFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_ArchaeologyUI = {
		ArchaeologyFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_AuctionUI = {
		AuctionFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	Blizzard_AuctionHouseUI = {
		AuctionHouseFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	Blizzard_BarbershopUI = {
		BarberShopFrame = { "RIGHT", "UIParent", "RIGHT", -18, -54 }
	},
	Blizzard_BindingUI = {
		KeyBindingFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_BlackMarketUI = {
		BlackMarketFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	Blizzard_Calendar = {
		CalendarCreateEventFrame = { "TOPLEFT", _G.CalendarFrame, "TOPRIGHT", 3, -24 },
		CalendarFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -96 },
		CalendarViewEventFrame = { "TOPLEFT", _G.CalendarFrame, "TOPRIGHT", 3, -24 },
		CalendarViewHolidayFrame = { "TOPLEFT", _G.CalendarFrame, "TOPRIGHT", 3, -24 },
	},
	Blizzard_ChallengesUI = {
		ChallengesKeystoneFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_Channels = {
		ChannelFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -96 }
	},
	Blizzard_Collections = {
		CollectionsJournal = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_Communities = {
		CommunitiesFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_CovenantPreviewUI = {
		CovenantPreviewFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_CovenantSanctum = {
		CovenantSanctumFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_CraftUI = {
		CraftFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_EncounterJournal = {
		EncounterJournal = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_GarrisonUI = {
		GarrisonBuildingFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
		GarrisonCapacitiveDisplayFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 27, -108 },
		GarrisonLandingPage = { "CENTER", "UIParent", "CENTER", 0, 0 },
		GarrisonMissionFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
		GarrisonRecruiterFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
		GarrisonRecruitSelectFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
		GarrisonShipyardFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	},
	Blizzard_GuildBankUI = {
		GuildBankFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	Blizzard_GuildControlUI = {
		GuildControlUI = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_InspectUI = {
		InspectFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_ItemSocketingUI = {
		ItemSocketingFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_ItemUpgradeUI = {
		ItemUpgradeFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_LookingForGuildUI = {
		LookingForGuildFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_MacroUI = {
		MacroFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_OrderHallUI = {
		OrderHallTalentFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 32, -116 }
	},
	Blizzard_QuestChoice = {
		QuestChoiceFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	Blizzard_TalentUI = {
		PlayerTalentFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 100, -84 },
		TalentFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 100, -84 },
	},
	Blizzard_Soulbinds = {
		SoulbindViewer = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_ScrappingMachineUI = {
		ScrappingMachineFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_TalkingHeadUI = {
		TalkingHeadFrame = { "BOTTOM", "UIParent", "BOTTOM", 0, 96 }
	},
	Blizzard_TradeSkillUI = {
		TradeSkillFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_TrainerUI = {
		ClassTrainerFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_VoidStorageUI = {
		VoidStorageFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_WeeklyRewards = {
		WeeklyRewardsFrame = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
}

function MF:LoadPosition(frame, elapsed)
	if frame.MFisMoving or InCombatLockdown() then return end

	frame.throttle = (frame.throttle or 0) + (elapsed or .01)

	if frame:IsMovable() and frame:IsUserPlaced() and (frame.throttle > .01) then
		frame:SetScript('OnMouseDown', nil)
		local a, b, c, d, e = unpack(MF.db[frame:GetName()].Points)
		frame:ClearAllPoints()
		frame:SetPoint(a, _G[b], c, d, e, true)
		frame.throttle = 0
	end
end

function MF:OnDragStart(frame)
	frame.MFisMoving = true
	frame:StartMoving()
end

function MF:OnDragStop(frame)
	frame:StopMovingOrSizing()
	local Name = frame:GetName()
	if MF.db[Name].Permanent then
		local a, _, c, d, e = frame:GetPoint()
		local b = frame:GetParent():GetName() or "UIParent"
		if Name == 'QuestFrame' or Name == 'GossipFrame' then
			MF.db.GossipFrame.Points = {a, b, c, d, e}
			MF.db.QuestFrame.Points = {a, b, c, d, e}
		else
			MF.db[Name].Points = {a, b, c, d, e}
		end
		frame:SetUserPlaced(true)
		frame:ClearAllPoints()
		frame:SetPoint(a, _G[b], c, d, e, true)
	elseif frame:IsUserPlaced() then
		frame:SetUserPlaced(false)
	end
	frame.MFisMoving = false
end

function MF:SetUIPanelAttribute(frame, name, value)
	local info = _G.UIPanelWindows[frame:GetName()];
	if ( not info ) then
		return;
	end

	_G.SetUIPanelAttribute(frame, name, value)
end

function MF:MakeMovable(Name)
	if not _G[Name] then
		return
	end

	local Frame = _G[Name]

	if Name == 'AchievementFrame' then
		_G.AchievementFrameHeader:EnableMouse(false)
	end

	if Name == 'WorldMapFrame' then
		if PA.Classic then
			MF:SetUIPanelAttribute(_G.WorldMapFrame, 'maximizePoint', nil)

			function ToggleWorldMap()
				if _G.WorldMapFrame:IsShown() then
					_G.HideUIPanel(_G.WorldMapFrame)
				else
					_G.ShowUIPanel(_G.WorldMapFrame)
				end
			end

			function OpenWorldMap()
				_G.ShowUIPanel(_G.WorldMapFrame)
			end

			_G.ToggleWorldMap()
			_G.ToggleWorldMap()
		end
	end

	Frame:EnableMouse(true)
	Frame:SetMovable(true)
	Frame:RegisterForDrag('LeftButton')
	Frame:SetClampedToScreen(true)

	MF:HookScript(Frame, 'OnUpdate', 'LoadPosition')
	MF:HookScript(Frame, 'OnDragStart', 'OnDragStart')
	MF:HookScript(Frame, 'OnDragStop', 'OnDragStop')
	MF:HookScript(Frame, 'OnHide', 'OnDragStop')

	MF:SecureHook(Frame, 'SetPoint', function(_, _, _, _, _, locked)
		if not locked then
			MF:LoadPosition(Frame)
		end
	end)
end

function MF:ADDON_LOADED(_, addon)
	if AddOnFrames[addon] then
		for Frame in pairs(AddOnFrames[addon]) do
			MF:MakeMovable(Frame)
		end
	end
end

function MF:GetOptions()
	PA.Options.args.MovableFrames = PA.ACH:Group(MF.Title, MF.Description, nil, nil, function(info) return MF.db[info[#info]] end, function(info, value) MF.db[info[#info]] = value MF:Update() end)
	PA.Options.args.MovableFrames.args.Header = PA.ACH:Description(MF.Description, 0)
	PA.Options.args.MovableFrames.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) MF.db[info[#info]] = value if (not MF.isEnabled) then MF:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)
	PA.Options.args.MovableFrames.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	PA.Options.args.MovableFrames.args.General.inline = true

	PA.Options.args.MovableFrames.args.General.args.Permanent = PA.ACH:MultiSelect(PA.ACL['Permanent Moving'], nil, 1, {}, nil, nil, function(_, key) return MF.db[key].Permanent end, function(_, key, value) MF.db[key].Permanent = value end)
	PA.Options.args.MovableFrames.args.General.args.Reset = PA.ACH:Group(PA.ACL['Reset Moving'], nil, 2)
	PA.Options.args.MovableFrames.args.General.args.Reset.inline = true

	for Frame in pairs(Frames) do
		PA.Options.args.MovableFrames.args.General.args.Permanent.values[Frame] = Frame
		PA.Options.args.MovableFrames.args.General.args.Reset.args[Frame] = PA.ACH:Execute(Frame, nil, nil, function(info) _G.HideUIPanel(_G[info[#info]]) end, nil, nil, nil, nil, nil, function(info) return not MF.db[info[#info]].Permanent end)
	end

	for _, Table in pairs(AddOnFrames) do
		for Frame in pairs(Table) do
			PA.Options.args.MovableFrames.args.General.args.Permanent.values[Frame] = Frame
			PA.Options.args.MovableFrames.args.General.args.Reset.args[Frame] = PA.ACH:Execute(Frame, nil, nil, function(info) _G.HideUIPanel(_G[info[#info]]) end, nil, nil, nil, nil, nil, function(info) return not MF.db[info[#info]].Permanent end)
		end
	end

	PA.Options.args.MovableFrames.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	PA.Options.args.MovableFrames.args.Authors = PA.ACH:Description(MF.Authors, -1, 'large')
end

function MF:BuildProfile()
	PA.Defaults.profile.MovableFrames = { Enable = true }

	if PA.Tukui then
		Frames.LossOfControlFrame = { "CENTER", "UIParent", "CENTER", 0, 60 }
	end

	for Frame, DefaultPoints in pairs(Frames) do
		PA.Defaults.profile.MovableFrames[Frame] = { Permanent = true, Points = DefaultPoints }
	end

	for _, Table in pairs(AddOnFrames) do
		for Frame, DefaultPoints in pairs(Table) do
			PA.Defaults.profile.MovableFrames[Frame] = { Permanent = true, Points = DefaultPoints }
		end
	end
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

	for Frame, _ in pairs(Frames) do
		MF:MakeMovable(Frame)
	end

	-- Check Forced Loaded AddOns
	for AddOn, Table in pairs(AddOnFrames) do
		if IsAddOnLoaded(AddOn) then
			for Frame in pairs(Table) do
				MF:MakeMovable(Frame)
			end
		end
	end

	MF:RegisterEvent('ADDON_LOADED')
end
