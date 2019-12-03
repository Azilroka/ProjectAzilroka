local PA = _G.ProjectAzilroka
if PA.Retail then return end

local BN = PA:NewModule('BuffsNotice', 'AceEvent-3.0')
PA.BN = BN

BN.Title = PA.ACL['|cFF16C3F2Buffs|r |cFFFFFFFFNotice|r']
BN.Description = ''
BN.Authors = 'Azilroka    Tukz'

local pairs = pairs
local select = select
local IsSpellKnown = IsSpellKnown
local GetSpellInfo = GetSpellInfo
local GetSpellTexture = GetSpellTexture
local UnitAffectingCombat = UnitAffectingCombat
local UnitInVehicle = UnitInVehicle
local UnitBuff = UnitBuff
local PlaySoundFile = PlaySoundFile
local GetSpecialization = GetSpecialization
local UnitLevel = UnitLevel
local GetInventorySlotInfo = GetInventorySlotInfo
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemID = GetInventoryItemID

local WarningSound = 'Interface/AddOns/ProjectAzilroka/Warning.mp3'

local BuffReminder1 = {
	['DEATHKNIGHT'] = {
		6673, -- Battle Shout
		57330, -- Horn of Winter
		93435, -- Roar of Courage (Hunter Pet)
	},
	['DRUID'] = {
		1126, -- Mark of the Wild
		20217, -- Blessing of Kings
		90363, -- Embrace of the Shale Spider
		117666, -- Legacy of the Emperor
	},
	['HUNTER'] = {
		5118, -- Aspect of the Cheetah
		13159, -- Aspect of the Pack
		13165, -- Aspect of the Hawk
		109260, -- Aspect of the Iron Hawk
	},
	['MAGE'] = {
		6117, -- Mage Armor
		7302, -- Frost Armor
		30482, -- Molten Armor
	},
	['MONK'] = {
		1126, -- Mark of the Wild
		20217, -- Blessing of Kings
		90363, -- Embrace of the Shale Spider
		116781, -- Legacy of the White Tiger
		117666, -- Legacy of the Emperor
	},
	['PALADIN'] = {
		1126, -- Mark of the Wild
		19740, -- Blessing of Might
		20217, -- Blessing of Kings
		90363, -- Embrace of the Shale Spider
		117666, -- Legacy of the Emperor
	},
	['PRIEST'] = {
		588, -- Inner Fire
		73413, -- Inner Will
	},
	['ROGUE'] = {
		2823, -- Deadly Poison
		8679, -- Wound Poison
	},
	['SHAMAN'] = {
		324, -- Lightning Shield
		974, -- Earth Shield
		52127, -- Water Shield
	},
	['WARLOCK'] = {
		109773, -- Dark Intent
	},
	['WARRIOR'] = {
		469, -- Commanding Shout
		6673, -- Battle Shout
		93435, -- Roar of Courage (Hunter Pet)
		57330, -- Horn of Winter
		21562, -- PW: Fortitude
	},
}

local BuffReminder2 = {
	['DEATHKNIGHT'] = {
		48263, -- Blood Presence
		48265, -- Unholy Presence
		48266, -- Frost Presence
	},
	['MAGE'] = {
		1459, -- Arcane Brilliance
		61316, -- Dalaran Brilliance
	},
	['PRIEST'] = {
		21562, -- PW: Fortitude
	},
	['ROGUE'] = {
		3408, -- Crippling Poison
		5761, -- Mind-numbing Poison
		108211, -- Leeching Poison
		108215, -- Paralytic Poison
	},
}

local PlaySound = true

local function PositionFrames(self, event)
	BuffsWarning1:ClearAllPoints()
	BuffsWarning2:ClearAllPoints()
	WeaponBuffs:ClearAllPoints()
	local Width = 40
	BuffsWarning1:SetPoint('LEFT', BuffsWarningFrame, 'LEFT', 0, 0)
	BuffsWarning2:SetPoint('LEFT', BuffsWarningFrame, 'LEFT', BuffsWarning1:IsShown() and 48 or 0, 0)
	WeaponBuffs:SetPoint('LEFT', BuffsWarningFrame, 'LEFT', BuffsWarning1:IsShown() and 48 or 0, 0)
	if BuffsWarning1:IsShown() and (BuffsWarning2:IsShown() or WeaponBuffs:IsShown()) then Width = 88 end
	BuffsWarningFrame:SetWidth(Width)
	BuffsWarningFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 100)
end

local function OnEvent(self, event)
	if event == 'PLAYER_LOGIN' then AddEvents(self) end
	if event == 'PLAYER_LOGIN' or event == 'SPELLS_CHANGED' then
		for key, buff in pairs(self.Buffs) do
			if IsSpellKnown(buff) then
				self.Icon:SetTexture(GetSpellTexture(GetSpellInfo(buff)))
				break
			end
		end
	end
	if self.Icon:GetTexture() == nil then return end
	if UnitAffectingCombat('player') and not UnitInVehicle('player') then
		for key, buff in pairs(self.Buffs) do
			if UnitBuff('player', GetSpellInfo(buff)) then
				self:Hide()
				return
			end
		end
		self:Show()
		if PlaySound == true then
			PlaySound = false
			PlaySoundFile(WarningSound)
		end
	else
		self:Hide()
	end
	PositionFrames()
end

local function WeaponBuffsOnEvent(self, event)
	if MyClass ~= 'SHAMAN' then return end
	if event == 'PLAYER_LOGIN' then AddEvents(self) end

	if UnitLevel('player') < 10 then return end

	local MainHandTexture, OffHandTexture
	local Spec = GetSpecialization()
	if Spec == 3 and IsSpellKnown(51730) then
		MainHandTexture = select(3, GetSpellInfo(51730))
	elseif Spec == 2 and IsSpellKnown(8232) then
		MainHandTexture = select(3, GetSpellInfo(8232))
		OffHandTexture = select(3, GetSpellInfo(8024))
	else
		MainHandTexture = select(3, GetSpellInfo(8024))
	end

	self.Icon:SetTexture(MainHandTexture)
	if UnitAffectingCombat('player') and not UnitInVehicle('player') then
		local MainHand, MainHandTime, _, OffHand, OffHandTime = GetWeaponEnchantInfo()
		local OffHandWeapon = GetInventoryItemID('player', GetInventorySlotInfo('SecondaryHandSlot'))
		if OffHand and select(6, GetItemInfo(OffHandWeapon)) == ENCHSLOT_WEAPON then
			if MainHand ~= nil then self.Icon:SetTexture(OffHandTexture) end
			if MainHand and OffHand then
				self:Hide()
				return
			end
		elseif MainHand then
			self:Hide()
			return
		end
		self:Show()
		if PlaySound == true then
			PlaySound = false
			PlaySoundFile(WarningSound)
		end
	else
		self:Hide()
	end
	PositionFrames()
end

local function CreateWarningFrame(Name)
	local Frame = CreateFrame('Frame', Name, BuffsWarningFrame)
	Frame:Hide()
	Frame:SetSize(40, 40)
	Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
	Frame.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	Frame:SetTemplate()
	Frame.Icon:SetInside()
	Frame:RegisterEvent('PLAYER_LOGIN')

	return Frame
end

local ThrottleTime, TimeStart = 30, 0
local function SoundThrottle(self, elapsed)
	TimeStart = TimeStart + elapsed
	if TimeStart > ThrottleTime then
		if PlaySound == false then
			PlaySound = true
		end
		TimeStart = 0
	end
end

function BN:BuildProfile()
	PA.Defaults.profile.BuffsNotice = {
		Enable = false,
	}

	PA.Options.args.general.args.BuffsNotice = {
		type = 'toggle',
		name = BN.Title,
		desc = BN.Description,
	}
end

function BN:Initialize()
	BN.db = PA.db['QuestSounds']

	if BN.db.Enable ~= true then
		return
	end

	local BuffsWarning1 = CreateWarningFrame('BuffsWarning1')
	BuffsWarning1.Buffs = BuffReminder1[MyClass]
	BuffsWarning1:SetScript('OnEvent', OnEvent)

	local BuffsWarning2 = CreateWarningFrame('BuffsWarning2')
	BuffsWarning2.Buffs = BuffReminder2[MyClass] or {}
	BuffsWarning2:SetScript('OnEvent', OnEvent)

	local WeaponBuffs = CreateWarningFrame('WeaponBuffs')
	WeaponBuffs:SetScript('OnEvent', WeaponBuffsOnEvent)

	local BuffsWarningFrame = CreateFrame('Frame', 'BuffsWarningFrame', UIParent)
	BuffsWarningFrame:SetSize(40, 40)
	BuffsWarningFrame:SetScript('OnUpdate', SoundThrottle)
	--BN:GetOptions()

	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	self:RegisterEvent('SPELLS_CHANGED')
	self:RegisterEvent('PLAYER_TALENT_UPDATE')
	self:RegisterUnitEvent('UNIT_AURA', 'player')
	self:RegisterUnitEvent('UNIT_INVENTORY_CHANGED', 'player')
	self:RegisterUnitEvent('UNIT_ENTERING_VEHICLE', 'player')
	self:RegisterUnitEvent('UNIT_ENTERED_VEHICLE', 'player')
	self:RegisterUnitEvent('UNIT_EXITING_VEHICLE', 'player')
	self:RegisterUnitEvent('UNIT_EXITED_VEHICLE', 'player')
end
