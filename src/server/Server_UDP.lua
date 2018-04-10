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
        local searchDB = string.format("SELECT * FROM Client where Client.ip_client = '%s'", sensorID)
        local cursor = self.databaseConnection:execute(searchDB)
        if(not cursor:fetch()) then
            self.databaseConnection:execute(string.format("INSERT INTO Client(ip_client) VALUES('%s')", sensorID))
            self.databaseConnection:commit()
        end

        searchDB = string.format("SELECT Client_Water.expend_date, Client_Water.fk_water_consume_id, Water_Consume.last_syncronization FROM Client_Water INNER JOIN Client on Client.client_id = Client_Water.fk_client_id INNER JOIN Water_Consume on Client_Water.fk_water_consume_id = Water_Consume.water_consume_id WHERE Client.ip_client = '%s'", sensorID)
        cursor = self.databaseConnection:execute(searchDB)
        if(not cursor:fetch()) then
            cursor = self.databaseConnection:execute(string.format("SELECT Client.client_id from Client WHERE ip_client = '%s'", sensorID))
            local client_id = tonumber(cursor:fetch())
            self.databaseConnection:execute(string.format("INSERT INTO Water_Consume(water_expended,last_syncronization) VALUES(0, '%s')", dateTime:match("%d+:%d+:%d+")))
            self.databaseConnection:commit()
            cursor = self.databaseConnection:execute(string.format("SELECT Water_Consume.water_consume_id from Water_Consume WHERE water_expended = 0 and last_syncronization = '%s'", dateTime:match("%d+:%d+:%d+")))
            local waterConsume_id = tonumber(cursor:fetch())

            self.databaseConnection:execute(string.format("INSERT INTO Client_Water(fk_client_id, fk_water_consume_id, expend_date) VALUES('%d', '%d', '%s')", client_id, waterConsume_id, os.date("%Y-%m-%d")))
            self.databaseConnection:commit()
        end
    end

    local function messageReceivedTreatment(message)
        local sensorID = message:match("[a-zA-Z0-9,:]+")
        local beging, ending = message:find("->")
        local waterExpense = message:sub(ending + 1):match("%d+")

        beging, ending = message:find("%[=%]:")
        local dateTime = message:sub(ending + 1)
        insertIntoDatabase(sensorID, waterExpense, dateTime)
    end

    local function receiveInformation()
        while true do
            local message = self.serverConnection:receive()
            if(message) then
                messageReceivedTreatment(message)
                print(message)
            end
            coroutine.yield()
        end
    end

    return {
        receiveInformation = receiveInformation; 
    }

end

return Server_UDP
