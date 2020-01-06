local PA = _G.ProjectAzilroka
local MF = PA:NewModule('MovableFrames', 'AceEvent-3.0', 'AceHook-3.0')
PA.MF, _G.MovableFrames = MF, MF

MF.Title = PA.ACL['|cFF16C3F2Movable|r |cFFFFFFFFFrames|r']
MF.Description = PA.ACL['Make Blizzard Frames Movable']
MF.Authors = 'Azilroka    Simpy'

local pairs = pairs
local unpack = unpack
local tinsert = tinsert
local sort = sort

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
	Blizzard_ArchaeologyUI = {
		ArchaeologyFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_AuctionUI = {
		AuctionFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
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
		ChallengesKeystoneFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	},
	Blizzard_Channels = {
		ChannelFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -96 },
	},
	Blizzard_Collections = {
		CollectionsJournal = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	Blizzard_Communities = {
		CommunitiesFrame = { "CENTER", "UIParent", "CENTER", 0, 0 },
	},
	Blizzard_CraftUI = {
		CraftFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
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
}

function MF:LoadPosition(frame)
	if frame.isMoving or InCombatLockdown() then return end
	local a, b, c, d, e
	if frame:IsUserPlaced() then
		a, b, c, d, e = unpack(MF.db[frame:GetName()].Points)
		frame:ClearAllPoints()
		frame:SetPoint(a, _G[b], c, d, e, true)
	end
end

function MF:OnDragStart(frame)
	frame.isMoving = true
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
	elseif frame:IsUserPlaced() then
		frame:SetUserPlaced(false)
	end
	frame.isMoving = false
end

function MF:GetUIPanelAttribute(frame, name)
    local info = _G.UIPanelWindows[frame:GetName()];
    if ( not info ) then
		return;
    end

	return frame:GetAttribute("UIPanelLayout-"..name);
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

	if Name == 'AchievementFrame' then _G.AchievementFrameHeader:EnableMouse(false) end

	if Name == 'WorldMapFrame' and PA.Classic then
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

	Frame:EnableMouse(true)
	Frame:SetMovable(true)
	Frame:RegisterForDrag('LeftButton')
	Frame:SetClampedToScreen(true)

	MF:HookScript(Frame, 'OnUpdate', 'LoadPosition')
	MF:HookScript(Frame, 'OnDragStart', 'OnDragStart')
	MF:HookScript(Frame, 'OnDragStop', 'OnDragStop')
	MF:HookScript(Frame, 'OnHide', 'OnDragStop')

	if MF.db[Name] and MF.db[Name]['Points'] then
		local a, b, c, d, e = unpack(MF.db[Name].Points)
		Frame:ClearAllPoints()
		Frame:SetPoint(a, _G[b], c, d, e, true)
	end

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
	PA.Options.args.MovableFrames = {
		type = 'group',
		name = MF.Title,
		desc = MF.Description,
		childGroups = 'tab',
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(MF.Title),
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				get = function(info) return MF.db[info[#info]] end,
				set = function(info, value) MF.db[info[#info]] = value end,
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				args = {
					Permanent = {
						order = 1,
						type = 'group',
						guiInline = true,
						name = PA.ACL['Permanent Moving'],
						args = {},
					},
					Reset = {
						order = 2,
						type = 'group',
						guiInline = true,
						name = PA.ACL['Reset Moving'],
						args = {},
					},
				},
			},
			AuthorHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -1,
				type = 'description',
				name = MF.Authors,
				fontSize = 'large',
			},
		},
	}

	sort(MF.AllFrames)

	for _, Name in pairs(MF.AllFrames) do
		PA.Options.args.MovableFrames.args.General.args.Permanent.args[Name] = {
			type = 'toggle',
			name = Name,
			get = function(info) return MF.db[info[#info]].Permanent end,
			set = function(info, value) MF.db[info[#info]].Permanent = value end,
		}

		PA.Options.args.MovableFrames.args.General.args.Reset.args[Name] = {
			type = 'execute',
			name = Name,
			disabled = function(info) return not MF.db[info[#info]].Permanent end,
			func = function(info) _G.HideUIPanel(_G[info[#info]]) end,
		}
	end
end

function MF:BuildProfile()
	PA.Defaults.profile.MovableFrames = { Enable = true }

	MF.AllFrames = {}

	if PA.Tukui then
		Frames.LossOfControlFrame = { "CENTER", "UIParent", "CENTER", 0, 60 }
	end

	for Frame, DefaultPoints in pairs(Frames) do
		tinsert(MF.AllFrames, Frame)
		PA.Defaults.profile.MovableFrames[Frame] = { Permanent = true, Points = DefaultPoints }
	end

	for _, Table in pairs(AddOnFrames) do
		for Frame, DefaultPoints in pairs(Table) do
			tinsert(MF.AllFrames, Frame)
			PA.Defaults.profile.MovableFrames[Frame] = { Permanent = true, Points = DefaultPoints }
		end
	end
end

function MF:Initialize()
	MF.db = PA.db.MovableFrames

	if MF.db.Enable ~= true then
		return
	end

	--if PA.SLE and _G.ElvUI[1].db.profile.soundQuest then
	--	_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'Kaliels Tracker Quest Sound and QuestSounds will make double sounds. Which one do you want to disable?\n\n(This does not disable Kaliels Tracker)'
	--	_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'KT Quest Sound'
	--	_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Quest Sounds'
	--	_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function()
	--		_G.StaticPopupDialogs.PROJECTAZILROKA.text = PA.ACL["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."]
	--		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = _G.ACCEPT
	--		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = _G.CANCEL
	--		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = _G.ReloadUI
	--		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = nil
	--	end
	--	_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() MF.db.Enable = false _G.ReloadUI() end
	--	_G.StaticPopup_Show("PROJECTAZILROKA")
	--	return
	--end

	if PA:IsAddOnEnabled('WorldQuestTracker') then
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

	--function ShowUIPanel(frame, force)
	--	if ( not frame or frame:IsShown() ) then
	--		return;
	--	end

	--	frame:Show();

	--	UpdateUIPanelPositions()
	--end

	--function HideUIPanel(frame, skipSetPoint)
	--	if ( not frame or not frame:IsShown() ) then
	--		return;
	--	end

	--	frame:Hide();

	--	UpdateUIPanelPositions()
	--end

	MF:Hook('UIParent_ManageFramePosition', function()
		for _, Frame in pairs(MF.AllFrames) do
			if _G[Frame] and _G[Frame]:IsShown() then
				MF:LoadPosition(_G[Frame])
			end
		end
	end, true)
end
