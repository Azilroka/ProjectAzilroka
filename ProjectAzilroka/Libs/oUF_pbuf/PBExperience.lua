local PA = _G.ProjectAzilroka
local oUF = PA.oUF
if not oUF then
	return
end

local function UpdateColor(self, event, unit)
	if (not unit or self.unit ~= unit) then
		return
	end
	local element = self.PBExperience

	local r, g, b, t
	if (element.colorSmooth) then
		r, g, b = self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	elseif (element.colorExperience) then
		t = self.colors.power.MANA
	end

	if (t) then
		r, g, b = t[1], t[2], t[3]
	end

	if (b) then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if (bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if (element.PostUpdateColor) then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	(self.PBExperience.UpdateColor or UpdateColor)(self, ...)
end

local function Update(self, event, unit)
	local petInfo = self.pbouf_petinfo
	if not petInfo then
		return
	end

	local element = self.PBExperience

	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = C_PetBattles.GetXP(petInfo.petOwner, petInfo.petIndex)
	local level = C_PetBattles.GetLevel(petInfo.petOwner, petInfo.petIndex)
	if level == 25 then
		max = 1
		cur = 1
	end
	element:SetMinMaxValues(0, max)

	element:SetValue(cur)

	element.cur = cur
	element.max = max

	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, event, ...)
	if (self.isForced and event ~= "ElvUI_UpdateAllElements") then
		return
	end

	(self.PBExperience.Override or Update)(self, event, ...)

	ColorPath(self, event, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.PBExperience
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_XP_CHANGED", Path, true)

		if (element:IsObjectType("StatusBar") and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.PBExperience
	if (element) then
		element:Hide()

		element:SetScript("OnUpdate", nil)
		self:UnregisterEvent("PET_BATTLE_XP_CHANGED", Path)
	end
end

oUF:AddElement("PBExperience", Path, Enable, Disable)
