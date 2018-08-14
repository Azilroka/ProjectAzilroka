local PA = _G.ProjectAzilroka
local MF = PA:NewModule('MovableFrames', 'AceEvent-3.0', 'AceHook-3.0')
PA.MF, _G.MovableFrames = MF, MF

MF.Title = '|cFF16C3F2Movable|r |cFFFFFFFFFrames|r'
MF.Desciption = 'Make Blizzard Frames Movable'
MF.Authors = 'Azilroka    Simpy'

local pairs, unpack, tinsert, sort = pairs, unpack, tinsert, sort
local _G = _G
local IsAddOnLoaded, C_Timer = IsAddOnLoaded, C_Timer

local Frames = {
	'AddonList',
	'AudioOptionsFrame',
	'BankFrame',
	'BonusRollFrame',
	'BonusRollLootWonFrame',
	'BonusRollMoneyWonFrame',
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
	'LFDRoleCheckPopup',
	'LFGDungeonReadyDialog',
	'LFGDungeonReadyStatus',
	'LootFrame',
	'MailFrame',
	'MerchantFrame',
	'OpenMailFrame',
	'PetitionFrame',
	'PetStableFrame',
	'PVEFrame',
--	'PVPReadyDialog',
	'QuestFrame',
	'QuestLogPopupDetailFrame',
	'RaidBrowserFrame',
	'RaidInfoFrame',
	'RaidParentFrame',
	'ReadyCheckFrame',
	'ReportCheatingDialog',
	'RolePollPopup',
	'ScrollOfResurrectionSelectionFrame',
	'SpellBookFrame',
	'SplashFrame',
	'StackSplitFrame',
	'StaticPopup1',
	'StaticPopup2',
	'StaticPopup3',
	'StaticPopup4',
	'TabardFrame',
	'TaxiFrame',
	'TimeManagerFrame',
	'TradeFrame',
	'TutorialFrame',
	'VideoOptionsFrame',
	'WorldMapFrame',
	'WorldStateScoreFrame',
}

local AddOnFrames = {
	['Blizzard_AchievementUI'] = { 'AchievementFrame' },
	['Blizzard_ArchaeologyUI'] = { 'ArchaeologyFrame' },
	['Blizzard_AuctionUI'] = { 'AuctionFrame' },
	['Blizzard_BarberShopUI'] = { 'BarberShopFrame' },
	['Blizzard_BindingUI'] = { 'KeyBindingFrame' },
	['Blizzard_BlackMarketUI'] = { 'BlackMarketFrame' },
	['Blizzard_Calendar'] = { 'CalendarCreateEventFrame', 'CalendarFrame', 'CalendarViewEventFrame', 'CalendarViewHolidayFrame' },
	['Blizzard_ChallengesUI'] = { 'ChallengesKeystoneFrame' }, -- 'ChallengesLeaderboardFrame'
	['Blizzard_Collections'] = { 'CollectionsJournal' },
	['Blizzard_Communities'] = { 'CommunitiesFrame'},
	['Blizzard_EncounterJournal'] = { 'EncounterJournal' },
	['Blizzard_GarrisonUI'] = { 'GarrisonLandingPage', 'GarrisonMissionFrame', 'GarrisonCapacitiveDisplayFrame', 'GarrisonBuildingFrame', 'GarrisonRecruiterFrame', 'GarrisonRecruitSelectFrame', 'GarrisonShipyardFrame' },
	['Blizzard_GMChatUI'] = { 'GMChatStatusFrame' },
	['Blizzard_GMSurveyUI'] = { 'GMSurveyFrame' },
	['Blizzard_GuildBankUI'] = { 'GuildBankFrame' },
	['Blizzard_GuildControlUI'] = { 'GuildControlUI' },
	['Blizzard_GuildUI'] = { 'GuildFrame', 'GuildLogFrame' },
	['Blizzard_InspectUI'] = { 'InspectFrame' },
	['Blizzard_ItemAlterationUI'] = { 'TransmogrifyFrame' },
	['Blizzard_ItemSocketingUI'] = { 'ItemSocketingFrame' },
	['Blizzard_ItemUpgradeUI'] = { 'ItemUpgradeFrame' },
	['Blizzard_LookingForGuildUI'] = { 'LookingForGuildFrame' },
	['Blizzard_MacroUI'] = { 'MacroFrame' },
	['Blizzard_OrderHallUI'] = { 'OrderHallTalentFrame' },
	['Blizzard_QuestChoice'] = { 'QuestChoiceFrame' },
	['Blizzard_TalentUI'] = { 'PlayerTalentFrame' },
	['Blizzard_TalkingHeadUI'] = { 'TalkingHeadFrame' },
	['Blizzard_TradeSkillUI'] = { 'TradeSkillFrame' },
	['Blizzard_TrainerUI'] = { 'ClassTrainerFrame' },
	['Blizzard_VoidStorageUI'] = { 'VoidStorageFrame' },
}

local SpecialFrame = {
	"GameMenuFrame",
	"VideoOptionsFrame",
	"AudioOptionsFrame",
	"InterfaceOptionsFrame",
	"HelpFrame",
}

function MF:LoadPosition(frame)
	local Name = frame:GetName()

	if not frame:GetPoint() then
		frame:SetPoint('TOPLEFT', 'UIParent', 'TOPLEFT', 16, -116)
	end

	if MF.db[Name] and MF.db[Name]['Permanent'] and MF.db[Name]['Points'] then
		frame:ClearAllPoints()
		frame:SetPoint(unpack(MF.db[Name]['Points']))
	end
end

function MF:OnDragStart(frame)
	self:Unhook(frame, 'OnUpdate')
	frame:StartMoving()
end

function MF:OnDragStop(frame)
	frame:StopMovingOrSizing()
	local Name = frame:GetName()
	if MF.db[Name] and MF.db[Name]['Permanent'] then
		local a, _, c, d, e = frame:GetPoint()
		local b = frame:GetParent():GetName() or 'UIParent'
		if Name == 'QuestFrame' or Name == 'GossipFrame' then
			MF.db['GossipFrame'].Points = {a, b, c, d, e}
			MF.db['QuestFrame'].Points = {a, b, c, d, e}
		else
			MF.db[Name].Points = {a, b, c, d, e}
		end
	else
		frame:SetUserPlaced(false)
	end
	if (not self:IsHooked(frame, 'OnUpdate')) then
		self:HookScript(frame, 'OnUpdate', 'LoadPosition')
	end
end

function MF:MakeMovable(Name)
	if not _G[Name] then
		PA:Print(PA.ACL["Frame doesn't exist: "]..Name)
		return
	end

	local Frame = _G[Name]

	if Name == 'AchievementFrame' then AchievementFrameHeader:EnableMouse(false) end

	Frame:EnableMouse(true)
	Frame:SetMovable(true)
	Frame:RegisterForDrag('LeftButton')
	Frame:SetClampedToScreen(true)
	self:HookScript(Frame, 'OnUpdate', 'LoadPosition')
	self:HookScript(Frame, 'OnDragStart', 'OnDragStart')
	self:HookScript(Frame, 'OnDragStop', 'OnDragStop')
	self:HookScript(Frame, 'OnHide', 'OnDragStop')

	if not tContains(SpecialFrame, Name) then
		SetUIPanelAttribute(Frame, 'area', nil)
		tinsert(UISpecialFrames, Name)
	end

	C_Timer.After(0, function()
		if MF.db[Name] and MF.db[Name]['Permanent'] == true and MF.db[Name]['Points'] then
			Frame:ClearAllPoints()
			Frame:SetPoint(unpack(MF.db[Name]['Points']))
		end
	end)
end

function MF:ADDON_LOADED(_, addon)
	if AddOnFrames[addon] then
		for _, Frame in pairs(AddOnFrames[addon]) do
			self:MakeMovable(Frame)
		end
	end
end

function MF:GetOptions()
	local Options = {
		order = 209,
		type = 'group',
		name = MF.Title,
		desc = MF.Desciption,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(MF.Title),
			},
			permanent = {
				order = 1,
				type = 'group',
				guiInline = true,
				name = PA.ACL['Permanent Moving'],
				args = {},
			},
			reset = {
				order = 2,
				type = 'group',
				guiInline = true,
				name = PA.ACL['Reset Moving'],
				args = {},
			},
			AuthorHeader = {
				order = 3,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = 4,
				type = 'description',
				name = MF.Authors,
				fontSize = 'large',
			},
		},
	}

	sort(self.AllFrames)

	local Index = 1
	for _, Name in pairs(self.AllFrames) do
		Options.args.permanent.args[Name] = {
			order = Index,
			type = 'toggle',
			name = Name,
			get = function(info) return MF.db[info[#info]]['Permanent'] end,
			set = function(info, value) MF.db[info[#info]]['Permanent'] = value end,
		}

		Options.args.reset.args[Name] = {
			order = Index,
			type = 'execute',
			name = Name,
			disabled = function(info) return not MF.db[info[#info]]['Permanent'] end,
			func = function(info) HideUIPanel(_G[info[#info]]) end,
		}

		Index = Index + 1
	end

	self.AllFrames = nil

	Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(MF.data)
	Options.args.profiles.order = -2

	PA.Options.args.MovableFrames = Options
end

function MF:BuildProfile()
	self.AllFrames = CopyTable(Frames)

	for _, Table in pairs(AddOnFrames) do
		for _, Frame in pairs(Table) do
			tinsert(self.AllFrames, Frame)
		end
	end

	local Defaults = { profile = {} }

	for _, Frame in pairs(self.AllFrames) do
		if not Defaults.profile[Frame] then
			Defaults.profile[Frame] = { ['Permanent'] = true }
		end
	end

	self.data = PA.ADB:New('MovableFramesDB', Defaults)
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function MF:SetupProfile()
	self.db = self.data.profile
end

function MF:Initialize()
	if PA.Tukui then
		tinsert(Frames, 'LossOfControlFrame')
		sort(Frames)
	end

	MF:BuildProfile()
	MF:GetOptions()

	for i = 1, #Frames do
		MF:MakeMovable(Frames[i])
	end

	-- Check Forced Loaded AddOns
	for AddOn, Table in pairs(AddOnFrames) do
		if IsAddOnLoaded(AddOn) then
			for _, Frame in pairs(Table) do
				MF:MakeMovable(Frame)
			end
		end
	end
--[[
	hooksecurefunc(ExtendedUI['CAPTUREPOINT'], 'create', function(id)
		if _G['WorldStateCaptureBar'..id].MoverAssigned then return end
		MF:MakeMovable(_G['WorldStateCaptureBar'..id])
		_G['WorldStateCaptureBar'..id].MoverAssigned = true
	end)
]]
	MF:RegisterEvent('ADDON_LOADED')
end
