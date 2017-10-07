local addon, st = ...
local stAM = st[1] --for local usage

--loaded in stAddonManager.lua (stAM:Initialize)
stAM.defaultConfig = {
	['numAddonsShown'] = 15,
	['frameWidth'] = 225,
	['usePixelFont'] = false
}

function stAM.UpdateFontType()
	if stAM_Config['usePixelFont'] == nil then return end --Failsafe: Don't run if config isn't loaded yet
	st.font = (stAM_Config['usePixelFont'] and st.pixelfont) or st.normalfont

	for _,fs in pairs(st.FontStringTable) do
		fs:SetFont(unpack(st.font))
	end
end

function stAM.UpdateWindowWidth()
	if stAM_Config['frameWidth'] == nil then return end --Failsafe: Don't run if config isn't loaded yet

	stAM:SetWidth(stAM_Config['frameWidth'])
end

function stAM.UpdateConfig(self)
	self:UpdateFontType()
	self:UpdateWindowWidth()
	self:UpdateAddonList()
end

function stAM.InitConfig(self)
	local options = {
		[1] = {
			type = 'editbox',
			label = 'Number of Addons Shown',
			default = stAM_Config['numAddonsShown'],
			scripts = {
				['OnEnterPressed'] = function(self)
					local numAddons = tonumber(self:GetText():gsub('%D',''), 10) --remove anything that isn't a number
					if numAddons < 3 then numAddons = 3 end
					if numAddons > 30 then numAddons = 30 end
					stAM_Config['numAddonsShown'] = numAddons
					stAM:UpdateAddonList()
				end,
				['OnEscapePressed'] = function(self)
					self:SetText(stAM_Config['numAddonsShown'])
				end,
			}
		},
		[2] = {
			type = 'editbox',
			label = 'Main Window Width',
			default = stAM_Config['frameWidth'],
			scripts = {
				['OnEnterPressed'] = function(self)
					local frameWidth = tonumber(self:GetText():gsub('%D',''), 10) --remove anything that isn't a number
					if frameWidth < 200 then frameWidth = 200 end
					if frameWidth > 500 then frameWidth = 500 end
					stAM_Config['frameWidth'] = frameWidth
					stAM:UpdateWindowWidth()

				end,
				['OnEscapePressed'] = function(self)
					self:SetText(stAM_Config['frameWidth'])
				end,
			}
		},
		[3] = {
			type = 'checkbox',
			label = 'Use Pixel Font',
			default = stAM_Config['usePixelFont'],
			scripts = {
				['OnClick'] = function(self, btn)
					stAM_Config['usePixelFont'] = self:GetChecked() or false
					stAM:UpdateFontType()
				end,
			},
		}
	}


	local config = CreateFrame('Frame', self:GetName()..'_ConfigWindow', self)
	config:SetTemplate()
	config:SetFrameLevel(self.addons.buttons[1]:GetFrameLevel()+1)
	config:SetAllPoints(self.addons)
	config.title = st.CreateFontString(config, nil, 'OVERLAY', 'Config', {'TOPLEFT', config}, 'CENTER', st.FontStringTable)
	config.title:SetPoint('TOPRIGHT', config)
	config.title:SetHeight(25)


	config.options = {}
	local sectionHeight = 20
	for i, option in pairs(options) do		
		local frame = CreateFrame('Frame', config:GetName()..'_Option'..i, config)
		frame:SetHeight(sectionHeight)

		if i == 1 then
			frame:SetPoint('TOPRIGHT', config.title, 'BOTTOMRIGHT', -10, -2)
			frame:SetPoint('TOPLEFT', config.title, 'BOTTOMLEFT', 10, -2)
		else
			frame:SetPoint('TOPRIGHT', config.options[i-1], 'BOTTOMRIGHT', 0, -2)
			frame:SetPoint('TOPLEFT',  config.options[i-1], 'BOTTOMLEFT', 0, -2)
		end

		if option.label then
			frame.label = st.CreateFontString(frame, frame:GetName()..'_Label', 'OVERLAY', option.label or '', {'LEFT', 5}, 'LEFT', st.FontStringTable)
		end

		if option.type then
			if option.type == 'checkbox' then
				local checkbox = st.CreateCheckBox(frame:GetName()..'_CheckBox', frame, 10, 10, {'RIGHT', -20})
				for script, func in pairs(option.scripts) do
					checkbox:HookScript(script, func)
				end
				checkbox:SetChecked(option.default)
				frame.checkbox = checkbox
			elseif option.type == 'editbox' then
				local editbox = st.CreateEditBox(frame:GetName()..'_EditBox', frame, 40, 20, {'RIGHT', -5})
				for script, func in pairs(option.scripts) do
					editbox:HookScript(script, func)
				end
				editbox:SetText(option.default or '')
				editbox:SetJustifyH('RIGHT')
				frame.editbox = editbox
			end
		end

		config.options[i] = frame
	end

	config.options = options

	self.configMenu = config
	self:UpdateConfig()
end

function stAM.ToggleConfig(self)
	if not self.configMenu then
		self:InitConfig()
	else
		ToggleFrame(self.configMenu)
	end
	if self.configMenu:IsShown() then
		if self.profileMenu and self.profileMenu:IsShown() then stAM:ToggleProfiles() end
		self:UpdateConfig()
	else
		self:UpdateAddonList()
	end
end