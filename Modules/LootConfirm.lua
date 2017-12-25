local PA = _G.ProjectAzilroka
local LC = PA:NewModule('LootConfirm', 'AceEvent-3.0')
_G.LootConfirm = LC

LC.Title = '|cFF16C3F2Loot|r |cFFFFFFFFConfirm|r'
LC.Description = 'Confirms Loot for Solo/Groups (Need/Greed/Disenchant)'
LC.Authors = 'Azilroka, Infinitron'

local tonumber, strmatch, select = tonumber, strmatch, select
local ConfirmLootRoll, GetNumLootItems, ConfirmLootSlot, CloseLoot = ConfirmLootRoll, GetNumLootItems, ConfirmLootSlot, CloseLoot
local RollOnLoot = RollOnLoot
local IsEquippableItem, GetItemInfo, GetInventoryItemLink = IsEquippableItem, GetItemInfo, GetInventoryItemLink
local GetLootRollItemInfo, GetLootRollItemLink = GetLootRollItemInfo, GetLootRollItemLink

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

	RollOnLoot(id, self.db['Disenchant'] and Disenchant and LOOT_ROLL_TYPE_DISENCHANT or LOOT_ROLL_TYPE_GREED)
end

function LC:ADDON_LOADED(event, addon)
	if addon == 'ElvUI_Config' then
		ElvUI[1].Options.args.general.args.general.args.autoRoll.disabled = true
		self:UnregisterEvent(event)
	end
end

function LC:GetOptions()
	local Options = {
		type = 'group',
		name = LC.Title,
		desc = LC.Description,
		order = 208,
		args = {
			header = {
				order = 0,
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
					Confirm = {
						order = 1,
						type = 'toggle',
						name = PA.ACL['Auto Confirm'],
						desc = PA.ACL['Automatically click OK on BOP items'],
					},
					Greed = {
						order = 2,
						type = 'toggle',
						name = PA.ACL['Auto Greed'],
						desc = PA.ACL['Automatically greed'],
					},
					Disenchant = {
						order = 3,
						type = 'toggle',
						name = PA.ACL['Auto Disenchant'],
						desc = PA.ACL['Automatically disenchant'],
					},
					ByLevel = {
						order = 4,
						type = 'toggle',
						name = PA.ACL['Auto-roll based on a given level'],
						desc = PA.ACL['This will auto-roll if you are above the given level if: You cannot equip the item being rolled on, or the ilevel of your equipped item is higher than the item being rolled on or you have an heirloom equipped in that slot'],
					},
					Level = {
						order = 5,
						type = 'range',
						name = PA.ACL['Level to start auto-rolling from'],
						min = 1, max = MAX_PLAYER_LEVEL, step = 1,
						disabled = function() return not LC.db['ByLevel'] end,
					},
				},
			},
		},
	}

	PA.Options.args.LootConfirm = Options
end

function LC:BuildProfile()
	self.data = PA.ADB:New("EnhancedShadowsDB", {
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

	self.data.RegisterCallback(self, "OnProfileChanged", "SetupProfile")
	self.data.RegisterCallback(self, "OnProfileCopied", "SetupProfile")
	self.db = self.data.profile
end

function LC:SetupProfile()
	self.db = self.data.profile
end

function LC:Initialize()
	self:BuildProfile()
	self:GetOptions()

	UIParent:UnregisterEvent('LOOT_BIND_CONFIRM')
	UIParent:UnregisterEvent('CONFIRM_DISENCHANT_ROLL')
	UIParent:UnregisterEvent('CONFIRM_LOOT_ROLL')

	self:RegisterEvent('CONFIRM_DISENCHANT_ROLL', 'HandleEvent')
	self:RegisterEvent('CONFIRM_LOOT_ROLL', 'HandleEvent')
	self:RegisterEvent('LOOT_OPENED', 'HandleEvent')
	self:RegisterEvent('LOOT_BIND_CONFIRM', 'HandleEvent')
	--self:RegisterEvent('START_LOOT_ROLL')

	if PA.ElvUI then
		ElvUI[1].db.general.autoRoll = false
		self:RegisterEvent("ADDON_LOADED")
	end
end