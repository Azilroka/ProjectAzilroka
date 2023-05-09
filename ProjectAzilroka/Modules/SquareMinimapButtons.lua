local PA = _G.ProjectAzilroka
local SMB = PA:NewModule('SquareMinimapButtons', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
PA.SMB, _G.SquareMinimapButtons = SMB, SMB

SMB.Title = PA.ACL['|cFF16C3F2Square|r |cFFFFFFFFMinimap Buttons|r']
SMB.Description = PA.ACL['Minimap Button Bar / Minimap Button Skinning']
SMB.Authors = 'Azilroka    Sinaris    Omega    Durc'
SMB.isEnabled = false

local _G = _G
local strfind = strfind
local strmatch = strmatch
local strlower = strlower
local tinsert = tinsert
local pairs = pairs
local unpack = unpack
local tostring = tostring

local InCombatLockdown = InCombatLockdown
local C_PetBattles = C_PetBattles
local Minimap = Minimap

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local HasNewMail = HasNewMail
local MinimapMailFrameUpdate = MinimapMailFrameUpdate

SMB.Buttons = {}

SMB.IgnoreButton = {
	BattlefieldMinimap = true,
	ButtonCollectFrame = true,
	ElvUI_MinimapHolder = true,
	ExpansionLandingPageMinimapButton = true,
	GameTimeFrame = true,
	HelpOpenWebTicketButton = true,
	HelpOpenTicketButton = true,
	InstanceDifficultyFrame = true,
	MinimapBackdrop = true,
	MiniMapMailFrame = true,
	MinimapPanel = true,
	MiniMapTracking = true,
	MiniMapVoiceChatFrame = true,
	MinimapZoomIn = true,
	MinimapZoomOut = true,
	QueueStatusButton = true,
	RecipeRadarMinimapButtonFrame = true,
	SexyMapCustomBackdrop = true,
	SexyMapPingFrame = true,
	TimeManagerClockButton = true,
	TukuiMinimapCoord = true,
	TukuiMinimapZone = true,
	SL_MinimapDifficultyFrame = true, -- S&L Instance Indicator
	SLECoordsHolder = true, -- S&L Coords Holder
	QuestieFrameGroup = true -- Questie
}

local ButtonFunctions = { 'SetParent', 'ClearAllPoints', 'SetPoint', 'SetSize', 'SetScale', 'SetIgnoreParentScale', 'SetFrameStrata', 'SetFrameLevel' }

local RemoveTextureID = { [136430] = true, [136467] = true, [136477] = true, [136468] = true, [130924] = true }
local RemoveTextureFile = { 'interface/characterframe', 'border', 'background', 'alphamask', 'highlight' }

function SMB:RemoveTexture(texture)
	if type(texture) == 'string' then
		for _, path in next, RemoveTextureFile do
			if strfind(texture, path) or (strfind(texture, 'interface/minimap') and not strfind(texture, 'interface/minimap/tracking')) then
				return true
			end
		end
	else
		return RemoveTextureID[texture]
	end
end

function SMB:LockButton(Button)
	for _, Function in pairs(ButtonFunctions) do
		Button[Function] = PA.Noop
	end

	if Button.SetFixedFrameStrata then Button:SetFixedFrameStrata(true) end
	if Button.SetFixedFrameLevel then Button:SetFixedFrameLevel(true) end
end

function SMB:UnlockButton(Button)
	for _, Function in pairs(ButtonFunctions) do
		Button[Function] = nil
	end

	if Button.SetFixedFrameStrata then Button:SetFixedFrameStrata(false) end
	if Button.SetFixedFrameLevel then Button:SetFixedFrameLevel(false) end
end

function SMB:ToggleBar_FrameStrataLevel(value)
	if SMB.Bar.SetFixedFrameStrata then SMB.Bar:SetFixedFrameStrata(value) end
	if SMB.Bar.SetFixedFrameLevel then SMB.Bar:SetFixedFrameLevel(value) end
end

function SMB:HandleBlizzardButtons()
	if not SMB.db.BarEnabled then return end
	local Size = SMB.db.IconSize
	local MailFrameVersion = PA.Retail and _G.MinimapCluster.MailFrame or _G.MiniMapMailFrame

	if SMB.db.MoveMail and MailFrameVersion and not MailFrameVersion.SMB then
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

		MailFrameVersion:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0) end)
		MailFrameVersion:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)
		MailFrameVersion:EnableMouse(false)

		if MailFrameVersion:IsShown() then
			Frame.Icon:SetVertexColor(0, 1, 0)
		end

		-- Hide Icon & Border
		_G.MiniMapMailIcon:Hide()
		--_G.MiniMapMailBorder:Hide()

		if SMB.db.Shadows then
			PA:CreateShadow(Frame)
		end

		MailFrameVersion.SMB = true
		tinsert(SMB.Buttons, Frame)
	end

	if PA.Retail then
		if SMB.db.HideGarrison then
			_G.ExpansionLandingPageMinimapButton:UnregisterAllEvents()
			_G.ExpansionLandingPageMinimapButton:SetParent(SMB.Hider)
			_G.ExpansionLandingPageMinimapButton:Hide()
		elseif SMB.db.MoveGarrison and (C_Garrison.GetLandingPageGarrisonType() > 0) and not _G.ExpansionLandingPageMinimapButton.SMB then
			Mixin(ExpansionLandingPageMinimapButton, BackdropTemplateMixin)
			_G.ExpansionLandingPageMinimapButton:SetParent(Minimap)
			_G.ExpansionLandingPageMinimapButton:UnregisterEvent('GARRISON_HIDE_LANDING_PAGE')
			_G.ExpansionLandingPageMinimapButton:Show()
			_G.ExpansionLandingPageMinimapButton:SetScale(1)
			_G.ExpansionLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
			_G.ExpansionLandingPageMinimapButton:SetScript('OnEnter', function(s)
				s:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			_G.ExpansionLandingPageMinimapButton:SetScript('OnLeave', function(s)
				PA:SetTemplate(s)
				if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			_G.ExpansionLandingPageMinimapButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(_G.ExpansionLandingPageMinimapButton)
			end

			tinsert(SMB.Buttons, _G.ExpansionLandingPageMinimapButton)
		end

		if SMB.db.MoveTracker and not _G.MinimapCluster.Tracking.Button.SMB then
			--_G.MinimapCluster.Tracking.Show = nil

			_G.MinimapCluster.Tracking.Button:Show()
			PA:SetTemplate(_G.MinimapCluster.Tracking.Button)

			_G.MinimapCluster.Tracking.Button:SetParent(SMB.Bar)
			_G.MinimapCluster.Tracking.Button:SetSize(Size, Size)

			--_G.MinimapCluster.Tracking.Icon:ClearAllPoints()
			--_G.MinimapCluster.Tracking.Icon:SetPoint('CENTER')

			_G.MinimapCluster.Tracking.Background:SetAlpha(0)
			--_G.MinimapCluster.Tracking.IconOverlay:SetAlpha(0)
			_G.MinimapCluster.Tracking.Button:SetAlpha(0)

			_G.MinimapCluster.Tracking.Button:SetParent(_G.MinimapCluster.Tracking)
			_G.MinimapCluster.Tracking.Button:ClearAllPoints()
			_G.MinimapCluster.Tracking.Button:SetAllPoints(_G.MinimapCluster.Tracking)

			_G.MinimapCluster.Tracking.Button:SetScript('OnMouseDown', nil)
			_G.MinimapCluster.Tracking.Button:SetScript('OnMouseUp', nil)

			_G.MinimapCluster.Tracking.Button:HookScript('OnEnter', function()
				_G.MinimapCluster.Tracking.Button:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			_G.MinimapCluster.Tracking.Button:HookScript('OnLeave', function()
				PA:SetTemplate(_G.MinimapCluster.Tracking.Button)
				if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			_G.MinimapCluster.Tracking.Button.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(_G.MinimapCluster.Tracking.Button)
			end

			tinsert(SMB.Buttons, _G.MinimapCluster.Tracking.Button)
		end

		if SMB.db["MoveQueue"] and not _G.QueueStatusButton.SMB then
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

			_G.QueueStatusButton:SetParent(SMB.Bar)
			_G.QueueStatusButton:SetFrameLevel(Frame:GetFrameLevel() + 2)
			_G.QueueStatusButton:ClearAllPoints()
			_G.QueueStatusButton:SetPoint("CENTER", Frame, "CENTER", 0, 0)

			--d_G.QueueStatusButton:SetHighlightTexture(nil)

			_G.QueueStatusButton:HookScript('OnShow', function() Frame:EnableMouse(false) end)
			_G.QueueStatusButton:HookScript('PostClick', _G.QueueStatusButton.OnLeave)
			_G.QueueStatusButton:HookScript('OnHide', function() Frame:EnableMouse(true) end)

			_G.QueueStatusButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(Frame)
			end

			tinsert(SMB.Buttons, Frame)
		end
	else
		-- MiniMapTrackingFrame
		if SMB.db.MoveGameTimeFrame and not _G.GameTimeFrame.SMB then
			PA:SetTemplate(_G.GameTimeFrame)
			_G.GameTimeTexture:SetTexture('')

			_G.GameTimeFrame.SMB = true
			tinsert(SMB.Buttons, _G.GameTimeFrame)
		end
	end

	if not InCombatLockdown() then
		SMB:Update()
	end
end

function SMB:SkinMinimapButton(button)
	for _, frames in next, { button, button:GetChildren() } do
		for _, region in next, { frames:GetRegions() } do
			if region.IsObjectType and region:IsObjectType('Texture') then
				local texture = region.GetTextureFileID and region:GetTextureFileID()
				if not texture then
					texture = strlower(tostring(region:GetTexture()))
				end

				if SMB:RemoveTexture(texture) then
					region:SetTexture()
					region:SetAlpha(0)
				else
					region:ClearAllPoints()
					region:SetDrawLayer('ARTWORK')
					PA:SetInside(region)

					local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = region:GetTexCoord()
					if ULx == 0 and ULy == 0 and LLx == 0 and LLy == 1 and URx == 1 and URy == 0 and LRx == 1 and LRy == 1 then
						region:SetTexCoord(unpack(PA.TexCoords))
						button:HookScript('OnLeave', function() region:SetTexCoord(unpack(PA.TexCoords)) end)
					end

					region.SetPoint = function() return end
				end
			end
		end
	end

	button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	button:SetFrameStrata(Minimap:GetFrameStrata())
	button:SetSize(SMB.db.IconSize, SMB.db.IconSize)

	if not button.ignoreTemplate then
		PA:SetTemplate(button)

		if SMB.db.Shadows then
			PA:CreateShadow(button)
		end
	end

	button:HookScript('OnEnter', function()
		if SMB.Bar:IsShown() then
			UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
		end
	end)
	button:HookScript('OnLeave', function(s)
		PA:SetTemplate(s)
		if SMB.Bar:IsShown() and SMB.db.BarMouseOver then
			UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
		end
	end)

	button.isSkinned = true
	tinsert(SMB.Buttons, button)
end


function SMB:GrabMinimapButtons(forceUpdate)
	if (InCombatLockdown() or C_PetBattles and C_PetBattles.IsInBattle()) then return end

	local UpdateBar = forceUpdate

	for _, btn in ipairs({Minimap:GetChildren()}) do
		local name = btn.GetName and btn:GetName() or btn.name

		if not (not btn:IsObjectType('Button') or -- Don't want frames only buttons
			SMB.IgnoreButton[name] or -- Ignored by default
			btn.isSkinned or -- Skinned buttons
			btn.uiMapID or -- HereBeDragons | HandyNotes
			btn.arrow or -- HandyNotes | TomCat Tours
			btn.texture or -- HandyNotes
			(btn.waypoint or btn.isZygorWaypoint) or -- Zygor
			(btn.nodeID or btn.title and btn.x and btn.y) or -- GatherMate2
			(btn.data and btn.data.UiMapID) or (name and strmatch(name, "^QuestieFrame")) or -- Questie
			(btn.uid or btn.point and btn.point.uid) or -- TomTom
			not name and not btn.icon -- don't want unnamed ones
			)
		then
			SMB:SkinMinimapButton(btn)
			UpdateBar = true
		end
	end

	if UpdateBar then
		SMB:Update()
	end
end

function SMB:Update()
	if not SMB.db.BarEnabled or not SMB.db.Enable then return end

	local AnchorX, AnchorY = 0, 1
	local ButtonsPerRow = SMB.db.ButtonsPerRow or 12
	local Spacing = SMB.db.ButtonSpacing or 2
	local Size = SMB.db.IconSize or 27
	local ActualButtons, Maxed = 0

	local Anchor, DirMult = 'TOPLEFT', 1

	if SMB.db.ReverseDirection then
		Anchor, DirMult = 'TOPRIGHT', -1
	end

	SMB:ToggleBar_FrameStrataLevel(false)
	SMB.Bar:SetFrameStrata(SMB.db.Strata)
	SMB.Bar:SetFrameLevel(SMB.db.Level)
	SMB:ToggleBar_FrameStrataLevel(true)

	for _, Button in next, SMB.Buttons do
		if Button:IsVisible() then
			AnchorX, ActualButtons = AnchorX + 1, ActualButtons + 1

			if (AnchorX % (ButtonsPerRow + 1)) == 0 then
				AnchorY, AnchorX, Maxed = AnchorY + 1, 1, true
			end

			SMB:UnlockButton(Button)

			PA:SetTemplate(Button)

			Button:SetParent(SMB.Bar)
			Button:SetIgnoreParentScale(false)
			Button:ClearAllPoints()
			Button:SetPoint(Anchor, SMB.Bar, Anchor, DirMult * (Spacing + ((Size + Spacing) * (AnchorX - 1))), (- Spacing - ((Size + Spacing) * (AnchorY - 1))))
			Button:SetSize(Size, Size)
			Button:SetScale(1)
			Button:SetFrameStrata(SMB.db.Strata)
			Button:SetFrameLevel(SMB.db.Level + 1)
			Button:SetScript('OnDragStart', nil)
			Button:SetScript('OnDragStop', nil)

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
		UnregisterStateDriver(SMB.Bar, 'visibility')
		SMB.Bar:Hide()
	else
		RegisterStateDriver(SMB.Bar, 'visibility', SMB.db.Visibility)
		SMB.Bar:Show()
	end

	if SMB.db.BarMouseOver then
		UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
	else
		UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
	end
end

function SMB:GetOptions()
	local SquareMinimapButtons = PA.ACH:Group(SMB.Title, SMB.Description, nil, nil, function(info) return SMB.db[info[#info]] end, function(info, value) SMB.db[info[#info]] = value SMB:Update() end)
	PA.Options.args.SquareMinimapButtons = SquareMinimapButtons

	SquareMinimapButtons.args.Description = PA.ACH:Description(SMB.Description, 0)
	SquareMinimapButtons.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) SMB.db[info[#info]] = value if (not SMB.isEnabled) then SMB:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)
	SquareMinimapButtons.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	SquareMinimapButtons.args.General.inline = true

	SquareMinimapButtons.args.General.args.MBB = PA.ACH:Group(PA.ACL['Minimap Buttons / Bar'], nil, 1)
	SquareMinimapButtons.args.General.args.MBB.inline = true
	SquareMinimapButtons.args.General.args.MBB.args.BarEnabled = PA.ACH:Toggle(PA.ACL['Enable Bar'], nil, 1)
	SquareMinimapButtons.args.General.args.MBB.args.BarMouseOver = PA.ACH:Toggle(PA.ACL['Bar MouseOver'], nil, 2)
	SquareMinimapButtons.args.General.args.MBB.args.Backdrop = PA.ACH:Toggle(PA.ACL['Bar Backdrop'], nil, 3)
	SquareMinimapButtons.args.General.args.MBB.args.IconSize = PA.ACH:Range(PA.ACL['Icon Size'], nil, 4, { min = 12, max = 48, step = 1 })
	SquareMinimapButtons.args.General.args.MBB.args.ButtonSpacing = PA.ACH:Range(PA.ACL['Button Spacing'], nil, 5, { min = -1, max = 10, step = 1 })
	SquareMinimapButtons.args.General.args.MBB.args.ButtonsPerRow = PA.ACH:Range(PA.ACL['Buttons Per Row'], nil, 6, { min = 1, max = 100, step = 1 })
	SquareMinimapButtons.args.General.args.MBB.args.Shadows = PA.ACH:Toggle(PA.ACL['Shadows'], nil, 7)
	SquareMinimapButtons.args.General.args.MBB.args.ReverseDirection = PA.ACH:Toggle(PA.ACL['Reverse Direction'], nil, 8)
	SquareMinimapButtons.args.General.args.Strata = PA.ACH:Select(PA.ACL['Frame Strata'], nil, 3, { BACKGROUND = 'BACKGROUND', LOW = 'LOW', MEDIUM = 'MEDIUM', HIGH = 'HIGH', DIALOG = 'DIALOG', FULLSCREEN = 'FULLSCREEN', FULLSCREEN_DIALOG = 'FULLSCREEN_DIALOG', TOOLTIP = 'TOOLTIP' })
	SquareMinimapButtons.args.General.args.Level = PA.ACH:Range(PA.ACL['Frame Level'], nil, 4, { min = 0, max = 255, step = 1 })

	SquareMinimapButtons.args.General.args.MBB.args.Visibility = PA.ACH:Input(PA.ACL['Visibility'], nil, 12, nil, 'double')

	SquareMinimapButtons.args.General.args.Blizzard = PA.ACH:Group(PA.ACL['Blizzard'], nil, 2, nil, nil, function(info, value) SMB.db[info[#info]] = value SMB:HandleBlizzardButtons() end)
	SquareMinimapButtons.args.General.args.Blizzard.inline = true
	SquareMinimapButtons.args.General.args.Blizzard.args.HideGarrison = PA.ACH:Toggle(PA.ACL['Hide Garrison'], nil, nil, nil, nil, nil, nil, nil, function() return SMB.db.MoveGarrison end, function() return PA.Classic end)
	SquareMinimapButtons.args.General.args.Blizzard.args.MoveGarrison = PA.ACH:Toggle(PA.ACL['Move Garrison Icon'], nil, nil, nil, nil, nil, nil, nil, function() return SMB.db.HideGarrison end, function() return PA.Classic end)
	SquareMinimapButtons.args.General.args.Blizzard.args.MoveMail = PA.ACH:Toggle(PA.ACL['Move Mail Icon'])
	SquareMinimapButtons.args.General.args.Blizzard.args.MoveGameTimeFrame = PA.ACH:Toggle(PA.ACL['Move Game Time Frame'], nil, nil, nil, nil, nil, nil, nil, nil, function() return PA.Retail end)
	SquareMinimapButtons.args.General.args.Blizzard.args.MoveTracker = PA.ACH:Toggle(PA.ACL['Move Tracker Icon'], nil, nil, nil, nil, nil, nil, nil, nil, function() return PA.Classic end)
	SquareMinimapButtons.args.General.args.Blizzard.args.MoveQueue = PA.ACH:Toggle(PA.ACL['Move Queue Status Icon'], nil, nil, nil, nil, nil, nil, nil, nil, function() return PA.Classic end)

	SquareMinimapButtons.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	SquareMinimapButtons.args.Authors = PA.ACH:Description(SMB.Authors, -1, 'large')
end

function SMB:BuildProfile()
	PA.Defaults.profile.SquareMinimapButtons = {
		Enable = true,
		Strata = 'MEDIUM',
		Level = 12,
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
		Visibility = '[petbattle] hide; show'
	}
end

function SMB:UpdateSettings()
	SMB.db = PA.db.SquareMinimapButtons
end

function SMB:PLAYER_ENTERING_WORLD()
	SMB:GrabMinimapButtons(true)
end

function SMB:Initialize()
	SMB:UpdateSettings()

	if SMB.db.Enable ~= true then
		return
	end

	SMB.isEnabled = true

	SMB.Hider = CreateFrame("Frame", nil, _G.UIParent)

	SMB.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', _G.UIParent)
	SMB.Bar:Hide()
	SMB.Bar:SetPoint('RIGHT', _G.UIParent, 'RIGHT', -45, 0)
	SMB.Bar:SetClampedToScreen(true)
	SMB.Bar:SetMovable(true)
	SMB.Bar:EnableMouse(true)
	SMB.Bar:SetSize(SMB.db.IconSize, SMB.db.IconSize)
	PA:SetTemplate(SMB.Bar)

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

	SMB:RegisterEvent("PLAYER_ENTERING_WORLD")
	SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
	SMB:ScheduleTimer('HandleBlizzardButtons', 7)
end
