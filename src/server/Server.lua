-- load namespace
local socket = require "socket"
local NoReply = require "util.NoReply"
local DataManager = require "server.DataManager"
local sqlite3 = (require "luasql.sqlite3"):sqlite3()

local Server = {}

function Server:new()

    local self = {
        host; 
        port; 
        server; 
        databaseConnection; 
        udp_thread; 
        tcp_thread; 
        dataManager; 

        constructor = function(this)
            this.host = "192.168.0.109" 
            this.port = 3030 
            this.udp_thread = nil
            this.tcp_thread = nil
            -- create a TCP socket and bind it to the local host, at any port
            this.server = assert(socket.bind(this.host, this.port))
            this.databaseConnection = sqlite3:connect("inova_database.sqlite3")
            this.dataManager = DataManager:instance()
            this.dataManager.setConnection(this.databaseConnection)
            this.dataManager.tryCreateTables()
        end
    }

    self.constructor(self)

    local sendMail = function ()
        local m = NoReply:new({title = "Startup Inova", address = "<joao.victor.oliveira.couto@gmail.com>"}, 
            {title = "Client", address = "<jictyvoo.ecomp@gmail.com>"}, 
        {address = "smtp.gmail.com", user = "joao.victor.oliveira.couto@gmail.com", password = "professional981098@mail", port = 465})

        m.sendMessage("Meta de consumo", "Atingiu a meta de consumo estabelecida")
    end

    local tcp_loop = function()
        local tcp_server = (require "server.Server_TCP"):new(socket.tcp(), self.databaseConnection, self.dataManager) 
        --tcp_server.authenticateClient("[sensorID]<" .. "94:39:e5:f6:6c:1d" .. ">)([clientMail]<" .. "jictyvoo" .. ">\n")
        while true do
            print("A simple test")
            socket.sleep(0.5)
            coroutine.yield()
            --socket.sleep(2)
        end
    end

    local udp_loop = function()
        local udp_connection = (require "server.Server_UDP"):new(socket, self.host, self.port + 1, self.databaseConnection)
        udp_connection.receiveInformation()
    end

    local startServer = function()
        self.udp_thread = coroutine.create(udp_loop)
        self.tcp_thread = coroutine.create(tcp_loop)
        while true do
            coroutine.resume(self.udp_thread)
            --coroutine.resume(self.tcp_thread)
        end
    end

    return {startServer = startServer; sendMail = sendMail}
end

Server:new().startServer()
