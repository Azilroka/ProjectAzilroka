local PA = _G.ProjectAzilroka
local oUF = PA.oUF
if not oUF then
	return
end

--[[
	Configuration values for both health and power:
		.enabled: enable cutaway for this element, defaults to disabled
		.fadeOutTime: How long it takes the cutaway health to fade, defaults to 0.6 seconds
		.lengthBeforeFade: How long it takes before the cutaway begins to fade, defaults to 0.3 seconds
]]
-- GLOBALS: ElvUI

local _G = _G
local max = math.max
local hooksecurefunc = hooksecurefunc

local E -- placeholder

local function checkElvUI()
	if not E then
		E = _G.ElvUI and _G.ElvUI[1]

		assert(E, "PBCutaway was not able to locate ElvUI and it is required.")
	end
end

local function closureFunc(self)
	self.ready = nil
	self.playing = nil
	self.cur = nil
end

local function fadeClosure(element)
	if not element.FadeObject then
		element.FadeObject = {
			finishedFuncKeep = true,
			finishedArg1 = element,
			finishedFunc = closureFunc
		}
	end

	E:UIFrameFadeOut(element, element.fadeOutTime, element.__parentElement:GetAlpha(), 0)
end

local function Shared_PreUpdate(self, element, petOwner, petIndex)
	element.petOwner = petOwner
	element.petIndex = petIndex
	element.cur = self.cur
	element.ready = true
end

local function UpdateSize(self, element, curV, maxV)
	local isVertical = self:GetOrientation() == "VERTICAL"
	local pm = (isVertical and self:GetHeight()) or self:GetWidth()
	local oum = (1 / maxV) * pm
	local c = max(element.cur - curV, 0)
	local mm = c * oum
	if isVertical then
		element:SetHeight(mm)
	else
		element:SetWidth(mm)
	end
end

local PRE = 0
local POST = 1

local function Shared_UpdateCheckReturn(self, element, updateType, ...)
	if not element:IsVisible() then
		return true
	end
	if (updateType == PRE) then
		local maxV = ...
		return (not element.enabled or not self.cur) or element.ready or not maxV
	elseif (updateType == POST) then
		local curV, maxV, petOwner, petIndex = ...
		return (not element.enabled or not element.cur) or (not element.ready or not curV or not maxV) or
			element.petOwner ~= petOwner or
			element.petIndex ~= petIndex
	else
		return false
	end
end

local function PBHealth_PreUpdate(self, unit)
	local petInfo = self.__owner.pbouf_petinfo
	local element = self.__owner.PBCutaway.Health
	local maxV = (element.GetHealthMax or C_PetBattles.GetMaxHealth)(petInfo.petOwner, petInfo.petIndex)
	if Shared_UpdateCheckReturn(self, element, PRE, maxV) then
		return
	end

	Shared_PreUpdate(self, element, unit)
end

local function PBHealth_PostUpdate(self, unit, curHealth, maxHealth)
	local element = self.__owner.PBCutaway.Health
	if Shared_UpdateCheckReturn(self, element, POST, curHealth, maxHealth, unit) then
		return
	end
	UpdateSize(self, element, curHealth, maxHealth)
	if element.playing then
		return
	end

	if (element.cur - curHealth) > (maxHealth * 0.01) then
		element:SetAlpha(self:GetAlpha())

		E:Delay(element.lengthBeforeFade, fadeClosure, element)

		element.playing = true
	else
		element:SetAlpha(0)
		closureFunc(element)
	end
end

local function PBHealth_PostUpdateColor(self, _, _, _, _)
	local r, g, b = self:GetStatusBarColor()
	self.__owner.PBCutaway.Health:SetVertexColor(r * 1.5, g * 1.5, b * 1.5)
end

local defaults = {
	health = {
		enabled = true,
		lengthBeforeFade = 0.3,
		fadeOutTime = 0.6
	}
}

local function UpdateConfigurationValues(self, db)
	local hs = false
	if (self.Health) then
		local health = self.Health
		local hdb = db.health
		hs = hdb.enabled
		health.enabled = hs
		if (hs) then
			health.lengthBeforeFade = hdb.lengthBeforeFade
			health.fadeOutTime = hdb.fadeOutTime
			health:Show()
		else
			health:Hide()
		end
	end
	return hs
end

local function Enable(self)
	local element = self and self.PBCutaway
	if (element) then
		checkElvUI()

		if (element.Health and element.Health:IsObjectType("Texture") and not element.Health:GetTexture()) then
			element.Health:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if (not element.defaultsSet) then
			UpdateConfigurationValues(element, defaults)
			element.defaultsSet = true
		end

		if element.Health and self.PBHealth then
			self.PBHealth.__owner = self
			element.Health.__parentElement = self.PBHealth
			element.Health:SetAlpha(0)

			if not element.Health.hasCutawayHook then
				if self.PBHealth.PreUpdate then
					hooksecurefunc(self.PBHealth, "PreUpdate", PBHealth_PreUpdate)
				else
					self.PBHealth.PreUpdate = PBHealth_PreUpdate
				end

				if self.PBHealth.PostUpdate then
					hooksecurefunc(self.PBHealth, "PostUpdate", PBHealth_PostUpdate)
				else
					self.PBHealth.PostUpdate = PBHealth_PostUpdate
				end

				if self.PBHealth.PostUpdateColor then
					hooksecurefunc(self.PBHealth, "PostUpdateColor", PBHealth_PostUpdateColor)
				else
					self.PBHealth.PostUpdateColor = PBHealth_PostUpdateColor
				end

				element.Health.hasCutawayHook = true
			end
		end

		if not (element.UpdateConfigurationValues) then
			element.UpdateConfigurationValues = UpdateConfigurationValues
		end

		return true
	end
end

local function disableElement(element)
	if element then
		element.enabled = false
		element:Hide()
	end
end

local function Disable(self)
	if self and self.PBCutaway then
		disableElement(self.PBCutaway.Health)
	end
end

oUF:AddElement("PBCutaway", nil, Enable, Disable)
