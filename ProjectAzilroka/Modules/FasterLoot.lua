local PA = _G.ProjectAzilroka
local FL = PA:NewModule('FasterLoot', 'AceEvent-3.0')
PA.FL, _G.FasterLoot = FL, FL

FL.Title = PA.ACL['|cFF16C3F2Faster|r |cFFFFFFFFLoot|r']
FL.Description = PA.ACL['Increases auto loot speed near instantaneous.']
FL.Authors = 'Azilroka'
FL.isEnabled = false

local GetNumLootItems = GetNumLootItems
local LootSlot = LootSlot
local GetCVarBool = GetCVarBool
local IsModifiedClick = IsModifiedClick
local GetBagName = GetBagName
local GetLootSlotLink = GetLootSlotLink
local GetItemInfo = GetItemInfo
local EquipItemByName = EquipItemByName

local NUM_BAG_SLOTS = NUM_BAG_SLOTS

local HaveEmptyBagSlots = 0

function FL:LootItems()
	if FL.isLooting then
		return
	end

	for i = 0, NUM_BAG_SLOTS do
		if not GetBagName(i) then
			HaveEmptyBagSlots = HaveEmptyBagSlots + 1
		end
	end

	local link, itemEquipLoc, bindType, _
	if (GetCVarBool('autoLootDefault') ~= IsModifiedClick('AUTOLOOTTOGGLE')) then
		FL.isLooting = true
		for i = GetNumLootItems(), 1, -1 do
			link = GetLootSlotLink(i)
			LootSlot(i)
			if link then
				itemEquipLoc, _, _, _, _, bindType = select(9, GetItemInfo(link))

				if itemEquipLoc == "INVTYPE_BAG" and bindType < 2 and HaveEmptyBagSlots > 0 then
					EquipItemByName(link)
				end
			end
		end
	end
end

function FL:QUEST_COMPLETE(event)
end

function FL:LOOT_CLOSED()
	FL.isLooting = false
	FL.HaveEmptyBagSlots = 0
end

function FL:BuildProfile()
	PA.Defaults.profile['FasterLoot'] = { Enable = true }
end

function FL:GetOptions()
	local FasterLoot = PA.ACH:Group(FL.Title, FL.Description, nil, nil, function(info) return FL.db[info[#info]] end)
	PA.Options.args.FasterLoot = FasterLoot

	FasterLoot.args.Description = PA.ACH:Header(FL.Description, 0)
	FasterLoot.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) FL.db[info[#info]] = value if not FL.isEnabled then FL:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	FasterLoot.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	FasterLoot.args.Authors = PA.ACH:Description(FL.Authors, -1, 'large')
end

function FL:Initialize()
	FL.db = PA.db.FasterLoot

	if PA.db.FasterLoot.Enable ~= true then
		return
	end

	FL.isEnabled = true

	LOOTFRAME_AUTOLOOT_DELAY = 0.1;
	LOOTFRAME_AUTOLOOT_RATE = 0.1;

	FL:RegisterEvent('LOOT_READY', 'LootItems')
	FL:RegisterEvent('LOOT_OPENED', 'LootItems')
	FL:RegisterEvent('LOOT_CLOSED')
	FL:RegisterEvent('QUEST_COMPLETE')
end
