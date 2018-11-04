local PA = _G.ProjectAzilroka
local RR = PA:NewModule('ReputationReward', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
PA.RR = RR

local _G = _G
local floor = floor
local pairs = pairs
local select = select
local tinsert = tinsert
local wipe = wipe
local format = format

local CreateFrame = _G.CreateFrame
local GetFactionInfo = _G.GetFactionInfo
local GetFactionInfoByID = _G.GetFactionInfoByID
local GetNumFactions = _G.GetNumFactions
local GetNumQuestLogRewardFactions = _G.GetNumQuestLogRewardFactions
local GetQuestLogRewardFactionInfo = _G.GetQuestLogRewardFactionInfo
local UnitAura = _G.UnitAura
local Immersion

RR.Title = '|cFF16C3F2Reputation|r|cFFFFFFFFRewards|r'
RR.Description = 'Adds Reputation into Quest Log & Quest Frame.'
RR.Authors = 'Azilroka'
RR.Credits = 'jayd'

function RR:BuildFactionHeaders()
	RR.FactionHeaders = {}

	local numFactions, CollapsedHeaders, header = GetNumFactions(), {}

	local i = 1

	while i <= numFactions do
		local _, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, _, factionID = GetFactionInfo(i)

		if isHeader and isCollapsed then
			CollapsedHeaders[#CollapsedHeaders + 1] = i
			ExpandFactionHeader(i)
			numFactions = GetNumFactions()
		end

		if isHeader then
			header = factionID
		end

		if factionID and header then
			RR.FactionHeaders[factionID] = header
		end

		i = i + 1
	end

	if #CollapsedHeaders > 0 then
		for k = #CollapsedHeaders, 1, -1 do
			CollapseFactionHeader(CollapsedHeaders[k])
		end
	end
end

function RR:GetFactionHeader(factionID)
	return RR.FactionHeaders[factionID]
end

function RR:GetBonusReputation(amtBase, factionID)
	local mult = PA.MyRace == 'Human' and 1.1 or 1
	local rep = amtBase

	if factionID == 609 or factionID == 576 or factionID == 529 then
		rep = rep * 2
	elseif factionID == 59 then
		rep = rep * 4
	end

	for i = 1, 40 do
		local ID = select(11, UnitAura('player', i))
		if not ID then break end
		if RR.AuraInfo[ID] and ((RR.AuraInfo[ID].faction == factionID) or (RR.AuraInfo[ID].faction == 0)) then
			mult = mult + RR.AuraInfo[ID].bonus
		end
	end

	local hasBonusRepGain = select(15, GetFactionInfoByID(factionID))
	if hasBonusRepGain then
		mult = mult * 2
	end

	return (rep * mult) - rep
end

function RR:Show()
	local numRepFactions = GetNumQuestLogRewardFactions()
	if numRepFactions == 0 then
		ReputationRewardsFrame:Hide()
		return
	end

	wipe(RR.ReputationInfo)

	for i = 1, numRepFactions do
		local factionID, amtBase = GetQuestLogRewardFactionInfo(i)

		local factionName, _, _, _, _, _, AtWar, ToggleAtWar, isHeader = GetFactionInfoByID(factionID)

		if factionName and (AtWar and ToggleAtWar or (not AtWar)) then
			amtBase = floor(amtBase / 100)

			local amtBonus = RR:GetBonusReputation(amtBase, factionID)

			RR.ReputationInfo[factionID] = { Name = factionName, Base = amtBase, Bonus = amtBonus, Header = isHeader, FactionID = factionID, Child = RR:GetFactionHeader(factionID) }
		end
	end

	for _, Info in pairs(RR.ReputationInfo) do
		if (Info.FactionID ~= RR:GetFactionHeader(Info.Child)) and (Info.Child == RR:GetFactionHeader(Info.FactionID)) and (Info.Base == (RR.ReputationInfo[Info.Child] and RR.ReputationInfo[Info.Child].Base or 0)) then
			RR.ReputationInfo[Info.FactionID] = nil
		end
	end

	local QuestString, NumShown = nil, 0
	for _, Info in pairs(RR.ReputationInfo) do
		local Color = Info.Base < 0 and "|cEFF00000" or "|cFFFFFFFF"

		local String = Info.Bonus ~= 0 and format(RR.ReputationBonusString, Info.Name, Color, (Info.Base + Info.Bonus), Info.Base, Info.Bonus) or format(RR.ReputationString, Info.Name, Color, Info.Base)

		if not QuestString then
			QuestString = String
		else
			QuestString = QuestString..'\n'..String
		end

		NumShown = NumShown + 1
	end

	if NumShown == 0 then return end

	ReputationRewardsFrame.Description:SetHeight((NumShown * 12) + 10)
	ReputationRewardsFrame.Description:SetText(QuestString)
	ReputationRewardsFrame:SetHeight((NumShown * 12) + 30)

	ReputationRewardsFrame:ClearAllPoints()

	if Immersion and ImmersionContentFrame.RewardsFrame then
		ReputationRewardsFrame:SetParent(ImmersionContentFrame.RewardsFrame)
		ReputationRewardsFrame:SetPoint('TOPLEFT', ImmersionContentFrame.RewardsFrame, 'TOPRIGHT', -1, 0)
	elseif QuestInfoFrame.mapView then
		ReputationRewardsFrame:SetParent(QuestInfoDescriptionText:GetParent())
		ReputationRewardsFrame:SetPoint('TOPLEFT', QuestInfoDescriptionText, 'BOTTOMLEFT', 0, -10)
	elseif QuestInfoFrame.rewardsFrame then
		ReputationRewardsFrame:SetParent(QuestInfoFrame.rewardsFrame)
		ReputationRewardsFrame:SetPoint('TOPLEFT', QuestInfoFrame.rewardsFrame, 'BOTTOMLEFT', 0, -6)
	end

	ReputationRewardsFrame:Show()
end

function RR:Initialize()
	Immersion = IsAddOnLoaded('Immersion')
	local ReputationRewardsFrame = CreateFrame('Frame', 'ReputationRewardsFrame', QuestInfoFrame)
	ReputationRewardsFrame:SetSize(288, 40)
	ReputationRewardsFrame:Hide()

	ReputationRewardsFrame.Header = ReputationRewardsFrame:CreateFontString(nil, 'ARTWORK', 'QuestFont_Shadow_Huge')
	ReputationRewardsFrame.Header:SetSize(288, 20)
	ReputationRewardsFrame.Header:SetPoint('TOPLEFT', ReputationRewardsFrame, 'TOPLEFT')
	ReputationRewardsFrame.Header:SetJustifyH('LEFT')
	ReputationRewardsFrame.Header:SetJustifyV('TOP')
	ReputationRewardsFrame.Header:SetTextColor(1, .82, .1)
	ReputationRewardsFrame.Header:SetText(REPUTATION)

	ReputationRewardsFrame.Description = ReputationRewardsFrame:CreateFontString(nil, 'ARTWORK', 'QuestFontNormalSmall')
	ReputationRewardsFrame.Description:SetSize(288, 20)
	ReputationRewardsFrame.Description:SetPoint('TOPLEFT', ReputationRewardsFrame.Header, 'BOTTOMLEFT', 0, -6)
	ReputationRewardsFrame.Description:SetJustifyH('LEFT')
	ReputationRewardsFrame.Description:SetJustifyV('TOP')
	ReputationRewardsFrame.Description:SetTextColor(1, 1, 1)

	RR.ReputationString = '|cFFFFFFFF%s|r: %s%s|r'
	RR.ReputationBonusString = "|cFFFFFFFF%s|r: %s%s|r |cFFFFFFFF(%s Base + %s Bonus)|r"

	RR.ReputationInfo = {}

	-- ID = { bonus = .%, faction = factionID or 0 }
	RR.AuraInfo = {
		[61849] = { bonus = .1, faction = 0 },		--
		[24705] = { bonus = .1, faction = 0 },		--
	    [95987] = { bonus = .1, faction = 0 },		--
		[39913] = { bonus = .1, faction = 947 },	-- Thrallmar
		[39911] = { bonus = .1, faction = 946 },	-- Honor Hold
		[39953] = { bonus = .1, faction = 1031 },	-- Sha'tar
		[46668] = { bonus = .1, faction = 0 },		-- Darkmoon Faire
		[136583] = { bonus = .1 , faction = 0 },	-- Darkmoon Faire

	--	["Banner of Cooperation"] = { bonus = .05, faction = 0 },
	--	["Standard of Unity"] = { bonus = .1, faction = 0 },
	--	["Battle Standard of Coordination"] = { bonus = .15, faction = 0 },
	}

	RR:BuildFactionHeaders()

	RR:SecureHook('QuestInfo_Display', 'Show')

	if Immersion then
		RR:SecureHook(ImmersionFrame, 'QUEST_DETAIL', 'Show')
	end
end

--[[
RR.FactionID = {
	['Horde'] = {
		[68] = true,	-- Undercity
		[76] = true,	-- Orgrimmar
		[81] = true,	-- Thunder Bluff
		[510] = true,	-- The Defilers
		[530] = true,	-- Darkspear Trolls
		[729] = true,	-- Frostwolf Clan
		[889] = true,	-- Warsong Outriders
		[911] = true,	-- Silvermoon City
		[922] = true,	-- Tranquillien
		[941] = true,	-- The Mag'har
		[947] = true,	-- Thrallmar
		[1052] = true,	-- Horde Expedition
		[1064] = true,	-- The Taunka
		[1067] = true,	-- The Hand of Vengeance
		[1085] = true,	-- Warsong Offensive
		[1124] = true,	-- The Sunreavers
		[1133] = true,	-- Bilgewater Cartel
		[1172] = true,	-- Dragonmaw Clan
		[1178] = true,	-- Hellscream's Reach
		[1228] = true,	-- Forest Hozen
		[1352] = true,	-- Huojin Pandaren
		[1374] = true,	-- Brawl'gar Arena
		[1375] = true,	-- Dominance Offensive
		[1388] = true,	-- Sunreaver Onslaught
		[2103] = true,	-- Zandalari Empire
		[2156] = true,	-- Talanji's Expedition
		[2157] = true,	-- The Honorbound
		[2158] = true,	-- Voldunai
		[2163] = true,	-- Tortollan Seekers
		[2164] = true,	-- Champions of Azeroth
	},
	['Alliance'] = {
		[47] = true,	-- Ironforge
		[54] = true,	-- Gnomeregan
		[69] = true,	-- Darnassus
		[72] = true,	-- Stormwind
		[509] = true,	-- The League of Arathor
		[589] = true,	-- Wintersaber Trainers
		[730] = true,	-- Stormpike Guard
		[890] = true,	-- Silverwing Sentinels
		[930] = true,	-- Exodar
		[946] = true,	-- Honor Hold
		[978] = true,	-- Kurenai
		[1037] = true,	-- Alliance Vanguard
		[1050] = true,	-- Valiance Expedition
		[1068] = true,	-- Explorers' League
		[1094] = true,	-- The Silver Covenant
		[1126] = true,	-- The Frostborn
		[1134] = true,	-- Gilneas
		[1174] = true,	-- Wildhammer Clan
		[1177] = true,	-- Baradin's Wardens
		[1242] = true,	-- Pearlfin Jinyu
		[1353] = true,	-- Tushui Pandaren
		[1376] = true,	-- Operation: Shieldwall
		[1387] = true,	-- Kirin Tor Offensive
		[1419] = true,	-- Bizmo's Brawlpub
		[2160] = true,	-- Proudmoore Admiralty
		[2161] = true,	-- Order of Embers
		[2162] = true,	-- Storm's Wake
	},
	['All'] = {
		[21] = true,	-- Booty Bay
		[59] = true,	-- Thorium Brotherhood
		[70] = true,	-- Syndicate
		[87] = true,	-- Bloodsail Buccaneers
		[92] = true, 	-- Gelkis Clan Centaur
		[93] = true,	-- Magram Clan Centaur
		[270] = true,	-- Zandalar Tribe
		[349] = true,	-- Ravenholdt
		[369] = true,	-- Gadgetzan
		[470] = true,	-- Ratchet
		[529] = true,	-- Argent Dawn
		[576] = true,	-- Timbermaw Hold
		[577] = true,	-- Everlook
		[609] = true,	-- Cenarion Circle
		[749] = true,	-- Hydraxian Waterlords
		[809] = true,	-- Shen'dralar
		[909] = true,	-- Darkmoon Faire
		[910] = true,	-- Brood of Nozdormu
		[932] = true,	-- The Aldor
		[933] = true,	-- The Consortium
		[934] = true,	-- The Scryers
		[935] = true,	-- The Sha'tar
		[942] = true,	-- Cenarion Expedition
		[967] = true,	-- The Violet Eye
		[970] = true,	-- Sporeggar
		[989] = true,	-- Keepers of Time
		[990] = true,	-- The Scale of the Sands
		[1011] = true,	-- Lower City
		[1012] = true,	-- Ashtongue Deathsworn
		[1015] = true,	-- Netherwing
		[1031] = true,	-- Sha'tari Skyguard
		[1038] = true,	-- Ogri'la
		[1073] = true,	-- The Kalu'ak
		[1077] = true,	-- Shattered Sun Offensive
		[1090] = true,	-- Kirin Tor
		[1091] = true,	-- The Wyrmrest Accord
		[1098] = true,	-- Knights of the Ebon Blade
		[1104] = true,	-- Frenzyheart Tribe
		[1105] = true,	-- The Oracles
		[1106] = true,	-- Argent Crusade
		[1119] = true,	-- The Sons of Hodir
		[1135] = true,	-- The Earthen Ring
		[1156] = true,	-- The Ashen Verdict
		[1158] = true,	-- Guardians of Hyjal
		[1171] = true,	-- Therazane
		[1173] = true,	-- Ramkahen
		[1204] = true,	-- Avengers of Hyjal
		[1216] = true,	-- Shang Xi's Academy
		[1269] = true,	-- Golden Lotus
		[1270] = true,	-- Shado-Pan
		[1271] = true,	-- Order of the Cloud Serpent
		[1272] = true,	-- The Tillers
		[1302] = true,	-- The Anglers
		[1337] = true,	-- The Klaxxi
		[1341] = true,	-- The August Celestials
		[1345] = true,	-- The Lorewalkers
		[1359] = true,	-- The Black Prince
		[1416] = true,	-- Akama's Trust
		[1435] = true,	-- Shado-Pan Assault
		[2045] = true,	-- Armies of Legionfall
		[2165] = true,	-- Army of the Light
		[2170] = true,	-- Argussian Reach
	},
}
]]
