local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local FG = PA:NewModule('FriendGroups', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
_G.FriendGroups= FG

FG.Title, FG.Description, FG.Authors, FG.Credits = 'Friend Groups', ACL['Manage Friends List with Groups'], 'Azilroka', 'Mikeprod    frankkkkk'

local FRIENDS_GROUP_NAME_COLOR = NORMAL_FONT_COLOR

local ONE_YEAR = 31536000

local FriendListEntries = {}
local GroupCount = 0
local GroupTotal = {}
local GroupOnline = {}
local GroupSorted = {}

local FriendRequestString = string.sub(FRIEND_REQUESTS,1,-6)

local OPEN_DROPDOWNMENUS_SAVE = nil

local friend_popup_menus = { "FRIEND", "FRIEND_OFFLINE", "BN_FRIEND", "BN_FRIEND_OFFLINE" }

UnitPopupButtons["FRIEND_GROUP_NEW"] = { text = "Create new group"}
UnitPopupButtons["FRIEND_GROUP_ADD"] = { text = "Add to group", nested = 1}
UnitPopupButtons["FRIEND_GROUP_DEL"] = { text = "Remove from group", nested = 1}
UnitPopupMenus["FRIEND_GROUP_ADD"] = { }
UnitPopupMenus["FRIEND_GROUP_DEL"] = { }

local FriendsScrollFrame
local FriendButtonTemplate

if FriendsListFrameScrollFrame then
	FriendsScrollFrame = FriendsListFrameScrollFrame
	FriendButtonTemplate = "FriendsListButtonTemplate"
else
	FriendsScrollFrame = FriendsFrameFriendsScrollFrame
	FriendButtonTemplate = "FriendsFrameButtonTemplate"
end

function FG:FriendGroups_GetTopButton(offset)
	local usedHeight = 0
	for i = 1, #FriendListEntries do
		local buttonHeight = FRIENDS_BUTTON_HEIGHTS[FriendListEntries[i].buttonType]
		if ( usedHeight + buttonHeight >= offset ) then
			return i - 1, offset - usedHeight
		else
			usedHeight = usedHeight + buttonHeight
		end
	end
end

function FG:GetOnlineInfoText(client, isMobile, rafLinkType, locationText)
	if not locationText or locationText == "" then
		return UNKNOWN
	end
	if isMobile then
		return LOCATION_MOBILE_APP
	end
	if (client == BNET_CLIENT_WOW) and (rafLinkType ~= Enum.RafLinkType.None) and not isMobile then
		if rafLinkType == Enum.RafLinkType.Recruit then
			return RAF_RECRUIT_FRIEND:format(locationText)
		else
			return RAF_RECRUITER_FRIEND:format(locationText)
		end
	end
	return locationText
end

function FG:FriendGroups_UpdateFriendButton(button)
	local index = button.index
	button.buttonType = FriendListEntries[index].buttonType
	button.id = FriendListEntries[index].id
	local height = FRIENDS_BUTTON_HEIGHTS[button.buttonType]
	local nameText, nameColor, infoText, broadcastText, isFavoriteFriend
	if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
		local info = C_FriendList.GetFriendInfoByIndex(FriendListEntries[index].id)
		broadcastText = nil
		if info.connected then
			button.background:SetColorTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a)
			if info.afk then
				button.status:SetTexture(FRIENDS_TEXTURE_AFK)
			elseif ( info.dnd ) then
				button.status:SetTexture(FRIENDS_TEXTURE_DND)
			else
				button.status:SetTexture(FRIENDS_TEXTURE_ONLINE)
			end

			nameColor = PA:ClassColorCode(info.gameAccountInfo.className)

			nameText = info.name..", "..format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className)
			if PA.Retail then
				infoText = FG:GetOnlineInfoText(BNET_CLIENT_WOW, info.mobile, info.rafLinkType, info.area)
			end
		else
			button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
			button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE)
			nameText = info.name
			nameColor = FRIENDS_GRAY_COLOR
			infoText = FRIENDS_LIST_OFFLINE
		end
		button.gameIcon:Hide()
		button.summonButton:ClearAllPoints()
		button.summonButton:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, -1)
		FriendsFrame_SummonButton_Update(button.summonButton)
	elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
		local accountInfo = _G.C_BattleNet.GetFriendAccountInfo(button.id)
		if accountInfo then
			nameText = accountInfo.accountName
			infoText = accountInfo.gameAccountInfo.richPresence

			if accountInfo.gameAccountInfo.isOnline then
				button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a)
				if accountInfo.isAFK or accountInfo.gameAccountInfo.isGameAFK then
					button.status:SetTexture(FRIENDS_TEXTURE_AFK)
				elseif accountInfo.isDND or accountInfo.gameAccountInfo.isGameBusy then
					button.status:SetTexture(FRIENDS_TEXTURE_DND)
				else
					button.status:SetTexture(FRIENDS_TEXTURE_ONLINE)
				end

				if accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and accountInfo.gameAccountInfo.wowProjectID == WOW_PROJECT_ID then
					if not accountInfo.gameAccountInfo.areaName or accountInfo.gameAccountInfo.areaName == "" then
						infoText = UNKNOWN
					else
						infoText = accountInfo.gameAccountInfo.isWowMobile and LOCATION_MOBILE_APP or info.gameAccountInfo.areaName
					end
				end

				button.gameIcon:SetTexture(BNet_GetClientTexture(accountInfo.gameAccountInfo.clientProgram))
				nameColor = FRIENDS_BNET_NAME_COLOR

				local fadeIcon = (accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW) and (accountInfo.gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID)
				button.gameIcon:SetAlpha(fadeIcon and .6 or 1)

				local shouldShowSummonButton = FriendsFrame_ShouldShowSummonButton(button.summonButton)
				button.gameIcon:SetShown(not shouldShowSummonButton)

				local restriction = FriendsFrame_GetInviteRestriction(button.id)
				button.travelPassButton:SetEnabled(restriction == INVITE_RESTRICTION_NONE)
				button.travelPassButton:SetShown(restriction == INVITE_RESTRICTION_NONE)
			else
				button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
				button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE)
				nameColor = FRIENDS_GRAY_COLOR
				button.gameIcon:Hide()
				if ( not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR ) then
					infoText = FRIENDS_LIST_OFFLINE
				else
					infoText = string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline))
				end
			end
			button.summonButton:ClearAllPoints()
			button.summonButton:SetPoint("CENTER", button.gameIcon, "CENTER", 1, 0)
			FriendsFrame_SummonButton_Update(button.summonButton)
		end
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
		local title
		local group = FriendListEntries[index].text
		if group == "" or not group then
			title = "[no group]"
		else
			title = group
		end
		local counts = "(" .. GroupOnline[group] .. "/" .. GroupTotal[group] .. ")"

		if button["text"] then
			button.text:SetText(title)
			button.text:Show()
			nameText = counts
			button.name:SetJustifyH("RIGHT")
		else
			nameText = title.." "..counts
			button.name:SetJustifyH("CENTER")
		end
		nameColor = FRIENDS_GROUP_NAME_COLOR

--		if FriendGroups_SavedVars.collapsed[group] then
--			button.status:SetTexture("Interface\\Buttons\\UI-PlusButton-UP")
--		else
			button.status:SetTexture("Interface\\Buttons\\UI-MinusButton-UP")
--		end
		infoText = group
		button.info:Hide()
		button.gameIcon:Hide()
		button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
		button.background:SetAlpha(0.5)
		local scrollFrame = FriendsScrollFrame
		--[[local divider = scrollFrame.dividerPool:Acquire()
		divider:SetParent(scrollFrame.ScrollChild)
		divider:SetAllPoints(button)
		divider:Show()--]]
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE_HEADER ) then
		local header = FriendsScrollFrame.PendingInvitesHeaderButton
		header:SetPoint("TOPLEFT", button, 1, 0)
		header:Show()
		header:SetFormattedText(FRIEND_REQUESTS, BNGetNumFriendInvites())
		local collapsed = GetCVarBool("friendInvitesCollapsed")
		if ( collapsed ) then
			header.DownArrow:Hide()
			header.RightArrow:Show()
		else
			header.DownArrow:Show()
			header.RightArrow:Hide()
		end
		nameText = nil
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE ) then
		local scrollFrame = FriendsScrollFrame
		local invite = scrollFrame.invitePool:Acquire()
		invite:SetParent(scrollFrame.ScrollChild)
		invite:SetAllPoints(button)
		invite:Show()
		local inviteID, accountName = BNGetFriendInviteInfo(button.id)
		invite.Name:SetText(accountName)
		invite.inviteID = inviteID
		invite.inviteIndex = button.id
		nameText = nil
	end
	-- selection
	if ( FriendsFrame.selectedFriendType == FriendListEntries[index].buttonType and FriendsFrame.selectedFriend == FriendListEntries[index].id ) then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
	-- finish setting up button if it's not a header
	if ( nameText ) then
		if button.buttonType ~= FRIENDS_BUTTON_TYPE_DIVIDER then
		if button["text"] then
			button.text:Hide()
		end
			button.name:SetJustifyH("LEFT")
			button.background:SetAlpha(1)
			button.info:Show()
		end
		button.name:SetText(nameText)
		button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
		button.info:SetText(infoText)
		button:Show()
		if isFavoriteFriend and button.Favorite then
			button.Favorite:Show()
			button.Favorite:ClearAllPoints()
			button.Favorite:SetPoint("TOPLEFT", button.name, "TOPLEFT", button.name:GetStringWidth(), 0)
		elseif button.Favorite then
			button.Favorite:Hide()
		end
	else
		button:Hide()
	end
	-- update the tooltip if hovering over a button
	if ( FriendsTooltip.button == button ) or ( GetMouseFocus() == button ) then
		if FriendsFrameTooltip_Show then
			FriendsFrameTooltip_Show(button)
		else
			button:OnEnter()
		end
	end
	return height
end


function FG:FriendGroups_UpdateFriends()
	local scrollFrame = FriendsScrollFrame
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	local numButtons = #buttons
	local numFriendListEntries = #FriendListEntries

	local usedHeight = 0

	scrollFrame.dividerPool:ReleaseAll()
	scrollFrame.invitePool:ReleaseAll()
	scrollFrame.PendingInvitesHeaderButton:Hide()
	for i = 1, numButtons do
		local button = buttons[i]
		local index = offset + i
		if ( index <= numFriendListEntries ) then
			button.index = index
			local height = FG:FriendGroups_UpdateFriendButton(button)
			button:SetHeight(height)
			usedHeight = usedHeight + height
		else
			button.index = nil
			button:Hide()
		end
	end
	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalFriendListEntriesHeight, usedHeight)

	-- Delete unused groups in the collapsed part
--[[	for key,_ in pairs(FriendGroups_SavedVars.collapsed) do
		if not GroupTotal[key] then
			FriendGroups_SavedVars.collapsed[key] = nil
		end
	end
--]]
end

function FG:FillGroups(groups, note, ...)
	wipe(groups)
	local n = select('#', ...)
	for i = 1, n do
		local v = select(i, ...)
		v = strtrim(v)
		groups[v] = true
	end
	if n == 0 then
		groups[""] = true
	end
	return note
end

function FG:NoteAndGroups(note, groups)
	if not note then
		return FG:FillGroups(groups, "")
	end
	if groups then
		return FG:FillGroups(groups, strsplit("#", note))
	end
	return strsplit("#", note)
end

function FG:CreateNote(note, groups)
	local value = ""
	if note then
		value = note
	end
	for group in pairs(groups) do
		value = value .. "#" .. group
	end
	return value
end

function FG:AddGroup(note, group)
	local groups = {}
	note = FG:NoteAndGroups(note, groups)
	groups[""] = nil --ew
	groups[group] = true
	return FG:CreateNote(note, groups)
end

function FG:RemoveGroup(note, group)
	local groups = {}
	note = FG:NoteAndGroups(note, groups)
	groups[""] = nil --ew
	groups[group] = nil
	return FG:CreateNote(note, groups)
end

function FG:IncrementGroup(group, online)
	if not GroupTotal[group] then
		GroupCount = GroupCount + 1
		GroupTotal[group] = 0
		GroupOnline[group] = 0
	end
	GroupTotal[group] = GroupTotal[group] + 1
	if online then
		GroupOnline[group] = GroupOnline[group] + 1
	end
end

function FG:FriendGroups_Update(forceUpdate)
	local numBNetTotal, numBNetOnline, numBNetFavorite, numBNetFavoriteOnline = BNGetNumFriends()
	numBNetFavorite = numBNetFavorite or 0
	numBNetFavoriteOnline = numBNetFavoriteOnline or 0
	local numBNetOffline = numBNetTotal - numBNetOnline
	local numBNetFavoriteOffline = numBNetFavorite - numBNetFavoriteOnline
	local numWoWTotal = C_FriendList.GetNumFriends()
	local numWoWOnline = C_FriendList.GetNumOnlineFriends()
	local numWoWOffline = numWoWTotal - numWoWOnline

	if QuickJoinToastButton then
		QuickJoinToastButton:UpdateDisplayedFriendCount()
	end
	if ( not FriendsListFrame:IsShown() and not forceUpdate) then
		return
	end

	wipe(FriendListEntries)
	wipe(GroupTotal)
	wipe(GroupOnline)
	wipe(GroupSorted)
	GroupCount = 0

	local BnetFriendGroups = {}
	local WowFriendGroups = {}
	local FriendReqGroup = {}

	local buttonCount = 0

	FriendListEntries.count = 0
	local addButtonIndex = 0
	local totalButtonHeight = 0
	local function AddButtonInfo(buttonType, id)
		addButtonIndex = addButtonIndex + 1
		if ( not FriendListEntries[addButtonIndex] ) then
			FriendListEntries[addButtonIndex] = { }
		end
		FriendListEntries[addButtonIndex].buttonType = buttonType
		FriendListEntries[addButtonIndex].id = id
		FriendListEntries.count = FriendListEntries.count + 1
		totalButtonHeight = totalButtonHeight + FRIENDS_BUTTON_HEIGHTS[buttonType]
	end

	-- invites
	local numInvites = BNGetNumFriendInvites()
	if ( numInvites > 0 ) then
		for i = 1, numInvites do
			if not FriendReqGroup[i] then
				FriendReqGroup[i] = {}
			end
			FG:IncrementGroup(FriendRequestString,true)
			FG:NoteAndGroups(nil, FriendReqGroup[i])
			--if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_INVITE, i)
			--end
		end
	end

	-- favorite friends online
	for i = 1, numBNetFavoriteOnline do
		if not BnetFriendGroups[i] then
			BnetFriendGroups[i] = {}
		end
		local noteText = select(13,BNGetFriendInfo(i))
		FG:NoteAndGroups(noteText, BnetFriendGroups[i])
		for group in pairs(BnetFriendGroups[i]) do
			FG:IncrementGroup(group, true)
			--if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i)
			--end
		end
	end
	--favorite friends offline
	for i = 1, numBNetFavoriteOffline do
		local j = i + numBNetFavoriteOnline
		if not BnetFriendGroups[j] then
			BnetFriendGroups[j] = {}
		end
		local noteText = select(13,BNGetFriendInfo(j))
		FG:NoteAndGroups(noteText, BnetFriendGroups[j])
		for group in pairs(BnetFriendGroups[j]) do
			FG:IncrementGroup(group)
			--if not FriendGroups_SavedVars.collapsed[group] and not FriendGroups_SavedVars.hide_offline then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, j)
			--end
		end
	end
	-- online Battlenet friends
	for i = 1, numBNetOnline - numBNetFavoriteOnline do
		local j = i + numBNetFavorite
		if not BnetFriendGroups[j] then
			BnetFriendGroups[j] = {}
		end
		local noteText = select(13,BNGetFriendInfo(j))
		FG:NoteAndGroups(noteText, BnetFriendGroups[j])
		for group in pairs(BnetFriendGroups[j]) do
			FG:IncrementGroup(group, true)
			--if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, j)
			--end
		end
	end
	-- online WoW friends
	for i = 1, numWoWOnline do
		if not WowFriendGroups[i] then
			WowFriendGroups[i] = {}
		end
		local note = C_FriendList.GetFriendInfoByIndex(i) and C_FriendList.GetFriendInfoByIndex(i).notes
		FG:NoteAndGroups(note, WowFriendGroups[i])
		for group in pairs(WowFriendGroups[i]) do
			FG:IncrementGroup(group, true)
			--if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, i)
			--end
		end
	end
	-- offline Battlenet friends
	for i = 1, numBNetOffline - numBNetFavoriteOffline do
		local j = i + numBNetFavorite + numBNetOnline - numBNetFavoriteOnline
		if not BnetFriendGroups[j] then
			BnetFriendGroups[j] = {}
		end
		local noteText = select(13,BNGetFriendInfo(j))
		FG:NoteAndGroups(noteText, BnetFriendGroups[j])
		for group in pairs(BnetFriendGroups[j]) do
			FG:IncrementGroup(group)
			--if not FriendGroups_SavedVars.collapsed[group] and not FriendGroups_SavedVars.hide_offline then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, j)
			--end
		end
	end
	-- offline WoW friends
	for i = 1, numWoWOffline do
		local j = i + numWoWOnline
		if not WowFriendGroups[j] then
			WowFriendGroups[j] = {}
		end
		local note = C_FriendList.GetFriendInfoByIndex(j) and C_FriendList.GetFriendInfoByIndex(j).notes
		FG:NoteAndGroups(note, WowFriendGroups[j])
		for group in pairs(WowFriendGroups[j]) do
			FG:IncrementGroup(group)
			--if not FriendGroups_SavedVars.collapsed[group] and not FriendGroups_SavedVars.hide_offline then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, j)
			--end
		end
	end

	buttonCount = buttonCount + GroupCount
	-- 1.5 is a magic number which prevents the list scroll to be too long
	totalScrollHeight = totalButtonHeight + GroupCount * FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_DIVIDER]

	FriendsScrollFrame.totalFriendListEntriesHeight = totalScrollHeight
	FriendsScrollFrame.numFriendListEntries = addButtonIndex

	if buttonCount > #FriendListEntries then
		for i = #FriendListEntries + 1, buttonCount do
			FriendListEntries[i] = {}
		end
	end

	for group in pairs(GroupTotal) do
		table.insert(GroupSorted, group)
	end
	table.sort(GroupSorted)

	if GroupSorted[1] == "" then
		table.remove(GroupSorted, 1)
		table.insert(GroupSorted, "")
	end

	for key,val in pairs(GroupSorted) do
		if val == FriendRequestString then
			table.remove(GroupSorted,key)
			table.insert(GroupSorted,1,FriendRequestString)
		end
	end

	local index = 0
	for _,group in ipairs(GroupSorted) do
		index = index + 1
		FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_DIVIDER
		FriendListEntries[index].text = group
		--if not FriendGroups_SavedVars.collapsed[group] then
			for i = 1, #FriendReqGroup do
				if group == FriendRequestString then
					index = index + 1
					FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_INVITE
					FriendListEntries[index].id = i
				end
			end
			for i = 1, numBNetFavoriteOnline do
				if BnetFriendGroups[i][group] then
					index = index + 1
					FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_BNET
					FriendListEntries[index].id = i
				end
			end
			for i = numBNetFavorite + 1, numBNetOnline + numBNetFavoriteOffline do
				if BnetFriendGroups[i][group] then
					index = index + 1
					FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_BNET
					FriendListEntries[index].id = i
				end
			end
			for i = 1, numWoWOnline do
				if WowFriendGroups[i][group] then
					index = index + 1
					FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_WOW
					FriendListEntries[index].id = i
				end
			end
			--if not FriendGroups_SavedVars.hide_offline then
				for i = numBNetFavoriteOnline + 1, numBNetFavorite do
					if BnetFriendGroups[i][group] then
						index = index + 1
						FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_BNET
						FriendListEntries[index].id = i
					end
				end
				for i = numBNetOnline + numBNetFavoriteOffline + 1, numBNetTotal do
					if BnetFriendGroups[i][group] then
						index = index + 1
						FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_BNET
						FriendListEntries[index].id = i
					end
				end
				for i = numWoWOnline + 1, numWoWTotal do
					if WowFriendGroups[i][group] then
						index = index + 1
						FriendListEntries[index].buttonType = FRIENDS_BUTTON_TYPE_WOW
						FriendListEntries[index].id = i
					end
				end
			--end
		--end
	end
	FriendListEntries.count = index

	-- selection
	local selectedFriend = 0
	-- check that we have at least 1 friend
	if numBNetTotal + numWoWTotal > 0 then
		-- get friend
		if FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW then
			selectedFriend = C_FriendList.GetSelectedFriend()
		elseif FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET then
			selectedFriend = BNGetSelectedFriend()
		end
		-- set to first in list if no friend
		if not selectedFriend or selectedFriend == 0 then
			FriendsFrame_SelectFriend(FriendListEntries[1].buttonType, 1)
			selectedFriend = 1
		end
		-- check if friend is online
		FriendsFrameSendMessageButton:SetEnabled(FriendsList_CanWhisperFriend(FriendsFrame.selectedFriendType, selectedFriend))
	else
		FriendsFrameSendMessageButton:Disable()
	end
	FriendsFrame.selectedFriend = selectedFriend

	-- RID warning, upon getting the first RID invite
	local showRIDWarning = false
	local numInvites = BNGetNumFriendInvites()
	if ( numInvites > 0 and not GetCVarBool("pendingInviteInfoShown") ) then
		local _, _, _, _, _, _, isRIDEnabled = BNGetInfo()
		if ( isRIDEnabled ) then
			for i = 1, numInvites do
				local inviteID, accountName, isBattleTag = BNGetFriendInviteInfo(i)
				if ( not isBattleTag ) then
					-- found one
					showRIDWarning = true
					break
				end
			end
		end
	end
	if showRIDWarning then
		FriendsListFrame.RIDWarning:Show()
		FriendsScrollFrame.scrollBar:Disable()
		FriendsScrollFrame.scrollUp:Disable()
		FriendsScrollFrame.scrollDown:Disable()
	else
		FriendsListFrame.RIDWarning:Hide()
	end
	FG:FriendGroups_UpdateFriends()
end

function FG:FriendGroups_SaveOpenMenu()
	if OPEN_DROPDOWNMENUS then
		OPEN_DROPDOWNMENUS_SAVE = CopyTable(OPEN_DROPDOWNMENUS)
	end
end

-- when one of our new menu items is clicked
function FG:FriendGroups_OnFriendMenuClick(self)
	if not self.value then
		return
	end

	local add = strmatch(self.value, "FGROUPADD_(.+)")
	local del = strmatch(self.value, "FGROUPDEL_(.+)")
	local creating = self.value == "FRIEND_GROUP_NEW"

	if add or del or creating then
		local dropdown = UIDROPDOWNMENU_INIT_MENU
		local source = OPEN_DROPDOWNMENUS_SAVE[1] and OPEN_DROPDOWNMENUS_SAVE[1].which or self.owner -- OPEN_DROPDOWNMENUS is nil on click

		if source == "BN_FRIEND" or source == "BN_FRIEND_OFFLINE" then
			local note = select(13, BNGetFriendInfoByID(dropdown.bnetIDAccount))
			if creating then
				StaticPopup_Show("FRIEND_GROUP_CREATE", nil, nil, { id = dropdown.bnetIDAccount, note = note, set = BNSetFriendNote })
			else
				if add then
					note = FG:AddGroup(note, add)
				else
					note = FG:RemoveGroup(note, del)
				end
				BNSetFriendNote(dropdown.bnetIDAccount, note)
			end
		elseif source == "FRIEND" or source == "FRIEND_OFFLINE" then
			for i = 1, C_FriendList.GetNumFriends() do
				local friend_info = C_FriendList.GetFriendInfoByIndex(i)
				local name = friend_info.name
				local note = friend_info.notes
				if dropdown.name and name:find(dropdown.name) then
					if creating then
						StaticPopup_Show("FRIEND_GROUP_CREATE", nil, nil, { id = i, note = note, set = SetFriendNotes })
					else
						if add then
							note = FG:AddGroup(note, add)
						else
							note = FG:RemoveGroup(note, del)
						end
						SetFriendNotes(i, note)
					end
					break
				end
			end
		end
		FG:FriendGroups_Update()
	end
	HideDropDownMenu(1)
end

-- hide the add/remove group buttons if we're not right clicking on a friendlist item
function FG:FriendGroups_HideButtons()
	local dropdown = UIDROPDOWNMENU_INIT_MENU

	local hidden = false
	for index, value in ipairs(UnitPopupMenus[UIDROPDOWNMENU_MENU_VALUE] or UnitPopupMenus[dropdown.which]) do
		if value == "FRIEND_GROUP_ADD" or value == "FRIEND_GROUP_DEL" or value == "FRIEND_GROUP_NEW" then
			if not dropdown.friendsList then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0
				hidden = true
			end
		end
	end

	if not hidden then
		wipe(UnitPopupMenus["FRIEND_GROUP_ADD"])
		wipe(UnitPopupMenus["FRIEND_GROUP_DEL"])
		local groups = {}
		local note = nil

		if dropdown.bnetIDAccount then
			note = select(13, BNGetFriendInfoByID(dropdown.bnetIDAccount))
		else
			for i = 1, C_FriendList.GetNumFriends() do
				local friend_info = C_FriendList.GetFriendInfoByIndex(i)
				local name = friend_info.name
				local noteText = friend_info.notes
				if dropdown.name and name:find(dropdown.name) then
					note = noteText
					break
				end
			end
		end

		FG:NoteAndGroups(note, groups)

		for _,group in ipairs(GroupSorted) do
			if group ~= "" and not groups[group] then
				local faux = "FGROUPADD_" .. group
				--polluting the popup buttons list
				UnitPopupButtons[faux] = { text = group}
				table.insert(UnitPopupMenus["FRIEND_GROUP_ADD"], faux)
			end
		end
		for group in pairs(groups) do
			if group ~= "" then
				local faux = "FGROUPDEL_" .. group
				UnitPopupButtons[faux] = { text = group}
				table.insert(UnitPopupMenus["FRIEND_GROUP_DEL"], faux)
			end
		end
	end
end

function FG:FriendGroups_Rename(self, old)
	local input = self.editBox:GetText()
	if input == "" then
		return
	end
	local groups = {}
	for i = 1, BNGetNumFriends() do
		local presenceID, _, _, _, _, _, _, _, _, _, _, _, noteText = BNGetFriendInfo(i)
		local note = FG:NoteAndGroups(noteText, groups)
		if groups[old] then
			groups[old] = nil
			groups[input] = true
			note = FG:CreateNote(note, groups)
			BNSetFriendNote(presenceID, note)
		end
	end
	for i = 1, C_FriendList.GetNumFriends() do
		local note = C_FriendList.GetFriendInfoByIndex(i) and C_FriendList.GetFriendInfoByIndex(i).notes
		note = FG:NoteAndGroups(note, groups)
		if groups[old] then
			groups[old] = nil
			groups[input] = true
			note = FG:CreateNote(note, groups)
			SetFriendNotes(i, note)
		end
	end
	FG:FriendGroups_Update()
end

function FG:FriendGroups_Create(self, data)
	local input = self.editBox:GetText()
	if input == "" then
		return
	end
	local note = FG:AddGroup(data.note, input)
	data.set(data.id, note)
end

StaticPopupDialogs["FRIEND_GROUP_RENAME"] = {
	text = "Enter new group name",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = FG.FriendGroups_Rename,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		FG:FriendGroups_Rename(parent, parent.data)
		parent:Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["FRIEND_GROUP_CREATE"] = {
	text = "Enter new group name",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = FG.FriendGroups_Create,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		FG:FriendGroups_Create(parent, parent.data)
		parent:Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

function FG:InviteOrGroup(clickedgroup, invite)
	local groups = {}
	for i = 1, BNGetNumFriends() do
		local presenceID, _, _, _, _, toonID, _, _, _, _, _, _, noteText = BNGetFriendInfo(i)
		local note = FG:NoteAndGroups(noteText, groups)
		if groups[clickedgroup] then
			if invite and toonID then
				BNInviteFriend(toonID)
			elseif not invite then
				groups[clickedgroup] = nil
				note = FG:CreateNote(note, groups)
				BNSetFriendNote(presenceID, note)
			end
		end
	end
	for i = 1, C_FriendList.GetNumFriends() do
		local friend_info = C_FriendList.GetFriendInfoByIndex(i)
		local name = friend_info.name
		local connected = friend_info.connected
		local noteText = friend_info.notes
		local note = FG:NoteAndGroups(noteText, groups)
		if groups[clickedgroup] then
			if invite and connected then
				InviteUnit(name)
			elseif not invite then
				groups[clickedgroup] = nil
				note = FG:CreateNote(note, groups)
				SetFriendNotes(i, note)
			end
		end
	end
end

local FriendGroups_Menu = CreateFrame("Frame", "FriendGroups_Menu")
FriendGroups_Menu.displayMode = "MENU"
local menu_items = {
	[1] = {
		{ text = "", notCheckable = true, isTitle = true },
		{ text = "Invite all to party", notCheckable = true, func = function(self, menu, clickedgroup) FG:InviteOrGroup(clickedgroup, true) end },
		{ text = "Rename group", notCheckable = true, func = function(self, menu, clickedgroup) StaticPopup_Show("FRIEND_GROUP_RENAME", nil, nil, clickedgroup) end },
		{ text = "Remove group", notCheckable = true, func = function(self, menu, clickedgroup) FG:InviteOrGroup(clickedgroup, false) end },
		{ text = "Settings", notCheckable = true, hasArrow = true },
	},
}

FriendGroups_Menu.initialize = function(self, level)
	if not menu_items[level] then return end
	for _, items in ipairs(menu_items[level]) do
		local info = UIDropDownMenu_CreateInfo()
		for prop, value in pairs(items) do
			info[prop] = value ~= "" and value or UIDROPDOWNMENU_MENU_VALUE ~= "" and UIDROPDOWNMENU_MENU_VALUE or "[no group]"
		end
		info.arg1 = k
		info.arg2 = UIDROPDOWNMENU_MENU_VALUE
		UIDropDownMenu_AddButton(info, level)
	end
end

function FG:FriendGroups_OnClick(self, button)
	if self["text"] and not self.text:IsShown() then
		--hooks["FriendsFrameFriendButton_OnClick"](self, button)
		return
	end

	if self.buttonType ~= FRIENDS_BUTTON_TYPE_DIVIDER then
		if FriendsListButtonMixin then
			FriendsListButtonMixin.OnClick(self, button)
			return
		end
	end

	local group = self.info:GetText() or ""
	if button == "RightButton" then
		ToggleDropDownMenu(1, group, FriendGroups_Menu, "cursor", 0, 0)
	else
		--FriendGroups_SavedVars.collapsed[group] = not FriendGroups_SavedVars.collapsed[group]
		FG:FriendGroups_Update()
	end
end

function FG:FriendGroups_OnEnter(self)
	if ( self.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
		if FriendsTooltip:IsShown() then
			FriendsTooltip:Hide()
		end
		return
	end
end

function FG:HookButtons()
	local scrollFrame = FriendsScrollFrame
	local buttons = scrollFrame.buttons
	local numButtons = #buttons
	for i = 1, numButtons do
		if not FriendsFrameFriendButton_OnClick then
			buttons[i]:SetScript("OnClick", function(s) FG:FriendGroups_OnClick(s) end)
		end
		if not FriendsFrameTooltip_Show then
			buttons[i]:HookScript("OnEnter", function(s) FG:FriendGroups_OnEnter(s) end)
		end
	end
end

function FG:GetOptions()
	PA.Options.args.FriendGroups = {
		type = 'group',
		name = FG.Title,
		desc = FG.Description,
		get = function(info) return FG.db[info[#info]] end,
		set = function(info, value) FG.db[info[#info]] = value end,
		args = {
			Description = {
				order = 0,
				type = 'description',
				name = FG.Description,
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = ACL['Enable'],
				set = function(info, value)
					FG.db[info[#info]] = value
					if (not FG.isEnabled) then
						FG:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			General = {
				order = 2,
				type = 'group',
				name = ACL['General'],
				guiInline = true,
				args = {},
			},
			AuthorHeader = {
				order = -2,
				type = 'header',
				name = ACL['Authors:'],
			},
			Authors = {
				order = -1,
				type = 'description',
				name = FG.Authors,
				fontSize = 'large',
			},
		},
	}
end

function FG:BuildProfile()
	PA.Defaults.profile.FriendGroups = {
		Enable = true,
		HideOffline = false,
	}
end

function FG:UpdateSettings()
	FG.db = PA.db.FriendGroups
end

function FG:Initialize()
	if FG.db.Enable ~= true then
		return
	end

	FG.isEnabled = true

	FG:SecureHook("FriendsList_Update", 'FriendGroups_Update')

	FG:RawHook("FriendsFrame_UpdateFriends", 'FriendGroups_UpdateFriends', true)

	FG:SecureHook("UnitPopup_ShowMenu", 'FriendGroups_SaveOpenMenu')
	FG:SecureHook("UnitPopup_OnClick", 'FriendGroups_OnFriendMenuClick')
	FG:SecureHook("UnitPopup_HideButtons", 'FriendGroups_HideButtons')

	if FriendsFrameFriendButton_OnClick then
		FG:RawHook("FriendsFrameFriendButton_OnClick", 'FriendGroups_OnClick')
	end
	if FriendsFrameTooltip_Show then
		FG:SecureHook("FriendsFrameTooltip_Show", 'FriendGroups_OnEnter')
	end

	--FriendsScrollFrame.dynamic = function(offset) print(offset) FG:FriendGroups_GetTopButton(offset) end
	FriendsScrollFrame.update = function() FG:FriendGroups_UpdateFriends() end

	--add some more buttons
	FriendsScrollFrame.buttons[1]:SetHeight(FRIENDS_FRAME_FRIENDS_FRIENDS_HEIGHT)
	HybridScrollFrame_CreateButtons(FriendsScrollFrame, FriendButtonTemplate)

	--tremove(UnitPopupMenus["BN_FRIEND"], 5) --remove target option

	--add our add/remove group buttons to the friend list popup menus
	for _,menu in ipairs(friend_popup_menus) do
		tinsert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "FRIEND_GROUP_NEW")
		tinsert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "FRIEND_GROUP_ADD")
		tinsert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "FRIEND_GROUP_DEL")
	end

	FG:HookButtons()
end
