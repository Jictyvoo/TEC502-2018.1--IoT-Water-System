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
        connectedClients;
        constructor = function(this)
            this.host = "192.168.0.109"
            this.port = 3030
            this.udp_thread = nil
            this.tcp_thread = nil
            -- create a TCP socket and bind it to the local host, at any port
            this.server = socket.tcp()
            this.server:bind(this.host, this.port)
            this.server:listen(1000)
            this.server:settimeout(0.001)
            this.connectedClients = {}
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
    local verifyGoal_loop = function()
        local dbCommand = [[
            SELECT * FROM 
        ]]
        self.databaseConnection:execute(dbCommand)
    end
    local executeClient = function()
        while true do
            for index, value in pairs(self.connectedClients) do
                coroutine.resume(value)
                --print(coroutine.status(value))
                coroutine.yield()
            end
            coroutine.yield()
        end
    end
    local tcp_loop = function()
        local client = nil
        while true do
            client = self.server:accept()
            if(client) then
                local peername = client:getpeername()
                print(string.format("Client Connected in IP:%s", peername))
                local tcp_server = (require "server.Server_TCP"):new(client, self.databaseConnection, self.dataManager)
                tcp_server.setThreadTable(self.connectedClients)
                tcp_server.start()
            end
            coroutine.yield()
        end
    end
    local udp_loop = function()
        local udp_connection = (require "server.Server_UDP"):new(socket, self.host, self.port + 1, self.databaseConnection)
        udp_connection.receiveInformation()
    end
    local startServer = function()
        self.udp_thread = coroutine.create(udp_loop)
        self.tcp_thread = coroutine.create(tcp_loop)
        local clients = coroutine.create(executeClient)
        while true do
            coroutine.resume(self.udp_thread)
            coroutine.resume(self.tcp_thread)
            coroutine.resume(clients)
            --print(coroutine.status(self.tcp_thread))
        end
    end
    return {startServer = startServer; sendMail = sendMail}
end
Server:new().startServer()
