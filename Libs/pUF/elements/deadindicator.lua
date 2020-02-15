local _, ns = ...
local pUF = ns.pUF

local function Update(self, event)
	local petOwner, petIndex = unpack(self.petInfo)
	if (not petOwner or not petIndex) then
		return
	end
	local element = self.DeadIndicator

	if (element.PreUpdate) then
		element.PreUpdate(petOwner, petIndex)
	end

	local cur = C_PetBattles.GetHealth(petOwner, petIndex)

	element:SetShown(cur == 0)

	if (element.PostUpdate) then
		element:PostUpdate(petOwner, petIndex, cur == 0)
	end
end

local function Path(self, ...)
	(self.DeadIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local element = self.DeadIndicator
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_HEALTH_CHANGED", Path)

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.DeadIndicator
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_HEALTH_CHANGED", Path)
	end
end

pUF:AddElement("DeadIndicator", Path, Enable, Disable)