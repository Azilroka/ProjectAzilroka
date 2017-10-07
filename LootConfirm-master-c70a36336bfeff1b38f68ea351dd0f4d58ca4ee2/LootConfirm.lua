local AddOnName = ...
local LC = LibStub('AceAddon-3.0'):NewAddon('LootConfirm', 'AceEvent-3.0')
local EP

local Defaults = {
	['Confirm'] = true,
	['Greed'] = false,
	['Disenchant'] = false,
	['ByLevel'] = false,
	['Level'] = GetMaxPlayerLevel(),
}

LootConfirmOptions = CopyTable(Defaults)

local AutoGreed = {
	[43102] = true,
	[52078] = true,
}

function LC:GetOptions()
	local Options = {
		type = 'group',
		name = select(2, GetAddOnInfo(AddOnName)),
		order = 3,
		args = {
			header = {
				order = 1,
				type = 'header',
				name = 'Automatic loot confirmation and auto greed/disenchant',
			},
			general = {
				order = 2,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return LootConfirmOptions[info[#info]] end,
    			set = function(info, value) LootConfirmOptions[info[#info]] = value end, 
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
						desc = 'Automatically greed uncommon (green) quality items at max level',
					},
					Disenchant = {
						order = 3,
						type = 'toggle',
						name = 'Auto Disenchant',
						desc = 'Automatically disenchant uncommon (green) quality items at max level'
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
						min = 1, max = GetMaxPlayerLevel(), step = 1,
						disabled = function() return not LootConfirmOptions['ByLevel'] end,
					},
				},
			},
			about = {
				type = "group",
				name = "Help",
				order = -1,
				args = {
					reset = {
						type = 'execute',
						order = 1,
						name = 'Reset Settings',
						desc = CONFIRM_RESET_SETTINGS,
						confirm = true,
						func = function()
							LootConfirmOptions = CopyTable(Defaults)
						end,
					}
				}
			}
		},
	}

	if EP then
		if IsAddOnLoaded('ElvUI') and ElvUI[1].Options.args.general ~= nil then
			if ElvUI[1].db.general then ElvUI[1].db.general.autoRoll = false end
			ElvUI[1].Options.args.general.args.general.args.autoRoll.disabled = function() return true end
		end
		local Ace3OptionsPanel = IsAddOnLoaded("ElvUI") and ElvUI[1] or Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.brokerldb = Options
	else
		local ACR, ACD = LibStub("AceConfigRegistry-3.0", true), LibStub("AceConfigDialog-3.0", true)
		if not (ACR or ACD) then return end
		ACR:RegisterOptionsTable("LootConfirm", Options)
		ACD:AddToBlizOptions("LootConfirm", "LootConfirm", nil, "general")
		for k, v in pairs(Options.args) do
			if k ~= "general" and k ~= 'header' then
				ACD:AddToBlizOptions("LootConfirm", v.name, "LootConfirm", k)
			end
		end
	end
end

function LC:HandleEvent(event, ...)
	if not LootConfirmOptions['Confirm'] then return end
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
local PlayerLevel, MaxPlayerLevel

function LC:START_LOOT_ROLL(event, id)
	if not (LootConfirmOptions['Greed'] or LootConfirmOptions['Disenchant']) then return end
	local Texture, Name, Count, Quality, BindOnPickUp, Need, Greed, Disenchant = GetLootRollItemInfo(id)
	local Link = GetLootRollItemLink(id)
	local ItemID = tonumber(strmatch(Link, 'item:(%d+)'))

	if AutoGreed[ItemID] then
		RollOnLoot(id, LOOT_ROLL_TYPE_GREED)
	end

	if IsXPUserDisabled() then MaxPlayerLevel = PlayerLevel end
	if (LootConfirmOptions['ByLevel'] and PlayerLevel < LootConfirmOptions['Level'] and PlayerLevel ~= MaxPlayerLevel) then return end
	if LootConfirmOptions['ByLevel'] then
		if IsEquippableItem(Link) then
			local _, _, _, ItemLevel, _, _, _, _, Slot = GetItemInfo(Link)
			local ItemLink = GetInventoryItemLink('player', Slot)
			local MatchItemLevel = ItemLink and select(4, GetItemInfo(ItemLink)) or 1
			if Quality ~= 7 and MatchItemLevel < ItemLevel then return end
		end
	end

	if Quality <= LE_ITEM_QUALITY_UNCOMMON then
		if LootConfirmOptions['Disenchant'] and Disenchant then
			RollOnLoot(id, LOOT_ROLL_TYPE_DISENCHANT)
		else
			RollOnLoot(id, LOOT_ROLL_TYPE_GREED)
		end
	end
end

function LC:PLAYER_LEVEL_UP(event, level)
	PlayerLevel = level
end

function LC:Initialize()
	MaxPlayerLevel = GetMaxPlayerLevel()
	PlayerLevel = UnitLevel('player')

	UIParent:UnregisterEvent('LOOT_BIND_CONFIRM')
	UIParent:UnregisterEvent('CONFIRM_DISENCHANT_ROLL')
	UIParent:UnregisterEvent('CONFIRM_LOOT_ROLL')

	self:RegisterEvent('PLAYER_LEVEL_UP')
	self:RegisterEvent('CONFIRM_DISENCHANT_ROLL', 'HandleEvent')
	self:RegisterEvent('CONFIRM_LOOT_ROLL', 'HandleEvent')
	self:RegisterEvent('LOOT_OPENED', 'HandleEvent')
	self:RegisterEvent('LOOT_BIND_CONFIRM', 'HandleEvent')
	self:RegisterEvent('START_LOOT_ROLL')

	EP = LibStub('LibElvUIPlugin-1.0', true)
	if EP then
		EP:RegisterPlugin(AddOnName, LC.GetOptions)
	else
		LC:GetOptions()
	end
end

LC:Initialize()