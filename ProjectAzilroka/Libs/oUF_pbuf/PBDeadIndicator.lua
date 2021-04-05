local PA = _G.ProjectAzilroka
local oUF = PA.oUF
if not oUF then
	return
end

local function Update(self, event)
	local petInfo = self.pbouf_petinfo
	if not petInfo then
		return
	end
	local element = self.PBDeadIndicator

	if (element.PreUpdate) then
		element.PreUpdate()
	end

	local cur = C_PetBattles.GetHealth(petInfo.petOwner, petInfo.petIndex)

	element:SetShown(cur == 0)

	if (element.PostUpdate) then
		element:PostUpdate(petInfo, cur == 0)
	end
end

local function Path(self, ...)
	(self.PBDeadIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local element = self.PBDeadIndicator
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_HEALTH_CHANGED", Path, true)

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.PBDeadIndicator
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_HEALTH_CHANGED", Path)
	end
end

oUF:AddElement("PBDeadIndicator", Update, Enable, Disable)
