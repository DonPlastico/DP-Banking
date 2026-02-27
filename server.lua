local QBCore = exports['qb-core']:GetCoreObject()
local Accounts = {}
local Statements = {}

RegisterNetEvent('DP-Banking:server:cancelAllCards', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end

    -- Eliminar todas las tarjetas bancarias del jugador
    while Player.Functions.GetItemByName('bank_card') do
        Player.Functions.RemoveItem('bank_card', 1)
    end

    -- Registrar en el log
    TriggerEvent('qb-log:server:CreateLog', 'banking', 'Tarjetas Canceladas', 'red',
        string.format('**%s** ha cancelado todas sus tarjetas bancarias', GetPlayerName(src)))
end)

-- Functions

local function getPlayerAndCitizenId(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then
        return nil, nil
    end
    return Player, Player.PlayerData.citizenid
end

local function GetNumberOfAccounts(citizenid)
    local numberOfAccounts = 0
    for _, account in pairs(Accounts) do
        if account.citizenid == citizenid then
            numberOfAccounts = numberOfAccounts + 1
        end
    end
    return numberOfAccounts
end

-- Exported Functions

local function CreatePlayerAccount(playerId, accountName, accountBalance, accountUsers)
    local Player, citizenid = getPlayerAndCitizenId(playerId)
    if not Player or not citizenid then
        return false
    end

    if Accounts[accountName] then
        return false
    end

    Accounts[accountName] = {
        citizenid = citizenid,
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'shared',
        users = accountUsers
    }

    local insertSuccess = MySQL.insert.await(
        'INSERT INTO bank_accounts (citizenid, account_name, account_balance, account_type, users) VALUES (?, ?, ?, ?, ?)',
        {citizenid, accountName, accountBalance, 'shared', accountUsers})
    return insertSuccess
end
exports('CreatePlayerAccount', CreatePlayerAccount)

local function CreateJobAccount(accountName, accountBalance)
    Accounts[accountName] = {
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'job'
    }
    local insertSuccess = MySQL.insert.await(
        'INSERT INTO bank_accounts (account_name, account_balance, account_type) VALUES (?, ?, ?)',
        {accountName, accountBalance, 'job'})
    return insertSuccess
end
exports('CreateJobAccount', CreateJobAccount)

local function CreateGangAccount(accountName, accountBalance)
    Accounts[accountName] = {
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'gang'
    }
    local insertSuccess = MySQL.insert.await(
        'INSERT INTO bank_accounts (account_name, account_balance, account_type) VALUES (?, ?, ?)',
        {accountName, accountBalance, 'gang'})
    return insertSuccess
end
exports('CreateGangAccount', CreateGangAccount)

local function CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    local Player, citizenid = getPlayerAndCitizenId(playerId)
    if not Player or not citizenid then
        return false
    end

    local newStatement = {
        citizenid = citizenid,
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = statementType
    }
    if accountType == 'player' or accountType == 'shared' then
        if accountType == 'player' then
            account = 'Personal'
        end
        if not Statements[citizenid] then
            Statements[citizenid] = {}
        end
        if not Statements[citizenid][account] then
            Statements[citizenid][account] = {}
        end
        Statements[citizenid][account][#Statements[citizenid][account] + 1] = newStatement
    else
        if not Statements[account] then
            Statements[account] = {}
        end
        Statements[account][#Statements[account] + 1] = newStatement
    end

    local insertSuccess = MySQL.insert.await(
        'INSERT INTO bank_statements (citizenid, account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?, ?)',
        {citizenid, account, amount, reason, statementType})
    if not insertSuccess then
        return false
    end
    return true
end
exports('CreateBankStatement', CreateBankStatement)

local function AddMoney(accountName, amount, reason)
    if not reason then
        reason = 'External Deposit'
    end
    local newStatement = {
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = 'deposit'
    }
    if Accounts[accountName] then
        local accountToUpdate = Accounts[accountName]
        accountToUpdate.account_balance = accountToUpdate.account_balance + amount
        if not Statements[accountName] then
            Statements[accountName] = {}
        end
        Statements[accountName][#Statements[accountName] + 1] = newStatement
        MySQL.insert.await(
            'INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)',
            {accountName, amount, reason, 'deposit'})
        local updateSuccess = MySQL.update.await(
            'UPDATE bank_accounts SET account_balance = account_balance + ? WHERE account_name = ?',
            {amount, accountName})
        return updateSuccess
    end
    return false
end
exports('AddMoney', AddMoney)
exports('AddGangMoney', AddMoney)

local function RemoveMoney(accountName, amount, reason)
    if not reason then
        reason = 'External Withdrawal'
    end
    local newStatement = {
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = 'withdraw'
    }
    if Accounts[accountName] then
        local accountToUpdate = Accounts[accountName]
        accountToUpdate.account_balance = accountToUpdate.account_balance - amount
        if not Statements[accountName] then
            Statements[accountName] = {}
        end
        Statements[accountName][#Statements[accountName] + 1] = newStatement
        MySQL.insert.await(
            'INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)',
            {accountName, amount, reason, 'withdraw'})
        local updateSuccess = MySQL.update.await(
            'UPDATE bank_accounts SET account_balance = account_balance - ? WHERE account_name = ?',
            {amount, accountName})
        return updateSuccess
    end
    return false
end
exports('RemoveMoney', RemoveMoney)
exports('RemoveGangMoney', RemoveMoney)

local function GetAccount(accountName)
    if Accounts[accountName] then
        return Accounts[accountName]
    end
    return nil
end
exports('GetAccount', GetAccount)
exports('GetGangAccount', GetAccount)

local function GetAccountBalance(accountName)
    local account = GetAccount(accountName)
    return account and account.account_balance or 0
end
exports('GetAccountBalance', GetAccountBalance)

-- Callbacks

QBCore.Functions.CreateCallback('DP-Banking:server:getUserInfo', function(source, cb, data)
    local citizenid = data.citizenid
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if not Player then
        -- Buscar en la base de datos si el jugador no está en línea
        local result = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
        if result and result.charinfo then
            local charinfo = json.decode(result.charinfo)
            cb({
                name = charinfo.firstname .. ' ' .. charinfo.lastname,
                citizenid = citizenid
            })
            return
        end
    end

    if Player then
        cb({
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            citizenid = citizenid
        })
        return
    end

    cb({
        name = "Usuario no encontrado",
        citizenid = citizenid
    })
end)

QBCore.Functions.CreateCallback('DP-Banking:server:openBank', function(source, cb)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return
    end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local accounts = {}
    local statements = {}
    if job.name ~= 'unemployed' and not Accounts[job.name] then
        CreateJobAccount(job.name, 0)
    end
    if gang.name ~= 'none' and not Accounts[gang.name] then
        CreateGangAccount(gang.name, 0)
    end
    accounts[#accounts + 1] = {
        account_name = 'Personal',
        account_type = 'Personal',
        account_balance = Player.PlayerData.money.bank
    }
    statements['Personal'] = Statements[citizenid] and Statements[citizenid]['Personal'] or {}
    for accountName, accountInfo in pairs(Accounts) do
        if accountInfo.citizenid == citizenid then
            accounts[#accounts + 1] = accountInfo
            if Statements[accountName] then
                statements[accountName] = Statements[accountName]
            end
        end
        if accountInfo.users and string.find(accountInfo.users, citizenid) then
            accounts[#accounts + 1] = accountInfo
            if Statements[accountName] then
                statements[accountName] = Statements[accountName]
            end
        end
        if (accountName == job.name and job.isboss) or (accountName == gang.name and gang.isboss) then
            accounts[#accounts + 1] = accountInfo
            if Statements[accountName] then
                statements[accountName] = Statements[accountName]
            end
        end
    end
    cb(accounts, statements, Player.PlayerData)
end)

QBCore.Functions.CreateCallback('DP-Banking:server:openATM', function(source, cb)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return
    end
    local bankCards = Player.Functions.GetItemsByName('bank_card')
    if not bankCards then
        return QBCore.Functions.Notify(src, Lang:t('error.card'), 'error', 5000)
    end
    local acceptablePins = {}
    for _, bankCard in ipairs(bankCards) do
        acceptablePins[#acceptablePins + 1] = bankCard.info.cardPin
    end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local accounts = {}
    accounts[#accounts + 1] = {
        account_name = 'Personal',
        account_type = 'Personal',
        account_balance = Player.PlayerData.money.bank
    }
    for accountName, accountInfo in pairs(Accounts) do
        if accountInfo.citizenid == citizenid then
            accounts[#accounts + 1] = accountInfo
        end
        if accountInfo.users and string.find(accountInfo.users, citizenid) then
            accounts[#accounts + 1] = accountInfo
        end
        if (accountName == job.name and job.isboss) or (accountName == gang.name and gang.isboss) then
            accounts[#accounts + 1] = accountInfo
        end
    end
    cb(accounts, Player.PlayerData, acceptablePins)
end)

QBCore.Functions.CreateCallback('DP-Banking:server:withdraw', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local accountName = data.accountName
    local withdrawAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'Bank Withdrawal'
    if accountName == 'Personal' then
        local accountBalance = Player.PlayerData.money.bank
        if accountBalance < withdrawAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        Player.Functions.RemoveMoney('bank', withdrawAmount, 'bank withdrawal')
        Player.Functions.AddMoney('cash', withdrawAmount, 'bank withdrawal')
        if not CreateBankStatement(src, 'Personal', withdrawAmount, reason, 'withdraw', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.withdraw')
        })
    end
    if Accounts[accountName] then
        local job = Player.PlayerData.job
        local gang = Player.PlayerData.gang
        if Accounts[accountName].account_type == 'job' and job.name ~= accountName and not job.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        if Accounts[accountName].account_type == 'gang' and gang.name ~= accountName and not gang.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        local accountBalance = GetAccountBalance(accountName)
        if accountBalance < withdrawAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        if not RemoveMoney(accountName, withdrawAmount) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        Player.Functions.AddMoney('cash', withdrawAmount, 'bank account: ' .. accountName .. ' withdrawal')
        if not CreateBankStatement(src, accountName, withdrawAmount, reason, 'withdraw',
            Accounts[accountName].account_type) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.withdraw')
        })
    end
end)

QBCore.Functions.CreateCallback('DP-Banking:server:deposit', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local accountName = data.accountName
    local depositAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'Bank Deposit'
    if accountName == 'Personal' then
        local accountBalance = Player.PlayerData.money.cash
        if accountBalance < depositAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        Player.Functions.RemoveMoney('cash', depositAmount, 'bank deposit')
        Player.Functions.AddMoney('bank', depositAmount, 'bank deposit')
        if not CreateBankStatement(src, 'Personal', depositAmount, reason, 'deposit', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.deposit')
        })
    end
    if Accounts[accountName] then
        local job = Player.PlayerData.job
        local gang = Player.PlayerData.gang
        if Accounts[accountName].account_type == 'job' and job.name ~= accountName and not job.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        if Accounts[accountName].account_type == 'gang' and gang.name ~= accountName and not gang.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        if Player.PlayerData.money.cash < depositAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        Player.Functions.RemoveMoney('cash', depositAmount, 'bank account: ' .. accountName .. ' deposit')
        if not AddMoney(accountName, depositAmount) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.deposit')
        })
    end
end)

QBCore.Functions.CreateCallback('DP-Banking:server:internalTransfer', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local fromAccountName = data.fromAccountName
    local toAccountName = data.toAccountName
    local transferAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'Internal transfer'
    if fromAccountName == 'Personal' then
        if Player.PlayerData.money.bank < transferAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        Player.Functions.RemoveMoney('bank', transferAmount, reason)
        if toAccountName == 'Personal' then
            Player.Functions.AddMoney('bank', transferAmount, reason)
        else
            if not AddMoney(toAccountName, transferAmount) then
                return cb({
                    success = false,
                    message = Lang:t('error.error')
                })
            end
        end
        if not CreateBankStatement(src, 'Personal', transferAmount, reason, 'withdraw', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.transfer')
        })
    elseif toAccountName == 'Personal' then
        if Accounts[fromAccountName].account_type == 'job' and job.name ~= fromAccountName and not job.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        if Accounts[fromAccountName].account_type == 'gang' and gang.name ~= fromAccountName and not gang.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        local fromAccountBalance = GetAccountBalance(fromAccountName)
        if fromAccountBalance < transferAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        if not RemoveMoney(fromAccountName, transferAmount) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        Player.Functions.AddMoney('bank', transferAmount, reason)
        if not CreateBankStatement(src, 'Personal', transferAmount, reason, 'deposit', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.transfer')
        })
    else
        if Accounts[fromAccountName].account_type == 'job' and job.name ~= fromAccountName and not job.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        if Accounts[fromAccountName].account_type == 'gang' and gang.name ~= fromAccountName and not gang.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        local fromAccountBalance = GetAccountBalance(fromAccountName)
        if fromAccountBalance < transferAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        if not RemoveMoney(fromAccountName, transferAmount) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        if not AddMoney(toAccountName, transferAmount) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.transfer')
        })
    end
end)

QBCore.Functions.CreateCallback('DP-Banking:server:externalTransfer', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local toAccountName = data.toAccountNumber
    local toPlayer = QBCore.Functions.GetPlayerByCitizenId(toAccountName)
    if not toPlayer then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local fromAccountName = data.fromAccountName
    local transferAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'External transfer'
    if fromAccountName == 'Personal' then
        if Player.PlayerData.money.bank < transferAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        Player.Functions.RemoveMoney('bank', transferAmount, reason)
        toPlayer.Functions.AddMoney('bank', transferAmount, reason)
        if not CreateBankStatement(src, 'Personal', transferAmount, reason, 'withdraw', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        if not CreateBankStatement(toPlayer.PlayerData.source, 'Personal', transferAmount, reason, 'deposit', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.transfer')
        })
    else
        if Accounts[fromAccountName].account_type == 'job' and job.name ~= fromAccountName and not job.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        if Accounts[fromAccountName].account_type == 'gang' and gang.name ~= fromAccountName and not gang.isboss then
            return cb({
                success = false,
                message = Lang:t('error.access')
            })
        end
        local fromAccountBalance = GetAccountBalance(fromAccountName)
        if fromAccountBalance < transferAmount then
            return cb({
                success = false,
                message = Lang:t('error.money')
            })
        end
        if not RemoveMoney(fromAccountName, transferAmount) then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        toPlayer.Functions.AddMoney('bank', transferAmount, reason)
        if not CreateBankStatement(toPlayer.PlayerData.source, 'Personal', transferAmount, reason, 'deposit', 'player') then
            return cb({
                success = false,
                message = Lang:t('error.error')
            })
        end
        cb({
            success = true,
            message = Lang:t('success.transfer')
        })
    end
end)

QBCore.Functions.CreateCallback('DP-Banking:server:orderCard', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = "Jugador no encontrado"
        })
    end

    local pinNumber = tonumber(data.pin)
    if not pinNumber or string.len(tostring(pinNumber)) ~= 4 then
        return cb({
            success = false,
            message = "PIN inválido. Debe tener 4 dígitos"
        })
    end

    local cardNumber = math.random(1000000000000000, 9999999999999999)
    local info = {
        citizenid = citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        cardNumber = cardNumber,
        cardPin = pinNumber
    }

    exports['qb-inventory']:AddItem(src, 'bank_card', 1, false, info)

    TriggerEvent('qb-log:server:CreateLog', 'banking', 'Tarjeta Ordenada', 'green',
        string.format('**%s** ordenó una nueva tarjeta bancaria', GetPlayerName(src)))

    cb({
        success = true,
        message = "Tarjeta de débito ordenada correctamente"
    })
end)

QBCore.Functions.CreateCallback('DP-Banking:server:openAccount', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local accountName = data.accountName
    local initialAmount = tonumber(data.amount)
    if GetNumberOfAccounts(citizenid) >= Config.maxAccounts then
        return cb({
            success = false,
            message = Lang:t('error.accounts')
        })
    end
    if Player.PlayerData.money.bank < initialAmount then
        return cb({
            success = false,
            message = Lang:t('error.money')
        })
    end
    Player.Functions.RemoveMoney('bank', initialAmount, 'Opened account ' .. accountName)
    if not CreatePlayerAccount(src, accountName, initialAmount, json.encode({})) then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    if not CreateBankStatement(src, accountName, initialAmount, 'Initial deposit', 'deposit', 'shared') then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    if not CreateBankStatement(src, 'Personal', initialAmount, 'Initial deposit for ' .. accountName, 'withdraw',
        'player') then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    TriggerEvent('qb-log:server:CreateLog', 'banking', 'Account Opened', 'green',
        string.format('**%s** opened account **%s** with an initial deposit of **$%s**', GetPlayerName(src),
            accountName, initialAmount))
    cb({
        success = true,
        message = Lang:t('success.account')
    })
end)

QBCore.Functions.CreateCallback('DP-Banking:server:renameAccount', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end

    local oldName = data.oldName
    local newName = data.newName

    -- Verificar si el nuevo nombre ya existe
    local existingAccount = MySQL.scalar.await('SELECT account_name FROM bank_accounts WHERE account_name = ?',
        {newName})
    if existingAccount then
        return cb({
            success = false,
            message = 'Ya existe una cuenta con ese nombre'
        })
    end

    if not Accounts[oldName] then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end

    if Accounts[oldName].citizenid ~= citizenid then
        return cb({
            success = false,
            message = Lang:t('error.access')
        })
    end

    local result = MySQL.update.await(
        'UPDATE bank_accounts SET account_name = ? WHERE account_name = ? AND citizenid = ?',
        {newName, oldName, citizenid})

    if not result then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end

    -- Actualizar localmente
    Accounts[newName] = Accounts[oldName]
    Accounts[newName].account_name = newName
    Accounts[oldName] = nil

    TriggerEvent('qb-log:server:CreateLog', 'banking', 'Account Renamed', 'red',
        string.format('**%s** renamed **%s** to **%s**', GetPlayerName(src), oldName, newName))

    cb({
        success = true,
        message = Lang:t('success.rename')
    })
end)

QBCore.Functions.CreateCallback('DP-Banking:server:deleteAccount', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end

    local accountName = data.accountName

    if not Accounts[accountName] then
        return cb({
            success = false,
            message = Lang:t('error.account')
        })
    end

    if Accounts[accountName].citizenid ~= citizenid then
        return cb({
            success = false,
            message = Lang:t('error.access')
        })
    end

    -- Primero eliminamos los statements
    local result = MySQL.rawExecute.await('DELETE FROM bank_statements WHERE account_name = ?', {accountName})
    if not result then
        return cb({
            success = false,
            message = 'Error al eliminar el historial de la cuenta'
        })
    end

    -- Luego la cuenta
    result = MySQL.rawExecute.await('DELETE FROM bank_accounts WHERE account_name = ? AND citizenid = ?',
        {accountName, citizenid})

    if not result then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end

    Accounts[accountName] = nil

    TriggerEvent('qb-log:server:CreateLog', 'banking', 'Account Deleted', 'red',
        string.format('**%s** deleted account **%s**', GetPlayerName(src), accountName))

    cb({
        success = true,
        message = Lang:t('success.delete')
    })
end)

QBCore.Functions.CreateCallback('DP-Banking:server:addUser', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local userToAdd = data.userName
    local accountName = data.accountName
    if not Accounts[accountName] then
        return cb({
            success = false,
            message = Lang:t('error.account')
        })
    end
    if Accounts[accountName].citizenid ~= citizenid then
        return cb({
            success = false,
            message = Lang:t('error.access')
        })
    end
    local account = Accounts[accountName]
    local users = json.decode(account.users)
    for _, cid in ipairs(users) do
        if cid == userToAdd then
            return cb({
                success = false,
                message = Lang:t('error.user')
            })
        end
    end
    users[#users + 1] = userToAdd
    local usersData = json.encode(users)
    Accounts[accountName].users = usersData
    local result = MySQL.update.await('UPDATE bank_accounts SET users = ? WHERE account_name = ? AND citizenid = ?',
        {usersData, accountName, citizenid})
    if not result then
        cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    TriggerEvent('qb-log:server:CreateLog', 'banking', 'User Added', 'green',
        string.format('**%s** added **%s** to **%s**', GetPlayerName(src), userToAdd, accountName))
    cb({
        success = true,
        message = Lang:t('success.userAdd')
    })
end)

QBCore.Functions.CreateCallback('DP-Banking:server:removeUser', function(source, cb, data)
    local src = source
    local Player, citizenid = getPlayerAndCitizenId(src)
    if not Player or not citizenid then
        return cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    local userToRemove = data.userName
    local accountName = data.accountName
    if not Accounts[accountName] then
        return cb({
            success = false,
            message = Lang:t('error.account')
        })
    end
    if Accounts[accountName].citizenid ~= citizenid then
        return cb({
            success = false,
            message = Lang:t('error.access')
        })
    end
    local account = Accounts[accountName]
    local users = json.decode(account.users)
    local userFound = false
    for i = #users, 1, -1 do
        if users[i] == userToRemove then
            table.remove(users, i)
            userFound = true
            break
        end
    end
    if not userFound then
        return cb({
            success = false,
            message = Lang:t('error.noUser')
        })
    end
    local usersData = json.encode(users)
    Accounts[accountName].users = usersData
    local result = MySQL.update.await('UPDATE bank_accounts SET users = ? WHERE account_name = ? AND citizenid = ?',
        {usersData, accountName, citizenid})
    if not result then
        cb({
            success = false,
            message = Lang:t('error.error')
        })
    end
    TriggerEvent('qb-log:server:CreateLog', 'banking', 'User Removed', 'red',
        string.format('**%s** removed **%s** from **%s**', GetPlayerName(src), userToRemove, accountName))
    cb({
        success = true,
        message = Lang:t('success.userRemove')
    })
end)

-- Items

QBCore.Functions.CreateUseableItem('bank_card', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return
    end
    if Player.Functions.GetItemByName(item.name) then
        TriggerClientEvent('DP-Banking:client:useCard', source)
    end
end)

-- Threads

CreateThread(function()
    local accounts = MySQL.query.await('SELECT * FROM bank_accounts')

    for _, account in ipairs(accounts) do
        Accounts[account.account_name] = account
    end

    for job in pairs(QBCore.Shared.Jobs) do
        if Accounts[job] == nil then
            CreateJobAccount(job, 0)
        end
    end
end)

CreateThread(function()
    local statements = MySQL.query.await('SELECT * FROM bank_statements')
    for _, statement in ipairs(statements) do
        if statement.account_name == 'Personal' then
            if not Statements[statement.citizenid] then
                Statements[statement.citizenid] = {}
            end
            if not Statements[statement.citizenid][statement.account_name] then
                Statements[statement.citizenid][statement.account_name] = {}
            end
            Statements[statement.citizenid][statement.account_name][#Statements[statement.citizenid][statement.account_name] +
                1] = statement
        else
            if not Statements[statement.account_name] then
                Statements[statement.account_name] = {}
            end
            Statements[statement.account_name][#Statements[statement.account_name] + 1] = statement
        end
    end
end)

-- Commands

QBCore.Commands.Add('givecash', 'Give Cash', {{
    name = 'id',
    help = 'Player ID'
}, {
    name = 'amount',
    help = 'Amount'
}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local target = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not target then
        return QBCore.Functions.Notify(src, Lang:t('error.noUser'), 'error', 5000)
    end
    local targetPed = GetPlayerPed(tonumber(args[1]))
    local targetCoords = GetEntityCoords(targetPed)
    local amount = tonumber(args[2])
    if not amount then
        return QBCore.Functions.Notify(src, Lang:t('error.amount'), 'error', 5000)
    end
    if amount <= 0 then
        return QBCore.Functions.Notify(src, Lang:t('error.amount'), 'error', 5000)
    end
    if #(playerCoords - targetCoords) > 5 then
        return QBCore.Functions.Notify(src, Lang:t('error.toofar'), 'error', 5000)
    end
    if Player.PlayerData.money.cash < amount then
        return QBCore.Functions.Notify(src, Lang:t('error.money'), 'error', 5000)
    end
    Player.Functions.RemoveMoney('cash', amount, 'cash transfer')
    target.Functions.AddMoney('cash', amount, 'cash transfer')
    QBCore.Functions.Notify(src, string.format(Lang:t('success.give'), amount), 'success', 5000)
    QBCore.Functions.Notify(target.PlayerData.source, string.format(Lang:t('success.receive'), amount), 'success', 5000)
end)
