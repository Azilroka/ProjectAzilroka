local _, ns = ...
local pUF = ns.pUF

local function Update(self, event)
	local petOwner, petIndex = unpack(self.petInfo)
	if (not petOwner or not petIndex) then
		return
	end
	local element = self.FamilyIcon

	if (element.PreUpdate) then
		element.PreUpdate(petOwner, petIndex)
	end

	local petType = C_PetBattles.GetPetType(petOwner, petIndex)

	element:SetTexture([[Interface\AddOns\ElvUI_NihilistUI\media\textures\]] .. _G.PET_TYPE_SUFFIX[petType])

	if (element.PostUpdate) then
		element:PostUpdate(petOwner, petIndex, petType)
	end
end

local function Path(self, ...)
	(self.FamilyIcon.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local element = self.FamilyIcon
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_PET_TYPE_CHANGED", Path)

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.FamilyIcon
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_PET_TYPE_CHANGED", Path)
	end
end

pUF:AddElement("FamilyIcon", Path, Enable, Disable)
