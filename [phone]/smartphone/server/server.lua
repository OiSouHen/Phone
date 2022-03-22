-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("smartphone",cRP)
vCLIENT = Tunnel.getInterface("smartphone")
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE
-----------------------------------------------------------------------------------------------------------------------------------------
vRP.prepare("smartphone/remMessageId","DELETE FROM phone_messages WHERE id = @id")
vRP.prepare("smartphone/getChatMessagesId","SELECT * FROM phone_chat ORDER BY id DESC")
vRP.prepare("smartphone/cleanPhoneCallbyOwner","DELETE FROM phone_calls WHERE owner = @owner")
vRP.prepare("smartphone/remAllMessage","DELETE FROM phone_messages WHERE receiver = @receiver")
vRP.prepare("smartphone/getPhoneContacts","SELECT * FROM phone_contacts WHERE identifier = @identifier")
vRP.prepare("smartphone/remAllPhoneContacts","DELETE FROM phone_contacts WHERE identifier = @identifier")
vRP.prepare("smartphone/removeCallDays","DELETE FROM phone_calls WHERE (DATEDIFF(CURRENT_DATE,time) > 3)")
vRP.prepare("smartphone/addChatMessages","INSERT INTO phone_chat(channel,message) VALUES(@channel,@message)")
vRP.prepare("smartphone/cleanPhoneCallsbyNumber","DELETE FROM phone_calls WHERE owner = @owner AND num = @num")
vRP.prepare("smartphone/removeMessageDays","DELETE FROM phone_messages WHERE (DATEDIFF(CURRENT_DATE,time) > 3)")
vRP.prepare("smartphone/remPhoneContacts","DELETE FROM phone_contacts WHERE id = @id AND identifier = @identifier")
vRP.prepare("smartphone/getHistoryCalls","SELECT * FROM phone_calls WHERE owner = @owner ORDER BY time DESC LIMIT 20")
vRP.prepare("smartphone/getChatMessages","SELECT * FROM phone_chat WHERE channel = @channel ORDER BY time DESC LIMIT 30")
vRP.prepare("smartphone/updatePhoneContacts","UPDATE phone_contacts SET number = @number, display = @display WHERE id = @id")
vRP.prepare("smartphone/remMessageNumber","DELETE FROM phone_messages WHERE receiver = @receiver AND transmitter = @transmitter")
vRP.prepare("smartphone/insertPhoneCalls","INSERT INTO phone_calls(owner,num,incoming,accepts) VALUES(@owner,@num,@incoming,@accepts)")
vRP.prepare("smartphone/addPhoneContacts","INSERT INTO phone_contacts(identifier,number,display) VALUES(@identifier,@number,@display)")
vRP.prepare("smartphone/updateReadMessage","UPDATE phone_messages SET isRead = 1 WHERE receiver = @receiver AND transmitter = @transmitter")
vRP.prepare("smartphone/getPhoneMessagesId","SELECT * FROM phone_messages WHERE transmitter = @transmitter AND receiver = receiver ORDER BY id DESC LIMIT 1")
vRP.prepare("smartphone/insertPhoneMessages","INSERT INTO phone_messages(transmitter,receiver,message,isRead,owner) VALUES(@transmitter,@receiver,@message,@owner,@owner)")
vRP.prepare("smartphone/getPhoneMessages","SELECT phone_messages.* FROM phone_messages LEFT JOIN summerz_characters ON summerz_characters.id = @identifier WHERE phone_messages.receiver = summerz_characters.phone")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local userPhones = {}
local phoneEncoders = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKPHONE
-----------------------------------------------------------------------------------------------------------------------------------------
function cRP.checkPhone()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local consultPhone = vRP.getInventoryItemAmount(user_id,"cellphone")
		if consultPhone[1] <= 0 then
			TriggerClientEvent("Notify",source,"amarelo","Precisa de <b>1x "..itemName("cellphone").."</b>.",5000)
			return false
		end

		if vRP.checkBroken(consultPhone[2]) then
			TriggerClientEvent("Notify",source,"vermelho","<b>"..itemName("cellphone").."</b> descarregado.",5000)
			return false
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NOTIFYCONTACTCHANGE
-----------------------------------------------------------------------------------------------------------------------------------------
function notifyContactChange(source,user_id)
	local myContacts = vRP.query("smartphone/getPhoneContacts",{ identifier = parseInt(user_id) })
	TriggerClientEvent("Smartphone:contactList",source,myContacts)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDCONTACT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:addContact")
AddEventHandler("Smartphone:addContact",function(display,phoneNumber)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/addPhoneContacts",{ identifier = parseInt(user_id), number = phoneNumber, display = display })
		notifyContactChange(source,user_id)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATECONTACT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:updateContact")
AddEventHandler("Smartphone:updateContact",function(id,display,phoneNumber)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/updatePhoneContacts",{ number = phoneNumber, display = display, id = id })
		notifyContactChange(source,user_id)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETECONTACT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:deleteContact")
AddEventHandler("Smartphone:deleteContact",function(id)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/remPhoneContacts",{ id = id, identifier = parseInt(user_id) })
		notifyContactChange(source,user_id)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:sendMessage")
AddEventHandler("Smartphone:sendMessage",function(phoneNumber,message)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id and phoneNumber ~= nil then
		vRP.execute("smartphone/insertPhoneMessages",{ transmitter = userPhones[tostring(user_id)], receiver = phoneNumber, message = message, owner = 0 })
		local nuser_id = vRP.userPhone(phoneNumber)
		if nuser_id then
			local otherPlayer = vRP.userSource(nuser_id)
			if otherPlayer then
				local consult = vRP.query("smartphone/getPhoneMessagesId",{ transmitter = userPhones[tostring(user_id)], receiver = phoneNumber })
				TriggerClientEvent("Smartphone:receiveMessage",otherPlayer,consult[1])
			end
		end

		vRP.execute("smartphone/insertPhoneMessages",{ transmitter = phoneNumber, receiver = userPhones[tostring(user_id)], message = message, owner = 1 })
		local consult = vRP.query("smartphone/getPhoneMessagesId",{ transmitter = phoneNumber, receiver = userPhones[tostring(user_id)] })
		TriggerClientEvent("Smartphone:receiveMessage",source,consult[1])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:deleteMessage")
AddEventHandler("Smartphone:deleteMessage",function(msgId)
	vRP.execute("smartphone/remMessageId",{ id = parseInt(msgId) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEMESSAGENUMBER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:deleteMessageNumber")
AddEventHandler("Smartphone:deleteMessageNumber",function(phoneNumber)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/remMessageNumber",{ receiver = userPhones[tostring(user_id)], transmitter = phoneNumber })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETEALLMESSAGE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:deleteAllMessage")
AddEventHandler("Smartphone:deleteAllMessage",function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/remAllMessage",{ receiver = userPhones[tostring(user_id)] })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETREADMESSAGENUMBER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:setReadMessageNumber")
AddEventHandler("Smartphone:setReadMessageNumber",function(phoneNumber)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/updateReadMessage",{ receiver = userPhones[tostring(user_id)], transmitter = phoneNumber })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:DELETEALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:deleteALL")
AddEventHandler("Smartphone:deleteALL",function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		TriggerClientEvent("Smartphone:allMessage",source,{})
		TriggerClientEvent("Smartphone:contactList",source,{})
		TriggerClientEvent("appelsDeleteAllHistorique",source,{})
		vRP.execute("smartphone/remAllPhoneContacts",{ identifier = parseInt(user_id) })
		vRP.execute("smartphone/remAllMessage",{ receiver = userPhones[tostring(user_id)] })
		vRP.execute("smartphone/cleanPhoneCallbyOwner",{ owner = userPhones[tostring(user_id)] })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDHISTORIQUECALL
-----------------------------------------------------------------------------------------------------------------------------------------
function sendHistoriqueCall(source,phoneNumber)
	local history = vRP.query("smartphone/getHistoryCalls",{ owner = phoneNumber })
	if history ~= nil then
		TriggerClientEvent("Smartphone:historiqueCall",source,history)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVECALLINGS
-----------------------------------------------------------------------------------------------------------------------------------------
function saveCallings(phoneInfos)
	if phoneInfos["extraData"] == nil then
		vRP.execute("smartphone/insertPhoneCalls",{ owner = phoneInfos["transmitter_num"], num = phoneInfos["receiver_num"], incoming = 1, accepts = phoneInfos["is_accepts"] })
		sendHistoriqueCall(phoneInfos["transmitter_src"],phoneInfos["transmitter_num"])
	end

	if phoneInfos["is_valid"] then
		local num = phoneInfos["transmitter_num"]
		if phoneInfos["hidden"] then
			num = "####-####"
		end

		vRP.execute("smartphone/insertPhoneCalls",{ owner = phoneInfos["receiver_num"], num = num, incoming = 0, accepts = phoneInfos["is_accepts"] })
		sendHistoriqueCall(phoneInfos["receiver_src"],phoneInfos["receiver_num"])
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:GETHISTORIQUECALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:getHistoriqueCall")
AddEventHandler("Smartphone:getHistoriqueCall",function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		sendHistoriqueCall(source,userPhones[tostring(user_id)])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTCALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:startCall")
AddEventHandler("Smartphone:startCall",function(phoneNumber,rtcOffer,extraData)
	if phoneNumber == nil or phoneNumber == "" then
		return
	end

	local hidden = string.sub(phoneNumber,1,1)
	if hidden == "#" then
		phoneNumber = string.sub(phoneNumber,2)
	end

	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local nuser_id = vRP.userPhone(phoneNumber)
		if nuser_id and userPhones[tostring(user_id)] ~= phoneNumber then
			local otherPlayer = vRP.userSource(nuser_id)
			if otherPlayer then
				local indexCall = parseInt(1500 + user_id)
				phoneEncoders[indexCall] = { id = indexCall, transmitter_src = source, transmitter_num = userPhones[tostring(user_id)], receiver_src = otherPlayer, receiver_num = phoneNumber, is_valid = otherPlayer, is_accepts = false, hidden = hidden, rtcOffer = rtcOffer, extraData = extraData }

				TriggerClientEvent("Smartphone:waitingCall",source,phoneEncoders[indexCall],true)
				TriggerClientEvent("Smartphone:waitingCall",otherPlayer,phoneEncoders[indexCall],false)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:CANDIDATES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:candidates")
AddEventHandler("Smartphone:candidates",function(callId,candidates)
	local source = source

	if phoneEncoders[callId] ~= nil then
		local otherPlayer = phoneEncoders[callId]["transmitter_src"]
		if source == otherPlayer then 
			otherPlayer = phoneEncoders[callId]["receiver_src"]
		end

		TriggerClientEvent("Smartphone:candidates",otherPlayer,candidates)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:ACCEPTCALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:acceptCall")
AddEventHandler("Smartphone:acceptCall",function(infoCall,rtcAnswer)
	local id = infoCall["id"]

	if phoneEncoders[id] ~= nil then
		phoneEncoders[id]["receiver_src"] = infoCall["receiver_src"] or phoneEncoders[id]["receiver_src"]

		if phoneEncoders[id]["transmitter_src"] ~= nil and phoneEncoders[id]["receiver_src"] ~= nil then
			phoneEncoders[id]["is_accepts"] = true
			phoneEncoders[id]["rtcAnswer"] = rtcAnswer
			TriggerClientEvent("Smartphone:acceptCall",phoneEncoders[id]["transmitter_src"],phoneEncoders[id],true)
			TriggerClientEvent("Smartphone:acceptCall",phoneEncoders[id]["receiver_src"],phoneEncoders[id],false)
			saveCallings(phoneEncoders[id])
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:REJECTCALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:rejectCall")
AddEventHandler("Smartphone:rejectCall",function(infoCall)
	local id = infoCall["id"]
	if phoneEncoders[id] ~= nil then
		if phoneEncoders[id]["transmitter_src"] ~= nil then
			TriggerClientEvent("Smartphone:rejectCall",phoneEncoders[id]["transmitter_src"])
		end

		if phoneEncoders[id]["receiver_src"] ~= nil then
			TriggerClientEvent("Smartphone:rejectCall",phoneEncoders[id]["receiver_src"])
		end

		if not phoneEncoders[id]["is_accepts"] then
			saveCallings(phoneEncoders[id])
		end

		TriggerEvent("Smartphone:removeCall",phoneEncoders)
		phoneEncoders[id] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:APPELSDELETEHISTORIQUE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:appelsDeleteHistorique")
AddEventHandler("Smartphone:appelsDeleteHistorique",function(phoneNumber)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/cleanPhoneCallsbyNumber",{ owner = userPhones[tostring(user_id)], num = phoneNumber })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:APPELSDELETEALLHISTORIQUE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:appelsDeleteAllHistorique")
AddEventHandler("Smartphone:appelsDeleteAllHistorique",function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.execute("smartphone/cleanPhoneCallbyOwner",{ owner = userPhones[tostring(user_id)] })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERSPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerSpawn",function(user_id,source)
	local identity = vRP.userIdentity(user_id)
	if identity then
		userPhones[tostring(user_id)] = identity["phone"]

		TriggerClientEvent("Smartphone:myPhoneNumber",source,userPhones[tostring(user_id)])
		sendHistoriqueCall(source,userPhones[tostring(user_id)])

		local myContats = vRP.query("smartphone/getPhoneContacts",{ identifier = parseInt(user_id) })
		TriggerClientEvent("Smartphone:contactList",source,myContats)

		local myMessages = vRP.query("smartphone/getPhoneMessages",{ identifier = parseInt(user_id) })
		TriggerClientEvent("Smartphone:allMessage",source,myMessages)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GCPHONE:ALLUPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("Smartphone:allUpdate")
AddEventHandler("Smartphone:allUpdate",function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local identity = vRP.userIdentity(user_id)
		if identity then
			userPhones[tostring(user_id)] = identity["phone"]

			TriggerClientEvent("Smartphone:myPhoneNumber",source,userPhones[tostring(user_id)])
			sendHistoriqueCall(source,userPhones[tostring(user_id)])

			local myContats = vRP.query("smartphone/getPhoneContacts",{ identifier = parseInt(user_id) })
			TriggerClientEvent("Smartphone:contactList",source,myContats)

			local myMessages = vRP.query("smartphone/getPhoneMessages",{ identifier = parseInt(user_id) })
			TriggerClientEvent("Smartphone:allMessage",source,myMessages)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERLEAVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerLeave",function(user_id,source)
	if userPhones[tostring(user_id)] then
		userPhones[tostring(user_id)] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADREMOVEDAYS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	vRP.execute("smartphone/removeCallDays")
	vRP.execute("smartphone/removeMessageDays")
end)