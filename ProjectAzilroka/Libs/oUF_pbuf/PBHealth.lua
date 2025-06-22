local PA = _G.ProjectAzilroka[1]
local oUF = PA.oUF
if not oUF then
	return
end

local function UpdateColor(self, event, unit)
	local element = self.PBHealth

	local r, g, b, t
	if element.colorClass then
		local _, class = UnitClass("player")
		t = self.colors.class[class]
	elseif element.colorSmooth then
		r, g, b =
			self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	elseif element.colorHealth then
		t = self.colors.health
	end

	if t then
		r, g, b = t[1], t[2], t[3]
	end

	if b then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if bg then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	(self.PBHealth.UpdateColor or UpdateColor)(self, ...)
end

local function Update(self, event, unit)
	local petInfo = self.pbouf_petinfo
	if not petInfo then
		return
	end

	local element = self.PBHealth

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local cur, max =
		C_PetBattles.GetHealth(petInfo.petOwner, petInfo.petIndex),
		C_PetBattles.GetMaxHealth(petInfo.petOwner, petInfo.petIndex)

	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	element.cur = cur
	element.max = max

	if element.PostUpdate then
		element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, event, ...)
	(self.PBHealth.Override or Update)(self, event, ...)

	ColorPath(self, event, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.PBHealth
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_OPENING_START", Path, true)
		self:RegisterEvent("PET_BATTLE_OPENING_DONE", Path, true)
		self:RegisterEvent("PET_BATTLE_HEALTH_CHANGED", Path, true)
		self:RegisterEvent("PET_BATTLE_MAX_HEALTH_CHANGED", Path, true)

		if element:IsObjectType("StatusBar") and not element:GetStatusBarTexture() then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.PBHealth
	if element then
		element:Hide()

		element:SetScript("OnUpdate", nil)
		self:UnregisterEvent("PET_BATTLE_HEALTH_CHANGED", Path)
		self:UnregisterEvent("PET_BATTLE_MAX_HEALTH_CHANGED", Path)
		self:UnregisterEvent("PET_BATTLE_OPENING_DONE", Path)
		self:UnregisterEvent("PET_BATTLE_OPENING_START", Path)
	end
end

oUF:AddElement("PBHealth", Path, Enable, Disable)
