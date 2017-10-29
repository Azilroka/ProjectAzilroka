local PA = _G.ProjectAzilroka
local LC = LibStub('AceAddon-3.0'):NewAddon('LootConfirm', 'AceEvent-3.0')
_G.LootConfirm = LC

LC.Title = 'Loot Confirm'
LC.Version = 2.34
LC.Authors = 'Azilroka, Infinitron'

local tonumber, strmatch, select = tonumber, strmatch, select
local ConfirmLootRoll, GetNumLootItems, ConfirmLootSlot, CloseLoot = ConfirmLootRoll, GetNumLootItems, ConfirmLootSlot, CloseLoot
local RollOnLoot = RollOnLoot
local IsXPUserDisabled = IsXPUserDisabled
local IsEquippableItem, GetItemInfo, GetInventoryItemLink = IsEquippableItem, GetItemInfo, GetInventoryItemLink
local GetLootRollItemInfo, GetLootRollItemLink = GetLootRollItemInfo, GetLootRollItemLink

function LC:GetOptions()
	local Options = {
		type = 'group',
		name = LC.Title,
		order = 208,
		args = {
			header = {
				order = 1,
				type = 'header',
				name = 'Confirms Loot for Solo/Groups (Need/Greed/Disenchant)',
			},
			general = {
				order = 2,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return LC.db[info[#info]] end,
				set = function(info, value) LC.db[info[#info]] = value end,
				args = {
					Confirm = {
						order = 1,
						type = 'toggle',
						name = 'Auto Confirm',
						desc = 'Automatically click OK on BOP items',
					},
					Greed = {
						order = 2,
						type = 'toggle',
						name = 'Auto Greed',
						desc = 'Automatically greed',
					},
					Disenchant = {
						order = 3,
						type = 'toggle',
						name = 'Auto Disenchant',
						desc = 'Automatically disenchant'
					},
					ByLevel = {
						order = 4,
						type = 'toggle',
						name = 'Auto-roll based on a given level',
						desc = 'This will auto-roll if you are above the given level if: You cannot equip the item being rolled on, or the ilevel of your equipped item is higher than the item being rolled on or you have an heirloom equipped in that slot'
					},
					Level = {
						order = 5,
						type = 'range',
						name = 'Level to start auto-rolling from',
						min = 1, max = MAX_PLAYER_LEVEL, step = 1,
						disabled = function() return not LC.db['ByLevel'] end,
					},
				},
			},
		},
	}

	if PA.ElvUI then
		ElvUI[1].db.general.autoRoll = false
		ElvUI[1].Options.args.general.args.general.args.autoRoll.disabled = true
	end

	PA.AceOptionsPanel.Options.args.LootConfirm = Options
end

function LC:UpdateProfile()
	self.data = LibStub("AceDB-3.0"):New("EnhancedShadowsDB", {
		profile = {
			['Confirm'] = true,
			['Greed'] = false,
			['Disenchant'] = false,
			['ByLevel'] = false,
			['Level'] = MAX_PLAYER_LEVEL,
			['AutoGreed'] = {
				[43102] = true,
				[52078] = true,
			}
		},
	})

	self.data.RegisterCallback(self, "OnProfileChanged", "UpdateProfile")
	self.data.RegisterCallback(self, "OnProfileCopied", "UpdateProfile")
	self.db = self.data.profile
end

function LC:HandleEvent(event, ...)
	if not self.db['Confirm'] then return end
	if event == 'CONFIRM_LOOT_ROLL' or event == 'CONFIRM_DISENCHANT_ROLL' then
		local arg1, arg2 = ...
		ConfirmLootRoll(arg1, arg2)
	elseif event == 'LOOT_OPENED' or event == 'LOOT_BIND_CONFIRM' then
		for slot = 1, GetNumLootItems() do
			ConfirmLootSlot(slot)
		end
		if GetNumLootItems() == 0 then
			CloseLoot()
		end
	end
end

-- LOOT_ROLL_TYPE_PASS, LOOT_ROLL_TYPE_NEED

function LC:START_LOOT_ROLL(event, id)
	if not (self.db['Greed'] or self.db['Disenchant']) then return end
	local _, _, _, Quality, _, _, _, Disenchant = GetLootRollItemInfo(id)
	local Link = GetLootRollItemLink(id)
	local ItemID = tonumber(strmatch(Link, 'item:(%d+)'))

	if self.db.AutoGreed[ItemID] then
		RollOnLoot(id, LOOT_ROLL_TYPE_GREED)
	end

	if self.db['ByLevel'] then
		if IsEquippableItem(Link) then
			local _, _, _, ItemLevel, _, _, _, _, Slot = GetItemInfo(Link)
			local ItemLink = GetInventoryItemLink('player', Slot)
			local MatchItemLevel = ItemLink and select(4, GetItemInfo(ItemLink)) or 1
			if Quality ~= 7 and MatchItemLevel < ItemLevel then
				return
			end
		end
	end

	if self.db['Disenchant'] and Disenchant then
		RollOnLoot(id, LOOT_ROLL_TYPE_DISENCHANT)
	else
		RollOnLoot(id, LOOT_ROLL_TYPE_GREED)
	end
end

function LC:Initialize()
	self:UpdateProfile()

	UIParent:UnregisterEvent('LOOT_BIND_CONFIRM')
	UIParent:UnregisterEvent('CONFIRM_DISENCHANT_ROLL')
	UIParent:UnregisterEvent('CONFIRM_LOOT_ROLL')

	self:RegisterEvent('CONFIRM_DISENCHANT_ROLL', 'HandleEvent')
	self:RegisterEvent('CONFIRM_LOOT_ROLL', 'HandleEvent')
	self:RegisterEvent('LOOT_OPENED', 'HandleEvent')
	self:RegisterEvent('LOOT_BIND_CONFIRM', 'HandleEvent')
	self:RegisterEvent('START_LOOT_ROLL')
end
