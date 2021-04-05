local PA = _G.ProjectAzilroka
local MXP = PA:NewModule('MasterXP', 'AceTimer-3.0', 'AceEvent-3.0')

MXP.Title = PA.ACL['|cFF16C3F2Master|r |cFFFFFFFFExperience|r']
MXP.Description = PA.ACL['Shows Experience Bars for Party / Battle.net Friends']
MXP.Authors = 'Azilroka     Nihilistzsche'
MXP.isEnabled = false
PA.MXP, _G.MasterExperience = MXP, MXP

local _G = _G
local min, max, format = min, max, format
local tostring, tonumber = tostring, tonumber
local strsplit = strsplit

local CreateFrame = CreateFrame
local GetXPExhaustion = GetXPExhaustion
local IsXPUserDisabled = IsXPUserDisabled
local GetQuestLogRewardXP = GetQuestLogRewardXP
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local UnitXP, UnitXPMax = UnitXP, UnitXPMax

local BNGetInfo = BNGetInfo

local QuestLogXP, ZoneQuestXP, CompletedQuestXP = 0, 0, 0
local CurrentXP, XPToLevel, RestedXP, CurrentLevel

MXP.playerRealm = format('%s-%s', UnitName("player"), gsub(GetRealmName(), '[%s%-]', ''))
MXP.battleTag = MXP.isBNConnected and select(2, BNGetInfo())
MXP.BNFriends = {}
MXP.isBNConnected = false

MXP.MasterExperience = CreateFrame('Frame', 'MasterExperience', PA.PetBattleFrameHider)
MXP.MasterExperience:SetSize(250, 400)
MXP.MasterExperience:SetPoint('BOTTOM', _G.UIParent, 'BOTTOM', 0, 43)
MXP.MasterExperience.Bars = {}

if not (PA.Tukui or PA.ElvUI) then
	MXP.MasterExperience:SetMovable(true)
end

function MXP:CheckQuests(questID, zoneOnly)
	if not questID or questID == 0 then
		return
	end

	local isCompleted = _G.C_QuestLog.ReadyForTurnIn(questID)
	local experience = GetQuestLogRewardXP(questID)
	if zoneOnly then
		ZoneQuestXP = ZoneQuestXP + experience
	else
		QuestLogXP = QuestLogXP + experience
	end
	if isCompleted then
		CompletedQuestXP = CompletedQuestXP + experience
	end
end

function MXP:AssignInfo(bar, infoString)
	if infoString then
		-- Split the String
		bar.Info.name, bar.Info.class, bar.Info.level,
		bar.Info.atMaxLevel, bar.Info.xpDisabled,
		bar.Info.CurrentXP, bar.Info.XPToLevel, bar.Info.RestedXP,
		bar.Info.QuestLogXP, bar.Info.ZoneQuestXP, bar.Info.CompletedQuestXP = strsplit(":", infoString)

		-- Convert Strings to Number
		bar.Info.CurrentXP, bar.Info.XPToLevel, bar.Info.RestedXP, bar.Info.QuestLogXP, bar.Info.ZoneQuestXP, bar.Info.CompletedQuestXP = tonumber(bar.Info.CurrentXP), tonumber(bar.Info.XPToLevel), tonumber(bar.Info.RestedXP), tonumber(bar.Info.QuestLogXP), tonumber(bar.Info.ZoneQuestXP), tonumber(bar.Info.CompletedQuestXP)

		-- Convert String to Boolean
		bar.Info.atMaxLevel, bar.Info.xpDisabled = bar.Info.atMaxLevel == 'true', bar.Info.xpDisabled == 'true'
	end
	return bar.Info
end

function MXP:UpdateBar(barID, infoString)
	local bar = MXP.MasterExperience.Bars[barID] or MXP:CreateBar()
	bar:Show()

	local info = MXP:AssignInfo(bar, infoString)

	if info.XPToLevel <= 0 then info.XPToLevel = 1 end

	local remainXP = info.XPToLevel - info.CurrentXP
	local remainPercent = remainXP / info.XPToLevel
	info.RemainTotal, info.RemainBars = remainPercent * 100, remainPercent * 20
	info.PercentXP, info.RemainXP = (info.CurrentXP / info.XPToLevel) * 100, remainXP

	-- Set the Colors
	local expColor, restedColor, questColor = MXP.db.Colors.Experience, MXP.db.Colors.Rested, MXP.db.Colors.Quest

	if MXP.db.ColorByClass and info.class then
		expColor = MXP:ConvertColorToClass(expColor, PA:GetClassColor(info.class))
		restedColor = MXP:ConvertColorToClass(restedColor, PA:GetClassColor(info.class), .6)
	end

	bar:SetStatusBarColor(expColor.r, expColor.g, expColor.b, expColor.a)
	bar.Rested:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)
	bar.Quest:SetStatusBarColor(questColor.r, questColor.g, questColor.b, questColor.a)

	local displayString, textFormat = '', 'CURPERCREM'

	if info.atMaxLevel or info.xpDisabled then
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)

		if displayString ~= 'NONE' then
			displayString = info.xpDisabled and PA.ACL["Disabled"] or PA.ACL["Max Level"]
		end
	else
		bar:SetMinMaxValues(0, info.XPToLevel)
		bar:SetValue(info.CurrentXP)

		if textFormat == 'PERCENT' then
			displayString = format('%.2f%%', info.PercentXP)
		elseif textFormat == 'CURMAX' then
			displayString = format('%s - %s', info.CurrentXP, info.XPToLevel)
		elseif textFormat == 'CURPERC' then
			displayString = format('%s - %.2f%%', info.CurrentXP, info.PercentXP)
		elseif textFormat == 'CUR' then
			displayString = format('%s', info.CurrentXP)
		elseif textFormat == 'REM' then
			displayString = format('%s', info.RemainXP)
		elseif textFormat == 'CURREM' then
			displayString = format('%s - %s', info.CurrentXP, info.RemainXP)
		elseif textFormat == 'CURPERCREM' then
			displayString = format('%s - %.2f%% (%s)', info.CurrentXP, info.PercentXP, info.RemainXP)
		end

		local isRested = info.RestedXP and info.RestedXP > 0
		if isRested then
			bar.Rested:SetMinMaxValues(0, info.XPToLevel)
			bar.Rested:SetValue(min(info.CurrentXP + info.RestedXP, info.XPToLevel))

			info.PercentRested = (info.RestedXP / info.XPToLevel) * 100

			if textFormat == 'PERCENT' then
				displayString = format('%s R:%.2f%%', displayString, info.PercentRested)
			elseif textFormat == 'CURPERC' then
				displayString = format('%s R:%s [%.2f%%]', displayString, info.RestedXP, info.PercentRested)
			elseif textFormat ~= 'NONE' then
				displayString = format('%s R:%s', displayString, info.RestedXP)
			end
		end

		local hasQuestXP = info.QuestLogXP > 0
		if hasQuestXP then
			info.QuestPercent = (info.QuestLogXP / info.XPToLevel) * 100

			bar.Quest:SetMinMaxValues(0, info.XPToLevel)
			bar.Quest:SetValue(min(info.CurrentXP + info.QuestLogXP, info.XPToLevel))

			if textFormat == 'PERCENT' then
				displayString = format('%s Q:%.2f%%', displayString, info.QuestPercent)
			elseif textFormat == 'CURPERC' then
				displayString = format('%s Q:%s [%.2f%%]', displayString, info.QuestLogXP, info.QuestPercent)
			elseif textFormat ~= 'NONE' then
				displayString = format('%s Q:%s', displayString, info.QuestLogXP)
			end
		end

		displayString = format('%s %s - %s', PA.ACL['Lvl'], info.level, displayString)

		bar.Rested:SetShown(isRested)
		bar.Quest:SetShown(hasQuestXP)
	end

	bar.Text:SetText(displayString)
	bar.Name:SetText(MXP.BNFriends[info.name] and MXP.BNFriends[info.name].accountName or info.name)

	local numShown = 0
	for _, Bar in ipairs(MXP.MasterExperience.Bars) do
		if Bar:IsShown() then
			numShown = numShown + 1
		end
	end

	MXP.MasterExperience:SetSize(max(MXP.db.Width, numShown * MXP.db.Width), max(MXP.db.Height, numShown * MXP.db.Height))
	if MXP.MasterExperience.mover then
		MXP.MasterExperience.mover:SetSize(MXP.MasterExperience:GetSize())
	end
end

function MXP:Bar_OnEnter()
	if MXP.db.MouseOver then
		UIFrameFadeIn(self, 0.4, self:GetAlpha(), 1)
	end

	if self.Info.atMaxLevel or self.Info.xpDisabled then return end

	_G.GameTooltip:ClearLines()
	_G.GameTooltip:SetOwner(self, 'ANCHOR_CURSOR', 0, -4)

	_G.GameTooltip:AddLine(format("%s's %s", MXP.BNFriends[self.Info.name] and MXP.BNFriends[self.Info.name].accountName or self.Info.name, PA.ACL["Experience"]))
	_G.GameTooltip:AddLine(' ')

	_G.GameTooltip:AddDoubleLine(PA.ACL["XP:"], format(' %d / %d (%.2f%%)', self.Info.CurrentXP, self.Info.XPToLevel, self.Info.PercentXP), 1, 1, 1)
	_G.GameTooltip:AddDoubleLine(PA.ACL["Remaining:"], format(' %s (%.2f%% - %d '..PA.ACL["Bars"]..')', self.Info.RemainXP, self.Info.RemainTotal, self.Info.RemainBars), 1, 1, 1)

	if self.Info.QuestLogXP and self.Info.QuestLogXP > 0 then
		_G.GameTooltip:AddDoubleLine(PA.ACL["Quest Log XP:"], format('+%d (%.2f%%)', self.Info.QuestLogXP, self.Info.QuestPercent), 1, 1, 1)
	end

	if self.Info.RestedXP and self.Info.RestedXP > 0 then
		_G.GameTooltip:AddDoubleLine(PA.ACL["Rested:"], format('+%d (%.2f%%)', self.Info.RestedXP, self.Info.PercentRested), 1, 1, 1)
	end

	_G.GameTooltip:Show()
end

function MXP:Bar_OnLeave()
	if MXP.db.MouseOver then
		UIFrameFadeIn(self, 0.4, self:GetAlpha(), 0)
	end

	GameTooltip_Hide(self)
end

function MXP:GetBarPoints(barIndex)
	local point = MXP.db.GrowthDirection == 'UP' and 'BOTTOM' or 'TOP'
	local relativeFrame = barIndex == 1 and MXP.MasterExperience or MXP.MasterExperience.Bars[barIndex - 1]
	local relativePoint = (barIndex == 1 or MXP.db.GrowthDirection == 'DOWN') and 'BOTTOM' or 'TOP'
	local yOffset = barIndex == 1 and 0 or MXP.db.GrowthDirection == 'UP' and 2 or -2

	return point, relativeFrame, relativePoint, yOffset
end

function MXP:CreateBar()
	local barIndex = (#MXP.MasterExperience.Bars + 1)

	local Bar = CreateFrame('StatusBar', 'MasterXP_Bar'..barIndex, MXP.MasterExperience)
	PA:CreateBackdrop(Bar)
	Bar:SetStatusBarTexture(PA.Solid)
	Bar:Hide()
	Bar:SetSize(MXP.db.Width, MXP.db.Height)
	Bar:SetScript('OnEnter', MXP.Bar_OnEnter)
	Bar:SetScript('OnLeave', MXP.Bar_OnLeave)
	Bar.Info = {}

	local point, relativeFrame, relativePoint, yOffset = MXP:GetBarPoints(barIndex)
	Bar:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)

	Bar.Text = Bar:CreateFontString(nil, 'OVERLAY')
	Bar.Text:SetFont(PA.LSM:Fetch('font', MXP.db.Font), MXP.db.FontSize, MXP.db.FontFlag)
	Bar.Text:SetPoint('CENTER')

	Bar.Name = Bar:CreateFontString(nil, 'OVERLAY')
	Bar.Name:SetFont(PA.LSM:Fetch('font', MXP.db.Font), MXP.db.FontSize, MXP.db.FontFlag)
	Bar.Name:SetJustifyV('MIDDLE')
	Bar.Name:SetJustifyH('RIGHT')
	Bar.Name:SetPoint('RIGHT', Bar, 'LEFT', -2, 0)

	Bar.Rested = CreateFrame('StatusBar', '$parent_Rested', Bar)
	Bar.Rested:SetFrameLevel(Bar:GetFrameLevel())
	Bar.Rested:Hide()
	Bar.Rested:SetStatusBarTexture(PA.Solid, 'ARTWORK', -2)
	Bar.Rested:SetAllPoints()

	Bar.Quest = CreateFrame('StatusBar', '$parent_Quest', Bar)
	Bar.Quest:SetFrameLevel(Bar:GetFrameLevel())
	Bar.Quest:Hide()
	Bar.Quest:SetStatusBarTexture(PA.Solid, 'ARTWORK', -1)
	Bar.Quest:SetAllPoints()

	MXP.MasterExperience.Bars[barIndex] = Bar

	return Bar
end

function MXP:UPDATE_EXHAUSTION()
	RestedXP = GetXPExhaustion()
end

function MXP:PLAYER_LEVEL_UP()
	CurrentLevel = UnitLevel('player')
end

function MXP:PLAYER_XP_UPDATE()
	CurrentXP, XPToLevel = UnitXP('player'), UnitXPMax('player')
end

function MXP:QUEST_LOG_UPDATE()
	QuestLogXP, ZoneQuestXP, CompletedQuestXP = 0, 0, 0

	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHidden then
			MXP:CheckQuests(C_QuestLog.GetQuestIDForLogIndex(i), info.isOnMap)
		end
	end

	MXP:SendMessage()
end

local newColorTable = {}
function MXP:ConvertColorToClass(colorTable, classColorTable, multiplier)
	wipe(newColorTable)
	multiplier = multiplier or 1
	for key in pairs(classColorTable) do
		if colorTable[key] then
			newColorTable[key] = classColorTable[key] * multiplier
		end
	end

	return newColorTable
end

function MXP:ClearBars()
	for _, bar in ipairs(MXP.MasterExperience.Bars) do
		wipe(bar.Info)
		bar:Hide()
		bar:SetAlpha(1)
	end
end

function MXP:GetAssignedBar(name)
	local numBars = #MXP.MasterExperience.Bars
	if (not numBars or numBars == 0) then
		return 1
	else
		for i = 1, numBars do
			if MXP.MasterExperience.Bars[i] and (MXP.MasterExperience.Bars[i].Info.name == name or not MXP.MasterExperience.Bars[i].Info.name) then
				return i
			end
		end
		return numBars + 1
	end
end

function MXP:UpdateAllBars()
	MXP:ClearBars()

	local inParty = IsInGroup() and not IsInRaid()

	if MXP.db.BattleNet and MXP.isBNConnected or MXP.db.Party and inParty then
		MXP:SendMessage()
	end

	if MXP.db.Party and inParty then
		C_ChatInfo.SendAddonMessage('PA_MXP', 'REQUESTINFO', 'PARTY')
	end

	if MXP.db.BattleNet and MXP.isBNConnected then
		for _, info in pairs(MXP.BNFriends) do
			if info.presenceID then
				BNSendGameData(info.presenceID, 'PA_MXP', 'REQUESTINFO')
			end
		end
	end
end

function MXP:BattleNetUpdate(_, friendIndex)
	if MXP.isBNConnected and friendIndex then
		local hideBar = true
		local friendInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
		for gameIndex = 1, C_BattleNet.GetFriendNumGameAccounts(friendIndex) do
			local info = C_BattleNet.GetFriendGameAccountInfo(friendIndex, gameIndex)
			if info and info.clientProgram == 'WoW' then
				BNSendGameData(info.gameAccountID, 'PA_MXP', 'REQUESTINFO')
				hideBar = false
			end
		end
		if hideBar then
			local bar = MXP.MasterExperience.Bars[MXP:GetAssignedBar(friendInfo.battleTag)]
			if bar then
				bar:Hide()
			end
		end
	end
end

function MXP:UpdateCurrentBars()
	local font, fontSize, fontFlag = PA.LSM:Fetch('font', MXP.db.Font), MXP.db.FontSize, MXP.db.FontFlag

	for barIndex, bar in ipairs(MXP.MasterExperience.Bars) do
		MXP:UpdateBar(barIndex)
		bar:SetSize(MXP.db.Width, MXP.db.Height)
		bar:ClearAllPoints()
		bar:SetAlpha(MXP.db.MouseOver and 0 or 1)
		bar.Text:SetFont(font, fontSize, fontFlag)
		bar.Name:SetFont(font, fontSize, fontFlag)

		local point, relativeFrame, relativePoint, yOffset = MXP:GetBarPoints(barIndex)
		bar:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	end
end

function MXP:SendMessage()
	if not IsPlayerInWorld() then return end

	if MXP.db.Party and IsInGroup(LE_PARTY_CATEGORY_HOME) and not IsInRaid() then
		local message = format('%s:%s:%d:%s:%s:%d:%d:%d:%d:%d:%d:%d', MXP.playerRealm, PA.MyClass or UnitClass('player'), CurrentLevel or UnitLevel('player'), tostring(IsPlayerAtEffectiveMaxLevel()), tostring(IsXPUserDisabled()), CurrentXP or 0, XPToLevel or 0, RestedXP or 0, QuestLogXP or 0, ZoneQuestXP or 0, CompletedQuestXP or 0)
		C_ChatInfo.SendAddonMessage('PA_MXP', message, 'PARTY')
	end

	if MXP.db.BattleNet and MXP.isBNConnected then
		local message = format('%s:%s:%d:%s:%s:%d:%d:%d:%d:%d:%d:%d', MXP.battleTag, PA.MyClass or UnitClass('player'), CurrentLevel or UnitLevel('player'), tostring(IsPlayerAtEffectiveMaxLevel()), tostring(IsXPUserDisabled()), CurrentXP or 0, XPToLevel or 0, RestedXP or 0, QuestLogXP or 0, ZoneQuestXP or 0, CompletedQuestXP or 0)
		for _, info in pairs(MXP.BNFriends) do
			if info.presenceID then
				BNSendGameData(info.presenceID, 'PA_MXP', message)
			end
		end
	end
end

function MXP:HandleBNET()
	wipe(MXP.BNFriends)

	if MXP.isBNConnected then
		MXP:BattleTag()
		local _, numBNetOnline = BNGetNumFriends()
		for friendIndex = 1, numBNetOnline do
			local friendInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
			for gameIndex = 1, C_BattleNet.GetFriendNumGameAccounts(friendIndex) do
				local info = C_BattleNet.GetFriendGameAccountInfo(friendIndex, gameIndex)
				if info and info.clientProgram == 'WoW' then
					MXP.BNFriends[friendInfo.battleTag] = { presenceID = info.gameAccountID, accountName = friendInfo.accountName }
					MXP.BNFriends[info.gameAccountID] = { battleTag = friendInfo.battleTag, accountName = friendInfo.accountName }
				end
			end
		end
	end
end

function MXP:HandleBNStatus()
	MXP.isBNConnected = _G.BNConnected()
end

function MXP:BattleTag()
	if not MXP.battleTag then
		MXP.battleTag = MXP.isBNConnected and select(2, BNGetInfo())
	end
end

function MXP:RecieveMessage(event, prefix, message, _, sender)
	if prefix ~= 'PA_MXP' then return end

	if event == 'CHAT_MSG_ADDON' and sender ~= MXP.playerRealm then
		if message == 'REQUESTINFO' then
			MXP:SendMessage()
		else
			MXP:UpdateBar(MXP:GetAssignedBar(sender), message)
		end
	elseif event == 'BN_CHAT_MSG_ADDON' and MXP.db.BattleNet and MXP.BNFriends[sender] then
		if message == 'REQUESTINFO' then
			MXP:SendMessage()
		else
			MXP:UpdateBar(MXP:GetAssignedBar(MXP.BNFriends[sender].battleTag), message)
		end
	end
end

function MXP:GetOptions()
	local MasterExperience = PA.ACH:Group(MXP.Title, MXP.Description, nil, nil, function(info) return MXP.db[info[#info]] end)
	PA.Options.args.MasterExperience = MasterExperience

	MasterExperience.args.Description = PA.ACH:Description(MXP.Description, 0)
	MasterExperience.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) MXP.db[info[#info]] = value if not MXP.isEnabled then MXP:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	MasterExperience.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, function(info) return MXP.db[info[#info]] end, function(info, value) MXP.db[info[#info]] = value MXP:UpdateCurrentBars() end)
	MasterExperience.args.General.inline = true
	MasterExperience.args.General.args.Party = PA.ACH:Toggle(PA.ACL['Party'], nil, 0, nil, nil, nil, nil, function(info, value) MXP.db[info[#info]] = value MXP:UpdateAllBars() end)
	MasterExperience.args.General.args.BattleNet = PA.ACH:Toggle(PA.ACL['BattleNet'], nil, 1, nil, nil, nil, nil, function(info, value) MXP.db[info[#info]] = value MXP:UpdateAllBars() end)
	MasterExperience.args.General.args.MouseOver = PA.ACH:Toggle(PA.ACL['MouseOver'], nil, 2)
	MasterExperience.args.General.args.GrowthDirection = PA.ACH:Select(PA.ACL['Growth Direction'], nil, 3, { UP = 'Up', DOWN = 'Down' })

	MasterExperience.args.General.args.FontGroup = PA.ACH:Group(PA.ACL['Font'], nil, 3)
	MasterExperience.args.General.args.FontGroup.inline = true
	MasterExperience.args.General.args.FontGroup.args.Font = PA.ACH:SharedMediaFont(PA.ACL['Font'], nil, 1)
	MasterExperience.args.General.args.FontGroup.args.FontSize = PA.ACH:Range(PA.ACL['Font Size'], nil, 2, { min = 6, max = 22, step = 1 })
	MasterExperience.args.General.args.FontGroup.args.FontFlag = PA.ACH:FontFlags(PA.ACL['Font Outline'], nil, 3)

	MasterExperience.args.General.args.SizeGroup = PA.ACH:Group(PA.ACL['Size'], nil, -2, nil, nil, function(info, value) MXP.db[info[#info]] = value MXP:UpdateCurrentBars() end)
	MasterExperience.args.General.args.SizeGroup.args.Width = PA.ACH:Range(PA.ACL['Width'], nil, 1, { min = 1, max = 512, step = 1 })
	MasterExperience.args.General.args.SizeGroup.args.Height = PA.ACH:Range(PA.ACL['Height'], nil, 2, { min = 1, max = 64, step = 1 })

	MasterExperience.args.General.args.Colors = PA.ACH:Group(PA.ACL["Colors"], nil, -1, nil, function(info) local t = MXP.db.Colors[info[#info]] return t.r, t.g, t.b, t.a end, function(info, r, g, b, a) local t = MXP.db.Colors[info[#info]] t.r, t.g, t.b, t.a = r, g, b, a MXP:UpdateCurrentBars() end)
	MasterExperience.args.General.args.Colors.args.ColorByClass = PA.ACH:Toggle(PA.ACL['Color By Class'], nil, 0, nil, nil, nil, function(info) return MXP.db[info[#info]] end, function(info, value) MXP.db[info[#info]] = value MXP:UpdateCurrentBars() end)
	MasterExperience.args.General.args.Colors.args.Experience = PA.ACH:Color('Experience', nil, 1, true)
	MasterExperience.args.General.args.Colors.args.Rested = PA.ACH:Color('Rested', nil, 2, true)
	MasterExperience.args.General.args.Colors.args.Quest = PA.ACH:Color('Quest', nil, 3, true)

	MasterExperience.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	MasterExperience.args.Authors = PA.ACH:Description(MXP.Authors, -1, 'large')
end

function MXP:BuildProfile()
	PA.Defaults.profile.MasterExperience = {
		Enable = false,
		ColorByClass = false,
		BattleNet = true,
		Party = true,
		GrowthDirection = 'UP',
		Width = 256,
		Height = 20,
		Font = 'Arial Narrow',
		FontSize = 12,
		FontFlag = 'OUTLINE',
		Colors = {
			Experience = { r = 0, g = .4, b = 1, a = .8 },
			Rested = { r = 1, g = 0, b = 1, a = .2},
			Quest = { r = 0, g = 1, b = 0, a = .5}
		},
	}
end

function MXP:UpdateSettings()
	MXP.db = PA.db.MasterExperience
end

function MXP:Initialize()
	MXP:UpdateSettings()

	if MXP.db.Enable ~= true then
		return
	end

	MXP.isEnabled = true

	_G.C_ChatInfo.RegisterAddonMessagePrefix('PA_MXP')

	if PA.Tukui then
		_G.Tukui[1].Movers:RegisterFrame(MXP.MasterExperience)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(MXP.MasterExperience, 'MasterExperienceMover', 'Master Experience Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,MasterExperience')
	else
		MXP.MasterExperience:SetScript('OnDragStart', MXP.MasterExperience.StartMoving)
		MXP.MasterExperience:SetScript('OnDragStop', MXP.MasterExperience.StopMovingOrSizing)
	end

	MXP:RegisterEvent('BN_CHAT_MSG_ADDON', 'RecieveMessage')
	MXP:RegisterEvent('CHAT_MSG_ADDON', 'RecieveMessage')
	MXP:RegisterEvent('DISABLE_XP_GAIN', 'SendMessage')
	MXP:RegisterEvent('ENABLE_XP_GAIN', 'SendMessage')
	MXP:RegisterEvent('QUEST_LOG_UPDATE')
	MXP:RegisterEvent('GROUP_ROSTER_UPDATE', 'UpdateAllBars')
	MXP:RegisterEvent('BN_FRIEND_INFO_CHANGED', 'BattleNetUpdate')
	MXP:RegisterEvent('BN_FRIEND_ACCOUNT_ONLINE', 'HandleBNET')
	MXP:RegisterEvent('BN_FRIEND_ACCOUNT_OFFLINE', 'HandleBNET')
	MXP:RegisterEvent('PLAYER_XP_UPDATE')
	MXP:RegisterEvent('UPDATE_EXHAUSTION')
	MXP:RegisterEvent('PLAYER_LEVEL_UP')
	MXP:RegisterEvent("BN_CONNECTED", 'HandleBNStatus')
	MXP:RegisterEvent("BN_DISCONNECTED", 'HandleBNStatus')

	MXP:BattleTag()

	MXP:HandleBNStatus()
	MXP:HandleBNET()
	MXP:UPDATE_EXHAUSTION()
	MXP:PLAYER_XP_UPDATE()
	MXP:QUEST_LOG_UPDATE()
	MXP:PLAYER_LEVEL_UP()

	MXP:UpdateAllBars()

	if IsPlayerAtEffectiveMaxLevel() then -- Place in recieve only mode.
		MXP:SendMessage()
	else
		MXP:ScheduleRepeatingTimer('SendMessage', 2)
	end
end
