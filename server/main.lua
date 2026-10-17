lib.versionCheck('Qbox-project/qbx_spawn')

local config = require 'config.server'
local ps_starters = {
    -- ["Name of Starting appartment"] = vector3()
    ["Motel"] = vector3(325.14, -229.54, 54.21)
}

local lastRequests = {}

local function isRateLimited(source, callbackName)
    local now = os.time()
    local requests = lastRequests[source]

    if not requests then
        requests = {}
        lastRequests[source] = requests
    elseif requests[callbackName] == now then
        return true
    end

    requests[callbackName] = now
    return false
end

local function isFiniteNumber(value)
    return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

local function decodeCoords(encodedCoords)
    if type(encodedCoords) ~= 'string' then return end

    local success, coords = pcall(json.decode, encodedCoords)
    if not success or type(coords) ~= 'table' then return end
    if not isFiniteNumber(coords.x) or not isFiniteNumber(coords.y) or not isFiniteNumber(coords.z) then return end
    if coords.w ~= nil and not isFiniteNumber(coords.w) then return end

    return coords
end

lib.callback.register('qbx_spawn:server:getLastLocation', function(source)
    if isRateLimited(source, 'lastLocation') then return end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local queryResult = MySQL.single.await('SELECT position FROM players WHERE citizenid = ?', { player.PlayerData.citizenid })
    if not queryResult then return end

    local position = decodeCoords(queryResult.position)
    if not position then return end

    local currentPropertyId = player.PlayerData.metadata.inside and player.PlayerData.metadata.inside.propertyId

    return position, currentPropertyId
end)

lib.callback.register('qbx_spawn:server:getHouses', function(source)
    if not GetResourceState('qbx_properties'):find('start') then
        return {}
    end

    if isRateLimited(source, 'properties') then return {} end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local houseData = {}
<<<<<<< fork

    local houses = MySQL.query.await(
                       'SELECT * FROM properties WHERE owner_citizenid = ?',
                       {player.PlayerData.citizenid})

    if not houses then return {} end

    for i = 1, #houses do
        local house = houses[i]
        if not house.apartment then
            local door = exports['ps-housing']:getMainDoor(house.property_id, 1, true)
            local coords = door.objCoords or door.coords or door.doors[1] and door.doors[1].coords or door.doors[1].objCoords
            houseData[#houseData + 1] = {label = house.street, coords = coords}
        end
||||||| base
    local properties = MySQL.query.await('SELECT id, property_name, coords FROM properties WHERE owner = ?', {player.PlayerData.citizenid})
    for i = 1, #properties do
        local property = properties[i]
        houseData[#houseData + 1] = {
            label = property.property_name,
            coords = json.decode(property.coords),
            propertyId = property.id,
        }
=======
    local properties = MySQL.query.await('SELECT id, property_name, coords FROM properties WHERE owner = ?', { player.PlayerData.citizenid }) or {}

    for i = 1, #properties do
        local property = properties[i]
        local coords = decodeCoords(property.coords)

        if coords then
            houseData[#houseData + 1] = {
                label = property.property_name,
                coords = coords,
                propertyId = property.id,
            }
        end
>>>>>>> upstream
    end

    return houseData
end)

lib.callback.register('qbx_spawn:server:alreadySpawned', function(source)
    if not config.selectOnFirstSpawn then return false end
    local player = exports.qbx_core:GetPlayer(source)
    while not player do
        Wait(100)
        player = exports.qbx_core:GetPlayer(source)
    end
    local spawnedPlayers = GlobalState.SpawnedPlayers or {}
    return spawnedPlayers[player.PlayerData.citizenid]
end)

RegisterNetEvent('qbx_spawn:server:spawn', function()
    if not config.selectOnFirstSpawn then return false end
    local player = exports.qbx_core:GetPlayer(source)
    while not player do
        Wait(100)
        player = exports.qbx_core:GetPlayer(source)
    end
    local spawnedPlayers = GlobalState.SpawnedPlayers or {}
    spawnedPlayers[player.PlayerData.citizenid] = true
    GlobalState:set('SpawnedPlayers', spawnedPlayers, true)
end)

AddEventHandler('playerDropped', function()
    lastRequests[source] = nil
end)
