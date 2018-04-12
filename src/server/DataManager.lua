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
