local PA = _G.ProjectAzilroka
local OzCooldowns = PA:NewModule('OzCooldowns', 'AceEvent-3.0', 'AceTimer-3.0')
PA.OzCooldowns = OzCooldowns

OzCooldowns.Title = '|cFF16C3F2Oz|r|cFFFFFFFFCooldowns|r'
OzCooldowns.Description = 'OzCooldowns'
OzCooldowns.Authors = 'Azilroka    Nimaear'

_G.OzCooldowns = OzCooldowns

local AS, ES

local pairs = pairs
local format = format
local ceil = ceil
local wipe = wipe
local sort = sort
local select = select
local floor = floor
local unpack = unpack
local tinsert = tinsert
local tostring = tostring
local tonumber = tonumber
local hooksecurefunc = hooksecurefunc

local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellCharges = GetSpellCharges
local IsSpellKnown = IsSpellKnown
local DoesSpellExist = DoesSpellExist

local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local SendChatMessage = SendChatMessage

local CopyTable = CopyTable
local CreateFrame = CreateFrame
local UIParent = UIParent

local Threshold, TimeFormats, TimeColors, RegisteredCooldowns = 10, { [1] = '%d', [2] = '%.1f' }, {}, {}

local Cooldowns = {}
local CooldownFrames = {}

local function GetColor(Color, Alpha)
	if type(Color) == "table" then
		return Color[1] or 1, Color[2] or 1, Color[3] or 1, Alpha or Color[4] or 1
	else
		return 1, 1, 1, Alpha or 1
	end
end

local function GetTexCoords(Coords)
	if type(Coords) == "table" then
		return Coords[1] or 0, Coords[2] or 1, Coords[3] or 0, Coords[4] or 1
	else
		return 0, 1, 0, 1
	end
end

function OzCooldowns:FindCooldown(SpellID)
	for _, Frame in pairs(Cooldowns) do
		if SpellID == Frame['SpellID'] then
			if self.db["Mode"] == "HIDE" then
				OzCooldowns:DelayedEnableCooldown(Frame)
			else
				OzCooldowns:EnableCooldown(Frame)
			end
			break
		end
	end
end

function OzCooldowns:DelayedEnableCooldown(Frame)
	Frame:SetParent(self.Delay)

	Frame:Show()
	Frame:SetScript("OnUpdate", function(s)
		local Start, Duration, Enable = GetSpellCooldown(s.SpellID)
		local Charges, _, ChargeStart, ChargeDuration = GetSpellCharges(s.SpellID)
		local CurrentDuration = (Start + Duration - GetTime())
		if Charges then
			CurrentDuration = (ChargeStart + ChargeDuration - GetTime())
		end
		if Enable and (CurrentDuration and floor(CurrentDuration) <= OzCooldowns.db["MinimumDuration"] and floor(CurrentDuration) > .1) then
			OzCooldowns:EnableCooldown(s)
		else
			OzCooldowns:DisableCooldown(s)
		end
	end)
end

function OzCooldowns:EnableCooldown(Frame)
	Frame.Enabled = true
	Frame:SetParent(self.Holder)
	Frame.Icon:SetDesaturated(false)

	if OzCooldowns.db["StatusBar"] then
		Frame.Cooldown:SetDrawSwipe(false)
		Frame.StatusBar:Show()
	end

	Frame:Show()
	Frame:SetScript("OnUpdate", function(s)
		local Start, Duration, Enable = GetSpellCooldown(s.SpellID)
		local Charges, _, ChargeStart, ChargeDuration = GetSpellCharges(s.SpellID)
		local CurrentDuration = (Start + Duration - GetTime())
		if Charges then
			Start, Duration = ChargeStart, ChargeDuration
			CurrentDuration = (ChargeStart + ChargeDuration - GetTime())
			if Start == (((2^32)/1000) - ChargeDuration) then
				CurrentDuration = 0
			end
		end

		s.CurrentDuration = CurrentDuration

		if Enable and OzCooldowns.db['BuffTimer'] then
			local Stacks, _, AuraDuration, ExpirationTime = select(3, AuraUtil.FindAuraByName(s.SpellName, 'player'))
			if ExpirationTime then
				Start, Duration = ExpirationTime - AuraDuration, AuraDuration
				CurrentDuration = (Duration - (GetTime() - Start))
				Charges = Stacks
				s.Cooldown:SetReverse(true)
				s.StatusBar:SetReverseFill(true)
			else
				s.Cooldown:SetReverse(false)
				s.StatusBar:SetReverseFill(false)
			end
		end

		if Enable and (s.CurrentDuration and s.CurrentDuration > 0) then
			local Normalized = CurrentDuration / Duration
			s.Cooldown:SetCooldown(Start, Duration)
			s.StatusBar:SetValue(Normalized)
			s.Stacks:SetText(Charges ~= nil and Charges > 0 and Charges or '')
			if OzCooldowns.db["FadeMode"] == "GreenToRed" then
				s.StatusBar:SetStatusBarColor(1 - Normalized, Normalized, 0)
			elseif OzCooldowns.db["FadeMode"] == "RedToGreen" then
				s.StatusBar:SetStatusBarColor(Normalized, 1 - Normalized, 0)
			end
		else
			OzCooldowns:DisableCooldown(s)
		end
	end)
end

function OzCooldowns:DisableCooldown(Frame)
	Frame.Enabled = false
	Frame.CurrentDuration = 0
	Frame.StatusBar:Hide()
	Frame.Cooldown:SetDrawSwipe(true)

	if OzCooldowns.db["Mode"] == "HIDE" then
		Frame:Hide()
		Frame:SetParent(self.Hider)
	else
		Frame:SetAlpha(.3)
		Frame:SetParent(self.Holder)
		Frame.Icon:SetDesaturated(true)
	end
	Frame:SetScript("OnUpdate", nil)
end

function OzCooldowns:Position()
	local Vertical, Spacing, Size = OzCooldowns.db["Vertical"], OzCooldowns.db["Spacing"], OzCooldowns.db["Size"]
	local xSpacing = Vertical and 0 or Spacing
	local ySpacing = Vertical and -(Spacing + (OzCooldowns.db["StatusBar"] and 8 or 0)) or 0
	local AnchorPoint = Vertical and "BOTTOMLEFT" or "TOPRIGHT"
	local LastFrame = OzCooldowns.Holder
	local Index = 0

	if OzCooldowns.db["SortByDuration"] and OzCooldowns.db["Mode"] == "HIDE" then
		sort(Cooldowns, function (a, b)
			local aStart, aDuration = GetSpellCooldown(a.SpellID)
			local bStart, bDuration = GetSpellCooldown(b.SpellID)
			return (aStart + aDuration) < (bStart + bDuration)
		end)
	end

	for i = 1, #Cooldowns do
		local Frame = Cooldowns[i]

		if OzCooldowns.db["Mode"] == "DIM" then
			Frame:ClearAllPoints()
			Frame:SetPoint("TOPLEFT", LastFrame, Index == 0 and "TOPLEFT" or AnchorPoint, xSpacing, ySpacing)
			LastFrame = Frame
			Index = Index + 1
		end

		if OzCooldowns.db["Mode"] == "HIDE" then
			if Frame.Enabled then
				Frame:ClearAllPoints()
				Frame:SetPoint("TOPLEFT", LastFrame, Index == 0 and "TOPLEFT" or AnchorPoint, xSpacing, ySpacing)
				LastFrame = Frame
				Index = Index + 1
			else
				Frame:SetParent(OzCooldowns.Hider)
			end
		end
	end

	if OzCooldowns.db["Vertical"] then
		OzCooldowns.Holder:SetSize(40, Size * Index + (Index + 1) * ySpacing)
	else
		OzCooldowns.Holder:SetSize(Size * Index + (Index + 1) * xSpacing, 40)
	end
end

function OzCooldowns:UpdateCooldownFrames()
	local Size = self.db["Size"]
	local MouseEnabled = self.db["Tooltips"] or self.db["Announce"]

	for _, Frame in pairs(CooldownFrames) do
		Frame:SetSize(Size, Size)
		Frame:EnableMouse(MouseEnabled)
		Frame.Stacks:SetFont(PA.LSM:Fetch("font", self.db["StackFont"]), self.db["StackFontSize"], self.db["StackFontFlag"])
		Frame.StatusBar:SetStatusBarTexture(PA.LSM:Fetch('statusbar', self.db["StatusBarTexture"]))
		Frame.StatusBar:SetStatusBarColor(unpack(self.db["StatusBarTextureColor"]))
		Frame.StatusBar:SetSize(Size - ((AS and AS.PixelPerfect and 2 or 4) or 2), 4)
		if self.Masque and self.db.Masque and Frame.__MSQ_NormalSkin then
			Frame.StatusBar.Backdrop:SetTexture(Frame.__MSQ_NormalSkin.EmptyTexture or Frame.__MSQ_NormalSkin.Texture)
			Frame.StatusBar.Backdrop:SetTexCoord(GetTexCoords(Frame.__MSQ_NormalSkin.EmptyCoords or Frame.__MSQ_NormalSkin.TexCoords))
			Frame.StatusBar.Backdrop:SetVertexColor(GetColor(Frame.__MSQ_NormalSkin.Color))
		end
	end
end

function OzCooldowns:CreateCooldownFrame(SpellID)
	local SpellName, _, SpellTexture = GetSpellInfo(SpellID)
	local Size = self.db["Size"]

	local Frame = CreateFrame("Button", 'OzCD_'..SpellID, self.Holder)
	Frame:RegisterForClicks('AnyUp')
	Frame:SetSize(Size, Size)

	local Icon = Frame:CreateTexture(nil, "ARTWORK", nil, 1)
	Icon:SetPoint('TOPLEFT', 2, -2)
	Icon:SetPoint('BOTTOMRIGHT', -2, 2)
	Icon:SetTexCoord(.08, .92, .08, .92)
	Icon:SetTexture(SpellTexture)

	local Stacks = Frame:CreateFontString(nil, "OVERLAY")
	Stacks:SetFont(PA.LSM:Fetch('font', self.db.StackFont), self.db.StackFontSize, self.db.StackFontFlag)
	Stacks:SetTextColor(1, 1, 1)
	Stacks:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMRIGHT", 0, 2)

	local StatusBar = CreateFrame("StatusBar", nil, Frame)
	StatusBar:SetSize(Size - 2, 4)
	StatusBar:SetPoint("TOP", Frame, "BOTTOM", 0, -1)
	StatusBar:SetMinMaxValues(0, 1)

	local Cooldown = CreateFrame("Cooldown", nil, Frame, "CooldownFrameTemplate")
	Cooldown:SetAllPoints(Icon)
	Cooldown:SetDrawEdge(false)

	self:RegisterCooldown(Cooldown)

	if self.Masque and self.db.Masque then
		self.MasqueGroup:AddButton(Frame)

		StatusBar.Backdrop = StatusBar:CreateTexture(nil, 'OVERLAY')
		StatusBar.Backdrop:SetPoint('TOPLEFT', -4, 1)
		StatusBar.Backdrop:SetPoint('BOTTOMRIGHT', 4, -1)

		StatusBar.Background = StatusBar:CreateTexture(nil, 'BACKGROUND')
		StatusBar.Background:SetColorTexture(0, 0, 0, .6)
		StatusBar.Background:SetPoint('TOPLEFT', -1, 1)
		StatusBar.Background:SetPoint('BOTTOMRIGHT', 1, -1)
	else
		PA:SetTemplate(Frame)
		PA:CreateShadow(Frame)
		PA:SetInside(Icon)
		PA:CreateBackdrop(StatusBar, 'Default')
		PA:CreateShadow(StatusBar.Backdrop)
		StatusBar:SetPoint("TOP", Frame, "BOTTOM", 0, -3)
	end

	if not (self.ElvUI or self.Tukui) then
		Frame:RegisterForDrag('LeftButton')
		Frame:SetScript('OnDragStart', function(s) s:GetParent():StartMoving() end)
		Frame:SetScript('OnDragStop', function(s) s:GetParent():StopMovingOrSizing() end)
	end

	Frame:SetScript('OnEnter', function(s)
		if not OzCooldowns.db["Tooltips"] then return end
		GameTooltip:SetOwner(s, 'ANCHOR_CURSOR')
		GameTooltip:ClearLines()
		GameTooltip:SetSpellByID(s.SpellID)
		GameTooltip:Show()
	end)
	Frame:SetScript('OnLeave', GameTooltip_Hide)
	Frame:SetScript('OnClick', function(s)
		if not OzCooldowns.db["Announce"] then return end
		local Channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "SAY"
		local CurrentDuration = s.CurrentDuration
		local TimeRemaining
		if CurrentDuration > 60 then
			TimeRemaining = format("%d m", ceil(CurrentDuration / 60))
		elseif CurrentDuration <= 60 and CurrentDuration > 10 then
			TimeRemaining = format("%d s", CurrentDuration)
		elseif CurrentDuration <= 10 and CurrentDuration > 0 then
			TimeRemaining = format("%.1f s", CurrentDuration)
		end
		SendChatMessage(format("My %s will be off cooldown in %s", s.SpellName, TimeRemaining), Channel)
	end)

	Frame.Icon = Icon
	Frame.Stacks = Stacks
	Frame.StatusBar = StatusBar
	Frame.Cooldown = Cooldown
	Frame.SpellID = SpellID
	Frame.SpellName = SpellName

	self:DisableCooldown(Frame)

	return Frame
end

function OzCooldowns:BuildCooldowns()
	wipe(Cooldowns)

	local i = 1
	for SpellID in pairs(OzCooldowns.db.SpellCDs) do
		CooldownFrames[SpellID] = CooldownFrames[SpellID] or self:CreateCooldownFrame(SpellID)
		CooldownFrames[SpellID]:Hide() -- Just for DIM Mode
		if OzCooldowns.db.SpellCDs[SpellID] then
			Cooldowns[i] = CooldownFrames[SpellID]
			i = i + 1
		elseif CooldownFrames[SpellID] then
			self:DisableCooldown(CooldownFrames[SpellID])
		end
	end
	OzCooldowns:UpdateCooldownSettings()
	OzCooldowns:UpdateCooldownFrames()

	for _, Frame in pairs(Cooldowns) do
		self:FindCooldown(Frame.SpellID)
	end

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function OzCooldowns:UNIT_SPELLCAST_SUCCEEDED(event, ...)
	local Unit, _, SpellID  = ...
	if Unit == 'player' then
		C_Timer.After(.1, function() self:FindCooldown(SpellID) end)
	end
end

function OzCooldowns:MasqueCallback(Addon, Group, SkinID, Gloss, Backdrop, Colors, Disabled)
	for _, Frame in pairs(CooldownFrames) do
		Frame.StatusBar.Backdrop:SetTexture(Frame.__MSQ_NormalSkin.EmptyTexture or Frame.__MSQ_NormalSkin.Texture)
		Frame.StatusBar.Backdrop:SetTexCoord(GetTexCoords(Frame.__MSQ_NormalSkin.EmptyCoords or Frame.__MSQ_NormalSkin.TexCoords))
		Frame.__MSQ_BaseFrame:SetFrameLevel(2)
	end
end

function OzCooldowns:Initialize()
	OzCooldowns.db = PA.db['OzCooldowns']

	if OzCooldowns.db.Enable ~= true then
		return
	end

	AS = AddOnSkins and unpack(AddOnSkins)
	ES = _G.EnhancedShadows

	self:BuildProfile()

	if PA.Masque and self.db.Masque then
		PA.Masque:Register("OzCooldowns", self.MasqueCallback)
		self.MasqueGroup = PA.Masque:Group("OzCooldowns")
	end

	local Holder = CreateFrame("Frame", 'OzCooldownsHolder', UIParent)
	Holder:SetFrameStrata('LOW')
	Holder:SetFrameLevel(10)
	Holder:SetSize(40, 40)
	Holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 360)

	if PA.Tukui then
		Tukui[1]["Movers"]:RegisterFrame(Holder)
	elseif PA.ElvUI then
		ElvUI[1]:CreateMover(Holder, "OzCooldownsMover", "OzCooldowns Anchor", nil, nil, nil, "ALL,GENERAL")
	else
		Holder:SetMovable(true)
		Holder:SetScript('OnDragStart', Holder.StartMoving)
		Holder:SetScript('OnDragStop', Holder.StopMovingOrSizing)
	end

	self.Holder = Holder

	self.Hider = CreateFrame('Frame', nil, UIParent)
	self.Hider:Hide()

	self.Delay = CreateFrame('Frame', nil, UIParent)
	self.Delay:SetPoint('BOTTOM', UIParent, 'TOP', 0, 0)

	self:GetOptions()

	if not PA.ElvUI and GetCVarBool("countdownForCooldowns") == false and (not self.db.WarnUser) then
		StaticPopupDialogs["OZCOOLDOWNS"] = {
			text = 'Blizzard Console Variable - Show Numbers for Cooldown is Disabled. It needs to be enabled if you would like numbers on the cooldowns.\n\nWould you like to enable it?',
			button1 = YES,
			button2 = NO,
			OnAccept = function(self)
				SetCVar("countdownForCooldowns", "1")
			end,
			OnCancel = function(self)
				OzCooldowns.db.WarnUser = true
			end,
			timeout = 0,
			whileDead = 1,
			showAlert = 1,
		}
		StaticPopup_Show("OZCOOLDOWNS")
	end

	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'BuildCooldowns')
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:ScheduleRepeatingTimer('Position', .1)
end

function OzCooldowns:BuildProfile()
	local SpellList = {}

	for _, SpellID in pairs(PA.Racials) do
		if IsSpellKnown(SpellID) then
			tinsert(SpellList, SpellID)
		end
	end

	for _, SpellID in pairs(PA.SpellList) do
		if DoesSpellExist(SpellID) then
			SpellList[SpellID] = true
		end
	end

	PA.Defaults.profile['OzCooldowns'] = {
		['Announce'] = true,
		['BuffTimer'] = true,
		['CooldownText'] = {
			['Accurate'] = true,
			['Enable'] = true,
			['Expiring'] = { 1, 0, 0 },
			['Font'] = 'Arial Narrow',
			['FontFlag'] = 'OUTLINE',
			['FontSize'] = 14,
			['Minutes'] = { 1, 1, 1 },
			['Seconds'] = { 1, 1, 0 },
			['Threshold'] = 10,
		},
		['DurationText'] = true,
		['FadeMode'] = 'None',
		['Masque'] = false,
		['MinimumDuration'] = 600,
		['Mode'] = 'HIDE',
		['Size'] = 36,
		['SortByDuration'] = true,
		['Spacing'] = 4,
		['SpellCDs'] = CopyTable(SpellList),
		['StackFont'] = 'Arial Narrow',
		['StackFontFlag'] = 'OUTLINE',
		['StackFontSize'] = 12,
		['StatusBar'] = true,
		['StatusBarTexture'] = 'Blizzard Raid Bar',
		['StatusBarTextureColor'] = { .24, .54, .78 },
		['Tooltips'] = true,
		['Vertical'] = false,
		['WarnUser'] = false,
	}

	PA.Options.args.general.args.OzCooldowns = {
		type = 'toggle',
		name = OzCooldowns.Title,
		desc = OzCooldowns.Description,
	}
end

function OzCooldowns:GenerateSpellOptions()
	local SpellOptions = {}

	local Num = 1
	for k in pairs(OzCooldowns.db.SpellCDs) do
		local Name, _, Icon = GetSpellInfo(k)
		if Name then
			SpellOptions[tostring(k)] = {
				type = 'toggle',
				image = Icon,
				imageCoords = PA.TexCoords,
				name = Name,
				desc = 'Spell ID: '..k,
			}
			Num = Num + 1
		end
	end

	return SpellOptions
end

function OzCooldowns:GetOptions()
	local Options = {
		type = 'group',
		name = OzCooldowns.Title,
		childGroups = 'tab',
		get = function(info) return OzCooldowns.db[info[#info]] end,
		set = function(info, value) OzCooldowns.db[info[#info]] = value OzCooldowns:UpdateCooldownFrames() end,
		args = {
			main = {
				order = 0,
				type = 'group',
				name = PA.ACL['Main Options'],
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
						disabled = function() return OzCooldowns.db['Mode'] == 'DIM' end,
					},
					MinimumDuration = {
						order = 2,
						type = 'range',
						name = PA.ACL['Minimum Duration Visibility'],
						desc = PA.ACL['Duration in Seconds'],
						min = 2, max = 600, step = 1,
					},
					BuffTimer = {
						order = 3,
						type = 'toggle',
						name = PA.ACL['Buff Timer'],
					},
					CooldownText = {
						type = 'group',
						order = 4,
						name = PA.ACL['Cooldown Text'],
						guiInline = true,
						get = function(info) return OzCooldowns.db.CooldownText[info[#info]] end,
						set = function(info, value) OzCooldowns.db.CooldownText[info[#info]] = value OzCooldowns:UpdateCooldownSettings() end,
						args = {
							Enable = {
								type = 'toggle',
								order = 0,
								name = PA.ACL['Enabled'],
							},
							Accurate = {
								type = 'toggle',
								order = 0,
								name = PA.ACL['M:SS Format'],
							},
							Font = {
								type = 'select', dialogControl = 'LSM30_Font',
								order = 1,
								name = PA.ACL['Font'],
								values = PA.LSM:HashTable('font'),
							},
							FontSize = {
								type = 'range',
								order = 2,
								name = PA.ACL['Font Size'],
								min = 8, max = 18, step = 1,
							},
							FontFlag = {
								name = PA.ACL['Font Flag'],
								order = 3,
								type = 'select',
								values = {
									['MONOCHROME'] = 'MONOCHROME',
									['MONOCHROMEOUTLINE'] = 'MONOCHROMEOUTLINE',
									['NONE'] = 'None',
									['OUTLINE'] = 'OUTLINE',
									['THICKOUTLINE'] = 'THICKOUTLINE',
								},
							},
							Threshold = {
								type = 'range',
								order = 4,
								name = PA.ACL['Low Threshold'],
								desc = PA.ACL['Threshold before text turns red and is in decimal form. Set to -1 for it to never turn red'],
								min = -1, max = 20, step = 1,
							},
							Expiring = {
								type = 'color',
								order = 5,
								name = PA.ACL['Expiring'],
								desc = PA.ACL['Color when the text is about to expire'],
								get = function(info) return unpack(OzCooldowns.db.CooldownText[info[#info]]) end,
								set = function(info, r, g, b) OzCooldowns.db.CooldownText[info[#info]] = { r, g, b } OzCooldowns:UpdateCooldownSettings() end,
							},
							Seconds = {
								type = 'color',
								order = 6,
								name = SECONDS,
								desc = PA.ACL['Color when the text is in the seconds format.'],
								get = function(info) return unpack(OzCooldowns.db.CooldownText[info[#info]]) end,
								set = function(info, r, g, b) OzCooldowns.db.CooldownText[info[#info]] = { r, g, b } OzCooldowns:UpdateCooldownSettings() end,
							},
							Minutes = {
								type = 'color',
								order = 7,
								name = MINUTES,
								desc = PA.ACL['Color when the text is in the minutes format.'],
								get = function(info) return unpack(OzCooldowns.db.CooldownText[info[#info]]) end,
								set = function(info, r, g, b) OzCooldowns.db.CooldownText[info[#info]] = { r, g, b } OzCooldowns:UpdateCooldownSettings() end,
							},
						},
					},
					Icons = {
						order = 5,
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
							Mode = {
								order = 6,
								type = 'select',
								name = PA.ACL['Dim or Hide'],
								values = {
									['DIM'] = PA.ACL['DIM'],
									['HIDE'] = PA.ACL['HIDE'],
								},
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
								values = {
									['MONOCHROME'] = 'MONOCHROME',
									['MONOCHROMEOUTLINE'] = 'MONOCHROMEOUTLINE',
									['NONE'] = 'None',
									['OUTLINE'] = 'OUTLINE',
									['THICKOUTLINE'] = 'THICKOUTLINE',
								},
							},
						},
					},
					StatusBars = {
						order = 4,
						type = 'group',
						guiInline = true,
						name = PA.ACL['Status Bar'],
						args = {
							StatusBar = {
								order = 1,
								type = 'toggle',
								name = PA.ACL['Enabled'],
							},
							StatusBarTexture = {
								type = 'select',
								dialogControl = 'LSM30_Statusbar',
								order = 2,
								name = PA.ACL['Texture'],
								values = PA.LSM:HashTable('statusbar'),
								disabled = function() return not OzCooldowns.db['StatusBar'] end,
							},
							FadeMode = {
								order = 3,
								type = 'select',
								name = PA.ACL['Fade Mode'],
								disabled = function() return not OzCooldowns.db['StatusBar'] end,
								values = {
									['None'] = PA.ACL['None'],
									['RedToGreen'] = PA.ACL['Red to Green'],
									['GreenToRed'] = PA.ACL['Green to Red'],
								},
							},
							StatusBarTextureColor = {
								type = 'color',
								order = 4,
								name = PA.ACL['Texture Color'],
								hasAlpha = false,
								get = function(info) return unpack(OzCooldowns.db[info[#info]])	end,
								set = function(info, r, g, b, a) OzCooldowns.db[info[#info]] = { r, g, b, a} OzCooldowns:UpdateCooldownFrames() end,
								disabled = function() return not OzCooldowns.db['StatusBar'] or OzCooldowns.db['FadeMode'] == 'GreenToRed' or OzCooldowns.db['FadeMode'] == 'RedToGreen' end,
							},
						},
					},
				},
			},
			spells = {
				order = 1,
				type = 'group',
				name = SPELLS,
				args = OzCooldowns:GenerateSpellOptions(),
				get = function(info) return OzCooldowns.db.SpellCDs[tonumber(info[#info])] end,
				set = function(info, value)
					OzCooldowns.db.SpellCDs[tonumber(info[#info])] = value
					OzCooldowns:BuildCooldowns()
				end,
			},
		},
	}

	PA.Options.args.OzCooldowns = Options
end

local function GetTimeInfo(s)
	if s < 60 then
		if s >= Threshold then
			return floor(s), 1
		else
			return s, 2
		end
	else
		return OzCooldowns.db.CooldownText.Accurate and format('%d:%.2d', s/60, s%60) or ceil(s / 60), 0
	end
end

local function OnSetCooldown(self, start, duration)
	local timervalue, formatid = GetTimeInfo(duration - (GetTime() - start))
	self.text:SetFormattedText(TimeFormats[formatid], timervalue)
	self.text:SetTextColor(unpack(TimeColors[formatid]))
end

function OzCooldowns:RegisterCooldown(Cooldown)
	if (Cooldown.isHooked) then return end

	if not Cooldown.text then
		local NumRegions = Cooldown:GetNumRegions()
		for i = 1, NumRegions do
			local Region = select(i, Cooldown:GetRegions())
			if Region.GetText then
				Cooldown.text = Region
				Region:Point("CENTER", 1, 1)
			end
		end
	end

	hooksecurefunc(Cooldown, "SetCooldown", OnSetCooldown)
	tinsert(RegisteredCooldowns, Cooldown)

	if PA.ElvUI then
		ElvUI[1]:RegisterCooldown(Cooldown);
	end

	Cooldown.isHooked = true
end

function OzCooldowns:UpdateCooldownSettings()
	Threshold = self.db.CooldownText.Threshold

	TimeColors[0] = self.db.CooldownText.Minutes
	TimeColors[1] = self.db.CooldownText.Seconds
	TimeColors[2] = self.db.CooldownText.Expiring

	if self.db.CooldownText.Accurate then
		TimeFormats[0] = '%s'
	else
		TimeFormats[0] = '%dm'
	end

	for _, Cooldown in pairs(RegisteredCooldowns) do
		Cooldown.text:SetFont(PA.LSM:Fetch('font', self.db.CooldownText.Font), self.db.CooldownText.FontSize, self.db.CooldownText.FontFlag)
		if self.db.CooldownText['Enable'] then
			Cooldown:SetHideCountdownNumbers(false)
		else
			Cooldown:SetHideCountdownNumbers(true)
		end
	end
end
