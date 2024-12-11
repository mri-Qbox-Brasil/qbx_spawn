local config = require 'config.client'
local previewCam, scaleform, buttonsScaleform
local currentButtonID, previousButtonID = 1, 1
local arrowStart = {
    vec2(-3150.25, -1427.83),
    vec2(4173.08, 1338.72),
    vec2(-2390.23, 6262.24)
}

local spawns

local function setupCamera()
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', -24.77, -590.35, 90.8, -2.0, 0.0, 160.0, 45.0, false, 2)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 1, true, true)
end

local function stopCamera()
    SetCamActive(previewCam, false)
    DestroyCam(previewCam, true)
    RenderScriptCams(false, false, 1, true, true)

    BeginScaleformMovieMethod(scaleform, 'CLEANUP')
    EndScaleformMovieMethod()
end

local function managePlayer()
    SetEntityCoords(cache.ped, -21.58, -583.76, 86.31, false, false, false, false)
    FreezeEntityPosition(cache.ped, true)

    SetTimeout(500, function()
        DoScreenFadeIn(5000)
    end)
end

local function createSpawnArea()
    for i = 1, #spawns, 1 do
        local spawn = spawns[i]

        if not spawn.coords then return end
        BeginScaleformMovieMethod(scaleform, 'ADD_AREA')
        ScaleformMovieMethodAddParamInt(i)
        ScaleformMovieMethodAddParamFloat(spawn.coords.x)
        ScaleformMovieMethodAddParamFloat(spawn.coords.y)
        ScaleformMovieMethodAddParamFloat(500.0)
        ScaleformMovieMethodAddParamInt(255)
        ScaleformMovieMethodAddParamInt(0)
        ScaleformMovieMethodAddParamInt(0)
        ScaleformMovieMethodAddParamInt(100)
        EndScaleformMovieMethod()
    end
end

local function setupInstructionalButton(index, control, text)
    BeginScaleformMovieMethod(buttonsScaleform, 'SET_DATA_SLOT')

    ScaleformMovieMethodAddParamInt(index)

    ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(2, control, true))

    BeginTextCommandScaleformString('STRING')
    AddTextComponentSubstringKeyboardDisplay(text)
    EndTextCommandScaleformString()

    EndScaleformMovieMethod()
end

local function setupInstructionalScaleform()
    DrawScaleformMovieFullscreen(buttonsScaleform, 255, 255, 255, 0, 0)

    BeginScaleformMovieMethod(buttonsScaleform, 'CLEAR_ALL')
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(buttonsScaleform, 'SET_CLEAR_SPACE')
    ScaleformMovieMethodAddParamInt(200)
    EndScaleformMovieMethod()

    setupInstructionalButton(0, 191, 'Submit')
    setupInstructionalButton(1, 187, 'Down')
    setupInstructionalButton(2, 188, 'Up')

    BeginScaleformMovieMethod(buttonsScaleform, 'DRAW_INSTRUCTIONAL_BUTTONS')
    EndScaleformMovieMethod()
end

local function setupMap()
    scaleform = lib.requestScaleformMovie('HEISTMAP_MP', 5000) or 0
    buttonsScaleform = lib.requestScaleformMovie('INSTRUCTIONAL_BUTTONS', 5000) or 0
    CreateThread(function()
        setupInstructionalScaleform()
        createSpawnArea()
        while DoesCamExist(previewCam) do
            DrawScaleformMovie_3d(scaleform, -24.86, -593.38, 91.8, -180.0, -180.0, -20.0, 0.0, 2.0, 0.0, 3.815, 2.27, 1.0, 2)

            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(9)

            DrawScaleformMovieFullscreen(buttonsScaleform, 255, 255, 255, 255, 0)
            Wait(0)
        end

        SetScaleformMovieAsNoLongerNeeded(scaleform)
        SetScaleformMovieAsNoLongerNeeded(buttonsScaleform)
    end)
end

local function scaleformDetails(index)
    local spawn = spawns[index]
    print(json.encode(spawn))

    if not spawn.coords then return end
    BeginScaleformMovieMethod(scaleform, 'ADD_HIGHLIGHT')
    ScaleformMovieMethodAddParamInt(index)

    ScaleformMovieMethodAddParamFloat(spawn.coords.x)
    ScaleformMovieMethodAddParamFloat(spawn.coords.y)
    ScaleformMovieMethodAddParamFloat(500.0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(255)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(100)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, 'COLOUR_AREA')
    ScaleformMovieMethodAddParamInt(index)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(255)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, 'ADD_TEXT')
    ScaleformMovieMethodAddParamInt(index)
    ScaleformMovieMethodAddParamTextureNameString(locale(spawn.label))
    ScaleformMovieMethodAddParamFloat(spawn.coords.x)
    ScaleformMovieMethodAddParamFloat(spawn.coords.y - 500)
    ScaleformMovieMethodAddParamFloat(25 - math.random(0, 50))
    ScaleformMovieMethodAddParamInt(24)
    ScaleformMovieMethodAddParamInt(100)
    ScaleformMovieMethodAddParamInt(255)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()

    local randomCoords = arrowStart[math.random(#arrowStart)]

    BeginScaleformMovieMethod(scaleform, 'ADD_ARROW')
    ScaleformMovieMethodAddParamInt(index)
    ScaleformMovieMethodAddParamFloat(randomCoords.x)
    ScaleformMovieMethodAddParamFloat(randomCoords.y)
    ScaleformMovieMethodAddParamFloat(spawn.coords.x)
    ScaleformMovieMethodAddParamFloat(spawn.coords.y)
    ScaleformMovieMethodAddParamFloat(math.random(30, 80))
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, 'COLOUR_ARROW')
    ScaleformMovieMethodAddParamInt(index)
    ScaleformMovieMethodAddParamInt(255)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(100)
    EndScaleformMovieMethod()
end

local function updateScaleform()
    if previousButtonID == currentButtonID then return end

    for i = 1, #spawns, 1 do
        BeginScaleformMovieMethod(scaleform, 'REMOVE_HIGHLIGHT')
        ScaleformMovieMethodAddParamInt(i)
        EndScaleformMovieMethod()

        BeginScaleformMovieMethod(scaleform, 'REMOVE_TEXT')
        ScaleformMovieMethodAddParamInt(i)
        EndScaleformMovieMethod()

        BeginScaleformMovieMethod(scaleform, 'REMOVE_ARROW')
        ScaleformMovieMethodAddParamInt(i)
        EndScaleformMovieMethod()

        BeginScaleformMovieMethod(scaleform, 'COLOUR_AREA')
        ScaleformMovieMethodAddParamInt(i)
        ScaleformMovieMethodAddParamInt(255)
        ScaleformMovieMethodAddParamInt(0)
        ScaleformMovieMethodAddParamInt(0)
        ScaleformMovieMethodAddParamInt(100)
        EndScaleformMovieMethod()
    end

    scaleformDetails(currentButtonID)
end

local function inputHandler()
    while DoesCamExist(previewCam) do
        if IsControlJustReleased(0, 188) then
            previousButtonID = currentButtonID
            currentButtonID -= 1

            if currentButtonID < 1 then
                currentButtonID = #spawns
            end

            updateScaleform()
        elseif IsControlJustReleased(0, 187) then
            previousButtonID = currentButtonID
            currentButtonID += 1

            if currentButtonID > #spawns then
                currentButtonID = 1
            end

            updateScaleform()
        elseif IsControlJustReleased(0, 191) then
            if not config.clouds then
                DoScreenFadeOut(1000)

                while not IsScreenFadedOut() do
                    Wait(0)
                end
            else
                SwitchOutPlayer(PlayerPedId(), 0, 1)
                Citizen.Wait(250)
                stopCamera()
            end

            FreezeEntityPosition(cache.ped, false)
            
            local coords = spawns[currentButtonID].coords

            SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
            SetEntityHeading(cache.ped, coords.w or 0.0)


            local spawnData = spawns[currentButtonID]
            if spawnData.propertyId then
                TriggerServerEvent('ps-housing:server:enterProperty', tostring(spawnData.propertyId), 'spawn')
            elseif spawns[currentButtonID].coords == lib.callback.await('qbx_spawn:server:getLastLocation') then -- last location
                local insideMeta = QBX.PlayerData.metadata["inside"]
                if insideMeta.property_id ~= nil then
                    local property_id = insideMeta.property_id
                    TriggerServerEvent('ps-housing:server:enterProperty', tostring(property_id))
                end
            else
                SetEntityCoords(cache.ped, spawnData.coords.x, spawnData.coords.y, spawnData.coords.z, false, false, false, false)
                SetEntityHeading(cache.ped, spawnData.coords.w or 0.0)
            end

            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
        
            if config.clouds then 
                Citizen.Wait(5000)
                SwitchInPlayer(PlayerPedId())
                if not spawns[currentButtonID].first_time then
                    lib.requestAnimDict("random@peyote@generic", 15000)
                    Citizen.Wait(1500)
                    TaskPlayAnim(cache.ped, "random@peyote@generic", "wakeup", 8.0, 8.0, -1, 0, 0, false, false, false)
                end
            else
                DoScreenFadeIn(1000)
            end
            break
        end

        Wait(0)
    end
    if not config.clouds then
        stopCamera()
    end
end

AddEventHandler('qb-spawn:client:setupSpawns', function(cData, new, apps)
    spawns = {}
    if new then
        for k, v in pairs(apps) do 
            spawns[#spawns+1] = {
                first_time = true,
                key = k,
                label = v.label,
                coords = vector3(v.door.x, v.door.y, v.door.z)
            }
        end
    else
        spawns[#spawns+1] = {
            label = 'last_location',
            coords = lib.callback.await('qbx_spawn:server:getLastLocation')
        }

        for i = 1, #config.spawns do
            spawns[#spawns+1] = config.spawns[i]
        end

        local houses = lib.callback.await('qbx_spawn:server:getHouses')

        for i = 1, #houses do
            spawns[#spawns+1] = houses[i]
            --print(houses[i].label)
        end
    end

    Wait(400)

    managePlayer()
    setupCamera()
    setupMap()

    Wait(400)

    scaleformDetails(currentButtonID)
    inputHandler()
end)
