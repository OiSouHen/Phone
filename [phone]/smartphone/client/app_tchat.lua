RegisterNetEvent("Smartphone:tchat_receive")
AddEventHandler("Smartphone:tchat_receive",function(message)
	SendNUIMessage({ event = "tchat_receive", message = message })
end)

RegisterNetEvent("Smartphone:tchat_channel")
AddEventHandler("Smartphone:tchat_channel",function(channel,messages)
	SendNUIMessage({ event = "tchat_channel", messages = messages })
end)

RegisterNUICallback("tchat_addMessage",function(data,cb)
	TriggerServerEvent("Smartphone:tchat_addMessage",data["channel"],data["message"])
end)

RegisterNUICallback("tchat_getChannel",function(data,cb)
	TriggerServerEvent("Smartphone:tchat_channel",data["channel"])
end)