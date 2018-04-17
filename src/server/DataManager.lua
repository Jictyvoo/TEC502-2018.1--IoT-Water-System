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
local DataManager = {}
local dataManager_instance = nil
function DataManager:new(databaseConn)

    local self = {
        connection;

        constructor = function(this, databaseConn)
            this.connection = databaseConn
        end
    }

    self.constructor(self, databaseConn)

    local function setConnection(databaseConnection)
        self.connection = databaseConnection
    end

    local function tryCreateTables(databaseConnection)
        self.connection = databaseConnection or self.connection
        if (not self.connection) then
            return false
        end

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

    local function verifyGoal()
        local tableSearch = {}
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
        local cursor = self.connection:execute(dbCommand_1)
        while(cursor:fetch(tableSearch, "n")) do
            coroutine.yield()
            if(tableSearch[1]) then
                local mailSend = self.connection:execute(string.format(dbCommand_2, tableSearch[1], tableSearch[2]))
                if(mailSend) then
                    local client_email = mailSend:fetch()
                    local dbCommand_3 = "UPDATE Client SET goal_update = 0 WHERE client_id = %d"
                    coroutine.yield()
                    coroutine.yield(client_email)
                    self.connection:execute(string.format(dbCommand_3, tableSearch[2]))
                    self.connection:commit()
                end
            end
        end
    end

    return {
        setConnection = setConnection;
        tryCreateTables = tryCreateTables;
        verifyGoal = verifyGoal;
    }
end

function DataManager:instance()
    if(not dataManager_instance) then
        dataManager_instance = DataManager:new()
    end
    return dataManager_instance
end

return DataManager
