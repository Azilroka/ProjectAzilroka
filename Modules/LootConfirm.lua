local PA = _G.ProjectAzilroka
if PA.Retail then return end

local LC = PA:NewModule('LootConfirm', 'AceEvent-3.0')
PA.LC, _G.LootConfirm = LC, LC

LC.Title = 'Loot Confirm'
LC.Header = PA.ACL['|cFF16C3F2Loot|r |cFFFFFFFFConfirm|r']
LC.Description = PA.ACL['Confirms Loot for Solo/Groups (Need/Greed)']
LC.Authors = 'Azilroka     NihilisticPandemonium'
LC.isEnabled = false

local ConfirmLootRoll = ConfirmLootRoll
local GetNumLootItems = GetNumLootItems
local ConfirmLootSlot = ConfirmLootSlot
local RollOnLoot = RollOnLoot

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

function LC:START_LOOT_ROLL(_, id)
	if not LC.db['Greed'] then return end
	RollOnLoot(id, _G.LOOT_ROLL_TYPE_GREED)
end

function LC:GetOptions()
	PA.Options.args.LootConfirm = {
		type = 'group',
		name = LC.Title,
		desc = LC.Description,
		get = function(info) return LC.db[info[#info]] end,
		set = function(info, value) LC.db[info[#info]] = value end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = LC.Header
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					LC.db[info[#info]] = value
					if (not LC.isEnabled) then
						LC:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
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
end

function LC:BuildProfile()
	PA.Defaults.profile.LootConfirm = {
		Enable = false,
		Greed = false,
	}
end

function LC:Initialize()
	LC.db = PA.db['LootConfirm']

	if LC.db.Enable ~= true then
		return
	end

	LC.isEnabled = true

	_G.UIParent:UnregisterEvent('LOOT_BIND_CONFIRM')
	_G.UIParent:UnregisterEvent('CONFIRM_LOOT_ROLL')

	LC:RegisterEvent('CONFIRM_LOOT_ROLL', 'Confirm')
	LC:RegisterEvent('LOOT_OPENED', 'Confirm')
	LC:RegisterEvent('LOOT_BIND_CONFIRM', 'Confirm')

	--LC:RegisterEvent('START_LOOT_ROLL')
end
