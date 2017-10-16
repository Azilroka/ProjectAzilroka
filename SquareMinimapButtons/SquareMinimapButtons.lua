local PA = select(2, ...)

local SMB = LibStub('AceAddon-3.0'):NewAddon('SquareMinimapButtons', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
_G.SquareMinimapButtons = SMB

SMB.Title = '|cffC495DDSquare Minimap Buttons|r'
SMB.Version = 3.42
SMB.Authors = 'Azilroka    Infinitron    Sinaris    Omega'

local strsub, strlen, strfind, ceil = strsub, strlen, strfind, ceil
local tinsert, pairs, unpack, select = tinsert, pairs, unpack, select
local UnitAffectingCombat = UnitAffectingCombat
local Minimap = Minimap
local IsAddOnLoaded = IsAddOnLoaded

local SkinnedMinimapButtons = {}

local ignoreButtons = {
	'GameTimeFrame',
	'HelpOpenTicketButton',
	'MiniMapVoiceChatFrame',
	'TimeManagerClockButton',
	'BattlefieldMinimap',
	'ButtonCollectFrame',
	'GameTimeFrame',
	'TimeManagerClockButton',
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
}

local PartialIgnores = {
	'Node',
	'Note',
	'Pin',
	'POI',
}

local WhiteList = {
	'LibDBIcon',
}

local AcceptedFrames = {
	'BagSync_MinimapButton',
	'VendomaticButtonFrame',
	'MiniMapMailFrame',
}

local AddButtonsToBar = {
	'SmartBuff_MiniMapButton',
}

function SMB:SkinMinimapButton(Button)
	if (not Button or Button.isSkinned) then return end

	local Name = Button:GetName()
	if not Name then return end

	if Button:IsObjectType('Button') then
		local ValidIcon = false

		for i = 1, #WhiteList do
			if strsub(Name, 1, strlen(WhiteList[i])) == WhiteList[i] then ValidIcon = true break end
		end

		if not ValidIcon then
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
		
		if not Name == 'GarrisonLandingPageMinimapButton' then
			Button:SetPushedTexture(nil)
			Button:SetHighlightTexture(nil)
			Button:SetDisabledTexture(nil)
		end
	end
	for i = 1, Button:GetNumRegions() do
		local Region = select(i, Button:GetRegions())
		if Region:GetObjectType() == 'Texture' then
			local Texture = Region:GetTexture()

			if Texture and (strfind(Texture, 'Border') or strfind(Texture, 'Background') or strfind(Texture, 'AlphaMask') or strfind(Texture, 'Highlight')) then
				Region:SetTexture(nil)
				if Name == 'MiniMapTrackingButton' then
					Region:SetTexture('Interface\\Minimap\\Tracking\\None')
					Region:ClearAllPoints()
					Region:SetInside()
				end
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
				elseif Name == 'MiniMapMailFrame' then
					Region:ClearAllPoints()
					Region:SetPoint('CENTER', Button)
				end
				if not (Name == 'MiniMapMailFrame') then
					Region:ClearAllPoints()
					Region:SetInside()
					Region:SetTexCoord(unpack(self.TexCoords))
					Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(self.TexCoords)) end)
				end
				Region:SetDrawLayer('ARTWORK')
				Region.SetPoint = function() return end
			end
		end
	end

	Button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	Button:Size(SMB.db['IconSize'])

	if Name == 'GarrisonLandingPageMinimapButton' then
		Button:SetScale(1)
	end

	Button:SetTemplate()

	Button.isSkinned = true
	tinsert(SkinnedMinimapButtons, Button)
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

	if SMB.db['MoveBlizzard'] and not IsAddOnLoaded('Tukui') then
		MiniMapTrackingButton:Hide()
	end

	local AnchorX, AnchorY, MaxX = 0, 1, SMB.db['ButtonsPerRow']
	local ButtonsPerRow = SMB.db['ButtonsPerRow']
	local NumColumns = ceil(#SkinnedMinimapButtons / ButtonsPerRow)
	local Spacing, Mult = SMB.db['ButtonSpacing'], 1
	local Size = SMB.db['IconSize']
	local ActualButtons, Maxed = 0

	if NumColumns == 1 and ButtonsPerRow > #SkinnedMinimapButtons then
		ButtonsPerRow = #SkinnedMinimapButtons
	end

	for Key, Frame in pairs(SkinnedMinimapButtons) do
		local Name = Frame:GetName()
		local Exception = false
		for _, Button in pairs(AddButtonsToBar) do
			if Name == Button then
				Exception = true
				if Name == 'SmartBuff_MiniMapButton' then
					SMARTBUFF_MinimapButton_CheckPos = function() end
					SMARTBUFF_MinimapButton_OnUpdate = function() end
				end
				if not SMB.db['MoveBlizzard'] and (Name == 'QueueStatusMinimapButton' or Name == 'MiniMapMailFrame') then
					Exception = false
				end
			end
		end
		if SMB.db['MoveBlizzard'] and Name == 'MiniMapTrackingButton' then MiniMapTrackingButton:Show() end
		if Frame:IsVisible() and not (Name == 'QueueStatusMinimapButton' or Name == 'MiniMapMailFrame') or Exception then
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
			Frame:SetFrameLevel(self.Bar:GetFrameLevel() + 2)
			Frame:RegisterForDrag('LeftButton')
			Frame:SetScript('OnDragStart', nil)
			Frame:SetScript('OnDragStop', nil)
			Frame:HookScript('OnEnter', function(self) self:SetBackdropBorderColor(.7, 0, .7) end)
			Frame:HookScript('OnLeave', function(self) self:SetTemplate() end)

			if Maxed then ActualButtons = ButtonsPerRow end
			local BarWidth = (Spacing + ((Size * (ActualButtons * Mult)) + ((Spacing * (ActualButtons - 1)) * Mult) + (Spacing * Mult)))
			local BarHeight = (Spacing + ((Size * (AnchorY * Mult)) + ((Spacing * (AnchorY - 1)) * Mult) + (Spacing * Mult)))
			self.Bar:SetSize(BarWidth, BarHeight)
		end
	end

	self.Bar:Show()
end

function SMB:AddCustomUIButtons()
	if IsAddOnLoaded('Tukui') then
		tinsert(ignoreButtons, 'TukuiMinimapZone')
		tinsert(ignoreButtons, 'TukuiMinimapCoord')
	else
		tinsert(AcceptedFrames, 'MiniMapTrackingButton')
		MiniMapTrackingButton:SetParent(Minimap)
	end
	if IsAddOnLoaded('ElvUI') then
		tinsert(ignoreButtons, 'ElvConfigToggle')
	end
end

function SMB:SetupProfile()
	self.data = LibStub('AceDB-3.0'):New('SquareMinimapButtonsDB', {
		profile = {
			['BarMouseOver'] = false,
			['BarEnabled'] = false,
			['IconSize'] = 27,
			['ButtonsPerRow'] = 12,
			['ButtonSpacing'] = 2,
			['MoveBlizzard'] = false,
		},
	})
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function SMB:PLAYER_LOGIN()
	self:SetupProfile()

	self.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', UIParent)
	self.Bar:SetPoint('RIGHT', UIParent, 'RIGHT', -45, 0)
	self.Bar:SetFrameStrata('LOW')
	self.Bar:SetClampedToScreen(true)
	self.Bar:SetMovable(true)
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

	self.TexCoords = { .1, .9, .1, .9 }

	self:AddCustomUIButtons()
	QueueStatusMinimapButton:SetParent(Minimap)
	GarrisonLandingPageMinimapButton:SetParent(Minimap)

	Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

	if PA.EP then
		PA.EP:RegisterPlugin('ProjectAzilroka', self.GetOptions)
	else
		self:GetOptions()
	end
	self:ScheduleRepeatingTimer('GrabMinimapButtons', 5)
end

SMB:RegisterEvent('PLAYER_LOGIN')


function SMB:GetOptions()
	local Options = {
		type = 'group',
		name = SMB.Title,
		order = 101,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = format('%s |cFFFFFFFF - Version: %s|r', SMB.Title, SMB.Version),
			},
			mbb = {
				order = 1,
				type = 'group',
				name = 'Minimap Buttons / Bar',
				guiInline = true,
				get = function(info) return SMB.db[info[#info]] end,
				set = function(info, value) SMB.db[info[#info]] = value SMB:Update() end, 
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
					-- MoveBlizzard = {
					-- 	order = 3,
					-- 	type = 'toggle',
					-- 	name = 'Move Blizzard Buttons',
					-- 	desc = 'Mail / Dungeon',
					-- },
					IconSize = {
						order = 4,
						type = 'range',
						width = 'full',
						name = 'Icon Size',
						min = 12, max = 48, step = 1,
					},
					ButtonSpacing = {
 						order = 5,
 						type = 'range',
 						width = 'full',
						name = 'Button Spacing',
						min = 0, max = 10, step = 1,
					},
					ButtonsPerRow = {
						order = 6,
						type = 'range',
						width = 'full',
 						name = 'Buttons Per Row',
 						min = 1, max = 12, step = 1,
 					},
  				},
			},
			about = {
				type = 'group',
				name = 'About/Help',
				order = -2,
				args = {
					AuthorHeader = {
						order = 0,
						type = 'header',
						name = 'Authors:',
					},
					Authors = {
						order = 1,
						type = 'description',
						name = SMB.Authors,
						fontSize = 'large',
					},
				},
			},
		},
	}

	if PA.EP then
		local Ace3OptionsPanel = IsAddOnLoaded('ElvUI') and ElvUI[1] or Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.SquareMinimapButton = Options
	end

	PA.ACR:RegisterOptionsTable('SquareMinimapButtons', Options)
	PA.ACD:AddToBlizOptions('SquareMinimapButtons', 'SquareMinimapButtons', nil, 'mbb')
end
