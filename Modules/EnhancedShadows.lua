local PA = _G.ProjectAzilroka

if (PA.SLE or PA.NUI) then return end

local ES = LibStub('AceAddon-3.0'):NewAddon('EnhancedShadows', 'AceEvent-3.0')

_G.EnhancedShadows = ES

ES.Title = 'Enhanced Shadows'
ES.Author = 'Azilroka, Infinitron'

local unpack, floor, pairs = unpack, floor, pairs
local UnitAffectingCombat = UnitAffectingCombat

local ClassColor = RAID_CLASS_COLORS[select(2, UnitClass('player'))]

ES.RegisteredShadows = {}

function ES:UpdateProfile()
	self.data = LibStub("AceDB-3.0"):New("EnhancedShadowsDB", {
		profile = {
			['Color'] = { 0, 0, 0, 1 },
			['ColorByClass'] = false,
			['Size'] = 3,
		},
	})

	self.data.RegisterCallback(self, "OnProfileChanged", "UpdateProfile")
	self.data.RegisterCallback(self, "OnProfileCopied", "UpdateProfile")
	self.db = self.data.profile
end

function ES:GetOptions()
	local Options = {
		type = "group",
		order = 207,
		name = ES.Title,
		get = function(info) return ES.db[info[#info]] end,
		set = function(info, value) ES.db[info[#info]] = value ES:UpdateShadows() end,
		args = {
			Color = {
				type = "color",
				order = 1,
				name = "Shadow Color",
				hasAlpha = true,
				get = function(info) return unpack(ES.db[info[#info]]) end,
				set = function(info, r, g, b, a) ES.db[info[#info]] = { r, g, b, a } ES:UpdateShadows() end,
			},
			ColorByClass = {
				type = 'toggle',
				order = 2,
				name = 'Color by Class',
			},
			Size = {
				order = 2,
				type = 'range',
				name = "Size",
				min = 3, max = 10, step = 1,
			},
		},
	}

	PA.AceOptionsPanel.Options.args.enhancedshadows = Options
end

function ES:UpdateShadows()
	if UnitAffectingCombat('player') then return end

	for frame, _ in pairs(self.RegisteredShadows) do
		ES:UpdateShadow(frame)
	end
end

function ES:RegisterShadow(shadow)
	if shadow.isRegistered then return end
	ES.RegisteredShadows[shadow] = true
	shadow.isRegistered = true
end

function ES:Scale(x)
	return self.mult*floor(x/self.mult+.5)
end

function ES:UpdateShadow(shadow)
	local r, g, b, a = unpack(ES.db.Color)

	if ES.db.ColorByClass then
		r, g, b = ClassColor['r'], ClassColor['g'], ClassColor['b']
	end

	local backdrop = shadow:GetBackdrop()

	local Size = ES.db.Size
	shadow:SetOutside(shadow:GetParent(), Size, Size)

	backdrop.edgeSize = ES:Scale(Size > 3 and Size or 3)
	backdrop.insets = {left = ES:Scale(5), right = ES:Scale(5), top = ES:Scale(5), bottom = ES:Scale(5)}

	shadow:SetBackdrop(backdrop)
	shadow:SetBackdropColor(r, g, b, 0)
	shadow:SetBackdropBorderColor(r, g, b, a)
end

function ES:Initialize()
	self.mult = 768/select(2, GetPhysicalScreenSize())/UIParent:GetScale()

	self:UpdateProfile()

	self:UpdateShadows()
end
