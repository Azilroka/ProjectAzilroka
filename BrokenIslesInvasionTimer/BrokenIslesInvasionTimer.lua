--SavedVariables Setup
local BrokenIslesInvasionTimer, private = ...
local varinterval = 18.5
local varserver = "   NA   "
local varmessage = " A new Legion Invasion on the Broken Isles is UP! "
local varstartingTimeString = "Apr 13 2017 19:30 -0700 North America"
local varstartingTime = {year=2017, month=4, day=13, hour=19, minute=30,UTC=-7}
local lblLeftTime
local lblNextInvasion
local varLeftTime
local varNextInvasion
local varNextInvasionTS
local orange,yellow = "|cFFFF6906" , "|cffffff00"
local RegionId
local bDayLight = true

local Colors = {
    white    = "|cFFFFFFFF",
    red = "|cFFFF0000",
    darkred = "|cFFF00000",
    green = "|cFF00FF00",
    orange = "|cFFFF7F00",
    yellow = "|cFFFFFF00",
    gold = "|cFFFFD700",
    teal = "|cFF00FF9A",
    cyan = "|cFF1CFAFE",
    lightBlue = "|cFFB0B0FF",
    battleNetBlue = "|cff82c5ff",
    grey = "|cFF909090",

    -- classes
    classMage = "|cFF69CCF0",
    classHunter = "|cFFABD473",

    -- recipes
    recipeGrey = "|cFF808080",
    recipeGreen = "|cFF40C040",
    recipeOrange = "|cFFFF8040",

    -- rarity : http://wow.gamepedia.com/Quality
    common = "|cFFFFFFFF",
    uncommon = "|cFF1EFF00",
    rare = "|cFF0070DD",
    epic = "|cFFA335EE",
    legendary = "|cFFFF8000",
    heirloom = "|cFFE6CC80",
}

local ADDON, namespace = ...
local L = namespace.L

private.defaults = {}

bDayLight = date("*t").isdst


local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject("Broken Isle Invansion Timer", {
    type = "data source",
    icon = "Interface\\Addons\\"..ADDON.."\\icon.tga",
    text = "-",
})


function changeTime()
    if varserver == "   NA   " then
        varstartingTimeString = "Apr 13 2017 19:30 -0700 North America"
        varstartingTime = {year=2017, month=4, day=13, hour=19, minute=30,UTC=-7}
    else
        varstartingTimeString = "Apr 13 2017 18:30 +0000 EU"
        varstartingTime = {year=2017, month=4, day=13, hour=18, minute=30,UTC=0}
    end
    BrokenIslesInvasionTimerDB.startingTimeString = varstartingTimeString
end


local MainFrame = CreateFrame("Frame")
MainFrame:RegisterEvent("ADDON_LOADED")
MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")



function findNAandEU()
    FindNextInvasion()
    sTempNa = FindLeftTime()
end



BrokenIslesInvasionTimer = {};

BrokenIslesInvasionTimerDB = {
    server = varserver,
    startingTimeString = varstartingTimeString,
    startingTime =  varstartingTime,
    message = varmessage,
}


BrokenIslesInvasionTimer.panel = CreateFrame( "Frame", "BrokenIslesInvasionTimerPanel", UIParent );
-- Register in the Interface Addon Options GUI
-- Set the name for the Category for the Options Panel
BrokenIslesInvasionTimer.panel.name = "BrokenIslesInvasionTimer";
-- Add the panel to the Interface Options
InterfaceOptions_AddCategory(BrokenIslesInvasionTimer.panel);

local function CreateInterface()
    local pnlMain=CreateFrame("Frame", "pnlMain", BrokenIslesInvasionTimerPanel)
    pnlMain:SetPoint("TOPLEFT", 5, -5)
    pnlMain:SetScale(2.0)
    pnlMain:SetWidth(150)
    pnlMain:SetHeight(50)
    pnlMain:Show()

    local pnlMainFS = pnlMain:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--    pnlMainFS:SetText('|cff00c0ffTime Popup|r')
    pnlMainFS:SetPoint("TOPLEFT", 0, 0)
    pnlMainFS:SetFont("Fonts\\FRIZQT__.TTF", 10)

    btnReset = CreateFrame("Button", "btnResetButton", BrokenIslesInvasionTimerPanel, "UIPanelButtonTemplate")
    btnReset:ClearAllPoints()
    btnReset:SetPoint("BOTTOMLEFT", 5, 5)
    btnReset:SetScale(1.25)
    btnReset:SetWidth(125)
    btnReset:SetHeight(30)
    _G[btnReset:GetName() .. "Text"]:SetText("Reset to Default")

    btnReset:SetScript("OnClick", function (self, button, down)
        --BrokenIslesInvasionTimerDB = private.defaults;
        ReloadUI();
    end)


    local info = {}
    local cmbServer = CreateFrame("Frame", "cmbServerName", BrokenIslesInvasionTimerPanel, "UIDropDownMenuTemplate")
    cmbServer:SetPoint("TOPLEFT",  10, -75)
    cmbServer:SetScale(1)
    cmbServer.initialize = function()
        wipe(info)
        local names = {"   NA   ", "   EU   "}
        for i, name in next, names do
            info.text = names[i]
            info.value = names[i]
            info.func = function(self)
                cmbServerNameText:SetText(self:GetText())
                varserver = self:GetText()
                BrokenIslesInvasionTimerDB.server = varserver

                changeTime()
                FindNextInvasion()

            end
            UIDropDownMenu_AddButton(info)
        end
    end
    cmbServerNameText:SetText(varserver)

    varLeftTime = {day=0,hour=0, minute=0,second=0}
--
--    local chkDayLight = CreateFrame("CheckButton", "chkDayLightName", BrokenIslesInvasionTimerPanel, "UICheckButtonTemplate")
--    chkDayLight:ClearAllPoints()
--    chkDayLight:SetPoint("TOPLEFT", 220, -75)
--    _G[chkDayLight:GetName() .. "Text"]:SetText("Daylight Saving")
--    chkDayLight:SetChecked(bDayLight)
--    chkDayLight:SetScript("OnClick", function(self, button, down)
--            bDayLight = chkDayLight:GetChecked()
--            --print(bDayLight)
--            BrokenIslesInvasionTimerDB.DayLight = bDayLight
--        end)
--   -- MakeMovable(frame)


    lblNextInvasion = pnlMain:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblNextInvasion:SetFont("Fonts\\FRIZQT__.ttf",8)
    lblNextInvasion:SetPoint("TOPLEFT", 10, -120)
    lblNextInvasion:SetText(orange.."Next Invasion Start: " .. yellow..varNextInvasion .. " UTC+" .. varstartingTime.UTC )



    lblLeftTime = pnlMain:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblLeftTime:SetFont("Fonts\\FRIZQT__.ttf",8)
    lblLeftTime:SetPoint("TOPLEFT", 10, -140)
    temp = varLeftTime.hour .. ' hour(s) ' .. varLeftTime.minute .. ' minute(s) ' .. varLeftTime.second .. ' second(s) '
    lblLeftTime:SetText(orange.."Left Time: " ..yellow.. temp )


    function FindLeftTime()
        temp = date("!*t")
        temp.isdst = bDayLight
        tnow= time(temp) + (varstartingTime.UTC* 3600)
        local leftTime =  varNextInvasionTS - tnow   -- + (varstartingTime.UTC* 3600)  --varNextInvasionTS - tnow - (varstartingTime.UTC* 3600)
        if leftTime == 0 then
            message(varmessage)
        end
        if leftTime < 0 then
            leftTime = 0
            FindNextInvasion()
        end
        if leftTime > 3600 then
            varLeftTime.hour = math.floor(leftTime /3600)
            leftTime = leftTime - (varLeftTime.hour * 3600)
        end
        if leftTime > 60 then
            varLeftTime.minute = math.floor(leftTime /60)
            leftTime = leftTime - (varLeftTime.minute * 60)
        end
        varLeftTime.second = leftTime

        temp = varLeftTime.hour .. ' hour(s) ' .. varLeftTime.minute .. ' minute(s) ' .. varLeftTime.second .. ' second(s) '
        lblLeftTime:SetText(orange.."Left Time: " .. yellow.. temp )
        return temp

    end

    local total = 0

    local function onUpdate(self,elapsed)
        total = total + elapsed
        if total >= 1 then
            FindLeftTime()
            total = 0
                findNAandEU()
                dataobj.text = Colors.yellow ..sTempNa
        end
    end

    local f = CreateFrame("frame")
    f:SetScript("OnUpdate", onUpdate)


    end


 function FindNextInvasion()
    t1= time({
                    day=varstartingTime.day,
                    month=varstartingTime.month,
                    year=varstartingTime.year,
                    hour=varstartingTime.hour,
                    min=varstartingTime.minute,
                    sec=00})

--! Serveeeeeer
--! Serveeeeeer
--! Serveeeeeer
--! Serveeeeeer

    temp = date("!*t")
    temp.isdst = bDayLight

    tnow = time(temp)+ (varstartingTime.UTC * 3600)
    timeinterval = varinterval * 3600
    t2 = timeinterval + t1
    --print(date("%c",tnow  ))
    tcount = 0
    while t2 < tnow do

        tcount = tcount + 1
        t2 = (timeinterval * tcount)+ t1
       -- print(date("%c",t2  ))
    end

    varNextInvasionTS = t2
    varNextInvasion = date("%c",t2  )
    if lblNextInvasion ~= nil then
        lblNextInvasion:SetText(orange.."Next Invasion Start: " .. yellow..varNextInvasion .. " UTC+" .. varstartingTime.UTC )
    end
end

-------------------------------------------------------------------------------------
-- Auto-Loader
-------------------------------------------------------------------------------------
local panelevents = {}


function Bit_SlashCmd(msg)
    local msg = msg:lower()
    local tempvarserver = varserver
        if msg == "na" or msg == "eu"  then

        if (msg == "na") then
            varserver = "   NA   "
        end
        if (msg == "eu") then
            varserver = "   EU   "
        end

        changeTime()
        FindNextInvasion()
        local temp = FindLeftTime()
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00:" .. temp)

        --Return Back
        varserver = tempvarserver
        changeTime()
        FindNextInvasion()
        FindLeftTime()

    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00bit: There is no "..msg.." server" )
    end

end

SLASH_BIT1 = "/bit";
SlashCmdList["BIT"] = Bit_SlashCmd

function BrokenIslesInvasionTimer.SetConfigToDefaults()
    print("Resetting config to defaults")
    --BrokenIslesInvasionTimerDBPC = DefaultConfig
    RELOADUI()
end

function BrokenIslesInvasionTimer.GetConfigValue(key)
    return BrokenIslesInvasionTimerDBPC[key]
end

function BrokenIslesInvasionTimer.PrintPerformanceData()
    UpdateAddOnMemoryUsage()
    local mem = GetAddOnMemoryUsage("BrokenIslesInvasionTimer")
    print("BrokenIslesInvasionTimer is currently using " .. mem .. " kbytes of memory")
    collectgarbage(collect)
    UpdateAddOnMemoryUsage()
    mem = GetAddOnMemoryUsage("BrokenIslesInvasionTimer")
    print("BrokenIslesInvasionTimer is currently using " .. mem .. " kbytes of memory after garbage collection")
end



function panelevents:ACTIVE_TALENT_GROUP_CHANGED(self)
    --print("Panel:Talent Group Changed")
    --ApplyPanelSettings()
    --OnRefresh(BrokenIslesInvasionTimer.panel)
end

function panelevents:PLAYER_ENTERING_WORLD()
    --print("Panel:Player Entering World")
    -- Tihs may happen every time a loading screen is shown


    --ApplyPanelSettings()
    --ApplyAutomationSettings()
end

function panelevents:PLAYER_REGEN_ENABLED()

end

function panelevents:PLAYER_REGEN_DISABLED()

end

function panelevents:PLAYER_LOGIN()
    -- This happens only once a session

    -- Setup the interface panels
    --varinterval = BrokenIslesInvasionTimerDB.interval
    RegionId = GetCurrentRegion()
    varserver = BrokenIslesInvasionTimerDB.server
    varmessage = BrokenIslesInvasionTimerDB.message
    changeTime()
    FindNextInvasion()
    CreateInterface()


end

function panelevents:ADDON_LIST_UPDATE()

end

BrokenIslesInvasionTimer.panel:SetScript("OnEvent", function(self, event, ...) panelevents[event](self, ...) end)
for eventname in pairs(panelevents) do BrokenIslesInvasionTimer.panel:RegisterEvent(eventname) end
