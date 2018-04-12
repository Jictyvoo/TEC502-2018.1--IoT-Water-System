local Server_UDP = {}

function Server_UDP:new(socket, host, port, databaseConn)
    local self = {
        serverConnection; 
        databaseConnection; 

        constructor = function(this, socket, host, port, databaseConn)
            this.serverConnection = socket.udp()
            this.serverConnection.setsockname(this.serverConnection, host, port)
            this.serverConnection:settimeout(0.001)
            this.databaseConnection = databaseConn
        end
    }

    self.constructor(self, socket, host, port, databaseConn)

    local function insertIntoDatabase(sensorID, waterExpense, dateTime)
        local dbCommand = string.format("SELECT * FROM Client where Client.ip_client = '%s'", sensorID)
        local cursor = self.databaseConnection:execute(dbCommand)
        if(not cursor:fetch()) then
            self.databaseConnection:execute(string.format("INSERT INTO Client(ip_client) VALUES('%s')", sensorID))
            self.databaseConnection:commit()
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

        local dateOnly = dateTime:match("%d+-%d+-%d+")

        cursor = self.databaseConnection:execute(string.format(dbCommand, sensorID, dateOnly))
        local client_id, client_expend_id = cursor:fetch()
        if(not client_id) then
            cursor = self.databaseConnection:execute(string.format("SELECT Client.client_id from Client WHERE ip_client = '%s'", sensorID))
            client_id = tonumber(cursor:fetch())

            dbCommand = "INSERT INTO Client_Expend(fk_client_id, expend_date) VALUES(%d, '%s')"
            self.databaseConnection:execute(string.format(dbCommand, client_id, dateOnly))
            self.databaseConnection:commit()
            
            dbCommand = [[
                SELECT Client_Expend.water_expend_id FROM Client_Expend WHERE expend_date = '%s' AND
                fk_client_id = %d
            ]]
            cursor = self.databaseConnection:execute(string.format(dbCommand, dateOnly, client_id))
            client_expend_id = cursor:fetch()
        end
        self.databaseConnection:execute(string.format("INSERT INTO Water_Consume(water_expended,last_syncronization,fk_water_expend_id) VALUES(%f, '%s', %d)", waterExpense, dateTime:match("%d+:%d+:%d+"), client_expend_id))
        self.databaseConnection:commit() 
    end

    local function messageReceivedTreatment(message)
        local sensorID = message:match("[a-zA-Z0-9,:]+")
        local beging, ending = message:find("->")
        local waterExpense = message:sub(ending + 1):match("%d%.%d+")
        
        beging, ending = message:find("%[=%]:")
        local dateTime = message:sub(ending + 1)
        insertIntoDatabase(sensorID, waterExpense, dateTime)
    end

    local function receiveInformation()
        while true do
            local message = self.serverConnection:receive()
            if(message) then
                messageReceivedTreatment(message)
            end
            coroutine.yield()
        end
    end

    return {
        receiveInformation = receiveInformation; 
    }

end

return Server_UDP
