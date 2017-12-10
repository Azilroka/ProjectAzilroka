local PA = _G.ProjectAzilroka
local SMB = PA:NewModule('SquareMinimapButtons', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
_G.SquareMinimapButtons = SMB

SMB.Title = 'Square Minimap Buttons'
SMB.Description = 'Minimap Button Bar / Minimap Button Skinning'
SMB.Authors = 'Azilroka    Infinitron    Sinaris    Omega    Durc'

local strsub, strlen, strfind, ceil = strsub, strlen, strfind, ceil
local tinsert, pairs, unpack, select = tinsert, pairs, unpack, select
local UnitAffectingCombat = UnitAffectingCombat
local Minimap = Minimap
local IsAddOnLoaded = IsAddOnLoaded

SMB.Buttons = {}

local ignoreButtons = {
	'GameTimeFrame',
	'HelpOpenWebTicketButton',
	'MiniMapVoiceChatFrame',
	'TimeManagerClockButton',
	'BattlefieldMinimap',
	'ButtonCollectFrame',
	'GameTimeFrame',
	'QueueStatusMinimapButton',
}

local GenericIgnores = {
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
}

local PartialIgnores = {
	'Node',
	'Note',
	'Pin',
	'POI',
}

local AcceptedFrames = {
	'BagSync_MinimapButton',
	'VendomaticButtonFrame',
}

local AddButtonsToBar = {
	'SmartBuff_MiniMapButton',
}

function SMB:HandleBlizzardButtons()
	if not self.db['BarEnabled'] then return end

	if self.db['HideGarrison'] then
		GarrisonLandingPageMinimapButton:UnregisterAllEvents()
		GarrisonLandingPageMinimapButton:SetParent(self.Hider)
		GarrisonLandingPageMinimapButton:Hide()
	elseif self.db["MoveGarrison"] and not tContains(self.Buttons, GarrisonLandingPageMinimapButton) then
		GarrisonLandingPageMinimapButton:Show()
		GarrisonLandingPageMinimapButton:SetScale(1)
		GarrisonLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
		GarrisonLandingPageMinimapButton:SetScript('OnEnter', nil)
		GarrisonLandingPageMinimapButton:SetScript('OnLeave', nil)

		GarrisonLandingPageMinimapButton:SetNormalTexture(1044517)
		GarrisonLandingPageMinimapButton:GetNormalTexture(1044517):SetTexCoord(unpack(self.TexCoords))
		GarrisonLandingPageMinimapButton:GetNormalTexture():SetInside()

		GarrisonLandingPageMinimapButton:SetPushedTexture(1044517)
		GarrisonLandingPageMinimapButton:GetPushedTexture(1044517):SetTexCoord(unpack(self.TexCoords))
		GarrisonLandingPageMinimapButton:GetPushedTexture():SetInside()

		GarrisonLandingPageMinimapButton:SetHighlightTexture(nil)

		GarrisonLandingPageMinimapButton:HookScript('OnEnter', function(self)
			self:SetBackdropBorderColor(.7, 0, .7)
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		GarrisonLandingPageMinimapButton:HookScript('OnLeave', function(self)
			self:SetTemplate()
			if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		tinsert(self.Buttons, GarrisonLandingPageMinimapButton)
	end

	if self.db["MoveMail"] and not tContains(self.Buttons, MiniMapMailFrame) then
		local Frame = CreateFrame('Frame', 'SMB_MailFrame', self.Bar)
		Frame:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
		Frame:SetTemplate()
		Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
		Frame.Icon:SetPoint('CENTER')
		Frame.Icon:Size(18)
		Frame.Icon:SetTexture(MiniMapMailIcon:GetTexture())
		Frame:EnableMouse(true)
		Frame:HookScript('OnEnter', function(self)
			if HasNewMail() then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
				if GameTooltip:IsOwned(self) then
					MinimapMailFrameUpdate()
				end
			end
			self:SetBackdropBorderColor(.7, 0, .7)
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		Frame:HookScript('OnLeave', function(self)
			GameTooltip:Hide()
			self:SetTemplate()
			if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)
		MiniMapMailFrame:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0)	end)
		MiniMapMailFrame:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)

		-- Hide Icon & Border
		MiniMapMailIcon:Hide()
		MiniMapMailBorder:Hide()

		tinsert(self.Buttons, Frame)
	end

	if self.db["MoveTracker"] and not tContains(self.Buttons, MiniMapTracking) then
		MiniMapTracking.Show = nil

		MiniMapTracking:Show()

		MiniMapTracking:SetParent(self.Bar)
		MiniMapTracking:SetSize(self.db['IconSize'], self.db['IconSize'])

		MiniMapTrackingIcon:ClearAllPoints()
		MiniMapTrackingIcon:SetPoint('CENTER')

		MiniMapTrackingBackground:Hide()
		MiniMapTrackingIconOverlay:Hide()

		MiniMapTrackingButton:SetParent(MinimapTracking)
		MiniMapTrackingButton:ClearAllPoints()
		MiniMapTrackingButton:SetAllPoints(MiniMapTracking)

		MiniMapTrackingButton:SetScript('OnMouseDown', nil)
		MiniMapTrackingButton:SetScript('OnMouseUp', nil)

		MiniMapTrackingButton:HookScript('OnEnter', function(self)
			MiniMapTracking:SetBackdropBorderColor(.7, 0, .7)
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		MiniMapTrackingButton:HookScript('OnLeave', function(self)
			MiniMapTracking:SetTemplate()
			if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		tinsert(self.Buttons, MiniMapTracking)
	end

	if self.db["MoveQueue"] and not tContains(self.Buttons, QueueStatusMinimapButton) then
		local Frame = CreateFrame('Frame', 'SMB_QueueFrame', self.Bar)
		Frame:SetTemplate()
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
			self:SetBackdropBorderColor(.7, 0, .7)
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		Frame:HookScript('OnLeave', function(self)
			self:SetTemplate()
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

		tinsert(self.Buttons, Frame)
	end
end

function SMB:SkinMinimapButton(Button)
	if (not Button) then return end
	if Button.isSkinned then return end

	local Name = Button:GetName()
	if not Name then return end

	if Button:IsObjectType('Button') then
		for i = 1, #ignoreButtons do
			if Name == ignoreButtons[i] then return end
		end

		for i = 1, #GenericIgnores do
			if strsub(Name, 1, strlen(GenericIgnores[i])) == GenericIgnores[i] then return end
		end

		for i = 1, #PartialIgnores do
			if strfind(Name, PartialIgnores[i]) ~= nil then return end
		end
	end
	for i = 1, Button:GetNumRegions() do
		local Region = select(i, Button:GetRegions())
		if Region:GetObjectType() == 'Texture' then
			local Texture = Region:GetTexture()

			if Texture and (strfind(Texture, 'Border') or strfind(Texture, 'Background') or strfind(Texture, 'AlphaMask') or strfind(Texture, 'Highlight')) then
				Region:SetTexture(nil)
			else
				if Name == 'BagSync_MinimapButton' then
					Region:SetTexture('Interface\\AddOns\\BagSync\\media\\icon')
				elseif Name == 'DBMMinimapButton' then
					Region:SetTexture('Interface\\Icons\\INV_Helmet_87')
				elseif Name == 'OutfitterMinimapButton' then
					if Region:GetTexture() == 'Interface\\Addons\\Outfitter\\Textures\\MinimapButton' then
						Region:SetTexture(nil)
					end
				elseif Name == 'SmartBuff_MiniMapButton' then
					Region:SetTexture('Interface\\Icons\\Spell_Nature_Purge')
				elseif Name == 'VendomaticButtonFrame' then
					Region:SetTexture('Interface\\Icons\\INV_Misc_Rabbit_2')
				end
				Region:ClearAllPoints()
				Region:SetInside()
				Region:SetTexCoord(unpack(self.TexCoords))
				Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(self.TexCoords)) end)
				Region:SetDrawLayer('ARTWORK')
				Region.SetPoint = function() return end
			end
		end
	end

	Button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	Button:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
	Button:SetTemplate()
	Button:HookScript('OnEnter', function(self)
		self:SetBackdropBorderColor(.7, 0, .7)
		if SMB.Bar:IsShown() then
			UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
		end
	end)
	Button:HookScript('OnLeave', function(self)
		self:SetTemplate()
		if SMB.Bar:IsShown() and SMB.db['BarMouseOver'] then
			UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
		end
	end)

	Button.isSkinned = true
	tinsert(self.Buttons, Button)
end

function SMB:GrabMinimapButtons()
	if UnitAffectingCombat("player") then return end

	for i = 1, Minimap:GetNumChildren() do
		local object = select(i, Minimap:GetChildren())
		if object then
			if object:IsObjectType('Button') and object:GetName() then
				self:SkinMinimapButton(object)
			end
			for _, frame in pairs(AcceptedFrames) do
				if object:IsObjectType('Frame') and object:GetName() == frame then
					self:SkinMinimapButton(object)
				end
			end
		end
	end

	self:Update()
end

function SMB:Update()
	if not SMB.db['BarEnabled'] then return end

	local AnchorX, AnchorY, MaxX = 0, 1, SMB.db['ButtonsPerRow']
	local ButtonsPerRow = SMB.db['ButtonsPerRow']
	local NumColumns = ceil(#SMB.Buttons / ButtonsPerRow)
	local Spacing, Mult = SMB.db['ButtonSpacing'], 1
	local Size = SMB.db['IconSize']
	local ActualButtons, Maxed = 0

	if NumColumns == 1 and ButtonsPerRow > #SMB.Buttons then
		ButtonsPerRow = #SMB.Buttons
	end

	for _, Frame in pairs(SMB.Buttons) do
		if Frame:IsVisible() then
			AnchorX = AnchorX + 1
			ActualButtons = ActualButtons + 1
			if AnchorX > MaxX then
				AnchorY = AnchorY + 1
				AnchorX = 1
				Maxed = true
			end

			local yOffset = - Spacing - ((Size + Spacing) * (AnchorY - 1))
			local xOffset = Spacing + ((Size + Spacing) * (AnchorX - 1))
			Frame:SetTemplate()
			Frame:SetParent(self.Bar)
			Frame:ClearAllPoints()
			Frame:SetPoint('TOPLEFT', self.Bar, 'TOPLEFT', xOffset, yOffset)
			Frame:SetSize(SMB.db['IconSize'], SMB.db['IconSize'])
			Frame:SetFrameStrata('LOW')
			Frame:SetFrameLevel(self.Bar:GetFrameLevel() + 1)
			Frame:RegisterForDrag('LeftButton')
			Frame:SetScript('OnDragStart', nil)
			Frame:SetScript('OnDragStop', nil)

			if Maxed then ActualButtons = ButtonsPerRow end
			local BarWidth = (Spacing + ((Size * (ActualButtons * Mult)) + ((Spacing * (ActualButtons - 1)) * Mult) + (Spacing * Mult)))
			local BarHeight = (Spacing + ((Size * (AnchorY * Mult)) + ((Spacing * (AnchorY - 1)) * Mult) + (Spacing * Mult)))
			self.Bar:SetSize(BarWidth, BarHeight)
		end
	end

	self.Bar:Show()
	if self.db['BarMouseOver'] then
		UIFrameFadeOut(self.Bar, 0.2, self.Bar:GetAlpha(), 0)
	else
		UIFrameFadeIn(self.Bar, 0.2, self.Bar:GetAlpha(), 1)
	end
end

function SMB:AddCustomUIButtons()
	if PA.Tukui then
		tinsert(ignoreButtons, 'TukuiMinimapZone')
		tinsert(ignoreButtons, 'TukuiMinimapCoord')
	end
end

function SMB:GetOptions()
	local Options = {
		type = 'group',
		name = PA.ModuleColor..SMB.Title,
		desc = SMB.Description,
		order = 211,
		get = function(info) return SMB.db[info[#info]] end,
		set = function(info, value) SMB.db[info[#info]] = value SMB:Update() end,
		args = {
			mbb = {
				order = 1,
				type = 'group',
				name = 'Minimap Buttons / Bar',
				guiInline = true,
				args = {
					BarEnabled = {
						order = 1,
						type = 'toggle',
						name = 'Enable Bar',
					},
					BarMouseOver = {
						order = 2,
						type = 'toggle',
						name = 'Bar MouseOver',
					},
					IconSize = {
						order = 4,
						type = 'range',
						name = 'Icon Size',
						min = 12, max = 48, step = 1,
					},
					ButtonSpacing = {
						order = 5,
						type = 'range',
						name = 'Button Spacing',
						min = 0, max = 10, step = 1,
					},
					ButtonsPerRow = {
						order = 6,
						type = 'range',
						name = 'Buttons Per Row',
						min = 1, max = 12, step = 1,
					},
				},
			},
			blizzard = {
				type = "group",
				name = "Blizzard",
				guiInline = true,
				order = 2,
				args = {
					HideGarrison  = {
						type = "toggle",
						name = "Hide Garrison",
						order = 1,
					},
					MoveGarrison  = {
						type = "toggle",
						name = "Move Garrison Icon",
						order = 2,
					},
					MoveMail  = {
						type = "toggle",
						name = "Move Mail Icon",
						order = 3,
					},
					MoveTracker  = {
						type = "toggle",
						name = "Move Tracker Icon",
						order = 3,
					},
					MoveQueue  = {
						type = "toggle",
						name = "Move Queue Status Icon",
						order = 3,
					},
				},
			},
			AuthorHeader = {
				order = 3,
				type = 'header',
				name = 'Authors:',
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

function SMB:SetupProfile()
	self.db = self.data.profile
end

function SMB:Initialize()
	self.data = PA.ADB:New('SquareMinimapButtonsDB', {
		profile = {
			['BarMouseOver'] = false,
			['BarEnabled'] = false,
			['IconSize'] = 27,
			['ButtonsPerRow'] = 12,
			['ButtonSpacing'] = 2,
			['HideGarrison'] = false,
			['MoveGarrison'] = false,
			['MoveMail'] = false,
			['MoveTracker'] = false,
			['MoveQueue'] = false,
		},
	})
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')

	self:SetupProfile()
	self:GetOptions()

	self.Hider = CreateFrame("Frame", nil, UIParent)

	self.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', UIParent)
	self.Bar:Hide()
	self.Bar:SetPoint('RIGHT', UIParent, 'RIGHT', -45, 0)
	self.Bar:SetFrameStrata('LOW')
	self.Bar:SetClampedToScreen(true)
	self.Bar:SetMovable(true)
	self.Bar:EnableMouse(true)
	self.Bar:SetSize(self.db.IconSize, self.db.IconSize)
	self.Bar:SetTemplate('Transparent', true)

	self.Bar:SetScript('OnEnter', function(self) UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1) end)
	self.Bar:SetScript('OnLeave', function(self)
		if SMB.db['BarMouseOver'] then
			UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		end
	end)

	if IsAddOnLoaded('Tukui') then
		Tukui[1]['Movers']:RegisterFrame(self.Bar)
	elseif IsAddOnLoaded('ElvUI') then
		ElvUI[1]:CreateMover(self.Bar, 'SquareMinimapButtonBarMover', 'SquareMinimapButtonBar Anchor', nil, nil, nil, 'ALL,GENERAL')
	end

	self.TexCoords = { .08, .92, .08, .92 }

	self:AddCustomUIButtons()

	Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

	self:HandleBlizzardButtons()

	self:ScheduleRepeatingTimer('GrabMinimapButtons', 5)
end