local QBCore = exports['qb-core']:GetCoreObject()
local zones = {}
local isPlayerInsideBankZone = false
local menuOpen = false

-- Variables para almacenar los datos temporales
local NewAccountData = {
    name = nil,
    amount = nil
}

local debitCardData = {
    pin = nil
}

-- Functions
local function OpenBankInterface()
    QBCore.Functions.TriggerCallback('DP-Banking:server:openBank', function(accounts, statements, playerData)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openBank',
            accounts = accounts,
            statements = statements,
            playerData = playerData
        })
    end)
end

local function OpenATM()
    QBCore.Functions.Progressbar('accessing_atm', Lang:t('progress.atm'), 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false
    }, {
        animDict = 'amb@prop_human_atm@male@enter',
        anim = 'enter'
    }, {
        model = 'prop_cs_credit_card',
        bone = 28422,
        coords = vector3(0.1, 0.03, -0.05),
        rotation = vector3(0.0, 0.0, 180.0)
    }, {}, function()
        QBCore.Functions.TriggerCallback('DP-Banking:server:openATM', function(accounts, playerData, acceptablePins)
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openATM',
                accounts = accounts,
                pinNumbers = acceptablePins,
                playerData = playerData
            })
        end)
    end)
end

local function NearATM()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for _, v in pairs(Config.atmModels) do
        local hash = joaat(v)
        local atm = IsObjectNearPoint(hash, playerCoords.x, playerCoords.y, playerCoords.z, 1.5)
        if atm then
            return true
        end
    end
end

-- Función para abrir el menú del banco
local function OpenBankMenu()
    local menu = {{
        header = "BANCO - OPCIONES",
        txt = "Selecciona una opción",
        isMenuHeader = true,
        icon = "fa-solid fa-university"
    }, {
        header = "ACCEDER AL BANCO",
        txt = "Acceder a todas las opciones bancarias",
        icon = "fa-solid fa-wallet",
        params = {
            event = "DP-Banking:client:openBankFull"
        }
    }, {
        header = "CONSEGUIR TARJETA", -- Nueva opción
        txt = "Ordenar nueva tarjeta de débito",
        icon = "fa-solid fa-credit-card",
        params = {
            event = "DP-Banking:client:orderDebitCardMenu"
        }
    }, {
        header = "ME HAN ROBADO LA TARJETA",
        txt = "Cancelar todas mis tarjetas bancarias",
        icon = "fa-solid fa-people-robbery",
        params = {
            event = "DP-Banking:client:reportStolenCards"
        }
    }, {
        header = "TODO LISTO",
        txt = "Cerrar este menú",
        icon = "fa-solid fa-check",
        params = {
            event = "DP-Menu:closeMenu"
        }
    }}

    menuOpen = true
    exports['DP-Menu']:openMenu(menu)
end

-- Eventos para manejar las opciones del menú
RegisterNetEvent('DP-Banking:client:openBankFull', function()
    OpenBankInterface()
end)

RegisterNetEvent('DP-Menu:closeMenu', function()
    exports['DP-Menu']:closeMenu()
    menuOpen = false
end)

RegisterNetEvent('DP-Banking:client:reportStolenCards', function()
    local confirmMenu = {{
        header = "CONFIRMAR CANCELACIÓN",
        txt = "¿Estás seguro de cancelar todas tus tarjetas?",
        isMenuHeader = true,
        icon = "fa-solid fa-exclamation-triangle"
    }, {
        header = "SÍ, CANCELAR TARJETAS",
        txt = "Se bloquearán todas tus tarjetas inmediatamente",
        icon = "fa-solid fa-check",
        params = {
            event = "DP-Banking:client:confirmCancelCards"
        }
    }, {
        header = "NO, VOLVER ATRÁS",
        icon = "fa-solid fa-arrow-left",
        params = {
            event = "DP-Banking:client:openBankMenu"
        }
    }}
    exports['DP-Menu']:openMenu(confirmMenu)
end)

RegisterNetEvent('DP-Banking:client:confirmCancelCards', function()
    QBCore.Functions.Progressbar('reporting_cards', 'Reportando tarjetas robadas...', 3000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function()
        TriggerServerEvent('DP-Banking:server:cancelAllCards')
        QBCore.Functions.Notify('Todas tus tarjetas han sido canceladas', 'success', 5000)
    end)
end)

RegisterNetEvent('DP-Banking:client:openBankMenu', function()
    -- Verificar distancia antes de abrir
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local isNear = false

    for _, coords in ipairs(Config.locations) do
        if #(playerCoords - coords) < 2.5 then
            isNear = true
            break
        end
    end

    if not isNear then
        QBCore.Functions.Notify('Estás demasiado lejos del banco', 'error', 5000)
        return
    end

    OpenBankMenu()
    menuOpen = true
    StartDistanceCheck()
end)

RegisterNetEvent('DP-Banking:client:createNewAccount', function()
    if not NewAccountData.name or not NewAccountData.amount then
        QBCore.Functions.Notify('Debes completar todos los campos', 'error', 5000)
        return
    end

    QBCore.Functions.TriggerCallback('DP-Banking:server:openAccount', function(success, message)
        if success then
            QBCore.Functions.Notify(message, 'success', 5000)
            NewAccountData = {
                name = nil,
                amount = nil
            }
            TriggerEvent('DP-Menu:closeMenu')
        else
            QBCore.Functions.Notify(message, 'error', 5000)
        end
    end, {
        accountName = NewAccountData.name,
        amount = NewAccountData.amount
    })
end)

-- Menú para ordenar tarjeta
local function OpenOrderDebitCardMenu()
    local menu = {{
        header = "ORDENAR TARJETA DE DÉBITO",
        isMenuHeader = true,
        icon = "fa-solid fa-credit-card"
    }, {
        header = "Número PIN: " .. (debitCardData.pin or "No establecido"),
        txt = "Establecer PIN de 4 dígitos",
        icon = "fa-solid fa-lock",
        params = {
            event = "DP-Banking:client:setDebitCardPin"
        }
    }, {
        header = "CONFIRMAR ORDEN",
        txt = "Ordenar tarjeta con el PIN establecido",
        icon = "fa-solid fa-check-circle",
        disabled = not debitCardData.pin,
        params = {
            event = "DP-Banking:client:confirmOrderDebitCard"
        }
    }, {
        header = "CANCELAR",
        txt = "Volver al menú principal",
        icon = "fa-solid fa-times",
        params = {
            event = "DP-Banking:client:openBankMenu"
        }
    }}

    exports['DP-Menu']:openMenu(menu)
end

-- Evento para establecer el PIN
RegisterNetEvent('DP-Banking:client:setDebitCardPin', function()
    local input = exports['DP-Input']:ShowInput({
        header = "ESTABLECER PIN",
        submitText = "Confirmar",
        inputs = {{
            text = "Ingrese PIN de 4 dígitos",
            name = "pin",
            type = "number",
            isRequired = true,
            validate = function(value)
                if string.len(value) ~= 4 then
                    return "El PIN debe tener 4 dígitos"
                end
                return true
            end
        }}
    })

    if input then
        debitCardData.pin = tonumber(input.pin)
        TriggerEvent('DP-Banking:client:orderDebitCardMenu')
    end
end)

-- Evento para confirmar la orden
RegisterNetEvent('DP-Banking:client:confirmOrderDebitCard', function()
    if not debitCardData.pin then
        QBCore.Functions.Notify('Debes establecer un PIN primero', 'error', 5000)
        return
    end

    QBCore.Functions.TriggerCallback('DP-Banking:server:orderCard', function(success)
        if success then
            debitCardData.pin = nil
            TriggerEvent('DP-Menu:closeMenu')
            QBCore.Functions.Notify('Tarjeta creada', 'success', 5000)
        else
            QBCore.Functions.Notify('No se pudo crear la tarjeta', 'success', 5000)
        end
    end, {
        pin = debitCardData.pin
    })
end)

-- Evento para abrir el menú
RegisterNetEvent('DP-Banking:client:orderDebitCardMenu', function()
    OpenOrderDebitCardMenu()
end)

-- NUI Callback
RegisterNUICallback('closeApp', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:withdraw', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('deposit', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:deposit', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('internalTransfer', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:internalTransfer', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('externalTransfer', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:externalTransfer', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('orderCard', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:orderCard', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('openAccount', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:openAccount', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('renameAccount', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:renameAccount', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('deleteAccount', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:deleteAccount', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('addUser', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:addUser', function(status)
        cb(status)
    end, data)
end)

RegisterNUICallback('removeUser', function(data, cb)
    QBCore.Functions.TriggerCallback('DP-Banking:server:removeUser', function(status)
        cb(status)
    end, data)
end)

-- Events
RegisterNetEvent('DP-Banking:client:useCard', function()
    if NearATM() then
        OpenATM()
    end
end)

-- Threads
CreateThread(function()
    for i = 1, #Config.locations do
        local blip = AddBlipForCoord(Config.locations[i])
        SetBlipSprite(blip, Config.blipInfo.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.blipInfo.scale)
        SetBlipColour(blip, Config.blipInfo.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(tostring(Config.blipInfo.name))
        EndTextCommandSetBlipName(blip)
    end
end)

if Config.useTarget then
    CreateThread(function()
        for i = 1, #Config.locations do
            exports['qb-target']:AddCircleZone('bank_' .. i, Config.locations[i], 1.0, {
                name = 'bank_' .. i,
                useZ = true,
                debugPoly = false
            }, {
                options = {{
                    icon = 'fa-solid fa-university',
                    label = 'Abrir Banco',
                    action = function()
                        TriggerEvent('DP-Banking:client:openBankMenu')
                    end
                }},
                distance = 1.5
            })
        end
    end)

    CreateThread(function()
        for i = 1, #Config.atmModels do
            local atmModel = Config.atmModels[i]
            exports['qb-target']:AddTargetModel(atmModel, {
                options = {{
                    icon = 'fa-solid fa-university',
                    label = 'Open ATM',
                    item = 'bank_card',
                    action = function()
                        OpenATM()
                    end
                }},
                distance = 1.5
            })
        end
    end)
end

if not Config.useTarget then
    CreateThread(function()
        for i = 1, #Config.locations do
            local zone = CircleZone:Create(Config.locations[i], 2.5, { -- Reducido a 2.5m
                name = 'bank_' .. i,
                debugPoly = false
            })
            zones[#zones + 1] = zone
        end

        local combo = ComboZone:Create(zones, {
            name = 'bank_combo',
            debugPoly = false
        })

        combo:onPlayerInOut(function(isPointInside)
            isPlayerInsideBankZone = isPointInside
            if isPlayerInsideBankZone then
                if Config.useDPTextUI then
                    exports['DP-TextUI']:MostrarUI('banco', 'Abrir Banco', 'E', false)
                else
                    TriggerEvent('qb-core:client:DrawText', '[E] Abrir Banco', 'left')
                end

                CreateThread(function()
                    while isPlayerInsideBankZone do
                        Wait(0)
                        if IsControlJustPressed(0, 38) then
                            TriggerEvent('DP-Banking:client:openBankMenu')
                        end
                    end
                end)
            else
                if Config.useDPTextUI then
                    exports['DP-TextUI']:OcultarUI()
                else
                    TriggerEvent('qb-core:client:HideText')
                end

                if menuOpen then
                    exports['DP-Menu']:closeMenu()
                    menuOpen = false
                end
            end
        end)
    end)
end

-- Función para verificar la distancia
function StartDistanceCheck()
    local startCoords = GetEntityCoords(PlayerPedId())

    CreateThread(function()
        while menuOpen do
            Wait(500) -- Verifica cada medio segundo (más sensible)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- Verifica distancia desde el punto original
            if #(playerCoords - startCoords) >= 2.5 then
                exports['DP-Menu']:closeMenu()
                menuOpen = false
                break
            end
        end
    end)
end

RegisterNetEvent('DP-Menu:client:closeMenu', function()
    menuOpen = false
end)
