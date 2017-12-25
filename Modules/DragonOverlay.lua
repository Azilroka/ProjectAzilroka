local PA = _G.ProjectAzilroka

local DO = PA:NewModule('DragonOverlay', 'AceEvent-3.0')
_G.DragonOverlay = DO

local _G = _G
local pairs, tinsert, select, unpack = pairs, tinsert, select, unpack
local strfind, strsub = strfind, strsub
local UnitIsPlayer, UnitClass, UnitClassification = UnitIsPlayer, UnitClass, UnitClassification

DO.Title = 'DragonOverlay'
DO.Description = 'Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite'
DO.Authors = 'Azilroka    Infinitron'
DO.ImageCredits = 'Codeblake    Kkthnxbye    Narley    Durandil'

local MediaPath = 'Interface\\AddOns\\ProjectAzilroka\\Media\\DragonOverlay\\'

DO.Textures = {
	['Azure'] = MediaPath..'Azure',
	['Chromatic'] = MediaPath..'Chromatic',
	['Crimson'] = MediaPath..'Crimson',
	['Golden'] = MediaPath..'Golden',
	['Jade'] = MediaPath..'Jade',
	['Onyx'] = MediaPath..'Onyx',
	['HeavenlyBlue'] = MediaPath..'HeavenlyBlue',
	['HeavenlyCrimson'] = MediaPath..'HeavenlyCrimson',
	['HeavenlyGolden'] = MediaPath..'HeavenlyGolden',
	['HeavenlyJade'] = MediaPath..'HeavenlyJade',
	['HeavenlyOnyx'] = MediaPath..'HeavenlyOnyx',
	['ClassicElite'] = MediaPath..'ClassicElite',
	['ClassicRareElite'] = MediaPath..'ClassicRareElite',
	['ClassicRare'] = MediaPath..'ClassicRare',
	['ClassicBoss'] = MediaPath..'ClassicBoss',
}

function DO:GetOptions()
	local Options = {
		type = 'group',
		name = PA.ModuleColor..DO.Title,
		desc = DO.Description,
		order = 103,
		args = {
			general = {
				order = 0,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				get = function(info) return DO.db[info[#info]] end,
				set = function(info, value) DO.db[info[#info]] = value DO:SetOverlay() end,
				args = {
					ClassIcon = {
						order = 0,
						type = 'toggle',
						name = PA.ACL['Class Icon'],
					},
					FlipDragon = {
						order = 1,
						type = 'toggle',
						name = PA.ACL['Flip Dragon'],
					},
					Strata = {
						order = 2,
						type = 'select',
						name = PA.ACL['Frame Strata'],
						values = {
							['1-BACKGROUND'] = 'BACKGROUND',
							['2-LOW'] = 'LOW',
							['3-MEDIUM'] = 'MEDIUM',
							['4-HIGH'] = 'HIGH',
							['5-DIALOG'] = 'DIALOG',
							['6-FULLSCREEN'] = 'FULLSCREEN',
							['7-FULLSCREEN_DIALOG'] = 'FULLSCREEN_DIALOG',
							['8-TOOLTIP'] = 'TOOLTIP',
						},
					},
					Level = {
						order = 3,
						type = 'range',
						name = PA.ACL['Frame Level'],
						min = 0, max = 255, step = 1,
					},
					Desc = {
						order = 4,
						type = 'description',
						name = '',
					},
					AuthorHeader = {
						order = 20,
						type = 'header',
						name = PA.ACL['Authors:'],
					},
					Authors = {
						order = 21,
						type = 'description',
						name = DO.Authors,
						fontSize = 'large',
					},
					CreditsHeader = {
						order = 22,
						type = 'header',
						name = PA.ACL['Image Credits:'],
					},
					Credits = {
						order = 23,
						type = 'description',
						name = DO.ImageCredits,
						fontSize = 'large',
					},
				},
			},
		},
	}

	local Order = 4
	for Option, Name in pairs({ ['ClassIconPoints'] = PA.ACL['Class Icon Points'], ['DragonPoints'] = PA.ACL['Dragon Points'] }) do
		Options.args.general.args[Option] = {
			order = Order,
			type = 'group',
			name = Name,
			guiInline = true,
			get = function(info) return DO.db[Option][info[#info]] end,
			set = function(info, value) DO.db[Option][info[#info]] = value DO:SetOverlay() end,
			args = {
				point = {
					name = PA.ACL['Anchor Point'],
					order = 1,
					type = 'select',
					values = {},
				},
				relativeTo = {
					name = PA.ACL['Relative Frame'],
					order = 2,
					type = 'select',
					values = {},
				},
				relativePoint = {
					name = PA.ACL['Relative Point'],
					order = 3,
					type = 'select',
					values = {},
				},
				xOffset = {
					order = 5,
					type = 'range',
					name = PA.ACL['X Offset'],
					min = -350, max = 350, step = 1,
				},
				yOffset = {
					order = 5,
					type = 'range',
					name = PA.ACL['Y Offset'],
					min = -350, max = 350, step = 1,
				},
			},
		}

		for _, Point in pairs({ 'point', 'relativePoint' }) do
			Options.args.general.args[Option].args[Point].values = {
				['CENTER'] = 'CENTER',
				['BOTTOM'] = 'BOTTOM',
				['TOP'] = 'TOP',
				['LEFT'] = 'LEFT',
				['RIGHT'] = 'RIGHT',
				['BOTTOMLEFT'] = 'BOTTOMLEFT',
				['BOTTOMRIGHT'] = 'BOTTOMRIGHT',
				['TOPLEFT'] = 'TOPLEFT',
				['TOPRIGHT'] = 'TOPRIGHT',
			}
		end

		local UnitFrameParents = { oUF_PetBattleFrameHider }

		if PA.Tukui then
			tinsert(UnitFrameParents, Tukui[1].Panels.PetBattleHider)
		end

		if PA.ElvUI then
			tinsert(UnitFrameParents, ElvUF_Parent)
		end

		for _, Parent in pairs(UnitFrameParents) do
			for _, UnitFrame in pairs({Parent:GetChildren()}) do
				if SecureButton_GetUnit(UnitFrame) == 'target' then
					Options.args.general.args[Option].args.relativeTo.values[UnitFrame:GetName()] = UnitFrame:GetName()
				end
			end
		end
		Order = Order + 1
	end

	local MenuItems = {
		['elite'] = PA.ACL['Elite'],
		['rare'] = PA.ACL['Rare'],
		['rareelite'] = PA.ACL['Rare Elite'],
		['worldboss'] = PA.ACL['World Boss'],
	}

	Order = 6
	for Option, Name in pairs(MenuItems) do
		Options.args.general.args[Option] = {
			order = Order,
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
			order = Order + 1,
			type = 'description',
			name = '',
			image = function() return DO.Textures[DO.db[Option]], 128, 32 end,
			imageCoords = function() return {DO.db[Option]['FlipDragon'] and 1 or 0, DO.db[Option]['FlipDragon'] and 0 or 1, 0, 1} end,
		}
		Order = Order + 2
	end

	PA.Options.args.DragonOverlay = Options
end

function DO:SetOverlay()
	local Points = 'DragonPoints'
	local TargetClass = UnitClassification('target')
	local Texture = DO.Textures[self.db[TargetClass]]

	if UnitIsPlayer('target') and self.db['ClassIcon'] then
		TargetClass = select(2, UnitClass('target'))
		self.frame:SetSize(32, 32)
		self.frame.Texture:SetTexture([[Interface\WorldStateFrame\Icons-Classes]])
		self.frame.Texture:SetTexCoord(unpack(CLASS_ICON_TCOORDS[TargetClass]))
		Points = 'ClassIconPoints'
	else
		if Texture and strfind(Texture, 'Classic') then
			self.frame:SetSize(80, 80)
		else
			self.frame:SetSize(128, 32)
		end
		self.frame.Texture:SetTexture(Texture)
		self.frame.Texture:SetTexCoord(self.db['FlipDragon'] and 1 or 0, self.db['FlipDragon'] and 0 or 1, 0, 1)
	end

	self.frame:ClearAllPoints()
	self.frame:SetPoint(self.db[Points]['point'], _G[self.db[Points]['relativeTo']].Health, self.db[Points]['relativePoint'], self.db[Points]['xOffset'], self.db[Points]['yOffset'])
	self.frame:SetParent(self.db[Points]['relativeTo'])
	self.frame:SetFrameStrata(strsub(self.db['Strata'], 3))
	self.frame:SetFrameLevel(self.db['Level'])
end

function DO:SetupProfile()
	self.db = self.data.profile
end

function DO:Initialize()
	local Defaults = {
		profile = {
			['Strata'] = '2-MEDIUM',
			['Level'] = 12,
			['worldboss'] = 'Chromatic',
			['elite'] = 'HeavenlyGolden',
			['rare'] = 'Onyx',
			['rareelite'] = 'HeavenlyOnyx',
			['ClassIcon'] = false,
			['ClassIconPoints'] = {
				['point'] = 'CENTER',
				['relativeTo'] = 'oUF_Target',
				['relativePoint'] = 'TOP',
				['xOffset'] = 0,
				['yOffset'] = 5,
			},
			['DragonPoints'] = {
				['point'] = 'CENTER',
				['relativeTo'] = 'oUF_Target',
				['relativePoint'] = 'TOP',
				['xOffset'] = 0,
				['yOffset'] = 5,
			},
			['FlipDragon'] = false,
		},
	}

	for _, Option in pairs({'ClassIconPoints', 'DragonPoints' }) do
		if PA.Tukui then
			Defaults.profile[Option].relativeTo = 'oUF_TukuiTarget'
		end
		if PA.ElvUI then
			Defaults.profile[Option].relativeTo = 'ElvUF_Target'
		end
		if PA.NUI then
			Defaults.profile[Option].relativeTo = 'NenaUF_TargetVerticalUnitFrame'
		end
	end

	self.data = PA.ADB:New('DragonOverlayDB', Defaults)

	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')

	local frame = CreateFrame("Frame", 'DragonOverlayFrame', UIParent)
	frame.Texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.Texture:SetAllPoints()
	self.frame = frame

	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'SetupProfile')
	self:RegisterEvent('PLAYER_TARGET_CHANGED', 'SetOverlay')

	self:GetOptions()
end