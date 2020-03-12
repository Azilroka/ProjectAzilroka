local PA = _G.ProjectAzilroka
local oUF = PA.oUF
if not oUF then
	return
end

local events = {
	"PET_BATTLE_OPENING_START",
	"PET_BATTLE_OPENING_DONE",
	"PET_BATTLE_LEVEL_CHANGED",
	"PET_BATTLE_HEALTH_CHANGED",
	"PET_BATTLE_MAX_HEALTH_CHANGED",
	"PET_BATTLE_XP_CHANGED",
	"PET_BATTLE_AURA_APPLIED",
	"PET_BATTLE_AURA_CANCELED",
	"PET_BATTLE_AURA_CHANGED"
}

for _, event in ipairs(events) do
	oUF.SharedEvents[event] = true
end

local openingEvents = {events[1], events[2]}
local levelEvents = {events[3]}
local healthEvents = {events[4], events[5]}
local xpEvents = {events[6]}
local auraEvents = {events[7], events[8], events[9]}

local styles = {
	["CURRENT"] = "%s",
	["CURRENT_MAX"] = "%s - %s",
	["CURRENT_PERCENT"] = "%s ( %s%% )",
	["CURRENT_MAX_PERCENT"] = "%s - %s ( %s%% )",
	["CURRENT_RESTED"] = "%s | R: %s",
	["CURRENT_MAX_RESTED"] = "%s - %s | R: %s",
	["CURRENT_PERCENT_RESTED"] = "%s ( %s%% ) | R: %s",
	["CURRENT_MAX_PERCENT_RESTED"] = "%s - %s ( %s%% ) | R: %s",
	["TONEXT"] = "%s",
	["BUBBLES"] = "%s",
	["PERCENT"] = "%s%%",
	["RESTED"] = "%s"
}

local function GetFormattedText(style, min, max, rested)
	if (not styles[style] or not min) then
		return
	end

	if max == 0 then
		max = 1
	end

	local useStyle = styles[style]

	local percentValue
	if max ~= nil then
		percentValue = floor(min / max * 100)
	end

	if style == "TONEXT" then
		local deficit = max - min
		if deficit <= 0 then
			return ""
		else
			return string.format(useStyle, deficit)
		end
	elseif
		style == "CURRENT" or
			((style == "CURRENT_MAX" or style == "CURRENT_MAX_PERCENT" or style == "CURRENT_PERCENT") and min == max)
	 then
		return string.format(styles["CURRENT"], min)
	elseif style == "CURRENT_MAX" then
		return string.format(useStyle, min, max)
	elseif style == "CURRENT_PERCENT" then
		return string.format(useStyle, min, percentValue)
	elseif style == "CURRENT_MAX_PERCENT" then
		return string.format(useStyle, min, max, percentValue)
	elseif
		style == "CURRENT_RESTED" or
			((style == "CURRENT_MAX_RESTED" or style == "CURRENT_MAX_PERCENT_RESTED" or style == "CURRENT_PERCENT_RESTED") and
				min == max)
	 then
		return string.format(styles["CURRENT_RESTED"], min, rested)
	elseif style == "CURRENT_MAX_RESTED" then
		return string.format(useStyle, min, max, rested)
	elseif style == "CURRENT_PERCENT_RESTED" then
		return string.format(useStyle, min, percentValue, rested)
	elseif style == "CURRENT_MAX_PERCENT_RESTED" then
		return string.format(useStyle, min, max, percentValue, rested)
	elseif style == "BUBBLES" then
		local bubbles = floor(20 * (max - min) / max)
		return string.format(useStyle, bubbles)
	elseif style == "RESTED" then
		if not rested then
			rested = 0
		end
		return string.format(useStyle, rested)
	elseif style == "PERCENT" then
		return string.format(useStyle, percentValue)
	end
end

local function getPetInfo(args)
	return (args or ""):match("%d:%d")
end

oUF.Tags.Events["pbuf:name"] = openingEvents
oUF.Tags.Methods["pbuf:name"] = function(unit, _, customArgs)
	local petOwner, petIndex = getPetInfo(customArgs)
	if not petOwner or not petIndex then
		return ""
	end

	local customName, realName = C_PetBattles.GetName(petOwner, petIndex)
	return customName or realName
end

oUF.Tags.Events["pbuf:level"] = levelEvents
oUF.Tags.Methods["pbuf:level"] = function(unit, _, customArgs)
	local petOwner, petIndex = getPetInfo(customArgs)
	if not petOwner or not petIndex then
		return ""
	end

	local level = C_PetBattles.GetLevel(petOwner, petIndex)
	return level
end

local healthXpTags = {
	{"cur", "CURRENT"},
	{"max", "CURRENT"},
	{"percent", "PERCENT"}
}

for _, tagPair in ipairs(healthXpTags) do
	local hpTagStr = ("pbuf:hp:%s"):format(tagPair[1])
	local xpTagStr = ("pbuf:xp:%s"):format(tagPair[1])
	oUF.Tags.Events[hpTagStr] = healthEvents
	oUF.Tags.Methods[hpTagStr] = function(unit, _, customArgs)
		local petOwner, petIndex = getPetInfo(customArgs)
		if not petOwner or not petIndex then
			return ""
		end

		local health = C_PetBattles.GetHealth(petOwner, petIndex)
		local maxHealth = C_PetBattles.GetMaxHealth(petOwner, petIndex)

		return GetFormattedText(tagPair[2], tagPair[1] == "max" and maxHealth or health, maxHealth)
	end

	oUF.Tags.Events[xpTagStr] = xpEvents
	oUF.Tags.Events[xpTagStr] = function(unit, _, customArgs)
		local petOwner, petIndex = getPetInfo(customArgs)
		if not petOwner or not petIndex then
			return ""
		end

		if petOwner == LE_BATTLE_PET_ENEMY then
			return ""
		end

		local level = C_PetBattles.GetLevel(petOwner, petIndex)
		if level == 25 then
			return ""
		end

		local xp, maxXP = C_PetBattles.GetXP(petOwner, petIndex)

		return GetFormattedText(tagPair[2], tagPair[1] == "max" and maxXP or xp, xp)
	end
end

oUF.Tags.Events["pbuf:power"] = auraEvents
oUF.Tags.Methods["pbuf:power"] = function(unit, _, customArgs)
	local petOwner, petIndex = getPetInfo(customArgs)
	if not petOwner or not petIndex then
		return ""
	end

	local power = C_PetBattles.GetPower(petOwner, petIndex)
	return power
end

oUF.Tags.Events["pbuf:speed"] = auraEvents
oUF.Tags.Methods["pbuf:speed"] = function(unit, _, customArgs)
	local petOwner, petIndex = getPetInfo(customArgs)
	if not petOwner or not petIndex then
		return ""
	end

	local speed = C_PetBattles.GetSpeed(petOwner, petIndex)
end

oUF.Tags.Events["pbuf:breed"] = openingEvents
oUF.Tags.Methods["pbuf:breed"] = function(unit, _, customArgs)
	local petOwner, petIndex = getPetInfo(customArgs)
	if not petOwner or not petIndex then
		return ""
	end

	if not IsAddOnLoaded("BattlePetBreedID") then
		return ""
	end
	return _G.GetBreedID_Battle({petOwner = petOwner, petIndex = petIndex})
end

oUF.Tags.Events["pbuf:breedicon"] = openingEvents
oUF.Tags.Methods["pbuf:breedicon"] = function(unit, _, customArgs)
	local petOwner, petIndex = getPetInfo(customArgs)
	if not petOwner or not petIndex then
		return ""
	end

	if not _G.PetTracker then
		return ""
	end

	local level, maxHP, speciesID, power, speed, rarity =
		C_PetBattles.GetLevel(petOwner, petIndex),
		C_PetBattles.GetMaxHealth(petOwner, petIndex),
		C_PetBattles.GetPetSpeciesID(petOwner, petIndex),
		C_PetBattles.GetPower(petOwner, petIndex),
		C_PetBattles.GetSpeed(petOwner, petIndex),
		C_PetBattles.GetBreedQuality(petOwner, petIndex)
	local breed = _G.PetTracker.Predict:Breed(speciesID, level, rarity, maxHP, power, speed)

	return CreateTextureMarkup(_G.PetTracker:GetBreedIcon(breed, .9), 16, 16, 16, 16, 0, 1, 0, 1, 0, 0)
end
