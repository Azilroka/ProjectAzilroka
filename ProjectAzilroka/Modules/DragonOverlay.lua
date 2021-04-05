local PA = _G.ProjectAzilroka
local DO = PA:NewModule('DragonOverlay', 'AceEvent-3.0')
PA.DO, _G.DragonOverlay = DO, DO

local _G = _G
local pairs, tinsert, select, unpack = pairs, tinsert, select, unpack
local strfind = strfind
local UnitIsPlayer, UnitClass, UnitClassification = UnitIsPlayer, UnitClass, UnitClassification

DO.Title = PA.ACL['|cFF16C3F2Dragon|r |cFFFFFFFFOverlay|r']
DO.Description = PA.ACL['Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite']
DO.Authors = 'Azilroka    Nihilistzsche'
DO.ImageCredits = 'Codeblake    Kkthnxbye    Narley    Durandil'
DO.isEnabled = false

local MediaPath = 'Interface/AddOns/ProjectAzilroka/Media/DragonOverlay/'
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

DO.Textures = {
	Azure = MediaPath..'Azure',
	Chromatic = MediaPath..'Chromatic',
	Crimson = MediaPath..'Crimson',
	Golden = MediaPath..'Golden',
	Jade = MediaPath..'Jade',
	Onyx = MediaPath..'Onyx',
	HeavenlyBlue = MediaPath..'HeavenlyBlue',
	HeavenlyCrimson = MediaPath..'HeavenlyCrimson',
	HeavenlyGolden = MediaPath..'HeavenlyGolden',
	HeavenlyJade = MediaPath..'HeavenlyJade',
	HeavenlyOnyx = MediaPath..'HeavenlyOnyx',
	ClassicElite = MediaPath..'ClassicElite',
	ClassicRareElite = MediaPath..'ClassicRareElite',
	ClassicRare = MediaPath..'ClassicRare',
	ClassicBoss = MediaPath..'ClassicBoss',
}

function DO:SetOverlay()
	local Points

	if UnitIsPlayer('target') and DO.db['ClassIcon'] then
		DO.frame:SetSize(DO.db.IconSize, DO.db.IconSize)
		DO.frame.Texture:SetTexture('Interface/WorldStateFrame/Icons-Classes')
		DO.frame.Texture:SetTexCoord(unpack(CLASS_ICON_TCOORDS[select(2, UnitClass('target'))]))
		Points = 'ClassIconPoints'
	else
		DO.frame:SetSize(DO.db.Width, DO.db.Height)
		DO.frame.Texture:SetTexture(DO.Textures[DO.db[UnitClassification('target')]])
		DO.frame.Texture:SetTexCoord(DO.db['FlipDragon'] and 1 or 0, DO.db['FlipDragon'] and 0 or 1, 0, 1)
		Points = 'DragonPoints'
	end

	if _G[DO.db[Points]['relativeTo']] then
		DO.frame:ClearAllPoints()
		DO.frame:SetPoint(DO.db[Points]['point'], _G[DO.db[Points]['relativeTo']].Health, DO.db[Points]['relativePoint'], DO.db[Points]['xOffset'], DO.db[Points]['yOffset'])
		DO.frame:SetParent(DO.db[Points]['relativeTo'])
		DO.frame:SetFrameStrata(DO.db['Strata'])
		DO.frame:SetFrameLevel(DO.db['Level'])
	end
end

function DO:GetOptions()
	local DragonOverlay = PA.ACH:Group(DO.Title, DO.Description, nil, nil, function(info) return DO.db[info[#info]] end)
	PA.Options.args.DragonOverlay = DragonOverlay

	DragonOverlay.args.Description = PA.ACH:Description(DO.Description, 0)
	DragonOverlay.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) DO.db[info[#info]] = value if not DO.isEnabled then DO:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	DragonOverlay.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, nil, function(info, value) DO.db[info[#info]] = value DO:SetOverlay() end)
	DragonOverlay.args.General.inline = true

	DragonOverlay.args.General.args.ClassIcon = PA.ACH:Toggle(PA.ACL['Class Icon'], nil, 1)
	DragonOverlay.args.General.args.FlipDragon = PA.ACH:Toggle(PA.ACL['Flip Dragon'], nil, 2)
	DragonOverlay.args.General.args.Strata = PA.ACH:Select(PA.ACL['Frame Strata'], nil, 3, { BACKGROUND = 'BACKGROUND', LOW = 'LOW', MEDIUM = 'MEDIUM', HIGH = 'HIGH', DIALOG = 'DIALOG', FULLSCREEN = 'FULLSCREEN', FULLSCREEN_DIALOG = 'FULLSCREEN_DIALOG', TOOLTIP = 'TOOLTIP' })
	DragonOverlay.args.General.args.Level = PA.ACH:Range(PA.ACL['Frame Level'], nil, 4, { min = 0, max = 255, step = 1 })
	DragonOverlay.args.General.args.IconSize = PA.ACH:Range(PA.ACL['Icon Size'], nil, 5, { min = 0, max = 256, step = 1 })
	DragonOverlay.args.General.args.Width = PA.ACH:Range(PA.ACL['Width'], nil, 6, { min = 1, max = 256, step = 1 })
	DragonOverlay.args.General.args.Height = PA.ACH:Range(PA.ACL['Height'], nil, 7, { min = 1, max = 256, step = 1 })

	DragonOverlay.args.General.args.Dragons = PA.ACH:Group(PA.ACL['Dragons'], nil, -6)
	DragonOverlay.args.General.args.Dragons.inline = true

	DragonOverlay.args.General.args.Textures = PA.ACH:Group(PA.ACL['Preview'], nil, -5)
	DragonOverlay.args.General.args.Textures.inline = true

	for Option, Name in pairs({ ClassIconPoints = PA.ACL['Class Icon Points'], DragonPoints = PA.ACL['Dragon Points'] }) do
		DragonOverlay.args.General.args[Option] = PA.ACH:Group(Name, nil, nil, nil, function(info) return DO.db[Option][info[#info]] end, function(info, value) DO.db[Option][info[#info]] = value DO:SetOverlay() end)
		DragonOverlay.args.General.args[Option].inline = true
		DragonOverlay.args.General.args[Option].args.point = PA.ACH:Select(PA.ACL['Anchor Point'], nil, 1, PA.AllPoints)
		DragonOverlay.args.General.args[Option].args.relativeTo = PA.ACH:Select(PA.ACL['Relative Frame'], nil, 2, {})
		DragonOverlay.args.General.args[Option].args.relativePoint = PA.ACH:Select(PA.ACL['Relative Point'], nil, 3, PA.AllPoints)
		DragonOverlay.args.General.args[Option].args.xOffset = PA.ACH:Range(PA.ACL['X Offset'], nil, 4, { min = -350, max = 350, step = 1 })
		DragonOverlay.args.General.args[Option].args.yOffset = PA.ACH:Range(PA.ACL['Y Offset'], nil, 5, { min = -350, max = 350, step = 1 })

		local UnitFrameParents = { oUF_PetBattleFrameHider }

		if PA.Tukui then
			tinsert(UnitFrameParents, _G.Tukui[1].PetHider)
		end

		if PA.ElvUI then
			tinsert(UnitFrameParents, _G.ElvUF_Parent)
		end

		for _, Parent in pairs(UnitFrameParents) do
			for _, UnitFrame in pairs({Parent:GetChildren()}) do
				if _G.SecureButton_GetUnit(UnitFrame) == 'target' then
					DragonOverlay.args.General.args[Option].args.relativeTo.values[UnitFrame:GetName()] = UnitFrame:GetName()
				end
			end
		end
	end

	DragonOverlay.args.General.args.ClassIconPoints.disabled = function() return (not DO.db.ClassIcon) end

	local textures = {}
	for texture in pairs(DO.Textures) do textures[texture] = texture:gsub('(%l)(%u%l)','%1 %2') end

	for Option, Name in pairs({ elite = PA.ACL['Elite'], rare = PA.ACL['Rare'],	rareelite = PA.ACL['Rare Elite'], worldboss = PA.ACL['World Boss'] }) do
		DragonOverlay.args.General.args.Dragons.args[Option] = PA.ACH:Select(Name, nil, nil, textures)
		DragonOverlay.args.General.args.Textures.args[Option] = PA.ACH:Execute(Name, nil, nil, nil, function() return DO.Textures[DO.db[Option]], strfind(DO.db[Option], 'Classic') and 32 or 128, 32 end)
	end

	DragonOverlay.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -4)
	DragonOverlay.args.Authors = PA.ACH:Description(DO.Authors, -3, 'large')
	DragonOverlay.args.CreditsHeader = PA.ACH:Header(PA.ACL['Image Credits:'], -2)
	DragonOverlay.args.Credits = PA.ACH:Description(DO.ImageCredits, -1, 'large')
end

function DO:BuildProfile()
	PA.Defaults.profile.DragonOverlay = {
		Enable = true,
		Strata = 'MEDIUM',
		Level = 12,
		IconSize = 32,
		Width = 128,
		Height = 64,
		worldboss = 'Chromatic',
		elite = 'HeavenlyGolden',
		rare = 'Onyx',
		rareelite = 'HeavenlyOnyx',
		ClassIcon = false,
		FlipDragon = false,
		ClassIconPoints = {
			point = 'CENTER',
			relativeTo = 'oUF_Target',
			relativePoint = 'TOP',
			xOffset = 0,
			yOffset = 5,
		},
		DragonPoints = {
			point = 'CENTER',
			relativeTo = 'oUF_Target',
			relativePoint = 'TOP',
			xOffset = 0,
			yOffset = 5,
		},
	}

	for _, Option in pairs({ 'ClassIconPoints', 'DragonPoints' }) do
		if PA.Tukui then
			PA.Defaults.profile.DragonOverlay[Option].relativeTo = 'oUF_TukuiTarget'
		end
		if PA.ElvUI then
			PA.Defaults.profile.DragonOverlay[Option].relativeTo = 'ElvUF_Target'
		end
		if PA.NUI then
			PA.Defaults.profile.DragonOverlay[Option].relativeTo = 'NihilistUF_Target'
		end
		if PA.AzilUI then
			PA.Defaults.profile.DragonOverlay[Option].relativeTo = 'oUF_AzilUITarget'
		end
	end
end

function DO:UpdateSettings()
	DO.db = PA.db.DragonOverlay
end

function DO:Initialize()
	DO:UpdateSettings()

	if DO.db.Enable ~= true then
		return
	end

	DO.isEnabled = true

	local frame = _G.CreateFrame("Frame", 'DragonOverlayFrame', _G.UIParent)
	frame.Texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.Texture:SetAllPoints()
	DO.frame = frame

	DO:RegisterEvent('PLAYER_TARGET_CHANGED', 'SetOverlay')
end
