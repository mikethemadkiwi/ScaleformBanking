function SetCurrencyValues(pSrc, TransactionBankResult, TransactionCashResult)
	-- EDIT THIS TO SENT YOUR BANKING INFOR TO WHERE IT NEEDS TO BE UPDATED
	----
	TriggerEvent('mkstats:client:setbank', {pSrc, TransactionBankResult})
	TriggerEvent('mkstats:client:setcash', {pSrc, TransactionCashResult})
	----
end
----
Strip_Control_and_Extended_Codes = function( str )
	local s = ""
	for i = 1, str:len() do
		if str:byte(i) >= 32 and str:byte(i) <= 126 then
			s = s .. str:sub(i,i)
		end
	end
	return s
 end
----
 Strip_Control_Codes = function( str )
	local s = ""
	for i in str:gmatch( "%C+" ) do
		 s = s .. i
	end
	return s
 end
----
getUserIdentifiers = function(source)
	local name = GetPlayerName(source)
	local firstStrip = Strip_Control_Codes(name)
	local stripName = Strip_Control_and_Extended_Codes(firstStrip)
	local ids = {}  
	ids.fivem = nil
	ids.steam  = nil
	ids.license  = nil
	ids.discord  = nil
	ids.xbl      = nil
	ids.live   = nil
	ids.ip       = nil
	ids.other = {}
	ids.lastlogin = os.time()
	ids.name = stripName
	for k,v in pairs(GetPlayerIdentifiers(source))do  
		if string.sub(v, 1, string.len("steam:")) == "steam:" then
			ids.steam = v      
		elseif string.sub(v, 1, string.len("fivem:")) == "fivem:" then
			ids.fivem = v
		elseif string.sub(v, 1, string.len("license:")) == "license:" then
			ids.license = v
		elseif string.sub(v, 1, string.len("license2:")) == "license2:" then
			ids.license2 = v
		elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
			ids.xbl  = v
		elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
			ids.ip = v
		elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
			ids.discord = v
		elseif string.sub(v, 1, string.len("live:")) == "live:" then
			ids.live = v
		else
			table.insert(ids.other, v)
		end    
	end
	return ids
 end
----
 function FetchUserUUID(playerIds)
    local tmpUUID = MySQL.query.await('SELECT * FROM `_mkAccount` WHERE `license` = ?', { playerIds.license })
    return tmpUUID[1].current_player
end
----
RegisterNetEvent('mkATM:Transaction')
AddEventHandler('mkATM:Transaction', function(mkTransactionAmount, mkIsWithdrawal)
    local pSrc = source
    local userIDs = getUserIdentifiers(pSrc)
    local userUUID = FetchUserUUID(userIDs)		
	MySQL.ready(function()
	    MySQL.Async.fetchAll('SELECT * FROM _mkPlayer WHERE uuid = ?', { userUUID }, function(result)
			if(mkIsWithdrawal) then
				local TransactionBankResult = result[1]['bank'] - mkTransactionAmount
				local TransactionCashResult = result[1]['cash'] + mkTransactionAmount
				if(TransactionBankResult >= 0) then
					SetCurrencyValues(pSrc, TransactionBankResult, TransactionCashResult)
					Citizen.Wait(1000)
					if(mkTransactionAmount>0) then
						local Transaction  = CreateTransaction(userUUID, 'Cash Withdrawn', -mkTransactionAmount, GetFormattedTime())
						TriggerClientEvent('mkATM:TransactionSuccess', pSrc, TransactionBankResult, TransactionCashResult, json.encode(Transaction))
					else
						TriggerClientEvent('mkATM:TransactionSuccess', pSrc, TransactionBankResult, TransactionCashResult)
					end
				end
			else
				local TransactionBankResult = result[1]['bank'] + mkTransactionAmount
				local TransactionCashResult = result[1]['cash'] - mkTransactionAmount
				if(TransactionCashResult >= 0) then
					SetCurrencyValues(pSrc, TransactionBankResult, TransactionCashResult)
					Citizen.Wait(1000)
					if(mkTransactionAmount>0) then
						local Transaction = CreateTransaction(userUUID, 'Cash Deposited', mkTransactionAmount, GetFormattedTime())
						TriggerClientEvent('mkATM:TransactionSuccess', pSrc, TransactionBankResult, TransactionCashResult, json.encode(Transaction))
					else
						TriggerClientEvent('mkATM:TransactionSuccess', pSrc, TransactionBankResult, TransactionCashResult)
					end
				end
			end
		end)
	end)
end)
----
RegisterNetEvent('mkATM:StartATM')
AddEventHandler('mkATM:StartATM', function()
    local pSrc = source
    local userIDs = getUserIdentifiers(pSrc)
    local userUUID = FetchUserUUID(userIDs)

	MySQL.ready(function()
		local Transactions = {}
		MySQL.Async.fetchAll('SELECT * FROM `mkcashTransLog` WHERE player = @userUUID', { -- this may need to be clamped to limit 100
			['@userUUID'] = userUUID 
		}, function(result)
			for k,v in pairs(result) do
				Transactions[k] = v
			end
			TriggerClientEvent('mkATM:SetTransactions', pSrc, json.encode(Transactions))
		end)
	end)
end)
----
function CreateTransaction(uuid, Reason, Amount, Date)
	MySQL.ready(function()
		MySQL.Async.execute('INSERT INTO `mkcashTransLog` (player, reason, amount, date) VALUES (@uuid, @Reason, @Amount, @Date)', {
			['uuid'] = uuid,
			['Reason'] = Reason,
			['Amount'] = Amount,
			['Date'] = Date
		})
	end)

	return {
		['player'] = uuid,
		['reason'] = Reason,
		['amount'] = math.abs(Amount),
		['date'] = Date
	}
end
----
function GetFormattedTime()
	TimeTable = os.date('*t')
	local Day = '01'
	local Month  = '01'
	local Year = '1900'
	if(string.len(''..TimeTable['day']) == 1) then
		Day = '0'..TimeTable['day']
	else
		Day = TimeTable['day']
	end

	if(string.len(''..TimeTable['month']) == 1) then
		Month = '0'..TimeTable['month']
	else
		Month = TimeTable['month']
	end

	return ''..Month..'/'..Day..'/'..TimeTable['year']
end