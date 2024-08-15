local PA = _G.ProjectAzilroka
local OzCD = PA:NewModule('OzCooldowns', 'AceEvent-3.0', 'AceTimer-3.0')
PA.OzCD = OzCD

OzCD.Title = PA.ACL['|cFF16C3F2Oz|r|cFFFFFFFFCooldowns|r']
OzCD.Description = PA.ACL['Minimalistic Cooldowns']
OzCD.Authors = 'Azilroka    Nimaear'
OzCD.isEnabled = false

_G.OzCooldowns = OzCD

local next, ipairs = next, ipairs
local format, tostring, tonumber = format, tostring, tonumber
local ceil, floor = ceil, floor
local sort, unpack, tinsert = sort, unpack, tinsert

local GetTime = GetTime
local GetSpellInfo = PA.GetSpellInfo
local GetSpellCooldown = PA.GetSpellCooldown
local GetSpellCharges = PA.GetSpellCharges
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local SendChatMessage = SendChatMessage

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

local GLOBAL_COOLDOWN_TIME = 1.5
local COOLDOWN_MIN_DURATION = .1
local SpellOptions = {}

OzCD.HasCDDelay = {
	[5384] = true
}

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

function OzCD:PLAYER_ENTERING_WORLD()
	for SpellID in next, OzCD.db.SpellCDs do
		local cooldownInfo = GetSpellCooldown(SpellID)
		local currentDuration = (cooldownInfo.startTime + cooldownInfo.duration - GetTime()) or 0

		if cooldownInfo.isEnabled and (currentDuration > .1) and (currentDuration < OzCD.db.IgnoreDuration) then
			if (currentDuration >= OzCD.db.SuppressDuration) then
				OzCD.DelayCooldowns[SpellID] = Duration
			elseif (currentDuration >= COOLDOWN_MIN_DURATION) then
				OzCD.ActiveCooldowns[SpellID] = Duration
			end
		end
	end

	if OzCD.db.SortByDuration then
		sort(OzCD.ActiveCooldowns)
	end

	OzCD:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function OzCD:SPELL_UPDATE_COOLDOWN()
	for SpellID in next, OzCD.Cooldowns do
		local cooldownInfo, chargeInfo = GetSpellCooldown(SpellID), GetSpellCharges(SpellID)
		local Start, Duration = cooldownInfo.startTime, cooldownInfo.duration

		if chargeInfo and ( chargeInfo.currentCharges and chargeInfo.maxCharges > 1 and chargeInfo.currentCharges < chargeInfo.maxCharges ) then
			Start, Duration = chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration
		end

		local CurrentDuration = (Start + Duration - GetTime())

		if cooldownInfo.isEnabled and CurrentDuration and (CurrentDuration < OzCD.db.IgnoreDuration) then
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

function OzCD:UpdateActiveCooldowns()
	for i = PA:CountTable(OzCD.ActiveCooldowns) + 1, #OzCD.Holder do
		OzCD.Holder[i]:Hide()
	end

	local Position = 0
	for SpellID in next, OzCD.ActiveCooldowns do
		local spellData, cooldownInfo, chargeInfo = PA.SpellBook.Complete[SpellID]

		if spellData.name then
			Position = Position + 1
			local Frame, Start, Duration, Charges = OzCD:GetCooldown(Position)

			do
				cooldownInfo, chargeInfo = GetSpellCooldown(SpellID), GetSpellCharges(SpellID)

				if chargeInfo and (chargeInfo.currentCharges and chargeInfo.maxCharges > 1 and chargeInfo.currentCharges < chargeInfo.maxCharges) then
					Start, Duration = chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration
				else
					Start, Duration = cooldownInfo.startTime, cooldownInfo.duration
				end
			end

			local CurrentDuration = (Start + Duration - GetTime())

			Frame.CurrentDuration = CurrentDuration
			Frame.Duration = Duration
			Frame.SpellID = SpellID
			Frame.SpellName = spellData.name

			Frame.Icon:SetTexture(spellData.iconID)

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
	for SpellID in next, OzCD.DelayCooldowns do
		local spellData, cooldownInfo, chargeInfo, Start, Duration = PA.SpellBook.Complete[SpellID]

		do
			cooldownInfo, chargeInfo = GetSpellCooldown(SpellID), GetSpellCharges(SpellID)

			if chargeInfo and (chargeInfo.currentCharges and chargeInfo.maxCharges > 1 and chargeInfo.currentCharges < chargeInfo.maxCharges) then
				Start, Duration = chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration
			else
				Start, Duration = cooldownInfo.startTime, cooldownInfo.duration
			end
		end

		local CurrentDuration = (Start + Duration - GetTime())

		if cooldownInfo.isEnabled and CurrentDuration then
			if (CurrentDuration < OzCD.db.SuppressDuration) and (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
				OzCD.DelayCooldowns[SpellID] = nil
				OzCD.ActiveCooldowns[SpellID] = Duration
			end
		else
			OzCD.DelayCooldowns[SpellID] = nil
		end
	end
end

function OzCD:GetCooldown(index)
	local Frame = OzCD.Holder[index]
	if not Frame then
		Frame = CreateFrame('Button', 'OzCD_'..index, OzCD.Holder, 'PA_AuraTemplate')
		Frame:SetSize(OzCD.db.Size, OzCD.db.Size)

		Frame.Icon:SetTexCoord(unpack(PA.TexCoords))

		Frame.Cooldown:SetDrawEdge(false)
		Frame.Cooldown.CooldownOverride = 'OzCooldowns'

		Frame.Count:SetFont(PA.LSM:Fetch('font', OzCD.db.StackFont), OzCD.db.StackFontSize, OzCD.db.StackFontFlag)
		Frame.Count:SetTextColor(1, 1, 1)

		Frame.StatusBar:SetShown(OzCD.db.StatusBar)
		Frame.StatusBar:SetMinMaxValues(0, 1)
		Frame.StatusBar:SetStatusBarTexture(PA.LSM:Fetch('statusbar', OzCD.db.StatusBarTexture))
		Frame.StatusBar:SetStatusBarColor(unpack(OzCD.db.StatusBarTextureColor))
		Frame.StatusBar:SetSize(OzCD.db.Size - 2, 4)
		Frame.StatusBar:SetScript('OnUpdate', function(s)
			if (Frame.CurrentDuration and Frame.CurrentDuration > 0) then
				local normalized = Frame.CurrentDuration / Frame.Duration
				if normalized == 0 then
					normalized = 0
				elseif normalized == 1 then
					normalized = 1
				end
				s:SetValue(normalized)
				if OzCD.db.StatusBarGradient then
					s:SetStatusBarColor(1 - normalized, normalized, 0)
				end
			end
		end)

		if PA.Masque and OzCD.db.Masque then
			OzCD.MasqueGroup:AddButton(Frame)
			OzCD.MasqueGroup:ReSkin()
		else
			PA:SetTemplate(Frame)
			PA:CreateShadow(Frame)
			PA:CreateBackdrop(Frame.StatusBar)
			PA:CreateShadow(Frame.StatusBar.backdrop)
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
	end

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
		Frame.Count:SetFont(StackFont, OzCD.db.StackFontSize, OzCD.db.StackFontFlag)

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

function OzCD:GROUP_ROSTER_UPDATE()
	Channel = IsInRaid() and 'RAID' or IsInGroup() and 'PARTY' or 'SAY'
end

function OzCD:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, SpellID)
	if (unit == 'player' or unit == 'pet') and OzCD.db.SpellCDs[SpellID] then
		OzCD.Cooldowns[SpellID] = true
	end
end

function OzCD:SPELLS_CHANGED()
 	PA:AddKeysToTable(OzCD.db.SpellCDs, PA.SpellBook.Spells)
	PA.Options.args.OzCooldowns.args.General.args.Spells.args = OzCD:GenerateSpellOptions()
end

function OzCD:GenerateSpellOptions()
	for SpellID, SpellName in next, OzCD.db.SpellCDs do
		local spellData = PA.SpellBook.Complete[SpellID]
		local tblID = tostring(SpellID)

		if spellData.name and not SpellOptions[tblID] then
			SpellOptions[tblID] = {
				type = 'toggle',
				image = spellData.iconID,
				imageCoords = PA.TexCoords,
				name = ' '..spellData.name,
				desc = 'Spell ID: '..SpellID,
			}
		end
	end

	return SpellOptions
end

function OzCD:GetOptions()
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
		SpellCDs = PA.SpellBook.Spells,
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
	PA:AddKeysToTable(OzCD.db.SpellCDs, PA.SpellBook.Spells)
end

function OzCD:Initialize()
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

	OzCD:ScheduleRepeatingTimer('UpdateActiveCooldowns', OzCD.db.UpdateSpeed)
	OzCD:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
end
