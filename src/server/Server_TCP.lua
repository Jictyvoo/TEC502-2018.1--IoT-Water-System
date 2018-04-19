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
local Server_TCP = {} --create a local table that have new function to instantiate a new object
function Server_TCP:new(serverConn, databaseConn, clientMailList) --function to instantiate a new object
    local self = {--table with private attributes
        clientConnection;
        databaseConnection;
        clientId;
        thread; --thread table with all client coroutines
        clientMailList; --table with all clients mail

        constructor = function(this, serverConn, databaseConn, clientMailList) --constructor to initialize self atributtes
            this.clientConnection = serverConn
            this.databaseConnection = databaseConn
            this.clientId = nil
            this.thread = nil
            this.clientMailList = clientMailList
        end
    }

    self.constructor(self, serverConn, databaseConn, clientMailList)

    local function authenticateClient(message) --function that veify if client can connect into server
        if(message) then --only execute if have a message
            local beginig, ending = message:find("%[sensorID%]<") --search sensorID tag
            local sensorID = message:sub(ending):match("[a-zA-Z0-9,:]+") --get sensorID
            cursor = self.databaseConnection:execute(string.format("SELECT Client.client_id, Client.client_email from Client WHERE ip_client = '%s'", sensorID))
            local client_id, client_email = cursor:fetch() --search that ID in database
            if(not client_id or not ending) then --if nor find id or message tag, return false
                self.clientId = nil
                return false
            end
            self.clientId = client_id --set clientId attribute
            beginig, ending = message:find("%[clientMail%]<") --search clientMail tag
            client_email = message:sub(ending + 1, #message - 1) --stores clientMail
            if(self.clientMailList[sensorID] ~= client_email) then --verify if it is not same stored email
                print("Update email")
                self.clientMailList[sensorID] = client_email --update email stored
                self.databaseConnection:execute(string.format("UPDATE Client SET client_email = '%s' WHERE ip_client = '%s'", client_email, sensorID))
            end
            return true --if success authenticated return true
        end
        return false --if doesn't receive a message, return false
    end

    local function establishGoal(message) --function to establish a new goal
        local goalString = message:gsub("%[goal%]:=", "") --search goal tag in message
        self.databaseConnection:execute(string.format("UPDATE Client SET expend_goal = %d, goal_update = 1 WHERE client_id = %d", tonumber(goalString), self.clientId))
        self.databaseConnection:commit() --update goal in database
    end

    local function totalConsume() --take total consume of client in database
        local consultCommand = [[
        SELECT SUM(Water_Consume.water_expended), Client.expend_goal
        FROM Client INNER JOIN Client_Expend ON Client.client_id = Client_Expend.fk_client_id INNER JOIN 
        Water_Consume ON Water_Consume.fk_water_expend_id = Client_Expend.water_expend_id WHERE Client.client_id = '%d'
        ]]
        return self.databaseConnection:execute(string.format(consultCommand, self.clientId)):fetch()
    end

    local function requireWater() --search in database all water consume have and sends it
        local waterTable = {}
        local consultCommand = [[
        SELECT Water_Consume.water_expended, Water_Consume.last_syncronization, Client_Expend.expend_date
        FROM Client INNER JOIN Client_Expend ON Client.client_id = Client_Expend.fk_client_id INNER JOIN 
        Water_Consume ON Water_Consume.fk_water_expend_id = Client_Expend.water_expend_id WHERE Client.client_id = %d
        ]]
        local cursor = self.databaseConnection:execute(string.format(consultCommand, self.clientId))
        while cursor:fetch(waterTable, "n") do --search row by row and sends it to client
            self.clientConnection:send(string.format("[waterConsume]<%f>)([dateTime]<%s %s>\n", tonumber(waterTable[1]), waterTable[3], waterTable[2]))
        end
    end

    local function detectFunction(message) --receive first message from client and analyze who function to call
        if(message) then --if receive a message, execute, else abort
            local callFunction = message:match("%[.+%]"):gsub("%[", ""):gsub("%]", "") --search function to call
            coroutine.yield() --pause current coroutine
            if(callFunction == "goal") then
                establishGoal(message) --call requested function
            elseif(callFunction == "requireWater") then
                local totalExpend, clientGoal = totalConsume() --call totalConsume before requested function
                self.clientConnection:send(string.format("[totalWater]:=%f)([expendGoal]:=%f\n", totalExpend, clientGoal))
                requireWater()
            end
        end
    end

    local function mainExecution() --main function to execute others functions with connection
        local message = self.clientConnection:receive() --receive the message
        detectFunction(message)
        self.clientConnection:close()
        self.thread[self.clientId] = nil --when function over, remove it thread from table
    end

    local function tableThread()
        self.thread[self.clientId] = coroutine.create(mainExecution) --create client thread and put it in client thread table
    end

    local function start() --first called function thats start connection
        self.clientConnection:settimeout(0.01) --set the client timeout
        if(authenticateClient(self.clientConnection:receive())) then --verify if can authenticate client
            local ok, err = self.clientConnection:send("$YESAUT\n")
            --print(ok, err)
            tableThread() --create the thread if client passed
        else
            local ok, err = self.clientConnection:send("$NOTAUT\n") --send false to client and ends execution
            --print(ok, err)
        end
    end

    local function setThreadTable(thread)
        self.thread = thread --set client thread
    end

    return {--returns public methods
        start = start;
        setThreadTable = setThreadTable;
    }
end
return Server_TCP --return Server_TCP object to instantiate new class objects
