local AddOnName, NS = ...
local Title = select(2, GetAddOnInfo(AddOnName))
local Version = GetAddOnMetadata(AddOnName, 'Version')
local EP, Ace3OptionsPanel

local MovableFrame = CreateFrame('Frame')

MovableFramesSaved = {}

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
	'LossOfControlFrame',
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

local Options = {
	order = 100,
	type = 'group',
	name = Title,
	args = {
		permanent = {
			order = 1,
			type = 'group',
			name = 'Permanent Moving',
			guiInline = true,
			args = {},
		},
		reset = {
			order = 2,
			type = 'group',
			name = 'Reset Moving',
			args = {},
		},
	},
}

local function OnUpdate(self)
	if self.IsMoving then return end
	if MovableFramesSaved[self:GetName()]['Points'] then
		self:ClearAllPoints()
		self:SetPoint(unpack(MovableFramesSaved[self:GetName()]['Points']))
	end
end

local function OnDragStart(self)
	self:StartMoving()
	self.IsMoving = true
	if not MovableFramesSaved[self:GetName()]['Permanent'] then self:SetUserPlaced(false) end
end

local function OnDragStop(self)
	self:StopMovingOrSizing()
	self.IsMoving = false
	if MovableFramesSaved[self:GetName()]['Permanent'] then
		local a, b, c, d, e = self:GetPoint()
		b = self:GetParent():GetName()
		if self:GetName() == 'QuestFrame' or self:GetName() == 'GossipFrame' then
			MovableFramesSaved['GossipFrame'].Points = {a, b, c, d, e}
			MovableFramesSaved['QuestFrame'].Points = {a, b, c, d, e}
		else
			MovableFramesSaved[self:GetName()].Points = {a, b, c, d, e}
		end
	end
end

local Index = 0
function MovableFrame:MakeMovable(Frame)
	local Name = Frame:GetName()
	if IsAddOnLoaded('ElvUI') and Name == 'LossOfControlFrame' then return end

	if MovableFramesSaved[Name] == nil then MovableFramesSaved[Name] = {} end
	if MovableFramesSaved[Name]['Permanent'] == nil then MovableFramesSaved[Name]['Permanent'] = false end

	Options.args.permanent.args[Name] = {
		order = Index,
		type = 'toggle',
		name = Name,
		get = function(info) return MovableFramesSaved[info[#info]]['Permanent'] end,
		set = function(info, value) MovableFramesSaved[info[#info]]['Permanent'] = value end,
	}
	Options.args.reset.args[Name] = {
		order = Index,
		type = 'execute',
		name = Name,
		disabled = function() return not MovableFramesSaved[Name]['Permanent'] end,
		func = function() MovableFramesSaved[Name]['Points'] = nil end,
	}

	if Ace3OptionsPanel then -- Refresh the table
		Ace3OptionsPanel.Options.args.movableframes = CopyTable(Options)
	end

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
end

function MovableFrame:GetOptions()
	Ace3OptionsPanel = IsAddOnLoaded('ElvUI') and ElvUI[1] or Enhanced_Config[1]
	Ace3OptionsPanel.Options.args.movableframes = CopyTable(Options)
end

MovableFrame:RegisterEvent('PLAYER_LOGIN')
MovableFrame:SetScript('OnEvent', function(self, event, addon)
	if event == 'PLAYER_LOGIN' then
		self:RegisterEvent('ADDON_LOADED')
		EP = LibStub('LibElvUIPlugin-1.0', true)

		if EP then
			EP:RegisterPlugin(AddOnName, self.GetOptions)
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
			MovableFrame:MakeMovable(_G['WorldStateCaptureBar'..id])
			_G['WorldStateCaptureBar'..id].MoverAssigned = true
		end)
	end
	if event == 'ADDON_LOADED' then
		if AddOnFrames[addon] then
			for _, Frame in pairs(AddOnFrames[addon]) do
				self:MakeMovable(_G[Frame])
			end
		end
	end
end)