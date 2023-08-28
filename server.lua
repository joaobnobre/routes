bfm = {}
Tunnel.bindInterface(GetCurrentResourceName(), bfm)
cbfm = Tunnel.getInterface(GetCurrentResourceName())

local s,n = Notifys['Success'],Notifys['Denied']

local routeLobbys = {}

-- Funções Main
bfm.sendServerInviteToGroup = function(srcToInvite)
    local inviterSrc = source
    local inviterName = getUserNameByIdentity(inviterSrc)
    local inviterId = getUserId(inviterSrc)
    if srcToInvite and inviterName and inviterId then
        TriggerClientEvent('receiveInviteClient', srcToInvite, inviterName,inviterId,inviterSrc)
        return true
    end
end

RegisterServerEvent('clientInviteResponse')
AddEventHandler('clientInviteResponse', function(inviteResponse,inviterName,inviterId,inviterSrc)
    local responseSrc = source
    if inviteResponse then
        if not routeLobbys[inviterSrc] then
            routeLobbys[inviterSrc] = {responseSrc}
        else
            table.insert(routeLobbys[inviterSrc],responseSrc)
        end
        TriggerClientEvent('reiceiveFinalResponseFromInvite', inviterSrc, inviteResponse,responseSrc,routeLobbys[inviterSrc])
    else
        TriggerClientEvent('reiceiveFinalResponseFromInvite', inviterSrc, inviteResponse,responseSrc)
    end
end)

RegisterServerEvent('desyncLobby')
AddEventHandler('desyncLobby', function()
    local _s = source
    if routeLobbys[_s] then
        for k,v in next,routeLobbys[_s] do
            TriggerClientEvent('desyncFromLobby', tonumber(v))
        end
        routeLobbys[_s] = nil
    end
end)

RegisterServerEvent('syncRouteLobbyBeginning')
AddEventHandler('syncRouteLobbyBeginning', function(routeId,routeTypes,routeItems)
    local inviterSrc = source
    if routeLobbys[inviterSrc] then
        for k,v in next,routeLobbys[inviterSrc] do
            TriggerClientEvent('beginRouteLobby', tonumber(v), routeId,routeTypes,routeItems,routeLobbys[inviterSrc])
        end
    end
end)

desyncFromRunningLobbySvRequest = function()
    local _s = source
    if routeLobbys[_s] then
        for k,v in next,routeLobbys[_s] do
            TriggerClientEvent('desyncFromRunningLobby', tonumber(v))
        end
        routeLobbys[_s] = nil
    end
end
RegisterServerEvent('desyncFromRunningLobbySvRequest')
AddEventHandler('desyncFromRunningLobbySvRequest', desyncFromRunningLobbySvRequest)

findOwnerSrc = function(invitedSrc)
    for k,v in next,routeLobbys do
        for _,w in next,routeLobbys[tonumber(k)] do
            if tonumber(invitedSrc) == tonumber(w) then
                return tonumber(_)
            end
        end
    end
end

desyncPlayerFromGroupSvRequest = function()
    local _s = source
    local groupOwnerSrc = findOwnerSrc(_s)
    if groupOwnerSrc then
        for k,v in next,routeLobbys[groupOwnerSrc] do
            if v == _s then
                routeLobbys[groupOwnerSrc][k] = nil
            end
        end

        for k,v in next,routeLobbys[groupOwnerSrc] do
            TriggerClientEvent('desyncPlayerFromGroupResponse', tonumber(v), _s,routeLobbys[groupOwnerSrc])
        end
    end
end
RegisterServerEvent('desyncPlayerFromGroupSvRequest')
AddEventHandler('desyncPlayerFromGroupSvRequest', desyncPlayerFromGroupSvRequest)

bfm.serverSideCheck = function(routeId)
    local _source = source
    return beforeRouteChecks(_source,routeId)
end

bfm.routePaycheck = function(routeId,routeTypes,routeItems,antiEulen)
    local _source = source
    if routeId and routeTypes and routeItems and antiEulen then
        local genRoute,pedPos = antiEulen[1],antiEulen[2]
        local distanceFromPaymentLocal = #(pedPos - vec3(Config.routes[routeId].routeLocations[genRoute][1],Config.routes[routeId].routeLocations[genRoute][2],Config.routes[routeId].routeLocations[genRoute][3]))
        if distanceFromPaymentLocal < 3.733 then
            if routeTypes[1] == 0 then
                receivableRoutePayment(_source,routeId,routeItems)
            elseif routeTypes[1] == 1 then
                deliverableRoutePayment(_source,routeId,routeItems)
            end
        end
    end
end

-- Funções Suporte
bfm.getUserName = function(_s)
    local name = getUserNameByIdentity(_s)
    return name
end

idealizeItemAmountOnPayment = function(item,routeItemsAmount,routeId)
    local idealAmount,idealValue
    local minAmount,maxAmount = Config.routes[routeId].deliverableItems[item][1],Config.routes[routeId].deliverableItems[item][2]
    local minValue,maxValue = Config.routes[routeId].deliverableItems[item][3],Config.routes[routeId].deliverableItems[item][4]
    if routeItemsAmount <= 3 then
        idealAmount = math.random(minAmount,maxAmount)
        idealValue = math.random(minValue,maxValue)
    elseif routeItemsAmount >= 4 then
        if minAmount == 1 then minAmount = minAmount + 1 end
        idealAmount = math.random(1,minAmount)
        idealValue = math.floor((math.random(minValue,maxValue))/1.5)
    end
    return idealAmount,idealValue*idealAmount
end

idealizeItemAmountOnReceive = function(item,routeItemsAmount,routeId)
    local idealValue
    local minValue,maxValue = Config.routes[routeId].receivableItems[item][1],Config.routes[routeId].receivableItems[item][2]
    if routeItemsAmount <= 3 then 
        idealValue = math.random(minValue,maxValue)
    elseif routeItemsAmount > 3 and routeItemsAmount <= 5 then 
        if minValue == 1 then minValue = minValue + 1 end
        idealValue = math.random(1,minValue)
    elseif routeItemsAmount > 5 then
        idealValue = minValue
    end
    return idealValue
end

-- RouteTools Stuff
local saveNewRouteFirstPos

bfm.offServer = function()
    local source = source
    local routes,actual,markerId = cbfm.offIt(source)
    if actual >= 2 then
        s('Setagem de rotas finalizada! Verifique o arquivo no diretório escolhido.',7337,source)
        
        local certainTable = genNewConfigUpdate(routes,saveNewRouteFirstPos)
        local path = string.gsub(GetResourcePath(GetCurrentResourceName())..'/config.lua','/',[[\]])
        local file = io.open(path, "w")
        file:write(certainTable)
        file:close()
        file = nil
        saveNewRouteFirstPos = nil
        TriggerClientEvent('reloadConfigRoutes', -1, Config.routes)
    else
        n('Você não atingiu o número mínimo de rotas (2) para que um arquivo fosse criado.',7337,source)
    end
end

genNewConfigUpdate = function(routeLocationsArray,startRoute)
    local path = string.gsub(GetResourcePath(GetCurrentResourceName())..'/config.lua','/',[[\]])
    local file = io.open(path, "r")
    local readt = string.sub(file:read("*all"), 0, -2)
    
readt = readt..[[

    []]..(#Config.routes+1)..[[] = {
        ['startRoute'] = { ]]..startRoute[1]..','..startRoute[2]..','..startRoute[3]..[[ },

        ['permissions'] = {
            'exemplo.permissao',
        },

        ['randomRoutes'] = false,

        ['routeLocations'] = { ]]
        for k,v in next,routeLocationsArray do
            readt = readt..[[

            []]..k..'] = { '..v[1]..', '..v[2]..', '..v[3]..' }, '
        end
        
        readt = readt..[[

        },

        ['receivableItems'] = {
            ['exemplo'] = { 2,7 },
        },

        ['deliverableItems'] = {
            ['exemplo'] = { 2,7 },
        },
        
        ['receiveDirtMoneyOnDelivery'] = true,
    },
}]]
file:close()

table.insert(Config.routes, {
    ['startRoute'] = { startRoute[1],startRoute[2],startRoute[3] },

    ['permissions'] = {
        'exemplo.permissao',
    },

    ['randomRoutes'] = false,

    ['routeLocations'] = routeLocationsArray,

    ['receivableItems'] = {
        ['exemplo'] = { 2,7 },
    },

    ['deliverableItems'] = {
        ['exemplo'] = { 2,7 },
    },
    
    ['receiveDirtMoneyOnDelivery'] = true,
})
return readt
end

cmdFunc = function(source,args)
    if cbfm.getCVar(source) then
        local routes,actual,markerId = cbfm.offIt(source)
        if actual >= 2 then
            s('Setagem de rotas finalizada! Verifique o arquivo no diretório escolhido.',7337,source)
            
            local certainTable = genNewConfigUpdate(routes,saveNewRouteFirstPos)
            local path = string.gsub(GetResourcePath(GetCurrentResourceName())..'/config.lua','/',[[\]])
            local file = io.open(path, "w")
            file:write(certainTable)
            file:close()
            file = nil
            saveNewRouteFirstPos = nil
        else
            n('Você não atingiu o número mínimo de rotas (2) para que um arquivo fosse criado.',7337,source)
        end
    else
        cbfm.onIt(source)
        saveNewRouteFirstPos = cbfm.getPosition(source)
    end
end
RegisterCommand('setrota', cmdFunc)