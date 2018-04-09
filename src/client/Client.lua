local socket = require "socket"

local Client = {}

function Client:new()

    local self = {
        host; 
        port; 

        sensorID; 
        clientMail; 

        constructor = function(this)
            this.host = "192.168.0.109"
            this.port = 3030
            this.sensorID = ""
            this.clientMail = ""
        end
    } 

    self.constructor(self)

    local function canConnect()
        if(self.clientMail:match("^[%w.]+@%w+%.%w+$") and #self.sensorID > 1) then
            return true
        end
        return false
    end

    local function sendMessage()
        if not canConnect then return false end
        local server = socket.connect(self.host, self.port)
        if server then --connection established
            server:send("[sensorID]<" .. self.sensorID .. ">)([clientMail]<" .. self.clientMail .. ">\n")
            if(server:receive() == "$AUT") then -- authenticated connection
                return server
            else
                return false
            end
        end
        return nil
    end

    local function sendNewGoal(newGoal)
        local server = sendMessage()
        if(server) then
            server:send("[goal]:=" .. newGoal)
            server:close()
        end
    end

    local function requireWaterConsume()
        local waterConsumeRow = nil
        local totalWaterExpended = nil

        local server = sendMessage()
        if(server) then
            server:send("[requireWater]?><")
            repeat 
                local message, err = server:receive()
                if not message then
                    server:close()
                    break
                end
                if message:match("[totalWater]:=") then
                    local begining, ending = message:find("[totalWater]:=")
                    totalWaterExpended = tonumber(message:sub(ending))
                else
                    local begining, ending = message:find("[waterConsume]<")
                    local newConsume = {consume = 0, dateTime = ""}
                    newConsume.consume = tonumber(message:sub(ending):match("%d"))
                    begining, ending = message:find(">)([clientMail]<")
                    newConsume.dateTime = message:match("[.^>]+")
                end
            until not server
        end

        return waterConsumeRow, totalWaterExpended
    end

    return {sendNewGoal = sendNewGoal, requireWaterConsume = requireWaterConsume}
end

return Client
