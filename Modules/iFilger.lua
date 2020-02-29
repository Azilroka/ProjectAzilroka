local PA = _G.ProjectAzilroka
local iFilger = PA:NewModule('iFilger', 'AceEvent-3.0', 'AceTimer-3.0')
PA.iFilger = iFilger

iFilger.Title = 'iFilger'
iFilger.Header = '|cFF16C3F2i|r|cFFFFFFFFFilger|r'
iFilger.Description = 'Minimalistic Auras / Buffs / Procs / Cooldowns'
iFilger.Authors = 'Azilroka    Nils Ruesch    Ildyria'

iFilger.isEnabled = false

local _G = _G

_G.iFilger = iFilger

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

iFilger.Cooldowns = {}
iFilger.ActiveCooldowns = {}
iFilger.DelayCooldowns = {}
iFilger.IsChargeCooldown = {}
iFilger.SpellList = {}
iFilger.CompleteSpellBook = {}
iFilger.ItemCooldowns = {}

local GLOBAL_COOLDOWN_TIME = 1.5
local COOLDOWN_MIN_DURATION = .1
local AURA_MIN_DURATION = .1

-- Simpy Magic
local t = {}
for _, name in pairs({'SPELL_RECAST_TIME_SEC','SPELL_RECAST_TIME_MIN','SPELL_RECAST_TIME_CHARGES_SEC','SPELL_RECAST_TIME_CHARGES_MIN'}) do
    t[name] = _G[name]:gsub('%%%.%dg','[%%d%%.]-'):gsub('%.$','%%.'):gsub('^(.-)$','^%1$')
end

function iFilger:Spawn(unit, name, db, filter, position)
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
	iFilger:CreateMover(object)

	if name ~= 'Cooldowns' and name ~= 'ItemCooldowns' then
		object:SetAttribute('unit', unit)
		object.unit = unit
		object.filter = filter
		object:RegisterEvent('UNIT_AURA')
		object:SetScript('OnEvent', function() iFilger:UpdateAuras(object, unit) end)
		RegisterUnitWatch(object)

		if not db.Enable then
			iFilger:DisableUnit(object)
		end
	end

	return object
end

function iFilger:DisableUnit(button)
	button:Disable()
	button:UnregisterEvent('UNIT_AURA')
	for _, element in ipairs(button) do
		element:Hide()
	end
end

function iFilger:EnableUnit(button)
	button:Enable()
	button:RegisterEvent('UNIT_AURA')
end

function iFilger:ScanTooltip(index, bookType)
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

function iFilger:ScanSpellBook(bookType, numSpells, offset)
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
				iFilger.CompleteSpellBook[SpellID] = true
				if iFilger:ScanTooltip(index, bookType) then
					iFilger.SpellList[SpellID] = SpellName or true
				end
			end
		elseif skillType == 'FLYOUT' then
			local flyoutId = special
			local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutId)
			if numSlots > 0 and isKnown then
				for flyoutIndex = 1, numSlots, 1 do
					local SpellID, overrideId = GetFlyoutSlotInfo(flyoutId, flyoutIndex)
					if SpellID ~= overrideId then
						iFilger.CompleteSpellBook[overrideId] = true
					else
						iFilger.CompleteSpellBook[SpellID] = true
					end
					if iFilger:ScanTooltip(index, bookType) then
						if SpellID ~= overrideId then
							iFilger.SpellList[overrideId] = true
						else
							iFilger.SpellList[SpellID] = true
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

function iFilger:UpdateActiveCooldowns()
	local Panel = iFilger.Panels.Cooldowns

	for i = PA:CountTable(iFilger.ActiveCooldowns) + 1, #Panel do
		Panel[i]:Hide()
	end

	local Position = 0
	for SpellID in pairs(iFilger.ActiveCooldowns) do
		local Name, _, Icon = GetSpellInfo(SpellID)

		if Name then
			Position = Position + 1
			local button = Panel[Position] or iFilger:CreateAuraIcon(Panel)

			local Start, Duration, CurrentDuration, Charges

			if iFilger.IsChargeCooldown[SpellID] then
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
					local timervalue, formatid = PA:GetTimeInfo(CurrentDuration, iFilger.db.cooldown.threshold)
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
				iFilger.ActiveCooldowns[SpellID] = nil
				button.CurrentDuration = 0
			end
		end
	end

	iFilger:SetPosition(Panel)
end

function iFilger:UpdateItemCooldowns()
	local Panel = iFilger.Panels.ItemCooldowns

	for i = PA:CountTable(iFilger.ItemCooldowns) + 1, #Panel do
		Panel[i]:Hide()
	end

	local Position = 0
	for itemID in pairs(iFilger.ItemCooldowns) do
		local Name = GetItemInfo(itemID)

		if Name then
			Position = Position + 1
			local button = Panel[Position] or iFilger:CreateAuraIcon(Panel)

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
					local timervalue, formatid = PA:GetTimeInfo(CurrentDuration, iFilger.db.cooldown.threshold)
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
				iFilger.ItemCooldowns[itemID] = nil
				button.CurrentDuration = 0
			end
		end
	end

	iFilger:SetPosition(Panel)
end

function iFilger:UpdateDelayedCooldowns()
	local Start, Duration, Enable, CurrentDuration, Charges, _

	for SpellID in pairs(iFilger.DelayCooldowns) do
		Start, Duration, Enable = GetSpellCooldown(SpellID)

		if iFilger.IsChargeCooldown[SpellID] then
			Charges, _, Start, Duration = GetSpellCharges(SpellID)
			if Charges then
				Start, Duration = Start, Duration
			end
		end

		CurrentDuration = (Start + Duration - GetTime())

		if Enable and CurrentDuration and (CurrentDuration < iFilger.db.Cooldowns.SuppressDuration) then
			iFilger.DelayCooldowns[SpellID] = nil
			iFilger.ActiveCooldowns[SpellID] = Duration
		end
	end
end

function iFilger:CreateMover(frame)
	if PA.ElvUI then
		_G.ElvUI[1]:CreateMover(frame, frame:GetName()..'Mover', frame:GetName(), nil, nil, nil, 'ALL,iFilger', nil, 'ProjectAzilroka,iFilger,'..frame.name)
	elseif PA.Tukui then
		_G.Tukui[1]['Movers']:RegisterFrame(frame)
	end
end

function iFilger:IsAuraRemovable(dispelType)
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

function iFilger:CustomFilter(element, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer)
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
				return not iFilger.CompleteSpellBook[spellID]
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

function iFilger:UpdateAuraIcon(element, unit, index, offset, filter, isDebuff, visible)
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
		local button = element[position] or iFilger:CreateAuraIcon(element, position)

		button.caster = caster
		button.filter = filter
		button.isDebuff = isDebuff
		button.isPlayer = caster == 'player' or caster == 'vehicle'
		button.expiration = expiration
		button.duration = duration
		button.spellID = spellID

		local show = iFilger:CustomFilter(element, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

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

function iFilger:SetPosition(element)
	local sizex = (element.db.Size + element.db.Spacing + 2) + (element.db.StatusBar and element.db.StatusBarWidth or 0)
	local sizey = element.db.Size + element.db.Spacing + 2
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthx = not element.db.StatusBar and (element.db.Direction == 'LEFT' and -1) or 1
	local growthy = ((element.db.StatusBar and element.db.StatusBarDirection == 'DOWN' or element.db.Direction == 'DOWN') and -1) or 1
	local cols = floor(element:GetWidth() / sizex + 0.5)

	local col, row
	for i, button in ipairs(element) do
		if(not button) then break end
		col = (i - 1) % cols
		row = floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

function iFilger:FilterAuraIcons(element, unit, filter, limit, isDebuff, offset, dontHide)
	if (not offset) then offset = 0 end
	local index, visible, hidden = 1, 0, 0

	while (visible < limit) do
		local result = iFilger:UpdateAuraIcon(element, unit, index, offset, filter, isDebuff, visible)
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

function iFilger:UpdateAuras(element, unit)
	if(element.unit ~= unit) then return end

	iFilger:FilterAuraIcons(element, unit, element.filter, element.numAuras or 32, nil, 0)

	iFilger:SetPosition(element)
end

function iFilger:PLAYER_ENTERING_WORLD()
	for SpellID in pairs(iFilger.db.Cooldowns.SpellCDs) do
		local Start, Duration, Enable = GetSpellCooldown(SpellID)
		local CurrentDuration = (Start + Duration - GetTime()) or 0

		if Enable and (CurrentDuration > .1) and (CurrentDuration < iFilger.db.Cooldowns.IgnoreDuration) then
			if (CurrentDuration >= iFilger.db.Cooldowns.SuppressDuration) then
				iFilger.DelayCooldowns[SpellID] = Duration
			elseif (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				iFilger.ActiveCooldowns[SpellID] = Duration
			end
		end
	end

	if iFilger.db.SortByDuration then
		sort(iFilger.ActiveCooldowns)
	end

	iFilger:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function iFilger:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, SpellID)
	if (unit == 'player' or unit == 'pet') and iFilger.db.Cooldowns.SpellCDs[SpellID] then
		iFilger.Cooldowns[SpellID] = true
	end
end

function iFilger:SPELL_UPDATE_COOLDOWN()
	local Start, Duration, Enable, Charges, _, ChargeStart, ChargeDuration, CurrentDuration

	for SpellID in pairs(iFilger.Cooldowns) do
		Start, Duration, Enable = GetSpellCooldown(SpellID)

		if iFilger.IsChargeCooldown[SpellID] ~= false then
			Charges, _, ChargeStart, ChargeDuration = GetSpellCharges(SpellID)

			if iFilger.IsChargeCooldown[SpellID] == nil then
				iFilger.IsChargeCooldown[SpellID] = Charges and true or false
			end

			if Charges then
				Start, Duration = ChargeStart, ChargeDuration
			end
		end

		CurrentDuration = (Start + Duration - GetTime())

		if Enable and CurrentDuration and (CurrentDuration < iFilger.db.Cooldowns.IgnoreDuration) then
			if (CurrentDuration >= iFilger.db.Cooldowns.SuppressDuration) then
				iFilger.DelayCooldowns[SpellID] = Duration
			elseif (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				iFilger.ActiveCooldowns[SpellID] = Duration
			end
		end

		iFilger.Cooldowns[SpellID] = nil
	end

	if iFilger.db.SortByDuration then
		sort(iFilger.ActiveCooldowns)
	end
end

function iFilger:BAG_UPDATE_COOLDOWN()
	for bagID = 0, 4 do
		for slotID = 1, GetContainerNumSlots(bagID) do
			local itemID = GetContainerItemID(bagID, slotID)
			if itemID then
				local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
				if duration and duration > GLOBAL_COOLDOWN_TIME then
					iFilger.ItemCooldowns[itemID] = true
				end
			end
		end
	end
end

function iFilger:CreateAuraIcon(element)
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
				local timervalue, formatid = PA:GetTimeInfo(expiration, iFilger.db.cooldown.threshold)
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

function iFilger:UpdateAll()
	for _, Frame in pairs(iFilger.Panels) do
		if Frame.db.Enable then
			iFilger:EnableUnit(Frame)
		else
			iFilger:DisableUnit(Frame)
		end
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

	iFilger:CancelAllTimers()

	if iFilger.db.Cooldowns.Enable then
		iFilger:ScheduleRepeatingTimer('UpdateActiveCooldowns', iFilger.db.Cooldowns.UpdateSpeed)
		iFilger:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
	end

	if iFilger.db.ItemCooldowns.Enable then
		iFilger:ScheduleRepeatingTimer('UpdateItemCooldowns', iFilger.db.ItemCooldowns.UpdateSpeed)
	end
end

function iFilger:SPELLS_CHANGED()
	local numPetSpells = _G.HasPetSpells()
	if numPetSpells then
		iFilger:ScanSpellBook(_G.BOOKTYPE_PET, numPetSpells)

		iFilger.db.Cooldowns.SpellCDs = iFilger.SpellList

		PA.Options.args.iFilger.args.Cooldowns.args.Spells.args = iFilger:GenerateSpellOptions()
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

function iFilger:BuildProfile()
	for tab = 1, _G.GetNumSpellTabs(), 1 do
		local name, _, offset, numSpells = _G.GetSpellTabInfo(tab)
		if name then
			iFilger:ScanSpellBook(_G.BOOKTYPE_SPELL, numSpells, offset)
		end
	end

	local numPetSpells = _G.HasPetSpells()
	if numPetSpells then
		iFilger:ScanSpellBook(_G.BOOKTYPE_PET, numPetSpells)
	end

	PA.ScanTooltip:Hide()

	PA.Defaults.profile.iFilger = {
		Enable = false,
		cooldown = CopyTable(PA.Defaults.profile.cooldown),
	}

	for _, Name in ipairs({'Cooldowns', 'ItemCooldowns', 'Buffs', 'Procs', 'Enhancements', 'RaidDebuffs', 'TargetDebuffs', 'FocusBuffs', 'FocusDebuffs'}) do
		PA.Defaults.profile.iFilger[Name] = {
			Direction = 'RIGHT',
			Enable = true,
			FollowCooldownText = false,
			Size = 28,
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

	PA.Defaults.profile.iFilger.Cooldowns.SpellCDs = iFilger.SpellList
end

function iFilger:GenerateSpellOptions()
	local SpellOptions = {}

	for SpellID, SpellName in pairs(iFilger.db.Cooldowns.SpellCDs) do
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

function iFilger:GetOptions()
	iFilger.db = PA.db.iFilger

	PA.Options.args.iFilger = {
		type = 'group',
		name = iFilger.Title,
		desc = iFilger.Description,
		childGroups = 'tab',
		get = function(info) return iFilger.db[info[#info]] end,
		set = function(info, value) iFilger.db[info[#info]] = value end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = iFilger.Header,
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					iFilger.db[info[#info]] = value
					if (not iFilger.isEnabled) then
						iFilger:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			AuthorHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -1,
				type = 'description',
				name = iFilger.Authors,
				fontSize = 'large',
			},
		},
	}

	for _, Name in ipairs({'Cooldowns','ItemCooldowns','Buffs','Procs','Enhancements','RaidDebuffs','TargetDebuffs','FocusBuffs','FocusDebuffs'}) do
		PA.Options.args.iFilger.args[Name] = {
			type = 'group',
			name = Name,
			get = function(info) return iFilger.db[Name][info[#info]] end,
			set = function(info, value) iFilger.db[Name][info[#info]] = value iFilger:UpdateAll() end,
			childGroups = 'tree',
			args = {
				Enable = {
					type = 'toggle',
					order = 1,
					name = 'Enabled',
				},
				Size = {
					type = 'range',
					order = 2,
					name = 'Icon Size',
					min = 16, max = 64, step = 1,
				},
				Spacing = {
					type = 'range',
					order = 3,
					name = 'Spacing',
					min = 1, max = 18, step = 1,
				},
				Direction = {
					name = 'Growth Direction',
					order = 4,
					type = 'select',
					disabled = function() return iFilger.db[Name].StatusBar end,
					values = {
						UP = 'Up',
						DOWN = 'Down',
						LEFT = 'Left',
						RIGHT = 'Right',
					},
				},
				FilterByList = {
					name = 'Filter by List',
					order = 5,
					type = 'select',
					hidden = Name == 'Cooldowns',
					values = { None = 'None', Whitelist = 'Whitelist', Blacklist = 'Blacklist' },
				},
				IconStack = {
					type = 'group',
					name = 'Stack Count',
					order = 10,
					args = {
						StackCountFont = {
							type = 'select', dialogControl = 'LSM30_Font',
							order = 1,
							name = 'Font',
							values = PA.LSM:HashTable('font'),
						},
						StackCountFontSize = {
							type = 'range',
							order = 2,
							name = 'Font Size',
							min = 8, max = 18, step = 1,
						},
						StackCountFontFlag = {
							name = 'Font Flag',
							order = 3,
							type = 'select',
							values = PA.FontFlags,
						},
					},
				},
				StatusBarGroup = {
					type = 'group',
					name = 'StatusBar',
					order = 11,
					args = {
						StatusBar = {
							order = 1,
							type = 'toggle',
							name = 'Enabled',
						},
						FollowCooldownText = {
							order = 2,
							type = 'toggle',
							name = 'Follow Cooldown Text Color',
							desc = 'Follow Cooldown Text Colors (Expiring / Seconds)',
						},
						StatusBarWidth = {
							type = 'range',
							order = 3,
							name = 'Width',
							min = 1, max = 256, step = 1,
							disabled = function() return not iFilger.db[Name].StatusBar end,
						},
						StatusBarHeight = {
							type = 'range',
							order = 4,
							name = 'Height',
							min = 1, max = 64, step = 1,
							disabled = function() return not iFilger.db[Name].StatusBar end,
						},
						StatusBarTexture = {
							type = 'select', dialogControl = 'LSM30_Statusbar',
							order = 5,
							name = 'Texture',
							values = PA.LSM:HashTable('statusbar'),
							disabled = function() return not iFilger.db[Name].StatusBar end,
						},
						StatusBarTextureColor = {
							type = 'color',
							order = 6,
							name = 'Texture Color',
							hasAlpha = false,
							get = function(info) return unpack(iFilger.db[Name][info[#info]]) end,
							set = function(info, r, g, b, a) iFilger.db[Name][info[#info]] = { r, g, b, a} end,
							disabled = function() return not iFilger.db[Name].StatusBar end,
						},
						StatusBarFont = {
							type = 'select', dialogControl = 'LSM30_Font',
							order = 7,
							name = 'Font',
							values = PA.LSM:HashTable('font'),
							disabled = function() return not iFilger.db[Name].StatusBar end,
						},
						StatusBarFontSize = {
							type = 'range',
							order = 8,
							name = 'Font Size',
							min = 8, max = 18, step = 1,
							disabled = function() return not iFilger.db[Name].StatusBar end,
						},
						StatusBarFontFlag = {
							name = 'Font Flag',
							order = 9,
							type = 'select',
							disabled = function() return not iFilger.db[Name].StatusBar end,
							values = PA.FontFlags,
						},
						StatusBarDirection = {
							name = 'Growth Direction',
							order = 10,
							type = 'select',
							disabled = function() return not iFilger.db[Name].StatusBar end,
							values = {
								UP = 'Up',
								DOWN = 'Down',
							},
						},
						StatusBarName = {
							type = 'group',
							name = 'Name',
							order = 11,
							guiInline = true,
							disabled = function() return not iFilger.db[Name].StatusBar end,
							args = {
								StatusBarNameEnabled = {
									order = 1,
									type = 'toggle',
									name = 'Enabled',
								},
								StatusBarNameX = {
									type = 'range',
									order = 2,
									name = 'Name X Offset',
									min = -256, max = 256, step = 1,
								},
								StatusBarNameY = {
									type = 'range',
									order = 3,
									name = 'Name Y Offset',
									min = -64, max = 64, step = 1,
								},
							},
						},
						StatusBarTime = {
							type = 'group',
							name = 'Time',
							order = 12,
							guiInline = true,
							disabled = function() return not iFilger.db[Name].StatusBar end,
							args = {
								StatusBarTimeEnabled = {
									order = 1,
									type = 'toggle',
									name = 'Enabled',
								},
								StatusBarTimeX = {
									type = 'range',
									order = 12,
									name = 'Time X Offset',
									min = -256, max = 256, step = 1,
								},
								StatusBarTimeY = {
									type = 'range',
									order = 13,
									name = 'Time Y Offset',
									min = -64, max = 64, step = 1,
								},
							},
						},
					},
				},
				filterGroup = {
					type = 'group',
					name = PA.ACL["Filters"],
					order = 12,
					hidden = Name == 'Cooldowns',
					args = {
						selectFilter = {
							order = 2,
							type = 'select',
							name = PA.ACL["Select Filter"],
							get = function(info) return selectedFilter end,
							set = function(info, value)
								selectedFilter, selectedSpell = nil, nil
								if value ~= '' then
									selectedFilter = value
								end
							end,
							values = { Whitelist = 'Whitelist', Blacklist = 'Blacklist'},
						},
						filterGroup = {
							type = 'group',
							name = function() return selectedFilter end,
							hidden = function() return not selectedFilter end,
							guiInline = true,
							order = 10,
							args = {
								addSpell = {
									order = 1,
									name = PA.ACL["Add SpellID"],
									desc = PA.ACL["Add a spell to the filter."],
									type = 'input',
									get = function(info) return "" end,
									set = function(info, value)
										value = tonumber(value)
										if not value then return end

										local spellName = GetSpellInfo(value)
										selectedSpell = (spellName and value) or nil
										if not selectedSpell then return end

										iFilger.db[Name][selectedFilter][value] = true
									end,
								},
								removeSpell = {
									order = 2,
									name = PA.ACL["Remove Spell"],
									desc = PA.ACL["Remove a spell from the filter. Use the spell ID if you see the ID as part of the spell name in the filter."],
									type = 'execute',
									func = function()
										local value = GetSelectedSpell()
										if not value then return end
										selectedSpell = nil

										iFilger.db[Name][selectedFilter][value] = nil;
									end,
								},
								selectSpell = {
									name = PA.ACL["Select Spell"],
									type = 'select',
									order = 10,
									width = "double",
									get = function(info)
										if not iFilger.db[Name][selectedFilter][selectedSpell] then
											selectedSpell = nil
										end
										return selectedSpell or ''
									end,
									set = function(info, value)
										selectedSpell = (value ~= '' and value) or nil
									end,
									values = function()
										local list = iFilger.db[Name][selectedFilter]
										if not list then return end
										wipe(spellList)

										for filter in pairs(list) do
											local spellName = tonumber(filter) and GetSpellInfo(filter)
											local name = (spellName and format("%s |cFF888888(%s)|r", spellName, filter)) or tostring(filter)
											spellList[filter] = name
										end

										if not next(spellList) then
											spellList[''] = PA.ACL["None"]
										end

										return spellList
									end,
								},
							},
						},
						resetFilter = {
							order = 2,
							type = "execute",
							name = PA.ACL["Reset Filter"],
							desc = PA.ACL["This will reset the contents of this filter back to default. Any spell you have added to this filter will be removed."],
							confirm = true,
							func = function(info) wipe(iFilger.db[Name][selectedFilter]) selectedSpell = nil end,
						},
						spellGroup = {
							type = "group",
							name = function()
								local spell = GetSelectedSpell()
								local spellName = spell and GetSpellInfo(spell)
								return (spellName and spellName..' |cFF888888('..spell..')|r') or spell or ' '
							end,
							hidden = function() return not GetSelectedSpell() end,
							order = -15,
							guiInline = true,
							args = {
								enabled = {
									name = PA.ACL["Enable"],
									order = 0,
									type = 'toggle',
									get = function(info)
										local spell = GetSelectedSpell()
										if not spell then return end

										return iFilger.db[Name][selectedFilter][spell]
									end,
									set = function(info, value)
										local spell = GetSelectedSpell()
										if not spell then return end

										iFilger.db[Name][selectedFilter][spell] = value
									end,
								},
							},
						}
					},
				}
			},
		}
	end

	PA.Options.args.iFilger.args.Cooldowns.args.UpdateSpeed = {
		order = 5,
		type = 'range',
		name = PA.ACL['Update Speed'],
		min = .1, max = .5, step = .1,
	}

	PA.Options.args.iFilger.args.ItemCooldowns.args.UpdateSpeed = {
		order = 5,
		type = 'range',
		name = PA.ACL['Update Speed'],
		min = .1, max = .5, step = .1,
	}

	PA.Options.args.iFilger.args.Cooldowns.args.SuppressDuration = {
		order = 6,
		type = 'range',
		name = PA.ACL['Suppress Duration Threshold'],
		desc = PA.ACL['Duration in Seconds'],
		min = 2, max = 600, step = 1,
	}

	PA.Options.args.iFilger.args.Cooldowns.args.IgnoreDuration = {
		order = 7,
		type = 'range',
		name = PA.ACL['Ignore Duration Threshold'],
		desc = PA.ACL['Duration in Seconds'],
		min = 2, max = 600, step = 1,
	}

	PA.Options.args.iFilger.args.Cooldowns.args.Spells = {
		order = 12,
		type = 'group',
		name = _G.SPELLS,
		args = iFilger:GenerateSpellOptions(),
		get = function(info) return iFilger.db.Cooldowns.SpellCDs[tonumber(info[#info])] end,
		set = function(info, value)	iFilger.db.Cooldowns.SpellCDs[tonumber(info[#info])] = value end,
	}
end

function iFilger:Initialize()
	iFilger.db = PA.db.iFilger

	if iFilger.db.Enable ~= true then
		return
	end

	iFilger.isEnabled = true

	if PA.ElvUI then
		tinsert(_G.ElvUI[1].ConfigModeLayouts, #(_G.ElvUI[1].ConfigModeLayouts)+1, 'iFilger')
		_G.ElvUI[1].ConfigModeLocalizedStrings['iFilger'] = 'iFilger'
	end

	iFilger.Panels = {
		Buffs = iFilger:Spawn('player', 'Buffs', iFilger.db.Buffs, 'HELPFUL', { 'TOPLEFT', UIParent, 'CENTER', -351, -203 }),
		RaidDebuffs = iFilger:Spawn('player', 'RaidDebuffs', iFilger.db.RaidDebuffs, 'HARMFUL', { 'TOPLEFT', UIParent, 'CENTER', -351, -203 }),
		Procs = iFilger:Spawn('player', 'Procs', iFilger.db.Procs, 'HELPFUL', { 'BOTTOMLEFT', UIParent, 'CENTER', -57, -52 }),
		Enhancements = iFilger:Spawn('player', 'Enhancements', iFilger.db.Enhancements, 'HELPFUL', { 'BOTTOMRIGHT', UIParent, 'CENTER', -351, 161 }),
		TargetDebuffs = iFilger:Spawn('target', 'TargetDebuffs', iFilger.db.TargetDebuffs, 'HARMFUL|PLAYER', { 'TOPLEFT', UIParent, 'CENTER', 283, -207 }),
		Cooldowns = iFilger:Spawn('player', 'Cooldowns', iFilger.db.Cooldowns, nil, { 'BOTTOMRIGHT', UIParent, 'CENTER', -71, -109 }),
		ItemCooldowns = iFilger:Spawn('player', 'ItemCooldowns', iFilger.db.ItemCooldowns, nil, { 'BOTTOMRIGHT', UIParent, 'CENTER', -71, -109 }),
	}

	iFilger:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')	-- For Cooldown Queue
	iFilger:RegisterEvent('SPELL_UPDATE_COOLDOWN')		-- Process Cooldown Queue
	iFilger:RegisterEvent('SPELLS_CHANGED')
	iFilger:RegisterEvent('BAG_UPDATE_COOLDOWN')
	iFilger:RegisterEvent('PLAYER_TARGET_CHANGED', function() iFilger:UpdateAuras(iFilger.Panels.TargetDebuffs, 'target') end)

	if PA.Retail then
		iFilger.Panels.FocusBuffs = iFilger:Spawn('focus', 'FocusBuffs', iFilger.db.FocusBuffs, 'HELPFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 })
		iFilger.Panels.FocusDebuffs = iFilger:Spawn('focus', 'FocusDebuffs', iFilger.db.FocusDebuffs, 'HARMFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 })
		iFilger:RegisterEvent('PLAYER_FOCUS_CHANGED', function() iFilger:UpdateAuras(iFilger.Panels.FocusBuffs, 'focus') iFilger:UpdateAuras(iFilger.Panels.FocusDebuffs, 'focus') end)
	end

	if iFilger.db.Cooldowns.Enable then
		iFilger:ScheduleRepeatingTimer('UpdateActiveCooldowns', iFilger.db.Cooldowns.UpdateSpeed)
		iFilger:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
	end

	if iFilger.db.ItemCooldowns.Enable then
		iFilger:ScheduleRepeatingTimer('UpdateItemCooldowns', iFilger.db.ItemCooldowns.UpdateSpeed)
	end
end
