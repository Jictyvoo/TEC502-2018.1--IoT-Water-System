local socket = require "socket"
local macadress = require "util.macAdress"

local Sensor = {}

function Sensor:new()
    local self = {
        host; 
        port; 
        udp; 
        id; 

        constructor = function(this)
            this.host = "192.168.0.109"
            this.port = 3031
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
