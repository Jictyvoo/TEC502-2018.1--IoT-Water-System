-- load namespace
local socket = require "socket"
local NoReply = require "util.NoReply"
local sqlite3 = (require "luasql.sqlite3"):sqlite3()
local effil = require("effil")

-- channel allow to push data in one thread and pop in other
local channel = effil.channel()

local Server = {}

function Server:new()

    local self = {
        host; 
        port; 
        server; 
        databaseConnection; 
        udp_thread; 
        tcp_thread; 

        constructor = function(this)
            this.host = "192.168.43.250" 
            this.port = 3030 
            this.udp_thread = nil
            this.tcp_thread = nil
            -- create a TCP socket and bind it to the local host, at any port
            this.server = assert(socket.bind(this.host, this.port))
            this.databaseConnection = sqlite3:connect("inova_database.sqlite3")
            this.databaseConnection:execute("CREATE DATABASE IF NOT EXISTS inova_water")
            this.databaseConnection:execute("USE inova_water")
            this.databaseConnection:execute("CREATE TABLE IF NOT EXISTS Client(" .. 
                "client_id integer primary key," .. "ip_client varchar(20) not null," .. 
            "expend_goal int, client_email varchar(50));")

            this.databaseConnection:execute("CREATE TABLE IF NOT EXISTS Water_Consume(" .. 
            "water_consume_id integer primary key,water_expended int not null,last_syncronization time not null);")

            this.databaseConnection:execute("CREATE TABLE IF NOT EXISTS Client_Water(fk_client_id int not null," .. 
                "fk_water_consume_id int not null, expend_date date not null," .. 
                "FOREIGN KEY(fk_client_id) REFERENCES Client(client_id)," .. 
            "FOREIGN KEY(fk_water_consume_id) REFERENCES Water_Consume(water_consume_id));")
            this.databaseConnection:commit()
        end
    }

    self.constructor(self)

    local sendMail = function ()
        local m = NoReply:new({title = "Startup Inova", address = "<joao.victor.oliveira.couto@gmail.com>"}, 
            {title = "Client", address = "<jictyvoo.ecomp@gmail.com>"}, 
        {address = "smtp.gmail.com", user = "joao.victor.oliveira.couto@gmail.com", password = "professional@mail", port = 465})

        m.sendMessage("Meta de consumo", "Atingiu a meta de consumo estabelecida")
    end

    local main = function()
        while true do
            print("Que merda")
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
        local tcp_server = (require "server.Server_TCP"):new(socket.tcp(), self.databaseConnection) 
        --tcp_server.authenticateClient("[sensorID]<" .. "94:39:e5:f6:6c:1d" .. ">)([clientMail]<" .. "jictyvoo" .. ">\n")
        self.udp_thread = coroutine.create(udp_loop)
        self.tcp_thread = coroutine.create(main)
        while true do
            coroutine.resume(self.udp_thread)
            coroutine.resume(self.tcp_thread)
        end
    end

    return {startServer = startServer; sendMail = sendMail}
end

Server:new().startServer()
