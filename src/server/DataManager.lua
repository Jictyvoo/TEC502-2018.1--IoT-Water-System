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
local DataManager = {} --create a local table to storage instatiation functions
local dataManager_instance = nil --local variable to storage the current class instance
function DataManager:new(databaseConn) --function to create a new instance of DataManager

    local self = {--local table to storage private attributes
        connection; --attribute to storage database connection

        constructor = function(this, databaseConn) --constructor function that initialize attributes
            this.connection = databaseConn
        end
    }

    self.constructor(self, databaseConn) --call constructor

    local function setConnection(databaseConnection)
        self.connection = databaseConnection
    end

    local function tryCreateTables(databaseConnection) --function that create all needed tables if not exist
        self.connection = databaseConnection or self.connection
        if (not self.connection) then --if not have a connection abort
            return false
        end

        --sql scripts for execute
        self.connection:execute("CREATE DATABASE IF NOT EXISTS inova_water")
        self.connection:execute("USE inova_water")

        local client_table = [[
            CREATE TABLE IF NOT EXISTS Client(
                client_id integer primary key,
                ip_client varchar(20) not null,
                zone char(2),
                expend_goal real,
                goal_update int(1),
                client_email varchar(50)
            )
         ]]
        self.connection:execute(client_table)

        local water_expend_table = [[
            CREATE TABLE IF NOT EXISTS Client_Expend(
                water_expend_id integer primary key,
                fk_client_id int not null,
                expend_date date not null,
                FOREIGN KEY(fk_client_id) REFERENCES Client(client_id)
            )
        ]]
        self.connection:execute(water_expend_table)

        local water_consume_table = [[
            CREATE TABLE IF NOT EXISTS Water_Consume(
                water_consume_id integer primary key,
                water_expended real not null,
                last_syncronization time not null,
                fk_water_expend_id int not null,
                FOREIGN KEY(fk_water_expend_id) REFERENCES Client_Expend(water_expend_id)
            )
        ]]

        self.connection:execute(water_consume_table)
        self.connection:commit()

        return true
    end

    local function verifyGoal() --function that verify if somebody reached the goal established
        local tableSearch = {} --table to stores search informations
        local dbCommand_1 = [[
            SELECT SUM(Water_Consume.water_expended), Client.client_id
            FROM Client INNER JOIN Client_Expend ON Client.client_id = Client_Expend.fk_client_id INNER JOIN 
            Water_Consume ON Water_Consume.fk_water_expend_id = Client_Expend.water_expend_id
            WHERE Client.goal_update = 1
        ]]
        local dbCommand_2 = [[
            SELECT client_email FROM Client INNER JOIN Client_Expend ON Client.client_id = Client_Expend.fk_client_id
            INNER JOIN Water_Consume ON Water_Consume.fk_water_expend_id = Client_Expend.water_expend_id
            WHERE Client.expend_goal < %f AND Client.client_id = %d
        ]]
        local cursor = self.connection:execute(dbCommand_1) --cursor for first search
        while(cursor:fetch(tableSearch, "n")) do --loop to verify if reached goal or not
            coroutine.yield() --pause actual coroutine
            if(tableSearch[1]) then --if found something
                local mailSend = self.connection:execute(string.format(dbCommand_2, tableSearch[1], tableSearch[2]))
                if(mailSend) then --if found a mail to send goal, execute it
                    local client_email = mailSend:fetch() --get the client mail
                    local dbCommand_3 = "UPDATE Client SET goal_update = 0 WHERE client_id = %d"
                    coroutine.yield() --pause coroutine
                    coroutine.yield(client_email) --pause coroutine and returns founded mail
                    self.connection:execute(string.format(dbCommand_3, tableSearch[2])) --remove mail from list
                    self.connection:commit()
                end
            end
        end
    end

    return {--returns methods that can be accessed externaly
        setConnection = setConnection;
        tryCreateTables = tryCreateTables;
        verifyGoal = verifyGoal;
    }
end

function DataManager:instance() --function to get the class instance
    if(not dataManager_instance) then --if functions first call instantiate a new object
        dataManager_instance = DataManager:new()
    end
    return dataManager_instance --return current instance
end

return DataManager --return DataManager object table
