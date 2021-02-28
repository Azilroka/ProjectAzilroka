local PA = _G.ProjectAzilroka
local BLDB = PA:NewModule('BLDB', 'AceEvent-3.0')
PA.BLDB, _G.BLDB = BLDB, BLDB

local _G = _G
local pairs = pairs
local tinsert = tinsert
local tremove = tremove

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local UIParent = UIParent

BLDB.Title = PA.ACL['|cFF16C3F2Broker|r|cFFFFFFFFLDB|r']
BLDB.Description = PA.ACL['Provides a Custom DataBroker Bar']
BLDB.Authors = 'Azilroka'
BLDB.isEnabled = false

function BLDB:TextUpdate(_, Name, _, Data)
	BLDB.PluginObjects[Name]:SetText(Data)
end

function BLDB:ValueUpdate(_, Name, _, Data, Object)
	BLDB.PluginObjects[Name]:SetFormattedText('%s %s', Data, Object.suffix)
end

function BLDB:AnimateSlide(frame, x, y, duration)
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

function BLDB:AnimSlideIn(frame)
	frame.anim.out1:Stop()
	frame:Show()
	frame.anim:Play()
end

function BLDB:AnimSlideOut(frame)
	frame.anim:Finish()
	frame.anim:Stop()
	frame.anim.out1:Play()
end

function BLDB:SlideOut()
	for _, Slides in pairs(BLDB.Whitelist) do
		BLDB:AnimSlideIn(Slides)
	end
	BLDB:AnimSlideIn(BLDB.Frame)
	BLDB.Frame.Arrow:SetRotation(1.57)
	BLDB.Slide = 'Out'
end

function BLDB:SlideIn()
	for _, Slides in pairs(BLDB.Buttons) do
		Slides:Hide()
	end
	BLDB.Frame.Arrow:SetRotation(-1.57)
	BLDB.Slide = 'In'
end

function BLDB:Update()
	for Name, Object in PA.LDB:DataObjectIterator() do
		BLDB:New(nil, Name, Object)
	end

	for Key, Slide in pairs(BLDB.Buttons) do
		Slide.Text:SetFont(PA.LSM:Fetch('font', BLDB.db['Font']), BLDB.db['FontSize'], BLDB.db['FontFlag'])
		if BLDB.db['ShowIcon'] and BLDB.db['ShowText'] then
			if BLDB.db['PanelWidth'] == 0 then BLDB.db['PanelWidth'] = 140 end
			Slide:SetSize(BLDB.db['PanelWidth'] + BLDB.db['PanelHeight'], BLDB.db['PanelHeight'])
			Slide.Icon:Show()
			Slide.Icon:SetPoint('RIGHT', Slide, 'RIGHT', -2, 0)
			Slide.Icon:Size(BLDB.db['PanelHeight'] - 4)
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', -(BLDB.db['PanelHeight'] / 2), 0)
		elseif BLDB.db['ShowIcon'] then
			BLDB.db['PanelWidth'] = 0
			Slide:SetSize(BLDB.db['PanelHeight'], BLDB.db['PanelHeight'])
			Slide.Icon:Show()
			Slide.Icon:Size(BLDB.db['PanelHeight'])
			Slide.Icon:SetPoint('RIGHT', Slide, 'RIGHT', 0, 0)
			Slide.Text:Hide()
		elseif BLDB.db['ShowText'] then
			if BLDB.db['PanelWidth'] == 0 then BLDB.db['PanelWidth'] = 140 end
			Slide:SetSize(BLDB.db['PanelWidth'], BLDB.db['PanelHeight'])
			Slide.Icon:Hide()
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', 0, 0)
		end
		if Slide.anim then
			local x = BLDB.db["PanelWidth"] + BLDB.db["PanelHeight"]
			Slide.anim.in1:SetOffset(-x, 0)
			Slide.anim.in2:SetOffset(x, 0)
			Slide.anim.out2:SetOffset(-x, 0)
		end
		for _, Blacklisted in pairs(BLDB.Blacklist) do
			if Slide:GetName() == Blacklisted then tremove(BLDB.Whitelist, Key) Slide.Enabled = false return end
		end
	end

	local yOffSet = 0
	for _, Slide in pairs(BLDB.Whitelist) do
		Slide:SetPoint('TOPLEFT', BLDB.Frame, 'TOPRIGHT', 1, yOffSet)
		yOffSet = yOffSet - BLDB.db['PanelHeight'] - 1
	end

	BLDB.Frame:Height((BLDB.db['PanelHeight'] * #BLDB.Whitelist) + (#BLDB.Whitelist - 1))
	if (#BLDB.Buttons == 0 or #BLDB.Whitelist == 0) then
		BLDB.Frame:Hide()
	end

	if not BLDB.db['MouseOver'] then
		_G.UIFrameFadeIn(BLDB.Frame, 0.2, BLDB.Frame:GetAlpha(), 1)
	else
		_G.UIFrameFadeOut(BLDB.Frame, 0.2, BLDB.Frame:GetAlpha(), 0)
	end
end

function BLDB:AddBlacklistFrame(frame)
	frame.Enabled = false
	local index
	for i, v in pairs(BLDB.Whitelist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(BLDB.Whitelist, index)
	tinsert(BLDB.Blacklist, frame:GetName())
	BLDB:SlideIn()
	BLDB:Update()
end

function BLDB:RemoveBlacklistFrame(frame)
	frame.Enabled = true
	local index
	for i, v in pairs(BLDB.Blacklist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(BLDB.Blacklist, index)
	tinsert(BLDB.Whitelist, frame)
	BLDB:SlideIn()
	BLDB:Update()
end

function BLDB:New(_, Name, Object)
	if _G['BLDB_'..Name] then return end
	for _, v in pairs(BLDB.Ignore) do
		if Name == v then return end
	end

	local Frame = CreateFrame('Frame', 'BLDB_'..Name, BLDB.Frame)
	Frame:Hide()
	Frame.pluginName = Name
	Frame.pluginObject = Object

	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetFrameLevel(3)
	PA:SetTemplate(Frame, 'Transparent')
	BLDB:AnimateSlide(Frame, -150, 0, 1)
	Frame:SetHeight(BLDB.db['PanelHeight'])
	Frame:SetWidth(BLDB.db['PanelWidth'])
	Frame.Enabled = true
	tinsert(BLDB.Buttons, Frame)
	tinsert(BLDB.Whitelist, Frame)

	Frame.Text = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Text:SetFont(PA.LSM:Fetch('font', BLDB.db['Font']), BLDB.db['FontSize'], BLDB.db['FontFlag'])
	Frame.Text:SetPoint('CENTER', Frame)

	Frame.Icon = Frame.IconBackdrop:CreateTexture(nil, 'ARTWORK')
	Frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	PA:CreateBackdrop(Frame.Icon)

	BLDB.PluginObjects[Name] = Frame.Text

	BLDB:TextUpdate(nil, Name, nil, Object.text or Object.label or Name)
	PA.LDB.RegisterCallback(BLDB, 'LibDataBroker_AttributeChanged_'..Name..'_text', 'TextUpdate')
	if Object.suffix then
		BLDB:ValueUpdate(nil, Name, nil, Object.value or Name, Object)
		PA.LDB.RegisterCallback(BLDB, 'LibDataBroker_AttributeChanged_'..Name..'_value', 'ValueUpdate')
	end

	Frame:SetScript('OnEnter', function(s)
		if s.anim:IsPlaying() then return end
		if s.pluginObject.OnTooltipShow then
			GameTooltip:SetOwner(s, 'ANCHOR_RIGHT' , 2, -(BLDB.db['PanelHeight']))
			PA:SetTemplate(GameTooltip, 'Transparent')
			GameTooltip:ClearLines()
			s.pluginObject.OnTooltipShow(GameTooltip, s)
			GameTooltip:Show()
		elseif s.pluginObject.OnEnter then
			PA:SetTemplate(GameTooltip, 'Transparent')
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
	tinsert(BLDB.EasyMenu, { text = 'Show '..Name, checked = function() return Frame.Enabled end, func = function() if Frame.Enabled then BLDB:AddBlacklistFrame(Frame) else BLDB:RemoveBlacklistFrame(Frame) end BLDB:Update() end } )

	if Object.OnCreate then Object.OnCreate(Object, Frame) end
end

function BLDB:GetOptions()
	local BrokerLDB = PA.ACH:Group(BLDB.Title, BLDB.Description, nil, nil, function(info) return BLDB.db[info[#info]] end)
	PA.Options.args.BrokerLDB = BrokerLDB

	BrokerLDB.args.Description = PA.ACH:Description(BLDB.Description, 0)
	BrokerLDB.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) BLDB.db[info[#info]] = value if not BLDB.isEnabled then BLDB:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	BrokerLDB.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2, nil, nil, function(info, value) BLDB.db[info[#info]] = value BLDB:Update() end)
	BrokerLDB.args.General.inline = true

	BrokerLDB.args.General.args.ShowIcon = PA.ACH:Toggle(PA.ACL['Show Icon'], nil, 1)
	BrokerLDB.args.General.args.MouseOver = PA.ACH:Toggle(PA.ACL['MouseOver'], nil, 2)
	BrokerLDB.args.General.args.ShowText = PA.ACH:Toggle(PA.ACL['Show Text'], nil, 3)
	BrokerLDB.args.General.args.PanelHeight = PA.ACH:Range(PA.ACL['Panel Height'], nil, 4, { min = 20, max = 40, step = 1 })
	BrokerLDB.args.General.args.PanelWidth = PA.ACH:Range(PA.ACL['Panel Width'], nil, 5, { min = 0, softMin = 140, max = 280, step = 1 })

	BrokerLDB.args.General.args.FontSettings = PA.ACH:Group(PA.ACL['Font Settings'], nil, -1)
	BrokerLDB.args.General.args.FontSettings.inline = true
	BrokerLDB.args.General.args.FontSettings.args.Font = PA.ACH:SharedMediaFont(PA.ACL['Font'], nil, 1)
	BrokerLDB.args.General.args.FontSettings.args.FontSize = PA.ACH:Range(PA.ACL['Font Size'], nil, 2, { min = 6, max = 22, step = 1 })
	BrokerLDB.args.General.args.FontSettings.args.FontFlag = PA.ACH:FontFlags(PA.ACL['Font Outline'], nil, 3)

	BrokerLDB.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	BrokerLDB.args.Authors = PA.ACH:Description(BLDB.Authors, -1, 'large')
end

function BLDB:BuildProfile()
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

function BLDB:UpdateSettings()
	BLDB.db = PA.db.BrokerLDB
end

function BLDB:Initialize()
	BLDB:UpdateSettings()

	if BLDB.db.Enable ~= true then
		return
	end

	BLDB.isEnabled = true

	BLDB.DropDown = CreateFrame('Frame', 'BLDBDropDown', UIParent, 'UIDropDownMenuTemplate')
	BLDB.Slide = 'In'
	BLDB.EasyMenu = {}

	BLDB.Buttons = {}
	BLDB.PluginObjects = {}

	BLDB.Ignore = { 'Cork' }

	BLDB.Whitelist = {}
	BLDB.Blacklist = {}

	PA.LDB.RegisterCallback(BLDB, 'LibDataBroker_DataObjectCreated', 'New')

	local Frame = CreateFrame('Button', nil, UIParent)
	Frame.Arrow = Frame:CreateTexture(nil, 'OVERLAY')
	Frame.Arrow:SetTexture([[Interface\AddOns\ProjectAzilroka\Media\Textures\Arrow]])
	Frame.Arrow:SetSize(12, 12)
	Frame.Arrow:SetPoint('CENTER', Frame, 0, 0)
	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetWidth(15)
	Frame:SetPoint('LEFT', UIParent, 'LEFT', 1, 0)
	Frame:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
	PA:SetTemplate(Frame, 'Transparent')
	BLDB:AnimateSlide(Frame, -150, 0, 1)

	Frame:SetScript('OnEnter', function(s) _G.UIFrameFadeIn(s, 0.2, s:GetAlpha(), 1) end)
	Frame:SetScript('OnLeave', function(s)
		if BLDB.Slide == 'In' and BLDB.db['MouseOver'] then
			_G.UIFrameFadeOut(s, 0.2, s:GetAlpha(), 0)
		end
	end)

	Frame:SetScript('OnClick', function(s, btn)
		if s.anim:IsPlaying() then return end
		if btn == 'LeftButton' then
			if BLDB.Slide == 'In' then
				BLDB:SlideOut()
			else
				BLDB:SlideIn()
			end
		else
			_G.EasyMenu(BLDB.EasyMenu, BLDB.DropDown, 'cursor', 0, 0, 'MENU', 2)
		end
	end)

	BLDB.Frame = Frame

	BLDB:Update()
	BLDB:SlideIn()
end
