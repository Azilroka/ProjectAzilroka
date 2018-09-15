local PA = _G.ProjectAzilroka
local MF = PA:NewModule('MovableFrames', 'AceEvent-3.0', 'AceHook-3.0')
PA.MF, _G.MovableFrames = MF, MF

MF.Title = '|cFF16C3F2Movable|r |cFFFFFFFFFrames|r'
MF.Desciption = 'Make Blizzard Frames Movable'
MF.Authors = 'Azilroka    Simpy'

ExportData = {}

local pairs, unpack, tinsert, sort = pairs, unpack, tinsert, sort
local _G = _G
local IsAddOnLoaded, C_Timer = IsAddOnLoaded, C_Timer

local Frames = {
	["AddonList"] = { "CENTER", "UIParent", "CENTER", 0, 24 },
	["BankFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["CharacterFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["DressUpFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 70, -104 },
	["FriendsFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["FriendsFriendsFrame"] = { "CENTER", "UIParent", "CENTER", 0, 50 },
	["GameMenuFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["GhostFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, 0 },
	["GossipFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["GuildInviteFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["GuildRegistrarFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["HelpFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["InterfaceOptionsFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["ItemTextFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["LFGDungeonReadyDialog"] = { "TOPLEFT", "LFGDungeonReadyPopup", "TOPLEFT", 0, 0 },
	["LootFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["LossOfControlFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["MailFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["MerchantFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["OpenMailFrame"] = { "TOPLEFT", "UIParent", "TOPRIGHT", 0, 0 },
	["PetitionFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["PetStableFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 },
	["PVEFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 100, -84 },
	["QuestFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["QuestLogPopupDetailFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, 0 },
	["RaidBrowserFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["RaidInfoFrame"] = { "TOPLEFT", "RaidFrame", "TOPRIGHT", 0, -27 },
	["RaidParentFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["ReadyCheckFrame"] = { "CENTER", "UIParent", "CENTER", 0, -10 },
	["ScrollOfResurrectionSelectionFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["SpellBookFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["SplashFrame"] = { "CENTER", "UIParent", "CENTER", 0, 60 },
	["StaticPopup1"] = { "TOP", "UIParent", "TOP", 0, -135 },
	["StaticPopup2"] = { "TOP", "UIParent", "TOP", 0, -135 },
	["StaticPopup3"] = { "TOP", "UIParent", "TOP", 0, -135 },
	["StaticPopup4"] = { "TOP", "UIParent", "TOP", 0, -135 },
	["TabardFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["TaxiFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 },
	["TimeManagerFrame"] = { "TOPRIGHT", "UIParent", "TOPRIGHT", -10, -190 },
	["TradeFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 },
	["VideoOptionsFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["WorldMapFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	["WorldStateScoreFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
}

local AddOnFrames = {
	['Blizzard_AchievementUI'] = {
		["AchievementFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 96, -116 }
	},
	['Blizzard_ArchaeologyUI'] = {
		["ArchaeologyFrame"] = { "TOPLEFT", "IParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_AuctionUI'] = {
		["AuctionFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	['Blizzard_BarbershopUI'] = {
		["BarberShopFrame"] = { "RIGHT", "UIParent", "RIGHT", -18, -54 }
	},
	['Blizzard_BindingUI'] = {
		["KeyBindingFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	['Blizzard_BlackMarketUI'] = {
		["BlackMarketFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	['Blizzard_Calendar'] = {
		["CalendarCreateEventFrame"] = { "TOPLEFT", "CalendarFrame", "TOPRIGHT", 3, -24 },
		["CalendarFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -96 },
		["CalendarViewEventFrame"] = { "TOPLEFT", "CalendarFrame", "TOPRIGHT", 3, -24 },
		["CalendarViewHolidayFrame"] = { "TOPLEFT", "CalendarFrame", "TOPRIGHT", 3, -24 },
	},
	['Blizzard_ChallengesUI'] = {
		['ChallengesKeystoneFrame'] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	},
	['Blizzard_Collections'] = {
		["CollectionsJournal"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_Communities'] = {
		["CommunitiesFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	},
	['Blizzard_EncounterJournal'] = {
		["EncounterJournal"] = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	['Blizzard_GarrisonUI'] = {
		["GarrisonBuildingFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
		["GarrisonCapacitiveDisplayFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 27, -108 },
		["GarrisonLandingPage"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
		["GarrisonMissionFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
		["GarrisonRecruiterFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
		["GarrisonRecruitSelectFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
		["GarrisonShipyardFrame"] = { "CENTER", "UIParent", "CENTER", 0, 0 },
	},
	['Blizzard_GuildBankUI'] = {
		['GuildBankFrame'] = { "TOPLEFT", "UIParent", "TOPLEFT", 0, -104 }
	},
	['Blizzard_GuildControlUI'] = {
		['GuildControlUI'] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_InspectUI'] = {
		["InspectFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_ItemSocketingUI'] = {
		["ItemSocketingFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_ItemUpgradeUI'] = {
		['ItemUpgradeFrame'] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_LookingForGuildUI'] = {
		['LookingForGuildFrame'] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_MacroUI'] = {
		['MacroFrame'] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_OrderHallUI'] = {
		["OrderHallTalentFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 32, -116 }
	},
	['Blizzard_QuestChoice'] = {
		['QuestChoiceFrame'] = { "CENTER", "UIParent", "CENTER", 0, 0 }
	},
	['Blizzard_TalentUI'] = {
		["PlayerTalentFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 100, -84 }
	},
	['Blizzard_ScrappingMachineUI'] = {
		['ScrappingMachineFrame'] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_TalkingHeadUI'] = {
		["TalkingHeadFrame"] = { "BOTTOM", "UIParent", "BOTTOM", 0, 96 }
	},
	['Blizzard_TradeSkillUI'] = {
		["TradeSkillFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_TrainerUI'] = {
		["ClassTrainerFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
	['Blizzard_VoidStorageUI'] = {
		["VoidStorageFrame"] = { "TOPLEFT", "UIParent", "TOPLEFT", 16, -116 }
	},
}

function MF:LoadPosition(frame)
	if (not UnitAffectingCombat("player")) and frame:IsUserPlaced() then
		frame:ClearAllPoints()
		frame:SetPoint(unpack(MF.db[frame:GetName()]['Points']))
	end
end

function MF:OnDragStart(frame)
	self:Unhook(frame, 'OnUpdate')
	frame:StartMoving()
end

function MF:OnDragStop(frame)
	frame:StopMovingOrSizing()
	local Name = frame:GetName()
	if MF.db[Name]['Permanent'] then
		local a, _, c, d, e = frame:GetPoint()
		local b = frame:GetParent():GetName()
		if Name == 'QuestFrame' or Name == 'GossipFrame' then
			MF.db['GossipFrame'].Points = {a, b, c, d, e}
			MF.db['QuestFrame'].Points = {a, b, c, d, e}
		else
			MF.db[Name].Points = {a, b, c, d, e}
		end
		frame:SetUserPlaced(true)
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
end

function MF:ADDON_LOADED(_, addon)
	if AddOnFrames[addon] then
		for Frame in pairs(AddOnFrames[addon]) do
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

	Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(MF.data)
	Options.args.profiles.order = -2

	PA.Options.args.MovableFrames = Options
end

function MF:BuildProfile()
	self.AllFrames = {}

	local Defaults = { profile = {} }

	for Frame, DefaultPoints in pairs(Frames) do
		tinsert(self.AllFrames, Frame)
		Defaults.profile[Frame] = { ['Permanent'] = true, ['Points'] = DefaultPoints }
	end

	for _, Table in pairs(AddOnFrames) do
		for Frame, DefaultPoints in pairs(Table) do
			tinsert(self.AllFrames, Frame)
			Defaults.profile[Frame] = { ['Permanent'] = true, ['Points'] = DefaultPoints }
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
