local PA = _G.ProjectAzilroka
local OzCD = PA:NewModule('OzCooldowns', 'AceEvent-3.0', 'AceTimer-3.0')
PA.OzCD = OzCD

OzCD.Title = 'OzCooldowns'
OzCD.Header = '|cFF16C3F2Oz|r|cFFFFFFFFCooldowns|r'
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
	Frame:EnableMouse(OzCD.db.Tooltips or OzCD.db.Announce)
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
			if (CurrentDuration >= OzCD.db.SuppressDuration) then
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

		OzCD.db.SpellCDs = OzCD.SpellList

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
	OzCD.db = PA.db.OzCooldowns

	PA.Options.args.OzCooldowns = {
		type = 'group',
		name = OzCD.Title,
		desc = OzCD.Description,
		get = function(info) return OzCD.db[info[#info]] end,
		set = function(info, value) OzCD.db[info[#info]] = value OzCD:UpdateSettings() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = OzCD.Header,
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					OzCD.db[info[#info]] = value
					if (not OzCD.isEnabled) then
						OzCD:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				args = {
					Masque = {
						order = 0,
						type = 'toggle',
						name = PA.ACL['Masque Support'],
					},
					SortByDuration = {
						order = 1,
						type = 'toggle',
						name = PA.ACL['Sort by Current Duration'],
					},
					SuppressDuration = {
						order = 2,
						type = 'range',
						name = PA.ACL['Suppress Duration Threshold'],
						desc = PA.ACL['Duration in Seconds'],
						min = 2, max = 600, step = 1,
					},
					IgnoreDuration = {
						order = 3,
						type = 'range',
						name = PA.ACL['Ignore Duration Threshold'],
						desc = PA.ACL['Duration in Seconds'],
						min = 2, max = 600, step = 1,
					},
					UpdateSpeed = {
						order = 5,
						type = 'range',
						name = PA.ACL['Update Speed'],
						min = .1, max = .5, step = .1,
					},
					Icons = {
						order = 6,
						type = 'group',
						guiInline = true,
						name = PA.ACL['Icons'],
						args = {
							Vertical = {
								order = 1,
								type = 'toggle',
								name = PA.ACL['Vertical'],
							},
							Tooltips = {
								order = 2,
								type = 'toggle',
								name = PA.ACL['Tooltips'],
							},
							Announce = {
								order = 3,
								type = 'toggle',
								name = PA.ACL['Announce on Click'],
							},
							Size = {
								order = 4,
								type = 'range',
								name = PA.ACL['Size'],
								min = 24, max = 60, step = 1,
							},
							Spacing = {
								order = 5,
								type = 'range',
								name = PA.ACL['Spacing'],
								min = 0, max = 20, step = 1,
							},
							StackFont = {
								type = 'select',
								dialogControl = 'LSM30_Font',
								order = 7,
								name = PA.ACL['Stacks/Charges Font'],
								values = PA.LSM:HashTable('font'),
							},
							StackFontSize = {
								type = 'range',
								order = 8,
								name = PA.ACL['Stacks/Charges Font Size'],
								min = 8, max = 18, step = 1,
							},
							StackFontFlag = {
								name = PA.ACL['Stacks/Charges Font Flag'],
								order = 9,
								type = 'select',
								values = PA.FontFlags,
							},
						},
					},
					StatusBars = {
						order = 7,
						type = 'group',
						guiInline = true,
						name = PA.ACL['Status Bar'],
						disabled = function() return not OzCD.db.StatusBar end,
						args = {
							StatusBar = {
								order = 1,
								type = 'toggle',
								name = PA.ACL['Enabled'],
								disabled = false,
							},
							StatusBarTexture = {
								type = 'select',
								dialogControl = 'LSM30_Statusbar',
								order = 2,
								name = PA.ACL['Texture'],
								values = PA.LSM:HashTable('statusbar'),
							},
							StatusBarGradient = {
								order = 3,
								type = 'toggle',
								name = PA.ACL['Gradient'],
							},
							StatusBarTextureColor = {
								type = 'color',
								order = 4,
								name = PA.ACL['Texture Color'],
								hasAlpha = false,
								get = function(info) return unpack(OzCD.db[info[#info]]) end,
								set = function(info, r, g, b, a) OzCD.db[info[#info]] = { r, g, b, a } OzCD:UpdateSettings() end,
								disabled = function() return not OzCD.db.StatusBar or OzCD.db.StatusBarGradient end,
							},
						},
					},
					Spells = {
						order = 8,
						type = 'group',
						name = _G.SPELLS,
						guiInline = true,
						args = OzCD:GenerateSpellOptions(),
						get = function(info) return OzCD.db.SpellCDs[tonumber(info[#info])] end,
						set = function(info, value)	OzCD.db.SpellCDs[tonumber(info[#info])] = value end,
					},
				},
			},
			AuthorHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -1,
				type = 'description',
				name = OzCD.Authors,
				fontSize = 'large',
			},
		},
	}
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
		cooldown = CopyTable(PA.Defaults.profile.cooldown),
	}
end

function OzCD:UpdateSettings()
	OzCD.db = PA.db.OzCooldowns
end

function OzCD:Initialize()
	OzCD.db = PA.db.OzCooldowns

	if OzCD.db.Enable ~= true then
		return
	end

	OzCD.isEnabled = true

	if PA.Masque and OzCD.db.Masque then
		PA.Masque:Register('OzCooldowns', function() end)
		OzCD.MasqueGroup = PA.Masque:Group('OzCooldowns')
	end

	local Holder = CreateFrame('Frame', 'OzCooldownsHolder', PA.PetBattleFrameHider)
	Holder:SetSize(40, 40)
	Holder:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 360)

	if PA.Tukui then
		_G.Tukui[1].Movers:RegisterFrame(Holder)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(Holder, 'OzCooldownsMover', 'OzCooldowns Anchor', nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,OzCooldowns')
	else
		Holder:SetMovable(true)
		Holder:SetScript('OnDragStart', Holder.StartMoving)
		Holder:SetScript('OnDragStop', Holder.StopMovingOrSizing)
	end

	OzCD.Holder = Holder

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
