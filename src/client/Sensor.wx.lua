-----------------------------------------------------------------------------
-- Name:        Sensor.wx.lua
-- Purpose:     Graphical Interface for use the Sensor in IoT tests
-- Author:      João Victor Oliveira Couto
-- Created:     April 2018
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require "wx"

local sensorSocket = (require "client.Sensor"):new()

local frame = nil
local currentCost = 100
local staticText = nil
local timer = nil
local checkListBox = nil
local radioBox = nil
local timerParams = {seconds = 1, updated = false}

local TEXTENTRY_ID = 1001
local UPBUTTON_ID = 1002
local DOWNBUTTON_ID = 1003
local RADIOBOX_ID = 1004
local CHECKLISTBOX_ID = 1005
local SENDBUTTON_ID = 1006

function timerSeconds(event)
    local timeString = event:GetString()
    timerParams.seconds = tonumber(timeString:sub(1, #timeString - 1))
    timerParams.updated = true
end

function automaticSend(event)
    if(checkListBox:IsChecked(0)) then
        local timeString = radioBox:GetStringSelection()
        timer:Start(1000 * tonumber(timeString:sub(1, #timeString - 1)))
    else
        timer:Stop()
    end
end

function updateStaticText()
    staticText:SetLabel("Current Flow: " .. currentCost .. "m³/s")
end

function firstPanel(panel, sizer, notebook)
    local panel, sizer = panel or wx.wxPanel(notebook, wx.wxID_ANY), sizer or wx.wxBoxSizer(wx.wxVERTICAL)
    
    local textEntry = wx.wxStaticText(panel, TEXTENTRY_ID, "Current Flow: " .. currentCost .. "m³/s"); 
    staticText = textEntry
    local upButton = wx.wxButton(panel, UPBUTTON_ID, "Up")
    local downButton = wx.wxButton(panel, DOWNBUTTON_ID, "Down")

    local buttonSizer = wx.wxFlexGridSizer(1, 0, 5, 5)
    buttonSizer:AddGrowableCol(2)
    buttonSizer:Add(upButton, 0, 0)
    buttonSizer:Add(downButton, 0, 0)

    -- Put them in a vertical sizer, with ratio 3 units for the text entry, 5 for button
    -- and padding of 6 pixels.
    sizer:Add(textEntry, 0, wx.wxALL + wx.wxGROW, 6)
    --sizer:Add(buttonSizer, 0, wx.wxALL + wx.wxGROW, 6)
    sizer:Add(buttonSizer, 0, wx.wxEXPAND, 0)

    radioBox = wx.wxRadioBox(panel, RADIOBOX_ID, "Syncronization Frequency", wx.wxDefaultPosition, 
    wx.wxDefaultSize, {"1s", "5s", "10s", "30s"}, 1, wx.wxRA_SPECIFY_ROWS)

    checkListBox = wx.wxCheckListBox(panel, CHECKLISTBOX_ID, wx.wxDefaultPosition, wx.wxSize(200, 30), 
    {"Send Automatic Data"}, wx.wxLB_MULTIPLE)

    local sendSizer = wx.wxFlexGridSizer(0, 1, 5, 5)
    sendSizer:AddGrowableRow(2)
    sendSizer:Add(radioBox, 0, 0)
    sendSizer:Add(checkListBox, 0, 0)

    local sendButton = wx.wxButton(panel, SENDBUTTON_ID, "Send Data")
    sendSizer:Add(sendButton, 0, wx.wxEXPAND, 0)

    sizer:Add(sendSizer, 0, wx.wxEXPAND, 0)

    --sizer:Add(radioBox, 1, wx.wxALL + wx.wxGROW, 0)
    --sizer:Add(checkListBox, 1, wx.wxALL + wx.wxGROW, 0)
    panel:SetSizer(sizer)
    sizer:SetSizeHints(panel)
end

function connectButtons()
    local upFunction = function (event)
        currentCost = currentCost + 10; updateStaticText()
    end

    local downFunction = function (event)
        currentCost = currentCost - 10; updateStaticText()
    end

    local sendFunction = function(event)
        sensorSocket.sendInformations(currentCost)
    end

    frame:Connect(RADIOBOX_ID, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, timerSeconds)
    frame:Connect(CHECKLISTBOX_ID, wx.wxEVT_COMMAND_CHECKLISTBOX_TOGGLED, automaticSend)
    frame:Connect(UPBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, upFunction)
    frame:Connect(DOWNBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, downFunction)
    frame:Connect(SENDBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, sendFunction)

    local accelTable = wx.wxAcceleratorTable({
        {wx.wxACCEL_NORMAL, wx.WXK_UP, UPBUTTON_ID}, 
    {wx.wxACCEL_NORMAL, wx.WXK_DOWN, DOWNBUTTON_ID}})

    frame:SetAcceleratorTable(accelTable)
end

function sendTimer(panel)
    timer = wx.wxTimer(panel)
    local timeEvent = function (event)
        sensorSocket.sendInformations(currentCost)
        if(timerParams.updated) then
            timer:Stop()
            timer:Start(1000 * timerParams.seconds)
        end
    end
    panel:Connect(wx.wxEVT_TIMER, timeEvent)
    --timer:Start(1000)

    local closeTimer = function (event)
        event:Skip()
        if timer then
            timer:Stop() -- always stop before exiting or deleting it
            timer:delete()
            timer = nil
        end
    end

    frame:Connect(wx.wxEVT_CLOSE_WINDOW, closeTimer)

end

function main()
    -- create the hierarchy: frame -> notebook
    frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Sensor Client", wx.wxDefaultPosition, wx.wxSize(200, 200))
    frame:CreateStatusBar(1)
    frame:SetStatusText("Sensor ID", 0)

    -- create first panel in the notebook control
    local panel_1 = wx.wxScrolledWindow(frame, wx.wxID_ANY)
    local sizer_1 = wx.wxBoxSizer(wx.wxVERTICAL)

    firstPanel(panel_1, sizer_1, frame)

    frame:SetSizeHints(frame:GetBestSize():GetWidth(), frame:GetBestSize():GetHeight())

    connectButtons()
    sendTimer(panel_1)

    panel_1:SetAutoLayout(true)

    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
