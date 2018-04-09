local socket = require "socket"

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
            this.id = "94:39:e5:f6:6c:1d"
        end
    }

    self.constructor(self)

    local sendInformations = function(message)
        assert(self.udp:sendto(self.id .. "->" .. message .. "[=]:" .. os.date("%Y-%m-%d %H:%M:%S"), self.host, self.port))
        --print(self.id .. "->" .. message .. "[=]:" .. os.date("%c"))
    end

    return {sendInformations = sendInformations}

end

return Sensor
