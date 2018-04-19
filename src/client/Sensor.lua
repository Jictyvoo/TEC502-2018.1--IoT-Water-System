--[[
Autor:João Victor Oliveira Couto

Componente Curricular: Concorrência e Conectividade

Concluido em: 14/04/2018

Declaro que este código foi elaborado por mim de forma individual e não contém nenhum
trecho de código de outro colega ou de outro autor, tais como provindos de livros e
apostilas, e páginas ou documentos eletrônicos da Internet. Qualquer trecho de código
de outra autoria que não a minha está destacado com uma citação para o autor e a fonte
do código, e estou ciente que estes trechos não serão considerados para fins de avaliação.
--]]
local socket = require "socket" --import socket API
local Json = require "util.Json" --import Json API
local macadress = require "util.macAdress" --import macAdress function

local Sensor = {} --create Sesnor table (like a class)

function Sensor:new() --create new function to instance a new object
    local self = {--create a local table to keep atributtes private
        host; --store host for the server
        port; --store port for the server
        udp; --udp object to send informations
        id; --sensor id

        constructor = function(this) --constructor that initializes self atributtes
            local file = io.open("config.snr", "r")
            local config = {host = "192.168.43.250", port = 3031}
            if(not file) then --create a config file if it not exists
                file = io.open("config.snr", "w")
                file:write(Json.encode(config)) --encode config table and write it in file
            else
                config = Json.decode(file:read("*all")) --if file exists, load all the file, decode and stores into config
            end
            file:close()
            this.host = config.host
            this.port = config.port
            this.udp = assert(socket.udp()) --create udp object
            this.id = macadress:findMac() --call C function to find computer MAC
        end
    }

    self.constructor(self)
    
    local sendInformations = function(message) --send informations to server with tcp
        assert(self.udp:sendto(self.id .. "->" .. message .. "[=]:" .. os.date("%Y-%m-%d %H:%M:%S"), self.host, self.port))
        --print(self.id .. "->" .. message .. "[=]:" .. os.date("%c"))
    end

    local getMAC = function() --returns the mac stored in the object
        return self.id
    end

    return {--return the functions that will be visible for others objects
        sendInformations = sendInformations,
        getMAC = getMAC
    }

end

return Sensor --return Sensor table with Sensor:new function
