local PA = _G.ProjectAzilroka
local iFilger = PA:NewModule('iFilger', 'AceEvent-3.0', 'AceTimer-3.0')
PA.iFilger = iFilger

iFilger.Title = 'iFilger'
iFilger.Header = '|cFF16C3F2i|r|cFFFFFFFFFilger|r'
iFilger.Description = 'Minimalistic Auras / Buffs / Procs / Cooldowns'
iFilger.Authors = 'Azilroka    Nils Ruesch    Ildyria'

iFilger.isEnabled = false

_G.iFilger = iFilger

local RegisterUnitWatch = RegisterUnitWatch
local UnitAura = UnitAura
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellCharges = GetSpellCharges
local CreateFrame = CreateFrame
local UIParent = UIParent

local pairs = pairs
local format = format
local sort = sort
local select = select
local floor = floor
local unpack = unpack
local tinsert = tinsert

local GetItemInfo = GetItemInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemCooldown = GetInventoryItemCooldown
local IsSpellKnown = IsSpellKnown

local VISIBLE = 1
local HIDDEN = 0

iFilger.Cooldowns = {}
iFilger.ActiveCooldowns = {}
iFilger.DelayCooldowns = {}
iFilger.IsChargeCooldown = {}
iFilger.SpellList = {}
iFilger.CompleteSpellBook = {}

-- Simpy Magic
local t = {}
for _, name in pairs({'SPELL_RECAST_TIME_SEC','SPELL_RECAST_TIME_MIN','SPELL_RECAST_TIME_CHARGES_SEC','SPELL_RECAST_TIME_CHARGES_MIN'}) do
    t[name] = _G[name]:gsub('%%%.%dg','%%d-'):gsub('%.$','%%.'):gsub('^(.-)$','^%1$')
end

function iFilger:Spawn(unit, name, db, filter, position)
	local object = CreateFrame('Button', 'iFilger_'..name, PA.PetBattleFrameHider, 'SecureUnitButtonTemplate')
	object:SetSize(100, 20)
	object:SetPoint(unpack(position))
	object:SetAttribute('unit', unit)

	object.unit = unit
	object.db = db
	object.filter = filter
	object.name = name
	object.createdIcons = 0
	object.anchoredIcons = 0

	object:RegisterEvent('UNIT_AURA')
	object:SetScript('OnEvent', function() iFilger:UpdateAuras(object, unit) end)

	RegisterUnitWatch(object)

	iFilger:CreateMover(object)

	if not db.Enable then
		iFilger:DisableUnit(object)
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
				SpellName = format('%s %s', SpellName, Rank)
			end
			iFilger.CompleteSpellBook[SpellID] = true
			if iFilger:ScanTooltip(index, bookType) then
				iFilger.SpellList[SpellID] = SpellName or true
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
	for i = PA:CountTable(iFilger.ActiveCooldowns) + 1, #iFilger.Holder do
		iFilger.Holder[i]:Hide()
	end

	local Position = 0
	for SpellID in pairs(iFilger.ActiveCooldowns) do
		local Name, _, Icon = GetSpellInfo(SpellID)

		if Name then
			Position = Position + 1
			local Frame = iFilger.Panels.Cooldowns[Position]
			if (not Frame) then
				Frame = iFilger:CreateAuraIcon(iFilger.Panels.Cooldowns)
			end

			local Start, Duration, CurrentDuration, Charges

			if iFilger.IsChargeCooldown[SpellID] then
				Charges, _, Start, Duration = GetSpellCharges(SpellID)
				if Charges then
					CurrentDuration = (Start + Duration - GetTime())
					if Start == (((2^32)/1000) - Duration) then
						CurrentDuration = 0
					end
				end
			else
				Start, Duration = GetSpellCooldown(SpellID)
				CurrentDuration = (Start + Duration - GetTime())
			end

			Frame.CurrentDuration = CurrentDuration
			Frame.Duration = Duration
			Frame.SpellID = SpellID
			Frame.SpellName = Name

			Frame.Icon:SetTexture(Icon)

			if (CurrentDuration and CurrentDuration > 0) then
				if iFilger.db[Frame.Owner]["StatusBar"] then
					local timervalue, formatid = iFilger:GetTimeInfo(CurrentDuration)
					self.StatusBar:SetValue(CurrentDuration / Duration)
					self.StatusBar.Time:SetFormattedText(iFilger.TimeFormats[formatid], timervalue)
					self.StatusBar.Time:SetTextColor(unpack(iFilger.TimeColors[formatid]))
					self.StatusBar:SetStatusBarColor(unpack(iFilger.db[Frame.Owner].StatusBarTextureColor))
					if iFilger.db[Frame.Owner]['FollowCooldownText'] and (formatid == 1 or formatid == 2) then
						self.StatusBar:SetStatusBarColor(unpack(iFilger.TimeColors[formatid]))
					end
				else
					Frame.Cooldown:SetCooldown(Start, Duration)
				end
				Frame:Show()
			else
				iFilger.ActiveCooldowns[SpellID] = nil
				Frame.CurrentDuration = 0
				Frame:Hide()
			end
		end
	end
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

		if Enable and CurrentDuration and (CurrentDuration < iFilger.db.SuppressDuration) then
			iFilger.DelayCooldowns[SpellID] = nil
			iFilger.ActiveCooldowns[SpellID] = Duration
		end
	end
end

function iFilger:CreateMover(frame)
	if PA.ElvUI then
		_G.ElvUI[1]:CreateMover(frame, frame:GetName()..'Mover', frame:GetName(), nil, nil, nil, "ALL,iFilger")
	elseif PA.Tukui then
		_G.Tukui[1]["Movers"]:RegisterFrame(frame)
	end
end

function iFilger:IsAuraRemovable(dispelType)
	if not dispelType then return end

	if PA.MyClass == "DEMONHUNTER" then
		return dispelType == "Magic" and IsSpellKnown(205604)
	elseif PA.MyClass == "DRUID" then
		return (dispelType == "Curse" or dispelType == "Poison") and IsSpellKnown(2782) or (dispelType == "Magic" and (IsSpellKnown(88423) or IsSpellKnown(2782)))
	elseif PA.MyClass == "HUNTER" then
		return (dispelType == "Disease" or dispelType == "Poison") and IsSpellKnown(212640)
	elseif PA.MyClass == "MAGE" then
		return dispelType == "Curse" and IsSpellKnown(475) or dispelType == "Magic" and IsSpellKnown(30449)
	elseif PA.MyClass == "MONK" then
		return dispelType == "Magic" and IsSpellKnown(115450) or (dispelType == "Disease" or dispelType == "Poison") and (IsSpellKnown(115450) or IsSpellKnown(218164))
	elseif PA.MyClass == "PALADIN" then
		return dispelType == "Magic" and IsSpellKnown(4987) or (dispelType == "Disease" or dispelType == "Poison") and (IsSpellKnown(4987) or IsSpellKnown(213644))
	elseif PA.MyClass == "PRIEST" then
		return dispelType == "Magic" and (IsSpellKnown(528) or IsSpellKnown(527)) or dispelType == "Disease" and IsSpellKnown(213634)
	elseif PA.MyClass == "SHAMAN" then
		return dispelType == "Magic" and (IsSpellKnown(370) or IsSpellKnown(77130)) or dispelType == "Curse" and (IsSpellKnown(77130) or IsSpellKnown(51886))
	elseif PA.MyClass == "WARLOCK" then
		return dispelType == "Magic" and (IsSpellKnown(171021, true) or IsSpellKnown(89808, true) or IsSpellKnown(212623))
	end

	return false
end

function iFilger:CustomFilter(element, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer)
	if element.name == 'Procs' then
		if duration == 0 then
			return false
		elseif caster == 'player' then
			return not iFilger.CompleteSpellBook[spellID]
		end
	else
		local isPlayer = (caster == 'player' or caster == 'vehicle')
		if (isPlayer or casterIsPlayer) and (duration ~= 0) then
			return true
		else
			return false
		end
	end
end

function iFilger:UpdateAuraIcon(element, unit, index, offset, filter, isDebuff, visible)
	local name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3 = UnitAura(unit, index, filter)

	if name then
		local position = visible + offset + 1
		local button = element[position]

		if (not button) then
			button = iFilger:CreateAuraIcon(element, position)
			element.createdIcons = element.createdIcons + 1
		end

		button.caster = caster
		button.filter = filter
		button.isDebuff = isDebuff
		button.isPlayer = caster == 'player' or caster == 'vehicle'
		button.expiration = expiration
		button.duration = duration

		local show = iFilger:CustomFilter(element, unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

		if show then
			if not element.db.StatusBar then
				if (duration and duration > 0) then
					button.Cooldown:SetCooldown(expiration - duration, duration)
				end
				button.Cooldown:SetShown(duration and duration > 0)
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

	for i, button in ipairs(element) do
		if(not button) then break end
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

function iFilger:FilterAuraIcons(element, unit, filter, limit, isDebuff, offset, dontHide)
	if (not offset) then offset = 0 end
	local index = 1
	local visible = 0
	local hidden = 0
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
	for SpellID in pairs(iFilger.db.SpellCDs) do
		local Start, Duration, Enable = GetSpellCooldown(SpellID)
		local CurrentDuration = (Start + Duration - GetTime()) or 0

		if Enable and (CurrentDuration > .1) and (CurrentDuration < iFilger.db.IgnoreDuration) then
			if (CurrentDuration >= iFilger.db.SuppressDuration) then
				iFilger.DelayCooldowns[SpellID] = Duration
			else
				iFilger.ActiveCooldowns[SpellID] = Duration
			end
		end
	end

	if iFilger.db.SortByDuration then
		sort(iFilger.ActiveCooldowns)
	end
end

function iFilger:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, SpellID)
	if unit == 'player' and (iFilger.db.SpellCDs[SpellID] or SpellID == 13877) then
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

		if Enable and CurrentDuration and (CurrentDuration < iFilger.db.IgnoreDuration) then
			if (CurrentDuration >= iFilger.db.SuppressDuration) then
				iFilger.DelayCooldowns[SpellID] = Duration
			else
				iFilger.ActiveCooldowns[SpellID] = Duration
			end
		end

		iFilger.Cooldowns[SpellID] = nil
	end

	if iFilger.db.SortByDuration then
		sort(iFilger.ActiveCooldowns)
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
	Frame.Texture:SetInside()
	Frame.Texture:SetTexCoord(unpack(PA.TexCoords))

	Frame.Stacks = Frame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	Frame.Stacks:SetFont(PA.LSM:Fetch('font', element.db.StackCountFont), element.db.StackCountFontSize, element.db.StackCountFontFlag)
	Frame.Stacks:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', 0, 2)

	Frame.StatusBar = CreateFrame('StatusBar', nil, Frame)
	Frame.StatusBar:SetSize(element.db.StatusBarWidth, element.db.StatusBarHeight)
	Frame.StatusBar:SetStatusBarTexture(PA.LSM:Fetch('statusbar', element.db.StatusBarTexture))
	Frame.StatusBar:SetStatusBarColor(unpack(element.db.StatusBarTextureColor))
	Frame.StatusBar:SetPoint('BOTTOMLEFT', Frame, 'BOTTOMRIGHT', 2, 0)
	Frame.StatusBar:SetMinMaxValues(0, 1)
	Frame.StatusBar:SetValue(0)
	Frame.StatusBar:SetScript('OnUpdate', function(s, elapsed)
		s.elapsed = (s.elapsed or 0) + elapsed
		if (s.elapsed > .1) then
			local timervalue, formatid = PA:GetTimeInfo(Frame.expiration - GetTime(), iFilger.db.cooldown.threshold)
			local color = PA.TimeColors[formatid]
			if timervalue then
				local Normalized = timervalue / Frame.duration
				s:SetValue(Normalized)
				s.Time:SetFormattedText(PA.TimeFormats[formatid][1], timervalue)
				s.Time:SetTextColor(color.r, color.g, color.b)
				if element.db.FollowCooldownText then
					s:SetStatusBarColor(color.r, color.g, color.b)
				end
			end
			self.elapsed = 0
		end
	end)

	Frame.StatusBar.Name = Frame.StatusBar:CreateFontString(nil, 'OVERLAY')
	Frame.StatusBar.Name:SetFont(PA.LSM:Fetch('font', element.db.StatusBarFont), element.db.StatusBarFontSize, element.db.StatusBarFontFlag)
	Frame.StatusBar.Name:SetPoint('BOTTOMLEFT', Frame.StatusBar, element.db.StatusBarNameX, element.db.StatusBarNameY)
	Frame.StatusBar.Name:SetJustifyH('LEFT')

	Frame.StatusBar.Time = Frame.StatusBar:CreateFontString(nil, 'OVERLAY')
	Frame.StatusBar.Time:SetFont(PA.LSM:Fetch('font', element.db.StatusBarFont), element.db.StatusBarFontSize, element.db.StatusBarFontFlag)
	Frame.StatusBar.Time:SetPoint('BOTTOMRIGHT', Frame.StatusBar, element.db.StatusBarTimeX, element.db.StatusBarTimeY)
	Frame.StatusBar.Time:SetJustifyH('RIGHT')

	PA:CreateBackdrop(Frame)
	PA:CreateShadow(Frame)
	PA:CreateBackdrop(Frame.StatusBar, 'Default')
	PA:CreateShadow(Frame.StatusBar.Backdrop)

	Frame.StatusBar:SetShown(element.db.StatusBar)
	Frame.StatusBar.Name:SetShown(element.db.StatusBarNameEnabled)
	Frame.StatusBar.Time:SetShown(element.db.StatusBarTimeEnabled)

	tinsert(element, Frame)

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
end

function iFilger:BuildProfile()
	PA.Defaults.profile.iFilger = {
		cooldown = CopyTable(PA.Defaults.profile.cooldown),
	}

	for _, Name in ipairs({'Cooldowns','Buffs','Procs','Enhancements','RaidDebuffs','TargetDebuffs','FocusBuffs','FocusDebuffs'}) do
		PA.Defaults.profile.iFilger[Name] = {
			Direction = 'RIGHT',
			Enable = true,
			FollowCooldownText = false,
			Size = 28,
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
			StatusBarNameY = 0,
			StatusBarTexture = PA.ElvUI and 'ElvUI Norm' or 'Blizzard Raid Bar',
			StatusBarTextureColor = { .24, .54, .78 },
			StatusBarTimeEnabled = true,
			StatusBarTimeX = 0,
			StatusBarTimeY = 0,
			StatusBarWidth = 148,
		}
	end
end

function iFilger:GetOptions()
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

	for _, Name in ipairs({'Cooldowns','Buffs','Procs','Enhancements','RaidDebuffs','TargetDebuffs','FocusBuffs','FocusDebuffs'}) do
		PA.Options.args.iFilger.args[Name] = {
			type = 'group',
			name = Name,
			get = function(info) return iFilger.db[Name][info[#info]] end,
			set = function(info, value) iFilger.db[Name][info[#info]] = value iFilger:UpdateAll() end,
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
				IconStack = {
					type = 'group',
					name = 'Stack Count',
					guiInline = true,
					order = 4,
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
					order = 5,
					guiInline = true,
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
									min = -12, max = 12, step = 1,
								},
								StatusBarNameY = {
									type = 'range',
									order = 3,
									name = 'Name Y Offset',
									min = -12, max = 12, step = 1,
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
									min = -12, max = 12, step = 1,
								},
								StatusBarTimeY = {
									type = 'range',
									order = 13,
									name = 'Time Y Offset',
									min = -12, max = 12, step = 1,
								},
							},
						},
					},
				},
			},
		}
	end
end

function iFilger:Initialize()
	iFilger.db = PA.db.iFilger

	if iFilger.db.Enable ~= true then
		return
	end

	iFilger.isEnabled = true

	if PA.ElvUI then
		tinsert(_G.ElvUI[1].ConfigModeLayouts, #(_G.ElvUI[1].ConfigModeLayouts)+1, "iFilger")
		_G.ElvUI[1].ConfigModeLocalizedStrings["iFilger"] = "iFilger"
	end

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

	iFilger.Panels = {
		Buffs = iFilger:Spawn('player', 'Buffs', iFilger.db.Buffs, 'HELPFUL', { 'TOPLEFT', UIParent, 'CENTER', -351, -203 }),
		RaidDebuffs = iFilger:Spawn('player', 'RaidDebuffs', iFilger.db.RaidDebuffs, 'HARMFUL', { 'TOPLEFT', UIParent, 'CENTER', -351, -203 }),
		Procs = iFilger:Spawn('player', 'Procs', iFilger.db.Procs, 'HELPFUL', { 'BOTTOMLEFT', UIParent, 'CENTER', -57, -52 }),
		Enhancements = iFilger:Spawn('player', 'Enhancements', iFilger.db.Enhancements, 'HELPFUL', { 'BOTTOMRIGHT', UIParent, 'CENTER', -351, 161 }),
		TargetDebuffs = iFilger:Spawn('target', 'TargetDebuffs', iFilger.db.TargetDebuffs, 'HARMFUL|PLAYER', { 'TOPLEFT', UIParent, 'CENTER', 283, -207 }),
		FocusBuffs = iFilger:Spawn('focus', 'FocusBuffs', iFilger.db.FocusBuffs, 'HELPFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 }),
		FocusDebuffs = iFilger:Spawn('focus', 'FocusDebuffs', iFilger.db.FocusDebuffs, 'HARMFUL', { 'TOPRIGHT', UIParent, 'CENTER', -53, 53 }),
	}
--[[
--	self.Panels['Cooldowns'] = { AnchorPoint = 'BOTTOMRIGHT', X = -71, Y = -109, AnchorText = 'Cooldowns', OptionsOrder = 1 }

	iFilger:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')	-- For Cooldown Queue
	iFilger:RegisterEvent('SPELL_UPDATE_COOLDOWN')		-- Process Cooldown Queue

	iFilger:ScheduleRepeatingTimer('UpdateActiveCooldowns', iFilger.db.UpdateSpeed)
	iFilger:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
]]
end
