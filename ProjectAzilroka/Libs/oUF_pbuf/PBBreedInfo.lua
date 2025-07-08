local PA = _G.ProjectAzilroka[1]
local oUF = PA.oUF
if not oUF then
	return
end

if not C_AddOns.IsAddOnLoaded("BattlePetBreedID") then
	return
end

local seenPetInfos = {}

local function GetBreedInfo(petInfo)
	if petInfo.breedInfo then
		return petInfo.breedInfo
	end
	local oldOpt = _G.BPBID_Options.format
	local breedInfo = {}
	_G.BPBID_Options.format = 3 -- %/%
	breedInfo.text = _G.GetBreedID_Battle(petInfo)
	if _G.PetTracker and not breedInfo.text:find("ERR") then
		_G.BPBID_Options.format = 1 -- num
		local breed = _G.GetBreedID_Battle(petInfo)
		breedInfo.icon = _G.PetTracker.Breeds:Icon(breed, 0.9)
	end
	_G.BPBID_Options.format = oldOpt
	if breedInfo.text:find("ERR") then
		breedInfo.text = ""
	end
	petInfo.breedInfo = breedInfo
	seenPetInfos[petInfo] = true
end

local F = CreateFrame("Frame")
local function OnEvent(self, event, ...)
	for petInfo in pairs(seenPetInfos) do
		petInfo.breedInfo = nil
	end
	wipe(seenPetInfos)
end
F:SetScript("OnEvent", OnEvent)
F:RegisterEvent("PET_BATTLE_CLOSE")

oUF.Tags.Vars.GetBreedInfo = GetBreedInfo
