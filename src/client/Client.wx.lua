-----------------------------------------------------------------------------
-- Name:        Client.wx.lua
-- Purpose:     Settings wxLua sample - show results of all informational functions
-- Author:      João Victor Oliveira Couto
-- Modified by:
-- Created:     05/04/2018
-- RCS-ID:
-- Copyright:   (c) 2018 João Victor Oliveira Couto
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath .. ";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")
local clientSocket = (require "client.Client"):new()

local frame = nil
local listCtrl = nil
local goalTextCtrl = nil
local currentGoal = "undefined"
local currentExpenditure = 0
local savedEmail = ""
local savedSensorID = ""

local ID_LISTCTRL = 1000
local CURRENTGOALTEXT = 1001
local CURRENTEXPENDITURE = 1002
local CONFIGURATIONDIALOG_ID = 1003
local CONFIGUREBUTTON_ID = 1004
local REFRESHBUTTON_ID = 1005
local SENDBUTTON_ID = 1006
local GOALTEXTCTRL_ID = 1007
-- ---------------------------------------------------------------------------
-- Add a list item with multiple col data
-- ---------------------------------------------------------------------------

function AddListItem(colTable)
    local lc_item = listCtrl:GetItemCount()

    lc_item = listCtrl:InsertItem(lc_item, colTable[1])
    listCtrl:SetItem(lc_item, 1, tostring(colTable[2]))

    return lc_item
end

-- ---------------------------------------------------------------------------
-- Fill the listctrl
-- ---------------------------------------------------------------------------

function FillListCtrl(listCtrl)
    listCtrl: DeleteAllItems()
    for i = 0, 100, 1 do
        AddListItem({"\t\t\t" .. i, os.date()})
    end
end

function listPanel(panel, sizer)
    listCtrl = wx.wxListView(panel, ID_LISTCTRL, wx.wxDefaultPosition, wx.wxDefaultSize, 
    wx.wxLC_REPORT)

    listCtrl:InsertColumn(0, "Water Consume (m³/s)")
    listCtrl:InsertColumn(1, "Date/Hour")

    listCtrl:SetColumnWidth(0, 200)
    listCtrl:SetColumnWidth(1, 200)
    
    sizer:Add(listCtrl, 0, wx.wxALL + wx.wxGROW, 6)
    return listCtrl
end

function informationPanel(panel, sizer)
    local refreshButton = wx.wxButton(panel, REFRESHBUTTON_ID, "Refresh", wx.wxDefaultPosition, wx.wxDefaultSize)
    sizer:Add(refreshButton, 0, wx.wxALL + wx.wxGROW, 6)

    local configurationButton = wx.wxButton(panel, CONFIGUREBUTTON_ID, "Configuration", wx.wxDefaultPosition, wx.wxDefaultSize)
    sizer:Add(configurationButton, 0, wx.wxALL + wx.wxGROW, 6)
end

function goalPanel(panel, sizer)
    local textSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    local currentGoalText = wx.wxStaticText(panel, CURRENTGOALTEXT, "Current Goal: " .. currentGoal .. " m³")
    local currentExpenditure = wx.wxStaticText(panel, CURRENTEXPENDITURE, "Current Expenditure: " .. currentExpenditure .. "m³")
    textSizer:Add(currentGoalText, 0, wx.wxALL + wx.wxGROW, 6)
    textSizer:Add(currentExpenditure, 0, wx.wxALL + wx.wxGROW, 6)

    local flexSizer = wx.wxFlexGridSizer(1, 0, 5, 5)

    flexSizer:Add(textSizer, 0, wx.wxALL + wx.wxGROW, 6)

    local sendFlexSizer = wx.wxFlexGridSizer(0, 3, 0, 0)

    local textNewGoal = wx.wxStaticText(panel, wx.wxID_ANY, "New Goal: ")
    sendFlexSizer:Add(textNewGoal, 0, wx.wxALL + wx.wxGROW, 6)

    goalTextCtrl = wx.wxTextCtrl(panel, GOALTEXTCTRL_ID, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_PROCESS_ENTER)
    sendFlexSizer:Add(goalTextCtrl, 0, wx.wxALL + wx.wxGROW, 6)

    local sendButton = wx.wxButton(panel, SENDBUTTON_ID, "Send", wx.wxDefaultPosition, wx.wxSize(wx.wxDefaultSize:GetWidth(), 30))
    sendFlexSizer:Add(sendButton, 0, wx.wxALL + wx.wxGROW, 0)
    flexSizer:Add(sendFlexSizer, 0, wx.wxALL + wx.wxGROW, 6)
    sizer:Add(flexSizer, 0, wx.wxALL + wx.wxGROW, 6)
end

function configurationDialog(parentWindow)
    local CONFIGPANEL_ID = 2000
    local EMAILADDRESSTEXT_ID = 2001
    local SENSORIDTEXT_ID = 2002
    local dialogConfig = wx.wxDialog(parentWindow, CONFIGURATIONDIALOG_ID, "Configure Client", wx.wxDefaultPosition, 
    wx.wxSize(300, 100))

    local configPanel = wx.wxPanel(dialogConfig, CONFIGPANEL_ID)
    local configSizer = wx.wxBoxSizer(wx.wxVERTICAL)

    local emailHorizontalSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local emailStaticText = wx.wxStaticText(configPanel, wx.wxID_ANY, "Put your e-mail address:")
    local emailTextInput = wx.wxTextCtrl(configPanel, EMAILADDRESSTEXT_ID, savedEmail)

    emailHorizontalSizer:Add(emailStaticText, 0, wx.wxALL + wx.wxGROW, 6)
    emailHorizontalSizer:Add(emailTextInput, 0, wx.wxALL + wx.wxGROW, 6)
    configSizer:Add(emailHorizontalSizer, 0, wx.wxALL + wx.wxGROW, 0)

    local sensorIdHorizontalSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local sensorIdStaticText = wx.wxStaticText(configPanel, wx.wxID_ANY, "Put your sensor ID:")
    local sensorIdTextInput = wx.wxTextCtrl(configPanel, SENSORIDTEXT_ID, savedSensorID)

    sensorIdHorizontalSizer:Add(sensorIdStaticText, 0, wx.wxALL + wx.wxGROW, 6)
    sensorIdHorizontalSizer:Add(sensorIdTextInput, 0, wx.wxALL + wx.wxGROW, 6)
    configSizer:Add(sensorIdHorizontalSizer, 0, wx.wxALL + wx.wxGROW, 0)

    configPanel:SetSizer(configSizer)

    local onQuitDialog = function(event)
        event:Skip()
        savedEmail = emailTextInput:GetValue()
        savedSensorID = sensorIdTextInput:GetValue()
    end
    dialogConfig:Connect(wx.wxEVT_CLOSE_WINDOW, onQuitDialog) 
    dialogConfig:Show(true)
end

function manipulateEvents()
    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    local closeFrameFunction = function (event)
        frame:Close(true)
    end
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, closeFrameFunction)

    -- connect the selection event of the about menu item
    local eventAbout = function (event)
        wx.wxMessageBox("This is the a Inova System to monitore your water consume.\n", 
        "About Inova Client", wx.wxOK + wx.wxICON_INFORMATION, frame)
    end 
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, eventAbout)

    local sendGoal = function(event) event:Skip(); clientSocket.sendNewGoal(goalTextCtrl:GetValue()) end

    frame:Connect(CONFIGUREBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event) event:Skip(); configurationDialog(frame) end)
    frame:Connect(REFRESHBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event) event:Skip(); FillListCtrl(listCtrl) end)
    frame:Connect(SENDBUTTON_ID, wx.wxEVT_COMMAND_BUTTON_CLICKED, sendGoal)
end

function configureMenuBar()
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the Inova Client Application")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")
    frame:SetMenuBar(menuBar)
end
-- ---------------------------------------------------------------------------
-- Main entry into the program
-- ---------------------------------------------------------------------------
function main()

    -- create the wxFrame window
    frame = wx.wxFrame(wx.NULL, -- no parent for toplevel windows
        wx.wxID_ANY, -- don't need a wxWindow ID
        "Inova Client", -- caption on the frame
        wx.wxDefaultPosition, -- let system place the frame
        wx.wxSize(556, 300), -- set the size of the frame
    wx.wxDEFAULT_FRAME_STYLE) -- use default frame styles
    frame:CreateStatusBar(1)
    frame:SetStatusText("Startup Inova")

    --create the panel
    local panel_1 = wx.wxPanel(frame, wx.wxID_ANY)
    local sizer_1 = wx.wxBoxSizer(wx.wxVERTICAL)
    local flexSizer = wx.wxFlexGridSizer(1, 0, 5, 5)
    flexSizer:AddGrowableCol(2)

    listCtrl = listPanel(panel_1, flexSizer) 
    FillListCtrl(listCtrl)

    local buttonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    informationPanel(panel_1, buttonSizer)

    flexSizer:Add(buttonSizer, 0, wx.wxEXPAND, 0)
    sizer_1:Add(flexSizer, 0, wx.wxEXPAND, 0)

    goalPanel(panel_1, sizer_1)

    panel_1:SetSizer(sizer_1)
    sizer_1:SetSizeHints(panel_1) -- limits page resize

    manipulateEvents()
    configureMenuBar()

    frame:SetSizeHints(frame:GetBestSize():GetWidth(), frame:GetBestSize():GetHeight())
    panel_1:SetAutoLayout(true)

    -- show the frame window
    frame:Show(true)

    configurationDialog(frame)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
