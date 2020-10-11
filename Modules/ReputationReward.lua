local PA = _G.ProjectAzilroka
if PA.Classic then return end

local RR = PA:NewModule('ReputationReward', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
PA.RR = RR

RR.Title = 'ReputationRewards'
RR.Header = PA.ACL['|cFF16C3F2Reputation|r|cFFFFFFFFRewards|r']
RR.Description = PA.ACL['Adds Reputation into Quest Log & Quest Frame.']
RR.Authors = 'Azilroka'
RR.isEnabled = false

local _G = _G
local floor = floor
local pairs = pairs
local select = select
local wipe = wipe
local mod = mod

local GetFactionInfo = _G.GetFactionInfo
local GetFactionInfoByID = _G.GetFactionInfoByID
local GetNumFactions = _G.GetNumFactions
local GetNumQuestLogRewardFactions = _G.GetNumQuestLogRewardFactions
local GetQuestLogRewardFactionInfo = _G.GetQuestLogRewardFactionInfo
local GetQuestLogTitle = _G.GetQuestLogTitle
local GetQuestLogSelection = _G.GetQuestLogSelection
local C_QuestLog = _G.C_QuestLog
local GetNumQuestLogChoices = _G.GetNumQuestLogChoices
local GetNumQuestChoices = _G.GetNumQuestChoices
local UnitAura = _G.UnitAura
local QuestInfo_GetRewardButton = _G.QuestInfo_GetRewardButton
local SetItemButtonCount = _G.SetItemButtonCount
local SetItemButtonTexture = _G.SetItemButtonTexture
local ExpandFactionHeader = _G.ExpandFactionHeader
local CollapseFactionHeader = _G.CollapseFactionHeader

local REWARDS_SECTION_OFFSET = 5

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
	local mult = 1
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

	local numQuestChoices = 0

	if ( _G.QuestInfoFrame.questLog ) then
		local questID = select(8, GetQuestLogTitle(GetQuestLogSelection()))
		if C_QuestLog.ShouldShowQuestRewards(questID) then
			numQuestChoices = GetNumQuestLogChoices()
		end
	else
		numQuestChoices = GetNumQuestChoices()
	end

	wipe(RR.ReputationInfo)

	for i = 1, numRepFactions do
		local factionID, amtBase = GetQuestLogRewardFactionInfo(i)
		local factionName, factionDescription, standingID, barMin, barMax, _, AtWar, ToggleAtWar, isHeader = GetFactionInfoByID(factionID)

		if factionName and (AtWar and ToggleAtWar or (not AtWar)) and (not (barMin == barMax)) then
			amtBase = floor(amtBase / 100)

			if PA.MyRace == 'Human' then
				amtBase = amtBase * 1.1
			end

			local amtBonus = RR:GetBonusReputation(amtBase, factionID)

			RR.ReputationInfo[factionID] = { Name = factionName, Description = factionDescription, Base = amtBase, Bonus = amtBonus, Header = isHeader, FactionID = factionID, Child = RR:GetFactionHeader(factionID), Standing = standingID }
		end
	end

	if RR.db.ShowAll then
		for _, Info in pairs(RR.ReputationInfo) do
			if Info.isHeader then
				RR.ReputationInfo[Info.FactionID] = nil
			end
		end
	else
		for _, Info in pairs(RR.ReputationInfo) do
			if (Info.FactionID ~= RR:GetFactionHeader(Info.Child)) and (Info.Child == RR:GetFactionHeader(Info.FactionID)) and (Info.Base == (RR.ReputationInfo[Info.Child] and RR.ReputationInfo[Info.Child].Base or 0)) then
				RR.ReputationInfo[Info.FactionID] = nil
			end
		end
	end

	local rewardsFrame, lastFrame = QuestInfo_ShowRewards()
	if not rewardsFrame then return end
	local buttonHeight = rewardsFrame.RewardButtons[1]:GetHeight()

	local rewardButtons = rewardsFrame.RewardButtons;
	local buttonIndex = 1
	for index, rewardButton in ipairs(rewardButtons) do
		if not rewardButton:IsShown() then
			buttonIndex = index
			break
		end
	end

	local Height = _G.QuestInfoFrame.rewardsFrame:GetHeight()

	if not _G.QuestInfoFrame.rewardsFrame:IsShown() then
		_G.QuestInfoFrame.rewardsFrame:Show()
	end

	for _, Info in pairs(RR.ReputationInfo) do
		local questItem = QuestInfo_GetRewardButton(rewardsFrame, buttonIndex)
		if questItem then
			questItem:Show()

			questItem.type = "reward"
			questItem.objectType = "reputation"

			questItem.Name:SetText(Info.Name)
			SetItemButtonCount(questItem, Info.Base + Info.Bonus)
			SetItemButtonTexture(questItem, PA.MyFaction and (PA.MyFaction == 'Neutral' and 'Interface/Icons/Achievement_Character_Pandaren_Female' or ('Interface/Icons/PVPCurrency-Conquest-%s'):format(PA.MyFaction)))
			questItem.IconBorder:Hide()

			local r, g, b = 1, 1, 1
			if Info.Base < 0 then r, g, b = 1, 0, 0 elseif Info.Bonus > 0 then r, g, b = 0, 1, 0 end

			questItem.Count:SetTextColor(r, g, b)
			questItem:ClearAllPoints()

			if (buttonIndex > 1) then
				if mod(buttonIndex, 2) == 1 then
					questItem:SetPoint('TOPLEFT', QuestInfo_GetRewardButton(rewardsFrame, buttonIndex - 2) or lastFrame, 'BOTTOMLEFT', 0, -REWARDS_SECTION_OFFSET)
					Height = Height + buttonHeight + REWARDS_SECTION_OFFSET
					lastFrame = questItem
				else
					questItem:SetPoint('TOPLEFT', QuestInfo_GetRewardButton(rewardsFrame, buttonIndex - 1) or lastFrame, 'TOPRIGHT', 2, 0)
				end
			else
				questItem:SetPoint('TOPLEFT', lastFrame, 'BOTTOMLEFT', 0, -REWARDS_SECTION_OFFSET)
				Height = Height + buttonHeight + REWARDS_SECTION_OFFSET
				lastFrame = questItem
			end

			buttonIndex = buttonIndex + 1
		end
	end

	if ( numQuestChoices == 1 ) then
		local a, b, c, d, e = _G.QuestInfoFrame.rewardsFrame.ItemReceiveText:GetPoint()
		_G.QuestInfoFrame.rewardsFrame.ItemReceiveText:SetPoint(a, b, c, d, e - ((((buttonIndex - 1) % 2) == 1 and (((buttonIndex - 1) / 2) * (buttonHeight + REWARDS_SECTION_OFFSET)) or 0)))
	end

	_G.QuestInfoFrame.rewardsFrame:Show()
	_G.QuestInfoFrame.rewardsFrame:SetHeight(Height)
end

function RR:GetOptions()
	PA.Options.args.ReputationReward = PA.ACH:Group(RR.Title, RR.Description, nil, nil, function(info) return RR.db[info[#info]] end, function(info, value) RR.db[info[#info]] = value end)
	PA.Options.args.ReputationReward.args.Header = PA.ACH:Header(RR.Header, 0)
	PA.Options.args.ReputationReward.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) RR.db[info[#info]] = value if (not RR.isEnabled) then RR:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	PA.Options.args.ReputationReward.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	PA.Options.args.ReputationReward.args.General.inline = true
	PA.Options.args.ReputationReward.args.General.args.ShowAll = PA.ACH:Toggle(PA.ACL['Show All Reputation'], nil, 1)

	PA.Options.args.ReputationReward.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	PA.Options.args.ReputationReward.args.Authors = PA.ACH:Description(RR.Authors, -1, 'large')
end

function RR:BuildProfile()
	PA.Defaults.profile.ReputationReward = { Enable = true }
end

function RR:UpdateSettings()
	RR.db = PA.db.ReputationReward
end

function RR:Initialize()
	RR:UpdateSettings()

	if RR.db.Enable ~= true then
		return
	end

	RR.isEnabled = true

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
