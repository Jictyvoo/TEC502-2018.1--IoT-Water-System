local Server_TCP = {}

function Server_TCP:new(serverConn, databaseConn)

    local self = {
        serverConnection; 
        databaseConnection; 
        clientId; 

        constructor = function(this, serverConn, databaseConn)
            this.serverConnection = serverConn
            this.databaseConnection = databaseConn
            this.clientId = nil
        end
    }

    self.constructor(self, serverConn, databaseConn)

    local function authenticateClient(message)
        local beginig, ending = message:find("%[sensorID%]<")
        local sensorID = message:sub(ending):match("[a-zA-Z0-9,:]+")
        cursor = self.databaseConnection:execute(string.format("SELECT Client.client_id, Client.client_email from Client WHERE ip_client = '%s'", sensorID))
        local client_id, client_email = cursor:fetch()
        if(not client_id) then
            self.clientId = nil
            return false
        end
        self.clientId = client_id
        beginig, ending = message:find("%[clientMail%]<")
        client_email = message:sub(ending + 1, #message - 2)
        self.databaseConnection:execute(string.format("UPDATE Client SET client_email = '%s' WHERE ip_client = '%s'", client_email, sensorID)) 
        
        return true
    end

    local function establishGoal(message)
        local goalString = message:gsub("%[goal%]:=", "")
        self.databaseConnection:execute(string.format("UPDATE Client SET expend_goal = '%d' WHERE client_id = '%d'", tonumber(goalString), self.clientId))
        self.databaseConnection:commit()
    end

    local function totalConsume()
        local consultCommand = [[
        SELECT SUM(Water_Consume.water_expended)
        FROM Client INNER JOIN Client_Water ON Client.client_id = Client_Water.fk_client_id INNER JOIN 
        Water_Consume ON Water_Consume.water_consume_id = Client_Water.fk_water_consume_id WHERE Client.client_id = '
        ]]
        return self.databaseConnection:execute(consultCommand .. self.clientId .. "'"):fetch()
    end

    local function requireWater()
        local waterTable = {}
        local consultCommand = [[
        SELECT Water_Consume.water_expended, Water_Consume.last_syncronization, Client_Water.expend_date
        FROM Client INNER JOIN Client_Water ON Client.client_id = Client_Water.fk_client_id INNER JOIN 
        Water_Consume ON Water_Consume.water_consume_id = Client_Water.fk_water_consume_id WHERE Client.client_id = '
        ]]
        local cursor = self.databaseConnection:execute(consultCommand .. self.clientId .. "'")
        cursor:fetch(waterTable, "n")
        self.serverConnection:send(string.format("[waterConsume]<%d>)([dateTime]<%s %s>", tonumber(waterTable[1]), waterTable[3], waterTable[2]))
    end

    local function detectFunction(message)
        local callFunction = message:match("%[.+%]"):gsub("%[", ""):gsub("%]", "")
        if(callFunction == "goal") then
            establishGoal(message)
        elseif(callFunction == "requireWater") then
            self.serverConnection:send(string.format("[totalWater]:=%d", totalConsume()))
            requireWater()
        end
    end

    local function mainExecution()
        if(authenticateClient(self.serverConnection:receive())) then
            detectFunction(self.serverConnection:receive())
        end
    end

    return {
        mainExecution = mainExecution; 
    }

end

return Server_TCP
