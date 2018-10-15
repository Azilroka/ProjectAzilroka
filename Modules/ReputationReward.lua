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

RR.Title = '|cFF16C3F2Reputation|r|cFFFFFFFFRewards|r'
RR.Description = 'Adds Reputation into Quest Log & Quest Frame.'
RR.Authors = 'Azilroka    jayd'

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

	-- Build a table so I can filter it.
	for i = 1, numRepFactions do
		local factionID, amtBase = GetQuestLogRewardFactionInfo(i)
		local factionName, _, _, _, _, _, _, _, isHeader = GetFactionInfoByID(factionID)
		amtBase = floor(amtBase / 100)

		local amtBonus = RR:GetBonusReputation(amtBase, factionID)

		RR.ReputationInfo[factionID] = { Name = factionName, Base = amtBase, Bonus = amtBonus, Header = isHeader, FactionID = factionID, Child = RR:GetFactionHeader(factionID) }
	end

	-- Filter the table
	for _, Info in pairs(RR.ReputationInfo) do
		if (Info.FactionID ~= RR:GetFactionHeader(Info.Child)) and (Info.Child == RR:GetFactionHeader(Info.FactionID)) and (Info.Base == (RR.ReputationInfo[Info.Child] and RR.ReputationInfo[Info.Child].Base or 0)) then
			RR.ReputationInfo[Info.FactionID] = nil
		end
	end

	-- Show the Filtered Table
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

	ReputationRewardsFrame.Description:SetHeight((NumShown * 12) + 10)
	ReputationRewardsFrame.Description:SetText(QuestString)
	ReputationRewardsFrame:SetHeight((NumShown * 12) + 30)

	ReputationRewardsFrame:ClearAllPoints()

	if QuestInfoFrame.mapView then
		ReputationRewardsFrame:SetParent(QuestInfoDescriptionText:GetParent())
		ReputationRewardsFrame:SetPoint('TOPLEFT', QuestInfoDescriptionText, 'BOTTOMLEFT', 0, -10)
	elseif QuestInfoFrame.rewardsFrame.XPFrame then
		ReputationRewardsFrame:SetParent(QuestInfoFrame.rewardsFrame)
		ReputationRewardsFrame:SetPoint('TOPLEFT', QuestInfoFrame.rewardsFrame.XPFrame, 'BOTTOMLEFT', 0, -6)
	end

	ReputationRewardsFrame:Show()
end

function RR:Initialize()
	local ReputationRewardsFrame = CreateFrame('Frame', 'ReputationRewardsFrame', QuestInfoFrame)
	ReputationRewardsFrame:SetSize(288, 40)
	ReputationRewardsFrame:Hide()

	ReputationRewardsFrame.Header = ReputationRewardsFrame:CreateFontString(nil, 'ARTWORK', 'QuestFont_Shadow_Huge')
	ReputationRewardsFrame.Header:SetSize(288, 20)
	ReputationRewardsFrame.Header:SetPoint('TOPLEFT', ReputationRewardsFrame, 'TOPLEFT')
	ReputationRewardsFrame.Header:SetJustifyH('LEFT')
	ReputationRewardsFrame.Header:SetJustifyV('TOP')
	ReputationRewardsFrame.Header:SetTextColor(1, .9, .1)
	ReputationRewardsFrame.Header:SetText('Reputation')

	ReputationRewardsFrame.Description = ReputationRewardsFrame:CreateFontString(nil, 'ARTWORK', 'QuestFontNormalSmall')
	ReputationRewardsFrame.Description:SetSize(288, 20)
	ReputationRewardsFrame.Description:SetPoint('TOPLEFT', ReputationRewardsFrame.Header, 'BOTTOMLEFT', 0, -3)
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
end
