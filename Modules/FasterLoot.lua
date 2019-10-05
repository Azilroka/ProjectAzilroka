local PA = _G.ProjectAzilroka
local FL = PA:NewModule('FasterLoot', 'AceEvent-3.0')
PA.FL, _G.FasterLoot = FL, FL

FL.Title = '|cFF16C3F2Faster|r |cFFFFFFFFLoot|r'
FL.Description = 'Increases auto loot speed near instantaneous.'
FL.Authors = 'Azilroka'

local GetNumLootItems, CloseLoot, LootSlot, GetCVarBool, IsModifiedClick = GetNumLootItems, CloseLoot, LootSlot, GetCVarBool, IsModifiedClick

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
	PA.Defaults.profile['FasterLoot'] = { ['Enable'] = true }

	PA.Options.args.general.args.FasterLoot = {
		type = 'toggle',
		name = FL.Title,
		desc = FL.Description,
	}
end

function FL:Initialize()
	if PA.db.FasterLoot.Enable ~= true then
		return
	end

	LOOTFRAME_AUTOLOOT_DELAY = 0.1;
	LOOTFRAME_AUTOLOOT_RATE = 0.1;

	FL:RegisterEvent('LOOT_READY', 'LootItems')
	FL:RegisterEvent('LOOT_OPENED', 'LootItems')
	FL:RegisterEvent('LOOT_CLOSED')
	FL:RegisterEvent('QUEST_COMPLETE')
end
