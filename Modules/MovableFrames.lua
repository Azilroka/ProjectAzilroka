local PA = _G.ProjectAzilroka
local MF = LibStub('AceAddon-3.0'):NewAddon('MovableFrames', 'AceEvent-3.0')
_G.MovableFrames = MF

MF.Title = '|cFFFFFFFFMovableFrames|r'
MF.Authors = 'Azilroka    Simpy'
MF.Version = 1.84

local pairs, unpack, tinsert, sort = pairs, unpack, tinsert, sort
local _G = _G
local IsAddOnLoaded = IsAddOnLoaded

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
	'PVPReadyDialog',
	'QuestFrame',
	'QuestLogPopupDetailFrame',
	'RaidBrowserFrame',
	'RaidParentFrame',
	'ReadyCheckFrame',
	'ReportCheatingDialog',
	'ReportPlayerNameDialog',
	'RolePollPopup',
	'ScrollOfResurrectionSelectionFrame',
	'SpellBookFrame',
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
	'WorldStateAlwaysUpFrame',
	'WorldStateScoreFrame',
}

local AddOnFrames = {
	['Blizzard_AchievementUI'] = { 'AchievementFrame' },
	['Blizzard_ArchaeologyUI'] = { 'ArchaeologyFrame' },
	['Blizzard_AuctionUI'] = { 'AuctionFrame' },
	['Blizzard_BarberShopUI'] = { 'BarberShopFrame' },
	['Blizzard_BindingUI'] = { 'KeyBindingFrame' },
	['Blizzard_BlackMarketUI'] = { 'BlackMarketFrame' },
	['Blizzard_ChallengesUI'] = { 'ChallengesKeystoneFrame' },
	['Blizzard_Calendar'] = { 'CalendarCreateEventFrame', 'CalendarFrame', 'CalendarViewEventFrame', 'CalendarViewHolidayFrame' },
	['Blizzard_Collections'] = { 'CollectionsJournal' },
	['Blizzard_EncounterJournal'] = { 'EncounterJournal' },
	['Blizzard_GarrisonUI'] = { 'GarrisonMissionFrame', 'GarrisonCapacitiveDisplayFrame', 'GarrisonLandingPage'	},
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
	['Blizzard_QuestChoice'] = { 'QuestChoiceFrame' },
	['Blizzard_TradeSkillUI'] = { 'TradeSkillFrame' },
	['Blizzard_TalentUI'] = { 'PlayerTalentFrame'},
	['Blizzard_TrainerUI'] = { 'ClassTrainerFrame' },
	['Blizzard_VoidStorageUI'] = { 'VoidStorageFrame' },
}

local function OnUpdate(self)
	if self.IsMoving then return end
	if MF.db[self:GetName()]['Points'] then
		self:ClearAllPoints()
		self:SetPoint(unpack(MF.db[self:GetName()]['Points']))
	end
end

local function OnDragStart(self)
	self:StartMoving()
	self.IsMoving = true
	if not MF.db[self:GetName()]['Permanent'] then self:SetUserPlaced(false) end
end

local function OnDragStop(self)
	self:StopMovingOrSizing()
	self.IsMoving = false
	if MF.db[self:GetName()]['Permanent'] then
		local a, b, c, d, e = self:GetPoint()
		b = self:GetParent():GetName()
		if self:GetName() == 'QuestFrame' or self:GetName() == 'GossipFrame' then
			MF.db['GossipFrame'].Points = {a, b, c, d, e}
			MF.db['QuestFrame'].Points = {a, b, c, d, e}
		else
			MF.db[self:GetName()].Points = {a, b, c, d, e}
		end
	end
end

local Index = 0
function MF:MakeMovable(Frame)
	local Name = Frame:GetName()

	if not Name then return end

	if Name == 'AchievementFrame' then AchievementFrameHeader:EnableMouse(false) end

	Frame:EnableMouse(true)
	Frame:SetMovable(true)
	Frame:RegisterForDrag('LeftButton')
	Frame:SetClampedToScreen(true)
	Frame:HookScript('OnUpdate', OnUpdate)
	Frame:HookScript('OnDragStart', OnDragStart)
	Frame:HookScript('OnDragStop', OnDragStop)
	if Name == 'WorldStateAlwaysUpFrame' then
		Frame:HookScript('OnEnter', function(self) self:SetTemplate() end)
		Frame:HookScript('OnLeave', function(self) self:StripTextures() end)
	end

	if PA.EP then
		if MF.db[Name] == nil then MF.db[Name] = {} end
		if MF.db[Name]['Permanent'] == nil then MF.db[Name]['Permanent'] = false end

		PA.AceOptionsPanel.Options.args.movableframes.args.permanent.args[Name] = {
			order = Index,
			type = 'toggle',
			name = Name,
			get = function(info) return MF.db[info[#info]]['Permanent'] end,
			set = function(info, value) MF.db[info[#info]]['Permanent'] = value end,
		}

		PA.AceOptionsPanel.Options.args.movableframes.args.reset.args[Name] = {
			order = Index,
			type = 'execute',
			name = Name,
			disabled = function() return not MF.db[Name]['Permanent'] end,
			func = function() MF.db[Name]['Points'] = nil end,
		}

		Index = Index + 1
	end
end

function MF:GetOptions()
	local Options = {
		order = 100,
		type = 'group',
		name = MF.Title,
		childGroups = 'tab',
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = format('%s |cFFFFFFFF - Version: %s|r', MF.Title, MF.Version),
			},
			permanent = {
				order = 1,
				type = 'group',
				name = 'Permanent Moving',
				args = {},
			},
			reset = {
				order = 2,
				type = 'group',
				name = 'Reset Moving',
				args = {},
			},
			about = {
				type = 'group',
				name = 'About/Help',
				order = -2,
				args = {
					AuthorHeader = {
						order = 0,
						type = 'header',
						name = 'Authors:',
					},
					Authors = {
						order = 1,
						type = 'description',
						name = MF.Authors,
						fontSize = 'large',
					},
				},
			},
		},
	}

	PA.AceOptionsPanel.Options.args.movableframes = Options
end

function MF:SetupProfile()
	self.data = LibStub('AceDB-3.0'):New('MovableFramesDB', { profile = {}, })
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function MF:ADDON_LOADED(event, addon)
	if AddOnFrames[addon] then
		for _, Frame in pairs(AddOnFrames[addon]) do
			self:MakeMovable(_G[Frame])
		end
	end
end

function MF:PLAYER_LOGIN()
	self:SetupProfile()
	self:RegisterEvent('ADDON_LOADED')

	if IsAddOnLoaded('Tukui') then
		tinsert(Frames, 'LossOfControlFrame')
		sort(Frames)
	end

	if PA.EP then
		PA.EP:RegisterPlugin("ProjectAzilroka", self.GetOptions)
	end

	for _, Frame in pairs(Frames) do
		if _G[Frame] then
			self:MakeMovable(_G[Frame])
		end
	end

	-- Check Forced Loaded AddOns
	for AddOn, Table in pairs(AddOnFrames) do
		if IsAddOnLoaded(AddOn) then
			for _, Frame in pairs(Table) do
				self:MakeMovable(_G[Frame])
			end
		end
	end

	hooksecurefunc(ExtendedUI['CAPTUREPOINT'], 'create', function(id)
		if _G['WorldStateCaptureBar'..id].MoverAssigned then return end
		MF:MakeMovable(_G['WorldStateCaptureBar'..id])
		_G['WorldStateCaptureBar'..id].MoverAssigned = true
	end)
end

MF:RegisterEvent('PLAYER_LOGIN')
