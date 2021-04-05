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

	local element = self.PBSpeed
	element:SetTexture([[Interface\PetBattles\PetBattle-StatIcons]])
	local l, r, t, b
	if petInfo.petOwner == _G.LE_BATTLE_PET_ALLY then
		l, r, t, b = 0, 0.5, 0.5, 1
	else
		l, r, t, b = 0.5, 0, 0.5, 1
	end
	element:SetTexCoord(l, r, t, b)
	if (element.PostUpdate) then
		element:PostUpdate(event)
	end
end

local function Path(self, ...)
	--[[ Override: Portrait.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	return (self.PBSpeed.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.PBSpeed
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_OPENING_START", Path, true)
		self:RegisterEvent("PET_BATTLE_OPENING_DONE", Path, true)
		self:RegisterEvent("PET_BATTLE_CLOSE", Path, true)
		self:RegisterEvent("PET_BATTLE_AURA_APPLIED", Path, true)
		self:RegisterEvent("PET_BATTLE_AURA_CANCELED", Path, true)
		self:RegisterEvent("PET_BATTLE_AURA_CHANGED", Path, true)

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.PBSpeed
	if (element) then
		element:Hide()

		self:UnregisterEvent("PET_BATTLE_OPENING_START")
		self:UnregisterEvent("PET_BATTLE_OPENING_DONE")
		self:UnregisterEvent("PET_BATTLE_CLOSE")
		self:UnregisterEvent("PET_BATTLE_AURA_APPLIED")
		self:UnregisterEvent("PET_BATTLE_AURA_CANCELED")
		self:UnregisterEvent("PET_BATTLE_AURA_CHANGED")
	end
end

oUF:AddElement("PBSpeed", Path, Enable, Disable)
