local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local IF = PA:NewModule('iFilger', 'AceEvent-3.0', 'AceTimer-3.0')
local LSM = PA.Libs.LSM
local _G = _G
_G.iFilger, PA.iFilger = IF, IF

IF.Title, IF.Description, IF.Authors, IF.isEnabled = 'iFilger', ACL['Minimalistic Auras / Buffs / Procs / Cooldowns'], 'Azilroka    Nils Ruesch    Ildyria', false

local CreateFrame, UIParent = CreateFrame, UIParent

local floor, format, strmatch, tonumber, tostring = floor, format, strmatch, tonumber, tostring
local sort, wipe, tinsert, unpack, next, ipairs = sort, wipe, tinsert, unpack, next, ipairs

local CopyTable = CopyTable
local GetTime = GetTime
local RegisterUnitWatch = RegisterUnitWatch

local GetContainerItemCooldown = C_Container.GetContainerItemCooldown
local GetContainerItemID = C_Container.GetContainerItemID
local GetContainerNumSlots = C_Container.GetContainerNumSlots

local GetItemInfo = C_Item.GetItemInfo
local GetItemCooldown = C_Item.GetItemCooldown

local GetSpellInfo = PA.GetSpellInfo
local GetSpellCooldown, GetSpellCharges = PA.GetSpellCooldown, PA.GetSpellCharges

local VISIBLE = 1
local HIDDEN = 0
local selectedSpell = ''
local selectedFilter = nil
local spellList = {}

IF.Cooldowns, IF.ActiveCooldowns, IF.DelayCooldowns, IF.IsChargeCooldown, IF.ItemCooldowns, IF.HasCDDelay = {}, {}, {}, {}, {}, { [5384] = true }

local GLOBAL_COOLDOWN_TIME, COOLDOWN_MIN_DURATION, AURA_MIN_DURATION = 1.5, .1, .1

function IF:Spawn(unit, name, db, filter, position)
	local object = CreateFrame('Button', 'iFilger_'..name, PA.PetBattleFrameHider)
	object.db, object.name, object.unit, object.filter, object.Whitelist, object.Blacklist, object.createdIcons, object.anchoredIcons = db, name, unit, filter, db.Whitelist, db.Blacklist, 0, 0
	object:SetSize(100, 20)
	object:SetPoint(unpack(position))
	object:EnableMouse(false)
	IF:CreateMover(object)

	if name ~= 'Cooldowns' and name ~= 'ItemCooldowns' then
		object:SetAttribute('unit', unit)
		object:RegisterEvent('UNIT_AURA')
		object:SetScript('OnEvent', function() IF:UpdateAuras(object, unit) end)
		RegisterUnitWatch(object)

		if not db.Enable then
			IF:DisableUnit(object)
		end
	end

	return object
end

function IF:DisableUnit(button)
	button:Disable()
	button:UnregisterEvent('UNIT_AURA')

	for _, element in ipairs(button) do
		element:Hide()
	end

	if button:GetAttribute('unit') then
		UnregisterUnitWatch(button)
	end

	IF:ToggleMover(button)
end

function IF:EnableUnit(button)
	button:Enable()
	button:RegisterEvent('UNIT_AURA')

	if button:GetAttribute('unit') then
		RegisterUnitWatch(button)
	end

	IF:ToggleMover(button)
end

function IF:UpdateActiveCooldowns()
	local Panel = IF.Panels.Cooldowns

	local Position = 1
	for SpellID in next, IF.ActiveCooldowns do
		local spellData = PA.SpellBook.Complete[SpellID]

		if spellData.name then
			local button = IF:GetCooldownFrame(Panel, Position)
			Position = Position + 1

			local Start, Duration, CurrentDuration, Charges

			do
				local cooldownInfo, chargeInfo = GetSpellCooldown(SpellID), GetSpellCharges(SpellID)

				if chargeInfo and (chargeInfo.currentCharges and chargeInfo.maxCharges > 1 and chargeInfo.currentCharges < chargeInfo.maxCharges) then
					Start, Duration = chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration
				else
					Start, Duration = cooldownInfo.startTime, cooldownInfo.duration
				end
			end

			CurrentDuration = (Start + Duration - GetTime())

			-- if Charges and Start == (((2^32)/1000) - Duration) then
			-- 	CurrentDuration = 0
			-- end

			button.duration = Duration
			button.spellID = SpellID
			button.spellName = spellData.name

			button.Icon:SetTexture(spellData.iconID)
			button:SetShown(CurrentDuration and CurrentDuration >= COOLDOWN_MIN_DURATION)

			if (CurrentDuration and CurrentDuration >= COOLDOWN_MIN_DURATION) then
				if Panel.db.StatusBar then
					local timervalue, formatid = PA:GetTimeInfo(CurrentDuration, IF.db.Cooldown.threshold)
					local color = PA.TimeColors[formatid]

					button.StatusBar:SetValue(CurrentDuration / Duration)
					button.StatusBar.Time:SetFormattedText(PA.TimeFormats[formatid][1], timervalue)
					button.StatusBar.Time:SetTextColor(unpack(PA.TimeColors[formatid]))
					button.StatusBar.Time:SetTextColor(color.r, color.g, color.b)
					if Panel.db.FollowCooldownText and (formatid == 1 or formatid == 2) then
						button.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
					end

					button.StatusBar.Name:SetText(Name)
				else
					button.Cooldown:SetCooldown(Start, Duration)
				end

				button.Cooldown:SetShown(not Panel.db.StatusBar)
				button.StatusBar:SetShown(Panel.db.StatusBar)
			else
				IF.ActiveCooldowns[SpellID] = nil
				button.CurrentDuration = 0
			end
		end
	end

	for i = Position + 1, #Panel do
		Panel[i]:Hide()
	end

	IF:SetPosition(Panel)
end

function IF:UpdateItemCooldowns()
	local Panel = IF.Panels.ItemCooldowns

	local Position = 1
	for itemID in next, IF.ItemCooldowns do
		local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = GetItemInfo(itemID)

		if itemName then
			local button = IF:GetCooldownFrame(Panel, Position)
			Position = Position + 1

			local Start, Duration, CurrentDuration = GetItemCooldown(itemID)
			CurrentDuration = (Start + Duration - GetTime())

			button.duration = Duration
			button.itemID = itemID
			button.itemName = Name
			button.expiration = Start + Duration

			button.Icon:SetTexture(itemTexture)
			button:SetShown(CurrentDuration and CurrentDuration >= COOLDOWN_MIN_DURATION)

			if (CurrentDuration and CurrentDuration >= COOLDOWN_MIN_DURATION) then
				if Panel.db.StatusBar then
					local timervalue, formatid = PA:GetTimeInfo(CurrentDuration, IF.db.Cooldown.threshold)
					local color = PA.TimeColors[formatid]

					button.StatusBar:SetValue(CurrentDuration / Duration)
					button.StatusBar.Time:SetFormattedText(PA.TimeFormats[formatid][1], timervalue)
					button.StatusBar.Time:SetTextColor(unpack(PA.TimeColors[formatid]))
					button.StatusBar.Time:SetTextColor(color.r, color.g, color.b)
					if Panel.db.FollowCooldownText and (formatid == 1 or formatid == 2) then
						button.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
					end

					button.StatusBar.Name:SetText(Name)
				else
					button.Cooldown:SetCooldown(Start, Duration)
				end

				button.Cooldown:SetShown(not Panel.db.StatusBar)
				button.StatusBar:SetShown(Panel.db.StatusBar)
			else
				IF.ItemCooldowns[itemID] = nil
				button.CurrentDuration = 0
			end
		end
	end

	for i = Position, #Panel do
		Panel[i]:Hide()
	end

	IF:SetPosition(Panel)
end

function IF:UpdateDelayedCooldowns()
	for SpellID in next, IF.DelayCooldowns do
		local spellData, Start, Duration = PA.SpellBook.Complete[SpellID]

		do
			local cooldownInfo, chargeInfo = GetSpellCooldown(SpellID), GetSpellCharges(SpellID)

			if chargeInfo and (chargeInfo.currentCharges and chargeInfo.maxCharges > 1 and chargeInfo.currentCharges < chargeInfo.maxCharges) then
				Start, Duration = chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration
			else
				Start, Duration = cooldownInfo.startTime, cooldownInfo.duration
			end
		end

		local CurrentDuration = (Start + Duration - GetTime())

		if CurrentDuration then
			if (CurrentDuration < IF.db.SuppressDuration) and (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				IF.DelayCooldowns[SpellID] = nil
				IF.ActiveCooldowns[SpellID] = Duration
			end
		else
			IF.DelayCooldowns[SpellID] = nil
		end
	end
end

function IF:CreateMover(frame)
	if PA.ElvUI then
		_G.ElvUI[1]:CreateMover(frame, frame:GetName()..'Mover', frame:GetName(), nil, nil, nil, 'ALL,iFilger', nil, 'ProjectAzilroka,iFilger,'..frame.name)
	elseif PA.Tukui then
		_G.Tukui[1]['Movers']:RegisterFrame(frame)
	end
end

function IF:ToggleMover(frame)
	if PA.ElvUI then
		if frame.db.Enable then
			_G.ElvUI[1]:EnableMover(frame.mover:GetName())
		else
			_G.ElvUI[1]:DisableMover(frame.mover:GetName())
		end
	end
end

function IF:CustomFilter(element, unit, button, name, auraData)
	if duration == 0 then
		return false
	end
	if element.db.FilterByList == 'Blacklist' then
		return not element.Blacklist[spellID]
	elseif element.db.FilterByList == 'Whitelist' then
		return element.Whitelist[spellID]
	elseif element.db.FilterByList == 'None' then
		if element.name == 'Procs' then
			if (caster == 'player' or caster == 'pet') then
				return not PA.SpellBook.Complete[spellID]
			end
		else
			local isPlayer = (caster == 'player' or caster == 'vehicle' or caster == 'pet')
			if (isPlayer or casterIsPlayer) and (duration ~= 0) then
				return true
			else
				return false
			end
		end
	end
end

function IF:UpdateAuraIcon(element, unit, index, offset, filter, isDebuff, visible)
	local auraData = PA:GetAuraData(unit, index, filter)

	if auraData then
		local position = visible + offset + 1
		local button = IF:GetCooldownFrame(element, position)
		local show = IF:CustomFilter(element, unit, button, auraData)

		button.caster, button.filter, button.isDebuff, button.expiration, button.duration, button.spellID, button.isPlayer = auraData.sourceUnit, filter, auraData.isHarmful, auraData.expirationTime, auraData.duration, auraData.spellId, auraData.isFromPlayerOrPlayerPet

		button:SetShown(show)

		if show then
			if not element.db.StatusBar then
				if (auraData.duration and auraData.duration >= AURA_MIN_DURATION) then
					button.Cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration)
				end
				button.Cooldown:SetShown(auraData.duration and auraData.duration >= AURA_MIN_DURATION)
			end

			button:SetID(index)
			button.Icon:SetTexture(auraData.icon)
			button.Count:SetText(auraData.applications > 1 and auraData.applications or '')
			button.StatusBar:SetStatusBarColor(unpack(element.db.StatusBarTextureColor))
			button.StatusBar.Name:SetText(auraData.name)
			button.backdrop:SetBackdropBorderColor(isDebuff and 1 or 0, 0, 0)

			return VISIBLE
		else
			return HIDDEN
		end
	end
end

function IF:SetPosition(element)
	local sizex = (element.db.Size + element.db.Spacing + 2) + (element.db.StatusBar and element.db.StatusBarWidth or 0)
	local sizey = element.db.Size + element.db.Spacing + 2
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthx = not element.db.StatusBar and (element.db.Direction == 'LEFT' and -1) or 1
	local growthy = ((element.db.StatusBar and element.db.StatusBarDirection == 'DOWN' or element.db.Direction == 'DOWN') and -1) or 1
	local cols = element.db.StatusBar and 1 or element.db.NumPerRow

	for i, button in ipairs(element) do
		if (not button) then break end
		local col, row = (i - 1) % cols, floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

function IF:FilterAuraIcons(element, unit, filter, limit, isDebuff, offset, dontHide)
	if (not offset) then offset = 0 end
	local index, visible, hidden = 1, 0, 0

	while (visible < limit) do
		local result = IF:UpdateAuraIcon(element, unit, index, offset, filter, isDebuff, visible)
		if (not result) then
			break
		elseif (result == VISIBLE) then
			visible = visible + 1
		elseif (result == HIDDEN) then
			hidden = hidden + 1
		end

		index = index + 1
	end

	if (not dontHide) then
		for i = visible + offset + 1, #element do
			element[i]:Hide()
		end
	end

	return visible, hidden
end

function IF:UpdateAuras(element, unit)
	if(element.unit ~= unit) then return end
	IF:FilterAuraIcons(element, unit, element.filter, element.numAuras or 32, nil, 0)
	IF:SetPosition(element)
end

function IF:PLAYER_ENTERING_WORLD()
	for SpellID in next, IF.db.Cooldowns.SpellCDs do
		local cooldownInfo = GetSpellCooldown(SpellID)
		local currentDuration = (cooldownInfo.startTime + cooldownInfo.duration - GetTime()) or 0

		if currentDuration > .1 and (currentDuration < IF.db.Cooldowns.IgnoreDuration) then
			if (currentDuration >= IF.db.Cooldowns.SuppressDuration) then
				IF.DelayCooldowns[SpellID] = true
			elseif (currentDuration > GLOBAL_COOLDOWN_TIME) then
				IF.ActiveCooldowns[SpellID] = true
			end
		end
	end

	if IF.db.SortByDuration then
		sort(IF.ActiveCooldowns)
	end

	IF:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function IF:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, SpellID)
	if (unit == 'player' or unit == 'pet') and IF.db.Cooldowns.SpellCDs[SpellID] then
		IF.Cooldowns[SpellID] = true
	end
end

function IF:SPELL_UPDATE_COOLDOWN()
	local Start, Duration, Enable, Charges, _, ChargeStart, ChargeDuration, CurrentDuration

	for SpellID in next, IF.Cooldowns do
		Start, Duration, Enable = GetSpellCooldown(SpellID)

		if IF.IsChargeCooldown[SpellID] ~= false then
			Charges, _, ChargeStart, ChargeDuration = GetSpellCharges(SpellID)

			if IF.IsChargeCooldown[SpellID] == nil then
				IF.IsChargeCooldown[SpellID] = Charges and true or false
			end

			if Charges then
				Start, Duration = ChargeStart, ChargeDuration
			end
		end

		CurrentDuration = (Start + Duration - GetTime())

		if Enable == 1 and CurrentDuration and (CurrentDuration < IF.db.Cooldowns.IgnoreDuration) then
			if (CurrentDuration >= IF.db.Cooldowns.SuppressDuration) or IF.HasCDDelay[SpellID] then
				IF.DelayCooldowns[SpellID] = true
			elseif (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				IF.ActiveCooldowns[SpellID] = true
			end
		end

		IF.Cooldowns[SpellID] = nil
	end

	if IF.db.SortByDuration then
		sort(IF.ActiveCooldowns)
	end
end

function IF:BAG_UPDATE_COOLDOWN()
	for bagID = 0, 4 do
		for slotID = 1, GetContainerNumSlots(bagID) do
			local itemID = GetContainerItemID(bagID, slotID)
			if itemID then
				local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
				if duration and duration > GLOBAL_COOLDOWN_TIME and enable == 1 then
					IF.ItemCooldowns[itemID] = true
				end
			end
		end
	end
end

function IF:GetCooldownFrame(element, position)
	local Frame = element[position]
	if not Frame then
		Frame = CreateFrame('Button', nil, element, 'PA_AuraTemplate')
		Frame:EnableMouse(false)
		Frame:SetSize(element.db.Size, element.db.Size)

		Frame.Cooldown:SetDrawEdge(false)
		Frame.Cooldown.CooldownOverride = 'iFilger'
		PA:RegisterCooldown(Frame.Cooldown)

		Frame.Icon:SetTexCoord(PA:TexCoords())

		Frame.Count:SetFont(LSM:Fetch('font', element.db.StackCountFont), element.db.StackCountFontSize, element.db.StackCountFontFlag)
		Frame.Count:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', 0, 2)

		Frame.StatusBar:SetSize(element.db.StatusBarWidth, element.db.StatusBarHeight)
		Frame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', element.db.StatusBarTexture))
		Frame.StatusBar:SetStatusBarColor(unpack(element.db.StatusBarTextureColor))
		Frame.StatusBar:SetPoint('BOTTOMLEFT', Frame, 'BOTTOMRIGHT', 2, 0)
		Frame.StatusBar:SetMinMaxValues(0, 1)
		Frame.StatusBar:SetValue(0)

		if element.name ~= 'Cooldowns' and element.name ~= 'ItemCooldowns' then
			Frame.Cooldown:SetReverse(true)
			Frame.StatusBar:SetScript('OnUpdate', function(s, elapsed)
				s.elapsed = (s.elapsed or 0) + elapsed
				if (s.elapsed > COOLDOWN_MIN_DURATION) then
					local expiration = Frame.expiration - GetTime()
					local timervalue, formatid = PA:GetTimeInfo(expiration, IF.db.Cooldown.threshold)
					local color = PA.TimeColors[formatid]
					if timervalue then
						local Normalized = PA:Clamp(expiration / Frame.duration)
						s:SetValue(Normalized)
						s.Time:SetFormattedText(PA.TimeFormats[formatid][1], timervalue)
						s.Time:SetTextColor(color.r, color.g, color.b)
						if element.db.FollowCooldownText and (formatid == 1 or formatid == 2) then
							s:SetStatusBarColor(color.r, color.g, color.b)
						end
					end
					s.elapsed = 0
				end
			end)
		end

		Frame.StatusBar.Name:SetFont(LSM:Fetch('font', element.db.StatusBarFont), element.db.StatusBarFontSize, element.db.StatusBarFontFlag)
		Frame.StatusBar.Name:SetPoint('BOTTOMLEFT', Frame.StatusBar, element.db.StatusBarNameX, element.db.StatusBarNameY)

		Frame.StatusBar.Time:SetFont(LSM:Fetch('font', element.db.StatusBarFont), element.db.StatusBarFontSize, element.db.StatusBarFontFlag)
		Frame.StatusBar.Time:SetPoint('BOTTOMRIGHT', Frame.StatusBar, element.db.StatusBarTimeX, element.db.StatusBarTimeY)

		PA:CreateBackdrop(Frame)
		PA:CreateShadow(Frame.backdrop)
		PA:CreateBackdrop(Frame.StatusBar, 'Default')
		PA:CreateShadow(Frame.StatusBar.backdrop)

		Frame.Count:SetShown(true)
		Frame.StatusBar:SetShown(element.db.StatusBar)
		Frame.StatusBar.Name:SetShown(element.db.StatusBarNameEnabled)
		Frame.StatusBar.Time:SetShown(element.db.StatusBarTimeEnabled)

		tinsert(element, Frame)
		element.createdIcons = element.createdIcons + 1
	end

	return Frame
end

function IF:UpdateAll(init)
	if not init then
		for FrameName, Frame in next, IF.Panels do
			Frame.db = IF.db[FrameName]

			if Frame.db.Enable then
				IF:EnableUnit(Frame)
			else
				IF:DisableUnit(Frame)
			end

			Frame:SetWidth((Frame.db.StatusBar and 1 or Frame.db.NumPerRow) * (Frame.db.StatusBar and Frame.db.StatusBarWidth or Frame.db.Size))

			for _, Button in ipairs(Frame) do
				Button:SetSize(Frame.db.Size, Frame.db.Size)
				Button.Count:SetFont(LSM:Fetch('font', Frame.db.StackCountFont), Frame.db.StackCountFontSize, Frame.db.StackCountFontFlag)
				Button.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', Frame.db.StatusBarTexture))
				Button.StatusBar:SetStatusBarColor(unpack(Frame.db.StatusBarTextureColor))
				Button.StatusBar:SetSize(Frame.db.StatusBarWidth, Frame.db.StatusBarHeight)
				Button.StatusBar.Name:SetFont(LSM:Fetch('font', Frame.db.StatusBarFont), Frame.db.StatusBarFontSize, Frame.db.StatusBarFontFlag)
				Button.StatusBar.Time:SetFont(LSM:Fetch('font', Frame.db.StatusBarFont), Frame.db.StatusBarFontSize, Frame.db.StatusBarFontFlag)
				Button.StatusBar.Name:SetPoint('BOTTOMLEFT', Button.StatusBar, Frame.db.StatusBarNameX, Frame.db.StatusBarNameY)
				Button.StatusBar.Time:SetPoint('BOTTOMRIGHT', Button.StatusBar, Frame.db.StatusBarTimeX, Frame.db.StatusBarTimeY)
				Button.StatusBar:SetShown(Frame.db.StatusBar)
				Button.StatusBar.Name:SetShown(Frame.db.StatusBarNameEnabled)
				Button.StatusBar.Time:SetShown(Frame.db.StatusBarTimeEnabled)
			end
		end
	end

	IF:CancelAllTimers()

	if IF.db.Cooldowns.Enable then
		IF:ScheduleRepeatingTimer('UpdateActiveCooldowns', IF.db.Cooldowns.UpdateSpeed)
		IF:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
	end

	if IF.db.ItemCooldowns.Enable then
		IF:ScheduleRepeatingTimer('UpdateItemCooldowns', IF.db.ItemCooldowns.UpdateSpeed)
	end
end

function IF:SPELLS_CHANGED()
	PA:AddKeysToTable(IF.db.Cooldowns.SpellCDs, PA.SpellBook.Spells)
	PA.Options.args.iFilger.args.Cooldowns.args.Spells.args = PA:GenerateSpellOptions(IF.db.Cooldowns.SpellCDs)
end

local function GetSelectedSpell()
	if selectedSpell and selectedSpell ~= '' then
		local spell = strmatch(selectedSpell, " %((%d+)%)$") or selectedSpell
		if spell then
			return tonumber(spell) or spell
		end
	end
end

function IF:BuildProfile()
	PA.Defaults.profile.iFilger = {
		Enable = false,
		Cooldown = CopyTable(PA.Defaults.profile.Cooldown),
	}

	for _, Name in next, {'Cooldowns', 'ItemCooldowns', 'Buffs', 'Procs', 'Enhancements', 'RaidDebuffs', 'TargetDebuffs', 'FocusBuffs', 'FocusDebuffs'} do
		PA.Defaults.profile.iFilger[Name] = {
			Direction = 'RIGHT',
			Enable = true,
			FollowCooldownText = false,
			Size = 28,
			NumPerRow = 12,
			SuppressDuration = 60,
			IgnoreDuration = 300,
			UpdateSpeed = .1,
			Spacing = 4,
			StackCountFont = PA.ElvUI and 'Homespun' or 'Arial Narrow',
			StackCountFontFlag = PA.ElvUI and 'MONOCHROMEOUTLINE' or 'OUTLINE',
			StackCountFontSize = PA.ElvUI and 10 or 12,
			StatusBar = false,
			StatusBarDirection = 'UP',
			StatusBarFont = PA.ElvUI and 'Homespun' or 'Arial Narrow',
			StatusBarFontFlag = PA.ElvUI and 'MONOCHROMEOUTLINE' or 'OUTLINE',
			StatusBarFontSize = PA.ElvUI and 10 or 12,
			StatusBarHeight = 5,
			StatusBarNameEnabled = true,
			StatusBarNameX = 0,
			StatusBarNameY = 8,
			StatusBarTexture = PA.ElvUI and 'ElvUI Norm' or 'Blizzard Raid Bar',
			StatusBarTextureColor = { .24, .54, .78 },
			StatusBarTimeEnabled = true,
			StatusBarTimeX = 0,
			StatusBarTimeY = 8,
			StatusBarWidth = 148,
		}

		if Name ~= 'Cooldowns' then
			PA.Defaults.profile.iFilger[Name].FilterByList = 'None'
			PA.Defaults.profile.iFilger[Name].Whitelist = {}
			PA.Defaults.profile.iFilger[Name].Blacklist = {}
		end
	end

	PA.Defaults.profile.iFilger.Cooldowns.SpellCDs = PA.SpellBook.Spells
end

function IF:GetOptions()
	local iFilger = ACH:Group(IF.Title, IF.Description, nil, 'tab')
	PA.Options.args.iFilger = iFilger

	iFilger.args.Description = ACH:Description(IF.Description, 0)
	iFilger.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, function(info) return IF.db[info[#info]] end, function(info, value) IF.db[info[#info]] = value if (not IF.isEnabled) then IF:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	iFilger.args.AuthorHeader = ACH:Header(ACL['Authors:'], -2)
	iFilger.args.Authors = ACH:Description(IF.Authors, -1, 'large')

	for _, Name in next, { 'Cooldowns', 'ItemCooldowns', 'Buffs', 'Procs', 'Enhancements', 'RaidDebuffs', 'TargetDebuffs', 'FocusBuffs', 'FocusDebuffs' } do
		iFilger.args[Name] = ACH:Group(Name, nil, nil, nil, function(info) return IF.db[Name][info[#info]] end, function(info, value) IF.db[Name][info[#info]] = value IF:UpdateAll() end)

		iFilger.args[Name].args.Enable = ACH:Toggle(ACL['Enable'], nil, 0)
		iFilger.args[Name].args.Size = ACH:Range(ACL['Icon Size'], nil, 1, { min = 16, max = 64, step = 1 })
		iFilger.args[Name].args.Spacing = ACH:Range(ACL['Spacing'], nil, 2, { min = 0, max = 18, step = 1 })
		iFilger.args[Name].args.NumPerRow = ACH:Range(ACL['Number Per Row'], nil, 3, { min = 1, max = 24, step = 1 }, nil, nil, nil, nil, function() return IF.db[Name].StatusBar end)
		iFilger.args[Name].args.Direction = ACH:Select(ACL['Growth Direction'], nil, 4, { LEFT = 'Left', RIGHT = 'Right' }, nil, nil, nil, nil, nil, function() return IF.db[Name].StatusBar end)
		iFilger.args[Name].args.FilterByList = ACH:Select(ACL['Filter by List'], nil, 5, { None = 'None', Whitelist = 'Whitelist', Blacklist = 'Blacklist' }, nil, nil, nil, nil, nil, Name == 'Cooldowns')

		iFilger.args[Name].args.IconStack = ACH:Group(ACL['Stack Count'], nil, 10)
		iFilger.args[Name].args.IconStack.inline = true
		iFilger.args[Name].args.IconStack.args.StackCountFont = ACH:SharedMediaFont(ACL['Font'], nil, 1)
		iFilger.args[Name].args.IconStack.args.StackCountFontSize = ACH:Range(ACL['Font Size'], nil, 2, { min = 8, max = 18, step = 1 })
		iFilger.args[Name].args.IconStack.args.StackCountFontFlag = ACH:FontFlags(ACL['Font Flag'], nil, 3)

		iFilger.args[Name].args.StatusBarGroup = ACH:Group(ACL['StatusBar'], nil, 11, nil, nil, nil, function() return not IF.db[Name].StatusBar end)
		iFilger.args[Name].args.StatusBarGroup.inline = true
		iFilger.args[Name].args.StatusBarGroup.args.StatusBar = ACH:Toggle(ACL['Enable'], nil, 0, nil, nil, nil, nil, nil, false)
		iFilger.args[Name].args.StatusBarGroup.args.FollowCooldownText = ACH:Toggle(ACL['Follow Cooldown Text Color'], ACL['Follow Cooldown Text Colors (Expiring / Seconds)'], 1)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarWidth = ACH:Range(ACL['Width'], nil, 3, { min = 1, max = 256, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarHeight = ACH:Range(ACL['Height'], nil, 4, { min = 1, max = 64, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTexture = ACH:SharedMediaStatusbar(ACL['Texture'], nil, 5)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTextureColor = ACH:Color(ACL['Texture Color'], nil, 6, nil, nil, function(info) return unpack(IF.db[Name][info[#info]]) end, function(info, r, g, b, a) IF.db[Name][info[#info]] = { r, g, b, a} end)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarFont = ACH:SharedMediaFont(ACL['Font'], nil, 7)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarFontSize = ACH:Range(ACL['Font Size'], nil, 8, { min = 8, max = 18, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarFontFlag = ACH:FontFlags(ACL['Font Flag'], nil, 9)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarDirection = ACH:Select(ACL['Growth Direction'], nil, 10, { UP = 'Up', DOWN = 'Down' })

		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName = ACH:Group(ACL['Name'], nil, 11)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.inline = true
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.args.StatusBarNameEnabled = ACH:Toggle(ACL['Enable'], nil, 0)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.args.StatusBarNameX = ACH:Range(ACL['X Offset'], nil, 1, { min = -256, max = 256, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.args.StatusBarNameY = ACH:Range(ACL['Y Offset'], nil, 2, { min = -64, max = 64, step = 1 })

		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime = ACH:Group(ACL['Name'], nil, 12)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.inline = true
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.args.StatusBarTimeEnabled = ACH:Toggle(ACL['Enable'], nil, 0)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.args.StatusBarTimeX = ACH:Range(ACL['X Offset'], nil, 1, { min = -256, max = 256, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.args.StatusBarTimeY = ACH:Range(ACL['Y Offset'], nil, 2, { min = -64, max = 64, step = 1 })

		iFilger.args[Name].args.filterGroup = ACH:Group(ACL['Filters'], nil, 12, nil, nil, nil, nil, Name == 'Cooldowns')
		iFilger.args[Name].args.filterGroup.inline = true
		iFilger.args[Name].args.filterGroup.args.selectFilter = ACH:Select(ACL['Select Filter'], nil, 1, { Whitelist = 'Whitelist', Blacklist = 'Blacklist' }, nil, nil, function() return selectedFilter end, function(_, value) selectedFilter, selectedSpell = nil, nil if value ~= '' then selectedFilter = value end end)
		iFilger.args[Name].args.filterGroup.args.resetFilter = ACH:Execute(ACL["Reset Filter"], ACL["This will reset the contents of this filter back to default. Any spell you have added to this filter will be removed."], 2, function() wipe(IF.db[Name][selectedFilter]) selectedSpell = nil end, nil, true)

		iFilger.args[Name].args.filterGroup.args.filterGroup = ACH:Group(function() return selectedFilter end, nil, 10, nil, nil, nil, nil, function() return not selectedFilter end)
		iFilger.args[Name].args.filterGroup.args.filterGroup.inline = true
		iFilger.args[Name].args.filterGroup.args.filterGroup.args.addSpell = ACH:Input(ACL['Add SpellID'], ACL['Add a spell to the filter.'], 1, nil, nil, function() return '' end, function(_, value) value = tonumber(value) if not value then return end local spellName = GetSpellInfo(value) selectedSpell = (spellName and value) or nil if not selectedSpell then return end IF.db[Name][selectedFilter][value] = true end)
		iFilger.args[Name].args.filterGroup.args.filterGroup.args.removeSpell = ACH:Execute(ACL["Remove Spell"], ACL["Remove a spell from the filter. Use the spell ID if you see the ID as part of the spell name in the filter."], 2, function() local value = GetSelectedSpell() if not value then return end selectedSpell = nil IF.db[Name][selectedFilter][value] = nil end, nil, true)
		iFilger.args[Name].args.filterGroup.args.filterGroup.args.selectSpell = ACH:Select(ACL["Select Spell"], nil, 10, function() local list = IF.db[Name][selectedFilter] if not list then return end wipe(spellList) for filter in next, list do local spellName = tonumber(filter) and GetSpellInfo(filter) local name = (spellName and format("%s |cFF888888(%s)|r", spellName, filter)) or tostring(filter) spellList[filter] = name end if not next(spellList) then spellList[''] = ACL["None"] end return spellList end, nil, 'double', function() if not IF.db[Name][selectedFilter][selectedSpell] then selectedSpell = nil end return selectedSpell or '' end, function(_, value) selectedSpell = (value ~= '' and value) or nil end)
		iFilger.args[Name].args.filterGroup.args.spellGroup = ACH:Group(function() local spell = GetSelectedSpell() local spellName = spell and GetSpellInfo(spell) return (spellName and spellName..' |cFF888888('..spell..')|r') or spell or ' ' end, nil, -15, nil, nil, nil, nil, function() return not GetSelectedSpell() end)
		iFilger.args[Name].args.filterGroup.args.spellGroup.inline = true
		iFilger.args[Name].args.filterGroup.args.spellGroup.args.enabled = ACH:Toggle(ACL['Enable'], nil, 0, nil, nil, nil, function() local spell = GetSelectedSpell() if not spell then return end return IF.db[Name][selectedFilter][spell] end, function(_, value) local spell = GetSelectedSpell() if not spell then return end IF.db[Name][selectedFilter][spell] = value end)
	end

	iFilger.args.Cooldowns.args.UpdateSpeed = ACH:Range(ACL['Update Speed'], nil, 5, { min = .1, max = .5, step = .1 })
	iFilger.args.ItemCooldowns.args.UpdateSpeed = ACH:Range(ACL['Update Speed'], nil, 5, { min = .1, max = .5, step = .1 })

	iFilger.args.Cooldowns.args.SuppressDuration = ACH:Range(ACL['Suppress Duration Threshold'], ACL['Duration in Seconds'], 6, { min = 2, max = 600, step = 1 })
	iFilger.args.Cooldowns.args.IgnoreDuration = ACH:Range(ACL['Ignore Duration Threshold'], ACL['Duration in Seconds'], 7, { min = 2, max = 600, step = 1 })

	iFilger.args.Cooldowns.args.Spells = ACH:Group(_G.SPELLS, nil, 12, nil, function(info) return IF.db.Cooldowns.SpellCDs[tonumber(info[#info])] end, function(info, value) IF.db.Cooldowns.SpellCDs[tonumber(info[#info])] = value end)
	iFilger.args.Cooldowns.args.Spells.inline = true
	iFilger.args.Cooldowns.args.Spells.args = PA:GenerateSpellOptions(IF.db.Cooldowns.SpellCDs)
end

function IF:UpdateSettings()
	IF.db = PA.db.iFilger
end

function IF:Initialize()
	if IF.db.Enable ~= true then
		return
	end

	IF.isEnabled = true

	if PA.ElvUI then
		ElvUI[1]:ConfigMode_AddGroup('iFilger')
	end

	IF.Panels = {
		Buffs = IF:Spawn('player', 'Buffs', IF.db.Buffs, 'HELPFUL', { 'TOPLEFT', UIParent, 'CENTER', -351, -203 }),
		RaidDebuffs = IF:Spawn('player', 'RaidDebuffs', IF.db.RaidDebuffs, 'HARMFUL', { 'TOPLEFT', UIParent, 'CENTER', -351, -203 }),
		Procs = IF:Spawn('player', 'Procs', IF.db.Procs, 'HELPFUL', { 'BOTTOMLEFT', UIParent, 'CENTER', -57, -52 }),
		Enhancements = IF:Spawn('player', 'Enhancements', IF.db.Enhancements, 'HELPFUL', { 'BOTTOMRIGHT', UIParent, 'CENTER', -351, 161 }),
		TargetDebuffs = IF:Spawn('target', 'TargetDebuffs', IF.db.TargetDebuffs, 'HARMFUL|PLAYER', { 'TOPLEFT', UIParent, 'CENTER', 283, -207 }),
		Cooldowns = IF:Spawn('player', 'Cooldowns', IF.db.Cooldowns, nil, { 'BOTTOMRIGHT', UIParent, 'CENTER', -71, -109 }),
		ItemCooldowns = IF:Spawn('player', 'ItemCooldowns', IF.db.ItemCooldowns, nil, { 'BOTTOMRIGHT', UIParent, 'CENTER', -71, -109 }),
	}

	IF:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')	-- For Cooldown Queue
	IF:RegisterEvent('SPELL_UPDATE_COOLDOWN')		-- Process Cooldown Queue
	IF:RegisterEvent('BAG_UPDATE_COOLDOWN')
	IF:RegisterEvent('PLAYER_TARGET_CHANGED', function() if IF.db.TargetDebuffs.Enable then IF:UpdateAuras(IF.Panels.TargetDebuffs, 'target') end end)

	if not PA.Classic then
		IF.Panels.FocusBuffs = IF:Spawn('focus', 'FocusBuffs', IF.db.FocusBuffs, 'HELPFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 })
		IF.Panels.FocusDebuffs = IF:Spawn('focus', 'FocusDebuffs', IF.db.FocusDebuffs, 'HARMFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 })
		IF:RegisterEvent('PLAYER_FOCUS_CHANGED', function() IF:UpdateAuras(IF.Panels.FocusBuffs, 'focus') IF:UpdateAuras(IF.Panels.FocusDebuffs, 'focus') end)
	end

	IF:UpdateAll(true)
end
