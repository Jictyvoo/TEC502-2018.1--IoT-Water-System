-----------------------------------------------------------------------------
-- Name:        Sensor.wx.lua
-- Purpose:     Graphical Interface for use the Sensor in IoT tests
-- Author:      João Victor Oliveira Couto
-- Created:     April 2018
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

local sensorSocket = (require "client.Sensor"):new()

local currentFlow = 0 --stores the current flow
local totalConsume = 0 --stores current consume
local previousConsume = 0 --stores previous consume sended
local timer = nil --timer object to send and update GUI
local timerParams = {current = 0, seconds = 60, updated = false, automatic = false} --table for control timer

local TEXTENTRY_ID = 1001 --id for text entry
local UPBUTTON_ID = 1002 --id for uo button
local DOWNBUTTON_ID = 1003 --id for down button
local RADIOBOX_ID = 1004 --id for radio box
local CHECKLISTBOX_ID = 1005 --id check list box
local SENDBUTTON_ID = 1006 --id for send button

local UI = {} --main table thats stores all graphical items

-- create mainFrame
UI.mainFrame = wx.wxFrame (wx.NULL, wx.wxID_ANY, "Inova Sensor", wx.wxDefaultPosition, wx.wxSize(230, 250), wx.wxCLOSE_BOX + wx.wxDEFAULT_FRAME_STYLE + wx.wxMAXIMIZE_BOX + wx.wxMINIMIZE_BOX + wx.wxTAB_TRAVERSAL)
UI.mainFrame:SetSizeHints(wx.wxSize(230, 250), wx.wxSize(230, 250)) --set mainFrame size

UI.statusBarSensor = UI.mainFrame:CreateStatusBar(1) --create a status bar to show mac address
UI.mainFrame:SetStatusText(string.format("Sensor ID:%s", sensorSocket.getMAC()), 0)
UI.mainSizer = wx.wxBoxSizer(wx.wxVERTICAL) --create a sizer to put GUI items

UI.mainPanel = wx.wxPanel(UI.mainFrame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
UI.panelSizer = wx.wxBoxSizer(wx.wxVERTICAL) --create a sizer inside the panel that is inside the mainSizer

UI.currentFlow_staticText = wx.wxStaticText(UI.mainPanel, wx.wxID_ANY, string.format("Current Flow: %.2fm³/s", currentFlow), wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.currentFlow_staticText:Wrap(-1)
UI.panelSizer:Add(UI.currentFlow_staticText, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --add staticText into sizer

UI.totalConsume_staticText = wx.wxStaticText(UI.mainPanel, wx.wxID_ANY, string.format("Total Consume: %.2fm³", totalConsume), wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.totalConsume_staticText:Wrap(-1)
UI.panelSizer:Add(UI.totalConsume_staticText, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --add staticText into sizer

UI.buttonSizer_grid = wx.wxGridSizer(0, 2, 0, 0) --create a sizer only for buttons

UI.upButton = wx.wxButton(UI.mainPanel, UPBUTTON_ID, "Up", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.buttonSizer_grid:Add(UI.upButton, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --create the burron and put in sizer

UI.downButton = wx.wxButton(UI.mainPanel, DOWNBUTTON_ID, "Down", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.buttonSizer_grid:Add(UI.downButton, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --create the burron and put in sizer

UI.panelSizer:Add(UI.buttonSizer_grid, 1, wx.wxEXPAND, 5) --put button sizer into panel sizer

UI.sycronization_radioBoxChoices = {"1", "5", "10", "60"} --create a table thats stores all the options
UI.sycronization_radioBox = wx.wxRadioBox(UI.mainPanel, RADIOBOX_ID, "Syncronization Frequency", wx.wxDefaultPosition, wx.wxDefaultSize, UI.sycronization_radioBoxChoices, 1, wx.wxRA_SPECIFY_ROWS)
UI.sycronization_radioBox:SetSelection(0) --set default selection to the first item in the Radio Box
UI.panelSizer:Add(UI.sycronization_radioBox, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --adds the radio box into panel sizer

UI.sendAutomatic_checkBox = wx.wxCheckBox(UI.mainPanel, CHECKLISTBOX_ID, "Send Automatic Data", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.panelSizer:Add(UI.sendAutomatic_checkBox, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --puts checkBox into the panel sizer

UI.sendData_button = wx.wxButton(UI.mainPanel, SENDBUTTON_ID, "Send Data", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.panelSizer:Add(UI.sendData_button, 0, wx.wxALIGN_CENTER + wx.wxALL, 5) --puts send data button into panel sizer

UI.mainPanel:SetSizer(UI.panelSizer) --set panel sizer into main sizer
UI.mainPanel:Layout()
UI.panelSizer:Fit(UI.mainPanel) --fit panel sizer with mainPanel size
UI.mainSizer:Add(UI.mainPanel, 1, wx.wxEXPAND + wx. wxALL, 5) --put main panel into main sizer

UI.mainFrame:SetSizer(UI.mainSizer) --set main sizer into main frame
UI.mainFrame:Layout()

UI.mainFrame:Centre(wx.wxBOTH)

--[[Space for UI functions--]]
function timerSeconds(event) --function that's change the time to send data to server
    local timeString = event:GetString()
    timerParams.seconds = tonumber(timeString) * 60 --multiply selected time for 60 to be minutes
    timerParams.updated = true --informs about time update
end

function automaticSend(event) --function that activate automatic send of data
    if(UI.sendAutomatic_checkBox:IsChecked()) then
        timerParams.automatic = true
    else
        timerParams.automatic = false
        timerParams.current = 0 --put 0 into current timelapse
    end
end

function updateCurrentFlow_staticText() --function to update static text in UI
    UI.currentFlow_staticText:SetLabel(string.format("Current Flow: %.2fm³/s", currentFlow))
end

function updateTotalConsume_staticText() --function to update static text in UI
    UI.totalConsume_staticText:SetLabel(string.format("Total Consume: %.2fm³", totalConsume))
end

function connectButtons() --function to connect buttons to events
    local upFunction = function (event) --local function that update current flow
        currentFlow = currentFlow + 0.01; updateCurrentFlow_staticText()
    end

    local downFunction = function (event) --local function that update current flow
        currentFlow = currentFlow > 0 and (currentFlow - 0.01) or currentFlow
        updateCurrentFlow_staticText()
    end

    local sendFunction = function(event) --local function that call socket send data function
        sensorSocket.sendInformations(totalConsume - previousConsume)
        previousConsume = totalConsume
    end

    --now connect all the UI items to functions and events to execute it
    UI.mainFrame:Connect(RADIOBOX_ID, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, timerSeconds)
    UI.mainFrame:Connect(CHECKLISTBOX_ID, wx.wxEVT_COMMAND_CHECKBOX_CLICKED, automaticSend)
    UI.mainFrame:Connect(UPBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, upFunction)
    UI.mainFrame:Connect(DOWNBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, downFunction)
    UI.mainFrame:Connect(SENDBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, sendFunction)

    local accelTable = wx.wxAcceleratorTable({--a table that enable use of the keyboard
        {wx.wxACCEL_NORMAL, wx.WXK_UP, UPBUTTON_ID},
    {wx.wxACCEL_NORMAL, wx.WXK_DOWN, DOWNBUTTON_ID}})

    UI.mainFrame:SetAcceleratorTable(accelTable)
end

function sendTimer(panel) --function that's create a timer in UI
    timer = wx.wxTimer(panel)
    local timeEvent = function (event) --event that execute with time event
        if(timerParams.automatic) then --verify if is sending automatic data
            timerParams.current = timerParams.current + 1 --count seconds passed
            if(timerParams.current >= timerParams.seconds) then --if it's time to send, send data
                sensorSocket.sendInformations(totalConsume - previousConsume)
                previousConsume = totalConsume --establish the previous consume to be current consume
                timerParams.current = 0 --put 0 in time counter
            end
        end
        totalConsume = totalConsume + currentFlow --update total consume every second
        updateTotalConsume_staticText()
    end
    panel:Connect(wx.wxEVT_TIMER, timeEvent) --connect timer event
    timer:Start(1000) --start timer that will invoke event every second

    local closeTimer = function (event) --event to close timer if program closed
        event:Skip() --skip event
        if timer then
            timer:Stop() -- always stop before exiting or deleting it
            timer:delete()
            timer = nil
        end
    end

    UI.mainFrame:Connect(wx.wxEVT_CLOSE_WINDOW, closeTimer) --connect close event

end

connectButtons() --call function connectButtons
sendTimer(UI.mainPanel) --call function sendTimer

UI.mainFrame:Show(true) -- show the frame

wx.wxGetApp():MainLoop() --execute main loop
