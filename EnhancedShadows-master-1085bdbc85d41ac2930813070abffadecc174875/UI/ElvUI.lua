function EnhancedShadows:ElvUIShadows()
	local Frames = {
		ElvUI_BottomPanel,
		ElvUI_TopPanel,
		ElvUI_ExperienceBar,
		ElvUI_ReputationBar,
		ElvUI_ConsolidatedBuffs,
		LeftMiniPanel,
		RightMiniPanel,
		GameTooltip,
		--LeftChatDataPanel,
		--LeftChatToggleButton,
		--RightChatDataPanel,
		--RightChatToggleButton,
		ElvConfigToggle,
	}

	local BackdropFrames = {
		ElvUIBags,
		ElvUI_BarPet,
		ElvUI_StanceBar,
		ElvUI_TotemBar,
		LeftChatPanel,
		RightChatPanel,
		Minimap,
		FarmModeMap,
		GameTooltipStatusBar,
	}

	for _, frame in pairs(Frames) do
		if frame then
			frame:CreateShadow()
			EnhancedShadows:RegisterShadow(frame.shadow)
		end
	end
	for _, frame in pairs(BackdropFrames) do
		if frame.backdrop then
			frame.backdrop:CreateShadow()
			EnhancedShadows:RegisterShadow(frame.backdrop.shadow)
		end
	end
	for i = 1, 10 do
		if _G["ElvUI_Bar"..i] then
			_G["ElvUI_Bar"..i].backdrop:CreateShadow()
			EnhancedShadows:RegisterShadow(_G["ElvUI_Bar"..i].backdrop.shadow)
			for k = 1, 12 do
				_G["ElvUI_Bar"..i.."Button"..k].backdrop:CreateShadow()
				EnhancedShadows:RegisterShadow(_G["ElvUI_Bar"..i.."Button"..k].backdrop.shadow)
			end
			_G["ElvUI_Bar"..i].backdrop:HookScript('OnShow', function(self) for k = 1, 12 do _G[self:GetParent():GetName().."Button"..k].backdrop.shadow:Hide() end end)
			_G["ElvUI_Bar"..i].backdrop:HookScript('OnHide', function(self) for k = 1, 12 do _G[self:GetParent():GetName().."Button"..k].backdrop.shadow:Show() end end)
			if _G["ElvUI_Bar"..i].backdrop:IsShown() then
				_G["ElvUI_Bar"..i].backdrop:Hide()
				_G["ElvUI_Bar"..i].backdrop:Show()
			else
				_G["ElvUI_Bar"..i].backdrop:Show()
				_G["ElvUI_Bar"..i].backdrop:Hide()
			end
		end
	end

	-- Stance Bar buttons
	for i = 1, NUM_STANCE_SLOTS do
		local stanceBtn = {_G["ElvUI_StanceBarButton"..i]}
		for _, button in pairs(stanceBtn) do
			if button then
				button:CreateShadow()
				EnhancedShadows:RegisterShadow(button.shadow)
			end
		end
	end
	_G["ElvUI_StanceBar"].backdrop:HookScript('OnShow', function(self) for i = 1, NUM_STANCE_SLOTS do _G[self:GetParent():GetName().."Button"..i].shadow:Hide() end end)
	_G["ElvUI_StanceBar"].backdrop:HookScript('OnHide', function(self) for i = 1, NUM_STANCE_SLOTS do _G[self:GetParent():GetName().."Button"..i].shadow:Show() end end)
	if _G["ElvUI_StanceBar"].backdrop:IsShown() then
		_G["ElvUI_StanceBar"].backdrop:Hide()
		_G["ElvUI_StanceBar"].backdrop:Show()
	else
		_G["ElvUI_StanceBar"].backdrop:Show()
		_G["ElvUI_StanceBar"].backdrop:Hide()
	end

	-- Unitframes (toDo Player ClassBars, Target ComboBar)
	local unitframes = {"Player", "Target", "TargetTarget", "Pet", "PetTarget", "Focus", "FocusTarget"}

	do
		for _, frame in pairs(unitframes) do 
			local self = _G["ElvUF_"..frame]
			local unit = string.lower(frame)
			local health = self.Health
			local power = self.Power
			local castbar = self.Castbar
			local portrait = self.Portrait

			health:CreateShadow()
			EnhancedShadows:RegisterShadow(health.shadow)
			if power then
				power:CreateShadow()
				EnhancedShadows:RegisterShadow(power.shadow)
			end
			if (unit == "player" or unit == "target" or unit == "focus") then
				if castbar then
					castbar:CreateShadow()
					castbar.ButtonIcon.bg:CreateShadow()
					EnhancedShadows:RegisterShadow(castbar.shadow)
					EnhancedShadows:RegisterShadow(castbar.ButtonIcon.bg.shadow)
				end
			end
			if (unit == "player" or unit == "target") then
				if portrait then
					portrait:CreateShadow()
					EnhancedShadows:RegisterShadow(portrait.shadow)
				end
			end
		end
	end

	LeftChatToggleButton:SetFrameStrata('BACKGROUND')
	LeftChatToggleButton:SetFrameLevel(LeftChatDataPanel:GetFrameLevel() - 1)
	RightChatToggleButton:SetFrameStrata('BACKGROUND')
	RightChatToggleButton:SetFrameLevel(RightChatDataPanel:GetFrameLevel() - 1)
end