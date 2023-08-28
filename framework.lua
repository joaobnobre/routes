-- Framework Functions
vRP = Proxy.getInterface('vRP')

getUserId = function(playerSrc)
    return vRP.getUserId(playerSrc)
end

getUserIdentity = function(playerSrc)
    return vRP.getUserIdentity(getUserId(playerSrc))
end

hasPermission = function(playerSrc,permission)
    return vRP.hasPermission(getUserId(playerSrc),permission)
end

giveInvItem = function(playerSrc,item,amount)
    vRP.giveInventoryItem(getUserId(playerSrc),item,amount)
end

tryGetInvItem = function(playerSrc, item, amount)
    return vRP.tryGetInventoryItem(getUserId(playerSrc), item, amount)
end

giveMoney = function(playerSrc,amount)
    vRP.giveMoney(getUserId(playerSrc),amount)
end

-- Server Functions
getUserNameByIdentity = function(playerSrc) 
    local identity = getUserIdentity(playerSrc)
    local name,fname = identity.name,identity.firstname
    return name..' '..fname
end

beforeRouteChecks = function(playerSrc,routeId)
    if #Config['routes'][routeId]['permissions'] >= 1 then
        for key,permission in next,Config['routes'][routeId]['permissions'] do
            if hasPermission(playerSrc,permission) then
                return true
            end
        end
    else
        return true
    end
end

receivableRoutePayment = function(playerSrc,routeId,routeItems)
    for key,item in next,routeItems do
        local idealAmount = idealizeItemAmountOnReceive(item,#routeItems,routeId)
        giveInvItem(playerSrc,item,idealAmount)
        Notifys.Success('Você coletou x'..idealAmount..' '..item..'!',7331,playerSrc)
    end
end

deliverableRoutePayment = function(playerSrc,routeId,routeItems)
    for key,item in next,routeItems do
        local idealAmount,idealValue = idealizeItemAmountOnPayment(item,#routeItems,routeId)
        if tryGetInvItem(playerSrc,item,idealAmount) then
            if Config.routes[routeId].receiveDirtMoneyOnDelivery then
                giveInvItem(playerSrc,Config.dirtMoneyItem,idealValue)
                Notifys.Success('Você recebeu R$'..idealValue..' sujo por x'..idealAmount..' '..item..'!',7331,playerSrc)
            else
                giveMoney(playerSrc,idealValue)
                Notifys.Success('Você recebeu R$'..idealValue..' por x'..idealAmount..' '..item..'!',7331,playerSrc)
            end
        else
            Notifys.Denied('Você não possui x'..idealAmount..' '..item..' para entregar!',7331,playerSrc)
        end
    end
end

-- Client functions
function getPosition()
	local x,y,z = table.unpack(GetEntityCoords(PlayerPedId(),true))
	return x,y,z
end

function getNearestPlayers(radius)
	local r = {}
	local pid = PlayerId()
	local px,py,pz = getPosition()

	for k,player in ipairs(GetActivePlayers()) do
		if player ~= pid and NetworkIsPlayerConnected(player) then
			local oped = GetPlayerPed(player)
			local x,y,z = table.unpack(GetEntityCoords(oped,true))
            local distance = #(vec3(x,y,z) - vec3(px,py,pz))
			if distance <= radius then
                local s = GetPlayerServerId(player)
                local n = bfm.getUserName(s)
                table.insert(r, {s,n})
			end
		end
	end
	return r
end

local anims = {}
local anim_ids = Tools.newIDGenerator()

stopAnim = function(upper)
	anims = {}
	if upper then
		ClearPedSecondaryTask(PlayerPedId())
	else
		ClearPedTasks(PlayerPedId())
	end
end

playAnim = function(upper,seq,looping)
	stopAnim(upper)

	local flags = 0
	if upper then flags = flags+48 end
	if looping then flags = flags+1 end

	CreateThread(function()
		local id = anim_ids:gen()
		anims[id] = true

		for k,v in next,seq do
			local dict = v[1]
			local name = v[2]
			local loops = v[3] or 1

			for i=1,loops do
				if anims[id] then
					local first = (k == 1 and i == 1)
					local last = (k == #seq and i == loops)

					RequestAnimDict(dict)
					local i = 0
					while not HasAnimDictLoaded(dict) and i < 1000 do
					Wait(10)
					RequestAnimDict(dict)
					i = i + 1
				end

				if HasAnimDictLoaded(dict) and anims[id] then
					local inspeed = 3.0
					local outspeed = -3.0
					if not first then inspeed = 2.0 end
					if not last then outspeed = 2.0 end

					TaskPlayAnim(PlayerPedId(),dict,name,inspeed,outspeed,-1,flags,0,0,0,0)
				end
					Wait(1)
					while GetEntityAnimCurrentTime(PlayerPedId(),dict,name) <= 0.95 and IsEntityPlayingAnim(PlayerPedId(),dict,name,3) and anims[id] do
						Wait(1)
					end
				end
			end
		end
		anim_ids:free(id)
		anims[id] = nil
	end)
end

screenTxt = function(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

-- Notify Section
Notifys = {
    Success = function(message,time,playerSource)
        if SERVER and playerSource then
            TriggerClientEvent('Notify', playerSource, 'sucesso', message, time)
        else
            TriggerEvent('Notify', 'sucesso', message, time)
        end
    end,
    Denied = function(message,time,playerSource)
        if SERVER and playerSource then
            TriggerClientEvent('Notify', playerSource, 'negado', message, time)
        else
            TriggerEvent('Notify', 'negado', message, time)
        end
    end,
}