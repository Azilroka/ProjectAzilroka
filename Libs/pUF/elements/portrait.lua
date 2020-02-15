--[[
# Element: Portraits

Handles the updating of the battle pet's portrait.

## Widget

Portrait - A `PlayerModel` or a `Texture` used to represent the unit's portrait.

## Notes

A question mark model will be used if the widget is a PlayerModel and the client doesn't have the model information for
the unit.

## Examples

    -- 3D Portrait
    -- Position and size
    local Portrait = CreateFrame('PlayerModel', nil, self)
    Portrait:SetSize(32, 32)
    Portrait:SetPoint('RIGHT', self, 'LEFT')

    -- Register it with oUF
    self.Portrait = Portrait

    -- 2D Portrait
    local Portrait = self:CreateTexture(nil, 'OVERLAY')
    Portrait:SetSize(32, 32)
    Portrait:SetPoint('RIGHT', self, 'LEFT')

    -- Register it with oUF
    self.Portrait = Portrait
--]]

local _, ns = ...
local pUF = ns.pUF

local function Update(self, event)
	local petOwner, petIndex = unpack(self.petInfo)
	if (not petOwner or not petIndex) then
		return
	end
	local element = self.Portrait
	local isAvailable = pUF.Private.petExists(petOwner, petIndex)

	if (element.PreUpdate) then element:PreUpdate(petOwner, petIndex) end

	if isAvailable then
		local displayID = C_PetBattles.GetDisplayID(petOwner, petIndex)
		if element:IsObjectType('PlayerModel') and displayID ~= element.displayID then
			element:SetDisplayInfo(displayID)
			element:SetCamDistanceScale(0.6)
			element:Show()
			element.displayID = displayID
		else
			local icon = C_PetBattles.GetIcon(petOwner, petIndex)
			element:SetTexture(icon)
			element:Show()
		end
	else
		element:Hide()
	end

	if (element.PostUpdate) then element:PostUpdate(petOwner, petIndex, event, isAvailable) end
end

local function Path(self, ...)
	--[[ Override: Portrait.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	--]]
	return (self.Portrait.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.Portrait
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_OPENING_START", Path)
		self:RegisterEvent("PET_BATTLE_OPENING_DONE", Path)

		return true
	end
end

local function Disable(self)
	local element = self.Portrait
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_OPENING_START", Path)
		self:UnregisterEvent("PET_BATTLE_OPENING_DONE", Path)
	end
end

pUF:AddElement("Portrait", Path, Enable, Disable)