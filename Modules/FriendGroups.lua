local PA = _G.ProjectAzilroka
local FG = PA:NewModule('FriendGroup', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
_G.FriendGroup = FG

FG.Title = '|cFF16C3F2Friend|r |cFFFFFFFFGroups|r'
FG.Desciption = 'Manage Firends List with Groups'
FG.Authors = 'Azilroka'
FG.Credits = 'Mikeprod    frankkkkk'

local hooks = {}

local function Hook(source, target, secure)
	hooks[source] = _G[source]
	if secure then
		hooksecurefunc(source, target)
	else
		_G[source] = target
	end
end

local FRIENDS_GROUP_NAME_COLOR = NORMAL_FONT_COLOR

local INVITE_RESTRICTION_NO_TOONS = 0
local INVITE_RESTRICTION_CLIENT = 1
local INVITE_RESTRICTION_LEADER = 2
local INVITE_RESTRICTION_FACTION = 3
local INVITE_RESTRICTION_INFO = 4
local INVITE_RESTRICTION_NONE = 5

local ONE_MINUTE = 60
local ONE_HOUR = 60 * ONE_MINUTE
local ONE_DAY = 24 * ONE_HOUR
local ONE_MONTH = 30 * ONE_DAY
local ONE_YEAR = 12 * ONE_MONTH

local FriendButtons = { count = 0 }
local GroupCount = 0
local GroupTotal = {}
local GroupOnline = {}
local GroupSorted = {}

local FriendRequestString = string.sub(FRIEND_REQUESTS,1,-5)

local OPEN_DROPDOWNMENUS_SAVE = nil
local friend_popup_menus = { "FRIEND", "FRIEND_OFFLINE", "BN_FRIEND", "BN_FRIEND_OFFLINE" }
UnitPopupButtons["FRIEND_GROUP_NEW"] = { text = "Create new group", dist = 0 }
UnitPopupButtons["FRIEND_GROUP_ADD"] = { text = "Add to group", dist = 0, nested = 1 }
UnitPopupButtons["FRIEND_GROUP_DEL"] = { text = "Remove from group", dist = 0, nested = 1 }
UnitPopupMenus["FRIEND_GROUP_ADD"] = { }
UnitPopupMenus["FRIEND_GROUP_DEL"] = { }

local function ClassColourCode(class,table)
	local initialClass = class
	for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
		if class == v then
			class = k
			break
		end
	end
	if class == initialClass then
		for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			if class == v then
				class = k
				break
			end
		end
	end
	if table then
		return RAID_CLASS_COLORS[class]
	else
		local colour = RAID_CLASS_COLORS[class]
		return string.format("|cFF%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)
	end
end

local function FriendGroups_GetTopButton(offset)
	local usedHeight = 0
	for i = 1, FriendButtons.count do
		local buttonHeight = FRIENDS_BUTTON_HEIGHTS[FriendButtons[i].buttonType]
		if ( usedHeight + buttonHeight >= offset ) then
			return i - 1, offset - usedHeight
		else
			usedHeight = usedHeight + buttonHeight
		end
	end
	return 0,0
end

local function FriendGroups_UpdateFriendButton(button)
	local index = button.index
	button.buttonType = FriendButtons[index].buttonType
	button.id = FriendButtons[index].id
	local height = FRIENDS_BUTTON_HEIGHTS[button.buttonType]
	local nameText, nameColor, infoText, broadcastText
	local hasTravelPassButton = false
	if ( button.buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
		local name, level, class, area, connected, status, note, isRaF, guid = GetFriendInfo(FriendButtons[index].id)
		broadcastText = nil
		if ( connected ) then
			button.background:SetColorTexture(FRIENDS_WOW_BACKGROUND_COLOR.r, FRIENDS_WOW_BACKGROUND_COLOR.g, FRIENDS_WOW_BACKGROUND_COLOR.b, FRIENDS_WOW_BACKGROUND_COLOR.a)
			if ( status == "" ) then
				button.status:SetTexture(FRIENDS_TEXTURE_ONLINE)
			elseif ( status == CHAT_FLAG_AFK ) then
				button.status:SetTexture(FRIENDS_TEXTURE_AFK)
			elseif ( status == CHAT_FLAG_DND ) then
				button.status:SetTexture(FRIENDS_TEXTURE_DND)
			end

			if FriendGroups_SavedVars.colour_classes then
				nameColor = ClassColourCode(class,true)
			else
				nameColor = FRIENDS_WOW_NAME_COLOR
			end
			nameText = name..", "..format(FRIENDS_LEVEL_TEMPLATE, level, class)
		else
			button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
			button.status:SetTexture(FRIENDS_TEXTURE_OFFLINE)
			nameText = name
			nameColor = FRIENDS_GRAY_COLOR
		end
		infoText = area
		button.gameIcon:Hide()
		button.summonButton:ClearAllPoints()
		button.summonButton:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, -1)
		FriendsFrame_SummonButton_Update(button.summonButton)
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_BNET ) then
		local bnetIDAccount, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client, isOnline, lastOnline, isBnetAFK, isBnetDND, messageText, noteText, isRIDFriend, messageTime, canSoR = BNGetFriendInfo(FriendButtons[index].id)
		broadcastText = messageText
		-- set up player name and character name
		local characterName = characterName
		if ( accountName ) then
			nameText = accountName
			if ( isOnline ) then
				characterName = BNet_GetValidatedCharacterName(characterName, battleTag, client)
			end
		else
			nameText = UNKNOWN
		end

		-- append character name
		if ( characterName ) then
			if ( client == BNET_CLIENT_WOW and CanCooperateWithGameAccount(bnetIDGameAccount) ) then
				local level = select(11, BNGetGameAccountInfo(bnetIDGameAccount))
				if FriendGroups_SavedVars.colour_classes then
					local class = select(8, BNGetGameAccountInfo(bnetIDGameAccount))
					nameText = nameText.." "..ClassColourCode(class).."("..characterName.."-"..level..")"..FONT_COLOR_CODE_CLOSE
				else
					nameText = nameText.." "..FRIENDS_WOW_NAME_COLOR_CODE.."("..characterName.."-"..level..")"..FONT_COLOR_CODE_CLOSE
				end
			else
				local level = select(11, BNGetGameAccountInfo(bnetIDGameAccount))
				if ( ENABLE_COLORBLIND_MODE == "1" ) then
					characterName = characterName..CANNOT_COOPERATE_LABEL
				end
				if level ~= "" then
					nameText = nameText.." "..FRIENDS_OTHER_NAME_COLOR_CODE.."("..characterName.."-"..level..")"..FONT_COLOR_CODE_CLOSE
				else
					nameText = nameText.." "..FRIENDS_OTHER_NAME_COLOR_CODE.."("..characterName..")"..FONT_COLOR_CODE_CLOSE
				end
			end
		end

		if ( isOnline ) then
			local _, _, _, realmName, realmID, faction, _, _, _, zoneName, _, gameText, _, _, _, _, _, isGameAFK, isGameBusy, guid = BNGetGameAccountInfo(bnetIDGameAccount)
			button.background:SetColorTexture(FRIENDS_BNET_BACKGROUND_COLOR.r, FRIENDS_BNET_BACKGROUND_COLOR.g, FRIENDS_BNET_BACKGROUND_COLOR.b, FRIENDS_BNET_BACKGROUND_COLOR.a)
			if ( isBnetAFK or isGameAFK ) then
				button.status:SetTexture(FRIENDS_TEXTURE_AFK)
			elseif ( isBnetDND or isGameBusy ) then
				button.status:SetTexture(FRIENDS_TEXTURE_DND)
			else
				button.status:SetTexture(FRIENDS_TEXTURE_ONLINE)
			end
			if ( client == BNET_CLIENT_WOW ) then
				if ( not zoneName or zoneName == "" ) then
					infoText = UNKNOWN
				else
					infoText = zoneName
				end
			else
				infoText = gameText
			end
			button.gameIcon:SetTexture(BNet_GetClientTexture(client))
			nameColor = FRIENDS_BNET_NAME_COLOR

			--Note - this logic should match the logic in FriendsFrame_ShouldShowSummonButton

			local shouldShowSummonButton = FriendsFrame_ShouldShowSummonButton(button.summonButton)
			button.gameIcon:SetShown(not shouldShowSummonButton)

			-- travel pass
			hasTravelPassButton = true
			local restriction = FriendsFrame_GetInviteRestriction(button.id)
			if ( restriction == INVITE_RESTRICTION_NONE ) then
				button.travelPassButton:Enable()
			else
				button.travelPassButton:Disable()
			end
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
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
		local title
		local group = FriendButtons[index].text
		if group == "" or not group then
			title = "[no group]"
		else
			title = group
		end
		button.text:SetText(title)
		button.text:Show()

		local counts = "(" .. GroupOnline[group] .. "/" .. GroupTotal[group] .. ")"
		nameText = counts
		nameColor = FRIENDS_GROUP_NAME_COLOR
		button.name:SetJustifyH("RIGHT")

		if FriendGroups_SavedVars.collapsed[group] then
			button.status:SetTexture("Interface\\Buttons\\UI-PlusButton-UP")
		else
			button.status:SetTexture("Interface\\Buttons\\UI-MinusButton-UP")
		end
		infoText = group
		button.info:Hide()
		button.gameIcon:Hide()
		button.background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR.r, FRIENDS_OFFLINE_BACKGROUND_COLOR.g, FRIENDS_OFFLINE_BACKGROUND_COLOR.b, FRIENDS_OFFLINE_BACKGROUND_COLOR.a)
		button.background:SetAlpha(0.5)
		local scrollFrame = FriendsFrameFriendsScrollFrame
		local divider = scrollFrame.dividerPool:Acquire()
		divider:SetParent(scrollFrame.ScrollChild)
		divider:SetAllPoints(button)
		divider:Show()
	elseif ( button.buttonType == FRIENDS_BUTTON_TYPE_INVITE_HEADER ) then
		local header = FriendsFrameFriendsScrollFrame.PendingInvitesHeaderButton
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
		local scrollFrame = FriendsFrameFriendsScrollFrame
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
	-- travel pass?
	if ( hasTravelPassButton ) then
		button.travelPassButton:Show()
	else
		button.travelPassButton:Hide()
	end
	-- selection
	if ( FriendsFrame.selectedFriendType == FriendButtons[index].buttonType and FriendsFrame.selectedFriend == FriendButtons[index].id ) then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
	-- finish setting up button if it's not a header
	if ( nameText ) then
		if button.buttonType ~= FRIENDS_BUTTON_TYPE_DIVIDER then
			button.text:Hide()
			button.name:SetJustifyH("LEFT")
			button.background:SetAlpha(1)
			button.info:Show()
		end
		button.name:SetText(nameText)
		button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
		button.info:SetText(infoText)
		button:Show()
	else
		button:Hide()
	end
	-- update the tooltip if hovering over a button
	if ( FriendsTooltip.button == button ) then
		FriendsFrameTooltip_Show(button)
	end
	if ( GetMouseFocus() == button ) then
		FriendsFrameTooltip_Show(button)
	end
	return height
end


local function FriendGroups_UpdateFriends()
	local scrollFrame = FriendsFrameFriendsScrollFrame
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	local numButtons = #buttons
	local numFriendButtons = FriendButtons.count

	local usedHeight = 0

	scrollFrame.dividerPool:ReleaseAll()
	scrollFrame.invitePool:ReleaseAll()
	scrollFrame.PendingInvitesHeaderButton:Hide()
	for i = 1, numButtons do
		local button = buttons[i]
		local index = offset + i
		if ( index <= numFriendButtons ) then
			button.index = index
			local height = FriendGroups_UpdateFriendButton(button)
			button:SetHeight(height)
			usedHeight = usedHeight + height
		else
			button.index = nil
			button:Hide()
		end
	end
	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalFriendListEntriesHeight, usedHeight)

	if hooks["FriendsFrame_UpdateFriends"] then
		hooks["FriendsFrame_UpdateFriends"]()
	end

	-- Delete unused groups in the collapsed part
	for key,_ in pairs(FriendGroups_SavedVars.collapsed) do
		if not GroupTotal[key] then
			FriendGroups_SavedVars.collapsed[key] = nil
		end
	end
end

local function FillGroups(groups, note, ...)
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

local function NoteAndGroups(note, groups)
	if not note then
		return FillGroups(groups, "")
	end
	if groups then
		return FillGroups(groups, strsplit("#", note))
	end
	return strsplit("#", note)
end

local function CreateNote(note, groups)
	local value = ""
	if note then
		value = note
	end
	for group in pairs(groups) do
		value = value .. "#" .. group
	end
	return value
end

local function AddGroup(note, group)
	local groups = {}
	note = NoteAndGroups(note, groups)
	groups[""] = nil --ew
	groups[group] = true
	return CreateNote(note, groups)
end

local function RemoveGroup(note, group)
	local groups = {}
	note = NoteAndGroups(note, groups)
	groups[""] = nil --ew
	groups[group] = nil
	return CreateNote(note, groups)
end

local function IncrementGroup(group, online)
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

local function FriendGroups_Update(forceUpdate)
	local numBNetTotal, numBNetOnline = BNGetNumFriends()
	local numBNetOffline = numBNetTotal - numBNetOnline
	local numWoWTotal, numWoWOnline = GetNumFriends()
	local numWoWOffline = numWoWTotal - numWoWOnline

	QuickJoinToastButton:UpdateDisplayedFriendCount()
	if ( not FriendsListFrame:IsShown() and not forceUpdate) then
		return
	end

	wipe(FriendButtons)
	wipe(GroupTotal)
	wipe(GroupOnline)
	wipe(GroupSorted)
	GroupCount = 0

	local BnetFriendGroups = {}
	local WowFriendGroups = {}
	local FriendReqGroup = {}

	local buttonCount = 0

	FriendButtons.count = 0
	local addButtonIndex = 0
	local totalButtonHeight = 0
	local function AddButtonInfo(buttonType, id)
		addButtonIndex = addButtonIndex + 1
		if ( not FriendButtons[addButtonIndex] ) then
			FriendButtons[addButtonIndex] = { }
		end
		FriendButtons[addButtonIndex].buttonType = buttonType
		FriendButtons[addButtonIndex].id = id
		FriendButtons.count = FriendButtons.count+1
		totalButtonHeight = totalButtonHeight + FRIENDS_BUTTON_HEIGHTS[buttonType]
	end

	-- invites
	local numInvites = BNGetNumFriendInvites()
	if ( numInvites > 0 ) then
		for i = 1, numInvites do
			if not FriendReqGroup[i] then
				FriendReqGroup[i] = {}
			end
			IncrementGroup(FriendRequestString,true)
			NoteAndGroups(_, FriendReqGroup[i])
			if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_INVITE, i)
			end
		end
	end
	-- online Battlenet friends
	for i = 1, numBNetOnline do
		if not BnetFriendGroups[i] then
			-- print('Bnet Online', i)
			BnetFriendGroups[i] = {}
		end
		local noteText = select(13,BNGetFriendInfo(i))
		NoteAndGroups(noteText, BnetFriendGroups[i])
		for group in pairs(BnetFriendGroups[i]) do
			IncrementGroup(group, true)
			 if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, i)
			end
		end
	end
	-- online WoW friends
	for i = 1, numWoWOnline do
		if not WowFriendGroups[i] then
			WowFriendGroups[i] = {}
			-- print('WoW Online', i)
		end
		local note = select(7,GetFriendInfo(i))
		NoteAndGroups(note, WowFriendGroups[i])
		for group in pairs(WowFriendGroups[i]) do
			IncrementGroup(group, true)
			if not FriendGroups_SavedVars.collapsed[group] then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, i)
			end
		end
	end
	-- offline Battlenet friends
	for i = 1, numBNetOffline do
		local j = i + numBNetOnline
		if not BnetFriendGroups[j] then
			BnetFriendGroups[j] = {}
			-- print('Bnet Offline', j)
		end
		local noteText = select(13,BNGetFriendInfo(j))
		NoteAndGroups(noteText, BnetFriendGroups[j])
		for group in pairs(BnetFriendGroups[j]) do
			IncrementGroup(group)
			 if not FriendGroups_SavedVars.collapsed[group] and not FriendGroups_SavedVars.hide_offline then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_BNET, j)
			end
		end
	end
	-- offline WoW friends
	for i = 1, numWoWOffline do
		local j = i + numWoWOnline
		if not WowFriendGroups[j] then
			WowFriendGroups[j] = {}
			-- print('WoW Offline', j)
		end
		local note = select(7,GetFriendInfo(j))
		NoteAndGroups(note, WowFriendGroups[j])
		for group in pairs(WowFriendGroups[j]) do
			IncrementGroup(group)
			if not FriendGroups_SavedVars.collapsed[group] and not FriendGroups_SavedVars.hide_offline then
				buttonCount = buttonCount + 1
				AddButtonInfo(FRIENDS_BUTTON_TYPE_WOW, j)
			end
		end
	end

	buttonCount = buttonCount + GroupCount
	totalScrollHeight = totalButtonHeight + GroupCount * FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_DIVIDER]

	FriendsFrameFriendsScrollFrame.totalFriendListEntriesHeight = totalScrollHeight
	FriendsFrameFriendsScrollFrame.numFriendListEntries = addButtonIndex

	if buttonCount > #FriendButtons then
		for i = #FriendButtons + 1, buttonCount do
			FriendButtons[i] = {}
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
		FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_DIVIDER
		FriendButtons[index].text = group
		if not FriendGroups_SavedVars.collapsed[group] then
			for i = 1, #FriendReqGroup do
				if group == FriendRequestString then
					index = index + 1
					FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_INVITE
					FriendButtons[index].id = i
				end
			end
			for i = 1, numBNetOnline do
				if BnetFriendGroups[i][group] then
					index = index + 1
					FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_BNET
					FriendButtons[index].id = i
				end
			end
			for i = 1, numWoWOnline do
				if WowFriendGroups[i][group] then
					index = index + 1
					FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_WOW
					FriendButtons[index].id = i
				end
			end
			if not FriendGroups_SavedVars.hide_offline then
				for i = numBNetOnline + 1, numBNetTotal do
					if BnetFriendGroups[i][group] then
						index = index + 1
						FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_BNET
						FriendButtons[index].id = i
					end
				end
				for i = numWoWOnline + 1, numWoWTotal do
					if WowFriendGroups[i][group] then
						index = index + 1
						FriendButtons[index].buttonType = FRIENDS_BUTTON_TYPE_WOW
						FriendButtons[index].id = i
					end
				end
			end
		end
	end
	FriendButtons.count = index

	-- selection
	local selectedFriend = 0
	-- check that we have at least 1 friend
	if ( numBNetTotal + numWoWTotal > 0 ) then
		-- get friend
		if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
			selectedFriend = GetSelectedFriend()
		elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
			selectedFriend = BNGetSelectedFriend()
		end
		-- set to first in list if no friend
		if ( not selectedFriend or selectedFriend == 0 ) then
			FriendsFrame_SelectFriend(FriendButtons[1].buttonType, 1)
			selectedFriend = 1
		end
		-- check if friend is online
		local isOnline
		if ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_WOW ) then
			local name, level, class, area
			name, level, class, area, isOnline = GetFriendInfo(selectedFriend)
		elseif ( FriendsFrame.selectedFriendType == FRIENDS_BUTTON_TYPE_BNET ) then
			local bnetIDAccount, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client
			bnetIDAccount, accountName, battleTag, isBattleTag, characterName, bnetIDGameAccount, client, isOnline = BNGetFriendInfo(selectedFriend)
			if ( not accountName ) then
				isOnline = false
			end
		end
		if ( isOnline ) then
			FriendsFrameSendMessageButton:Enable()
		else
			FriendsFrameSendMessageButton:Disable()
		end
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
	if ( showRIDWarning ) then
		FriendsListFrame.RIDWarning:Show()
		FriendsFrameFriendsScrollFrame.scrollBar:Disable()
		FriendsFrameFriendsScrollFrame.scrollUp:Disable()
		FriendsFrameFriendsScrollFrame.scrollDown:Disable()
	else
		FriendsListFrame.RIDWarning:Hide()
	end
	FriendGroups_UpdateFriends()
end

local function FriendGroups_OnClick(self, button)
	if not self.text:IsShown() then
		hooks["FriendsFrameFriendButton_OnClick"](self, button)
		return
	end

	local group = self.info:GetText() or ""
	if button == "RightButton" then
		ToggleDropDownMenu(1, group, FriendGroups_Menu, "cursor", 0, 0)
	else
		FriendGroups_SavedVars.collapsed[group] = not FriendGroups_SavedVars.collapsed[group]
		FriendGroups_Update()
	end
end

local function FriendGroups_SaveOpenMenu()
	if OPEN_DROPDOWNMENUS then
		OPEN_DROPDOWNMENUS_SAVE = CopyTable(OPEN_DROPDOWNMENUS)
	end
end

-- when one of our new menu items is clicked
local function FriendGroups_OnFriendMenuClick(self)
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
					note = AddGroup(note, add)
				else
					note = RemoveGroup(note, del)
				end
				BNSetFriendNote(dropdown.bnetIDAccount, note)
			end
		elseif source == "FRIEND" or source == "FRIEND_OFFLINE" then
			for i = 1, GetNumFriends() do
				local name, _, _, _, _, _, note = GetFriendInfo(i)
				if dropdown.name and name:find(dropdown.name) then
					if creating then
						StaticPopup_Show("FRIEND_GROUP_CREATE", nil, nil, { id = i, note = note, set = SetFriendNotes })
					else
						if add then
							note = AddGroup(note, add)
					else
						note = RemoveGroup(note, del)
					end
						SetFriendNotes(i, note)
					end
					break
				end
			end
		end
		FriendGroups_Update()
	end
	HideDropDownMenu(1)
end

-- hide the add/remove group buttons if we're not right clicking on a friendlist item
local function FriendGroups_HideButtons()
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
			for i = 1, GetNumFriends() do
				local name, _, _, _, _, _, noteText = GetFriendInfo(i)
				if dropdown.name and name:find(dropdown.name) then
					note = noteText
					break
				end
			end
		end

		NoteAndGroups(note, groups)

		for _,group in ipairs(GroupSorted) do
			if group ~= "" and not groups[group] then
				local faux = "FGROUPADD_" .. group
				--polluting the popup buttons list
				UnitPopupButtons[faux] = { text = group, dist = 0 }
				table.insert(UnitPopupMenus["FRIEND_GROUP_ADD"], faux)
			end
		end
		for group in pairs(groups) do
			if group ~= "" then
				local faux = "FGROUPDEL_" .. group
				UnitPopupButtons[faux] = { text = group, dist = 0 }
				table.insert(UnitPopupMenus["FRIEND_GROUP_DEL"], faux)
			end
		end
	end
end

local function FriendGroups_Rename(self, old)
	local input = self.editBox:GetText()
	if input == "" then
		return
	end
	local groups = {}
	for i = 1, BNGetNumFriends() do
		local presenceID, _, _, _, _, _, _, _, _, _, _, _, noteText = BNGetFriendInfo(i)
		local note = NoteAndGroups(noteText, groups)
		if groups[old] then
			groups[old] = nil
			groups[input] = true
			note = CreateNote(note, groups)
			BNSetFriendNote(presenceID, note)
		end
	end
	for i = 1, GetNumFriends() do
		local note = select(7, GetFriendInfo(i))
		note = NoteAndGroups(note, groups)
		if groups[old] then
			groups[old] = nil
			groups[input] = true
			note = CreateNote(note, groups)
			SetFriendNotes(i, note)
		end
	end
	FriendGroups_Update()
end

local function FriendGroups_Create(self, data)
	local input = self.editBox:GetText()
	if input == "" then
		return
	end
	local note = AddGroup(data.note, input)
	data.set(data.id, note)
end

StaticPopupDialogs["FRIEND_GROUP_RENAME"] = {
	text = "Enter new group name",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = FriendGroups_Rename,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		FriendGroups_Rename(parent, parent.data)
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
	OnAccept = FriendGroups_Create,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		FriendGroups_Create(parent, parent.data)
		parent:Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

local function InviteOrGroup(clickedgroup, invite)
	local groups = {}
	for i = 1, BNGetNumFriends() do
		local presenceID, _, _, _, _, toonID, _, _, _, _, _, _, noteText = BNGetFriendInfo(i)
		local note = NoteAndGroups(noteText, groups)
		if groups[clickedgroup] then
			if invite and toonID then
				BNInviteFriend(toonID)
			elseif not invite then
				groups[clickedgroup] = nil
				note = CreateNote(note, groups)
				BNSetFriendNote(presenceID, note)
			end
		end
	end
	for i = 1, GetNumFriends() do
		local name, _, _, _, connected, _, noteText = GetFriendInfo(i)
		local note = NoteAndGroups(noteText, groups)
		if groups[clickedgroup] then
			if invite and connected then
				InviteUnit(name)
			elseif not invite then
				groups[clickedgroup] = nil
				note = CreateNote(note, groups)
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
		{ text = "Invite all to party", notCheckable = true, func = function(self, menu, clickedgroup) InviteOrGroup(clickedgroup, true) end },
		{ text = "Rename group", notCheckable = true, func = function(self, menu, clickedgroup) StaticPopup_Show("FRIEND_GROUP_RENAME", nil, nil, clickedgroup) end },
		{ text = "Remove group", notCheckable = true, func = function(self, menu, clickedgroup) InviteOrGroup(clickedgroup, false) end },
		{ text = "Settings", notCheckable = true, hasArrow = true },
	},
	[2] = {
		{ text = "Hide all offline", checked = function() return FriendGroups_SavedVars.hide_offline end, func = function() CloseDropDownMenus() FriendGroups_SavedVars.hide_offline = not FriendGroups_SavedVars.hide_offline FriendGroups_Update() end },
		{ text = "Colour names", checked = function() return FriendGroups_SavedVars.colour_classes end, func = function() CloseDropDownMenus() FriendGroups_SavedVars.colour_classes = not FriendGroups_SavedVars.colour_classes FriendGroups_Update() end },
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

--local frame = CreateFrame("Frame")
-- frame:RegisterEvent("PLAYER_LOGIN")

-- frame:SetScript("OnEvent", function(self, event, ...)
	-- if event == "PLAYER_LOGIN" then
		-- Hook("FriendsList_Update", FriendGroups_Update, true)
		-- if other addons have hooked this, we should too
		-- if not issecurevariable("FriendsFrame_UpdateFriends") then
			-- Hook("FriendsFrame_UpdateFriends", FriendGroups_UpdateFriends)
		-- end
		-- Hook("FriendsFrameFriendButton_OnClick", FriendGroups_OnClick)
		-- Hook("UnitPopup_ShowMenu", FriendGroups_SaveOpenMenu, true)
		-- Hook("UnitPopup_OnClick", FriendGroups_OnFriendMenuClick, true)
		-- Hook("UnitPopup_HideButtons", FriendGroups_HideButtons, true)
		-- Hook("FriendsFrameTooltip_Show",function(button)
			-- if ( button.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER ) then
				-- if FriendsTooltip:IsShown() then
					-- FriendsTooltip:Hide()
				-- end
				-- return
			-- end
		-- end,true)-- Fixes tooltip showing on groups

		-- FriendsFrameFriendsScrollFrame.dynamic = FriendGroups_GetTopButton
		-- FriendsFrameFriendsScrollFrame.update = FriendGroups_UpdateFriends

		-- add some more buttons
		-- FriendsFrameFriendsScrollFrame.buttons[1]:SetHeight(FRIENDS_FRAME_FRIENDS_FRIENDS_HEIGHT)
		-- HybridScrollFrame_CreateButtons(FriendsFrameFriendsScrollFrame, "FriendsFrameButtonTemplate")

		-- table.remove(UnitPopupMenus["BN_FRIEND"], 5) --remove target option

		-- add our add/remove group buttons to the friend list popup menus
		-- for _,menu in ipairs(friend_popup_menus) do
			-- table.insert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "FRIEND_GROUP_NEW")
			-- table.insert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "FRIEND_GROUP_ADD")
			-- table.insert(UnitPopupMenus[menu], #UnitPopupMenus[menu], "FRIEND_GROUP_DEL")
		-- end

		-- if not FriendGroups_SavedVars then
			-- FriendGroups_SavedVars = {
				-- collapsed = {},
				-- hide_offline = false,
				-- colour_classes = true,
			-- }
		-- end
	-- end
-- end)
