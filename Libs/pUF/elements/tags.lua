local _, ns = ...
local pUF = ns.pUF
local NT = LibStub("LibNihilistUITags-1.0")

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

local function RegisterTags()
	local function getPetInfo(fs)
		return unpack(fs.petInfo)
	end

	-- tags needed:
	-- name, level, breed (using BattlePetBreedID), hp:cur, hp:max
	-- hp:percent, xp:cur, xp:max, xp:percent
	-- power, speed
	NT:RegisterTag(
		"epb:name",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local customName, realName = C_PetBattles.GetName(petOwner, petIndex)
			return customName or realName
		end,
		"PET_BATTLE_OPENING_START PET_BATTLE_OPENING_DONE"
	)

	NT:RegisterTag(
		"epb:level",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local level = C_PetBattles.GetLevel(petOwner, petIndex)
			return level
		end,
		"PET_BATTLE_LEVEL_CHANGED"
	)

	NT:RegisterTag(
		"epb:hp:cur",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local health = C_PetBattles.GetHealth(petOwner, petIndex)
			local maxHealth = C_PetBattles.GetMaxHealth(petOwner, petIndex)
			return GetFormattedText("CURRENT", health, maxHealth)
		end,
		"PET_BATTLE_HEALTH_CHANGED PET_BATTLE_MAX_HEALTH_CHANGED"
	)

	NT:RegisterTag(
		"epb:hp:max",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local health = C_PetBattles.GetHealth(petOwner, petIndex)
			local maxHealth = C_PetBattles.GetMaxHealth(petOwner, petIndex)
			return GetFormattedText("CURRENT", maxHealth, maxHealth)
		end,
		"PET_BATTLE_HEALTH_CHANGED PET_BATTLE_MAX_HEALTH_CHANGED"
	)

	NT:RegisterTag(
		"epb:hp:percent",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local health = C_PetBattles.GetHealth(petOwner, petIndex)
			local maxHealth = C_PetBattles.GetMaxHealth(petOwner, petIndex)
			return GetFormattedText("PERCENT", health, maxHealth)
		end,
		"PET_BATTLE_HEALTH_CHANGED PET_BATTLE_MAX_HEALTH_CHANGED"
	)

	NT:RegisterTag(
		"epb:xp:cur",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local xp, maxXP = C_PetBattles.GetXP(petOwner, petIndex)
			local level = C_PetBattles.GetLevel(petOwner, petIndex)
			if petOwner == LE_BATTLE_PET_ENEMY or level == 25 then
				return ''
			else
				return GetFormattedText("CURRENT", xp, maxXP)
			end
		end,
		"PET_BATTLE_XP_CHANGED"
	)

	NT:RegisterTag(
		"epb:xp:max",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local xp, maxXP = C_PetBattles.GetXP(petOwner, petIndex)
			local level = C_PetBattles.GetLevel(petOwner, petIndex)
			if petOwner == LE_BATTLE_PET_ENEMY or level == 25 then
				return ''
			else
				return GetFormattedText("CURRENT", maxXP, maxXP)
			end
		end,
		"PET_BATTLE_XP_CHANGED"
	)

	NT:RegisterTag(
		"epb:xp:percent",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local xp, maxXP = C_PetBattles.GetXP(petOwner, petIndex)
			local level = C_PetBattles.GetLevel(petOwner, petIndex)
			if petOwner == LE_BATTLE_PET_ENEMY or level == 25 then
				return ''
			else
				return GetFormattedText("PERCENT", xp, maxXP)
			end
		end,
		"PET_BATTLE_XP_CHANGED"
	)

	NT:RegisterTag(
		"epb:power",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local power = C_PetBattles.GetPower(petOwner, petIndex)
			return power
		end,
		"PET_BATTLE_AURA_APPLIED PET_BATTLE_AURA_CANCELED PET_BATTLE_AURA_CHANGED"
	)

	NT:RegisterTag(
		"epb:speed",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			local speed = C_PetBattles.GetSpeed(petOwner, petIndex)
			return speed
		end,
		"PET_BATTLE_AURA_APPLIED PET_BATTLE_AURA_CANCELED PET_BATTLE_AURA_CHANGED"
	)

	NT:RegisterTag(
		"epb:breed",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			if IsAddOnLoaded("BattlePetBreedID") then
				return _G.GetBreedID_Battle({petOwner = petOwner, petIndex = petIndex})
			else
				return ''
			end
		end,
		"PET_BATTLE_OPENING_START PET_BATTLE_OPENING_DONE"
	)

	NT:RegisterTag(
		"epb:breedicon",
		function(fs)
			local petOwner, petIndex = getPetInfo(fs)
			if not _G.PetTracker then
				return ''
			end
			local level, maxHP =
				C_PetBattles.GetLevel(petOwner, petIndex),
				C_PetBattles.GetMaxHealth(petOwner, petIndex)
			local speciesID, power, speed, rarity =
				C_PetBattles.GetPetSpeciesID(petOwner, petIndex),
				C_PetBattles.GetPower(petOwner, petIndex),
				C_PetBattles.GetSpeed(petOwner, petIndex),
				C_PetBattles.GetBreedQuality(petOwner, petIndex)
			local breed = _G.PetTracker.Predict:Breed(speciesID, level, rarity, maxHP, power, speed)
			return _G.PetTracker:GetBreedIcon(breed, .9)
		end,
		"PET_BATTLE_OPENING_START PET_BATTLE_OPENING_DONE"
	)
end

pUF.GetFormattedText = GetFormattedText
pUF.RegisterTags = RegisterTags

RegisterTags()