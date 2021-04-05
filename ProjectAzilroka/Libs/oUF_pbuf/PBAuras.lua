local PA = _G.ProjectAzilroka
local oUF = PA.oUF
if not oUF then
	return
end

local function UpdateTooltip(self)
	local petInfo = self:GetParent().__owner.pbouf_petinfo
	local auraID, _, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(petInfo.petOwner, petInfo.petIndex, self:GetID())
	if not auraID then
		return
	end
	local _, name, icon = C_PetBattles.GetAbilityInfoByID(auraID)
	GameTooltip:ClearLines()
	GameTooltip:AddTexture(icon)
	GameTooltip:AddDoubleLine(name, auraID, isBuff and 0 or 1, isBuff and 1 or 0, 0, 1, 1, .7)
	GameTooltip:AddLine(" ")
	_G.PetBattleAbilityTooltip_SetAura(petInfo.petOwner, petInfo.petIndex, self:GetID())
	GameTooltip:AddLine(_G.PetBattlePrimaryAbilityTooltip.Description:GetText(), 1, 1, 1)
	GameTooltip:AddLine(" ")
	if turnsRemaining > 0 then
		local remaining = function(r)
			return r > 3 and EPB.Colors.Green or r > 2 and EPB.Colors.Yellow or EPB.Colors.Red
		end
		local c1, c2, c3 = unpack(remaining(turnsRemaining))
		GameTooltip:AddLine(turnsRemaining .. " |cffffffffTurns Remaining|r", c1, c2, c3)
	end
	GameTooltip:Show()
end

local function onEnter(self)
	if (not self:IsVisible()) then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 2, 4)
	self:UpdateTooltip()
end

local function onLeave()
	GameTooltip_Hide()
end

local function createAuraIcon(element, index)
	local button = CreateFrame("Button", nil, element)
	button:RegisterForClicks("RightButtonUp")

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints()

	local turnsRemainingFrame = CreateFrame("Frame", nil, button)
	turnsRemainingFrame:SetAllPoints(button)
	turnsRemainingFrame:SetFrameLevel(button:GetFrameLevel() + 1)

	local turnsRemaining = turnsRemainingFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	turnsRemaining:SetPoint("BOTTOMRIGHT", turnsRemainingFrame, "BOTTOMRIGHT", -1, 0)

	button.UpdateTooltip = UpdateTooltip
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)

	button.icon = icon
	button.turnsRemaining = turnsRemaining

	--[[ Callback: Auras:PostCreateIcon(button)
	Called after a new aura button has been created.

	* self   - the widget holding the aura buttons
	* button - the newly created aura button (Button)
	--]]
	if (element.PostCreateIcon) then
		element:PostCreateIcon(button)
	end

	return button
end

local VISIBLE = 0
local HIDDEN = 1

local function updateIcon(element, petOwner, petIndex, index, offset, isDebuff, visible)
	local auraID, _, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(petOwner, petIndex, index)
	if not auraID then
		return HIDDEN
	end
	isBuff = not (not isBuff)
	isDebuff = not (not isDebuff)
	if isBuff == isDebuff then
		return HIDDEN
	end
	local id, name, icon = C_PetBattles.GetAbilityInfoByID(auraID)

	if (name) then
		local position = visible + offset + 1
		local button = element[position]
		if (not button) then
			--[[ Override: Auras:CreateIcon(position)
			Used to create the aura button at a given position.

			* self     - the widget holding the aura buttons
			* position - the position at which the aura button is to be created (number)

			## Returns

			* button - the button used to represent the aura (Button)
			--]]
			button = (element.CreateIcon or createAuraIcon)(element, position)

			tinsert(element, button)
			element.createdIcons = element.createdIcons + 1
		end

		button.isDebuff = isDebuff

		if (button.icon) then
			button.icon:SetTexture(icon)
		end
		if (button.turnsRemaining) then
			button.turnsRemaining:SetText(turnsRemaining > 0 and turnsRemaining)
		end

		local size = element.size or 16
		button:SetSize(size, size)

		button:EnableMouse(not element.disableMouse)
		button:SetID(index)
		button:Show()

		if (element.PostUpdateIcon) then
			element:PostUpdateIcon(petOwner, petIndex, button, index, position, turnsRemaining, isDebuff)
		end
	end

	return VISIBLE
end

local function SetPosition(element, from, to)
	local sizex = (element.size or 16) + (element["spacing-x"] or element.spacing or 0)
	local sizey = (element.size or 16) + (element["spacing-y"] or element.spacing or 0)
	local anchor = element.initialAnchor or "BOTTOMLEFT"
	local growthx = (element["growth-x"] == "LEFT" and -1) or 1
	local growthy = (element["growth-y"] == "DOWN" and -1) or 1
	local cols = floor(element:GetWidth() / sizex + 0.5)

	for i = from, to do
		local button = element[i]

		-- Bail out if the to range is out of scope.
		if (not button) then
			break
		end
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

local ABSOLUTE_MAX = 12
local function filterIcons(element, petOwner, petIndex, limit, isDebuff, offset, dontHide)
	if (not offset) then
		offset = 0
	end
	local index = 1
	local visible = 0
	local hidden = 0

	while (visible < limit and index <= ABSOLUTE_MAX) do
		local result = updateIcon(element, petOwner, petIndex, index, offset, isDebuff, visible)
		if (not result) then
			break
		elseif (result == VISIBLE) then
			visible = visible + 1
		elseif (result == HIDDEN) then
			hidden = hidden + 1
		end

		index = index + 1
	end

	if (not dontHide) then
		for i = visible + offset + 1, #element do
			element[i]:Hide()
		end
	end

	return visible, hidden
end

local function UpdateAuras(self, _, petOwner, petIndex)
	local buffs = self.PBBuffs
	if (buffs) then
		if (buffs.PreUpdate) then
			buffs:PreUpdate(petOwner, petIndex)
		end

		local numBuffs = buffs.num or ABSOLUTE_MAX
		local visibleBuffs = filterIcons(buffs, petOwner, petIndex, numBuffs)
		buffs.visibleBuffs = visibleBuffs

		local fromRange, toRange
		if (buffs.PreSetPosition) then
			fromRange, toRange = buffs:PreSetPosition(numBuffs)
		end

		if (fromRange or buffs.createdIcons > buffs.anchoredIcons) then
			(buffs.SetPosition or SetPosition)(buffs, fromRange or buffs.anchoredIcons + 1, toRange or buffs.createdIcons)
			buffs.anchoredIcons = buffs.createdIcons
		end

		if (buffs.PostUpdate) then
			buffs:PostUpdate(petOwner, petIndex)
		end
	end

	local debuffs = self.PBDebuffs
	if (debuffs) then
		if (debuffs.PreUpdate) then
			debuffs:PreUpdate(petOwner, petIndex)
		end

		local numDebuffs = debuffs.num or ABSOLUTE_MAX
		local visibleDebuffs = filterIcons(debuffs, petOwner, petIndex, numDebuffs, true)
		debuffs.visibleDebuffs = visibleDebuffs

		local fromRange, toRange
		if (debuffs.PreSetPosition) then
			fromRange, toRange = debuffs:PreSetPosition(numDebuffs)
		end

		if (fromRange or debuffs.createdIcons > debuffs.anchoredIcons) then
			(debuffs.SetPosition or SetPosition)(
				debuffs,
				fromRange or debuffs.anchoredIcons + 1,
				toRange or debuffs.createdIcons
			)
			debuffs.anchoredIcons = debuffs.createdIcons
		end

		if (debuffs.PostUpdate) then
			debuffs:PostUpdate(petOwner, petIndex)
		end
	end
end

local function Update(self, event)
	local petInfo = self.pbouf_petinfo
	if not petInfo then
		return
	end
	local petOwner, petIndex = petInfo.petOwner, petInfo.petIndex
	UpdateAuras(self, event, petOwner, petIndex)

	-- Assume no event means someone wants to re-anchor things. This is usually
	-- done by UpdateAllElements and :ForceUpdate.
	if (event == "ForceUpdate" or not event) then
		local buffs = self.PBBuffs
		if (buffs) then
			(buffs.SetPosition or SetPosition)(buffs, 1, buffs.createdIcons)
		end

		local debuffs = self.PBDebuffs
		if (debuffs) then
			(debuffs.SetPosition or SetPosition)(debuffs, 1, debuffs.createdIcons)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate")
end

local function Enable(self)
	if (self.PBBuffs or self.PBDebuffs) then
		self:RegisterEvent("PET_BATTLE_AURA_APPLIED", Update, true)
		self:RegisterEvent("PET_BATTLE_AURA_CANCELED", Update, true)
		self:RegisterEvent("PET_BATTLE_AURA_CHANGED", Update, true)

		local buffs = self.PBBuffs
		if (buffs) then
			buffs.__owner = self
			buffs.ForceUpdate = ForceUpdate

			buffs.createdIcons = buffs.createdIcons or 0
			buffs.anchoredIcons = 0

			buffs:Show()
		end

		local debuffs = self.PBDebuffs
		if (debuffs) then
			debuffs.__owner = self
			debuffs.ForceUpdate = ForceUpdate

			debuffs.createdIcons = debuffs.createdIcons or 0
			debuffs.anchoredIcons = 0

			debuffs:Show()
		end

		return true
	end
end

local function Disable(self)
	if (self.PBBuffs or self.PBDebuffs) then
		self:UnregisterEvent("PET_BATTLE_AURA_APPLIED", Update)
		self:UnregisterEvent("PET_BATTLE_AURA_CANCELED", Update)
		self:UnregisterEvent("PET_BATTLE_AURA_CHANGED", Update)

		if (self.PBBuffs) then
			self.PBBuffs:Hide()
		end
		if (self.PBDebuffs) then
			self.PBDebuffs:Hide()
		end
	end
end

oUF:AddElement("PBAuras", Update, Enable, Disable)
