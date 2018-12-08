local PA = _G.ProjectAzilroka
local DO = PA:NewModule('DragonOverlay', 'AceEvent-3.0')
PA.DO, _G.DragonOverlay = DO, DO

local _G = _G
local pairs, tinsert, select, unpack = pairs, tinsert, select, unpack
local strfind, strsub = strfind, strsub
local UnitIsPlayer, UnitClass, UnitClassification = UnitIsPlayer, UnitClass, UnitClassification

DO.Title = '|cFF16C3F2Dragon|r |cFFFFFFFFOverlay|r'
DO.Description = 'Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite'
DO.Authors = 'Azilroka    Whiro'
DO.ImageCredits = 'Codeblake    Kkthnxbye    Narley    Durandil'

local MediaPath = [[Interface\AddOns\ProjectAzilroka\Media\DragonOverlay\]]

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

function DO:SetOverlay()
	local Points

	if UnitIsPlayer('target') and self.db['ClassIcon'] then
		self.frame:SetSize(DO.db.IconSize, DO.db.IconSize)
		self.frame.Texture:SetTexture([[Interface\WorldStateFrame\Icons-Classes]])
		self.frame.Texture:SetTexCoord(unpack(CLASS_ICON_TCOORDS[select(2, UnitClass('target'))]))
		Points = 'ClassIconPoints'
	else
		self.frame:SetSize(DO.db.Width, DO.db.Height)
		self.frame.Texture:SetTexture(DO.Textures[self.db[UnitClassification('target')]])
		self.frame.Texture:SetTexCoord(self.db['FlipDragon'] and 1 or 0, self.db['FlipDragon'] and 0 or 1, 0, 1)
		Points = 'DragonPoints'
	end

	if _G[self.db[Points]['relativeTo']] then
		self.frame:ClearAllPoints()
		self.frame:SetPoint(self.db[Points]['point'], _G[self.db[Points]['relativeTo']].Health, self.db[Points]['relativePoint'], self.db[Points]['xOffset'], self.db[Points]['yOffset'])
		self.frame:SetParent(self.db[Points]['relativeTo'])
		self.frame:SetFrameStrata(strsub(self.db['Strata'], 3))
		self.frame:SetFrameLevel(self.db['Level'])
	end
end

function DO:GetOptions()
	local Options = {
		type = 'group',
		name = DO.Title,
		desc = DO.Description,
		args = {
			header = {
				order = 1,
				type = 'header',
				name = PA:Color(DO.Title)
			},
			general = {
				order = 2,
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
					IconSize = {
						order = 4,
						type = 'range',
						name = PA.ACL['Icon Size'],
						min = 1, max = 255, step = 1,
					},
					Width = {
						order = 5,
						type = 'range',
						name = PA.ACL['Width'],
						min = 1, max = 255, step = 1,
					},
					Height = {
						order = 6,
						type = 'range',
						name = PA.ACL['Height'],
						min = 1, max = 255, step = 1,
					},
					Desc = {
						order = 7,
						type = 'description',
						name = '',
					},
					Dragons = {
						order = -6,
						type = 'group',
						name = 'Dragons',
						guiInline = true,
						get = function(info) return DO.db[info[#info]] end,
						set = function(info, value) DO.db[info[#info]] = value DO:SetOverlay() end,
						args = {},
					},
					textures = {
						order = -5,
						type = 'group',
						name = 'Preview',
						guiInline = true,
						args = {},
					},
					AuthorHeader = {
						order = -4,
						type = 'header',
						name = PA.ACL['Authors:'],
					},
					Authors = {
						order = -3,
						type = 'description',
						name = DO.Authors,
						fontSize = 'large',
					},
					CreditsHeader = {
						order = -2,
						type = 'header',
						name = PA.ACL['Image Credits:'],
					},
					Credits = {
						order = -1,
						type = 'description',
						name = DO.ImageCredits,
						fontSize = 'large',
					},
				},
			},
		},
	}

	for Option, Name in pairs({ ['ClassIconPoints'] = PA.ACL['Class Icon Points'], ['DragonPoints'] = PA.ACL['Dragon Points'] }) do
		Options.args.general.args[Option] = {
			order = 8,
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
					order = 4,
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
	end

	Options.args.general.args.ClassIconPoints.disabled = function() return (not DO.db.ClassIcon) end

	local MenuItems = {
		['elite'] = PA.ACL['Elite'],
		['rare'] = PA.ACL['Rare'],
		['rareelite'] = PA.ACL['Rare Elite'],
		['worldboss'] = PA.ACL['World Boss'],
	}

	local Order = 1
	for Option, Name in pairs(MenuItems) do
		Options.args.general.args.Dragons.args[Option] = {
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
		Order = Order + 1
	end

	Order = 1
	for Option, Name in pairs(MenuItems) do
		Options.args.general.args.textures.args[Option] = {
			order = Order,
			type = 'execute',
			name = Name,
			image = function() return DO.Textures[DO.db[Option]], strfind(DO.db[Option], 'Classic') and 32 or 128, 32 end,
		}
		Order = Order + 1
	end

	PA.Options.args.DragonOverlay = Options
end

function DO:BuildProfile()
	PA.Defaults.profile['DragonOverlay'] = {
		['Enable'] = true,
		['Strata'] = '3-MEDIUM',
		['Level'] = 12,
		['IconSize'] = 32,
		['Width'] = 128,
		['Height'] = 64,
		['worldboss'] = 'Chromatic',
		['elite'] = 'HeavenlyGolden',
		['rare'] = 'Onyx',
		['rareelite'] = 'HeavenlyOnyx',
		['ClassIcon'] = false,
		['FlipDragon'] = false,
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
	}

	for _, Option in pairs({ 'ClassIconPoints', 'DragonPoints' }) do
		if PA.Tukui then
			PA.Defaults.profile['DragonOverlay'][Option].relativeTo = 'oUF_TukuiTarget'
		end
		if PA.ElvUI then
			PA.Defaults.profile['DragonOverlay'][Option].relativeTo = 'ElvUF_Target'
		end
		if PA.CUI then
			PA.Defaults.profile['DragonOverlay'][Option].relativeTo = 'ChaoticUF_Target'
		end
		if PA.AzilUI then
			PA.Defaults.profile['DragonOverlay'][Option].relativeTo = 'oUF_AzilUITarget'
		end
	end

	PA.Options.args.general.args.DragonOverlay = {
		type = 'toggle',
		name = DO.Title,
		desc = DO.Description,
	}
end

function DO:Initialize()
	DO.db = PA.db['DragonOverlay']

	if DO.db.Enable ~= true then
		return
	end

	DO:GetOptions()

	local frame = CreateFrame("Frame", 'DragonOverlayFrame', UIParent)
	frame.Texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.Texture:SetAllPoints()
	DO.frame = frame

	DO:RegisterEvent('PLAYER_TARGET_CHANGED', 'SetOverlay')
end