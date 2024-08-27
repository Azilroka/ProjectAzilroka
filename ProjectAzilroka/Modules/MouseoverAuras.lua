local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local MA = PA:NewModule('MouseoverAuras', 'AceEvent-3.0', 'AceTimer-3.0')
_G.MouseoverAuras, PA.MouseoverAuras = MA, MA

MA.Title, MA.Description, MA.Authors, MA.isEnabled = 'Mouseover Auras', ACL['Auras for your mouseover target'], 'Azilroka', false

local floor, tinsert = floor, tinsert

local CreateFrame, UIParent, UnitExists, GetCursorPosition = CreateFrame, UIParent, UnitExists, GetCursorPosition

local VISIBLE, HIDDEN = 1, 0

function MA:GetAuraIcon(index)
	if MA.Holder[index] then
		return MA.Holder[index]
	end

	local button = CreateFrame('Button', 'MouseoverAurasHolderButton'..index, MA.Holder, 'PA_AuraTemplate')
	button.Icon:SetTexCoord(PA:TexCoords())

	PA:SetTemplate(button)
	PA:RegisterCooldown(button.Cooldown)

	MA.Holder.createdIcons = MA.Holder.createdIcons + 1
	tinsert(MA.Holder, button)

	return button
end

function MA:CustomFilter(unit, button, auraData) -- More to be done here
	return auraData.isFromPlayerOrPlayerPet and auraData.duration > 0
end

function MA:UpdateIcon(unit, index, offset, filter, isDebuff, visible)
	local auraData = PA:GetAuraData(unit, index, filter)

	if auraData then
		local position = visible + offset + 1
		local button = MA:GetAuraIcon(position)
		local show = MA:CustomFilter(unit, button, auraData)
		button.caster, button.filter, button.isDebuff, button.isPlayer = auraData.sourceUnit, filter, auraData.isHarmful, auraData.isFromPlayerOrPlayerPet

		if show then
			button:SetBackdropBorderColor(auraData.isHarmful and 1 or 0, 0, 0)
			button:SetSize(MA.db.Size, MA.db.Size)
			button:SetID(index)
			button:SetShown(show)

			button.Cooldown:SetShown(auraData.duration and auraData.duration > 0)
			button.Cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration)
			button.Icon:SetTexture(auraData.icon)
			button.Count:SetText(auraData.applications > 1 and auraData.applications or '')

			return VISIBLE
		end
	end

	return auraData and auraData.name and HIDDEN or nil
end

function MA:SetPosition()
	if not MA.Holder then return end

	local size, anchor, x, y = MA.db.Size + MA.db.Spacing, 'BOTTOMLEFT', 1, -1
	local cols = floor(MA.Holder:GetWidth() / size + 0.5)

	for i, button in ipairs(MA.Holder) do
		if(not button) then break end
		local col, row = (i - 1) % cols, floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, MA.Holder, anchor, col * size * x, row * size * y)
	end
end

function MA:FilterIcons(unit, filter, limit, isDebuff, offset)
	offset = offset or 0

	local visible, hidden = 0, 0

	for index = 1, limit do
		local result = MA:UpdateIcon(unit, index, offset, filter, isDebuff, visible)
		if (not result) then
			break
		elseif (result == VISIBLE) then
			visible = visible + 1
		elseif (result == HIDDEN) then
			hidden = hidden + 1
		end
	end

	local maxButton = visible + offset + 1
	for i, button in ipairs(MA.Holder) do
		if i >= maxButton then
			button:Hide()
		end
	end

	return visible, hidden
end

function MA:UpdateAuras(unit)
	local numBuffs, numDebuffs = 32, 40
	local max = numBuffs + numDebuffs

	local visibleBuffs = MA:FilterIcons(unit, 'HELPFUL', min(numBuffs, max), nil, 0, true)
	local visibleDebuffs = MA:FilterIcons(unit, 'HARMFUL', min(numDebuffs, max - visibleBuffs), true, visibleBuffs)

	if (MA.Holder.createdIcons > MA.Holder.anchoredIcons) then
		MA:SetPosition()
		MA.Holder.anchoredIcons = MA.Holder.createdIcons
	end
end

function MA:Update(elapsed)
	if (not UnitExists('mouseover')) or (PA:GetMouseFocus() and PA:GetMouseFocus():IsForbidden() ) then
		MA.Holder:Hide()
		return
	end

	local scale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()

	MA.Holder:ClearAllPoints()
	MA.Holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (x / scale), (y / scale) - 70)

	MA.Holder.elapsed = MA.Holder.elapsed + elapsed

	if (MA.Holder.elapsed > .25) then
		MA:UpdateAuras('mouseover')
		MA.Holder.elapsed = 0
	end
end

function MA:UPDATE_MOUSEOVER_UNIT()
	local unitExists = UnitExists('mouseover')
	MA.Holder:SetShown(unitExists)
	if unitExists then MA:UpdateAuras('mouseover') end
end

function MA:GetOptions()
	local MouseoverAuras = ACH:Group(MA.Title, MA.Description, nil, 'tab', function(info) return MA.db[info[#info]] end, function(info, value) MA.db[info[#info]] = value MA:SetPosition() end)
	PA.Options.args.MouseoverAuras = MouseoverAuras

	MouseoverAuras.args.Description = ACH:Header(MA.Description, 0)
	MouseoverAuras.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) MA.db[info[#info]] = value if not MA.isEnabled then MA:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	MouseoverAuras.args.General = ACH:Group(ACL['General'], nil, 2)
	MouseoverAuras.args.General.inline = true

	MouseoverAuras.args.General.args.Size = ACH:Range(ACL['Size'], nil, 1, { min = 16, max = 60, step = 1 })
	MouseoverAuras.args.General.args.Spacing = ACH:Range(ACL['Spacing'], nil, 2, { min = 0, max = 20, step = 1 })

	MouseoverAuras.args.AuthorHeader = ACH:Header(ACL['Authors:'], -2)
	MouseoverAuras.args.Authors = ACH:Description(MA.Authors, -1, 'large')
end

function MA:BuildProfile()
	PA.Defaults.profile.MouseoverAuras = {
		Enable = false,
		Size = 16,
		Spacing = 1,
		cooldown = CopyTable(PA.Defaults.profile.Cooldown),
	}
end

function MA:UpdateSettings()
	MA.db = PA.db.MouseoverAuras
end

function MA:Initialize()
	if MA.db.Enable ~= true then
		return
	end

	MA.isEnabled = true

	MA.Holder = CreateFrame('Frame', 'MouseoverAurasHolder', _G.UIParent)
	MA.Holder:SetFrameStrata('TOOLTIP')
	MA.Holder:Hide()
	MA.Holder:SetSize(120, 40)
	MA.Holder:SetScript('OnUpdate', MA.Update)

	MA.Holder.createdIcons, MA.Holder.anchoredIcons, MA.Holder.elapsed = 0, 0, 0

	MA:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
end
