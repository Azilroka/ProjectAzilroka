local _, ns = ...
local pUF = ns.pUF

local function Update(self, event)
	local petOwner, petIndex = unpack(self.petInfo)
	if (not petOwner or not petIndex) then
		return
	end
	local element = self.Health

	if (element.PreUpdate) then
		element.PreUpdate(petOwner, petIndex)
	end

	local cur = C_PetBattles.GetHealth(petOwner, petIndex)
	local max = C_PetBattles.GetMaxHealth(petOwner, petIndex)

	element:SetMinMaxValues(0, max)

	element.cur = cur
	element.max = max

	element:SetValue(cur)

	if (element.PostUpdate) then
		element:PostUpdate(petOwner, petIndex, cur, max)
	end
end

local function Path(self, ...)
	(self.Health.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local element = self.Health
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_HEALTH_CHANGED", Path)
		self:RegisterEvent("PET_BATTLE_MAX_HEALTH_CHANGED", Path)

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Health
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_HEALTH_CHANGED", Path)
		self:UnregisterEvent("PET_BATTLE_MAX_HEALTH_CHANGED", Path)
	end
end

pUF:AddElement("Health", Path, Enable, Disable)
