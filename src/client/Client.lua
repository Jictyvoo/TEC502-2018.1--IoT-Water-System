local socket = require "socket"
local Json = require "util.Json"
local Client = {}
function Client:new()
    local self = {
        host;
        port;
        server;
        sensorID;
        clientMail;
        constructor = function(this)
            local file = io.open("config.clt", "r")
            local config = {host = "192.168.43.250", port = 3030, sensorID = "", clientMail = ""}
            if(not file) then
                file = io.open("config.clt", "w")
                file:write(Json.encode(config))
            else
                config = Json.decode(file:read("*all"))
            end
            file:close()
            this.host = config.host
            this.port = config.port
            this.sensorID = config.sensorID
            this.clientMail = config.clientMail
            this.server = socket.tcp()
            this.server:bind(this.host, this.port)
            this.server:settimeout(0.01)
        end
    }
    self.constructor(self)
    local function newSocket()
        self.server = socket.tcp()
        self.server:bind(self.host, self.port)
        self.server:settimeout(0.01)
    end
    local function setSensorID(sensorID)
        self.sensorID = sensorID
    end
    local function setClientMail(clientMail)
        self.clientMail = clientMail
    end
    local function canConnect()
        if(self.clientMail:match("^[%w.]+@%w+%.%w+$") and #self.sensorID > 1) then
            return true
        end
        return false
    end
    local function sendMessage()
        if not true--[[canConnect()--]] then return false end
        if self.server:connect(self.host, self.port) then --connection established
            self.server:send("[sensorID]<" .. self.sensorID .. ">)([clientMail]<" .. self.clientMail .. ">\n")
            --print("Information Sended") --works at here
            local message = self.server:receive()
            print(message)
            if(message == "$NOTAUT") then -- authenticated connection
                return false
            else
                return true
            end
        end
        return nil
    end
    local function sendNewGoal(newGoal)
        local authenticated = sendMessage()
        if(authenticated) then
            self.server:send(string.format("[goal]:=%d\n", newGoal))
        end
        self.server:close()
        newSocket()
    end
    local function requireWaterConsume()
        local waterConsumeRow = nil
        local totalWaterExpended = nil
        local authenticated = sendMessage()
        if(authenticated) then
            self.server:send("[requireWater]?><")
            repeat
                local message, err = self.server:receive()
                if not message then
                    self.server:close()
                    break
                end
                if message:match("[totalWater]:=") then
                    local begining, ending = message:find("[totalWater]:=")
                    totalWaterExpended = tonumber(message:sub(ending))
                else
                    local begining, ending = message:find("[waterConsume]<")
                    local newConsume = {consume = 0, dateTime = ""}
                    newConsume.consume = tonumber(message:sub(ending):match("%d"))
                    begining, ending = message:find(">)([dateTime]<")
                    newConsume.dateTime = message:match("[.^>]+")
                end
            until not self.server
        end
        self.server:close()
        newSocket()
        return waterConsumeRow, totalWaterExpended
    end
    return {
        sendNewGoal = sendNewGoal;
        requireWaterConsume = requireWaterConsume;
        setSensorID = setSensorID;
        setClientMail = setClientMail;
    }
end
return Client
