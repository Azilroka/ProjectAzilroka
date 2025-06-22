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

	local element = self.PBPortrait
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local displayID = C_PetBattles.GetDisplayID(petInfo.petOwner, petInfo.petIndex)
	local isAvailable = select(2, C_PetBattles.GetName(petInfo.petOwner, petInfo.petIndex)) ~= nil

	element.stateChanged = event ~= "OnUpdate" or element.displayID ~= displayID or element.state ~= isAvailable
	if element.stateChanged then -- ElvUI changed
		element.playerModel = element:IsObjectType("PlayerModel")
		element.state = isAvailable
		element.displayID = displayID

		if element.playerModel then
			if not isAvailable then
				element:SetCamDistanceScale(0.25)
				element:SetPortraitZoom(0)
				element:SetPosition(0, 0, 0.25)
				element:ClearModel()
				element:SetModel([[Interface\Buttons\TalkToMeQuestionMark.m2]])
			else
				element:SetCamDistanceScale(1)
				element:SetPortraitZoom(1)
				element:SetPosition(0, 0, 0)
				element:ClearModel()
				element:SetDisplayInfo(displayID)
			end
		elseif not element.customTexture then -- ElvUI changed
			local icon = C_PetBattles.GetIcon(petInfo.petOwner, petInfo.petIndex)
			element:SetTexture(icon)
		end
	end

	if element.PostUpdate then
		return element:PostUpdate(unit, event)
	end
end

local function Path(self, ...)
	return (self.PBPortrait.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.PBPortrait
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_OPENING_START", Path, true)
		self:RegisterEvent("PET_BATTLE_OPENING_DONE", Path, true)

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.PBPortrait
	if element then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_OPENING_START")
		self:UnregisterEvent("PET_BATTLE_OPENING_DONE")
	end
end

oUF:AddElement("PBPortrait", Path, Enable, Disable)
