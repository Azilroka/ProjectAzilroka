local PA = _G.ProjectAzilroka
local ES = PA:NewModule('EnhancedShadows', 'AceEvent-3.0', 'AceTimer-3.0')
PA.ES = ES

ES.Title = PA.ACL['|cFF16C3F2Enhanced|r |cFFFFFFFFShadows|r']
ES.Description = PA.ACL['Adds options for registered shadows']
ES.Authors = 'Azilroka     Nihilistzsche'
ES.isEnabled = false

local unpack, floor, pairs = unpack, floor, pairs
local UnitAffectingCombat = UnitAffectingCombat

ES.RegisteredShadows = {}

function ES:UpdateShadows()
	if UnitAffectingCombat('player') then return end

	for frame, _ in pairs(ES.RegisteredShadows) do
		ES:UpdateShadow(frame)
	end
end

function ES:RegisterFrameShadows(frame)
	local shadow = frame.shadow or frame.Shadow
	if shadow and not shadow.isRegistered then
		ES.RegisteredShadows[shadow] = true
		shadow.isRegistered = true
	end
	local ishadow = frame.invertedshadow or frame.InvertedShadow
	if ishadow and not ishadow.isRegistered then
		ES.RegisteredShadows[ishadow] = true
		shadow.isRegistered = true
	end
end

function ES:RegisterShadow(shadow)
	if not shadow then return end
	if shadow.isRegistered then return end
	ES.RegisteredShadows[shadow] = true
	shadow.isRegistered = true
end

function ES:Scale(x)
	return PA.Multiple * floor(x / PA.Multiple + .5)
end

function ES:UpdateShadow(shadow)
	local r, g, b, a = unpack(ES.db.Color)

	if ES.db.ColorByClass then
		r, g, b = unpack(PA.ClassColor)
	end

	local backdrop = shadow:GetBackdrop()

	local Size = ES.db.Size
	shadow:SetOutside(shadow:GetParent(), Size, Size)

	backdrop.edgeSize = ES:Scale(Size > 3 and Size or 3)

	shadow:SetBackdrop(backdrop)
	shadow:SetBackdropColor(r, g, b, 0)
	shadow:SetBackdropBorderColor(r, g, b, a)
end

function ES:GetOptions()
	local EnhancedShadows = PA.ACH:Group(ES.Title, ES.Description, nil, nil, function(info) return ES.db[info[#info]] end)
	PA.Options.args.EnhancedShadows =EnhancedShadows

	EnhancedShadows.args.Description = PA.ACH:Description(ES.Description, 0)
	EnhancedShadows.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) ES.db[info[#info]] = value if not ES.isEnabled then ES:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	EnhancedShadows.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, nil, function(info, value) ES.db[info[#info]] = value ES:UpdateShadows() end)
	EnhancedShadows.args.General.inline = true
	EnhancedShadows.args.General.args.Color = PA.ACH:Color(PA.ACL['Shadow Color'], nil, 1, true, nil, function(info) return unpack(ES.db[info[#info]]) end, function(info, r, g, b, a) ES.db[info[#info]] = { r, g, b, a } ES:UpdateShadows() end)
	EnhancedShadows.args.General.args.ColorByClass = PA.ACH:Toggle(PA.ACL['Color by Class'], nil, 2)
	EnhancedShadows.args.General.args.Size = PA.ACH:Range(PA.ACL['Size'], nil, 3, { min = 1, max = 10, step = 1 })

	EnhancedShadows.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	EnhancedShadows.args.Authors = PA.ACH:Description(ES.Authors, -1, 'large')
end

function ES:BuildProfile()
	PA.Defaults.profile.EnhancedShadows = {
		Enable = true,
		Color = { 0, 0, 0, 1 },
		ColorByClass = false,
		Size = 3,
	}
end

function ES:UpdateSettings()
	ES.db = PA.db.EnhancedShadows
end

function ES:Initialize()
	ES:UpdateSettings()

	if PA.SLE or PA.NUI or ES.db.Enable ~= true then
		return
	end

	_G.EnhancedShadows = ES

	ES.isEnabled = true

	ES:ScheduleTimer('UpdateShadows', 1)
end
