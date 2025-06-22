local PA = _G.ProjectAzilroka[1]
local oUF = PA.oUF
if not oUF then
	return
end

local function Update(self, event, unit)
	local petInfo = self.pbouf_petinfo
	if not petInfo then
		return
	end

	local element = self.PBFamilyIcon

	if element.PreUpdate then
		element:PreUpdate()
	end

	local petType = C_PetBattles.GetPetType(petInfo.petOwner, petInfo.petIndex)
	local suffix = _G.PET_TYPE_SUFFIX[petType]
	if suffix then
		element:SetTexture([[Interface\AddOns\ProjectAzilroka\Media\Textures\]] .. suffix)
	end

	if element.PostUpdate then
		return element:PostUpdate(petType)
	end
end

local function Path(self, ...)
	return (self.PBFamilyIcon.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.PBFamilyIcon
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_PET_TYPE_CHANGED", Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.PBFamilyIcon
	if element then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_PET_TYPE_CHANGED", Path)
	end
end

oUF:AddElement("PBFamilyIcon", Path, Enable, Disable)
