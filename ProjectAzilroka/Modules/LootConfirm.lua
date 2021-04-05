local PA = _G.ProjectAzilroka
if PA.Retail then return end

local LC = PA:NewModule('LootConfirm', 'AceEvent-3.0')
PA.LC, _G.LootConfirm = LC, LC

LC.Title = PA.ACL['|cFF16C3F2Loot|r |cFFFFFFFFConfirm|r']
LC.Description = PA.ACL['Confirms Loot for Solo/Groups (Need/Greed)']
LC.Authors = 'Azilroka     NihilisticPandemonium'
LC.isEnabled = false

local tonumber = tonumber
local strmatch = strmatch

local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
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

function LC:START_LOOT_ROLL(_, rollID)
	if not (LC.db.Disenchant or LC.db.Greed) then return end

	local texture, name, _, quality, bop, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rollID)
	local itemLink = GetLootRollItemLink(rollID)
	local itemID = tonumber(strmatch(itemLink, 'item:(%d+)'))

	if canDisenchant and LC.db.Disenchant then
		RollOnLoot(rollID, _G.LOOT_ROLL_TYPE_DISENCHANT)
	elseif canGreed and LC.db.Greed then
		RollOnLoot(rollID, _G.LOOT_ROLL_TYPE_GREED)
	end
end

function LC:GetOptions()
	local LootConfirm = PA.ACH:Group(LC.Title, LC.Description, nil, nil, function(info) return LC.db[info[#info]] end)
	PA.Options.args.LootConfirm = LootConfirm

	LootConfirm.args.Description = PA.ACH:Description(LC.Description, 0)
	LootConfirm.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) LC.db[info[#info]] = value if not LC.isEnabled then LC:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	LootConfirm.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	LootConfirm.args.General.inline = true

	LootConfirm.args.General.args.AutoRoll = PA.ACH:Description(PA.ACL['If Disenchant and Greed is selected. It will always try to Disenchant first.'], 0, 'large')
	LootConfirm.args.General.args.Disenchant = PA.ACH:Toggle(PA.ACL['Auto Disenchant'], nil, 1)
	LootConfirm.args.General.args.Greed = PA.ACH:Toggle(PA.ACL['Auto Greed'], nil, 2)

	LootConfirm.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	LootConfirm.args.Authors = PA.ACH:Description(LC.Authors, -1, 'large')
end

function LC:BuildProfile()
	PA.Defaults.profile.LootConfirm = {
		Enable = false,
		Greed = false,
	}
end

function LC:UpdateSettings()
	LC.db = PA.db.LootConfirm
end

function LC:Initialize()
	LC:UpdateSettings()

	if LC.db.Enable ~= true then
		return
	end

	LC.isEnabled = true

	_G.UIParent:UnregisterEvent('LOOT_BIND_CONFIRM')
	_G.UIParent:UnregisterEvent('CONFIRM_LOOT_ROLL')

	LC:RegisterEvent('CONFIRM_LOOT_ROLL', 'Confirm')
	LC:RegisterEvent('LOOT_OPENED', 'Confirm')
	LC:RegisterEvent('LOOT_BIND_CONFIRM', 'Confirm')
	LC:RegisterEvent('START_LOOT_ROLL')
end
