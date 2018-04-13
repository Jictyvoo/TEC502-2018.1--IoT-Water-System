local socket = require "socket"
local Json = require "util.Json"
local macadress = require "util.macAdress"

local Sensor = {}

function Sensor:new()
    local self = {
        host; 
        port; 
        udp; 
        id; 

        constructor = function(this)
            local file = io.open("config.snr", "r")
            local config = {host = "192.168.43.250", port = 3031}
            if(not file) then
                file = io.open("config.snr", "w")
                file:write(Json.encode(config))
            else
                config = Json.decode(file:read("*all"))
            end
            file:close()
            this.host = config.host
            this.port = config.port
            this.udp = assert(socket.udp())
            this.id = macadress:findMac()
        end
    }

    self.constructor(self)
    
    local sendInformations = function(message)
        assert(self.udp:sendto(self.id .. "->" .. message .. "[=]:" .. os.date("%Y-%m-%d %H:%M:%S"), self.host, self.port))
        --print(self.id .. "->" .. message .. "[=]:" .. os.date("%c"))
    end

    local getMAC = function()
        return self.id
    end

    return {
        sendInformations = sendInformations, 
        getMAC = getMAC
    }

end

return Sensor
