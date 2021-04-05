local PA = _G.ProjectAzilroka
local OzCD = PA:NewModule('OzCooldowns', 'AceEvent-3.0', 'AceTimer-3.0')
PA.OzCD = OzCD

OzCD.Title = '|cFF16C3F2Oz|r|cFFFFFFFFCooldowns|r'
OzCD.Description = 'Minimalistic Cooldowns'
OzCD.Authors = 'Azilroka    Nimaear'
OzCD.isEnabled = false

_G.OzCooldowns = OzCD

local pairs = pairs
local format = format
local ceil = ceil
local sort = sort
local floor = floor
local unpack = unpack
local tinsert = tinsert
local tostring = tostring
local tonumber = tonumber
local strmatch = strmatch

local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellCharges = GetSpellCharges
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellLink = GetSpellLink
local GetSpellBookItemName = GetSpellBookItemName
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local SendChatMessage = SendChatMessage
local GetFlyoutInfo = GetFlyoutInfo
local GetFlyoutSlotInfo = GetFlyoutSlotInfo

local CopyTable = CopyTable
local CreateFrame = CreateFrame
local UIParent = UIParent

local Channel

OzCD.Holder = CreateFrame('Frame', 'OzCooldownsHolder', PA.PetBattleFrameHider)
OzCD.Holder:SetSize(40, 40)
OzCD.Holder:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 360)

if not (PA.Tukui or PA.ElvUI) then
	OzCD.Holder:SetMovable(true)
end

OzCD.Cooldowns = {}
OzCD.ActiveCooldowns = {}
OzCD.DelayCooldowns = {}
OzCD.IsChargeCooldown = {}
OzCD.SpellList = {}

local GLOBAL_COOLDOWN_TIME = 1.5
local COOLDOWN_MIN_DURATION = .1

-- Simpy Magic
local t = {}
for _, name in pairs({'SPELL_RECAST_TIME_SEC','SPELL_RECAST_TIME_MIN','SPELL_RECAST_TIME_CHARGES_SEC','SPELL_RECAST_TIME_CHARGES_MIN'}) do
    t[name] = _G[name]:gsub('%%%.%dg','[%%d%%.]-'):gsub('%.$','%%.'):gsub('^(.-)$','^%1$')
end

OzCD.HasCDDelay = {
	[5384] = true
}

function OzCD:ScanTooltip(index, bookType)
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

function OzCD:ScanSpellBook(bookType, numSpells, offset)
	offset = offset or 0
	for index = offset + 1, offset + numSpells, 1 do
		local skillType, special = GetSpellBookItemInfo(index, bookType)
		if skillType == 'SPELL' or skillType == 'PETACTION' then
			local SpellID, SpellName, Rank
			if PA.Retail then
				SpellID = select(2, GetSpellLink(index, bookType))
			else
				SpellName, Rank, SpellID = GetSpellBookItemName(index, bookType)
				SpellName = (Rank and Rank ~= '') and format('%s %s', SpellName, Rank)
			end
			if SpellID and OzCD:ScanTooltip(index, bookType) then
				OzCD.SpellList[SpellID] = SpellName or true
			end
		elseif skillType == 'FLYOUT' then
			local flyoutId = special
			local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutId)
			if numSlots > 0 and isKnown then
				for flyoutIndex = 1, numSlots, 1 do
					local SpellID, overrideId = GetFlyoutSlotInfo(flyoutId, flyoutIndex)
					if OzCD:ScanTooltip(index, bookType) then
						if SpellID ~= overrideId then
							OzCD.SpellList[overrideId] = true
						else
							OzCD.SpellList[SpellID] = true
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

function OzCD:SetSize(Position)
	Position = Position or PA:CountTable(OzCD.ActiveCooldowns)
	local Vertical, Spacing, Size = OzCD.db.Vertical, OzCD.db.Spacing + 2, OzCD.db.Size
	local xSpacing = Vertical and 0 or Spacing
	local ySpacing = Vertical and (Spacing + (OzCD.db.StatusBar and 5 or 0)) or 0

	if OzCD.db.Vertical then
		OzCD.Holder:SetSize(Size, (Size * Position) + ((Position - 1) * ySpacing))
	else
		OzCD.Holder:SetSize((Size * Position) + ((Position - 1) * xSpacing), Size)
	end
end

function OzCD:UpdateActiveCooldowns()
	for i = PA:CountTable(OzCD.ActiveCooldowns) + 1, #OzCD.Holder do
		OzCD.Holder[i]:Hide()
	end

	local Position = 0
	for SpellID in pairs(OzCD.ActiveCooldowns) do
		local Name, _, Icon = GetSpellInfo(SpellID)

		if Name then
			Position = Position + 1
			local Frame = OzCD.Holder[Position]
			if (not Frame) then
				Frame = OzCD:CreateCooldown(Position)
			end

			local Start, Duration, CurrentDuration, Charges

			if OzCD.IsChargeCooldown[SpellID] then
				Charges, _, Start, Duration = GetSpellCharges(SpellID)
			else
				Start, Duration = GetSpellCooldown(SpellID)
			end

			CurrentDuration = (Start + Duration - GetTime())

			if Charges and Start == (((2^32)/1000) - Duration) then
				CurrentDuration = 0
			end

			Frame.CurrentDuration = CurrentDuration
			Frame.Duration = Duration
			Frame.SpellID = SpellID
			Frame.SpellName = Name

			Frame.Icon:SetTexture(Icon)

			if (CurrentDuration and CurrentDuration >= COOLDOWN_MIN_DURATION) then
				Frame.Cooldown:SetCooldown(Start, Duration)
				Frame:Show()
			else
				OzCD.ActiveCooldowns[SpellID] = nil
				Frame.CurrentDuration = 0
				Frame:Hide()
			end
		end
	end

	OzCD:SetSize(Position)
end

function OzCD:UpdateDelayedCooldowns()
	local Start, Duration, Enable, CurrentDuration, Charges, _

	for SpellID in pairs(OzCD.DelayCooldowns) do
		Start, Duration, Enable = GetSpellCooldown(SpellID)

		if OzCD.IsChargeCooldown[SpellID] then
			Charges, _, Start, Duration = GetSpellCharges(SpellID)
			if Charges then
				Start, Duration = Start, Duration
			end
		end

		CurrentDuration = (Start + Duration - GetTime())

		if Enable and CurrentDuration then
			if (CurrentDuration < OzCD.db.SuppressDuration) and (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				OzCD.DelayCooldowns[SpellID] = nil
				OzCD.ActiveCooldowns[SpellID] = Duration
			end
		else
			OzCD.DelayCooldowns[SpellID] = nil
		end
	end
end

function OzCD:CreateCooldown(index)
	local Frame = CreateFrame('Button', 'OzCD_'..index, OzCD.Holder)
	Frame:RegisterForClicks('AnyUp')
	Frame:SetSize(OzCD.db.Size, OzCD.db.Size)

	Frame.Cooldown = CreateFrame('Cooldown', '$parentCooldown', Frame, 'CooldownFrameTemplate')
	Frame.Cooldown:SetAllPoints()
	Frame.Cooldown:SetDrawEdge(false)
	Frame.Cooldown:SetReverse(false)
	Frame.Cooldown.CooldownOverride = 'OzCooldowns'

	Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
	Frame.Icon:SetTexCoord(unpack(PA.TexCoords))
	Frame.Icon:SetAllPoints()

	Frame.Stacks = Frame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	Frame.Stacks:SetFont(PA.LSM:Fetch('font', OzCD.db.StackFont), OzCD.db.StackFontSize, OzCD.db.StackFontFlag)
	Frame.Stacks:SetTextColor(1, 1, 1)
	Frame.Stacks:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', 0, 2)

	Frame.StatusBar = CreateFrame('StatusBar', nil, Frame)
	Frame.StatusBar:SetReverseFill(false)
	Frame.StatusBar:SetPoint('TOP', Frame, 'BOTTOM', 0, -1)
	Frame.StatusBar:SetMinMaxValues(0, 1)
	Frame.StatusBar:SetStatusBarTexture(PA.LSM:Fetch('statusbar', OzCD.db.StatusBarTexture))
	Frame.StatusBar:SetStatusBarColor(unpack(OzCD.db.StatusBarTextureColor))
	Frame.StatusBar:SetSize(OzCD.db.Size, 4)
	Frame.StatusBar:SetScript('OnUpdate', function(s)
		if (Frame.CurrentDuration and Frame.CurrentDuration > 0) then
			local Normalized = Frame.CurrentDuration / Frame.Duration
			s:SetValue(Normalized)
			if OzCD.db.StatusBarGradient then
				s:SetStatusBarColor(1 - Normalized, Normalized, 0)
			end
		end
	end)

	if not OzCD.db.StatusBar then Frame.StatusBar:Hide() end

	if PA.Masque and OzCD.db.Masque then
		OzCD.MasqueGroup:AddButton(Frame)
		OzCD.MasqueGroup:ReSkin()
	else
		PA:CreateBackdrop(Frame)
		PA:CreateShadow(Frame.Backdrop)
		PA:CreateBackdrop(Frame.StatusBar, 'Default')
		PA:CreateShadow(Frame.StatusBar.Backdrop)
	end

	if not (PA.ElvUI or PA.Tukui) then
		Frame:RegisterForDrag('LeftButton')
		Frame:SetScript('OnDragStart', function(s) s:GetParent():StartMoving() end)
		Frame:SetScript('OnDragStop', function(s) s:GetParent():StopMovingOrSizing() end)
	end

	Frame:SetScript('OnEnter', function(s)
		if not OzCD.db.Tooltips then return end
		_G.GameTooltip:SetOwner(s, 'ANCHOR_CURSOR')
		_G.GameTooltip:ClearLines()
		_G.GameTooltip:SetSpellByID(s.SpellID)
		_G.GameTooltip:Show()
	end)
	Frame:SetScript('OnLeave', _G.GameTooltip_Hide)
	Frame:SetScript('OnClick', function(s)
		if not OzCD.db.Announce then return end
		local CurrentDuration = s.CurrentDuration
		local TimeRemaining
		if CurrentDuration > 60 then
			TimeRemaining = format('%d m', ceil(CurrentDuration / 60))
		elseif CurrentDuration <= 60 and CurrentDuration > 10 then
			TimeRemaining = format('%d s', CurrentDuration)
		elseif CurrentDuration <= 10 and CurrentDuration > 0 then
			TimeRemaining = format('%.1f s', CurrentDuration)
		end

		SendChatMessage(format(PA.ACL["My %s will be off cooldown in %s"], s.SpellName, TimeRemaining), Channel)
	end)

	Frame:EnableMouse(OzCD.db.Tooltips or OzCD.db.Announce)

	PA:RegisterCooldown(Frame.Cooldown)

	tinsert(OzCD.Holder, Frame)

	OzCD:SetSize()
	OzCD:SetPosition()

	return Frame
end

function OzCD:SetPosition()
	local sizex = OzCD.db.Size + OzCD.db.Spacing + (OzCD.db.Vertical and 0 or 2)
	local sizey = OzCD.db.Size + OzCD.db.Spacing + (OzCD.db.Vertical and OzCD.db.StatusBar and 6 or 0)
	local anchor = 'BOTTOMLEFT'
	local growthx = 1
	local growthy = 1
	local cols = floor(OzCD.Holder:GetWidth() / sizex + 0.5)

	for i, button in ipairs(OzCD.Holder) do
		if (not button) then break end
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, OzCD.Holder, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

function OzCD:UpdateSettings()
	local StatusBarTexture = PA.LSM:Fetch('statusbar', OzCD.db.StatusBarTexture)
	local StackFont = PA.LSM:Fetch('font', OzCD.db.StackFont)

	for _, Frame in ipairs(OzCD.Holder) do
		Frame:SetSize(OzCD.db.Size, OzCD.db.Size)
		Frame:EnableMouse(OzCD.db.Tooltips or OzCD.db.Announce)
		Frame.Stacks:SetFont(StackFont, OzCD.db.StackFontSize, OzCD.db.StackFontFlag)

		if OzCD.db.StatusBar then
			Frame.StatusBar:SetStatusBarTexture(StatusBarTexture)
			Frame.StatusBar:SetStatusBarColor(unpack(OzCD.db.StatusBarTextureColor))
			Frame.StatusBar:SetSize(OzCD.db.Size, 4)
			Frame.StatusBar:Show()
		else
			Frame.StatusBar:Hide()
		end
	end

	OzCD:SetSize()
	OzCD:SetPosition()

	OzCD:CancelAllTimers()
	OzCD:ScheduleRepeatingTimer('UpdateActiveCooldowns', OzCD.db.UpdateSpeed)
	OzCD:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
end

function OzCD:PLAYER_ENTERING_WORLD()
	for SpellID in pairs(OzCD.db.SpellCDs) do
		local Start, Duration, Enable = GetSpellCooldown(SpellID)
		local CurrentDuration = (Start + Duration - GetTime()) or 0

		if Enable and (CurrentDuration > .1) and (CurrentDuration < OzCD.db.IgnoreDuration) then
			if (CurrentDuration >= OzCD.db.SuppressDuration) then
				OzCD.DelayCooldowns[SpellID] = Duration
			elseif (CurrentDuration >= COOLDOWN_MIN_DURATION) then
				OzCD.ActiveCooldowns[SpellID] = Duration
			end
		end
	end

	if OzCD.db.SortByDuration then
		sort(OzCD.ActiveCooldowns)
	end

	OzCD:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function OzCD:GROUP_ROSTER_UPDATE()
	Channel = IsInRaid() and 'RAID' or IsInGroup() and 'PARTY' or 'SAY'
end

function OzCD:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, SpellID)
	if (unit == 'player' or unit == 'pet') and OzCD.db.SpellCDs[SpellID] then
		OzCD.Cooldowns[SpellID] = true
	end
end

function OzCD:SPELL_UPDATE_COOLDOWN()
	local Start, Duration, Enable, Charges, _, ChargeStart, ChargeDuration, CurrentDuration

	for SpellID in pairs(OzCD.Cooldowns) do
		Start, Duration, Enable = GetSpellCooldown(SpellID)

		if OzCD.IsChargeCooldown[SpellID] ~= false then
			Charges, _, ChargeStart, ChargeDuration = GetSpellCharges(SpellID)

			if OzCD.IsChargeCooldown[SpellID] == nil then
				OzCD.IsChargeCooldown[SpellID] = Charges and true or false
			end

			if Charges then
				Start, Duration = ChargeStart, ChargeDuration
			end
		end

		CurrentDuration = (Start + Duration - GetTime())

		if Enable and CurrentDuration and (CurrentDuration < OzCD.db.IgnoreDuration) then
			if (CurrentDuration >= OzCD.db.SuppressDuration) or OzCD.HasCDDelay[SpellID] then
				OzCD.DelayCooldowns[SpellID] = Duration
			elseif (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				OzCD.ActiveCooldowns[SpellID] = Duration
			end
		end

		OzCD.Cooldowns[SpellID] = nil
	end

	if OzCD.db.SortByDuration then
		sort(OzCD.ActiveCooldowns)
	end
end

function OzCD:SPELLS_CHANGED()
	local numPetSpells = _G.HasPetSpells()
	if numPetSpells then
		OzCD:ScanSpellBook(_G.BOOKTYPE_PET, numPetSpells)

		PA:AddKeysToTable(OzCD.db.SpellCDs, OzCD.SpellList)

		PA.Options.args.OzCooldowns.args.General.args.Spells.args = OzCD:GenerateSpellOptions()
	end
end

function OzCD:GenerateSpellOptions()
	local SpellOptions = {}

	for SpellID, SpellName in pairs(OzCD.db.SpellCDs) do
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

function OzCD:GetOptions()
	OzCD:UpdateSettings()

	local OzCooldowns = PA.ACH:Group(OzCD.Title, OzCD.Description, nil, nil, function(info) return OzCD.db[info[#info]] end, function(info, value) OzCD.db[info[#info]] = value end)
	PA.Options.args.OzCooldowns = OzCooldowns

	OzCooldowns.args.Description = PA.ACH:Description(OzCD.Description, 0)
	OzCooldowns.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) OzCD.db[info[#info]] = value if (not OzCD.isEnabled) then OzCD:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	OzCooldowns.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	OzCooldowns.args.General.inline = true

	OzCooldowns.args.General.args.Masque = PA.ACH:Toggle(PA.ACL['Masque Support'], nil, 1)
	OzCooldowns.args.General.args.SortByDuration = PA.ACH:Toggle(PA.ACL['Sort by Current Duration'], nil, 2)
	OzCooldowns.args.General.args.SuppressDuration = PA.ACH:Range(PA.ACL['Suppress Duration Threshold'], PA.ACL['Duration in Seconds'], 3, { min = 2, max = 600, step = 1 })
	OzCooldowns.args.General.args.IgnoreDuration = PA.ACH:Range(PA.ACL['Ignore Duration Threshold'], PA.ACL['Duration in Seconds'], 4, { min = 2, max = 600, step = 1 })
	OzCooldowns.args.General.args.UpdateSpeed = PA.ACH:Range(PA.ACL['Update Speed'], nil, 5, { min = .1, max = .5, step = .1 })

	OzCooldowns.args.General.args.Icons = PA.ACH:Group(PA.ACL['Icons'], nil, 5)
	OzCooldowns.args.General.args.Icons.inline = true

	OzCooldowns.args.General.args.Icons.args.Vertical = PA.ACH:Toggle(PA.ACL['Vertical'], nil, 1)
	OzCooldowns.args.General.args.Icons.args.Tooltips = PA.ACH:Toggle(PA.ACL['Tooltips'], nil, 2)
	OzCooldowns.args.General.args.Icons.args.Announce = PA.ACH:Toggle(PA.ACL['Announce on Click'], nil, 3)
	OzCooldowns.args.General.args.Icons.args.Size = PA.ACH:Range(PA.ACL['Size'], nil, 4, { min = 24, max = 60, step = 1 })
	OzCooldowns.args.General.args.Icons.args.Spacing = PA.ACH:Range(PA.ACL['Spacing'], nil, 5, { min = 0, max = 20, step = 1 })

	OzCooldowns.args.General.args.Icons.args.StackFont = PA.ACH:SharedMediaFont(PA.ACL['Stacks/Charges Font'], nil, 7)
	OzCooldowns.args.General.args.Icons.args.StackFontSize = PA.ACH:Range(PA.ACL['Stacks/Charges Font Size'], nil, 5, { min = 8, max = 20, step = 1 })
	OzCooldowns.args.General.args.Icons.args.StackFontFlag = PA.ACH:FontFlags(PA.ACL['Stacks/Charges Font Flag'], nil, 9)

	OzCooldowns.args.General.args.StatusBars = PA.ACH:Group(PA.ACL['Status Bar'], nil, 7, nil, nil, nil, function() return not OzCD.db.StatusBar end)
	OzCooldowns.args.General.args.StatusBars.inline = true
	OzCooldowns.args.General.args.StatusBars.args.StatusBar = PA.ACH:Toggle(PA.ACL['Enabled'], nil, 1, nil, nil, nil, nil, nil, false)
	OzCooldowns.args.General.args.StatusBars.args.StatusBarTexture = PA.ACH:SharedMediaStatusbar(PA.ACL['Texture'], nil, 2)
	OzCooldowns.args.General.args.StatusBars.args.StatusBarGradient = PA.ACH:Toggle(PA.ACL['Gradient'], nil, 3)
	OzCooldowns.args.General.args.StatusBars.args.StatusBarTextureColor = PA.ACH:Color(PA.ACL['Texture Color'], nil, 4, nil, nil, function(info) return unpack(OzCD.db[info[#info]]) end, function(info, r, g, b, a) OzCD.db[info[#info]] = { r, g, b, a } OzCD:UpdateSettings() end, function() return not OzCD.db.StatusBar or OzCD.db.StatusBarGradient end)

	OzCooldowns.args.General.args.Spells = PA.ACH:Group(_G.SPELLS, nil, 8, nil, function(info) return OzCD.db.SpellCDs[tonumber(info[#info])] end, function(info, value) OzCD.db.SpellCDs[tonumber(info[#info])] = value end)
	OzCooldowns.args.General.args.Spells.inline = true
	OzCooldowns.args.General.args.Spells.args = OzCD:GenerateSpellOptions()

	OzCooldowns.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	OzCooldowns.args.Authors = PA.ACH:Description(OzCD.Authors, -1, 'large')
end

function OzCD:BuildProfile()
	-- Scan SpellBook
	for tab = 1, _G.GetNumSpellTabs(), 1 do
		local name, _, offset, numSpells = _G.GetSpellTabInfo(tab)
		if name then
			OzCD:ScanSpellBook(_G.BOOKTYPE_SPELL, numSpells, offset)
		end
	end

	local numPetSpells = _G.HasPetSpells()
	if numPetSpells then
		OzCD:ScanSpellBook(_G.BOOKTYPE_PET, numPetSpells)
	end

	PA.ScanTooltip:Hide()

	PA.Defaults.profile.OzCooldowns = {
		Enable = true,
		Announce = true,
		DurationText = true,
		Masque = false,
		SuppressDuration = 60,
		IgnoreDuration = 300,
		Size = 36,
		SortByDuration = true,
		Spacing = 4,
		SpellCDs = OzCD.SpellList,
		StackFont = 'Arial Narrow',
		StackFontFlag = 'OUTLINE',
		StackFontSize = 12,
		StatusBar = true,
		StatusBarTexture = 'Blizzard Raid Bar',
		StatusBarTextureColor = { .24, .54, .78 },
		StatusBarGradient = false,
		Tooltips = true,
		Vertical = false,
		UpdateSpeed = .1,
		Cooldown = CopyTable(PA.Defaults.profile.Cooldown),
	}
end

function OzCD:UpdateSettings()
	OzCD.db = PA.db.OzCooldowns
end

function OzCD:Initialize()
	OzCD:UpdateSettings()

	if OzCD.db.Enable ~= true then
		return
	end

	OzCD.isEnabled = true

	if PA.Masque and OzCD.db.Masque then
		PA.Masque:Register('OzCooldowns', function() end)
		OzCD.MasqueGroup = PA.Masque:Group('OzCooldowns')
	end

	if PA.Tukui then
		_G.Tukui[1].Movers:RegisterFrame(OzCD.Holder)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(OzCD.Holder, 'OzCooldownsMover', 'OzCooldowns Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,OzCooldowns')
	else
		OzCD.Holder:SetScript('OnDragStart', OzCD.Holder.StartMoving)
		OzCD.Holder:SetScript('OnDragStop', OzCD.Holder.StopMovingOrSizing)
	end

	OzCD:GROUP_ROSTER_UPDATE()

	if PA.Retail then
		OzCD:RegisterEvent('PLAYER_ENTERING_WORLD') -- Check for Active Cooldowns Login / Reload.
	end

	OzCD:RegisterEvent('GROUP_ROSTER_UPDATE') -- Channel Distribution
	OzCD:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED') -- For Cooldown Queue
	OzCD:RegisterEvent('SPELL_UPDATE_COOLDOWN')	-- Process Cooldown Queue
	OzCD:RegisterEvent('SPELLS_CHANGED') -- Process Pet Changes

	OzCD:ScheduleRepeatingTimer('UpdateActiveCooldowns', OzCD.db.UpdateSpeed)
	OzCD:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
end
