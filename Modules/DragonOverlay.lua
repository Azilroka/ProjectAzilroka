local PA = _G.ProjectAzilroka

local DO = LibStub('AceAddon-3.0'):NewAddon('DragonOverlay', 'AceEvent-3.0')
_G.DragonOverlay = DO

DO.Title = '|cffC495DDDragonOverlay|r'
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
		name = DO.Title,
		order = 103,
		args = {
			general = {
				order = 0,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return DO.db[info[#info]] end,
				set = function(info, value) DO.db[info[#info]] = value DO:Update() end,
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
					Strata = {
						name = 'Frame Strata',
						order = 2,
						type = 'select',
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
						name = 'Frame Level',
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
						name = 'Authors:',
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
						name = 'Image Credits:',
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
	for Option, Name in pairs({ ['ClassIconPoints'] = 'Class Icon Points', ['DragonPoints'] = 'Dragon Points' }) do
		Options.args.general.args[Option] = {
			order = Order,
			type = 'group',
			name = Name,
			guiInline = true,
			get = function(info) return DO.db[Option][info[#info]] end,
			set = function(info, value) DO.db[Option][info[#info]] = value DO:Update() end,
			args = {
				point = {
					name = 'Anchor Point',
					order = 1,
					type = 'select',
					values = {},
				},
				relativeTo = {
					name = 'Relative Frame',
					order = 2,
					type = 'select',
					values = {},
				},
				relativePoint = {
					name = 'Relative Point',
					order = 3,
					type = 'select',
					values = {},
				},
				xOffset = {
					order = 5,
					type = 'range',
					name = 'X Offset',
					min = -350, max = 350, step = 1,
				},
				yOffset = {
					order = 5,
					type = 'range',
					name = 'Y Offset',
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
		['elite'] = 'Elite',
		['rare'] = 'Rare',
		['rareelite'] = 'Rare Elite',
		['worldboss'] = 'World Boss',
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

	if PA.EP then
		PA.AceOptionsPanel.Options.args.DragonOverlay = Options
	end
end

function DO:Update()
	self.frame:SetParent(_G[self.db['DragonPoints']['relativeTo']])
	self:PLAYER_TARGET_CHANGED()
end

function DO:SetOverlay(Class)
	local Points = 'DragonPoints'
	local Texture = self.db[TargetClass]

	if UnitIsPlayer('target') and self.db['ClassIcon'] then
		local Class = select(2, UnitClass('target'))
		self.frame:SetSize(32, 32)
		self.frame.Texture:SetTexture([[Interface\WorldStateFrame\Icons-Classes]])
		self.frame.Texture:SetTexCoord(unpack(CLASS_ICON_TCOORDS[Class]))
		Points = 'ClassIconPoints'
	else
		if Texture and strfind(Texture, 'Classic') then
			self.frame:SetSize(80, 80)
		else
			self.frame:SetSize(128, 32)
		end
		self.frame.Texture:SetTexture(Texture or nil)
		self.frame.Texture:SetTexCoord(self.db['FlipDragon'] and 1 or 0, self.db['FlipDragon'] and 0 or 1, 0, 1)
	end

	self.frame:ClearAllPoints()
	self.frame:SetPoint(self.db[Points]['point'], _G[self.db[Points]['relativeTo']].Health, self.db[Points]['relativePoint'], self.db[Points]['xOffset'], self.db[Points]['yOffset'])
	self.frame:SetParent(self.db[Points]['relativeTo'])
	self.frame:SetFrameStrata(strsub(self.db['Strata'], 3))
	self.frame:SetFrameLevel(self.db['Level'])
end

function DO:PLAYER_TARGET_CHANGED()
	self:SetOverlay(UnitClassification('target'))
end

function DO:SetupProfile()
	self.data = LibStub('AceDB-3.0'):New('DragonOverlayDB', {
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
	})

	for _, Option in pairs({'ClassIconPoints', 'DragonPoints' }) do
		if PA.Tukui then
			self.data.profile[Option].relativeTo = 'oUF_TukuiTarget'
		end
		if PA.ElvUI then
			self.data.profile[Option].relativeTo = 'ElvUF_Target'
		end
		if PA.NUI then
			self.data.profile[Option].relativeTo = 'NenaUF_TargetVerticalUnitFrame'
		end
	end
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function DO:Initialize()
	self:SetupProfile()

	local frame = CreateFrame("Frame", 'DragonOverlayFrame', UIParent)
	frame.Texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.Texture:SetAllPoints()
	--frame:SetParent(self.db['DragonPoints']['relativeTo'] or UIParent)
	frame:SetFrameLevel(12)
	self.frame = frame

	self:RegisterEvent('PLAYER_TARGET_CHANGED')
end