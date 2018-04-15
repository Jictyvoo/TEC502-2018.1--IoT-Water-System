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
expend_goal real,
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
    return {
        setConnection = setConnection;
        tryCreateTables = tryCreateTables;
    }
end

function DataManager:instance()
    if(not dataManager_instance) then
        dataManager_instance = DataManager:new()
    end
    return dataManager_instance
end

return DataManager
