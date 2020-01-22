local PA = _G.ProjectAzilroka
local SMB = PA:NewModule('SquareMinimapButtons', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
PA.SMB, _G.SquareMinimapButtons = SMB, SMB

SMB.Title = 'Square Minimap Buttons'
SMB.Header = PA.ACL['|cFF16C3F2Square|r |cFFFFFFFFMinimap Buttons|r']
SMB.Description = PA.ACL['Minimap Button Bar / Minimap Button Skinning']
SMB.Authors = 'Azilroka    NihilisticPandemonium    Sinaris    Omega    Durc'
SMB.isEnabled = false

local _G = _G
local strsub = strsub
local strlen = strlen
local strfind = strfind
local strmatch = strmatch
local strlower = strlower
local tinsert = tinsert
local pairs = pairs
local unpack = unpack
local select = select
local tContains = tContains
local tostring = tostring
local floor = floor

local InCombatLockdown = InCombatLockdown
local C_PetBattles = C_PetBattles
local Minimap = Minimap

local rad = math.rad
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local max = math.max
local min = math.min
local deg = math.deg
local atan2 = math.atan2

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition
local HasNewMail = HasNewMail
local MinimapMailFrameUpdate = MinimapMailFrameUpdate

SMB.Buttons = {}

SMB.IgnoreButton = {
	'HelpOpenWebTicketButton',
	'MiniMapVoiceChatFrame',
	'TimeManagerClockButton',
	'BattlefieldMinimap',
	'ButtonCollectFrame',
	'GameTimeFrame',
	'QueueStatusMinimapButton',
	'GarrisonLandingPageMinimapButton',
	'MiniMapMailFrame',
	'MiniMapTracking',
	'MinimapZoomIn',
	'MinimapZoomOut',
	'TukuiMinimapZone',
	'TukuiMinimapCoord',
	'RecipeRadarMinimapButtonFrame',
}

SMB.GenericIgnore = {
	'Archy',
	'GatherMatePin',
	'GatherNote',
	'GuildInstance',
	'HandyNotesPin',
	'MiniMap',
	'Spy_MapNoteList_mini',
	'ZGVMarker',
	'poiMinimap',
	'GuildMap3Mini',
	'LibRockConfig-1.0_MinimapButton',
	'NauticusMiniIcon',
	'WestPointer',
	'Cork',
	'DugisArrowMinimapPoint',
	'QuestieFrame',
}

SMB.PartialIgnore = { 'Node', 'Pin', 'POI' }

SMB.OverrideTexture = {
	BagSync_MinimapButton = 'Interface/AddOns/BagSync/media/icon',
	DBMMinimapButton = 'Interface/Icons/INV_Helmet_87',
	SmartBuff_MiniMapButton = 'Interface/Icons/Spell_Nature_Purge',
	VendomaticButtonFrame = 'Interface/Icons/INV_Misc_Rabbit_2',
	OutfitterMinimapButton = '',
	RecipeRadar_MinimapButton = 'Interface/Icons/INV_Scroll_03',
	GameTimeFrame = ''
}

SMB.DoNotCrop = {
	ZygorGuidesViewerMapIcon = true,
	ItemRackMinimapFrame = true,
}

SMB.UnrulyButtons = {
	'WIM3MinimapButton',
	'RecipeRadar_MinimapButton',
}

local ButtonFunctions = { 'SetParent', 'ClearAllPoints', 'SetPoint', 'SetSize', 'SetScale', 'SetFrameStrata', 'SetFrameLevel' }

local RemoveTextureID = {
	[136430] = true,
	[136467] = true,
	[136468] = true,
	[130924] = true,
}

local RemoveTextureFile = {
	["interface/minimap/minimap-trackingborder"] = true,
	["interface/minimap/ui-minimap-border"] = true,
	["interface/minimap/ui-minimap-background"] = true,
}

function SMB:LockButton(Button)
	for _, Function in pairs(ButtonFunctions) do
		Button[Function] = PA.Noop
	end
end

function SMB:UnlockButton(Button)
	for _, Function in pairs(ButtonFunctions) do
		Button[Function] = nil
	end
end

function SMB:OnUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()

	px, py = px / scale, py / scale

	local pos = deg(atan2(py - my, px - mx)) % 360
	local angle = rad(pos or 225)
	local x, y = cos(angle), sin(angle)
	local w = (Minimap:GetWidth() + SMB.db.IconSize) / 2
	local h = (Minimap:GetHeight() + SMB.db.IconSize) / 2
	local diagRadiusW = sqrt(2*(w)^2)-10
	local diagRadiusH = sqrt(2*(h)^2)-10

	x = max(-w, min(x*diagRadiusW, w))
	y = max(-h, min(y*diagRadiusH, h))

	self:ClearAllPoints()
	self:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function SMB:OnDragStart()
	self:SetScript("OnUpdate", SMB.OnUpdate)
end

function SMB:OnDragStop()
	self:SetScript("OnUpdate", nil)
end

function SMB:HandleBlizzardButtons()
	if not SMB.db.BarEnabled then return end
	local Size = SMB.db.IconSize

	if SMB.db.MoveMail and not _G.MiniMapMailFrame.SMB then
		local Frame = CreateFrame('Frame', 'SMB_MailFrame', SMB.Bar)
		Frame:SetSize(Size, Size)
		PA:SetTemplate(Frame)
		Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
		Frame.Icon:SetPoint('CENTER')
		Frame.Icon:SetSize(18, 18)
		Frame.Icon:SetTexture(_G.MiniMapMailIcon:GetTexture())
		Frame:EnableMouse(true)
		Frame:HookScript('OnEnter', function(s)
			if HasNewMail() then
				GameTooltip:SetOwner(s, "ANCHOR_BOTTOMRIGHT")
				if GameTooltip:IsOwned(s) then
					MinimapMailFrameUpdate()
				end
			end
			s:SetBackdropBorderColor(unpack(PA.ClassColor))
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		Frame:HookScript('OnLeave', function(s)
			GameTooltip:Hide()
			PA:SetTemplate(s)
			if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		_G.MiniMapMailFrame:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0)	end)
		_G.MiniMapMailFrame:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)
		_G.MiniMapMailFrame:EnableMouse(false)

		if _G.MiniMapMailFrame:IsShown() then
			Frame.Icon:SetVertexColor(0, 1, 0)
		end

		-- Hide Icon & Border
		_G.MiniMapMailIcon:Hide()
		_G.MiniMapMailBorder:Hide()

		if SMB.db.Shadows then
			PA:CreateShadow(Frame)
		end

		_G.MiniMapMailFrame.SMB = true
		tinsert(SMB.Buttons, Frame)
	end

	if PA.Retail then
		if SMB.db.HideGarrison then
			_G.GarrisonLandingPageMinimapButton:UnregisterAllEvents()
			_G.GarrisonLandingPageMinimapButton:SetParent(SMB.Hider)
			_G.GarrisonLandingPageMinimapButton:Hide()
		elseif SMB.db.MoveGarrison and not _G.GarrisonLandingPageMinimapButton.SMB then
			_G.GarrisonLandingPageMinimapButton:SetParent(Minimap)
			_G.GarrisonLandingPageMinimapButton_OnLoad(_G.GarrisonLandingPageMinimapButton)
			_G.GarrisonLandingPageMinimapButton_UpdateIcon(_G.GarrisonLandingPageMinimapButton)
			_G.GarrisonLandingPageMinimapButton:Show()
			_G.GarrisonLandingPageMinimapButton:SetScale(1)
			_G.GarrisonLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
			_G.GarrisonLandingPageMinimapButton:SetScript('OnEnter', function(s)
				s:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			_G.GarrisonLandingPageMinimapButton:SetScript('OnLeave', function(s)
				PA:SetTemplate(s)
				if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			_G.GarrisonLandingPageMinimapButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(_G.GarrisonLandingPageMinimapButton)
			end

			tinsert(SMB.Buttons, _G.GarrisonLandingPageMinimapButton)
		end

		if SMB.db.MoveTracker and not _G.MiniMapTrackingButton.SMB then
			_G.MiniMapTracking.Show = nil

			_G.MiniMapTracking:Show()

			_G.MiniMapTracking:SetParent(SMB.Bar)
			_G.MiniMapTracking:SetSize(Size, Size)

			_G.MiniMapTrackingIcon:ClearAllPoints()
			_G.MiniMapTrackingIcon:SetPoint('CENTER')

			_G.MiniMapTrackingBackground:SetAlpha(0)
			_G.MiniMapTrackingIconOverlay:SetAlpha(0)
			_G.MiniMapTrackingButton:SetAlpha(0)

			_G.MiniMapTrackingButton:SetParent(_G.MinimapTracking)
			_G.MiniMapTrackingButton:ClearAllPoints()
			_G.MiniMapTrackingButton:SetAllPoints(_G.MiniMapTracking)

			_G.MiniMapTrackingButton:SetScript('OnMouseDown', nil)
			_G.MiniMapTrackingButton:SetScript('OnMouseUp', nil)

			_G.MiniMapTrackingButton:HookScript('OnEnter', function()
				_G.MiniMapTracking:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			_G.MiniMapTrackingButton:HookScript('OnLeave', function()
				PA:SetTemplate(_G.MiniMapTracking)
				if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			_G.MiniMapTrackingButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(_G.MiniMapTracking)
			end

			tinsert(SMB.Buttons, _G.MiniMapTracking)
		end

		if SMB.db["MoveQueue"] and not _G.QueueStatusMinimapButton.SMB then
			local Frame = CreateFrame('Frame', 'SMB_QueueFrame', SMB.Bar)
			PA:SetTemplate(Frame)
			Frame:SetSize(Size, Size)
			Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
			Frame.Icon:SetSize(Size, Size)
			Frame.Icon:SetPoint('CENTER')
			Frame.Icon:SetTexture('Interface/LFGFrame/LFG-Eye')
			Frame.Icon:SetTexCoord(0, 64 / 512, 0, 64 / 256)
			Frame:SetScript('OnMouseDown', function()
				if _G.PVEFrame:IsShown() then
					_G.HideUIPanel(_G.PVEFrame)
				else
					_G.ShowUIPanel(_G.PVEFrame)
					_G.GroupFinderFrame_ShowGroupFrame()
				end
			end)
			Frame:HookScript('OnEnter', function(s)
				s:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			Frame:HookScript('OnLeave', function(s)
				PA:SetTemplate(s)
				if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			_G.QueueStatusMinimapButton:SetParent(SMB.Bar)
			_G.QueueStatusMinimapButton:SetFrameLevel(Frame:GetFrameLevel() + 2)
			_G.QueueStatusMinimapButton:ClearAllPoints()
			_G.QueueStatusMinimapButton:SetPoint("CENTER", Frame, "CENTER", 0, 0)

			_G.QueueStatusMinimapButton:SetHighlightTexture(nil)

			_G.QueueStatusMinimapButton:HookScript('OnShow', function() Frame:EnableMouse(false) end)
			_G.QueueStatusMinimapButton:HookScript('PostClick', _G.QueueStatusMinimapButton_OnLeave)
			_G.QueueStatusMinimapButton:HookScript('OnHide', function() Frame:EnableMouse(true) end)

			_G.QueueStatusMinimapButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(Frame)
			end

			tinsert(SMB.Buttons, Frame)
		end
	else
		-- MiniMapTrackingFrame
		if SMB.db.MoveGameTimeFrame and not _G.GameTimeFrame.SMB then
			local STEP = 5.625 -- 256 * 5.625 = 1440M = 24H
			local PX_PER_STEP = 0.00390625 -- 1 / 256
			local l, r, offset

			PA:SetTemplate(_G.GameTimeFrame)
			_G.GameTimeTexture:SetTexture('')

			_G.GameTimeFrame.DayTimeIndicator = _G.GameTimeFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
			_G.GameTimeFrame.DayTimeIndicator:SetTexture("Interface/Minimap/HumanUITile-TimeIndicator", true)
			PA:SetInside(_G.GameTimeFrame.DayTimeIndicator)

			_G.GameTimeFrame:SetSize(Size, Size)

			_G.GameTimeFrame.timeOfDay = 0
			local function OnUpdate(s, elapsed)
				s.elapsed = (s.elapsed or 1) + elapsed
				if s.elapsed > 1 then
					local hour, minute = _G.GetGameTime()
					local time = hour * 60 + minute
					if time ~= s.timeOfDay then
						offset = PX_PER_STEP * floor(time / STEP)

						l = 0.25 + offset -- 64 / 256
						if l >= 1.25 then l = 0.25 end

						r = 0.75 + offset -- 192 / 256
						if r >= 1.75 then r = 0.75 end

						s.DayTimeIndicator:SetTexCoord(l, r, 0, 1)

						s.timeOfDay = time
					end

					s.elapsed = 0
				end
			end

			_G.GameTimeFrame:SetScript("OnUpdate", OnUpdate)
			_G.GameTimeFrame.SMB = true
			tinsert(SMB.Buttons, _G.GameTimeFrame)
		end
	end

	SMB:Update()
end

function SMB:SkinMinimapButton(Button)
	if (not Button) or Button.isSkinned then return end

	local Name = Button.GetName and Button:GetName()
	if not Name then return end

	if tContains(SMB.IgnoreButton, Name) then return end

	for i = 1, #SMB.GenericIgnore do
		if strsub(Name, 1, strlen(SMB.GenericIgnore[i])) == SMB.GenericIgnore[i] then return end
	end

	for i = 1, #SMB.PartialIgnore do
		if strmatch(Name, SMB.PartialIgnore[i]) ~= nil then return end
	end

	for i = 1, Button:GetNumRegions() do
		local Region = select(i, Button:GetRegions())
		if Region.IsObjectType and Region:IsObjectType('Texture') then
			local Texture = Region.GetTextureFileID and Region:GetTextureFileID()

			if RemoveTextureID[Texture] then
				Region:SetTexture()
			else
				Texture = strlower(tostring(Region:GetTexture()))
				if RemoveTextureFile[Texture] or strfind(Texture, 'interface/characterframe') or (strfind(Texture, 'interface/minimap') and not strfind(Texture, 'interface/minimap/tracking')) or strfind(Texture, 'border') or strfind(Texture, 'background') or strfind(Texture, 'alphamask') or strfind(Texture, 'highlight') then
					Region:SetTexture()
					Region:SetAlpha(0)
				else
					if SMB.OverrideTexture[Name] then
						Region:SetTexture(SMB.OverrideTexture[Name])
					end

					Region:ClearAllPoints()
					Region:SetDrawLayer('ARTWORK')
					PA:SetInside(Region)

					if not SMB.DoNotCrop[Name] and not Button.ignoreCrop then
						Region:SetTexCoord(unpack(PA.TexCoords))
						Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(PA.TexCoords)) end)
					end

					Region.SetPoint = function() return end
				end
			end
		end
	end

	Button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	Button:SetFrameStrata(Minimap:GetFrameStrata())
	Button:SetSize(SMB.db.IconSize, SMB.db.IconSize)

	if not Button.ignoreTemplate then
		PA:SetTemplate(Button)

		if SMB.db.Shadows then
			PA:CreateShadow(Button)
		end
	end

	--Button:SetScript('OnDragStart', SMB.OnDragStart)
	--Button:SetScript('OnDragStop', SMB.OnDragStop)

	Button:HookScript('OnEnter', function()
		if SMB.Bar:IsShown() then
			UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
		end
	end)
	Button:HookScript('OnLeave', function(s)
		PA:SetTemplate(s)
		if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
			UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
		end
	end)

	Button.isSkinned = true
	tinsert(SMB.Buttons, Button)
end

function SMB:GrabMinimapButtons()
	if (InCombatLockdown() or C_PetBattles and C_PetBattles.IsInBattle()) then return end

	for _, Button in pairs(SMB.UnrulyButtons) do
		if _G[Button] then
			_G[Button]:SetParent(Minimap)
		end
	end

	local UpdateBar
	for _, Frame in pairs({ Minimap, _G.MinimapBackdrop, _G.MinimapCluster }) do
		local NumChildren = Frame:GetNumChildren()
		if NumChildren > (Frame.SMBNumChildren or 0) then
			for i = 1, NumChildren do
				local object = select(i, Frame:GetChildren())
				if object then
					local name = object:GetName()
					local width = object:GetWidth()
					if name and width > 15 and width < 60 and (object:IsObjectType('Button') or object:IsObjectType('Frame')) then
						SMB:SkinMinimapButton(object)
					end
				end
			end

			Frame.SMBNumChildren = NumChildren
			UpdateBar = true
		end
	end

	if UpdateBar then
		SMB:Update()
	end
end

function SMB:Update()
	if not SMB.db.BarEnabled then return end

	local AnchorX, AnchorY = 0, 1
	local ButtonsPerRow = SMB.db.ButtonsPerRow or 12
	local Spacing = SMB.db.ButtonSpacing or 2
	local Size = SMB.db.IconSize or 27
	local ActualButtons, Maxed = 0

	local Anchor, DirMult = 'TOPLEFT', 1

	if SMB.db.ReverseDirection then
		Anchor, DirMult = 'TOPRIGHT', -1
	end

	for _, Button in pairs(SMB.Buttons) do
		if Button:IsVisible() then
			AnchorX, ActualButtons = AnchorX + 1, ActualButtons + 1

			if (AnchorX % (ButtonsPerRow + 1)) == 0 then
				AnchorY, AnchorX, Maxed = AnchorY + 1, 1, true
			end

			SMB:UnlockButton(Button)

			PA:SetTemplate(Button)

			Button:SetParent(SMB.Bar)
			Button:ClearAllPoints()
			Button:SetPoint(Anchor, SMB.Bar, Anchor, DirMult * (Spacing + ((Size + Spacing) * (AnchorX - 1))), (- Spacing - ((Size + Spacing) * (AnchorY - 1))))
			Button:SetSize(Size, Size)
			Button:SetScale(1)
			Button:SetFrameStrata('MEDIUM')
			Button:SetFrameLevel(SMB.Bar:GetFrameLevel() + 1)
			Button:SetScript('OnDragStart', nil)
			Button:SetScript('OnDragStop', nil)
			--Button:SetScript('OnEvent', nil)

			SMB:LockButton(Button)

			if Maxed then ActualButtons = ButtonsPerRow end
		end
	end

	local BarWidth = Spacing + (Size * ActualButtons) + (Spacing * (ActualButtons - 1)) + Spacing
	local BarHeight = Spacing + (Size * AnchorY) + (Spacing * (AnchorY - 1)) + Spacing

	SMB.Bar:SetSize(BarWidth, BarHeight)

	if SMB.db.Backdrop then
		PA:SetTemplate(SMB.Bar)
	else
		SMB.Bar:SetBackdrop(nil)
	end

	if ActualButtons == 0 then
		SMB.Bar:Hide()
	else
		SMB.Bar:Show()
	end

	if SMB.db.BarMouseOver then
		UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
	else
		UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
	end
end

function SMB:GetOptions()
	PA.Options.args.SquareMinimapButtons = {
		type = 'group',
		name = SMB.Title,
		desc = SMB.Description,
		get = function(info) return SMB.db[info[#info]] end,
		set = function(info, value) SMB.db[info[#info]] = value SMB:Update() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = SMB.Header,
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					SMB.db[info[#info]] = value
					if (not SMB.isEnabled) then
						SMB:Initialize()
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
					MBB = {
						order = 1,
						type = 'group',
						name = PA.ACL['Minimap Buttons / Bar'],
						guiInline = true,
						args = {
							BarEnabled = {
								order = 1,
								type = 'toggle',
								name = PA.ACL['Enable Bar'],
							},
							BarMouseOver = {
								order = 2,
								type = 'toggle',
								name = PA.ACL['Bar MouseOver'],
							},
							Backdrop = {
								order = 3,
								type = 'toggle',
								name = PA.ACL['Bar Backdrop'],
							},
							IconSize = {
								order = 4,
								type = 'range',
								name = PA.ACL['Icon Size'],
								min = 12, max = 48, step = 1,
							},
							ButtonSpacing = {
								order = 5,
								type = 'range',
								name = PA.ACL['Button Spacing'],
								min = 0, max = 10, step = 1,
							},
							ButtonsPerRow = {
								order = 6,
								type = 'range',
								name = PA.ACL['Buttons Per Row'],
								min = 1, max = 100, step = 1,
							},
							Shadows = {
								order = 7,
								type = 'toggle',
								name = PA.ACL['Shadows'],
							},
							ReverseDirection = {
								order = 8,
								type = "toggle",
								name = PA.ACL["Reverse Direction"],
							},
						},
					},
					Blizzard = {
						order = 2,
						type = 'group',
						name = PA.ACL['Blizzard'],
						guiInline = true,
						set = function(info, value) SMB.db[info[#info]] = value SMB:HandleBlizzardButtons() end,
						args = {
							HideGarrison  = {
								type = 'toggle',
								name = PA.ACL['Hide Garrison'],
								disabled = function() return SMB.db.MoveGarrison end,
								hidden = function() return PA.Classic end,
							},
							MoveGarrison  = {
								type = 'toggle',
								name = PA.ACL['Move Garrison Icon'],
								disabled = function() return SMB.db.HideGarrison end,
								hidden = function() return PA.Classic end,
							},
							MoveMail  = {
								type = 'toggle',
								name = PA.ACL['Move Mail Icon'],
							},
							MoveGameTimeFrame = {
								type = 'toggle',
								name = PA.ACL['Move Game Time Frame'],
								hidden = function() return PA.Retail end,
							},
							MoveTracker  = {
								type = 'toggle',
								name = PA.ACL['Move Tracker Icon'],
								hidden = function() return PA.Classic end,
							},
							MoveQueue  = {
								type = 'toggle',
								name = PA.ACL['Move Queue Status Icon'],
								hidden = function() return PA.Classic end,
							},
						},
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
				name = SMB.Authors,
				fontSize = 'large',
			},
		},
	}
end

function SMB:BuildProfile()
	PA.Defaults.profile.SquareMinimapButtons = {
		Enable = true,
		BarMouseOver = false,
		BarEnabled = true,
		Backdrop = true,
		IconSize = 20,
		ButtonsPerRow = 12,
		ButtonSpacing = 2,
		HideGarrison = false,
		MoveGarrison = true,
		MoveMail = true,
		MoveTracker = true,
		MoveQueue = true,
		MoveGameTimeFrame = true,
		Shadows = true,
		ReverseDirection = false,
	}
end

function SMB:Initialize()
	SMB.db = PA.db.SquareMinimapButtons

	if SMB.db.Enable ~= true then
		return
	end

	if PA.ElvUI and PA.SLE and _G.ElvUI[1].private.sle.minimap and _G.ElvUI[1].private.sle.minimap.mapicons.enable then
		_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'Square Minimap Buttons and S&L MiniMap Buttons are incompatible. You will have to choose one. This will reload the interface.'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'Square Minimap Buttons'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'S&L MiniMap Buttons'
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function() _G.ElvUI[1].private.sle.minimap.mapicons.enable = false _G.ReloadUI() end
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() SMB.db.Enable = false end
		_G.StaticPopup_Show("PROJECTAZILROKA")
		return
	end

	SMB.isEnabled = true

	SMB.Hider = CreateFrame("Frame", nil, _G.UIParent)

	SMB.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', _G.UIParent)
	SMB.Bar:Hide()
	SMB.Bar:SetPoint('RIGHT', _G.UIParent, 'RIGHT', -45, 0)
	SMB.Bar:SetFrameStrata('MEDIUM')
	SMB.Bar:SetFrameLevel(1)
	SMB.Bar:SetClampedToScreen(true)
	SMB.Bar:SetMovable(true)
	SMB.Bar:EnableMouse(true)
	SMB.Bar:SetSize(SMB.db.IconSize, SMB.db.IconSize)

	SMB.Bar:SetScript('OnEnter', function(s) UIFrameFadeIn(s, 0.2, s:GetAlpha(), 1) end)
	SMB.Bar:SetScript('OnLeave', function(s)
		if SMB.db.BarMouseOver then
			UIFrameFadeOut(s, 0.2, s:GetAlpha(), 0)
		end
	end)

	if PA.Tukui then
		_G.Tukui[1]['Movers']:RegisterFrame(SMB.Bar)
	elseif PA.ElvUI then
		_G.ElvUI[1]:CreateMover(SMB.Bar, 'SquareMinimapButtonBarMover', 'SquareMinimapButtonBar Anchor', nil, nil, nil, 'ALL,GENERAL')
	end

	SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
	SMB:ScheduleTimer('HandleBlizzardButtons', 7)
end
