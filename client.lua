cbfm = {}
Tunnel.bindInterface(GetCurrentResourceName(),cbfm)
bfm = Tunnel.getInterface(GetCurrentResourceName())

local s,n = Notifys['Success'],Notifys['Denied']

local onNui
local routeId,routeTypes,routeItems
local routeBlip,genRoute
local routeLobbyBlips = {}

local routeLobby,routeLobbyList = false,{}
local pendingInvite = 0
local pendingInviterName,pendingInviterId,pendingInviterSrc

RegisterNetEvent('reloadConfigRoutes')
AddEventHandler('reloadConfigRoutes', function(newConfigRoutes)
    Config.routes = newConfigRoutes
end)


-- Threads
findNuiThread = function()
    while true do
        local ocelotSleep = 1500

        if not routeLobby then
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            for k,v in next,Config.routes do
                local distanceToBlip = #(pedPos - vec3(v.startRoute[1],v.startRoute[2],v.startRoute[3]))
                if distanceToBlip < 5.733 then
                    ocelotSleep = 1
                    DrawMarker(31, v.startRoute[1],v.startRoute[2],v.startRoute[3]-0.77, 0, 0, 0, 0, 0, 0, 0.4337, 0.4337, 0.4337, 117,0,225, 70, false, true, 2, true)
                    if IsControlJustPressed(0,38) then
                        if not IsPedInAnyVehicle(ped, true) then
                            if not routeTypes and not routeItems and bfm.serverSideCheck(tonumber(k)) then
                                routeId = tonumber(k)
                                openGui({translateItemsArray(v.receivableItems),translateItemsArray(v.deliverableItems)})
                            end
                        else
                            n('Desça do veículo para iniciar uma rota.',7337)
                        end
                    end
                end
            end
        end

        Wait(ocelotSleep)
    end
end
CreateThread(findNuiThread)

routeThread = function()
    while routeTypes and routeItems do
        local ocelotSleep = 1500

        local ped = PlayerPedId()
        local pedPos = GetEntityCoords(ped)
        local routePos = vec3(Config.routes[routeId].routeLocations[genRoute][1],Config.routes[routeId].routeLocations[genRoute][2],Config.routes[routeId].routeLocations[genRoute][3])
        local distanceToBlip = #(pedPos - routePos)
        if distanceToBlip < 21.337 then
            ocelotSleep = 1
            DrawMarker(21, Config.routes[routeId].routeLocations[genRoute][1],Config.routes[routeId].routeLocations[genRoute][2],Config.routes[routeId].routeLocations[genRoute][3], 0, 0, 0, 0, 0, 0, 0.5733,0.5733,0.5733, 117,0,225,71, true, true, 2, true)
            
            if distanceToBlip < 2 then
                if IsControlJustPressed(0,38) then
                    if Config.forceOffVehicle then
                        if not IsPedInAnyVehicle(ped) then
                            playAnim(true,{{"pickup_object","pickup_low"}},false)
                            routePaycheck()
                            Wait(7)
                            nextRoute()
                            Wait(7)
                        else
                            n('Desça do veículo para prosseguir.',7337)
                            Wait(133)
                        end
                    else
                        routePaycheck()
                        Wait(7)
                        nextRoute()
                        Wait(7)
                    end
                end
            end
            
        end

        Wait(ocelotSleep)
    end
end

checkCancelRouteThread = function()
    while routeTypes and routeItems do
        local ocelotSleep = 1

        screenTxt('~w~PRESSIONE ~p~F7~w~ PARA FINALIZAR ROTAS',4, 0.1033,0.0733, 0.52, 255,255,255,255)
        screenTxt('~w~SIGA A MARCAÇÃO EM SEU ~p~GPS',4, 0.1033,0.04733, 0.52, 255,255,255,255)
        if IsControlJustPressed(0, 168) then
            TriggerServerEvent('desyncPlayerFromGroupSvRequest')

            routeId,routeTypes,routeItems = nil,nil,nil
            RemoveBlip(routeBlip)
            routeBlip = nil

            if routeLobby and #routeLobbyList >= 1 then
                TriggerServerEvent('desyncFromRunningLobbySvRequest')
            end

            routeLobby = false
            routeLobbyList = {}

            for k,v in next,routeLobbyBlips do
                RemoveBlip(v)
            end
            routeLobbyBlips = {}

            s('Você finalizou suas rotas.',7337)
        end

        Wait(ocelotSleep)
    end
end

pendingInviteThread = function()
    while pendingInvite > 0 do
        pendingInvite = pendingInvite - 1000
        Wait(1000)
    end
    pendingInvite = 0
end

-- Funções Main
nextRoute = function()
    if routeId then
        if Config.routes[routeId].randomRoutes then
            genRoute = math.random(1,#Config.routes[routeId].routeLocations)
            if routeBlip then
                RemoveBlip(routeBlip)
            end
            routeBlip = createBlip(Config.routes[routeId].routeLocations[genRoute][1],Config.routes[routeId].routeLocations[genRoute][2],Config.routes[routeId].routeLocations[genRoute][3])
        else
            if routeBlip then
                RemoveBlip(routeBlip)
                if genRoute == #Config.routes[routeId].routeLocations then
                    genRoute = 1
                else
                    genRoute = genRoute+1
                end
                routeBlip = createBlip(Config.routes[routeId].routeLocations[genRoute][1],Config.routes[routeId].routeLocations[genRoute][2],Config.routes[routeId].routeLocations[genRoute][3])
            else
                genRoute = 1
                routeBlip = createBlip(Config.routes[routeId].routeLocations[genRoute][1],Config.routes[routeId].routeLocations[genRoute][2],Config.routes[routeId].routeLocations[genRoute][3])
            end
        end
    end
end

routePaycheck = function()
    if routeId and routeTypes and routeTypes[1] and routeItems and #routeItems >= 1 then
        bfm.routePaycheck(routeId,routeTypes,routeItems,{genRoute,GetEntityCoords(PlayerPedId())})
    end
end

-- Prompt System
RegisterNUICallback('loadInviteCards', function(data,cb)
    local nearestPlayers = getNearestPlayers(4)
    if #nearestPlayers >= 1 then
        cb(nearestPlayers)
    else
        cb(false)
    end
end)

RegisterNUICallback('sendGroupInvite', function(data,cb)
    if data.elemento then
        local srcToInvite = data.elemento
        if bfm.sendServerInviteToGroup(srcToInvite) then
            cb(true)
        end
    end
end)

RegisterNetEvent('receiveInviteClient')
AddEventHandler('receiveInviteClient', function(inviterName,inviterId,inviterSrc)
    if pendingInvite == 0 then
        pendingInviterName = inviterName
        pendingInviterId = inviterId
        pendingInviterSrc = inviterSrc
        SendNUIMessage({onPrompt={inviterName,inviterId,inviterSrc}})

        pendingInvite = 15000
        CreateThread(pendingInviteThread)
    end
end)

acceptLobbyInvite = function()
    if pendingInvite > 0 then
        if inviterName and inviterId and inviterSrc then
            TriggerServerEvent('clientInviteResponse', true,inviterName,inviterId,inviterSrc)
            SendNUIMessage({closingPrompt=true})
            pendingInvite = 0
            routeLobby = true
        end
    end
end
RegisterCommand('acceptrouteslobbyinvite', acceptLobbyInvite)
RegisterKeyMapping('acceptrouteslobbyinvite', 'Aceitar oferta de lobby', 'keyboard', 'Y')

denyLobbyInvite = function()
    if pendingInvite > 0 then
        if inviterName and inviterId and inviterSrc then
            TriggerServerEvent('clientInviteResponse', inviterName,inviterId,inviterSrc)
            SendNUIMessage({closingPrompt=true})
            pendingInvite = 0
        end
    end
end
RegisterCommand('denyrouteslobbyinvite', denyLobbyInvite)
RegisterKeyMapping('denyrouteslobbyinvite', 'Recusar oferta de lobby', 'keyboard', 'N')

reiceiveFinalResponseFromInvite = function(inviteResponse,invitedSrc,newLobbyList)
    if inviteResponse and newLobbyList then
        routeLobby = true
        routeLobbyList = newLobbyList
    end
end
RegisterNetEvent('reiceiveFinalResponseFromInvite')
AddEventHandler('reiceiveFinalResponseFromInvite', reiceiveFinalResponseFromInvite)

desyncFromLobby = function()
    routeLobby = false
    routeLobbyList = {}
    pendingInvite = 0
    pendingInviterName = nil
    pendingInviterId = nil
    pendingInviterSrc = nil
    SendNUIMessage({closingPrompt=true})
end
RegisterNetEvent('desyncFromLobby')
AddEventHandler('desyncFromLobby', desyncFromLobby)

desyncFromRunningLobby = function()
    routeLobby = false
    routeLobbyList = {}
    
    pendingInvite = 0
    pendingInviterName,pendingInviterId,pendingInviterSrc = nil,nil,nil
    
    routeId,routeTypes,routeItems = nil,nil,nil
    RemoveBlip(routeBlip)
    routeBlip = nil

    for k,v in next,routeLobbyBlips do
        RemoveBlip(v)
    end
    routeLobbyBlips = {}

    s('O dono do lobby encerrou o grupo e suas rotas.')
end
RegisterNetEvent('desyncFromRunningLobby')
AddEventHandler('desyncFromRunningLobby', desyncFromRunningLobby)

desyncPlayerFromGroupResponse = function(srcToRemove,newLobbyList)
    RemoveBlip(routeLobbyBlips[srcToRemove])
    routeLobbyBlips[srcToRemove] = nil
    if routeLobby and #routeLobbyList >= 1 then
        routeLobbyList = newLobbyList
    end
end
RegisterNetEvent('desyncPlayerFromGroupResponse')
AddEventHandler('desyncPlayerFromGroupResponse', desyncPlayerFromGroupResponse)

beginRouteLobby = function(routeId,routeTypes,routeItems,routePlayers)
    routeId = routeId
    routeTypes = routeTypes
    routeItems = routeItems

    nextRoute()
    CreateThread(routeThread)
    CreateThread(checkCancelRouteThread)

    for k,v in next,routePlayers do
        local playerPed = GetPlayerPed(GetPlayerFromServerId(tonumber(v)))
        routeLobbyBlips[tonumber(v)] = AddBlipForEntity(playerPed)
        SetBlipSprite(routeLobbyBlips[tonumber(v)],126)
        SetBlipColour(routeLobbyBlips[tonumber(v)],48)
        SetBlipScale(routeLobbyBlips[tonumber(v)],0.5733)
        SetBlipAsShortRange(routeLobbyBlips[tonumber(v)],false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Companheiro de Rota')
        EndTextCommandSetBlipName(routeLobbyBlips[tonumber(v)])
    end
end
RegisterNetEvent('beginRouteLobby')
AddEventHandler('beginRouteLobby', beginRouteLobby)

-- NUI comms.
RegisterNUICallback('beginRoute', function(data)
    closeGui()
    if data.routeTypes and data.selectedItems then
        routeTypes = data.routeTypes
        routeItems = data.selectedItems

        nextRoute()
        CreateThread(routeThread)
        CreateThread(checkCancelRouteThread)

        if #routeLobbyList >= 1 then
            TriggerServerEvent('syncRouteLobbyBeginning', routeId,routeTypes,routeItems)
            for k,v in next,routeLobbyList do
                local playerPed = GetPlayerPed(GetPlayerFromServerId(tonumber(v)))
                routeLobbyBlips[tonumber(v)] = AddBlipForEntity(playerPed)
                SetBlipSprite(routeLobbyBlips[tonumber(v)],126)
                SetBlipColour(routeLobbyBlips[tonumber(v)],48)
                SetBlipScale(routeLobbyBlips[tonumber(v)],0.5733)
                SetBlipAsShortRange(routeLobbyBlips[tonumber(v)],false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString('Companheiro de Rota')
                EndTextCommandSetBlipName(routeLobbyBlips[tonumber(v)])
            end
        end

        s('Sua rotas começaram! Siga o caminho marcado em seu GPS.',7337)
    end
end)
    
openGui = function(arrayData)
    onNui = true
    SetNuiFocus(true, true)
    SendNUIMessage({onNui = true,arrayData=arrayData})
    TriggerScreenblurFadeIn(1000)
end

closeGui = function()
    onNui = false
    SetNuiFocus(false, false)
    SendNUIMessage({onNui = false})
    TriggerScreenblurFadeOut(1000)

    if not routeTypes and not routeItems then
        routeLobby = false
        routeLobbyList = {}
        TriggerServerEvent('desyncLobby')
    end
end
RegisterNUICallback('closeGui',closeGui)

-- Funções Suporte
translateItemsArray = function(array)
    local newArray = {}
    for k,v in next,array do
        table.insert(newArray, tostring(k))
    end
    return newArray
end

createBlip = function(x,y,z)
	edBlip = AddBlipForCoord(x,y,z)
	SetBlipSprite(edBlip,739)
	SetBlipColour(edBlip,48)
	SetBlipScale(edBlip,0.5733)
    SetBlipAsShortRange(edBlip,false)
	SetBlipRoute(edBlip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Rotas')
	EndTextCommandSetBlipName(edBlip)
    return edBlip
end

-- RouteTools Stuff
local onSetting,noclip
local routes,croutes,blips = {},{},{}
local actual = 0
local markerId = 1

cbfm.getPosition = function()
    local playerPos = GetEntityCoords(PlayerPedId())
    return {playerPos[1],playerPos[2],playerPos[3]}
end

cbfm.getCVar = function()
    return onSetting
end

cbfm.onIt = function()
    SendNuiMessage(json.encode({ display = true, blipsCounter = 0 }))
    routes = {}
    croutes = {}
    actual = 0
    onSetting = true
    startRouteThread()
    toggleNoClip(true)
    vAFK()
    
    s('Setagem de rotas ativada!',7337)
end

cbfm.offIt = function()
    onSetting = false
    SendNuiMessage(json.encode({ display = false }))
    toggleNoClip(false)
    return routes,actual,markerId
end

vAFK = function()
    CreateThread(function()
        local vAFKThread = GetIdOfThisThread()

        while onSetting do
            Wait(77333)
            if onSetting then
                if actual <= 1 then
                    routes = {}
                    croutes = {}
                    actual = 0
                    onSetting = false
                    SendNuiMessage(json.encode({ display = false }))
                    toggleNoClip(false)
                    
                    n('Sua setagem de rotas foi cancelada automaticamente.',7337)
                end
            else
                break
            end
        end
    end)
end

startRouteThread = function()
    CreateThread(function()
        local routesThread = GetIdOfThisThread()
        
        while onSetting do
            local checks = 1000
            
            local ped = PlayerPedId()
            local pedpos = GetEntityCoords(ped)
            local bool,chao = GetGroundZFor_3dCoord(pedpos[1], pedpos[2], pedpos[3])
            local dist = (pedpos[3] - chao)
            
            if dist <= 7.733 then
                local hit, coords = RayCastGamePlayCamera(33.7)
                if hit then
                    checks = 1
                    DrawMarker(markerId,coords.x, coords.y, coords.z+0.337,0,0,0,0.0,0,0,0.5,0.5,0.5, 117,0,225,68, 0,0,0,1)
                    
                    if IsControlJustPressed(0,24) then
                        actual = actual + 1
                        routes[actual] = {coords.x, coords.y, coords.z+0.337}
                        croutes[actual] = {coords.x, coords.y, coords.z+0.337}
                        SendNuiMessage(json.encode({ display = true, blipsCounter = actual }))
                        if actual == 1 then
                            startDrawMarkersThread()
                        end
                        PlaySoundFrontend(-1,'NAV_UP_DOWN','HUD_FRONTEND_DEFAULT_SOUNDSET')
                    end
                    
                    if IsControlJustPressed(0,73) then
                        if actual >= 1 then
                            routes[actual] = nil
                            croutes[actual] = nil
                            actual = actual - 1
                            SendNuiMessage(json.encode({ display = true, blipsCounter = actual }))
                            
                            PlaySoundFrontend(-1,'BACK','HUD_FRONTEND_DEFAULT_SOUNDSET')
                        else
                            PlaySoundFrontend(-1,'NO','HUD_FRONTEND_DEFAULT_SOUNDSET')
                            n('Não existem mais posições para deletar!',7337)
                        end
                    end
                    
                    if IsControlJustPressed(0,175) then
                        PlaySoundFrontend(-1,'CONTINUE','HUD_FRONTEND_DEFAULT_SOUNDSET')
                        markerId = markerId + 1
                        if markerId == 43 then
                            markerId = 1
                        end
                    end
                    
                    if IsControlJustPressed(0,174) then
                        PlaySoundFrontend(-1,'CONTINUE','HUD_FRONTEND_DEFAULT_SOUNDSET')
                        markerId = markerId - 1
                        if markerId == 0 then
                            markerId = 43
                        end
                    end
                    
                    if IsControlJustPressed(0,194) then
                        PlaySoundFrontend(-1,'QUIT','HUD_FRONTEND_DEFAULT_SOUNDSET')
                        bfm.offServer()
                    end
                end
            end
            
            Wait(checks)
        end
    end)
end

startDrawMarkersThread = function()
    CreateThread(function()
        while actual >= 1 and onSetting do
            for k,v in next,croutes do
                DrawMarker(markerId,v[1], v[2], v[3], 0,0,0,0.0,0,0,0.5,0.5,0.5, 247,133,7,68, 0,0,0,1)
            end
            Wait(1)
        end
    end)
end

startNoClipThread = function()
    CreateThread(function()
        local noClipThread = GetIdOfThisThread()
        
        while noclip do
            local ms = 1000
            
            if noclip then
                ms = 1
                local ped = PlayerPedId()
                local x,y,z = getPosition()
                local dx,dy,dz = getCamDirect()
                local speed = 1.0
                
                SetEntityVelocity(ped,0.0001,0.0001,0.0001)
                
                if IsControlPressed(0,21) then
                    speed = 5.0
                end
                
                if IsControlPressed(0,32) then
                    x = x+speed*dx
                    y = y+speed*dy
                    z = z+speed*dz
                end
                
                if IsControlPressed(0,269) then
                    x = x-speed*dx
                    y = y-speed*dy
                    z = z-speed*dz
                end
                
                SetEntityCoordsNoOffset(ped,x,y,z,true,true,true)
            end
            
            Wait(ms)
        end
    end)
end

toggleNoClip = function(bool)
    local ped = PlayerPedId()
    if bool then
        startNoClipThread()
        SetEntityInvincible(ped,true)
        SetEntityVisible(ped,false,false)
        noclip = true
    else
        SetEntityInvincible(ped,false)
        SetEntityVisible(ped,true,false)
        noclip = false
    end
end

getCamDirect = function()
	local heading = GetGameplayCamRelativeHeading()+GetEntityHeading(PlayerPedId())
	local pitch = GetGameplayCamRelativePitch()
	local x = -math.sin(heading*math.pi/180.0)
	local y = math.cos(heading*math.pi/180.0)
	local z = math.sin(pitch*math.pi/180.0)
	local len = math.sqrt(x*x+y*y+z*z)
	if len ~= 0 then
		x = x/len
		y = y/len
		z = z/len
	end
	return x,y,z
end

RotationToDirection = function(rotation)
    local adjustedRotation = { 
        x = (math.pi / 180) * rotation.x, 
        y = (math.pi / 180) * rotation.y, 
        z = (math.pi / 180) * rotation.z 
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

RayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = { 
        x = cameraCoord.x + direction.x * distance, 
        y = cameraCoord.y + direction.y * distance, 
        z = cameraCoord.z + direction.z * distance 
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
    return b, c
end
