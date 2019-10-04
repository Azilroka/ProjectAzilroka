local PA = _G.ProjectAzilroka
local SMB = PA:NewModule('SquareMinimapButtons', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
PA.SMB, _G.SquareMinimapButtons = SMB, SMB

SMB.Title = '|cFF16C3F2Square|r |cFFFFFFFFMinimap Buttons|r'
SMB.Description = 'Minimap Button Bar / Minimap Button Skinning'
SMB.Authors = 'Azilroka    Whiro    Sinaris    Omega    Durc'

local strsub, strlen, strfind, ceil = strsub, strlen, strfind, ceil
local tinsert, pairs, unpack, select, tContains = tinsert, pairs, unpack, select, tContains
local InCombatLockdown, C_PetBattles = InCombatLockdown, C_PetBattles
local Minimap = Minimap

SMB.Buttons = {}

SMB.IgnoreButton = {
	'GameTimeFrame',
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

SMB.PartialIgnore = { 'Node', 'Note', 'Pin', 'POI' }

SMB.OverrideTexture = {
	BagSync_MinimapButton = [[Interface\AddOns\BagSync\media\icon]],
	DBMMinimapButton = [[Interface\Icons\INV_Helmet_87]],
	SmartBuff_MiniMapButton = [[Interface\Icons\Spell_Nature_Purge]],
	VendomaticButtonFrame = [[Interface\Icons\INV_Misc_Rabbit_2]],
	OutfitterMinimapButton = '',
	RecipeRadar_MinimapButton = [[Interface\Icons\INV_Scroll_03]]
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

function SMB:HandleBlizzardButtons()
	if not self.db['BarEnabled'] then return end

	if self.db["MoveMail"] and not MiniMapMailFrame.SMB then
		local Frame = CreateFrame('Frame', 'SMB_MailFrame', self.Bar)
		Frame:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
		PA:SetTemplate(Frame)
		Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
		Frame.Icon:SetPoint('CENTER')
		Frame.Icon:SetSize(18, 18)
		Frame.Icon:SetTexture(MiniMapMailIcon:GetTexture())
		Frame:EnableMouse(true)
		Frame:HookScript('OnEnter', function(self)
			if HasNewMail() then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
				if GameTooltip:IsOwned(self) then
					MinimapMailFrameUpdate()
				end
			end
			self:SetBackdropBorderColor(unpack(PA.ClassColor))
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		Frame:HookScript('OnLeave', function(self)
			GameTooltip:Hide()
			PA:SetTemplate(self)
			if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		MiniMapMailFrame:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0)	end)
		MiniMapMailFrame:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)

		if MiniMapMailFrame:IsShown() then
			Frame.Icon:SetVertexColor(0, 1, 0)
		end

		-- Hide Icon & Border
		MiniMapMailIcon:Hide()
		MiniMapMailBorder:Hide()

		if SMB.db.Shadows then
			PA:CreateShadow(Frame)
		end

		MiniMapMailFrame.SMB = true
		tinsert(self.Buttons, Frame)
	end

	if PA.Retail then
		if self.db['HideGarrison'] then
			GarrisonLandingPageMinimapButton:UnregisterAllEvents()
			GarrisonLandingPageMinimapButton:SetParent(self.Hider)
			GarrisonLandingPageMinimapButton:Hide()
		elseif self.db["MoveGarrison"] and not GarrisonLandingPageMinimapButton.SMB then
			GarrisonLandingPageMinimapButton:SetParent(Minimap)
			GarrisonLandingPageMinimapButton_OnLoad(GarrisonLandingPageMinimapButton)
			GarrisonLandingPageMinimapButton_UpdateIcon(GarrisonLandingPageMinimapButton)
			GarrisonLandingPageMinimapButton:Show()
			GarrisonLandingPageMinimapButton:SetScale(1)
			GarrisonLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
			GarrisonLandingPageMinimapButton:SetScript('OnEnter', function(self)
				self:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			GarrisonLandingPageMinimapButton:SetScript('OnLeave', function(self)
				PA:SetTemplate(self)
				if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			GarrisonLandingPageMinimapButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(GarrisonLandingPageMinimapButton)
			end

			tinsert(self.Buttons, GarrisonLandingPageMinimapButton)
		end

		if self.db["MoveTracker"] and not MiniMapTrackingButton.SMB then
			MiniMapTracking.Show = nil

			MiniMapTracking:Show()

			MiniMapTracking:SetParent(self.Bar)
			MiniMapTracking:SetSize(self.db['IconSize'], self.db['IconSize'])

			MiniMapTrackingIcon:ClearAllPoints()
			MiniMapTrackingIcon:SetPoint('CENTER')

			MiniMapTrackingBackground:SetAlpha(0)
			MiniMapTrackingIconOverlay:SetAlpha(0)
			MiniMapTrackingButton:SetAlpha(0)

			MiniMapTrackingButton:SetParent(MinimapTracking)
			MiniMapTrackingButton:ClearAllPoints()
			MiniMapTrackingButton:SetAllPoints(MiniMapTracking)

			MiniMapTrackingButton:SetScript('OnMouseDown', nil)
			MiniMapTrackingButton:SetScript('OnMouseUp', nil)

			MiniMapTrackingButton:HookScript('OnEnter', function(self)
				MiniMapTracking:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			MiniMapTrackingButton:HookScript('OnLeave', function(self)
				PA:SetTemplate(MiniMapTracking)
				if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			MiniMapTrackingButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(MiniMapTracking)
			end

			tinsert(self.Buttons, MiniMapTracking)
		end

		if self.db["MoveQueue"] and not QueueStatusMinimapButton.SMB then
			local Frame = CreateFrame('Frame', 'SMB_QueueFrame', self.Bar)
			PA:SetTemplate(Frame)
			Frame:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
			Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
			Frame.Icon:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
			Frame.Icon:SetPoint('CENTER')
			Frame.Icon:SetTexture([[Interface\LFGFrame\LFG-Eye]])
			Frame.Icon:SetTexCoord(0, 64 / 512, 0, 64 / 256)
			Frame:SetScript('OnMouseDown', function()
				if PVEFrame:IsShown() then
					HideUIPanel(PVEFrame)
				else
					ShowUIPanel(PVEFrame)
					GroupFinderFrame_ShowGroupFrame()
				end
			end)
			Frame:HookScript('OnEnter', function(self)
				self:SetBackdropBorderColor(unpack(PA.ClassColor))
				if SMB.Bar:IsShown() then
					UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
				end
			end)
			Frame:HookScript('OnLeave', function(self)
				PA:SetTemplate(self)
				if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
					UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
				end
			end)

			QueueStatusMinimapButton:SetParent(self.Bar)
			QueueStatusMinimapButton:SetFrameLevel(Frame:GetFrameLevel() + 2)
			QueueStatusMinimapButton:ClearAllPoints()
			QueueStatusMinimapButton:SetPoint("CENTER", Frame, "CENTER", 0, 0)

			QueueStatusMinimapButton:SetHighlightTexture(nil)

			QueueStatusMinimapButton:HookScript('OnShow', function(self)
				Frame:EnableMouse(false)
			end)
			QueueStatusMinimapButton:HookScript('PostClick', QueueStatusMinimapButton_OnLeave)
			QueueStatusMinimapButton:HookScript('OnHide', function(self)
				Frame:EnableMouse(true)
			end)

			QueueStatusMinimapButton.SMB = true

			if SMB.db.Shadows then
				PA:CreateShadow(Frame)
			end

			tinsert(self.Buttons, Frame)
		end
	else
		-- MiniMapTrackingFrame
		-- GameTimeFrame
	end

	self:Update()
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
		if strfind(Name, SMB.PartialIgnore[i]) ~= nil then return end
	end

	for i = 1, Button:GetNumRegions() do
		local Region = select(i, Button:GetRegions())
		if Region.IsObjectType and Region:IsObjectType('Texture') then
			local Texture = Region.GetTextureFileID and Region:GetTextureFileID()

			if RemoveTextureID[Texture] then
				Region:SetTexture()
			else
				Texture = strlower(tostring(Region:GetTexture()))
				if RemoveTextureFile[Texture] or (strfind(Texture, [[interface\characterframe]]) or (strfind(Texture, [[interface\minimap]]) and not strfind(Texture, [[interface\minimap\tracking\]])) or strfind(Texture, 'border') or strfind(Texture, 'background') or strfind(Texture, 'alphamask') or strfind(Texture, 'highlight')) then
					Region:SetTexture()
					Region:SetAlpha(0)
				else
					if SMB.OverrideTexture[Name] then
						Region:SetTexture(SMB.OverrideTexture[Name])
					end

					Region:ClearAllPoints()
					Region:SetDrawLayer('ARTWORK')
					PA:SetInside(Region)

					if not Button.ignoreCrop then
						Region:SetTexCoord(unpack(self.TexCoords))
						Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(self.TexCoords)) end)
					end

					Region.SetPoint = function() return end
				end
			end
		end
	end

	Button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	Button:SetFrameStrata(Minimap:GetFrameStrata())
	Button:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])

	if not Button.ignoreTemplate then
		PA:SetTemplate(Button)

		if SMB.db.Shadows then
			PA:CreateShadow(Button)
		end
	end

	Button:HookScript('OnEnter', function(self)
		if SMB.Bar:IsShown() then
			UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
		end
	end)
	Button:HookScript('OnLeave', function(self)
		PA:SetTemplate(self)
		if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
			UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
		end
	end)

	Button.isSkinned = true
	tinsert(self.Buttons, Button)
end

function SMB:GrabMinimapButtons()
	if (InCombatLockdown() or C_PetBattles and C_PetBattles.IsInBattle()) then return end

	for _, Button in pairs(SMB.UnrulyButtons) do
		if _G[Button] then
			_G[Button]:SetParent(Minimap)
		end
	end

	for _, Frame in pairs({ Minimap, MinimapBackdrop }) do
		local NumChildren = Frame:GetNumChildren()
		if NumChildren < (Frame.SMBNumChildren or 0) then return end
		for i = 1, NumChildren do
			local object = select(i, Frame:GetChildren())
			if object then
				local name = object:GetName()
				local width = object:GetWidth()
				if name and width > 15 and width < 40 and (object:IsObjectType('Button') or object:IsObjectType('Frame')) then
					self:SkinMinimapButton(object)
				end
			end
		end

		Frame.SMBNumChildren = NumChildren
	end

	self:Update()
end

function SMB:Update()
	if not SMB.db['BarEnabled'] then return end

	local AnchorX, AnchorY = 0, 1
	local ButtonsPerRow = SMB.db['ButtonsPerRow'] or 12
	local Spacing = SMB.db['ButtonSpacing'] or 2
	local Size = SMB.db['IconSize'] or 27
	local ActualButtons, Maxed = 0

	local Anchor, DirMult = 'TOPLEFT', 1

	if SMB.db['ReverseDirection'] then
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

			Button:SetParent(self.Bar)
			Button:ClearAllPoints()
			Button:SetPoint(Anchor, self.Bar, Anchor, DirMult * (Spacing + ((Size + Spacing) * (AnchorX - 1))), (- Spacing - ((Size + Spacing) * (AnchorY - 1))))
			Button:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
			Button:SetScale(1)
			Button:SetFrameStrata('MEDIUM')
			Button:SetFrameLevel(self.Bar:GetFrameLevel() + 1)
			Button:SetScript('OnDragStart', nil)
			Button:SetScript('OnDragStop', nil)
			--Button:SetScript('OnEvent', nil)

			SMB:LockButton(Button)

			if Maxed then ActualButtons = ButtonsPerRow end
		end
	end

	local BarWidth = Spacing + (Size * ActualButtons) + (Spacing * (ActualButtons - 1)) + Spacing
	local BarHeight = Spacing + (Size * AnchorY) + (Spacing * (AnchorY - 1)) + Spacing

	self.Bar:SetSize(BarWidth, BarHeight)

	if self.db.Backdrop then
		PA:SetTemplate(self.Bar)
	else
		self.Bar:SetBackdrop(nil)
	end

	if ActualButtons == 0 then
		self.Bar:Hide()
	else
		self.Bar:Show()
	end

	if self.db['BarMouseOver'] then
		UIFrameFadeOut(self.Bar, 0.2, self.Bar:GetAlpha(), 0)
	else
		UIFrameFadeIn(self.Bar, 0.2, self.Bar:GetAlpha(), 1)
	end
end

function SMB:GetOptions()
	local Options = {
		type = 'group',
		name = SMB.Title,
		desc = SMB.Description,
		get = function(info) return SMB.db[info[#info]] end,
		set = function(info, value) SMB.db[info[#info]] = value SMB:Update() end,
		args = {
			Header = {
				order = 1,
				type = 'header',
				name = PA:Color(SMB.Title),
			},
			mbb = {
				order = 2,
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
			blizzard = {
				type = 'group',
				name = PA.ACL['Blizzard'],
				guiInline = true,
				set = function(info, value) SMB.db[info[#info]] = value SMB:Update() SMB:HandleBlizzardButtons() end,
				order = 2,
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
			AuthorHeader = {
				order = 3,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = 4,
				type = 'description',
				name = SMB.Authors,
				fontSize = 'large',
			},
		},
	}

	PA.Options.args.SquareMinimapButton = Options
end

function SMB:BuildProfile()
	PA.Defaults.profile['SquareMinimapButtons'] = {
		['Enable'] = true,
		['BarMouseOver'] = false,
		['BarEnabled'] = true,
		['Backdrop'] = true,
		['IconSize'] = 20,
		['ButtonsPerRow'] = 12,
		['ButtonSpacing'] = 2,
		['HideGarrison'] = false,
		['MoveGarrison'] = true,
		['MoveMail'] = true,
		['MoveTracker'] = true,
		['MoveQueue'] = true,
		['Shadows'] = true,
		['ReverseDirection'] = false,
	}

	PA.Options.args.general.args.SquareMinimapButtons = {
		type = 'toggle',
		name = SMB.Title,
		desc = SMB.Description,
	}
end

function SMB:Initialize()
	SMB.db = PA.db['SquareMinimapButtons']

	if SMB.db.Enable ~= true then
		return
	end

	if PA.ElvUI and PA.SLE then
		if ElvUI[1].private.sle.minimap.mapicons.enable then
			StaticPopupDialogs["PROJECTAZILROKA"].text = 'Square Minimap Buttons and S&L MiniMap Buttons are incompatible. You will have to choose one. This will reload the interface.'
			StaticPopupDialogs["PROJECTAZILROKA"].button1 = 'Square Minimap Buttons'
			StaticPopupDialogs["PROJECTAZILROKA"].button2 = 'S&L MiniMap Buttons'
			StaticPopupDialogs["PROJECTAZILROKA"].OnAccept = function() ElvUI[1].private.sle.minimap.mapicons.enable = false ReloadUI() end
			StaticPopupDialogs["PROJECTAZILROKA"].OnCancel = function() PA.db['SquareMinimapButtons']['Enable'] = false ReloadUI() end
			StaticPopup_Show("PROJECTAZILROKA")
			return
		end
	end

	SMB:GetOptions()

	SMB.Hider = CreateFrame("Frame", nil, UIParent)

	SMB.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', UIParent)
	SMB.Bar:Hide()
	SMB.Bar:SetPoint('RIGHT', UIParent, 'RIGHT', -45, 0)
	SMB.Bar:SetFrameStrata('MEDIUM')
	SMB.Bar:SetFrameLevel(1)
	SMB.Bar:SetClampedToScreen(true)
	SMB.Bar:SetMovable(true)
	SMB.Bar:EnableMouse(true)
	SMB.Bar:SetSize(SMB.db.IconSize, SMB.db.IconSize)

	SMB.Bar:SetScript('OnEnter', function(self) UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1) end)
	SMB.Bar:SetScript('OnLeave', function(self)
		if SMB.db['BarMouseOver'] then
			UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		end
	end)

	if PA.Tukui then
		Tukui[1]['Movers']:RegisterFrame(SMB.Bar)
	elseif PA.ElvUI then
		ElvUI[1]:CreateMover(SMB.Bar, 'SquareMinimapButtonBarMover', 'SquareMinimapButtonBar Anchor', nil, nil, nil, 'ALL,GENERAL')
	end

	SMB.TexCoords = PA.TexCoords

	SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
	SMB:ScheduleTimer('HandleBlizzardButtons', 7)
end
