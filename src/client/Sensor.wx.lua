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

local frame = nil
local currentFlow = 0
local totalConsume = 0
local previousConsume = 0
local timer = nil
local timerParams = {current = 0, seconds = 60, updated = false, automatic = false}

local TEXTENTRY_ID = 1001
local UPBUTTON_ID = 1002
local DOWNBUTTON_ID = 1003
local RADIOBOX_ID = 1004
local CHECKLISTBOX_ID = 1005
local SENDBUTTON_ID = 1006

local UI = {}

-- create mainFrame
UI.mainFrame = wx.wxFrame (wx.NULL, wx.wxID_ANY, "Inova Sensor", wx.wxDefaultPosition, wx.wxSize(230, 250), wx.wxCLOSE_BOX + wx.wxDEFAULT_FRAME_STYLE + wx.wxMAXIMIZE_BOX + wx.wxMINIMIZE_BOX + wx.wxTAB_TRAVERSAL)
UI.mainFrame:SetSizeHints(wx.wxSize(230, 250), wx.wxSize(230, 250))

UI.statusBarSensor = UI.mainFrame:CreateStatusBar(1)
UI.mainFrame:SetStatusText(string.format("Sensor ID:%s", sensorSocket.getMAC()), 0)
UI.mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)

UI.mainPanel = wx.wxPanel(UI.mainFrame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
UI.panelSizer = wx.wxBoxSizer(wx.wxVERTICAL)

UI.currentFlow_staticText = wx.wxStaticText(UI.mainPanel, wx.wxID_ANY, string.format("Current Flow: %.2fm³/s", currentFlow), wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.currentFlow_staticText:Wrap(-1)
UI.panelSizer:Add(UI.currentFlow_staticText, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.totalConsume_staticText = wx.wxStaticText(UI.mainPanel, wx.wxID_ANY, string.format("Total Consume: %.2fm³", totalConsume), wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.totalConsume_staticText:Wrap(-1)
UI.panelSizer:Add(UI.totalConsume_staticText, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.buttonSizer_grid = wx.wxGridSizer(0, 2, 0, 0)

UI.upButton = wx.wxButton(UI.mainPanel, UPBUTTON_ID, "Up", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.buttonSizer_grid:Add(UI.upButton, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.downButton = wx.wxButton(UI.mainPanel, DOWNBUTTON_ID, "Down", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.buttonSizer_grid:Add(UI.downButton, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.panelSizer:Add(UI.buttonSizer_grid, 1, wx.wxEXPAND, 5)

UI.sycronization_radioBoxChoices = {"1", "5", "10", "60"}
UI.sycronization_radioBox = wx.wxRadioBox(UI.mainPanel, RADIOBOX_ID, "Syncronization Frequency", wx.wxDefaultPosition, wx.wxDefaultSize, UI.sycronization_radioBoxChoices, 1, wx.wxRA_SPECIFY_ROWS)
UI.sycronization_radioBox:SetSelection(0)
UI.panelSizer:Add(UI.sycronization_radioBox, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.sendAutomatic_checkBox = wx.wxCheckBox(UI.mainPanel, CHECKLISTBOX_ID, "Send Automatic Data", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.panelSizer:Add(UI.sendAutomatic_checkBox, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.sendData_button = wx.wxButton(UI.mainPanel, SENDBUTTON_ID, "Send Data", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
UI.panelSizer:Add(UI.sendData_button, 0, wx.wxALIGN_CENTER + wx.wxALL, 5)

UI.mainPanel:SetSizer(UI.panelSizer)
UI.mainPanel:Layout()
UI.panelSizer:Fit(UI.mainPanel)
UI.mainSizer:Add(UI.mainPanel, 1, wx.wxEXPAND + wx. wxALL, 5)

UI.mainFrame:SetSizer(UI.mainSizer)
UI.mainFrame:Layout()

UI.mainFrame:Centre(wx.wxBOTH)

--[[Space for UI functions--]]
function timerSeconds(event)
    local timeString = event:GetString()
    timerParams.seconds = tonumber(timeString) * 60
    timerParams.updated = true
end

function automaticSend(event)
    if(UI.sendAutomatic_checkBox:IsChecked()) then
        timerParams.automatic = true
    else
        timerParams.automatic = false
        timerParams.current = 0
    end
end

function updateCurrentFlow_staticText()
    UI.currentFlow_staticText:SetLabel(string.format("Current Flow: %.2fm³/s", currentFlow))
end

function updateTotalConsume_staticText()
    UI.totalConsume_staticText:SetLabel(string.format("Total Consume: %.2fm³", totalConsume))
end

function connectButtons()
    local upFunction = function (event)
        currentFlow = currentFlow + 0.01; updateCurrentFlow_staticText()
    end

    local downFunction = function (event)
        currentFlow = currentFlow > 0 and (currentFlow - 0.01) or currentFlow
        updateCurrentFlow_staticText()
    end

    local sendFunction = function(event)
        sensorSocket.sendInformations(totalConsume - previousConsume)
        previousConsume = totalConsume
    end

    UI.mainFrame:Connect(RADIOBOX_ID, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, timerSeconds)
    UI.mainFrame:Connect(CHECKLISTBOX_ID, wx.wxEVT_COMMAND_CHECKBOX_CLICKED, automaticSend)
    UI.mainFrame:Connect(UPBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, upFunction)
    UI.mainFrame:Connect(DOWNBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, downFunction)
    UI.mainFrame:Connect(SENDBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, sendFunction)

    local accelTable = wx.wxAcceleratorTable({
        {wx.wxACCEL_NORMAL, wx.WXK_UP, UPBUTTON_ID},
    {wx.wxACCEL_NORMAL, wx.WXK_DOWN, DOWNBUTTON_ID}})

    UI.mainFrame:SetAcceleratorTable(accelTable)
end

function sendTimer(panel)
    timer = wx.wxTimer(panel)
    local timeEvent = function (event)
        if(timerParams.automatic) then
            timerParams.current = timerParams.current + 1
            if(timerParams.current >= timerParams.seconds) then
                sensorSocket.sendInformations(totalConsume - previousConsume)
                previousConsume = totalConsume
                timerParams.current = 0
            end
        end
        totalConsume = totalConsume + currentFlow
        updateTotalConsume_staticText()
        --[=[if(timerParams.updated) then
            timer:Stop()
            timer:Start(1000--[[ * timerParams.seconds--]])
        end--]=]
    end
    panel:Connect(wx.wxEVT_TIMER, timeEvent)
    timer:Start(1000)

    local closeTimer = function (event)
        event:Skip()
        if timer then
            timer:Stop() -- always stop before exiting or deleting it
            timer:delete()
            timer = nil
        end
    end

    UI.mainFrame:Connect(wx.wxEVT_CLOSE_WINDOW, closeTimer)

end

connectButtons()
sendTimer(UI.mainPanel)

UI.mainFrame:Show(true)

wx.wxGetApp():MainLoop()
