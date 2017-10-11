local DragonOverlay = CreateFrame('Frame', 'DragonOverlay', UIParent)
local EP, TargetFrame

DragonOverlayOptions = {
	['worldboss'] = 'Chromatic',
	['elite'] = 'HeavenlyGolden',
	['rare'] = 'Onyx',
	['rareelite'] = 'HeavenlyOnyx',
	['ClassIcon'] = false,
	['FlipDragon'] = false,
}

DragonOverlay.Textures = {
	['Azure'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\Azure',
	['Chromatic'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\Chromatic',
	['Crimson'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\Crimson',
	['Golden'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\Golden',
	['Jade'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\Jade',
	['Onyx'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\Onyx',
	['HeavenlyBlue'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\HeavenlyBlue',
	['HeavenlyCrimson'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\HeavenlyCrimson',
	['HeavenlyGolden'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\HeavenlyGolden',
	['HeavenlyJade'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\HeavenlyJade',
	['HeavenlyOnyx'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\HeavenlyOnyx',
	['ClassicElite'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\ClassicElite',
	['ClassicRareElite'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\ClassicRareElite',
	['ClassicRare'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\ClassicRare',
	['ClassicBoss'] = 'Interface\\AddOns\\DragonOverlay\\Textures\\ClassicBoss',
}

function DragonOverlay:Update()
	self:GetScript('OnEvent')(self, 'PLAYER_TARGET_CHANGED')
end

function DragonOverlay:GetOptions()
	local Options = {
		type = 'group',
		name = GetAddOnMetadata('DragonOverlay', 'Title'),
		order = 3,
		args = {
			general = {
				order = 2,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return DragonOverlayOptions[info[#info]] end,
    			set = function(info, value) DragonOverlayOptions[info[#info]] = value DragonOverlay:Update() end, 
				args = {
					ClassIcon = {
						order = 0,
						type = 'toggle',
						name = 'Class Icon',
					},
					FlipDragon = {
						order = 1,
						type = 'toggle',
						name = 'Flip Dragon',
					},
					Desc = {
						order = 2,
						type = 'description',
						name = '',
					},
				},
			},
		},
	}

	local MenuItems = {
		['elite'] = 'Elite',
		['rare'] = 'Rare',
		['rareelite'] = 'Rare Elite',
		['worldboss'] = 'World Boss',
	}

	local i = 3
	for Option, Name in pairs(MenuItems) do
		Options.args.general.args[Option] = {
			order = i,
			name = Name,
			type = "select",
			values = {
				['Azure'] = 'Azure',
				['Chromatic'] = 'Chromatic',
				['Crimson'] = 'Crimson',
				['Golden'] = 'Golden',
				['Jade'] = 'Jade',
				['Onyx'] = 'Onyx',
				['HeavenlyBlue'] = 'Heavenly Blue',
				['HeavenlyCrimson'] = 'Heavenly Crimson',
				['HeavenlyGolden'] = 'Heavenly Golden',
				['HeavenlyJade'] = 'Heavenly Jade',
				['HeavenlyOnyx'] = 'Heavenly Onyx',
				['ClassicElite'] = 'Classic Elite',
				['ClassicRareElite'] = 'Classic Rare Elite',
				['ClassicRare'] = 'Classic Rare',
				['ClassicBoss'] = 'Classic Boss',
			},
		}
		Options.args.general.args[Option..'Desc'] = {
			order = i + 1,
			type = 'description',
			name = '',
			image = function() return DragonOverlay.Textures[DragonOverlayOptions[Option]], 128, 32 end,
			imageCoords = function() return {DragonOverlayOptions['FlipDragon'] and 1 or 0, DragonOverlayOptions['FlipDragon'] and 0 or 1, 0, 1} end,
		}
		i = i + 2
	end

	if EP then
		local Ace3OptionsPanel = IsAddOnLoaded("ElvUI") and ElvUI[1] or Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.dragonoverlay = Options
	else
		local ACR, ACD = LibStub("AceConfigRegistry-3.0", true), LibStub("AceConfigDialog-3.0", true)
		if not ACR or ACD then return end
		ACR:RegisterOptionsTable("DragonOverlay", Options)
		ACD:AddToBlizOptions("DragonOverlay", "DragonOverlay", nil, "general")
	end
end

function DragonOverlay:SetOverlay(Texture)
	if UnitIsPlayer('target') and DragonOverlayOptions['ClassIcon'] then
		local Class = select(2, UnitClass('target'))
		self:SetSize(32, 32)
		self.Texture:SetTexture([[Interface\WorldStateFrame\Icons-Classes]])
		self.Texture:SetTexCoord(CLASS_BUTTONS[Class][1], CLASS_BUTTONS[Class][2], CLASS_BUTTONS[Class][3], CLASS_BUTTONS[Class][4])
	elseif Texture then
		if strfind(Texture, 'Classic') then
			self:SetSize(80, 80)
		else
			self:SetSize(128, 32)
		end
		self.Texture:SetTexture(Texture)
		self.Texture:SetTexCoord(DragonOverlayOptions['FlipDragon'] and 1 or 0, DragonOverlayOptions['FlipDragon'] and 0 or 1, 0, 1)
	end
	self:ClearAllPoints()
	if Texture and strfind(Texture, 'Classic') then
		self:SetPoint('CENTER', TargetFrame, (DragonOverlayOptions['FlipDragon'] and 'RIGHT' or 'LEFT'), (DragonOverlayOptions['FlipDragon'] and -17 or 17), 0)
	else
		self:SetPoint('CENTER', TargetFrame, 'TOP', 0, 5)
	end
	self:Show()
end

DragonOverlay:RegisterEvent('PLAYER_LOGIN')
DragonOverlay:SetScript('OnEvent', function(self, event)
	self:Hide()
	if event == 'PLAYER_LOGIN' then
		TargetFrame = oUF_TukuiTarget or ElvUF_Target or DuffedUITarget or oUF_Target
		if not TargetFrame then return end

		EP = LibStub('LibElvUIPlugin-1.0', true)
		if EP then
			EP:RegisterPlugin('DragonOverlay', self.GetOptions)
		else
			self:GetOptions()
		end

		self.Texture = self:CreateTexture(nil, 'ARTWORK')
		self.Texture:SetAllPoints()
		self:SetParent(TargetFrame)
		self:SetFrameLevel(12)
		self:RegisterEvent('PLAYER_TARGET_CHANGED')
	else
		local TargetClass = UnitClassification('target')
		if TargetClass == 'normal' or TargetClass == 'minus' then
			self:Hide()
		else
			self:SetOverlay(DragonOverlay.Textures[DragonOverlayOptions[TargetClass]])
		end
	end
end)