local PA = _G.ProjectAzilroka
local ES = PA:NewModule('EnhancedShadows', 'AceEvent-3.0', 'AceTimer-3.0')

ES.Title = 'Enhanced Shadows'
ES.Header = PA.ACL['|cFF16C3F2Enhanced|r |cFFFFFFFFShadows|r']
ES.Description = PA.ACL['Adds options for registered shadows']
ES.Authors = 'Azilroka     NihilisticPandemonium'
ES.isEnabled = false

local unpack, floor, pairs = unpack, floor, pairs
local UnitAffectingCombat = UnitAffectingCombat

ES.RegisteredShadows = {}

function ES:UpdateShadows()
	if UnitAffectingCombat('player') then return end

	for frame, _ in pairs(self.RegisteredShadows) do
		ES:UpdateShadow(frame)
	end
end

function ES:RegisterFrameShadows(frame)
	local shadow = frame.shadow or frame.Shadow
	if shadow and not shadow.isRegistered then
		ES.shadows[shadow] = true
		shadow.isRegistered = true
	end
	local ishadow = frame.invertedshadow or frame.InvertedShadow
	if ishadow and not ishadow.isRegistered then
		ES.shadows[ishadow] = true
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
	PA.Options.args.EnhancedShadows = {
		type = "group",
		name = ES.Title,
		desc = ES.Description,
		get = function(info) return ES.db[info[#info]] end,
		set = function(info, value) ES.db[info[#info]] = value ES:UpdateShadows() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = ES.Header
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					ES.db[info[#info]] = value
					if (not ES.isEnabled) then
						ES:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				args = {
					Color = {
						type = "color",
						order = 1,
						name = PA.ACL['Shadow Color'],
						hasAlpha = true,
						get = function(info) return unpack(ES.db[info[#info]]) end,
						set = function(info, r, g, b, a) ES.db[info[#info]] = { r, g, b, a } ES:UpdateShadows() end,
					},
					ColorByClass = {
						type = 'toggle',
						order = 2,
						name = PA.ACL['Color by Class'],
					},
					Size = {
						order = 3,
						type = 'range',
						name = PA.ACL['Size'],
						min = 3, max = 10, step = 1,
					},
				},
			},
			AuthorHeader = {
				order = -4,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -3,
				type = 'description',
				name = ES.Authors,
				fontSize = 'large',
			},
		},
	}
end

function ES:BuildProfile()
	PA.Defaults.profile.EnhancedShadows = {
		Enable = true,
		Color = { 0, 0, 0, 1 },
		ColorByClass = false,
		Size = 3,
	}
end

function ES:Initialize()
	ES.db = PA.db.EnhancedShadows

	if PA.SLE or PA.CUI or ES.db.Enable ~= true then
		return
	end

	PA.ES, _G.EnhancedShadows = ES, ES

	ES.isEnabled = true

	ES:ScheduleTimer('UpdateShadows', 1)
end
