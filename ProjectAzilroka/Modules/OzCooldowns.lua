local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local OzCD = PA:NewModule('OzCooldowns', 'AceEvent-3.0', 'AceTimer-3.0')
local LSM = PA.Libs.LSM
_G.OzCooldowns, PA.OzCD = OzCD, OzCD

OzCD.Title, OzCD.Description, OzCD.Authors, OzCD.isEnabled = 'OzCooldowns', ACL['Minimalistic Cooldowns'], 'Azilroka    Nimaear', false

local next, sort, unpack, tinsert, format, tonumber, floor = next, sort, unpack, tinsert, format, tonumber, floor

local GetTime, IsInRaid, IsInGroup, SendChatMessage = GetTime, IsInRaid, IsInGroup, SendChatMessage
local UIParent, CreateFrame, CopyTable = UIParent, CreateFrame, CopyTable

OzCD.Holder = CreateFrame('Frame', 'OzCooldownsHolder', PA.PetBattleFrameHider)
OzCD.Holder:SetSize(40, 40)
OzCD.Holder:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 360)
OzCD.Holder:SetMovable(not (PA.Tukui or PA.ElvUI))
OzCD.Holder.Buttons = {}

OzCD.Cooldowns, OzCD.ActiveCooldowns, OzCD.DelayCooldowns, OzCD.HasCDDelay = {}, {}, {}, { [5384] = true }

local GLOBAL_COOLDOWN_TIME, COOLDOWN_MIN_DURATION, Channel = 1.5, .1

function OzCD:SetSize(Position)
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
		local currentDuration = PA:GetCooldownInfo(SpellID)

		if (currentDuration > .1) and (currentDuration < OzCD.db.IgnoreDuration) then
			if (currentDuration >= OzCD.db.SuppressDuration) then
				OzCD.DelayCooldowns[SpellID] = currentDuration
			elseif (currentDuration >= COOLDOWN_MIN_DURATION) then
				OzCD.ActiveCooldowns[SpellID] = currentDuration
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
		local CurrentDuration, _, Duration = PA:GetCooldownInfo(SpellID)

		if CurrentDuration and (CurrentDuration < OzCD.db.IgnoreDuration) then
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
	local Position = 1
	for SpellID in next, OzCD.ActiveCooldowns do
		local spellData = PA.SpellBook.Complete[SpellID]

		if spellData.name then
			local Frame, CurrentDuration, Start, Duration = OzCD:GetCooldownFrame(Position), PA:GetCooldownInfo(SpellID)
			Position = Position + 1

			Frame.CurrentDuration = CurrentDuration
			Frame.Duration = Duration
			Frame.SpellID = SpellID
			Frame.SpellName = spellData.name

			OzCD.ActiveCooldowns[SpellID] = CurrentDuration -- Sync Time

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

	for i = Position, #OzCD.Holder.Buttons do
		OzCD.Holder.Buttons[i]:Hide()
	end

	OzCD:SetSize(Position)
end

function OzCD:UpdateDelayedCooldowns()
	for SpellID in next, OzCD.DelayCooldowns do
		local CurrentDuration, Start, Duration = PA:GetCooldownInfo(SpellID)

		if (CurrentDuration < OzCD.db.SuppressDuration) and (CurrentDuration > GLOBAL_COOLDOWN_TIME) then
			OzCD.DelayCooldowns[SpellID], OzCD.ActiveCooldowns[SpellID] = nil, Duration
		elseif CurrentDuration == 0 then
			OzCD.DelayCooldowns[SpellID] = nil
		end
	end
end

function OzCD:GetCooldownFrame(index)
	local Frame = OzCD.Holder.Buttons[index]
	if not Frame then
		Frame = CreateFrame('Button', 'OzCD_'..index, OzCD.Holder, 'PA_AuraTemplate')
		Frame:SetSize(OzCD.db.Size, OzCD.db.Size)

		Frame.Icon:SetTexCoord(PA:TexCoords())

		Frame.Cooldown:SetDrawEdge(false)
		Frame.Cooldown.CooldownOverride = 'OzCooldowns'

		Frame.Count:SetFont(LSM:Fetch('font', OzCD.db.StackFont), OzCD.db.StackFontSize, OzCD.db.StackFontFlag)
		Frame.Count:SetTextColor(1, 1, 1)

		Frame.StatusBar:SetShown(OzCD.db.StatusBar)
		Frame.StatusBar:SetMinMaxValues(0, 1)
		Frame.StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', OzCD.db.StatusBarTexture))
		Frame.StatusBar:SetStatusBarColor(unpack(OzCD.db.StatusBarTextureColor))
		Frame.StatusBar:SetSize(OzCD.db.Size - 2, 4)
		Frame.StatusBar:SetScript('OnUpdate', function(s, elapsed)
			s.elapsed = (s.elapsed or 0) + elapsed
			if s.elapsed > .1 and (Frame.CurrentDuration and Frame.CurrentDuration > 0) then
				local normalized = PA:Clamp(Frame.CurrentDuration / Frame.Duration)
				s:SetValue(normalized)
				if OzCD.db.StatusBarGradient then
					s:SetStatusBarColor(1 - normalized, normalized, 0)
				end

				s.elapsed = 0
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
			local timervalue, formatid, _, remainder = PA:GetTimeInfo(s.CurrentDuration, OzCD.db.Cooldown.threshold, OzCD.db.Cooldown.hhmmThreshold, OzCD.db.Cooldown.mmssThreshold)
			local which = (OzCD.db.Cooldown.textColors and 2 or 1) + (OzCD.db.Cooldown.showSeconds and 0 or 2)
			SendChatMessage(format(ACL["My %s will be off cooldown in %s"], s.SpellName, format(PA.TimeFormats[formatid][which], timervalue, remainder)), Channel)
		end)

		Frame:EnableMouse(OzCD.db.Tooltips or OzCD.db.Announce)
		PA:RegisterCooldown(Frame.Cooldown)

		tinsert(OzCD.Holder.Buttons, Frame)

		OzCD:SetPosition()
	end

	return Frame
end

function OzCD:SetPosition()
	local anchor, growthx, growthy, sizex, sizey = 'BOTTOMLEFT', 1, 1, OzCD.db.Size + OzCD.db.Spacing + (OzCD.db.Vertical and 0 or 2), OzCD.db.Size + OzCD.db.Spacing + (OzCD.db.Vertical and OzCD.db.StatusBar and 6 or 0)
	local cols = floor(OzCD.Holder:GetWidth() / sizex + 0.5)

	for i, button in next, OzCD.Holder.Buttons do
		if (not button) then break end
		local col, row = (i - 1) % cols, floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, OzCD.Holder, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

function OzCD:UpdateSettings()
	local StatusBarTexture = LSM:Fetch('statusbar', OzCD.db.StatusBarTexture)
	local StackFont = LSM:Fetch('font', OzCD.db.StackFont)

	for _, Frame in next, OzCD.Holder.Buttons do
		Frame:SetSize(OzCD.db.Size, OzCD.db.Size)
		Frame:EnableMouse(OzCD.db.Tooltips or OzCD.db.Announce)
		Frame.Count:SetFont(StackFont, OzCD.db.StackFontSize, OzCD.db.StackFontFlag)

		Frame.StatusBar:SetShown(OzCD.db.StatusBar)
		Frame.StatusBar:SetStatusBarTexture(StatusBarTexture)
		Frame.StatusBar:SetStatusBarColor(unpack(OzCD.db.StatusBarTextureColor))
		Frame.StatusBar:SetSize(OzCD.db.Size, 4)
	end

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
	PA.Options.args.OzCooldowns.args.General.args.Spells.args = PA:GenerateSpellOptions(OzCD.db.SpellCDs)
end

function OzCD:GetOptions()
	local OzCooldowns = ACH:Group(OzCD.Title, OzCD.Description, nil, nil, function(info) return OzCD.db[info[#info]] end, function(info, value) OzCD.db[info[#info]] = value end)
	PA.Options.args.OzCooldowns = OzCooldowns

	OzCooldowns.args.Description = ACH:Description(OzCD.Description, 0)
	OzCooldowns.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) OzCD.db[info[#info]] = value if (not OzCD.isEnabled) then OzCD:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	OzCooldowns.args.General = ACH:Group(ACL['General'], nil, 2)
	OzCooldowns.args.General.inline = true

	OzCooldowns.args.General.args.Masque = ACH:Toggle(ACL['Masque Support'], nil, 1)
	OzCooldowns.args.General.args.SortByDuration = ACH:Toggle(ACL['Sort by Current Duration'], nil, 2)
	OzCooldowns.args.General.args.SuppressDuration = ACH:Range(ACL['Suppress Duration Threshold'], ACL['Duration in Seconds'], 3, { min = 2, max = 600, step = 1 })
	OzCooldowns.args.General.args.IgnoreDuration = ACH:Range(ACL['Ignore Duration Threshold'], ACL['Duration in Seconds'], 4, { min = 2, max = 600, step = 1 })
	OzCooldowns.args.General.args.UpdateSpeed = ACH:Range(ACL['Update Speed'], nil, 5, { min = .1, max = .5, step = .1 })

	OzCooldowns.args.General.args.Icons = ACH:Group(ACL['Icons'], nil, 5)
	OzCooldowns.args.General.args.Icons.inline = true

	OzCooldowns.args.General.args.Icons.args.Vertical = ACH:Toggle(ACL['Vertical'], nil, 1)
	OzCooldowns.args.General.args.Icons.args.Tooltips = ACH:Toggle(ACL['Tooltips'], nil, 2)
	OzCooldowns.args.General.args.Icons.args.Announce = ACH:Toggle(ACL['Announce on Click'], nil, 3)
	OzCooldowns.args.General.args.Icons.args.Size = ACH:Range(ACL['Size'], nil, 4, { min = 24, max = 60, step = 1 })
	OzCooldowns.args.General.args.Icons.args.Spacing = ACH:Range(ACL['Spacing'], nil, 5, { min = 0, max = 20, step = 1 })

	OzCooldowns.args.General.args.Icons.args.StackFont = ACH:SharedMediaFont(ACL['Stacks/Charges Font'], nil, 7)
	OzCooldowns.args.General.args.Icons.args.StackFontSize = ACH:Range(ACL['Stacks/Charges Font Size'], nil, 5, { min = 8, max = 20, step = 1 })
	OzCooldowns.args.General.args.Icons.args.StackFontFlag = ACH:FontFlags(ACL['Stacks/Charges Font Flag'], nil, 9)

	OzCooldowns.args.General.args.StatusBars = ACH:Group(ACL['Status Bar'], nil, 7, nil, nil, nil, function() return not OzCD.db.StatusBar end)
	OzCooldowns.args.General.args.StatusBars.inline = true
	OzCooldowns.args.General.args.StatusBars.args.StatusBar = ACH:Toggle(ACL['Enabled'], nil, 1, nil, nil, nil, nil, nil, false)
	OzCooldowns.args.General.args.StatusBars.args.StatusBarTexture = ACH:SharedMediaStatusbar(ACL['Texture'], nil, 2)
	OzCooldowns.args.General.args.StatusBars.args.StatusBarGradient = ACH:Toggle(ACL['Gradient'], nil, 3)
	OzCooldowns.args.General.args.StatusBars.args.StatusBarTextureColor = ACH:Color(ACL['Texture Color'], nil, 4, nil, nil, function(info) return unpack(OzCD.db[info[#info]]) end, function(info, r, g, b, a) OzCD.db[info[#info]] = { r, g, b, a } OzCD:UpdateSettings() end, function() return not OzCD.db.StatusBar or OzCD.db.StatusBarGradient end)

	OzCooldowns.args.General.args.Spells = ACH:Group(_G.SPELLS, nil, 8, nil, function(info) return OzCD.db.SpellCDs[tonumber(info[#info])] end, function(info, value) OzCD.db.SpellCDs[tonumber(info[#info])] = value end)
	OzCooldowns.args.General.args.Spells.inline = true
	OzCooldowns.args.General.args.Spells.args = PA:GenerateSpellOptions(OzCD.db.SpellCDs)

	OzCooldowns.args.AuthorHeader = ACH:Header(ACL['Authors:'], -2)
	OzCooldowns.args.Authors = ACH:Description(OzCD.Authors, -1, 'large')
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
		OzCD.Holder:RegisterForDrag('LeftButton')
		OzCD.Holder:SetScript('OnDragStart', OzCD.Holder.StartMoving)
		OzCD.Holder:SetScript('OnDragStop', OzCD.Holder.StopMovingOrSizing)
	end

	OzCD:GROUP_ROSTER_UPDATE()

	OzCD:RegisterEvent('PLAYER_ENTERING_WORLD') -- Check for Active Cooldowns Login / Reload.
	OzCD:RegisterEvent('GROUP_ROSTER_UPDATE') -- Channel Distribution
	OzCD:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED') -- For Cooldown Queue
	OzCD:RegisterEvent('SPELL_UPDATE_COOLDOWN')	-- Process Cooldown Queue

	OzCD:ScheduleRepeatingTimer('UpdateActiveCooldowns', OzCD.db.UpdateSpeed)
	OzCD:ScheduleRepeatingTimer('UpdateDelayedCooldowns', .5)
end
