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
local Server_UDP = {} --local table Server_UDP
function Server_UDP:new(socket, host, port, databaseConn) --function to instantiate new object
    local self = {--local table to storage private attributes
        serverConnection;
        databaseConnection;
        constructor = function(this, socket, host, port, databaseConn) --constructor to initialize private attributes
            this.serverConnection = socket.udp()
            this.serverConnection.setsockname(this.serverConnection, host, port)
            this.serverConnection:settimeout(0.001)
            this.databaseConnection = databaseConn
        end
    }
    self.constructor(self, socket, host, port, databaseConn) --call constructor
    local function insertIntoDatabase(sensorID, waterExpense, dateTime) --function to insert into database new clients and storage information
        local dbCommand = string.format("SELECT * FROM Client where Client.ip_client = '%s'", sensorID)
        local cursor = self.databaseConnection:execute(dbCommand)
        if(not cursor:fetch()) then --verify if have it client ip
            self.databaseConnection:execute(string.format("INSERT INTO Client(ip_client) VALUES('%s')", sensorID))
            self.databaseConnection:commit() --insert new client ip into database
        end
        dbCommand = [[
            SELECT Client.client_id,
            Client_Expend.water_expend_id,
            Water_Consume.water_expended,
            Water_Consume.last_syncronization
            FROM Client_Expend INNER JOIN Client on Client.client_id = Client_Expend.fk_client_id
            INNER JOIN Water_Consume on Client_Expend.water_expend_id = Water_Consume.fk_water_expend_id
            WHERE Client.ip_client = '%s' AND Client_Expend.expend_date = '%s'
        ]]
        local dateOnly = dateTime:match("%d+-%d+-%d+") --take only date string
        cursor = self.databaseConnection:execute(string.format(dbCommand, sensorID, dateOnly))
        local client_id, client_expend_id = cursor:fetch() --search table connections in database
        if(not client_id) then --if not have connections in database, create then
            cursor = self.databaseConnection:execute(string.format("SELECT Client.client_id from Client WHERE ip_client = '%s'", sensorID))
            client_id = tonumber(cursor:fetch()) --get client id for current client ip
            dbCommand = "INSERT INTO Client_Expend(fk_client_id, expend_date) VALUES(%d, '%s')"
            self.databaseConnection:execute(string.format(dbCommand, client_id, dateOnly))
            self.databaseConnection:commit() --create a new line in the database line
            
            dbCommand = [[
                SELECT Client_Expend.water_expend_id FROM Client_Expend WHERE expend_date = '%s' AND
                fk_client_id = %d
            ]]
            cursor = self.databaseConnection:execute(string.format(dbCommand, dateOnly, client_id))
            client_expend_id = cursor:fetch() --get id from created line
        end
        self.databaseConnection:execute(string.format("INSERT INTO Water_Consume(water_expended,last_syncronization,fk_water_expend_id) VALUES(%f, '%s', %d)", waterExpense, dateTime:match("%d+:%d+:%d+"), client_expend_id))
        self.databaseConnection:commit() --insert water consume into database
    end
    local function messageReceivedTreatment(message) --function to verify the meaning of message
        local sensorID = message:match("[a-zA-Z0-9,:]+")
        local beging, ending = message:find("->")
        local waterExpense = message:sub(ending + 1):match("%d%.%d+")
        if(#sensorID < 14 or (not tonumber(waterExpense))) then --if cannot utilize informations, return nil
            return nil
        end
        
        beging, ending = message:find("%[=%]:") --search datetime in message
        local dateTime = message:sub(ending + 1)
        insertIntoDatabase(sensorID, waterExpense, dateTime) --call previous function
    end
    local function receiveInformation() --main class function
        while true do --main loop for udp server
            local message = self.serverConnection:receive() --receive sensor message
            if(message) then --if have a message call previous function
                --print(message)
                messageReceivedTreatment(message)
            end
            coroutine.yield() --pause current coroutine
        end
    end
    return {--returns only public functions that can be accessed outside the class
        receiveInformation = receiveInformation;
    }
end
return Server_UDP --return Server_UDP object with new function
