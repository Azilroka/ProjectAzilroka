local PA = _G.ProjectAzilroka
local BrokerLDB = PA:NewModule('BrokerLDB', 'AceEvent-3.0')
PA.BrokerLDB, _G.BrokerLDB = BrokerLDB, BrokerLDB

local _G = _G
local pairs = pairs
local tinsert = tinsert
local tremove = tremove

BrokerLDB.Title = 'BrokerLDB'
BrokerLDB.Header = PA.ACL['|cFF16C3F2Broker|r|cFFFFFFFFLDB|r']
BrokerLDB.Description = PA.ACL['Provides a Custom DataBroker Bar']
BrokerLDB.Authors = 'Azilroka'
BrokerLDB.isEnabled = false

function BrokerLDB:TextUpdate(_, Name, _, Data)
	BrokerLDB.PluginObjects[Name]:SetText(Data)
end

function BrokerLDB:ValueUpdate(_, Name, _, Data, Object)
	BrokerLDB.PluginObjects[Name]:SetFormattedText('%s %s', Data, Object.suffix)
end

function BrokerLDB:AnimateSlide(frame, x, y, duration)
	frame.anim = frame:CreateAnimationGroup('Move_In')
	frame.anim.in1 = frame.anim:CreateAnimation('Translation')
	frame.anim.in1:SetDuration(0)
	frame.anim.in1:SetOrder(1)
	frame.anim.in2 = frame.anim:CreateAnimation('Translation')
	frame.anim.in2:SetDuration(duration)
	frame.anim.in2:SetOrder(2)
	frame.anim.in2:SetSmoothing('OUT')
	frame.anim.out1 = frame:CreateAnimationGroup('Move_Out')
	frame.anim.out2 = frame.anim.out1:CreateAnimation('Translation')
	frame.anim.out2:SetDuration(duration)
	frame.anim.out2:SetOrder(1)
	frame.anim.out2:SetSmoothing('IN')
	frame.anim.in1:SetOffset(x, y)
	frame.anim.in2:SetOffset(-x, -y)
	frame.anim.out2:SetOffset(x, y)
	frame.anim.out1:SetScript('OnFinished', function() frame:Hide() end)
end

function BrokerLDB:AnimSlideIn(frame)
	frame.anim.out1:Stop()
	frame:Show()
	frame.anim:Play()
end

function BrokerLDB:AnimSlideOut(frame)
	frame.anim:Finish()
	frame.anim:Stop()
	frame.anim.out1:Play()
end

function BrokerLDB:SlideOut()
	for _, Slides in pairs(BrokerLDB.Whitelist) do
		BrokerLDB:AnimSlideIn(Slides)
	end
	BrokerLDB:AnimSlideIn(BrokerLDB.Frame)
	BrokerLDB.Frame.Arrow:SetRotation(1.57)
	BrokerLDB.Slide = 'Out'
end

function BrokerLDB:SlideIn()
	for _, Slides in pairs(BrokerLDB.Buttons) do
		Slides:Hide()
	end
	BrokerLDB.Frame.Arrow:SetRotation(-1.57)
	BrokerLDB.Slide = 'In'
end

function BrokerLDB:Update()
	for Name, Object in PA.LDB:DataObjectIterator() do
		BrokerLDB:New(nil, Name, Object)
	end

	for Key, Slide in pairs(BrokerLDB.Buttons) do
		Slide.Text:SetFont(PA.LSM:Fetch('font', BrokerLDB.db['Font']), BrokerLDB.db['FontSize'], BrokerLDB.db['FontFlag'])
		if BrokerLDB.db['ShowIcon'] and BrokerLDB.db['ShowText'] then
			if BrokerLDB.db['PanelWidth'] == 0 then BrokerLDB.db['PanelWidth'] = 140 end
			Slide:SetSize(BrokerLDB.db['PanelWidth'] + BrokerLDB.db['PanelHeight'], BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:Show()
			Slide.IconBackdrop:SetPoint('RIGHT', Slide, 'RIGHT', -2, 0)
			Slide.IconBackdrop:Size(BrokerLDB.db['PanelHeight'] - 4)
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', -(BrokerLDB.db['PanelHeight'] / 2), 0)
		elseif BrokerLDB.db['ShowIcon'] then
			BrokerLDB.db['PanelWidth'] = 0
			Slide:SetSize(BrokerLDB.db['PanelHeight'], BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:Show()
			Slide.IconBackdrop:Size(BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:SetPoint('RIGHT', Slide, 'RIGHT', 0, 0)
			Slide.Text:Hide()
		elseif BrokerLDB.db['ShowText'] then
			if BrokerLDB.db['PanelWidth'] == 0 then BrokerLDB.db['PanelWidth'] = 140 end
			Slide:SetSize(BrokerLDB.db['PanelWidth'], BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:Hide()
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', 0, 0)
		end
		if Slide.anim then
			local x = BrokerLDB.db["PanelWidth"] + BrokerLDB.db["PanelHeight"]
			Slide.anim.in1:SetOffset(-x, 0)
			Slide.anim.in2:SetOffset(x, 0)
			Slide.anim.out2:SetOffset(-x, 0)
		end
		for _, Blacklisted in pairs(BrokerLDB.Blacklist) do
			if Slide:GetName() == Blacklisted then tremove(BrokerLDB.Whitelist, Key) Slide.Enabled = false return end
		end
	end

	local yOffSet = 0
	for _, Slide in pairs(BrokerLDB.Whitelist) do
		Slide:SetPoint('TOPLEFT', BrokerLDB.Frame, 'TOPRIGHT', 1, yOffSet)
		yOffSet = yOffSet - BrokerLDB.db['PanelHeight'] - 1
	end

	BrokerLDB.Frame:Height((BrokerLDB.db['PanelHeight'] * #BrokerLDB.Whitelist) + (#BrokerLDB.Whitelist - 1))
	if (#BrokerLDB.Buttons == 0 or #BrokerLDB.Whitelist == 0) then
		BrokerLDB.Frame:Hide()
	end

	if not BrokerLDB.db['MouseOver'] then
		UIFrameFadeIn(BrokerLDB.Frame, 0.2, BrokerLDB.Frame:GetAlpha(), 1)
	else
		UIFrameFadeOut(BrokerLDB.Frame, 0.2, BrokerLDB.Frame:GetAlpha(), 0)
	end
end

function BrokerLDB:AddBlacklistFrame(frame)
	frame.Enabled = false
	local index
	for i, v in pairs(BrokerLDB.Whitelist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(BrokerLDB.Whitelist, index)
	tinsert(BrokerLDB.Blacklist, frame:GetName())
	BrokerLDB:SlideIn()
	BrokerLDB:Update()
end

function BrokerLDB:RemoveBlacklistFrame(frame)
	frame.Enabled = true
	local index
	for i, v in pairs(BrokerLDB.Blacklist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(BrokerLDB.Blacklist, index)
	tinsert(BrokerLDB.Whitelist, frame)
	BrokerLDB:SlideIn()
	BrokerLDB:Update()
end

function BrokerLDB:New(_, Name, Object)
	if _G['BrokerLDB_'..Name] then return end
	for _, v in pairs(BrokerLDB.Ignore) do
		if Name == v then return end
	end

	local Frame = CreateFrame('Frame', 'BrokerLDB_'..Name, BrokerLDB.Frame)
	Frame:Hide()
	Frame.pluginName = Name
	Frame.pluginObject = Object

	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetFrameLevel(3)
	Frame:SetTemplate('Transparent')
	BrokerLDB:AnimateSlide(Frame, -150, 0, 1)
	Frame:SetHeight(BrokerLDB.db['PanelHeight'])
	Frame:SetWidth(BrokerLDB.db['PanelWidth'])
	Frame.Enabled = true
	tinsert(BrokerLDB.Buttons, Frame)
	tinsert(BrokerLDB.Whitelist, Frame)

	Frame.Text = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Text:SetFont(PA.LSM:Fetch('font', BrokerLDB.db['Font']), BrokerLDB.db['FontSize'], BrokerLDB.db['FontFlag'])
	Frame.Text:SetPoint('CENTER', Frame)

	Frame.IconBackdrop = CreateFrame('Frame', nil, Frame)
	Frame.IconBackdrop:SetTemplate()

	Frame.Icon = Frame.IconBackdrop:CreateTexture(nil, 'ARTWORK')
	Frame.Icon:SetInside()
	Frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	BrokerLDB.PluginObjects[Name] = Frame.Text

	BrokerLDB:TextUpdate(nil, Name, nil, Object.text or Object.label or Name)
	PA.LDB.RegisterCallback(BrokerLDB, 'LibDataBroker_AttributeChanged_'..Name..'_text', 'TextUpdate')
	if Object.suffix then
		BrokerLDB:ValueUpdate(nil, Name, nil, Object.value or Name, Object)
		PA.LDB.RegisterCallback(BrokerLDB, 'LibDataBroker_AttributeChanged_'..Name..'_value', 'ValueUpdate')
	end

	Frame:SetScript('OnEnter', function(s)
		if s.anim:IsPlaying() then return end
		if s.pluginObject.OnTooltipShow then
			GameTooltip:SetOwner(s, 'ANCHOR_RIGHT' , 2, -(BrokerLDB.db['PanelHeight']))
			GameTooltip:SetTemplate('Transparent')
			GameTooltip:ClearLines()
			s.pluginObject.OnTooltipShow(GameTooltip, s)
			GameTooltip:Show()
		elseif s.pluginObject.OnEnter then
			GameTooltip:SetTemplate('Transparent')
			s.pluginObject.OnEnter(s)
		end
	end)
	Frame:SetScript('OnLeave', function(s)
		GameTooltip:Hide()
		if s.pluginObject.OnLeave then
			s.pluginObject.OnLeave(s)
		end
	end)
	Frame:SetScript('OnMouseUp', function(s, btn)
		if s.anim:IsPlaying() then return end
		if s.pluginObject.OnClick then
			s.pluginObject.OnClick(s, btn)
		end
	end)
	Frame:SetScript('OnUpdate', function(s) s.Icon:SetTexture(Object.icon) end)
	tinsert(BrokerLDB.EasyMenu, { text = 'Show '..Name, checked = function() return Frame.Enabled end, func = function() if Frame.Enabled then BrokerLDB:AddBlacklistFrame(Frame) else BrokerLDB:RemoveBlacklistFrame(Frame) end BrokerLDB:Update() end } )

	if Object.OnCreate then Object.OnCreate(Object, Frame) end
end

function BrokerLDB:GetOptions()
	PA.Options.args.BrokerLDB = PA.ACH:Group(BrokerLDB.Title, BrokerLDB.Description, nil, nil, function(info) return BrokerLDB.db[info[#info]] end)
	PA.Options.args.BrokerLDB.args.Header = PA.ACH:Header(BrokerLDB.Header, 0)
	PA.Options.args.BrokerLDB.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) BrokerLDB.db[info[#info]] = value if not BrokerLDB.isEnabled then BrokerLDB:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	PA.Options.args.BrokerLDB.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, nil, function(info, value) BrokerLDB.db[info[#info]] = value BrokerLDB:Update() end)
	PA.Options.args.BrokerLDB.args.General.guiInline = true

	PA.Options.args.BrokerLDB.args.General.args.ShowIcon = PA.ACH:Toggle(PA.ACL['Show Icon'], nil, 1)
	PA.Options.args.BrokerLDB.args.General.args.MouseOver = PA.ACH:Toggle(PA.ACL['MouseOver'], nil, 2)
	PA.Options.args.BrokerLDB.args.General.args.ShowText = PA.ACH:Toggle(PA.ACL['Show Text'], nil, 3)
	PA.Options.args.BrokerLDB.args.General.args.PanelHeight = PA.ACH:Range(PA.ACL['Panel Height'], nil, 4, { min = 20, max = 40, step = 1 })
	PA.Options.args.BrokerLDB.args.General.args.PanelWidth = PA.ACH:Range(PA.ACL['Panel Width'], nil, 5, { min = 0, softMin = 140, max = 280, step = 1 })

	PA.Options.args.BrokerLDB.args.General.args.FontSettings = PA.ACH:Group(PA.ACL['Font Settings'], nil, -1)
	PA.Options.args.BrokerLDB.args.General.args.FontSettings.guiInline = true
	PA.Options.args.BrokerLDB.args.General.args.FontSettings.args.Font = PA.ACH:SharedMediaFont(PA.ACL['Font'], nil, 1)
	PA.Options.args.BrokerLDB.args.General.args.FontSettings.args.FontSize = PA.ACH:Range(FONT_SIZE, nil, 2, { min = 6, max = 22, step = 1 })
	PA.Options.args.BrokerLDB.args.General.args.FontSettings.args.FontFlag = PA.ACH:Select(PA.ACL['Font Outline'], nil, 3, PA.FontFlags)

	PA.Options.args.BrokerLDB.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	PA.Options.args.BrokerLDB.args.Authors = PA.ACH:Description(BrokerLDB.Authors, -1, 'large')
end

function BrokerLDB:BuildProfile()
	PA.Defaults.profile.BrokerLDB = {
		Enable = false,
		PanelHeight = 20,
		PanelWidth = 140,
		MouseOver = false,
		ShowIcon = false,
		ShowText = true,
		Font = 'Tukui Pixel',
		FontSize = 12,
		FontFlag = 'MONOCHROMEOUTLINE',
	}
end

function BrokerLDB:Initialize()
	BrokerLDB.db = PA.db.BrokerLDB

	if BrokerLDB.db.Enable ~= true then
		return
	end

	BrokerLDB.isEnabled = true

	BrokerLDB.DropDown = CreateFrame('Frame', 'BrokerLDBDropDown', UIParent, 'UIDropDownMenuTemplate')
	BrokerLDB.Slide = 'In'
	BrokerLDB.EasyMenu = {}

	BrokerLDB.Buttons = {}
	BrokerLDB.PluginObjects = {}

	BrokerLDB.Ignore = { 'Cork' }

	BrokerLDB.Whitelist = {}
	BrokerLDB.Blacklist = {}

	PA.LDB.RegisterCallback(BrokerLDB, 'LibDataBroker_DataObjectCreated', 'New')

	local Frame = CreateFrame('Button', nil, UIParent)
	Frame.Arrow = Frame:CreateTexture(nil, 'OVERLAY')
	Frame.Arrow:SetTexture([[Interface\AddOns\ProjectAzilroka\Media\Textures\Arrow]])
	Frame.Arrow:SetSize(12, 12)
	Frame.Arrow:SetPoint('CENTER', Frame, 0, 0)
	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetWidth(15)
	Frame:SetPoint('LEFT', UIParent, 'LEFT', 1, 0)
	Frame:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
	Frame:SetTemplate('Transparent')
	BrokerLDB:AnimateSlide(Frame, -150, 0, 1)

	Frame:SetScript('OnEnter', function(s) UIFrameFadeIn(s, 0.2, s:GetAlpha(), 1) end)
	Frame:SetScript('OnLeave', function(s)
		if BrokerLDB.Slide == 'In' and BrokerLDB.db['MouseOver'] then
			UIFrameFadeOut(s, 0.2, s:GetAlpha(), 0)
		end
	end)

	Frame:SetScript('OnClick', function(s, btn)
		if s.anim:IsPlaying() then return end
		if btn == 'LeftButton' then
			if BrokerLDB.Slide == 'In' then
				BrokerLDB:SlideOut()
			else
				BrokerLDB:SlideIn()
			end
		else
			EasyMenu(BrokerLDB.EasyMenu, BrokerLDB.DropDown, 'cursor', 0, 0, 'MENU', 2)
		end
	end)

	BrokerLDB.Frame = Frame

	BrokerLDB:Update()
	BrokerLDB:SlideIn()
end
