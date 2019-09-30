local PA = _G.ProjectAzilroka
if PA.Retail then return end

local LC = PA:NewModule('LootConfirm', 'AceEvent-3.0')
PA.LC, _G.LootConfirm = LC, LC

LC.Title = '|cFF16C3F2Loot|r |cFFFFFFFFConfirm|r'
LC.Description = 'Confirms Loot for Solo/Groups (Need/Greed)'
LC.Authors = 'Azilroka     NihilisticPandemonium'

local tonumber, strmatch, select = tonumber, strmatch, select
local ConfirmLootRoll, GetNumLootItems, ConfirmLootSlot, CloseLoot = ConfirmLootRoll, GetNumLootItems, ConfirmLootSlot, CloseLoot
local RollOnLoot, LootSlot = RollOnLoot, LootSlot
local IsEquippableItem, GetItemInfo, GetInventoryItemLink = IsEquippableItem, GetItemInfo, GetInventoryItemLink
local GetLootRollItemInfo, GetLootRollItemLink = GetLootRollItemInfo, GetLootRollItemLink

function LC:Confirm(event, ...)
	if event == 'CONFIRM_LOOT_ROLL' then
		local arg1, arg2 = ...
		ConfirmLootRoll(arg1, arg2)
	elseif event == 'LOOT_OPENED' or event == 'LOOT_BIND_CONFIRM' then
		for slot = 1, GetNumLootItems() do
			ConfirmLootSlot(slot)
		end
	end
end

-- LOOT_ROLL_TYPE_PASS, LOOT_ROLL_TYPE_NEED
-- texture, item, quantity, currencyID, quality, locked, isQuestItem, questId, isActive = GetLootSlotInfo(slot);

function LC:START_LOOT_ROLL(event, id)
	if not self.db['Greed'] then return end
	RollOnLoot(id, LOOT_ROLL_TYPE_GREED)
end

function LC:GetOptions()
	local Options = {
		type = 'group',
		name = LC.Title,
		desc = LC.Description,
		args = {
			header = {
				order = 1,
				type = 'header',
				name = PA:Color(LC.Title)
			},
			general = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				get = function(info) return LC.db[info[#info]] end,
				set = function(info, value) LC.db[info[#info]] = value end,
				args = {
					Greed = {
						order = 2,
						type = 'toggle',
						name = PA.ACL['Auto Greed'],
						desc = PA.ACL['Automatically greed'],
					},
				},
			},
		},
	}

	PA.Options.args.LootConfirm = Options
end

function LC:BuildProfile()
	PA.Defaults.profile['LootConfirm'] = {
		['Enable'] = false,
		['Greed'] = false,
	}

	PA.Options.args.general.args.LootConfirm = {
		type = 'toggle',
		name = LC.Title,
		desc = LC.Description,
	}
end

function LC:Initialize()
	LC.db = PA.db['LootConfirm']

	if LC.db.Enable ~= true then
		return
	end

	LC:GetOptions()

	UIParent:UnregisterEvent('LOOT_BIND_CONFIRM')
	UIParent:UnregisterEvent('CONFIRM_LOOT_ROLL')

	LC:RegisterEvent('CONFIRM_LOOT_ROLL', 'Confirm')
	LC:RegisterEvent('LOOT_OPENED', 'Confirm')
	LC:RegisterEvent('LOOT_BIND_CONFIRM', 'Confirm')

	--LC:RegisterEvent('START_LOOT_ROLL')
end
