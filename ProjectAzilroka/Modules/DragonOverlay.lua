local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local DO = PA:NewModule('DragonOverlay', 'AceEvent-3.0')
PA.DO, _G.DragonOverlay = DO, DO

local _G = _G
local next, tinsert, unpack, strfind = next, tinsert, unpack, strfind
local UnitIsPlayer, UnitClass, UnitClassification = UnitIsPlayer, UnitClass, UnitClassification

DO.Title, DO.Description, DO.Authors, DO.ImageCredits, DO.isEnabled = 'Dragon Overlay', ACL['Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite'], 'Azilroka    Nihilistzsche', 'Codeblake    Kkthnxbye    Narley    Durandil', false

local CLASS_ICON_TCOORDS, MediaPath = CLASS_ICON_TCOORDS, 'Interface/AddOns/ProjectAzilroka/Media/DragonOverlay/'

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
	local Points = UnitIsPlayer('target') and DO.db.ClassIcon and 'ClassIconPoints' or 'DragonPoints'

	local Frame = _G[DO.db[Points].relativeTo]
	if Frame then
		if Points == 'ClassIconPoints' then
			local _, classToken = UnitClass('target')
			DO.frame:SetSize(DO.db.IconSize, DO.db.IconSize)
			DO.frame.Texture:SetTexture('Interface/WorldStateFrame/Icons-Classes')
			DO.frame.Texture:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classToken]))
		else
			DO.frame:SetSize(DO.db.Width, DO.db.Height)
			DO.frame.Texture:SetTexture(DO.Textures[DO.db[UnitClassification('target')]])
			DO.frame.Texture:SetTexCoord(DO.db.FlipDragon and 1 or 0, DO.db.FlipDragon and 0 or 1, 0, 1)
		end

		DO.frame:ClearAllPoints()
		DO.frame:SetParent(Frame)
		DO.frame:SetPoint(DO.db[Points].point, Frame.Health, DO.db[Points].relativePoint, DO.db[Points].xOffset, DO.db[Points].yOffset)
		DO.frame:SetFrameStrata(DO.db.Strata)
		DO.frame:SetFrameLevel(DO.db.Level)
	end
end

function DO:GetOptions()
	local DragonOverlay = ACH:Group(DO.Title, DO.Description, nil, nil, function(info) return DO.db[info[#info]] end)
	PA.Options.args.DragonOverlay = DragonOverlay

	DragonOverlay.args.Description = ACH:Description(DO.Description, 0)
	DragonOverlay.args.Enable = ACH:Toggle(ACL["Enable"], nil, 1, nil, nil, nil, nil, function(info, value) DO.db[info[#info]] = value if not DO.isEnabled then DO:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	DragonOverlay.args.General = ACH:Group(ACL["General"], nil, 2, nil, nil, function(info, value) DO.db[info[#info]] = value DO:SetOverlay() end)
	DragonOverlay.args.General.inline = true

	DragonOverlay.args.General.args.ClassIcon = ACH:Toggle(ACL["Class Icon"], nil, 1)
	DragonOverlay.args.General.args.FlipDragon = ACH:Toggle(ACL["Flip Dragon"], nil, 2)
	DragonOverlay.args.General.args.Strata = ACH:Select(ACL["Frame Strata"], nil, 3, { BACKGROUND = 'BACKGROUND', LOW = 'LOW', MEDIUM = 'MEDIUM', HIGH = 'HIGH', DIALOG = 'DIALOG', FULLSCREEN = 'FULLSCREEN', FULLSCREEN_DIALOG = 'FULLSCREEN_DIALOG', TOOLTIP = 'TOOLTIP' })
	DragonOverlay.args.General.args.Level = ACH:Range(ACL["Frame Level"], nil, 4, { min = 0, max = 255, step = 1 })
	DragonOverlay.args.General.args.IconSize = ACH:Range(ACL["Icon Size"], nil, 5, { min = 0, max = 256, step = 1 })
	DragonOverlay.args.General.args.Width = ACH:Range(ACL["Width"], nil, 6, { min = 1, max = 256, step = 1 })
	DragonOverlay.args.General.args.Height = ACH:Range(ACL["Height"], nil, 7, { min = 1, max = 256, step = 1 })

	DragonOverlay.args.General.args.Dragons = ACH:Group(ACL["Dragons"], nil, -6)
	DragonOverlay.args.General.args.Dragons.inline = true

	DragonOverlay.args.General.args.Textures = ACH:Group(ACL["Preview"], nil, -5)
	DragonOverlay.args.General.args.Textures.inline = true

	local parents, frames, textures = { oUF_PetBattleFrameHider }, {}, {}
	if PA.Tukui then tinsert(parents, _G.Tukui[1].PetHider) end
	if PA.ElvUI then tinsert(parents, _G.ElvUFParent) end

	for _, parent in next, parents do
		for _, UnitFrame in next, { parent:GetChildren() } do
			if _G.SecureButton_GetUnit(UnitFrame) == 'target' then frames[UnitFrame:GetName()] = UnitFrame:GetName() end
		end
	end

	for Option, Name in next, { ClassIconPoints = ACL["Class Icon Points"], DragonPoints = ACL["Dragon Points"] } do
		DragonOverlay.args.General.args[Option] = ACH:Group(Name, nil, nil, nil, function(info) return DO.db[Option][info[#info]] end, function(info, value) DO.db[Option][info[#info]] = value DO:SetOverlay() end)
		DragonOverlay.args.General.args[Option].inline = true
		DragonOverlay.args.General.args[Option].args.point = ACH:Select(ACL["Anchor Point"], nil, 1, PA.AllPoints)
		DragonOverlay.args.General.args[Option].args.relativeTo = ACH:Select(ACL["Relative Frame"], nil, 2, frames)
		DragonOverlay.args.General.args[Option].args.relativePoint = ACH:Select(ACL["Relative Point"], nil, 3, PA.AllPoints)
		DragonOverlay.args.General.args[Option].args.xOffset = ACH:Range(ACL["X Offset"], nil, 4, { min = -350, max = 350, step = 1 })
		DragonOverlay.args.General.args[Option].args.yOffset = ACH:Range(ACL["Y Offset"], nil, 5, { min = -350, max = 350, step = 1 })
	end

	DragonOverlay.args.General.args.ClassIconPoints.hidden = function() return (not DO.db.ClassIcon) end

	for texture in next, DO.Textures do textures[texture] = texture:gsub('(%l)(%u%l)','%1 %2') end

	for Option, Name in next, { elite = ACL["Elite"], rare = ACL["Rare"], rareelite = ACL["Rare Elite"], worldboss = ACL["World Boss"] } do
		DragonOverlay.args.General.args.Dragons.args[Option] = ACH:Select(Name, nil, nil, textures)
		DragonOverlay.args.General.args.Textures.args[Option] = ACH:Execute(Name, nil, nil, nil, function() return DO.Textures[DO.db[Option]], strfind(DO.db[Option], 'Classic') and 32 or 128, 32 end)
	end

	DragonOverlay.args.AuthorHeader = ACH:Header(ACL["Authors:"], -4)
	DragonOverlay.args.Authors = ACH:Description(DO.Authors, -3, 'large')
	DragonOverlay.args.CreditsHeader = ACH:Header(ACL["Image Credits:"], -2)
	DragonOverlay.args.Credits = ACH:Description(DO.ImageCredits, -1, 'large')
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
			relativeTo = PA.Tukui and 'oUF_TukuiTarget' or PA.ElvUI and 'ElvUF_Target' or PA.NUI and 'NihilistUF_Target' or 'oUF_Target',
			relativePoint = 'TOP',
			xOffset = 0,
			yOffset = 5,
		},
		DragonPoints = {
			point = 'CENTER',
			relativeTo = PA.Tukui and 'oUF_TukuiTarget' or PA.ElvUI and 'ElvUF_Target' or PA.NUI and 'NihilistUF_Target' or 'oUF_Target',
			relativePoint = 'TOP',
			xOffset = 0,
			yOffset = 5,
		},
	}
end

function DO:UpdateSettings()
	DO.db = PA.db.DragonOverlay
end

function DO:Initialize()
	if DO.db.Enable ~= true then
		return
	end

	DO.isEnabled = true

	local frame = CreateFrame('Frame', 'DragonOverlayFrame', UIParent)
	frame.Texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.Texture:SetAllPoints()
	DO.frame = frame

	DO:RegisterEvent('PLAYER_TARGET_CHANGED', 'SetOverlay')
end
