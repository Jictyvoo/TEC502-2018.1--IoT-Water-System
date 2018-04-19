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
local DataManager = require "server.DataManager" --import DataManager object class
local sqlite3 = (require "luasql.sqlite3"):sqlite3() --import sqlite3 api
local Server = {} --create table to have new function
function Server:new() --function to instantiate the object
    local self = {--local table to storage private attributes
        host; --server host attribute
        port; --server port attribute
        server; --server connection object
        databaseConnection; --database connection object
        udp_thread; --thread that will run udp connections
        tcp_thread; --thread that will run tcp connections
        goal_thread; --thread that will search clients that reached established goal
        dataManager; --dataManager object
        connectedClients; --table that stores connected clients threads
        emailAdress; --table that storage all email address of clients for evitate everytime write
        constructor = function(this) --constructor to initialize server attributes
            this.host = "192.168.0.109"
            this.port = 3035
            this.udp_thread = nil
            this.tcp_thread = nil
            this.goal_thread = nil
            -- create a TCP socket and bind it to the local host, at any port
            this.server = socket.tcp()
            this.server:bind(this.host, this.port)
            this.server:listen(1000)
            this.server:settimeout(0.001)
            this.connectedClients = {}
            this.emailAdress = {}
            this.databaseConnection = sqlite3:connect("inova_database.sqlite3")
            this.dataManager = DataManager:instance()
            this.dataManager.setConnection(this.databaseConnection)
            this.dataManager.tryCreateTables()
        end
    }
    self.constructor(self) --call constructor function
    local verifyGoal_loop = function() --function that verify client goal
        local verifySearch = coroutine.create(self.dataManager.verifyGoal) --create a thread to verify goal reach
        local lanes = require "lanes".configure() --require lanes api
        local linda = lanes.linda() --create a communication channel whith lanes thread
        local function sendMail() --function that's run in lanes thread
            local NoReply = require "util.NoReply" --require email class
            local no_reply = NoReply:new({title = "Startup Inova", address = "<joao.victor.oliveira.couto@gmail.com>"},
                {title = "Client", address = "<common@mail.com>"},
            {address = "smtp.gmail.com", user = "joao.victor.oliveira.couto@gmail.com", password = "_changed@mail", port = 465})
            while true do
                local key, value = linda:receive(3, "mailMessage") -- timeout in seconds
                if value then --if have somebody to send the email send to it
                    print("Sending to " .. string.format("<%s>", value))
                    no_reply.setTo("Client", string.format("<%s>", value))
                    no_reply.sendMessage("Meta de consumo", "Atingiu a meta de consumo estabelecida")
                end
            end
        end
        local second_thread = lanes.gen("*", sendMail)() --create lanes thread
        while true do --current thread loop
            if(coroutine.status(verifySearch) == "dead") then --if already verify all goals, verify again
                verifySearch = coroutine.create(self.dataManager.verifyGoal)
            end
            local ok, mail = coroutine.resume(verifySearch)
            --print(ok, mail)
            if(mail) then --if have to send a mail, send it to the other thread
                linda:send("mailMessage", mail) -- linda as upvalue
            end
            coroutine.yield() --pause current coroutine
        end
    end
    local executeClient = function() --function that execute client thread
        while true do --main loop for current thread
            for index, value in pairs(self.connectedClients) do --foreach that searchs clients to resume coroutine
                coroutine.resume(value)
                coroutine.yield() --pause current coroutine
            end
            coroutine.yield() --pause current coroutine
        end
    end
    local tcp_loop = function() --function that execute tcp listen thread
        local client = nil --variable that stores accepted client
        while true do --main loop for current thread
            client = self.server:accept() --try to connect to a client
            if(client) then --if successfuly connect to a client
                local peername = client:getpeername()
                print(string.format("Client Connected in IP:%s", peername)) --show that is connected
                local tcp_server = (require "server.Server_TCP"):new(client, self.databaseConnection, self.emailAdress)
                tcp_server.setThreadTable(self.connectedClients) --send clients thread table to new client connection
                tcp_server.start() --start client loop
            end
            coroutine.yield() --pause current coroutine
        end
    end
    local udp_loop = function() --function that execute udp listen thread
        local udp_connection = (require "server.Server_UDP"):new(socket, self.host, self.port + 1, self.databaseConnection)
        udp_connection.receiveInformation() --execute udp main loop
    end
    local startServer = function() --main server function that starts the server
        self.udp_thread = coroutine.create(udp_loop) --create udp coroutine
        self.tcp_thread = coroutine.create(tcp_loop) --create tcp coroutine
        self.goal_thread = coroutine.create(verifyGoal_loop) --create goal coroutine
        local clients = coroutine.create(executeClient) --create clients coroutine
        while true do
            coroutine.resume(self.udp_thread) --resume udp coroutine
            coroutine.resume(self.tcp_thread) --resume tcp coroutine
            coroutine.resume(clients) --resume clients coroutine
            coroutine.resume(self.goal_thread) --resume goal coroutine
            --print(coroutine.status(self.tcp_thread))
        end
    end
    return {startServer = startServer} --returns the only one method needed to be public
end
Server:new().startServer() --start the server
