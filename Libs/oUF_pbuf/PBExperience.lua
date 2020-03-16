--[[
# Element: Experience Bar

Handles the updating of a status bar that displays the unit's Experience.

## Widget

Experience - A `StatusBar` used to represent the unit's Experience.

## Sub-Widgets

.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.

## Notes

A default texture will be applied if the widget is a StatusBar and doesn't have a texture set.

## Options

.smoothGradient                   - 9 color values to be used with the .colorSmooth option (table)
.considerSelectionInCombatHostile - Indicates whether selection should be considered hostile while the unit is in
                                    combat with the player (boolean)

The following options are listed by priority. The first check that returns true decides the color of the bar.

.colorDisconnected - Use `self.colors.disconnected` to color the bar if the unit is offline (boolean)
.colorTapping      - Use `self.colors.tapping` to color the bar if the unit isn't tapped by the player (boolean)
.colorThreat       - Use `self.colors.threat[threat]` to color the bar based on the unit's threat status. `threat` is
                     defined by the first return of [UnitThreatSituation](https://wow.gamepedia.com/API_UnitThreatSituation) (boolean)
.colorClass        - Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the
                     second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) (boolean)
.colorClassNPC     - Use `self.colors.class[class]` to color the bar if the unit is a NPC (boolean)
.colorClassPet     - Use `self.colors.class[class]` to color the bar if the unit is player controlled, but not a player
                     (boolean)
.colorSelection    - Use `self.colors.selection[selection]` to color the bar based on the unit's selection color.
                     `selection` is defined by the return value of Private.unitSelectionType, a wrapper function
                     for [UnitSelectionType](https://wow.gamepedia.com/API_UnitSelectionType) (boolean)
.colorReaction     - Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the
                     unit. `reaction` is defined by the return value of
                     [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction.html) (boolean)
.colorSmooth       - Use `smoothGradient` if present or `self.colors.smooth` to color the bar with a smooth gradient
                     based on the player's current Experience percentage (boolean)
.colorExperience       - Use `self.colors.Experience` to color the bar. This flag is used to reset the bar color back to default
                     if none of the above conditions are met (boolean)

## Sub-Widgets Options

.multiplier - Used to tint the background based on the main widgets R, G and B values. Defaults to 1 (number)[0-1]

## Examples

    -- Position and size
    local Experience = CreateFrame('StatusBar', nil, self)
    Experience:SetHeight(20)
    Experience:SetPoint('TOP')
    Experience:SetPoint('LEFT')
    Experience:SetPoint('RIGHT')

    -- Add a background
    local Background = Experience:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(Experience)
    Background:SetTexture(1, 1, 1, .5)

    -- Options
    Experience.colorTapping = true
    Experience.colorDisconnected = true
    Experience.colorClass = true
    Experience.colorReaction = true
    Experience.colorExperience = true

    -- Make the background darker.
    Background.multiplier = .5

    -- Register it with oUF
    Experience.bg = Background
    self.PBExperience = Experience
--]]
local PA = _G.ProjectAzilroka
local oUF = PA.oUF
if not oUF then
	return
end

local function UpdateColor(self, event, unit)
	if (not unit or self.unit ~= unit) then
		return
	end
	local element = self.PBExperience

	local r, g, b, t
	if (element.colorSmooth) then
		r, g, b = self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	elseif (element.colorExperience) then
		t = self.colors.power.MANA
	end

	if (t) then
		r, g, b = t[1], t[2], t[3]
	end

	if (b) then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if (bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if (element.PostUpdateColor) then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	--[[ Override: Experience.UpdateColor(self, event, unit)
	Used to completely override the internal function for updating the widgets' colors.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.PBExperience.UpdateColor or UpdateColor)(self, ...)
end

local function Update(self, event, unit)
	local petInfo = self.pbouf_petinfo
	if not petInfo then
		return
	end

	local element = self.PBExperience

	--[[ Callback: Experience:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Experience element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = C_PetBattles.GetXP(petInfo.petOwner, petInfo.petIndex)
	local level = C_PetBattles.GetLevel(petInfo.petOwner, petInfo.petIndex)
	if level == 25 then
		max = 1
		cur = 1
	end
	element:SetMinMaxValues(0, max)

	element:SetValue(cur)

	element.cur = cur
	element.max = max

	--[[ Callback: Experience:PostUpdate(unit, cur, max)
	Called after the element has been updated.

	* self - the Experience element
	* unit - the unit for which the update has been triggered (string)
	* cur  - the unit's current Experience value (number)
	* max  - the unit's maximum possible Experience value (number)
	--]]
	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, event, ...)
	if (self.isForced and event ~= "ElvUI_UpdateAllElements") then
		return
	end -- ElvUI changed

	--[[ Override: Experience.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.PBExperience.Override or Update)(self, event, ...)

	ColorPath(self, event, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.PBExperience
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PET_BATTLE_XP_CHANGED", Path, true)

		if (element:IsObjectType("StatusBar") and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.PBExperience
	if (element) then
		element:Hide()

		element:SetScript("OnUpdate", nil) -- ElvUI changed
		self:UnregisterEvent("PET_BATTLE_XP_CHANGED", Path)
	end
end

oUF:AddElement("PBExperience", Path, Enable, Disable)
