local PA = _G.ProjectAzilroka
local MF = PA:NewModule('MovableFrames', 'AceEvent-3.0', 'AceHook-3.0')
PA.MF, _G.MovableFrames = MF, MF

MF.Title = '|cFF16C3F2Movable|r |cFFFFFFFFFrames|r'
MF.Description = 'Make Blizzard Frames Movable'
MF.Authors = 'Azilroka    Simpy'

local pairs, unpack, tinsert, sort = pairs, unpack, tinsert, sort
local _G = _G
local IsAddOnLoaded = IsAddOnLoaded

local Frames = {
	["AddonList"] = { "CENTER", _G.UIParent, "CENTER", 0, 24 },
	["BankFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["CharacterFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["DressUpFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 70, -104 },
	["FriendsFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["FriendsFriendsFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 50 },
	["GameMenuFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["GhostFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, 0 },
	["GossipFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["GuildInviteFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["GuildRegistrarFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["HelpFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["InterfaceOptionsFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["ItemTextFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["LFGDungeonReadyDialog"] = { "TOPLEFT", _G.LFGDungeonReadyPopup, "TOPLEFT", 0, 0 },
	["LootFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["LossOfControlFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["MailFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["MerchantFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["OpenMailFrame"] = { "TOPLEFT", _G.UIParent, "TOPRIGHT", 0, 0 },
	["PetitionFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["PetStableFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, -104 },
	["PVEFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 100, -84 },
	["QuestFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["QuestLogPopupDetailFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, 0 },
	["RaidBrowserFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["RaidInfoFrame"] = { "TOPLEFT", "RaidFrame", "TOPRIGHT", 0, -27 },
	["RaidParentFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["ReadyCheckFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, -10 },
	["ScrollOfResurrectionSelectionFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["SpellBookFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["SplashFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 60 },
	["StaticPopup1"] = { "TOP", _G.UIParent, "TOP", 0, -135 },
	["StaticPopup2"] = { "TOP", _G.UIParent, "TOP", 0, -135 },
	["StaticPopup3"] = { "TOP", _G.UIParent, "TOP", 0, -135 },
	["StaticPopup4"] = { "TOP", _G.UIParent, "TOP", 0, -135 },
	["TabardFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["TaxiFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, -104 },
	["TimeManagerFrame"] = { "TOPRIGHT", _G.UIParent, "TOPRIGHT", -10, -190 },
	["TradeFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 },
	["VideoOptionsFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["WorldMapFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	["WorldStateScoreFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
}

local AddOnFrames = {
	['Blizzard_AchievementUI'] = {
		["AchievementFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 96, -116 }
	},
	['Blizzard_ArchaeologyUI'] = {
		["ArchaeologyFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_AuctionUI'] = {
		["AuctionFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, -104 }
	},
	['Blizzard_BarbershopUI'] = {
		["BarberShopFrame"] = { "RIGHT", _G.UIParent, "RIGHT", -18, -54 }
	},
	['Blizzard_BindingUI'] = {
		["KeyBindingFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 }
	},
	['Blizzard_BlackMarketUI'] = {
		["BlackMarketFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, -104 }
	},
	['Blizzard_Calendar'] = {
		["CalendarCreateEventFrame"] = { "TOPLEFT", _G.CalendarFrame, "TOPRIGHT", 3, -24 },
		["CalendarFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -96 },
		["CalendarViewEventFrame"] = { "TOPLEFT", _G.CalendarFrame, "TOPRIGHT", 3, -24 },
		["CalendarViewHolidayFrame"] = { "TOPLEFT", _G.CalendarFrame, "TOPRIGHT", 3, -24 },
	},
	['Blizzard_ChallengesUI'] = {
		['ChallengesKeystoneFrame'] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	},
	['Blizzard_Channels'] = {
		['ChannelFrame'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -96 },
	},
	['Blizzard_Collections'] = {
		["CollectionsJournal"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_Communities'] = {
		["CommunitiesFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	},
	['Blizzard_EncounterJournal'] = {
		["EncounterJournal"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 }
	},
	['Blizzard_GarrisonUI'] = {
		["GarrisonBuildingFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
		["GarrisonCapacitiveDisplayFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 27, -108 },
		["GarrisonLandingPage"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
		["GarrisonMissionFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
		["GarrisonRecruiterFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
		["GarrisonRecruitSelectFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
		["GarrisonShipyardFrame"] = { "CENTER", _G.UIParent, "CENTER", 0, 0 },
	},
	['Blizzard_GuildBankUI'] = {
		['GuildBankFrame'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 0, -104 }
	},
	['Blizzard_GuildControlUI'] = {
		['GuildControlUI'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_InspectUI'] = {
		["InspectFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_ItemSocketingUI'] = {
		["ItemSocketingFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_ItemUpgradeUI'] = {
		['ItemUpgradeFrame'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_LookingForGuildUI'] = {
		['LookingForGuildFrame'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_MacroUI'] = {
		['MacroFrame'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_OrderHallUI'] = {
		["OrderHallTalentFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 32, -116 }
	},
	['Blizzard_QuestChoice'] = {
		['QuestChoiceFrame'] = { "CENTER", _G.UIParent, "CENTER", 0, 0 }
	},
	['Blizzard_TalentUI'] = {
		["PlayerTalentFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 100, -84 }
	},
	['Blizzard_ScrappingMachineUI'] = {
		['ScrappingMachineFrame'] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_TalkingHeadUI'] = {
		["TalkingHeadFrame"] = { "BOTTOM", _G.UIParent, "BOTTOM", 0, 96 }
	},
	['Blizzard_TradeSkillUI'] = {
		["TradeSkillFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_TrainerUI'] = {
		["ClassTrainerFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
	['Blizzard_VoidStorageUI'] = {
		["VoidStorageFrame"] = { "TOPLEFT", _G.UIParent, "TOPLEFT", 16, -116 }
	},
}

function MF:LoadPosition(frame)
	if frame.isMoving then return end
	if (not _G.UnitAffectingCombat("player")) and (frame:IsUserPlaced()) then
		local a, b, c, d, e = unpack(MF.db[frame:GetName()]['Points'])
		frame:ClearAllPoints()
		frame:SetPoint(a, b, c, d, e, true)
	else
		frame:ClearAllPoints()
		frame:SetPoint(unpack(PA.Defaults.profile['MovableFrames'][frame:GetName()]['Points']))
	end
end

function MF:OnDragStart(frame)
	frame.isMoving = true
	frame:StartMoving()
end

function MF:OnDragStop(frame)
	frame:StopMovingOrSizing()
	local Name = frame:GetName()
	if MF.db[Name]['Permanent'] then
		local a, _, c, d, e = frame:GetPoint()
		local b = frame:GetParent():GetName() or _G.UIParent
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
	frame.isMoving = false
end

function MF:MakeMovable(Name)
	if not _G[Name] then
		return
	end

	local Frame = _G[Name]

	if Name == 'AchievementFrame' then _G.AchievementFrameHeader:EnableMouse(false) end

	Frame:EnableMouse(true)
	Frame:SetMovable(true)
	Frame:RegisterForDrag('LeftButton')
	Frame:SetClampedToScreen(true)

	self:HookScript(Frame, 'OnUpdate', 'LoadPosition')
	self:HookScript(Frame, 'OnDragStart', 'OnDragStart')
	self:HookScript(Frame, 'OnDragStop', 'OnDragStop')
	self:HookScript(Frame, 'OnHide', 'OnDragStop')

	self:SecureHook(Frame, 'SetPoint', function(_, _, _, _, _, locked)
		if not locked then
			MF:LoadPosition(Frame)
		end
	end)
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

	sort(MF.AllFrames)

	for _, Name in pairs(MF.AllFrames) do
		Options.args.permanent.args[Name] = {
			type = 'toggle',
			name = Name,
			get = function(info) return MF.db[info[#info]]['Permanent'] end,
			set = function(info, value) MF.db[info[#info]]['Permanent'] = value end,
		}

		Options.args.reset.args[Name] = {
			type = 'execute',
			name = Name,
			disabled = function(info) return not MF.db[info[#info]]['Permanent'] end,
			func = function(info) _G.HideUIPanel(_G[info[#info]]) end,
		}
	end

	PA.Options.args.MovableFrames = Options
end

function MF:BuildProfile()
	PA.Defaults.profile['MovableFrames'] = { ['Enable'] = true }

	self.AllFrames = {}

	if PA.Tukui then
		Frames['LossOfControlFrame'] = { "CENTER", _G.UIParent, "CENTER", 0, 60 }
	end

	for Frame, DefaultPoints in pairs(Frames) do
		tinsert(self.AllFrames, Frame)
		PA.Defaults.profile['MovableFrames'][Frame] = { ['Permanent'] = true, ['Points'] = DefaultPoints }
	end

	for _, Table in pairs(AddOnFrames) do
		for Frame, DefaultPoints in pairs(Table) do
			tinsert(self.AllFrames, Frame)
			PA.Defaults.profile['MovableFrames'][Frame] = { ['Permanent'] = true, ['Points'] = DefaultPoints }
		end
	end

	PA.Options.args.general.args.MovableFrames = {
		type = 'toggle',
		name = MF.Title,
		desc = MF.Description,
	}
end

function MF:Initialize()
	MF.db = PA.db['MovableFrames']

	if MF.db.Enable ~= true then
		return
	end

	MF:GetOptions()

	if PA:IsAddOnEnabled('WorldQuestTracker') then
		Frames["WorldMapFrame"] = nil
	end

	if PA.ElvUI then
		AddOnFrames['Blizzard_TalkingHeadUI'] = nil
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

	MF:Hook('UIParent_ManageFramePosition', function()
		for _, Frame in pairs(MF.AllFrames) do
			if _G[Frame] and _G[Frame]:IsShown() then
				MF:LoadPosition(_G[Frame])
			end
		end
	end, true)
end
