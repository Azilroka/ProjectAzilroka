local AddOnName = ...
local LSM, EP = LibStub('LibSharedMedia-3.0'), LibStub('LibElvUIPlugin-1.0', true)
local BattlePetBreedID = IsAddOnLoaded('BattlePetBreedID')
local Color = RAID_CLASS_COLORS[select(2, UnitClass('player'))]
local _, BreedData, FriendFrame, EnemyFrame, CurrentTabard, CurrentHelm, BorderColor

local floor, format, unpack, min, max, select = floor, format, unpack, min, max, select

local EnhancedPetBattleUI = CreateFrame('Frame', 'EnhancedPetBattleUI', UIParent)

local Defaults = {
	['AlwaysShow'] = false,
	['HideBlizzard'] = false,
	['GrowUp'] = false,
	['StatusBarTexture'] = IsAddOnLoaded("ElvUI") and ElvUI[1].private.general.normTex or IsAddOnLoaded("Tukui") and "Tukui" or "Blizzard",
	['Font'] = IsAddOnLoaded("ElvUI") and ElvUI[1].db.general.font or IsAddOnLoaded("Tukui") and "Tukui Pixel" or "Arial Narrow",
	['FontSize'] = 12,
	['FontFlag'] = IsAddOnLoaded("Tukui") and "MONOCHROMEOUTLINE" or "OUTLINE",
	['TextOffset'] = 2,
	['EnhanceTooltip'] = true,
	['LevelBreakdown'] = true,
	['PetTrackerIcon'] = false,
	['TeamAurasOnBottom'] = true,
}

EnhancedPetBattleUIOptions = CopyTable(Defaults)

EnhancedPetBattleUI['Version'] = GetAddOnMetadata(AddOnName, 'Version')
EnhancedPetBattleUI['Title'] = GetAddOnMetadata(AddOnName, 'Title')
EnhancedPetBattleUI['TexturePath'] = [[Interface\AddOns\EnhancedPetBattleUI\Textures\]]
EnhancedPetBattleUI['TooltipHealthIcon'] = '|TInterface\\PetBattles\\PetBattle-StatIcons:16:16:0:0:32:32:16:32:16:32|t'
EnhancedPetBattleUI['TooltipPowerIcon'] = '|TInterface\\PetBattles\\PetBattle-StatIcons:16:16:0:0:32:32:0:16:0:16|t'
EnhancedPetBattleUI['TooltipSpeedIcon'] = '|TInterface\\PetBattles\\PetBattle-StatIcons:16:16:0:0:32:32:0:16:16:32|t'

local TexCoords = { 0.1, 0.9, 0.1, 0.9 }

local CelestialTournamentMapID = 1161;

local function round(num, idp)
	local mult = 10^(idp or 0)
	return floor(num * mult + 0.5) / mult
end

local function clamp(num, minVal, maxVal)
	return min(max(num, minVal), maxVal)
end

function EnhancedPetBattleUI:EnableMover(frame, PetOwner)
	if IsAddOnLoaded('ElvUI') then
		local isFriend = PetOwner == LE_BATTLE_PET_ALLY;
		ElvUI[1]:CreateMover(frame, 
			isFriend and "BattlePetMover" or "EnemyBattlePetMover",
			isFriend and "Battle Pet Frames" or "Enemy Battle Pet Frames", 
			nil, nil, nil, "ALL,SOLO"
		)
	elseif IsAddOnLoaded('Tukui') then
		Tukui[1]['Movers']:RegisterFrame(frame)
	else
		frame:SetMovable(true)
	end
end

function EnhancedPetBattleUI:GetLevelBreakdown(PetID)
    if not (PetTracker or BattlePetBreedID) then return end
	if not BreedData then return end
	if not PetID or PetID == "0x0000000000000000" then return 0, 10, 0 end

    local SpeciesID, _, Level, _, _, _,_ ,_, _, _, _, _, _, _, CanBattle = C_PetJournal.GetPetInfoByPetID(PetID)

    if not CanBattle then return 0, 10, 0 end
    local Health, _, Power, Speed, Rarity = C_PetJournal.GetPetStats(PetID)

    local BaseStats = BreedData.speciesToBaseStatProfile[SpeciesID]

    if (not BaseStats) then
    	return false
    end

    local BreedBonusPerLevel = {
        clamp(round((((Health-100)/5) / BreedData.qualityMultiplier[Rarity]) - Level*BaseStats[1],1)/Level,0,2),
        clamp(round((Power / BreedData.qualityMultiplier[Rarity]) - Level*BaseStats[2],1)/Level,0,2),
        clamp(round((Speed / BreedData.qualityMultiplier[Rarity]) - Level*BaseStats[3],1)/Level,0,2),
    }

    return BreedBonusPerLevel
end

function EnhancedPetBattleUI:GetHighestQuality(EnemySpeciesID)
	local NumPets = C_PetJournal.GetNumPets()
	local MaxQuality = -1
	local BestLevel = -1
	for i = 1, NumPets do
		local PetID, SpeciesID, _, _, Level = C_PetJournal.GetPetInfoByIndex(i, true)
		if PetID and SpeciesID == EnemySpeciesID then
			local Quality = select(5, C_PetJournal.GetPetStats(PetID))
			if Quality == nil then Quality = -1 end
			if MaxQuality < Quality then
				MaxQuality = Quality
			end
			if BestLevel < Level then
				BestLevel = Level
			end
		end
	end
	return MaxQuality, BestLevel
end

function EnhancedPetBattleUI:SetAuraTooltipScripts(frame)
	frame:SetScript('OnEnter', function(self,...)
		local auraID, instanceID, turnsRemaining, isBuff, casterOwner, casterIndex = C_PetBattles.GetAuraInfo(self.petOwner, self.petIndex, self.auraIndex)
		if not auraID then return end
		local id, name, icon, maxCooldown, description = C_PetBattles.GetAbilityInfoByID(auraID)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 2, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddTexture(icon)
		GameTooltip:AddDoubleLine(name, auraID, isBuff and 0 or 1, isBuff and 1 or 0, 0, 1, 1, .7)
		GameTooltip:AddLine(' ')
		PetBattleAbilityTooltip_SetAbilityByID(self.petOwner, self.petIndex, auraID)
		GameTooltip:AddLine(SharedPetAbilityTooltip_ParseText(PET_BATTLE_ABILITY_INFO, description), 1, 1, 1)
		GameTooltip:AddLine(' ')
		local remaining = function(r)
			return r > 3 and { 0, 1, 0 } or r > 2 and { 1, 1, 0 } or { 1, 0, 0 }
		end
		local c1, c2, c3 = unpack(remaining(turnsRemaining))
		if turnsRemaining > 0 then
			GameTooltip:AddLine(turnsRemaining..' |cffffffffTurns Remaining|r', c1, c2, c3)
		end
		GameTooltip:Show()
	end)
	frame:SetScript('OnLeave', GameTooltip_Hide)
end

function EnhancedPetBattleUI:HealthColorGradient(perc, ...)
	if perc >= 1 then
		return select(select('#', ...) - 2, ...)
	elseif perc <= 0 then
		return ...
	end

	local num = select('#', ...) / 3
	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

function EnhancedPetBattleUI:CreateUIFrame(Name, PetOwner, PetIndex, Parent)
	local Frame = CreateFrame('Frame', Name..PetIndex, Parent)
	Frame.petOwner = PetOwner
	Frame.petIndex = PetIndex
	Frame:Hide()
	Frame:SetSize(260, 60)
	Frame:SetFrameLevel(Parent:GetFrameLevel() + 1)
	Frame:SetTemplate('Transparent', true)
	Frame.BorderColor = { Frame:GetBackdropBorderColor() }
	Frame:CreateShadow()
	Frame:EnableMouse(true)
	if (not IsAddOnLoaded('ElvUI')) then
		Frame:RegisterForDrag('LeftButton')
		Frame:SetScript('OnDragStart', function(self) self:GetParent():StartMoving() end)
		Frame:SetScript('OnDragStop', function(self) self:GetParent():StopMovingOrSizing() end)
	end
	Frame:RegisterEvent('PLAYER_ENTERING_WORLD')
	Frame:RegisterEvent('PET_BATTLE_MAX_HEALTH_CHANGED')
	Frame:RegisterEvent('PET_BATTLE_HEALTH_CHANGED')
	Frame:RegisterEvent('PET_BATTLE_AURA_APPLIED')
	Frame:RegisterEvent('PET_BATTLE_AURA_CANCELED')
	Frame:RegisterEvent('PET_BATTLE_AURA_CHANGED')
	Frame:RegisterEvent('PET_BATTLE_XP_CHANGED')
	Frame:RegisterEvent('PET_BATTLE_OPENING_START')
	Frame:RegisterEvent('PET_BATTLE_OPENING_DONE')
	Frame:RegisterEvent('PET_BATTLE_CLOSE')
	Frame:RegisterEvent('BATTLE_PET_CURSOR_CLEAR')
	Frame:RegisterEvent('PET_JOURNAL_LIST_UPDATE')
	Frame:SetScript('OnEvent', function(self, event)
		local PetID, NumPets, CustomName, Level, XP, MaxXP, PetName, Icon, PetType, HP, MaxHP, Power, Speed, Rarity, _ = C_PetJournal.GetPetLoadOutInfo(self.petIndex)
		local AlwaysShow = EnhancedPetBattleUIOptions['AlwaysShow'] and self.petOwner == LE_BATTLE_PET_ALLY and true or nil
		local InPetBattle = C_PetBattles.IsInBattle()
		local WildBattle = C_PetBattles.IsWildBattle()

		if event == 'PET_BATTLE_OPENING_START' or AlwaysShow then
			self:Hide()
			if not InPetBattle and AlwaysShow then
				if PetID then
					self:Show()
				end
			end
			if InPetBattle then
				if self.petOwner == LE_BATTLE_PET_ALLY then
					NumPets = C_PetBattles.GetNumPets(1)
					for i = 1, 3 do
						if self.petIndex <= NumPets then
							self:Show()
						end
					end
				else
					NumPets = C_PetBattles.GetNumPets(2)
					for i = 1, 3 do
						if self.petIndex <= NumPets then
							self:Show()
						end
					end
				end
			end
		end

		if event == 'PET_BATTLE_CLOSE' then
			if self.petOwner == LE_BATTLE_PET_ENEMY then
				self.Icon.PetTexture:SetDesaturated(false)
				self.Icon.Dead:Hide()
			end
			self.Icon.Speed:SetVertexColor(1, 1, 0)
			self.OldPower = nil
			self.OldSpeed = nil
		end

		if not self:IsShown() then return end

		if not InPetBattle and self.petOwner == LE_BATTLE_PET_ALLY then
			SpeciesID, CustomName, Level, XP, MaxXP, _, _, PetName, Icon, PetType = C_PetJournal.GetPetInfoByPetID(PetID)
			HP, MaxHP, Power, Speed, Rarity = C_PetJournal.GetPetStats(PetID)
		elseif InPetBattle then
			SpeciesID = C_PetBattles.GetPetSpeciesID(self.petOwner, self.petIndex)
			CustomName, PetName = C_PetBattles.GetName(self.petOwner, self.petIndex)
			Level = C_PetBattles.GetLevel(self.petOwner, self.petIndex)
			XP, MaxXP = C_PetBattles.GetXP(self.petOwner, self.petIndex)
			Icon = C_PetBattles.GetIcon(self.petOwner, self.petIndex)
			PetType = C_PetBattles.GetPetType(self.petOwner, self.petIndex)
			HP, MaxHP = C_PetBattles.GetHealth(self.petOwner, self.petIndex), C_PetBattles.GetMaxHealth(self.petOwner, self.petIndex)
			Power = C_PetBattles.GetPower(self.petOwner, self.petIndex)
			Speed = C_PetBattles.GetSpeed(self.petOwner, self.petIndex)
			Rarity = C_PetBattles.GetBreedQuality(self.petOwner, self.petIndex)
			if not self.OldPower then self.OldPower = Power end
			if not self.OldSpeed then self.OldSpeed = Speed end

			if self.petOwner == LE_BATTLE_PET_ENEMY and WildBattle then
				self.TargetID = C_PetBattles.GetPetSpeciesID(self.petOwner, self.petIndex)
				self.Owned = C_PetJournal.GetOwnedBattlePetString(self.TargetID)
				self:SetBackdropBorderColor(unpack(self.BorderColor))
				if self.Owned == nil or self.Owned == 'Not Collected' then
					C_PetJournal.SetSearchFilter("")
					C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, true)
					for i = 1, C_PetJournal.GetNumPets() do
						local _, Species, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, Obtainable = C_PetJournal.GetPetInfoByIndex(i)
						if Obtainable and SpeciesID == Species then
							self:SetBackdropBorderColor(1, 0, 0)
						end
					end
				else
					local ColorBorder
					local OwnedQuality, OwnedLevel = EnhancedPetBattleUI:GetHighestQuality(self.TargetID)
					if OwnedQuality ~= -1 and OwnedQuality < Rarity then
						ColorBorder = true
					elseif OwnedQuality == Rarity then
						if OwnedLevel > 20 then
							OwnedLevel = OwnedLevel + 2
						elseif OwnedLevel > 15 then
							OwnedLevel = OwnedLevel + 1
						end
						if Level > OwnedLevel then
							ColorBorder = true
						end
					end
					if ColorBorder then
						self:SetBackdropBorderColor(1, 0.35, 0)
					end
				end
			end
		end

		if event == 'PET_BATTLE_OPENING_START' or AlwaysShow then
			local R, G, B = GetItemQualityColor(Rarity - 1)

			self.Name:SetTextColor(R, G, B)
			self.Name:SetText(CustomName or PetName)

			if PetTracker then
				local Breed = PetTracker.Predict:Breed(SpeciesID, Level, Rarity, MaxHP, Power, Speed)
				self.BreedID:SetText(EnhancedPetBattleUIOptions['PetTrackerIcon'] and PetTracker:GetBreedIcon(Breed, .9) or PetTracker:GetBreedName(Breed))
			elseif BattlePetBreedID then
				self.BreedID:SetText(InPetBattle and GetBreedID_Battle(self) or GetBreedID_Journal(PetID))
			end

			self.Icon:SetBackdropBorderColor(R, G, B)
			self.Icon.PetTexture:SetTexture(Icon)

			self.Level:SetText(Level)

			self.Icon.PetType:SetTexture(EnhancedPetBattleUI.TexturePath..PET_TYPE_SUFFIX[PetType])
		end
		
		if event == 'PET_BATTLE_XP_CHANGED' or event == 'PET_BATTLE_OPENING_START' or AlwaysShow then
			self.Experience:SetMinMaxValues(0, MaxXP)
			self.Experience:SetValue(XP)
			self.Experience.Text:SetFormattedText('%s / %s', XP, MaxXP)
		end

		if event == 'PET_BATTLE_MAX_HEALTH_CHANGED' or event == 'PET_BATTLE_HEALTH_CHANGED' or event == 'PET_BATTLE_OPENING_START' or AlwaysShow then
			if HP == 0 then
				self.Icon.PetTexture:SetDesaturated(true)
				self.Icon.Dead:Show()
			else
				self.Icon.PetTexture:SetDesaturated(false)
				self.Icon.Dead:Hide()
			end

			local R, G, B = EnhancedPetBattleUI:HealthColorGradient((HP/MaxHP), 1, 0, 0, 1, 1, 0, 0, 1, 0)

			self.Health:SetStatusBarColor(R, G, B)
			self.Health:SetMinMaxValues(0, MaxHP)
			self.Health:SetValue(HP)
			self.Health.Text:SetFormattedText('%s / %s', HP, MaxHP)
		end

		EnhancedPetBattleUI:SetupAuras(self, self.petOwner, self.petIndex)
		if self.OldPower and self.OldSpeed then
			if Power > self.OldPower then
				self.Power:SetTextColor(0, 1, 0)
			elseif Power < self.OldPower then
				self.Power:SetTextColor(1, 0, 0)
			else
				self.Power:SetTextColor(1, 1, 1)
			end

			if Speed > self.OldSpeed then
				self.Speed:SetTextColor(0, 1, 0)
			elseif Speed < self.OldSpeed then
				self.Speed:SetTextColor(1, 0, 0)
			else
				self.Speed:SetTextColor(1, 1, 1)
			end
		end
		self.Power:SetText(Power)
		self.Speed:SetText(Speed)
		if InPetBattle then
			local activeally = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY)
			local activeenemy = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
			if C_PetBattles.GetSpeed(LE_BATTLE_PET_ALLY, activeally) > C_PetBattles.GetSpeed(LE_BATTLE_PET_ENEMY, activeenemy) then
				_G[FriendFrame..activeally].Icon.Speed:SetVertexColor(0, 1, 0)
				_G[EnemyFrame..activeenemy].Icon.Speed:SetVertexColor(1, 0, 0)
			elseif C_PetBattles.GetSpeed(LE_BATTLE_PET_ALLY, activeally) < C_PetBattles.GetSpeed(LE_BATTLE_PET_ENEMY, activeenemy) then
				_G[FriendFrame..activeally].Icon.Speed:SetVertexColor(1, 0, 0)
				_G[EnemyFrame..activeenemy].Icon.Speed:SetVertexColor(0, 1, 0)
			else
				self.Icon.Speed:SetVertexColor(1, 1, 0)
			end
		end
	end)

	Frame.Icon = CreateFrame('Frame', nil, Frame)
	Frame.Icon:SetTemplate('Transparent')
	Frame.Icon:SetFrameLevel(Frame:GetFrameLevel() + 1)
	Frame.Icon:SetSize(40, 40)

	Frame.Icon.PetTexture = Frame.Icon:CreateTexture(nil, 'ARTWORK')
	Frame.Icon.PetTexture:SetTexCoord(unpack(TexCoords))
	Frame.Icon.PetTexture:SetInside()

	Frame.Icon.Dead = Frame.Icon:CreateTexture(nil, 'OVERLAY')
	Frame.Icon.Dead:Hide()
	Frame.Icon.Dead:SetTexture(self.TexturePath..'Dead')
	Frame.Icon.Dead:SetOutside(Frame.Icon, 8, 8)

	Frame.Icon.PetType = Frame:CreateTexture(nil, 'ARTWORK')
	Frame.Icon.PetType:SetSize(32, 32)
	Frame.Icon.PetType.Tooltip = CreateFrame('Frame', nil, Frame)
	Frame.Icon.PetType.Tooltip:SetSize(32, 32)
	Frame.Icon.PetType.Tooltip:SetScript('OnEnter', function(self)
		local parent = self:GetParent()
		local petType = C_PetBattles.GetPetType(parent.petOwner, parent.petIndex)
		local auraID = PET_BATTLE_PET_TYPE_PASSIVES[petType];
		PetBattleAbilityTooltip_SetAuraID(parent.petOwner, parent.petIndex, auraID)
		PetBattlePrimaryAbilityTooltip:ClearAllPoints();
		PetBattlePrimaryAbilityTooltip:SetPoint('BOTTOMRIGHT', parent, 'TOPRIGHT', 0, 2)
		PetBattlePrimaryAbilityTooltip:Show()
	end)
	Frame.Icon.PetType.Tooltip:SetScript('OnLeave', function() PetBattlePrimaryAbilityTooltip:Hide() end)

	Frame.Icon.Power = Frame:CreateTexture(nil, 'OVERLAY')
	Frame.Icon.Power:SetTexture([[Interface\PetBattles\PetBattle-StatIcons]])
	Frame.Icon.Power:SetSize(16, 16)

	Frame.Icon.Speed = Frame:CreateTexture(nil, 'OVERLAY')
	Frame.Icon.Speed:SetTexture([[Interface\PetBattles\PetBattle-StatIcons]])
	Frame.Icon.Speed:SetSize(16, 16)

	Frame.Power = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Speed = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Name = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Level = Frame.Icon:CreateFontString(nil, 'OVERLAY')
	Frame.BreedID = Frame.Icon:CreateFontString(nil, 'OVERLAY')

	Frame.Health = CreateFrame('StatusBar', nil, Frame)
	Frame.Health:SetSize(150, 11)
	Frame.Health:SetFrameLevel(Frame:GetFrameLevel() + 2)
	Frame.Health:CreateBackdrop('Transparent', true)
	Frame.Health.Text = Frame.Health:CreateFontString(nil, 'OVERLAY')

	Frame.Experience = CreateFrame('StatusBar', nil, Frame)
	Frame.Experience:SetSize(150, 11)
	Frame.Experience:SetFrameLevel(Frame:GetFrameLevel() + 2)
	Frame.Experience:CreateBackdrop('Transparent', true)
	Frame.Experience.Text = Frame.Experience:CreateFontString(nil, 'OVERLAY')

	EnhancedPetBattleUI:BuildAuras(Frame, PetOwner, PetIndex)

	if PetOwner == LE_BATTLE_PET_ALLY then
		Frame.Icon:SetPoint('LEFT', Frame, 'LEFT', 6, 0)
		Frame.Icon.PetType:SetPoint('TOPRIGHT', Frame, 'TOPRIGHT', 0, 0)
		Frame.Icon.PetType.Tooltip:SetAllPoints(Frame.Icon.PetType)
		Frame.Level:SetPoint('BOTTOMRIGHT', Frame.Icon, 0, 3)
		Frame.Level:SetJustifyV('BOTTOM') Frame.Level:SetJustifyH('RIGHT')
		Frame.BreedID:SetPoint('TOPLEFT', Frame.Icon, 3, -2)
		Frame.BreedID:SetJustifyV('TOP') Frame.BreedID:SetJustifyH('LEFT')
		Frame.Health:SetPoint('LEFT', Frame.Icon, 'RIGHT', 8, 3)
		Frame.Health.Text:SetJustifyV('TOP') Frame.Health.Text:SetJustifyH('CENTER')
		Frame.Experience:SetPoint('TOP', Frame.Health, 'BOTTOM', 0, -5)
		Frame.Experience.Text:SetJustifyV('TOP') Frame.Experience.Text:SetJustifyH('CENTER')
		Frame.Icon.Power:SetPoint('TOPLEFT', Frame.Health, 'RIGHT', 4, 8)
		Frame.Icon.Power:SetTexCoord(0, .5, 0, .5)
		Frame.Power:SetPoint('LEFT', Frame.Icon.Power, 'RIGHT', 4, 2)
		Frame.Icon.Speed:SetPoint('TOPLEFT', Frame.Experience, 'RIGHT', 4, 8)
		Frame.Icon.Speed:SetTexCoord(0, .5, .5, 1)
		Frame.Speed:SetPoint('LEFT', Frame.Icon.Speed, 'RIGHT', 4, 0)
		Frame.Name:SetPoint('BOTTOMLEFT', Frame.Health, 'TOPLEFT', 0, 4)
		Frame.Name:SetJustifyH('LEFT')
		Frame.BuffHolder:SetPoint('TOPLEFT', Frame, 'TOPRIGHT', 3, 1)
		Frame.DebuffHolder:SetPoint('BOTTOMLEFT', Frame, 'BOTTOMRIGHT', 3, -1)
	else
		Frame.Icon:SetPoint('RIGHT', Frame, 'RIGHT', -6, 0)
		Frame.Icon.PetType:SetPoint('TOPLEFT', Frame, 'TOPLEFT', 0, 0)
		Frame.Icon.PetType.Tooltip:SetAllPoints(Frame.Icon.PetType)
		Frame.Level:SetPoint('BOTTOMLEFT', Frame.Icon, 'BOTTOMLEFT', 4, 2)
		Frame.Level:SetJustifyV('BOTTOM') Frame.Level:SetJustifyH('LEFT')
		Frame.BreedID:SetPoint('TOPRIGHT', Frame.Icon, -1, -2)
		Frame.BreedID:SetJustifyV('TOP') Frame.BreedID:SetJustifyH('RIGHT')
		Frame.Health:SetPoint('RIGHT', Frame.Icon, 'LEFT', -8, 3)
		Frame.Health:SetReverseFill(true)
		Frame.Health.Text:SetJustifyV('TOP') Frame.Health.Text:SetJustifyH('CENTER')
		Frame.Experience:SetPoint('TOP', Frame.Health, 'BOTTOM', 0, -5)
		Frame.Experience:SetReverseFill(true)
		Frame.Experience.Text:SetJustifyV('TOP') Frame.Experience.Text:SetJustifyH('CENTER')
		Frame.Icon.Power:SetPoint('TOPRIGHT', Frame.Health, 'LEFT', -4, 8)
		Frame.Icon.Power:SetTexCoord(0, .5, 0, .5)
		Frame.Power:SetPoint('RIGHT', Frame.Health, 'LEFT', -18, 0)
		Frame.Icon.Speed:SetPoint('TOPRIGHT', Frame.Experience, 'LEFT', -4, 8)
		Frame.Icon.Speed:SetTexCoord(.5, 0, .5, 1)
		Frame.Speed:SetPoint('RIGHT', Frame.Experience, 'LEFT', -18, 0)
		Frame.Name:SetPoint('BOTTOMRIGHT', Frame.Health, 'TOPRIGHT', 2, 4)
		Frame.Name:SetJustifyH('RIGHT')
		Frame.BuffHolder:SetPoint('TOPRIGHT', Frame, 'TOPLEFT', -3, 1)
		Frame.DebuffHolder:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMLEFT', -3, -1)
		Frame.Icon:EnableMouse(true)
		Frame.Icon:SetScript('OnEnter', function(self, ...)
			C_PetJournal.SetSearchFilter("")
			C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true)
			C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_FAVORITES, false)
			C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, false)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 2, 4)
			GameTooltip:ClearLines()
			local parent = self:GetParent()
			if parent.Owned ~= nil then GameTooltip:AddLine(parent.Owned) end
			for i = 1, C_PetJournal.GetNumPets(false) do 
				local PetID, SpeciesID, _, _, Level, _, _, _, _, PetType = C_PetJournal.GetPetInfoByIndex(i)
				if SpeciesID == parent.TargetID and PetID then
					local _, MaxHealth, Power, Speed, Rarity = C_PetJournal.GetPetStats(PetID)
					local PetLink = C_PetJournal.GetBattlePetLink(PetID)
					if PetLink then
						GameTooltip:AddLine(' ')
						local Breed, BreedIndex, H25, P25, S25 = ''
						if PetTracker then
							BreedIndex = PetTracker.Predict:Breed(SpeciesID, Level, Rarity, MaxHealth, Power, Speed)
							Breed = EnhancedPetBattleUIOptions['PetTrackerIcon'] and PetTracker:GetBreedIcon(BreedIndex, 1) or PetTracker:GetBreedName(BreedIndex)
							H25, P25, S25 = PetTracker.Predict:Stats(SpeciesID, 25, Rarity, BreedIndex)
						elseif BattlePetBreedID then
							BPBID_Options.format = 1 -- Forcing it, No Choice, I need this info
							BreedIndex = GetBreedID_Battle(parent)
							BPBID_Options.format = 3 -- Forcing it, No Choice, I need this info
							Breed = GetBreedID_Battle(parent)
							H25 = ceil((BPBID_Arrays.BasePetStats[SpeciesID][1] + BPBID_Arrays.BreedStats[BreedIndex][1]) * 25 * ((BPBID_Arrays.RealRarityValues[Rarity] - 0.5) * 2 + 1) * 5 + 100 - 0.5)
							P25 = ceil((BPBID_Arrays.BasePetStats[SpeciesID][2] + BPBID_Arrays.BreedStats[BreedIndex][2]) * 25 * ((BPBID_Arrays.RealRarityValues[Rarity] - 0.5) * 2 + 1) - 0.5)
							S25 = ceil((BPBID_Arrays.BasePetStats[SpeciesID][3] + BPBID_Arrays.BreedStats[BreedIndex][3]) * 25 * ((BPBID_Arrays.RealRarityValues[Rarity] - 0.5) * 2 + 1) - 0.5)
						end
						GameTooltip:AddDoubleLine(PetLink, Breed, 1, 1, 1, 1, 1, 1)
						GameTooltip:AddDoubleLine('Species ID', SpeciesID, 1, 1, 1, 1, 0, 0)
						if EnhancedPetBattleUIOptions['EnhanceTooltip'] and (PetTracker or BattlePetBreedID) then
							GameTooltip:AddDoubleLine(format('%s %d', LEVEL, Level), format('%s %d', LEVEL, 25), 1, 1, 1, 1, 1, 1)
							GameTooltip:AddDoubleLine(format('%s %s', EnhancedPetBattleUI.TooltipHealthIcon, MaxHealth), H25, 1, 1, 1, 1, 1, 1)
							GameTooltip:AddDoubleLine(format('%s %s', EnhancedPetBattleUI.TooltipPowerIcon, Power), P25, 1, 1, 1, 1, 1, 1)
							GameTooltip:AddDoubleLine(format('%s %s', EnhancedPetBattleUI.TooltipSpeedIcon, Speed), S25, 1, 1, 1, 1, 1, 1)
							GameTooltip:AddDoubleLine('Breed Index', BreedIndex, 1, 1, 1, 1, 1, 1)
							if EnhancedPetBattleUIOptions['LevelBreakdown'] then
								local BaseStats = EnhancedPetBattleUI:GetLevelBreakdown(PetID)
								if BaseStats then
									local HPDS, PBDS, SBDS = unpack(BaseStats)
									local SPL = format('%s%s %s%s %s%s', EnhancedPetBattleUI.TooltipHealthIcon, round(HPDS, 2), EnhancedPetBattleUI.TooltipPowerIcon, round(PBDS, 2), EnhancedPetBattleUI.TooltipSpeedIcon, round(SBDS, 2))
									GameTooltip:AddLine(' ')
									GameTooltip:AddDoubleLine('Stats Per Level', SPL, 1, 1, 1, 1, 1, 1)
								end
							end
						else
							local RightString = format('%s%s %s%s %s%s', EnhancedPetBattleUI.TooltipHealthIcon, MaxHealth, EnhancedPetBattleUI.TooltipPowerIcon, Power, EnhancedPetBattleUI.TooltipSpeedIcon, Speed)
							GameTooltip:AddDoubleLine(format('%s %d', LEVEL, Level), RightString, 1, 1, 1, 1, 1, 1)
						end
					end
				end
			end
			GameTooltip:Show()
		end)
		Frame.Icon:SetScript('OnLeave', GameTooltip_Hide)
	end
end

function EnhancedPetBattleUI:BuildAuras(Frame, PetOwner, PetIndex)
	Frame.BuffHolder = CreateFrame('Frame', nil, Frame)
	Frame.BuffHolder:SetSize(99, 30)
	RegisterStateDriver(Frame.BuffHolder, 'visibility', '[petbattle] show; hide')

	Frame.DebuffHolder = CreateFrame('Frame', nil, Frame)
	Frame.DebuffHolder:SetSize(99, 30)
	RegisterStateDriver(Frame.DebuffHolder, 'visibility', '[petbattle] show; hide')

	local point, relativePoint, xcoord
	if PetOwner == LE_BATTLE_PET_ALLY then
		point, relativePoint, xcoord = 'LEFT', 'RIGHT', 3
	else
		point, relativePoint, xcoord = 'RIGHT', 'LEFT', -3
	end

	for i = 1, 3 do
		Frame.BuffHolder['Buff'..i] = CreateFrame('Frame', nil, Frame.BuffHolder)
		Frame.BuffHolder['Buff'..i].petOwner = PetOwner
		Frame.BuffHolder['Buff'..i].petIndex = PetIndex
		Frame.BuffHolder['Buff'..i]:SetTemplate()
		Frame.BuffHolder['Buff'..i]:SetBackdropBorderColor(0, 1, 0)
		Frame.BuffHolder['Buff'..i]:Hide()
		Frame.BuffHolder['Buff'..i]:SetSize(28, 28)
		Frame.BuffHolder['Buff'..i].Text = Frame.BuffHolder['Buff'..i]:CreateFontString(nil, 'OVERLAY')
		Frame.BuffHolder['Buff'..i].Text:SetPoint('CENTER')
		Frame.BuffHolder['Buff'..i].Texture = Frame.BuffHolder['Buff'..i]:CreateTexture(nil, 'ARTWORK')
		Frame.BuffHolder['Buff'..i].Texture:SetInside()
		Frame.BuffHolder['Buff'..i].Texture:SetTexCoord(unpack(TexCoords))

		Frame.DebuffHolder['Debuff'..i] = CreateFrame('Frame', nil, Frame)
		Frame.DebuffHolder['Debuff'..i].petOwner = PetOwner
		Frame.DebuffHolder['Debuff'..i].petIndex = PetIndex
		Frame.DebuffHolder['Debuff'..i]:SetTemplate()
		Frame.DebuffHolder['Debuff'..i]:SetBackdropBorderColor(1, 0, 0)
		Frame.DebuffHolder['Debuff'..i]:Hide()
		Frame.DebuffHolder['Debuff'..i]:SetSize(28, 28)
		Frame.DebuffHolder['Debuff'..i].Text = Frame.DebuffHolder['Debuff'..i]:CreateFontString(nil, 'OVERLAY')
		Frame.DebuffHolder['Debuff'..i].Text:SetPoint('CENTER')
		Frame.DebuffHolder['Debuff'..i].Texture = Frame.DebuffHolder['Debuff'..i]:CreateTexture(nil, 'ARTWORK')
		Frame.DebuffHolder['Debuff'..i].Texture:SetInside()
		Frame.DebuffHolder['Debuff'..i].Texture:SetTexCoord(unpack(TexCoords))

		if i == 1 then
			Frame.BuffHolder['Buff'..i]:SetPoint(point, Frame.BuffHolder, point, 0, 0)
			Frame.DebuffHolder['Debuff'..i]:SetPoint(point, Frame.DebuffHolder, point, 0, 0)
		else
			Frame.BuffHolder['Buff'..i]:SetPoint(point, Frame.BuffHolder['Buff'..i-1], relativePoint, xcoord, 0)
			Frame.DebuffHolder['Debuff'..i]:SetPoint(point, Frame.DebuffHolder['Debuff'..i-1], relativePoint, xcoord, 0)
		end

		EnhancedPetBattleUI:SetAuraTooltipScripts(Frame.BuffHolder['Buff'..i])
		EnhancedPetBattleUI:SetAuraTooltipScripts(Frame.DebuffHolder['Debuff'..i])
	end
end

function EnhancedPetBattleUI:SetUpTeamAuras(Parent, PetOwner)
	local Frame = CreateFrame('Frame', Parent:GetName()..'AuraHolder', Parent)
	Frame.petOwner = PetOwner
	Frame.petIndex = 0
	Frame:RegisterEvent('PET_BATTLE_AURA_APPLIED')
	Frame:RegisterEvent('PET_BATTLE_AURA_CANCELED')
	Frame:RegisterEvent('PET_BATTLE_AURA_CHANGED')
	Frame:RegisterEvent('PET_BATTLE_OPENING_START')
 	Frame:SetScript('OnEvent', function(self, event)
 		if (event == 'PET_BATTLE_OPENING_START') then
 			local NumPets, Name
 			local point, relativePoint, xcoord, ycoord 
			if self.petOwner == LE_BATTLE_PET_ALLY then
				NumPets = EnhancedPetBattleUIOptions['TeamAurasOnBottom'] and C_PetBattles.GetNumPets(1) or 1
				Name = 'EnhancedPetBattleUI_Pet'
			else
				Name = 'EnhancedPetBattleUI_EnemyPet'
				NumPets = EnhancedPetBattleUIOptions['TeamAurasOnBottom'] and C_PetBattles.GetNumPets(2) or 1
			end
 			if EnhancedPetBattleUIOptions['GrowUp'] then
				if EnhancedPetBattleUIOptions['TeamAurasOnBottom'] then
					point, relativePoint, xcoord, ycoord = 'BOTTOM', 'TOP', 0, 4
				else
					pont, relativePoint, xcoord, ycoord = 'TOP', 'BOTTOM', 0, -4
				end
			else 
				if EnhancedPetBattleUIOptions['TeamAurasOnBottom'] then
					point, relativePoint, xcoord, ycoord = 'TOP', 'BOTTOM', 0, -4
				else
					point, relativePoint, xcoord, ycoord = 'BOTTOM', 'TOP', 0, 4
				end
			end

			self:ClearAllPoints()
			self:SetPoint(point, Name..NumPets, relativePoint, xcoord, ycoord)
		end
		
		EnhancedPetBattleUI:SetupAuras(self, self.petOwner, self.petIndex)
	end)
	Frame:SetSize(260, 30)
	Frame:EnableMouse(false)

	EnhancedPetBattleUI:BuildAuras(Frame, PetOwner, 0)

	local BuffPoint, DebuffPoint
	if PetOwner == LE_BATTLE_PET_ALLY then
		BuffPoint, DebuffPoint = 'TOPLEFT', 'TOPRIGHT'
	else
		BuffPoint, DebuffPoint = 'TOPRIGHT', 'TOPLEFT'
	end

	Frame.BuffHolder:SetPoint(BuffPoint, Frame)
	Frame.DebuffHolder:SetPoint(DebuffPoint, Frame)
end

function EnhancedPetBattleUI:EnableAura(frame, auraIndex, icon, turnsRemaining)
	frame.auraIndex = auraIndex
	frame:Show()
	frame.Text:SetFont(LSM:Fetch('font', EnhancedPetBattleUIOptions['Font']), 20, EnhancedPetBattleUIOptions['FontFlag'])
	frame.Text:SetText(turnsRemaining > 0 and turnsRemaining or '')
	frame.Texture:SetTexture(icon)
end

function EnhancedPetBattleUI:SetupAuras(frame, owner, index)
	for i = 1, 3 do
		frame.BuffHolder['Buff'..i]:Hide()
		frame.DebuffHolder['Debuff'..i]:Hide()
	end
	for i = 1, 6 do
		local auraID, _, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(owner, index, i)
		if not auraID then return end
		local _, _, icon = C_PetBattles.GetAbilityInfoByID(auraID)
		if isBuff then
			if not frame.BuffHolder['Buff1']:IsShown() then
				EnhancedPetBattleUI:EnableAura(frame.BuffHolder['Buff1'], i, icon, turnsRemaining)
			elseif not frame.BuffHolder['Buff2']:IsShown() then
				EnhancedPetBattleUI:EnableAura(frame.BuffHolder['Buff2'], i, icon, turnsRemaining)
			elseif not frame.BuffHolder['Buff3']:IsShown() then
				EnhancedPetBattleUI:EnableAura(frame.BuffHolder['Buff3'], i, icon, turnsRemaining)
			end
		else
			if not frame.DebuffHolder['Debuff1']:IsShown() then
				EnhancedPetBattleUI:EnableAura(frame.DebuffHolder['Debuff1'], i, icon, turnsRemaining)
			elseif not frame.DebuffHolder['Debuff2']:IsShown() then
				EnhancedPetBattleUI:EnableAura(frame.DebuffHolder['Debuff2'], i, icon, turnsRemaining)
			elseif not frame.DebuffHolder['Debuff3']:IsShown() then
				EnhancedPetBattleUI:EnableAura(frame.DebuffHolder['Debuff3'], i, icon, turnsRemaining)
			end
		end
	end
end

local BaseFrameNames = {}

function EnhancedPetBattleUI:Update()
	local NormTex = LSM:Fetch('statusbar', EnhancedPetBattleUIOptions['StatusBarTexture'])
	local Font = LSM:Fetch('font', EnhancedPetBattleUIOptions['Font'])
	local FontSize = EnhancedPetBattleUIOptions['FontSize']
	local FontFlag = EnhancedPetBattleUIOptions['FontFlag']
	local Offset = EnhancedPetBattleUIOptions['TextOffset']
	local point, relativePoint, xcoord, ycoord
	local InstanceType = select(2, IsInInstance())

	if (InstanceType == 'party' or InstanceType == 'raid' or InstanceType == 'pvp' or InstanceType == 'arena' or not EnhancedPetBattleUIOptions['AlwaysShow']) then
		RegisterStateDriver(AllyFrameHolder, 'visibility', '[petbattle] show; hide')
	else
		RegisterStateDriver(AllyFrameHolder, 'visibility', '[combat] hide; show')
	end

	if EnhancedPetBattleUIOptions['GrowUp'] then
		point, relativePoint, xcoord, ycoord = 'BOTTOM', 'TOP', 0, 4
	else
		point, relativePoint, xcoord, ycoord = 'TOP', 'BOTTOM', 0, -4
	end

	BandageBattlePetButton.Text:SetFont(Font, FontSize, FontFlag)

	for Key, Frame in pairs(BaseFrameNames) do
		for i = 1, 3 do
			_G[Frame..i]:ClearAllPoints()

			if i == 1 then
				_G[Frame..i]:SetPoint(point, _G[Frame..i]:GetParent(), point, 0, 0)
			else
				_G[Frame..i]:SetPoint(point, _G[Frame..i-1], relativePoint, xcoord, ycoord)
			end

			_G[Frame..i].Name:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].Level:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].BreedID:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].Health:SetStatusBarTexture(NormTex)
			_G[Frame..i].Experience:SetStatusBarTexture(NormTex)
			_G[Frame..i].Experience:SetStatusBarColor(.24, .54, .78)
			_G[Frame..i].Health.Text:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].Experience.Text:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].Power:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].Speed:SetFont(Font, FontSize, FontFlag)
			_G[Frame..i].Health.Text:SetPoint('TOP', _G[Frame..i].Health, 'TOP', 0, Offset)
			_G[Frame..i].Experience.Text:SetPoint('TOP', _G[Frame..i].Experience, 'TOP', 0, Offset)

			for j = 1, 3 do
				_G[Frame..i].BuffHolder['Buff'..j].Text:SetFont(Font, 20, FontFlag)
				_G[Frame..i].DebuffHolder['Debuff'..j].Text:SetFont(Font, 20, FontFlag)
			end
		end
	end
end

local function GetOptions()

	local Options = {
		type = 'group',
		name = EnhancedPetBattleUI.Title,
		order = 101,
		args = {
			general = {
				order = 2,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return EnhancedPetBattleUIOptions[info[#info]] end,
				set = function(info, value) EnhancedPetBattleUIOptions[info[#info]] = value EnhancedPetBattleUI:Update() end, 
				args = {
					AlwaysShow = {
						order = 1,
						type = 'toggle',
						name = 'Always Show',
						desc = 'Always show the unit frames even when not in battle',
					},
					HideBlizzard = {
						order = 2,
						type = 'toggle',
						name = 'Hide Blizzard',
						desc = 'Hide the Blizzard Pet Frames during battles',
					},
					GrowUp = {
						order = 3,
						type = 'toggle',
						name = 'Grow the frames upwards',
						desc = 'Grow the frames from bottom for first pet upwards',
					},
					TeamAurasOnBottom = {
						order = 4,
						type = 'toggle',
						name = 'Team Aura On Bottom',
						desc = 'Place team auras on the bottom of the last pet shown (or top if Grow upwards is selected)',
					},
					PetTrackerIcon = {
						order = 5,
						type = 'toggle',
						name = 'Use PetTracker Icon',
						desc = 'Use PetTracker Icon instead of Breed ID',
						disabled = function() return not IsAddOnLoaded('PetTracker') end,
					},
					EnhanceTooltip = {
						order = 6,
						type = 'toggle',
						name = 'Enhance Tooltip',
						desc = 'Add More Detailed Info if BreedInfo is available.',
						disabled = function() return not (PetTracker or BattlePetBreedID) end,
					},
					LevelBreakdown = {
						order = 7,
						type = 'toggle',
						name = 'Level Breakdown',
						desc = 'Add Pet Level Breakdown if BreedInfo is available.',
						disabled = function() return not (EnhancedPetBattleUIOptions['EnhanceTooltip'] and (PetTracker or BattlePetBreedID)) end,
					},
					StatusBarTexture = {
						type = 'select', dialogControl = 'LSM30_Statusbar',
						order = 8,
						name = 'StatusBar Texture',
						values = AceGUIWidgetLSMlists.statusbar,
					},
					Font = {
						type = 'select', dialogControl = 'LSM30_Font',
						order = 9,
						name = 'Font',
						values = AceGUIWidgetLSMlists.font,
					},
					FontSize = {
						order = 10,
						name = 'Font Size',
						type = 'range',
						min = 8, max = 24, step = 1,
					},
					FontFlag = {
						name = 'Font Flag',
						order = 11,
						type = 'select',
						values = {
							['NONE'] = 'None',
							['OUTLINE'] = 'OUTLINE',
							['MONOCHROME'] = 'MONOCHROME',
							['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
							['THICKOUTLINE'] = 'THICKOUTLINE',
						},
					},
					TextOffset = {
						order = 12,
						name = 'Health/Experience Text Offset',
						type = 'range',
						min = -10, max = 10, step = 1,
					},
				},
			},
			about = {
				type = "group",
				name = "About/Help",
				order = -2,
				args = {
					header = {
						order = 6,
						type = 'header',
						name = '',
					},
					desc = {
						order = 7,
						type = "description",
						fontSize = "medium",
						name = CONFIRM_RESET_SETTINGS,
					},
					resetsettings = {
						type = 'execute',
						order = 8,
						name = 'Reset Settings',
						confirm = true,
						func = function() EnhancedPetBattleUIOptions = CopyTable(Defaults) end,
					},
				},
			},
		},
	}

	if EP then
		local Ace3OptionsPanel = IsAddOnLoaded("ElvUI") and ElvUI[1] or Enhanced_Config and Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.EnhancedPetBattleUI = Options
	else
		local ACR, ACD = LibStub("AceConfigRegistry-3.0", true), LibStub("AceConfigDialog-3.0", true)
		if not (ACR or ACD) then return end
		ACR:RegisterOptionsTable("EnhancedPetBattleUI", Options)
		ACD:AddToBlizOptions("EnhancedPetBattleUI", "EnhancedPetBattleUI", nil, "about")
		for k, v in pairs(Options.args) do
			if k ~= 'about' then
				ACD:AddToBlizOptions("EnhancedPetBattleUI", v.name, "EnhancedPetBattleUI", k)
			end
		end
	end
end

local function FixBandageButton(self)
	if (GetItemInfo(86143)) then
		BandageBattlePetButton.Icon:SetTexture(select(10, GetItemInfo(86143)));
		BandageBattlePetButton:SetAttribute('item', GetItemInfo(86143));
		return true;
	end
	return false;
end

EnhancedPetBattleUI:RegisterEvent('ADDON_LOADED')
EnhancedPetBattleUI:RegisterEvent('PLAYER_ENTERING_WORLD')
EnhancedPetBattleUI:SetScript('OnEvent', function(self, event, addon)
	if (event == "GET_ITEM_INFO_RECEIVED") then
		if (FixBandageButton(self)) then
			self:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
		end
	elseif addon == AddOnName then
		local BreedInfo = LibStub('LibPetBreedInfo-1.0', true)
		if BreedInfo then BreedData = BreedInfo.breedData self:UnregisterEvent(event) end

		GetOptions()

		FriendFrame, EnemyFrame = 'EnhancedPetBattleUI_Pet', 'EnhancedPetBattleUI_EnemyPet'
		tinsert(BaseFrameNames, 'EnhancedPetBattleUI_Pet')
		tinsert(BaseFrameNames, 'EnhancedPetBattleUI_EnemyPet')

		local AllyFrameHolder = CreateFrame('Frame', 'AllyFrameHolder', UIParent)
		AllyFrameHolder:SetFrameLevel(0)
		AllyFrameHolder:Hide()
		AllyFrameHolder:SetSize(260, 188)
		AllyFrameHolder:SetPoint('RIGHT', UIParent, 'BOTTOM', -200, 200)
		AllyFrameHolder:SetClampedToScreen(true)
		AllyFrameHolder:SetFrameStrata('BACKGROUND')
		AllyFrameHolder:RegisterEvent('PLAYER_ENTERING_WORLD')

		EnhancedPetBattleUI:SetUpTeamAuras(AllyFrameHolder, LE_BATTLE_PET_ALLY)

		local EnemyFrameHolder = CreateFrame('Frame', 'EnemyFrameHolder', UIParent)
		EnemyFrameHolder:SetSize(260, 188)
		EnemyFrameHolder:SetPoint('LEFT', UIParent, 'BOTTOM', 200, 200)
		EnemyFrameHolder:SetMovable()
		EnemyFrameHolder:SetClampedToScreen(true)
		EnemyFrameHolder:SetFrameStrata('BACKGROUND')
		RegisterStateDriver(EnemyFrameHolder, 'visibility', '[petbattle] show; hide')

		EnhancedPetBattleUI:SetUpTeamAuras(EnemyFrameHolder, LE_BATTLE_PET_ENEMY)

		for i = 1, 3 do
			EnhancedPetBattleUI:CreateUIFrame(FriendFrame, LE_BATTLE_PET_ALLY, i, AllyFrameHolder)
			EnhancedPetBattleUI:CreateUIFrame(EnemyFrame, LE_BATTLE_PET_ENEMY, i, EnemyFrameHolder)
		end

		EnhancedPetBattleUI:EnableMover(AllyFrameHolder, LE_BATTLE_PET_ALLY);
		EnhancedPetBattleUI:EnableMover(EnemyFrameHolder, LE_BATTLE_PAY_ENEMY);

		EnemyFrameHolder:SetScript('OnHide', function(self)
			for i = 1, 3 do
				_G[EnemyFrame..i]:Hide()
			end
		end)

		local EnhancedPetBattleUIExtraActionButtonHolder = CreateFrame('Frame', 'EnhancedPetBattleUIExtraActionButtonHolder', UIParent)
		EnhancedPetBattleUIExtraActionButtonHolder:SetSize(104, 50)
		EnhancedPetBattleUIExtraActionButtonHolder:SetFrameStrata('BACKGROUND')
		EnhancedPetBattleUIExtraActionButtonHolder:SetClampedToScreen(true)
		EnhancedPetBattleUIExtraActionButtonHolder:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		if IsAddOnLoaded('ElvUI') then
			ElvUI[1]:CreateMover(EnhancedPetBattleUIExtraActionButtonHolder, "PetBattleUIExtraActionButtonAnchor", "PetBattleUI ExtraAction", nil, nil, nil, "ALL,SOLO")
		else
			EnhancedPetBattleUIExtraActionButtonHolder:SetMovable(true)
		end
		RegisterStateDriver(EnhancedPetBattleUIExtraActionButtonHolder, 'visibility', '[petbattle][combat] hide; show')

		local function CreateExtraActionButton(name, type, id)
			local func = type == 'spell' and _G['GetSpellInfo'] or _G['GetItemInfo']
			local index = type == 'spell' and 3 or 10
			local hyperlink = type == 'spell' and GetSpellLink(id) or select(2, GetItemInfo(id))
			local Frame = CreateFrame('CheckButton', name..'Button', EnhancedPetBattleUIExtraActionButtonHolder, 'SecureActionButtonTemplate')
			Frame:SetSize(50, 50)
			Frame:SetAttribute('type', type)
			Frame:SetAttribute(type, func(id))
			Frame:SetTemplate('Default')
			Frame.BorderColor = { Frame:GetBackdropBorderColor() }
			Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
			Frame.Icon:SetTexture(select(index, func(id)));
			Frame.Icon:SetInside()
			Frame.Icon:SetTexCoord(unpack(TexCoords))
			Frame.Cooldown = CreateFrame('Cooldown', nil, Frame)
			Frame.Cooldown:SetAllPoints(Frame.Icon)
			Frame.Cooldown:SetScript('OnUpdate', function(self, elapsed)
				local Start, Duration = GetSpellCooldown(id)
				if Duration and Duration > 1.5 then
					self:SetCooldown(Start, Duration)
				end
			end)
			if IsAddOnLoaded('ElvUI') then ElvUI[1]:RegisterCooldown(Frame.Cooldown) end
			Frame:RegisterForDrag('LeftButton')
			Frame:SetScript('OnDragStart', function(self) self:GetParent():StartMoving() end)
			Frame:SetScript('OnDragStop', function(self) self:GetParent():StopMovingOrSizing() end)
			Frame:SetScript('OnEnter', function(self, ...)
				self:SetBackdropBorderColor(Color.r, Color.g, Color.b)
				GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT', 2, 4)
				GameTooltip:ClearLines()
				if (hyperlink) then
					GameTooltip:SetHyperlink(hyperlink)
				end
				GameTooltip:Show()
			end)
			Frame:SetScript('OnLeave', function(self)
				self:SetBackdropBorderColor(unpack(self.BorderColor))
				GameTooltip:Hide()
			end)
			Frame:RegisterEvent('PLAYER_ENTERING_WORLD')
			Frame:RegisterEvent('PET_JOURNAL_LIST_UPDATE')
			Frame:RegisterEvent('BAG_UPDATE')
			Frame:SetScript('OnEvent', function(self, event)
				if UnitAffectingCombat('player') then self:RegisterEvent('PLAYER_REGEN_ENABLED') return end
				local Health, MaxHealth, Show
				for i = 1, 3 do
					local PetID = C_PetJournal.GetPetLoadOutInfo(i)
					if PetID ~= nil then
						Health, MaxHealth = C_PetJournal.GetPetStats(PetID)
						if Health < (MaxHealth * .3) then
							Show = true
							break
						end
					end
				end
				if (select(4, UnitPosition("player")) == CelestialTournamentMapID) then
					Show = false;
				end
				if self.Text then
					local Count = GetItemCount(86143)
					if Count > 0 then
						self.Text:SetText(Count)
						self.Icon:SetDesaturated(false)
					elseif Count == 0 then
						self.Text:SetText()
						self.Icon:SetDesaturated(true)
					end
				end
				if Show then
					self:Show()
				else
					self:Hide()
				end
				self:UnregisterEvent('PLAYER_REGEN_ENABLED')
			end)
		end

		CreateExtraActionButton('ReviveBattlePet', 'spell', 125439)
		ReviveBattlePetButton:SetPoint('LEFT', EnhancedPetBattleUIExtraActionButtonHolder, 'LEFT', 0, 0)

		CreateExtraActionButton('BandageBattlePet', 'item', 86143)
		BandageBattlePetButton:SetPoint('RIGHT', EnhancedPetBattleUIExtraActionButtonHolder, 'RIGHT', 0, 0)
		
		if (not GetItemInfo(86143)) then
			self:RegisterEvent("GET_ITEM_INFO_RECEIVED");
		end
		
		BandageBattlePetButton.Text = BandageBattlePetButton:CreateFontString(nil, 'OVERLAY')
		BandageBattlePetButton.Text:SetFont(LSM:Fetch('font', EnhancedPetBattleUIOptions['Font']), EnhancedPetBattleUIOptions['FontSize'], EnhancedPetBattleUIOptions['FontFlag'])
		BandageBattlePetButton.Text:SetPoint('BOTTOMRIGHT', BandageBattlePetButton, 0, 2)

		AllyFrameHolder:SetScript('OnEvent', self.Update)

		EnhancedPetBattleUI:Update()
	end
	if event == 'ADDON_LOADED' then
		BreedInfo = LibStub('LibPetBreedInfo-1.0', true)
		if BreedInfo then
			BreedData = BreedInfo.breedData
			self:UnregisterEvent(event)
		end
	end
	if event == 'PLAYER_ENTERING_WORLD' then
		print(format('%s by |cFFFF7D0AAzilroka|r - Version: |cff1784d1%s|r Loaded!', self.Title, self.Version))
		self:UnregisterEvent(event)
	end
end)

hooksecurefunc('PetBattleAuraHolder_Update', function(self)
	if not EnhancedPetBattleUIOptions['HideBlizzard'] then return end
	if not (self.petOwner and self.petIndex) then return end
	local nextFrame = 1
	for i = 1, C_PetBattles.GetNumAuras(self.petOwner, self.petIndex) do
		local frame = self.frames[nextFrame]
		if not frame then return end

		frame.DebuffBorder:Hide()
		frame:Hide()
		if frame.backdrop then
			frame.backdrop:Hide()
		end
		frame.Icon:Hide()
		frame.Duration:SetText(turnsRemaining)
		nextFrame = nextFrame + 1
	end
end)

PetBattleFrame:HookScript('OnEvent', function(self, event)
	if EnhancedPetBattleUIOptions['HideBlizzard'] then
		PetBattleFrame.ActiveAlly:Hide()
		PetBattleFrame.Ally2:Hide()
		PetBattleFrame.Ally3:Hide()
		PetBattleFrame.ActiveEnemy:Hide()
		PetBattleFrame.Enemy2:Hide()
		PetBattleFrame.Enemy3:Hide()
		PetBattleFrame.TopVersusText:Hide()
	else
		PetBattleFrame.ActiveAlly:Show()
		local AllyPets = C_PetBattles.GetNumPets(1)
		local EnemyPets = C_PetBattles.GetNumPets(2)
		if AllyPets > 1 then
			for i = 2, AllyPets do
				PetBattleFrame['Ally'..i]:Show()
			end
		end
		if EnemyPets > 1 then
			for i = 2, EnemyPets do
				PetBattleFrame['Enemy'..i]:Show()
			end
		end
		PetBattleFrame.ActiveEnemy:Show()
		PetBattleFrame.TopVersusText:Show()
	end
	PetBattleFrameXPBar:Hide()
	if C_PetBattles.IsWildBattle() or C_PetBattles.IsPlayerNPC(2) then
		PetBattleFrame.BottomFrame.TurnTimer:Hide()
	else
		PetBattleFrame.BottomFrame.TurnTimer:Show()
	end
end)