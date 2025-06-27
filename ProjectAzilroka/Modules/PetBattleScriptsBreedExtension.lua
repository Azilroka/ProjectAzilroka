local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
if PA.Classic or not PA:IsAddOnEnabled("tdBattlePetScript") or not PA:IsAddOnEnabled("BattlePetBreedID") then
	return
end

local PBSBE = PA:NewModule("PetBattleScriptsBreedExtension")
local C_AddOns_IsAddOnLoaded = _G.C_AddOns.IsAddOnLoaded

function PBSBE.GetBreedInfo(petOwner, petIndex, breedFormat)
	local oldOpt = _G.BPBID_Options.format
	_G.BPBID_Options.format = breedFormat
	local breed = _G.GetBreedID_Battle({ petOwner = petOwner, petIndex = petIndex })
	_G.BPDID_Options.formaat = oldOpt
	return breed
end

function PBSBE.BreedText(owner, pet)
	return PBSBE.GetBreedInfo(owner, pet, 3)
end

function PBSBE.Breed(owner, pet)
	return PBSBE.GetBreedInfo(owner, pet, 1)
end

PBSBE.Conditions = {
	breed = PBSBE.BreedText,
	breednum = PBSBE.Breed,
}

function PBSBE:Initialize()
	pcall(C_AddOns_LoadAddOn, "tdBattlePetScript")
	if C_AddOns_IsAddOnLoaded("tdBattlePetScript") then
		local PBS = _G.PetBattleScripts
		for condition, func in pairs(self.Conditions) do
			PBS:RegisterCondition(condition, { type = "compare", arg = false }, func)
		end
	end
end
