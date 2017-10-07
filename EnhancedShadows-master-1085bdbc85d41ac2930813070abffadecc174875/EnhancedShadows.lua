local ES = LibStub('AceAdddon-3.0'):NewAddon('EnhancedShadows', 'AceEvent-3.0')
_G.EnhancedShadows = ES

local LSM, EP = LibStub('LibSharedMedia-3.0')
local ACR, ACD = LibStub("AceConfigRegistry-3.0"), LibStub("AceConfigDialog-3.0")

local unpack, floor, pairs = unpack, floor, pairs
local UnitAffectingCombat = UnitAffectingCombat

local ClassColor = RAID_CLASS_COLORS[select(2, UnitClass('player'))]

ES.RegisteredShadows = {}

function ES:UpdateProfile()
	self.data = LibStub("AceDB-3.0"):New("EnhancedShadowsDB", {
		profile = {
			['Color'] = { 0, 0, 0 },
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
		name = "EnhancedShadows",
		get = function(info) return ES.db[info[#info]] end,
		set = function(info, value) ES.db[info[#info]] = value ES:UpdateShadows() end,
		args = {
			Color = {
				type = "color",
				order = 1,
				name = "Shadow Color",
				hasAlpha = true,
				get = function(info) unpack(ES.db[info[#info]]) end,
				set = function(info, r, g, b, a) ES.db[info[#info]] = { r, g, b, a} ES:UpdateShadows() end,
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

	Options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(ES.data)
	Options.args.profiles.order = -2
	ACR:RegisterOptionsTable("EnhancedShadows", Options.args.profiles)

	if EP then
		local Ace3OptionsPanel = IsAddOnLoaded("ElvUI") and ElvUI[1] or Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.enhancedshadows = Options
	end

	ACR:RegisterOptionsTable("EnhancedShadows", Options)
	ACD:AddToBlizOptions("EnhancedShadows", "EnhancedShadows", nil, "Color")
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
	return self.mult*floor(x/self.mult+.5);
end

function ES:UpdateShadow(shadow)
	local r, g, b, a = unpack(ES.db.Color)

	if ES.db.ColorByClass then
		r, g, b = ClassColor['r'], ClassColor['g'], ClassColor['b']
	end

	local Size = ES.db.Size
	shadow:SetOutside(shadow:GetParent(), Size, Size)
	shadow:SetBackdrop({
		edgeFile = [[Interface\AddOns\EnhancedShadows\Media\Shadow]], edgeSize = ES:Scale(Size > 3 and Size or 3),
		insets = {left = ES:Scale(5), right = ES:Scale(5), top = ES:Scale(5), bottom = ES:Scale(5)},
	})
	shadow:SetBackdropColor(r, g, b, 0)
	shadow:SetBackdropBorderColor(r, g, b, a)
end

function ES:Initialize()
	self.mult = 768/select(2, GetPhysicalScreenSize())/UIParent:GetScale()

--	self:ElvUIShadows()

	self:UpdateShadows()

	if EP then
		EP:RegisterPlugin("EnhancedShadows", self.GetOptions)
	else
		self:GetOptions()
	end
end

ES:RegisterEvent("PLAYER_LOGIN", 'Initialize')