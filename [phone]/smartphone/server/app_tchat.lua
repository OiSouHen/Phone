function TchatGetMessageChannel(channel,cb)
	local consult = vRP.query("smartphone/getChatMessages",{ channel = channel })
	return consult
end

function TchatAddMessage(channel,message)
	vRP.execute("smartphone/addChatMessages",{ channel = channel, message = message })

	local consult = vRP.query("smartphone/getChatMessagesId",{ channel = channel })
	TriggerClientEvent("Smartphone:tchat_receive",-1,consult[1])
end

RegisterServerEvent("Smartphone:tchat_channel")
AddEventHandler("Smartphone:tchat_channel",function(channel)
	local source = source
	local consult = vRP.query("smartphone/getChatMessages",{ channel = channel })
	TriggerClientEvent("Smartphone:tchat_channel",source,channel,consult)
end)

RegisterServerEvent("Smartphone:tchat_addMessage")
AddEventHandler("Smartphone:tchat_addMessage",function(channel,message)
	TchatAddMessage(channel,message)
end)