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
	oUF.Tags.SharedEvents[event] = true
end

local openingEvents = string.join(" ", events[1], events[2])
local levelEvents = string.join(" ", events[1], events[2], events[3])
local healthEvents = string.join(" ", events[1], events[2], events[4], events[5])
local xpEvents = string.join(" ", events[1], events[2], events[6])
local auraEvents = string.join(" ", events[1], events[2], events[7], events[8], events[9])

local styles = {
	["CURRENT"] = "%s",
	["CURRENT_MAX"] = "%s - %s",
	["CURRENT_PERCENT"] = "%s ( %s%% )",
	["CURRENT_MAX_PERCENT"] = "%s - %s ( %s%% )",
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
-- luacheck: globals _FRAME Hex _TAGS _VARS

oUF.Tags.Events["pbuf:qualitycolor"] = openingEvents
oUF.Tags.Methods["pbuf:qualitycolor"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	local rarity = C_PetBattles.GetBreedQuality(petInfo.petOwner, petInfo.petIndex)
	return Hex(GetItemQualityColor(rarity - 1))
end

oUF.Tags.Events["pbuf:name"] = openingEvents
oUF.Tags.Methods["pbuf:name"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	local customName, realName = C_PetBattles.GetName(petInfo.petOwner, petInfo.petIndex)
	return customName or realName
end

oUF.Tags.Events["pbuf:level"] = levelEvents
oUF.Tags.Methods["pbuf:level"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	local level = C_PetBattles.GetLevel(petInfo.petOwner, petInfo.petIndex)
	return level
end

oUF.Tags.Events["pbuf:smartlevel"] = levelEvents
oUF.Tags.Methods["pbuf:smartlevel"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end
	local level = C_PetBattles.GetLevel(petInfo.petOwner, petInfo.petIndex)
	return level < 25 and level or ""
end

oUF.Tags.Events["pbuf:power"] = auraEvents
oUF.Tags.Methods["pbuf:power"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	local power = C_PetBattles.GetPower(petInfo.petOwner, petInfo.petIndex)
	return power
end

oUF.Tags.Events["pbuf:power:comparecolor"] = auraEvents
oUF.Tags.Methods["pbuf:power:comparecolor"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end
	if not _FRAME.PBPower then
		return ""
	end
	if not _FRAME.PBPower.oldPower then
		return Hex(1, 1, 1)
	end
	local power = C_PetBattles.GetPower(petInfo.petOwner, petInfo.petIndex)
	local oldPower = _FRAME.PBPower.oldPower
	if power < oldPower then
		return Hex(1, 0, 0)
	elseif power > oldPower then
		return Hex(0, 1, 0)
	else
		return Hex(1, 1, 1)
	end
end

oUF.Tags.Events["pbuf:speed"] = auraEvents
oUF.Tags.Methods["pbuf:speed"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	local speed = C_PetBattles.GetSpeed(petInfo.petOwner, petInfo.petIndex)
	return speed
end

oUF.Tags.Events["pbuf:speed:comparecolor"] = auraEvents
oUF.Tags.Methods["pbuf:speed:comparecolor"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end
	if not _FRAME.PBSpeed then
		return ""
	end
	if not _FRAME.PBSpeed.oldSpeed then
		return Hex(1, 1, 1)
	end
	local speed = C_PetBattles.GetSpeed(petInfo.petOwner, petInfo.petIndex)
	local oldSpeed = _FRAME.PBSpeed.oldSpeed
	if speed < oldSpeed then
		return Hex(1, 0, 0)
	elseif speed > oldSpeed then
		return Hex(0, 1, 0)
	else
		return Hex(1, 1, 1)
	end
end

oUF.Tags.Events["pbuf:breed"] = openingEvents
oUF.Tags.Methods["pbuf:breed"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	if not IsAddOnLoaded("BattlePetBreedID") then
		return ""
	end

	local breedInfo = petInfo.breedInfo
	if not breedInfo then
		_VARS.GetBreedInfo(petInfo)
		breedInfo = petInfo.breedInfo
	end
	return breedInfo.text
end

oUF.Tags.Events["pbuf:breedicon"] = openingEvents
oUF.Tags.Methods["pbuf:breedicon"] = function()
	local petInfo = _FRAME.pbouf_petinfo
	if not petInfo then
		return ""
	end

	if not IsAddOnLoaded("BattlePetBreedID") then
		return ""
	end

	local breedInfo = petInfo.breedInfo
	if not breedInfo or not breedInfo.icon then
		_VARS.GetBreedInfo(petInfo)
		breedInfo = petInfo.breedInfo
	end
	return breedInfo.icon or ""
end

for textFormat in pairs(styles) do
	local tagTextFormat = strlower(gsub(textFormat, "_", "-"))
	oUF.Tags.Events[format("pbuf:health:%s", tagTextFormat)] = healthEvents
	oUF.Tags.Methods[format("pbuf:health:%s", tagTextFormat)] = function()
		local petInfo = _FRAME.pbouf_petinfo
		if not petInfo then
			return ""
		end
		local health = C_PetBattles.GetHealth(petInfo.petOwner, petInfo.petIndex)
		local maxHealth = C_PetBattles.GetMaxHealth(petInfo.petOwner, petInfo.petIndex)
		local status = health == 0 and "Dead"
		if (status) then
			return status
		else
			return GetFormattedText(textFormat, health, maxHealth)
		end
	end

	oUF.Tags.Events[format("pbuf:health:%s-nostatus", tagTextFormat)] = healthEvents
	oUF.Tags.Methods[format("pbuf:health:%s-nostatus", tagTextFormat)] = function()
		local petInfo = _FRAME.pbouf_petinfo
		if not petInfo then
			return ""
		end
		local health = C_PetBattles.GetHealth(petInfo.petOwner, petInfo.petIndex)
		local maxHealth = C_PetBattles.GetMaxHealth(petInfo.petOwner, petInfo.petIndex)
		return GetFormattedText(textFormat, health, maxHealth)
	end

	oUF.Tags.Events[format("pbuf:xp:%s", tagTextFormat)] = xpEvents
	oUF.Tags.Methods[format("pbuf:xp:%s", tagTextFormat)] = function()
		local petInfo = _FRAME.pbouf_petinfo
		if not petInfo or petInfo.petOwner == LE_BATTLE_PET_ENEMY then
			return ""
		end
		local xp, maxXP = C_PetBattles.GetXP(petInfo.petOwner, petInfo.petIndex)
		local level = C_PetBattles.GetLevel(petInfo.petOwner, petInfo.petIndex)
		if level == 25 then
			return "Max"
		else
			return GetFormattedText(textFormat, xp, maxXP)
		end
	end

	oUF.Tags.Events[format("pbuf:xp:%s-nostatus", tagTextFormat)] = xpEvents
	oUF.Tags.Methods[format("pbuf:xp:%s-nostatus", tagTextFormat)] = function()
		local petInfo = _FRAME.pbouf_petinfo
		if not petInfo or petInfo.petOwner == LE_BATTLE_PET_ENEMY then
			return ""
		end
		local xp, maxXP = C_PetBattles.GetXP(petInfo.petOwner, petInfo.petIndex)
		local level = C_PetBattles.GetLevel(petInfo.petOwner, petInfo.petIndex)
		if level == 25 then
			return ""
		else
			return GetFormattedText(textFormat, xp, maxXP)
		end
	end
end

if ElvUI then
	local E = ElvUI[1]
	E:AddTagInfo("pbuf:qualitycolor", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:name", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:level", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:smartlevel", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:power", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:power:comparecolor", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:speed", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:speed:comparecolor", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:breed", 'ProjectAzilroka', nil, nil)
	E:AddTagInfo("pbuf:breedicon", 'ProjectAzilroka', nil, nil)

	for textFormat in pairs(styles) do
		local tagTextFormat = strlower(gsub(textFormat, "_", "-"))
		E:AddTagInfo(format("pbuf:health:%s", tagTextFormat), 'ProjectAzilroka', nil, nil)
		E:AddTagInfo(format("pbuf:health:%s-nostatus", tagTextFormat), 'ProjectAzilroka', nil, nil)
		E:AddTagInfo(format("pbuf:xp:%s", tagTextFormat), 'ProjectAzilroka', nil, nil)
		E:AddTagInfo(format("pbuf:xp:%s-nostatus", tagTextFormat), 'ProjectAzilroka', nil, nil)
	end
end
