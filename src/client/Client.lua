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
local socket = require "socket" --import socket api
local Json = require "util.Json" --import json enconde/decode api
local Client = {} --create a Client table
function Client:new() --create the client function to instanciate a new client object
    local self = {--create a local table to stores private attributes
        host; --atribute to storage server host
        port; --atribute to storage server port
        server; --atribute to storage server connection
        sensorID; --atribute to storage sensor ID for authenticate server connection
        clientMail; --atribute to storage client email

        constructor = function(this) --contructor to iniatilize private attributes
            local file = io.open("config.clt", "r") --open configuration file
            local config = {host = "192.168.0.109", port = 3030, sensorID = "", clientMail = ""} --standard config
            if(not file) then --if file does not exist create a new with standard config
                file = io.open("config.clt", "w")
                file:write(Json.encode(config)) --write standard config with json encode
            else
                config = Json.decode(file:read("*all")) --if file exists load into config table
            end
            file:close() --close opened file
            this.host = config.host --configure private host attribute
            this.port = config.port --configure private port attribute
            this.sensorID = config.sensorID --configure private sensorID attribute
            this.clientMail = config.clientMail --configure private clientMail attribute
            this.server = socket.tcp() --create a tcp object for connection
            this.server:bind(this.host, this.port) --establish the port and host to connect
            this.server:settimeout(0.1) --set timeout connection for don't stop client UI
        end
    }

    self.constructor(self) --execute constructor

    local function newSocket() --function to create a new socket after the previous has closed
        self.server = socket.tcp()
        self.server:bind(self.host, self.port)
        self.server:settimeout(0.1)
    end

    local function setSensorID(sensorID)
        self.sensorID = sensorID
    end

    local function setClientMail(clientMail)
        self.clientMail = clientMail
    end

    local function canConnect() --function to verify email pattern and returns if can or not connect
        if(self.clientMail:match("^[%w.]+@%w+%.%w+$") and #self.sensorID > 1) then
            return true
        end
        return false
    end

    local function sendMessage() --first function called when go to connect to the server
        if not canConnect() then return false, "Invalid e-mail or Sensor ID" end --return false if can't connect + erro message
        if self.server:connect(self.host, self.port) then --connection established
            self.server:send("[sensorID]<" .. self.sensorID .. ">)([clientMail]<" .. self.clientMail .. ">\n")
            local message = self.server:receive() --receive server reply
            if(not message) then --for some reason I need to put this here to work correctly
                message = self.server:receive() --receive server reply again if not succeed in first time
            end
            print(message) --print server reply for tests
            if(message == "$NOTAUT") then -- authenticated connection
                return false, "verify your credencials to try again" --return error message
            elseif(message ~= "[sensorID]<" .. self.sensorID .. ">)([clientMail]<" .. self.clientMail .. ">\n") then
                return true --return that connect has established succefully
            end
        end
        return nil, "Verify your internet connection to try again" --return error message if can't connect to server
    end

    local function sendNewGoal(newGoal) --function to send goal message to the server
        local authenticated, err = sendMessage() --call previous function and storage it returns
        if(authenticated) then --verify if was authenticated and can go ahed with connection
            self.server:send(string.format("[goal]:=%d\n", newGoal)) --send goal to the server
        end
        self.server:close() --after complete the connection purpose, close the server
        newSocket() --create a new socket after close the other one
        return (not authenticated and {"Authentication Error", err}) or nil --return error message or nil
    end

    local function requireWaterConsume() --function to require water from the server
        local waterConsumeRow = {} --table to storage all consume received from server
        local totalWaterExpended = nil --local variable to storage totalWaterExpended received from server
        local receivedGoal = nil --local variable to storage goal received from server
        local authenticated, err = sendMessage() --call previous function and storage it returns
        if(authenticated) then --verify if was authenticated and can go ahed with connection
            self.server:send("[requireWater]?><\n") --send requirement to server
            repeat --repeat until connection socket is opened
                local message, err = self.server:receive() --receive server message/reply
                --print(message, err)
                if not message then --if not receive server message/reply, close connection
                    self.server:close()
                    newSocket() --create a new socket after close the other one
                    break
                end
                if message:match("%[totalWater%]:=") then --if receive totalWater in message, do a specific treatment
                    local begining, ending = message:find("%[expendGoal%]:=")
                    if(ending) then --if receive expendGoal too, have a different treatment
                        totalWaterExpended = tonumber(message:sub(1, begining):match("%d+%.?%d*"))
                        receivedGoal = tonumber(message:sub(ending):match("%d+%.?%d*"))
                    else
                        totalWaterExpended = tonumber(message:match("%d+%.?%d*"))
                    end
                else
                    local begining, ending = message:find("%[waterConsume%]<") --if receive all consume rows, store then
                    local newConsume = {consume = 0, dateTime = ""} --create a temporary table
                    newConsume.consume = tonumber(message:sub(ending):match("%d+%.?%d*")) --storage information in temporary table
                    begining, ending = message:find(">%)%(%[dateTime%]<")
                    newConsume.dateTime = message:sub(ending + 1):match("[%d-:%s]+") --storage information in temporary table
                    table.insert(waterConsumeRow, newConsume) --insert temporary table into return consume table
                end
            until not self.server
        end
        self.server:close()
        newSocket() --create a new socket after close the other one
        return waterConsumeRow, totalWaterExpended, receivedGoal, (not authenticated and {"Authentication Error", err}) or nil
    end
    
    return {--return public methods that can be acessed in external code
        sendNewGoal = sendNewGoal;
        requireWaterConsume = requireWaterConsume;
        setSensorID = setSensorID;
        setClientMail = setClientMail;
    }
end
return Client --return Client object with new function
