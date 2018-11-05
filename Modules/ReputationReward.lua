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
		return
	end

	local numQuestRewards, numQuestChoices, numQuestCurrencies, totalHeight = 0, 0, 0, 0

	if ( QuestInfoFrame.questLog ) then
		local questID = select(8, GetQuestLogTitle(GetQuestLogSelection()));
		if C_QuestLog.ShouldShowQuestRewards(questID) then
			numQuestRewards = GetNumQuestLogRewards();
			numQuestChoices = GetNumQuestLogChoices();
			numQuestCurrencies = GetNumQuestLogRewardCurrencies();
		end
	else
		numQuestRewards = GetNumQuestRewards();
		numQuestChoices = GetNumQuestChoices();
		numQuestCurrencies = GetNumRewardCurrencies();
	end

	local totalRewards = numQuestRewards + numQuestChoices + numQuestCurrencies;

	local index
	local baseIndex = totalRewards
	local lastFrame
	local buttonIndex = baseIndex

	wipe(RR.ReputationInfo)

	for i = 1, numRepFactions do
		local factionID, amtBase = GetQuestLogRewardFactionInfo(i)
		local factionName, _, standingID, _, _, _, AtWar, ToggleAtWar, isHeader = GetFactionInfoByID(factionID)

		if factionName and (AtWar and ToggleAtWar or (not AtWar)) then
			amtBase = floor(amtBase / 100)

			local amtBonus = RR:GetBonusReputation(amtBase, factionID)

			RR.ReputationInfo[factionID] = { Name = factionName, Base = amtBase, Bonus = amtBonus, Header = isHeader, FactionID = factionID, Child = RR:GetFactionHeader(factionID), Standing = standingID }
		end
	end

	for _, Info in pairs(RR.ReputationInfo) do
		if (Info.FactionID ~= RR:GetFactionHeader(Info.Child)) and (Info.Child == RR:GetFactionHeader(Info.FactionID)) and (Info.Base == (RR.ReputationInfo[Info.Child] and RR.ReputationInfo[Info.Child].Base or 0)) then
			RR.ReputationInfo[Info.FactionID] = nil
		end
	end

	local i = 1
	for _, Info in pairs(RR.ReputationInfo) do
		buttonIndex = buttonIndex + 1
		index = i + baseIndex

		local questItem = QuestInfo_GetRewardButton(QuestInfoFrame.rewardsFrame, index)
		questItem:Show()

		questItem.Name:SetText(Info.Name)
		questItem.Icon:SetTexture(UnitFactionGroup('player') and ('Interface\\Icons\\PVPCurrency-Honor-%s'):format(UnitFactionGroup('player')))
--		questItem.Icon:SetTexture(([[Interface\Icons\Achievement_Reputation_0%d]]):format(Info.Standing or 1))
		questItem.Count:SetText(Info.Base + Info.Bonus)

		if Info.Base < 0 then
			questItem.Count:SetTextColor(1, 0, 0)
		elseif Info.Bonus > 0 then
			questItem.Count:SetTextColor(0, 1, 0)
		else
			questItem.Count:SetTextColor(1, 1, 1)
		end

		if ( buttonIndex > 1 ) then
			if ( mod(buttonIndex, 2) == 1 ) then
				questItem:SetPoint('TOPLEFT', QuestInfoFrame.rewardsFrame.RewardButtons[index - 2], 'BOTTOMLEFT', 0, -2)
				lastFrame = questItem
			else
				questItem:SetPoint('TOPLEFT', QuestInfoFrame.rewardsFrame.RewardButtons[index - 1], 'TOPRIGHT', 1, 0)
			end
		else
			questItem:SetPoint('TOPLEFT', lastFrame, 'BOTTOMLEFT', 0, -5)
			lastFrame = questItem
		end

		i = i + 1
	end
end

function RR:Initialize()
	Immersion = IsAddOnLoaded('Immersion')

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