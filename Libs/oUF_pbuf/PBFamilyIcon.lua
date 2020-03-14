--[[
# Element: Pet Battle Family Icon

Handles the visibility and updating of an indicator based on the unit's incoming resurrect status.

## Widget

PBFamilyIcon - A `Texture` used to display if the unit has an incoming resurrect.

## Notes

A default texture will be applied if the widget is a Texture and doesn't have a texture or a color set.

## Examples

    -- Position and size
    local PBFamilyIcon = self:CreateTexture(nil, 'OVERLAY')
    PBFamilyIcon:SetSize(16, 16)
    PBFamilyIcon:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.PBFamilyIcon = PBFamilyIcon
--]]
local PA = _G.ProjectAzilroka
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

	--[[ Callback: PBFamilyIcon:PreUpdate()
	Called before the element has been updated.

	* self - the PBFamilyIcon element
	--]]
	if (element.PreUpdate) then
		element:PreUpdate()
	end

	local petType = C_PetBattles.GetPetType(petInfo.petOwner, petInfo.petIndex)
	local suffix = _G.PET_TYPE_SUFFIX[petType]
	if suffix then
		element:SetTexture([[Interface\AddOns\ProjectAzilroka\Media\Textures\]] .. suffix)
	end

	--[[ Callback: PBFamilyIcon:PostUpdate(incomingResurrect)
	Called after the element has been updated.

	* self              - the PBFamilyIcon element
	* petType.          - the family type of thepet
	--]]
	if (element.PostUpdate) then
		return element:PostUpdate(petType)
	end
end

local function Path(self, ...)
	--[[ Override: PBFamilyIcon.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.PBFamilyIcon.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.PBFamilyIcon
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_PET_TYPE_CHANGED", Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.PBFamilyIcon
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_PET_TYPE_CHANGED", Path)
	end
end

oUF:AddElement("PBFamilyIcon", Path, Enable, Disable)
