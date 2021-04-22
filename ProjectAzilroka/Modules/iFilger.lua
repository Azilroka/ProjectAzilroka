local PA = _G.ProjectAzilroka
local IF = PA:NewModule('iFilger', 'AceEvent-3.0', 'AceTimer-3.0')
PA.iFilger = IF

IF.Title = '|cFF16C3F2i|r|cFFFFFFFFFilger|r'
IF.Description = 'Minimalistic Auras / Buffs / Procs / Cooldowns'
IF.Authors = 'Azilroka    Nils Ruesch    Ildyria'

IF.isEnabled = false

local _G = _G

_G.iFilger = IF

local CreateFrame = CreateFrame
local UIParent = UIParent

local floor = floor
local format = format
local ipairs = ipairs
local next = next
local pairs = pairs
local select = select
local sort = sort
local strmatch = strmatch
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe

local CopyTable = CopyTable
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerItemID = GetContainerItemID
local GetContainerNumSlots = GetContainerNumSlots
local GetFlyoutInfo = GetFlyoutInfo
local GetFlyoutSlotInfo = GetFlyoutSlotInfo
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemLink = GetInventoryItemLink
local GetItemCooldown = GetItemCooldown
local GetItemIcon = GetItemIcon
local GetItemInfo = GetItemInfo
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellCharges = GetSpellCharges
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetSpellLink = GetSpellLink
local GetTime = GetTime
local IsSpellKnown = IsSpellKnown
local RegisterUnitWatch = RegisterUnitWatch
local UnitAura = UnitAura

local VISIBLE = 1
local HIDDEN = 0
local selectedSpell = ''
local selectedFilter = nil
local spellList = {}

IF.Cooldowns = {}
IF.ActiveCooldowns = {}
IF.DelayCooldowns = {}
IF.IsChargeCooldown = {}
IF.SpellList = {}
IF.CompleteSpellBook = {}
IF.ItemCooldowns = {}
IF.HasCDDelay = {
	[5384] = true
}

local GLOBAL_COOLDOWN_TIME = 1.5
local COOLDOWN_MIN_DURATION = .1
local AURA_MIN_DURATION = .1

-- Simpy Magic
local t = {}
for _, name in pairs({'SPELL_RECAST_TIME_SEC','SPELL_RECAST_TIME_MIN','SPELL_RECAST_TIME_CHARGES_SEC','SPELL_RECAST_TIME_CHARGES_MIN'}) do
    t[name] = _G[name]:gsub('%%%.%dg','[%%d%%.]-'):gsub('%.$','%%.'):gsub('^(.-)$','^%1$')
end

function IF:Spawn(unit, name, db, filter, position)
	local object = CreateFrame('Button', 'iFilger_'..name, PA.PetBattleFrameHider)
	object:SetSize(100, 20)
	object:SetPoint(unpack(position))
	object.db = db
	object.name = name
	object.createdIcons = 0
	object.anchoredIcons = 0
	object.Whitelist = db.Whitelist
	object.Blacklist = db.Blacklist
	object:EnableMouse(false)
	IF:CreateMover(object)

	if name ~= 'Cooldowns' and name ~= 'ItemCooldowns' then
		object:SetAttribute('unit', unit)
		object.unit = unit
		object.filter = filter
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

function IF:ScanTooltip(index, bookType)
	PA.ScanTooltip:SetOwner(_G.UIParent, 'ANCHOR_NONE')
	PA.ScanTooltip:SetSpellBookItem(index, bookType)
	PA.ScanTooltip:Show()

	for i = 2, 4 do
		local str = _G['PAScanTooltipTextRight'..i]
		local text = str and str:GetText()
		if text then
			for _, matchtext in pairs(t) do
				if strmatch(text, matchtext) then
					return true
				end
			end
		end
	end
end

function IF:ScanSpellBook(bookType, numSpells, offset)
	offset = offset or 0
	for index = offset + 1, offset + numSpells, 1 do
		local skillType, special = GetSpellBookItemInfo(index, bookType)
		if skillType == 'SPELL' or skillType == 'PETACTION' then
			local SpellID, SpellName, Rank
			if PA.Retail then
				SpellID = select(2, GetSpellLink(index, bookType))
			else
				SpellName, Rank, SpellID = GetSpellBookItemName(index, bookType)
				if Rank ~= '' and Rank ~= nil then
					SpellName = format('%s %s', SpellName, Rank)
				end
			end
			if SpellID then
				IF.CompleteSpellBook[SpellID] = true
				if IF:ScanTooltip(index, bookType) then
					IF.SpellList[SpellID] = SpellName or true
				end
			end
		elseif skillType == 'FLYOUT' then
			local flyoutId = special
			local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutId)
			if numSlots > 0 and isKnown then
				for flyoutIndex = 1, numSlots, 1 do
					local SpellID, overrideId = GetFlyoutSlotInfo(flyoutId, flyoutIndex)
					if SpellID ~= overrideId then
						IF.CompleteSpellBook[overrideId] = true
					else
						IF.CompleteSpellBook[SpellID] = true
					end
					if IF:ScanTooltip(index, bookType) then
						if SpellID ~= overrideId then
							IF.SpellList[overrideId] = true
						else
							IF.SpellList[SpellID] = true
						end
					end
				end
			end
		elseif skillType == 'FUTURESPELL' then
		elseif not skillType then
			break
		end
	end
end

function IF:UpdateActiveCooldowns()
	local Panel = IF.Panels.Cooldowns

	for i = PA:CountTable(IF.ActiveCooldowns) + 1, #Panel do
		Panel[i]:Hide()
	end

	local Position = 0
	for SpellID in pairs(IF.ActiveCooldowns) do
		local Name, _, Icon = GetSpellInfo(SpellID)

		if Name then
			Position = Position + 1
			local button = Panel[Position] or IF:CreateAuraIcon(Panel)

			local Start, Duration, CurrentDuration, Charges

			if IF.IsChargeCooldown[SpellID] then
				Charges, _, Start, Duration = GetSpellCharges(SpellID)
			else
				Start, Duration = GetSpellCooldown(SpellID)
			end

			CurrentDuration = (Start + Duration - GetTime())

			if Charges and Start == (((2^32)/1000) - Duration) then
				CurrentDuration = 0
			end

			button.duration = Duration
			button.spellID = SpellID
			button.spellName = Name

			button.Texture:SetTexture(Icon)
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

	IF:SetPosition(Panel)
end

function IF:UpdateItemCooldowns()
	local Panel = IF.Panels.ItemCooldowns

	for i = PA:CountTable(IF.ItemCooldowns) + 1, #Panel do
		Panel[i]:Hide()
	end

	local Position = 0
	for itemID in pairs(IF.ItemCooldowns) do
		local Name = GetItemInfo(itemID)

		if Name then
			Position = Position + 1
			local button = Panel[Position] or IF:CreateAuraIcon(Panel)

			local Start, Duration, CurrentDuration
			Start, Duration = GetItemCooldown(itemID)
			CurrentDuration = (Start + Duration - GetTime())

			button.duration = Duration
			button.itemID = itemID
			button.itemName = Name
			button.expiration = Start + Duration

			button.Texture:SetTexture(GetItemIcon(itemID))
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

	IF:SetPosition(Panel)
end

function IF:UpdateDelayedCooldowns()
	local Start, Duration, Enable, CurrentDuration, Charges, _

	for SpellID in pairs(IF.DelayCooldowns) do
		Start, Duration, Enable = GetSpellCooldown(SpellID)

		if IF.IsChargeCooldown[SpellID] then
			Charges, _, Start, Duration = GetSpellCharges(SpellID)
			if Charges then
				Start, Duration = Start, Duration
			end
		end

		CurrentDuration = (Start + Duration - GetTime())

		if Enable and CurrentDuration and (CurrentDuration < IF.db.Cooldowns.SuppressDuration) then
			IF.DelayCooldowns[SpellID] = nil
			IF.ActiveCooldowns[SpellID] = Duration
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

function IF:IsAuraRemovable(dispelType)
	if not dispelType then return end

	if PA.MyClass == 'DEMONHUNTER' then
		return dispelType == 'Magic' and IsSpellKnown(205604)
	elseif PA.MyClass == 'DRUID' then
		return (dispelType == 'Curse' or dispelType == 'Poison') and IsSpellKnown(2782) or (dispelType == 'Magic' and (IsSpellKnown(88423) or IsSpellKnown(2782)))
	elseif PA.MyClass == 'HUNTER' then
		return (dispelType == 'Disease' or dispelType == 'Poison') and IsSpellKnown(212640)
	elseif PA.MyClass == 'MAGE' then
		return dispelType == 'Curse' and IsSpellKnown(475) or dispelType == 'Magic' and IsSpellKnown(30449)
	elseif PA.MyClass == 'MONK' then
		return dispelType == 'Magic' and IsSpellKnown(115450) or (dispelType == 'Disease' or dispelType == 'Poison') and (IsSpellKnown(115450) or IsSpellKnown(218164))
	elseif PA.MyClass == 'PALADIN' then
		return dispelType == 'Magic' and IsSpellKnown(4987) or (dispelType == 'Disease' or dispelType == 'Poison') and (IsSpellKnown(4987) or IsSpellKnown(213644))
	elseif PA.MyClass == 'PRIEST' then
		return dispelType == 'Magic' and (IsSpellKnown(528) or IsSpellKnown(527)) or dispelType == 'Disease' and IsSpellKnown(213634)
	elseif PA.MyClass == 'SHAMAN' then
		return dispelType == 'Magic' and (IsSpellKnown(370) or IsSpellKnown(77130)) or dispelType == 'Curse' and (IsSpellKnown(77130) or IsSpellKnown(51886))
	elseif PA.MyClass == 'WARLOCK' then
		return dispelType == 'Magic' and (IsSpellKnown(171021, true) or IsSpellKnown(89808, true) or IsSpellKnown(212623))
	end

	return false
end

function IF:CustomFilter(element, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer)
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
				return not IF.CompleteSpellBook[spellID]
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
	local name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3

	if PA.Classic and PA.LCD and not UnitIsUnit('player', unit) then
		local durationNew, expirationTimeNew
		name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3 = PA.LCD:UnitAura(unit, index, filter)

		if spellID then
			durationNew, expirationTimeNew = PA.LCD:GetAuraDurationByUnit(unit, spellID, caster, name)
		end

		if durationNew and durationNew > 0 then
			duration, expiration = durationNew, expirationTimeNew
		end
	else
		name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3 = UnitAura(unit, index, filter)
	end

	if name then
		local position = visible + offset + 1
		local button = element[position] or IF:CreateAuraIcon(element, position)

		button.caster = caster
		button.filter = filter
		button.isDebuff = isDebuff
		button.isPlayer = caster == 'player' or caster == 'vehicle'
		button.expiration = expiration
		button.duration = duration
		button.spellID = spellID

		local show = IF:CustomFilter(element, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

		if show then
			if not element.db.StatusBar then
				if (duration and duration >= AURA_MIN_DURATION) then
					button.Cooldown:SetCooldown(expiration - duration, duration)
				end
				button.Cooldown:SetShown(duration and duration >= AURA_MIN_DURATION)
			end

			button.StatusBar:SetStatusBarColor(unpack(element.db.StatusBarTextureColor))

			button.Texture:SetTexture(texture)
			button.Stacks:SetText(count > 1 and count)
			button.StatusBar.Name:SetText(name)

			button:SetID(index)
			button:Show()

			if isDebuff then
				button.Backdrop:SetBackdropBorderColor(1, 0, 0)
			else
				button.Backdrop:SetBackdropBorderColor(0, 0, 0)
			end

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

	local col, row
	for i, button in ipairs(element) do
		if (not button) then break end
		col = (i - 1) % cols
		row = floor((i - 1) / cols)

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
	for SpellID in pairs(IF.db.Cooldowns.SpellCDs) do
		local Start, Duration, Enable = GetSpellCooldown(SpellID)
		local CurrentDuration = (Start + Duration - GetTime()) or 0

		if Enable and (CurrentDuration > .1) and (CurrentDuration < IF.db.Cooldowns.IgnoreDuration) then
			if (CurrentDuration >= IF.db.Cooldowns.SuppressDuration) then
				IF.DelayCooldowns[SpellID] = true
			elseif (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
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

	for SpellID in pairs(IF.Cooldowns) do
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

		if Enable and CurrentDuration and (CurrentDuration < IF.db.Cooldowns.IgnoreDuration) then
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
				if duration and duration > GLOBAL_COOLDOWN_TIME then
					IF.ItemCooldowns[itemID] = true
				end
			end
		end
	end
end

function IF:CreateAuraIcon(element)
	local Frame = CreateFrame('Button', nil, element)
	Frame:EnableMouse(false)
	Frame:SetSize(element.db.Size, element.db.Size)

	Frame.Cooldown = CreateFrame('Cooldown', nil, Frame, 'CooldownFrameTemplate')
	Frame.Cooldown:SetAllPoints()
	Frame.Cooldown:SetReverse(false)
	Frame.Cooldown:SetDrawEdge(false)
	Frame.Cooldown.CooldownOverride = 'iFilger'
	PA:RegisterCooldown(Frame.Cooldown)

	Frame.Texture = Frame:CreateTexture(nil, 'ARTWORK')
	PA:SetInside(Frame.Texture)
	Frame.Texture:SetTexCoord(unpack(PA.TexCoords))

	local stackFrame = CreateFrame('Frame', nil, Frame)
	stackFrame:SetAllPoints(Frame)
	stackFrame:SetFrameLevel(Frame.Cooldown:GetFrameLevel() + 1)

	Frame.Stacks = stackFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	Frame.Stacks:SetFont(PA.LSM:Fetch('font', element.db.StackCountFont), element.db.StackCountFontSize, element.db.StackCountFontFlag)
	Frame.Stacks:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', 0, 2)

	Frame.StatusBar = CreateFrame('StatusBar', nil, Frame)
	Frame.StatusBar:SetSize(element.db.StatusBarWidth, element.db.StatusBarHeight)
	Frame.StatusBar:SetStatusBarTexture(PA.LSM:Fetch('statusbar', element.db.StatusBarTexture))
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
					local Normalized = expiration / Frame.duration
					s:SetValue(Normalized)
					s.Time:SetFormattedText(PA.TimeFormats[formatid][1], timervalue)
					s.Time:SetTextColor(color.r, color.g, color.b)
					if element.db.FollowCooldownText and (formatid == 1 or formatid == 2) then
						s:SetStatusBarColor(color.r, color.g, color.b)
					end
				end
				self.elapsed = 0
			end
		end)
	end

	Frame.StatusBar.Name = Frame.StatusBar:CreateFontString(nil, 'OVERLAY')
	Frame.StatusBar.Name:SetFont(PA.LSM:Fetch('font', element.db.StatusBarFont), element.db.StatusBarFontSize, element.db.StatusBarFontFlag)
	Frame.StatusBar.Name:SetPoint('BOTTOMLEFT', Frame.StatusBar, element.db.StatusBarNameX, element.db.StatusBarNameY)
	Frame.StatusBar.Name:SetJustifyH('LEFT')

	Frame.StatusBar.Time = Frame.StatusBar:CreateFontString(nil, 'OVERLAY')
	Frame.StatusBar.Time:SetFont(PA.LSM:Fetch('font', element.db.StatusBarFont), element.db.StatusBarFontSize, element.db.StatusBarFontFlag)
	Frame.StatusBar.Time:SetPoint('BOTTOMRIGHT', Frame.StatusBar, element.db.StatusBarTimeX, element.db.StatusBarTimeY)
	Frame.StatusBar.Time:SetJustifyH('RIGHT')

	PA:CreateBackdrop(Frame)
	PA:CreateShadow(Frame.Backdrop)
	PA:CreateBackdrop(Frame.StatusBar, 'Default')
	PA:CreateShadow(Frame.StatusBar.Backdrop)

	Frame.StatusBar:SetShown(element.db.StatusBar)
	Frame.StatusBar.Name:SetShown(element.db.StatusBarNameEnabled)
	Frame.StatusBar.Time:SetShown(element.db.StatusBarTimeEnabled)

	tinsert(element, Frame)
	element.createdIcons = element.createdIcons + 1

	return Frame
end

function IF:UpdateAll()
	for FrameName, Frame in pairs(IF.Panels) do
		Frame.db = IF.db[FrameName]

		if Frame.db.Enable then
			IF:EnableUnit(Frame)
		else
			IF:DisableUnit(Frame)
		end

		Frame:SetWidth((Frame.db.StatusBar and 1 or Frame.db.NumPerRow) * (Frame.db.StatusBar and Frame.db.StatusBarWidth or Frame.db.Size))

		for _, Button in ipairs(Frame) do
			Button:SetSize(Frame.db.Size, Frame.db.Size)
			Button.Stacks:SetFont(PA.LSM:Fetch('font', Frame.db.StackCountFont), Frame.db.StackCountFontSize, Frame.db.StackCountFontFlag)
			Button.StatusBar:SetStatusBarTexture(PA.LSM:Fetch('statusbar', Frame.db.StatusBarTexture))
			Button.StatusBar:SetStatusBarColor(unpack(Frame.db.StatusBarTextureColor))
			Button.StatusBar:SetSize(Frame.db.StatusBarWidth, Frame.db.StatusBarHeight)
			Button.StatusBar.Name:SetFont(PA.LSM:Fetch('font', Frame.db.StatusBarFont), Frame.db.StatusBarFontSize, Frame.db.StatusBarFontFlag)
			Button.StatusBar.Time:SetFont(PA.LSM:Fetch('font', Frame.db.StatusBarFont), Frame.db.StatusBarFontSize, Frame.db.StatusBarFontFlag)
			Button.StatusBar.Name:SetPoint('BOTTOMLEFT', Button.StatusBar, Frame.db.StatusBarNameX, Frame.db.StatusBarNameY)
			Button.StatusBar.Time:SetPoint('BOTTOMRIGHT', Button.StatusBar, Frame.db.StatusBarTimeX, Frame.db.StatusBarTimeY)
			Button.StatusBar:SetShown(Frame.db.StatusBar)
			Button.StatusBar.Name:SetShown(Frame.db.StatusBarNameEnabled)
			Button.StatusBar.Time:SetShown(Frame.db.StatusBarTimeEnabled)
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
	local numPetSpells = _G.HasPetSpells()
	if numPetSpells then
		IF:ScanSpellBook(_G.BOOKTYPE_PET, numPetSpells)

		PA:AddKeysToTable(IF.db.Cooldowns.SpellCDs, IF.SpellList)

		PA.Options.args.iFilger.args.Cooldowns.args.Spells.args = IF:GenerateSpellOptions()
	end
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
	for tab = 1, _G.GetNumSpellTabs(), 1 do
		local name, _, offset, numSpells = _G.GetSpellTabInfo(tab)
		if name then
			IF:ScanSpellBook(_G.BOOKTYPE_SPELL, numSpells, offset)
		end
	end

	local numPetSpells = _G.HasPetSpells()
	if numPetSpells then
		IF:ScanSpellBook(_G.BOOKTYPE_PET, numPetSpells)
	end

	PA.ScanTooltip:Hide()

	PA.Defaults.profile.iFilger = {
		Enable = false,
		Cooldown = CopyTable(PA.Defaults.profile.Cooldown),
	}

	for _, Name in ipairs({'Cooldowns', 'ItemCooldowns', 'Buffs', 'Procs', 'Enhancements', 'RaidDebuffs', 'TargetDebuffs', 'FocusBuffs', 'FocusDebuffs'}) do
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

	PA.Defaults.profile.iFilger.Cooldowns.SpellCDs = IF.SpellList
end

function IF:GenerateSpellOptions()
	local SpellOptions = {}

	for SpellID, SpellName in pairs(IF.db.Cooldowns.SpellCDs) do
		local Name, _, Icon = GetSpellInfo(SpellID)
		if Name then
			SpellOptions[tostring(SpellID)] = {
				type = 'toggle',
				image = Icon,
				imageCoords = PA.TexCoords,
				name = ' '..(type(SpellName) == 'string' and SpellName or Name),
				desc = 'Spell ID: '..SpellID,
			}
		end
	end

	return SpellOptions
end

function IF:GetOptions()
	IF:UpdateSettings()

	local iFilger = PA.ACH:Group(IF.Title, IF.Description, nil, 'tab')
	PA.Options.args.iFilger = iFilger

	iFilger.args.Description = PA.ACH:Description(IF.Description, 0)
	iFilger.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, function(info) return IF.db[info[#info]] end, function(info, value) IF.db[info[#info]] = value if (not IF.isEnabled) then IF:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	iFilger.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	iFilger.args.Authors = PA.ACH:Description(IF.Authors, -1, 'large')

	for _, Name in ipairs({'Cooldowns','ItemCooldowns','Buffs','Procs','Enhancements','RaidDebuffs','TargetDebuffs','FocusBuffs','FocusDebuffs'}) do
		iFilger.args[Name] = PA.ACH:Group(Name, nil, nil, nil, function(info) return IF.db[Name][info[#info]] end, function(info, value) IF.db[Name][info[#info]] = value IF:UpdateAll() end)

		iFilger.args[Name].args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 0)
		iFilger.args[Name].args.Size = PA.ACH:Range(PA.ACL['Icon Size'], nil, 1, { min = 16, max = 64, step = 1 })
		iFilger.args[Name].args.Spacing = PA.ACH:Range(PA.ACL['Spacing'], nil, 2, { min = 0, max = 18, step = 1 })
		iFilger.args[Name].args.NumPerRow = PA.ACH:Range(PA.ACL['Number Per Row'], nil, 3, { min = 1, max = 24, step = 1 }, nil, nil, nil, nil, function() return IF.db[Name].StatusBar end)
		iFilger.args[Name].args.Direction = PA.ACH:Select(PA.ACL['Growth Direction'], nil, 4, { LEFT = 'Left', RIGHT = 'Right' }, nil, nil, nil, nil, nil, function() return IF.db[Name].StatusBar end)
		iFilger.args[Name].args.FilterByList = PA.ACH:Select(PA.ACL['Filter by List'], nil, 5, { None = 'None', Whitelist = 'Whitelist', Blacklist = 'Blacklist' }, nil, nil, nil, nil, nil, Name == 'Cooldowns')

		iFilger.args[Name].args.IconStack = PA.ACH:Group(PA.ACL['Stack Count'], nil, 10)
		iFilger.args[Name].args.IconStack.inline = true
		iFilger.args[Name].args.IconStack.args.StackCountFont = PA.ACH:SharedMediaFont(PA.ACL['Font'], nil, 1)
		iFilger.args[Name].args.IconStack.args.StackCountFontSize = PA.ACH:Range(PA.ACL['Font Size'], nil, 2, { min = 8, max = 18, step = 1 })
		iFilger.args[Name].args.IconStack.args.StackCountFontFlag = PA.ACH:FontFlags(PA.ACL['Font Flag'], nil, 3)

		iFilger.args[Name].args.StatusBarGroup = PA.ACH:Group(PA.ACL['StatusBar'], nil, 11, nil, nil, nil, function() return not IF.db[Name].StatusBar end)
		iFilger.args[Name].args.StatusBarGroup.inline = true
		iFilger.args[Name].args.StatusBarGroup.args.StatusBar = PA.ACH:Toggle(PA.ACL['Enable'], nil, 0, nil, nil, nil, nil, nil, false)
		iFilger.args[Name].args.StatusBarGroup.args.FollowCooldownText = PA.ACH:Toggle(PA.ACL['Follow Cooldown Text Color'], PA.ACL['Follow Cooldown Text Colors (Expiring / Seconds)'], 1)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarWidth = PA.ACH:Range(PA.ACL['Width'], nil, 3, { min = 1, max = 256, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarHeight = PA.ACH:Range(PA.ACL['Height'], nil, 4, { min = 1, max = 64, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTexture = PA.ACH:SharedMediaStatusbar(PA.ACL['Texture'], nil, 5)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTextureColor = PA.ACH:Color(PA.ACL['Texture Color'], nil, 6, nil, nil, function(info) return unpack(IF.db[Name][info[#info]]) end, function(info, r, g, b, a) IF.db[Name][info[#info]] = { r, g, b, a} end)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarFont = PA.ACH:SharedMediaFont(PA.ACL['Font'], nil, 7)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarFontSize = PA.ACH:Range(PA.ACL['Font Size'], nil, 8, { min = 8, max = 18, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarFontFlag = PA.ACH:FontFlags(PA.ACL['Font Flags'], nil, 9)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarDirection = PA.ACH:Select(PA.ACL['Growth Direction'], nil, 10, { UP = 'Up', DOWN = 'Down' })

		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName = PA.ACH:Group(PA.ACL['Name'], nil, 11)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.inline = true
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.args.StatusBarNameEnabled = PA.ACH:Toggle(PA.ACL['Enable'], nil, 0)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.args.StatusBarNameX = PA.ACH:Range(PA.ACL['X Offset'], nil, 1, { min = -256, max = 256, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarName.args.StatusBarNameY = PA.ACH:Range(PA.ACL['Y Offset'], nil, 2, { min = -64, max = 64, step = 1 })

		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime = PA.ACH:Group(PA.ACL['Name'], nil, 12)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.inline = true
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.args.StatusBarTimeEnabled = PA.ACH:Toggle(PA.ACL['Enable'], nil, 0)
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.args.StatusBarTimeX = PA.ACH:Range(PA.ACL['X Offset'], nil, 1, { min = -256, max = 256, step = 1 })
		iFilger.args[Name].args.StatusBarGroup.args.StatusBarTime.args.StatusBarTimeY = PA.ACH:Range(PA.ACL['Y Offset'], nil, 2, { min = -64, max = 64, step = 1 })

		iFilger.args[Name].args.filterGroup = PA.ACH:Group(PA.ACL['Filters'], nil, 12, nil, nil, nil, nil, Name == 'Cooldowns')
		iFilger.args[Name].args.filterGroup.inline = true
		iFilger.args[Name].args.filterGroup.args.selectFilter = PA.ACH:Select(PA.ACL['Select Filter'], nil, 1, { Whitelist = 'Whitelist', Blacklist = 'Blacklist' }, nil, nil, function() return selectedFilter end, function(_, value) selectedFilter, selectedSpell = nil, nil if value ~= '' then selectedFilter = value end end)
		iFilger.args[Name].args.filterGroup.args.resetFilter = PA.ACH:Execute(PA.ACL["Reset Filter"], PA.ACL["This will reset the contents of this filter back to default. Any spell you have added to this filter will be removed."], 2, function() wipe(IF.db[Name][selectedFilter]) selectedSpell = nil end, nil, true)

		iFilger.args[Name].args.filterGroup.args.filterGroup = PA.ACH:Group(function() return selectedFilter end, nil, 10, nil, nil, nil, nil, function() return not selectedFilter end)
		iFilger.args[Name].args.filterGroup.args.filterGroup.inline = true
		iFilger.args[Name].args.filterGroup.args.filterGroup.args.addSpell = PA.ACH:Input(PA.ACL['Add SpellID'], PA.ACL['Add a spell to the filter.'], 1, nil, nil, function() return '' end, function(_, value) value = tonumber(value) if not value then return end local spellName = GetSpellInfo(value) selectedSpell = (spellName and value) or nil if not selectedSpell then return end IF.db[Name][selectedFilter][value] = true end)
		iFilger.args[Name].args.filterGroup.args.filterGroup.args.removeSpell = PA.ACH:Execute(PA.ACL["Remove Spell"], PA.ACL["Remove a spell from the filter. Use the spell ID if you see the ID as part of the spell name in the filter."], 2, function() local value = GetSelectedSpell() if not value then return end selectedSpell = nil IF.db[Name][selectedFilter][value] = nil end, nil, true)
		iFilger.args[Name].args.filterGroup.args.filterGroup.args.selectSpell = PA.ACH:Select(PA.ACL["Select Spell"], nil, 10, function() local list = IF.db[Name][selectedFilter] if not list then return end wipe(spellList) for filter in pairs(list) do local spellName = tonumber(filter) and GetSpellInfo(filter) local name = (spellName and format("%s |cFF888888(%s)|r", spellName, filter)) or tostring(filter) spellList[filter] = name end if not next(spellList) then spellList[''] = PA.ACL["None"] end return spellList end, nil, 'double', function() if not IF.db[Name][selectedFilter][selectedSpell] then selectedSpell = nil end return selectedSpell or '' end, function(_, value) selectedSpell = (value ~= '' and value) or nil end)
		iFilger.args[Name].args.filterGroup.args.spellGroup = PA.ACH:Group(function() local spell = GetSelectedSpell() local spellName = spell and GetSpellInfo(spell) return (spellName and spellName..' |cFF888888('..spell..')|r') or spell or ' ' end, nil, -15, nil, nil, nil, nil, function() return not GetSelectedSpell() end)
		iFilger.args[Name].args.filterGroup.args.spellGroup.inline = true
		iFilger.args[Name].args.filterGroup.args.spellGroup.args.enabled = PA.ACH:Toggle(PA.ACL['Enable'], nil, 0, nil, nil, nil, function() local spell = GetSelectedSpell() if not spell then return end return IF.db[Name][selectedFilter][spell] end, function(_, value) local spell = GetSelectedSpell() if not spell then return end IF.db[Name][selectedFilter][spell] = value end)
	end

	iFilger.args.Cooldowns.args.UpdateSpeed = PA.ACH:Range(PA.ACL['Update Speed'], nil, 5, { min = .1, max = .5, step = .1 })
	iFilger.args.ItemCooldowns.args.UpdateSpeed = PA.ACH:Range(PA.ACL['Update Speed'], nil, 5, { min = .1, max = .5, step = .1 })

	iFilger.args.Cooldowns.args.SuppressDuration = PA.ACH:Range(PA.ACL['Suppress Duration Threshold'], PA.ACL['Duration in Seconds'], 6, { min = 2, max = 600, step = 1 })
	iFilger.args.Cooldowns.args.IgnoreDuration = PA.ACH:Range(PA.ACL['Ignore Duration Threshold'], PA.ACL['Duration in Seconds'], 7, { min = 2, max = 600, step = 1 })

	iFilger.args.Cooldowns.args.Spells = PA.ACH:Group(_G.SPELLS, nil, 12, nil, function(info) return IF.db.Cooldowns.SpellCDs[tonumber(info[#info])] end, function(info, value) IF.db.Cooldowns.SpellCDs[tonumber(info[#info])] = value end)
	iFilger.args.Cooldowns.args.Spells.inline = true
	iFilger.args.Cooldowns.args.Spells.args = IF:GenerateSpellOptions()
end

function IF:UpdateSettings()
	IF.db = PA.db.iFilger
end

function IF:Initialize()
	IF:UpdateSettings()

	if IF.db.Enable ~= true then
		return
	end

	IF.isEnabled = true

	if PA.ElvUI then
		tinsert(_G.ElvUI[1].ConfigModeLayouts, #(_G.ElvUI[1].ConfigModeLayouts)+1, 'iFilger')
		_G.ElvUI[1].ConfigModeLocalizedStrings['iFilger'] = 'iFilger'
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
	IF:RegisterEvent('SPELLS_CHANGED')
	IF:RegisterEvent('BAG_UPDATE_COOLDOWN')
	IF:RegisterEvent('PLAYER_TARGET_CHANGED', function() if IF.db.TargetDebuffs.Enable then IF:UpdateAuras(IF.Panels.TargetDebuffs, 'target') end end)

	if PA.Retail then
		IF.Panels.FocusBuffs = IF:Spawn('focus', 'FocusBuffs', IF.db.FocusBuffs, 'HELPFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 })
		IF.Panels.FocusDebuffs = IF:Spawn('focus', 'FocusDebuffs', IF.db.FocusDebuffs, 'HARMFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 })
		IF:RegisterEvent('PLAYER_FOCUS_CHANGED', function() IF:UpdateAuras(IF.Panels.FocusBuffs, 'focus') IF:UpdateAuras(IF.Panels.FocusDebuffs, 'focus') end)
	end

	if IF.db.Cooldowns.Enable then
		IF:ScheduleRepeatingTimer('UpdateActiveCooldowns', IF.db.Cooldowns.UpdateSpeed)
		IF:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
	end

	if IF.db.ItemCooldowns.Enable then
		IF:ScheduleRepeatingTimer('UpdateItemCooldowns', IF.db.ItemCooldowns.UpdateSpeed)
	end
end
