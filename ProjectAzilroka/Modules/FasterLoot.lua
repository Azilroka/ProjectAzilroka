local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local FL = PA:NewModule('FasterLoot', 'AceEvent-3.0')
PA.FasterLoot, _G.FasterLoot = FL, FL

FL.Title, FL.Description, FL.Authors, FL.isEnabled = 'Faster Loot', ACL['Increases auto loot speed near instantaneous.'], 'Azilroka', false

local GetCVarBool, IsModifiedClick, LootSlot, GetNumLootItems, GetLootSlotLink = GetCVarBool, IsModifiedClick, LootSlot, GetNumLootItems, GetLootSlotLink
local GetBagName, GetContainerNumSlots = C_Container.GetBagName, C_Container.GetContainerNumSlots

local GetItemInfo, EquipItemByName = C_Item.GetItemInfo, C_Item.EquipItemByName

local NUM_BAG_SLOTS, HaveEmptyBagSlots = NUM_BAG_SLOTS, 0

function FL:LootItems()
	if FL.isLooting then return end

	for i = 0, NUM_BAG_SLOTS do
		if not GetBagName(i) then
			HaveEmptyBagSlots = HaveEmptyBagSlots + 1
		end
	end

	if (GetCVarBool('autoLootDefault') ~= IsModifiedClick('AUTOLOOTTOGGLE')) then
		FL.isLooting = true
		for i = GetNumLootItems(), 1, -1 do
			local link = GetLootSlotLink(i)
			LootSlot(i)
			if link then
				local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = GetItemInfo(link)

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
	FL.isLooting, FL.HaveEmptyBagSlots = false, 0
end

function FL:BuildProfile()
	PA.Defaults.profile['FasterLoot'] = { Enable = true }
end

function FL:GetOptions()
	local FasterLoot = ACH:Group(FL.Title, FL.Description, nil, nil, function(info) return FL.db[info[#info]] end)
	PA.Options.args.FasterLoot = FasterLoot

	FasterLoot.args.Description = ACH:Header(FL.Description, 0)
	FasterLoot.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) FL.db[info[#info]] = value if not FL.isEnabled then FL:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	FasterLoot.args.AuthorHeader = ACH:Header(ACL['Authors:'], -2)
	FasterLoot.args.Authors = ACH:Description(FL.Authors, -1, 'large')
end

function FL:UpdateSettings()
	FL.db = PA.db.FasterLoot
end

function FL:Initialize()
	if PA.db.FasterLoot.Enable ~= true then
		return
	end

	FL.isEnabled = true

	LOOTFRAME_AUTOLOOT_DELAY, LOOTFRAME_AUTOLOOT_RATE = .1, .1

	FL:RegisterEvent('LOOT_READY', 'LootItems')
	FL:RegisterEvent('LOOT_OPENED', 'LootItems')
	FL:RegisterEvent('LOOT_CLOSED')
	FL:RegisterEvent('QUEST_COMPLETE')
end
