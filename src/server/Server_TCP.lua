local Server_TCP = {}

function Server_TCP:new(serverConn, databaseConn)

    local self = {
        serverConnection; 
        databaseConnection; 

        constructor = function(this, serverConn, databaseConn)
            this.serverConnection = serverConn
            this.databaseConnection = databaseConn
        end
    }

    self.constructor(self, serverConn, databaseConn)

    local function authenticateClient(message)
        local beginig, ending = message:find("%[sensorID%]<")
        local sensorID = message:sub(ending):match("[a-zA-Z0-9,:]+")
        cursor = self.databaseConnection:execute(string.format("SELECT Client.client_id, Client.client_email from Client WHERE ip_client = '%s'", sensorID))
        local client_id, client_email = cursor:fetch()
        if(not client_id) then
            return false
        end
        beginig, ending = message:find("%[clientMail%]<")
        client_email = message:sub(ending + 1, #message - 2)
        self.databaseConnection:execute(string.format("UPDATE Client SET client_email = '%s' WHERE ip_client = '%s'", client_email, sensorID)) 
        
        return true
    end

    local function establishGoal(message)
        -- body
    end

    --[[local function mainLoop()
        while true do
            local client = self.server:accept()
            local clientIp = client:getpeername()
            if client:receive() == "pass" then
                client:send("$AUT\n")
                while true do
                    -- receive the line
                    local line, err = client:receive()
                    print(line)
                end
            else
                -- done with client, close the object
                client:close()
            end
        end
    end--]]

    return {authenticateClient = authenticateClient}

end

return Server_TCP
