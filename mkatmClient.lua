local mkPlayerBank = 0
local mkPlayerCash = 0
local mkTransactions = {}

local Scaleform = nil
local mkScaleformID = 'ATM'

local mkUsingATM = false
local mkNearATM = false

local mkLastTransactionWasWithdrawal = false;
local mkLastTransactionAmount = 0;

local mkButtonParams = {}

local mkCurrentATM = 0
local mkCurrentScreen = 0

local mkAwaitingResult = false
local mkReturnScaleform = 0

mkATMHashes = {
	[0] = -1126237515,
	[1] = -1364697528,
	[2] = 506770882,
	[3] = -870868698
}

function SetBankingInfo() 
	-- edit this to fetch your own cash and baning information. mine is set uysing native statInt values.
	----
	local retval2, BANK_BALANCE = StatGetInt(`BANK_BALANCE`, -1)
	local retval1, MP0_WALLET_BALANCE = StatGetInt(`MP0_WALLET_BALANCE`, -1)
	----
	mkPlayerBank = BANK_BALANCE
	mkPlayerCash = MP0_WALLET_BALANCE
	----
end

AddEventHandler('onClientResourceStart', function(resourceName) 
	if(GetCurrentResourceName() == resourceName) then
		TriggerServerEvent('mkATM:StartATM')
	end
end)

RegisterNetEvent('mkATM:TransactionSuccess')
AddEventHandler('mkATM:TransactionSuccess', function(mkBankAmount, mkCashAmount, mkTransactionJSON)
	SetBankingInfo()
	if(mkTransactionJSON) then
		local DecodedTransaction = json.decode(mkTransactionJSON)
		table.insert(mkTransactions, DecodedTransaction)
	end

	if(Scaleform~=nil) then
		mkOpenTransactionComplete()
	end
end)

RegisterNetEvent('mkATM:SetTransactions')
AddEventHandler('mkATM:SetTransactions', function(mkTransactionsJSON)
	local DecodedTransactions = json.decode(mkTransactionsJSON)
	mkTransactions = DecodedTransactions
end)

RegisterNetEvent('mkATM:SetMoney')
AddEventHandler('mkATM:SetMoney', function(mkBankAmount, mkCashAmount)
	SetBankingInfo()
end)

Citizen.CreateThread(function() 
	--Check if player is near an ATM
	while true do
		mkNearATM = false
		if(not mkUsingATM) then
			local PlayerPos = GetEntityCoords(GetPlayerPed(PlayerId()))
			for _, Hash in pairs(mkATMHashes) do
				ClosestATMObject = GetClosestObjectOfType(PlayerPos.x, PlayerPos.y, PlayerPos.z, 1.2, Hash, false, false, false)
				if(ClosestATMObject ~= 0) then
					mkCurrentATM = ClosestATMObject
					mkNearATM = true
				end
			end
		end
		Citizen.Wait(500)
	end
end)

Citizen.CreateThread(function() 
	--Display ATM help text
	while true do
		if(mkNearATM) then
			SetTextComponentFormat('STRING');
	        AddTextComponentString('Press ~INPUT_CONTEXT~ to access ATM.');
	        DisplayHelpTextFromStringLabel(0, false, true, -1);
		end
		Citizen.Wait(50)
	end
end)

Citizen.CreateThread(function() 
	--Check if player is trying to use ATM
	while true do
		if(IsControlJustPressed(0, 51) and mkNearATM and (not mkUsingATM)) then
			Scaleform = nil
			mkUsingATM = true

			local PlayerPed = PlayerPedId()
			local PlayerPedPos = GetEntityCoords(PlayerPed)
			local ATMPos = GetEntityCoords(mkCurrentATM)
			local ATMHeading = GetEntityHeading(mkCurrentATM)
			local ATMForwardVector = GetEntityForwardVector(mkCurrentATM)

			ClearPedTasks(PlayerPed)
			local x = math.pow(PlayerPedPos.x - ATMPos.x, 2)
			local y = math.pow(PlayerPedPos.y - ATMPos.y, 2)
			local dist = math.sqrt(x+y)
			if(dist > 0.6) then
				TaskGoStraightToCoord(PlayerPed, ATMPos.x - ATMForwardVector.x / 1.75, ATMPos.y - ATMForwardVector.y / 1.75, PlayerPedPos.z, 0.75, 3000, ATMHeading, 1);
			end
			mkWaitForATMAnim()
			TriggerServerEvent('mkATM:StartATM')
			Citizen.Wait(10)
			mkStartATMScaleform()
		end
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
	--Draw ATM scaleform
	while true do
		if(Scaleform~=nil) then
			if(IsPedDeadOrDying(PlayerPedId(), true)) then
				Scaleform=nil
			end
			
			DisableAllControlActions(0)
			StopCinematicShot(true)

            if(GetLastInputMethod(0)) then
            	SetMouseCursorActiveThisFrame();
				mkCallScaleformFunction(Scaleform, 'SET_MOUSE_INPUT', GetDisabledControlNormal(0, 239), GetDisabledControlNormal(0, 240))
            else
            	mkCallScaleformFunction('setCursorInvisible')
            	mkCallScaleformFunction('SET_MOUSE_INPUT', 0, 0)
            end

            if(IsDisabledControlJustPressed(0, 201)) then
            	BeginScaleformMovieMethod(Scaleform, 'GET_CURRENT_SELECTION');
            	mkReturnScaleform = EndScaleformMovieMethodReturn()

            	if(IsScaleformMovieMethodReturnValueReady(mkReturnScaleform)) then
            		mkATMMouseSelection(GetScaleformMovieMethodReturnValueInt(mkReturnScaleform))
            	else
            		mkAwaitingResult = true
            	end
			elseif(IsDisabledControlJustPressed(0, 237)) then
            	BeginScaleformMovieMethod(Scaleform, 'GET_CURRENT_SELECTION');
            	mkReturnScaleform = EndScaleformMovieMethodReturn()

            	if(IsScaleformMovieMethodReturnValueReady(mkReturnScaleform)) then
            		mkATMMouseSelection(GetScaleformMovieMethodReturnValueInt(mkReturnScaleform))
            	else
            		mkAwaitingResult = true
            	end
            elseif(IsDisabledControlJustReleased(0, 202)) then
            	mkCloseMenu()
            elseif(IsDisabledControlJustPressed(0, 187)) then
				if (mkCurrentScreen == 6) then
            		mkCallScaleformFunction(Scaleform, 'SCROLL_PAGE', -40)
				end
			elseif(IsDisabledControlJustPressed(0, 242)) then
				if (mkCurrentScreen == 6) then
            		mkCallScaleformFunction(Scaleform, 'SCROLL_PAGE', -40)
				end
            elseif(IsDisabledControlJustPressed(0, 188)) then
				if (mkCurrentScreen == 6) then
            		mkCallScaleformFunction(Scaleform, 'SCROLL_PAGE', 40)
				end
            elseif(IsDisabledControlJustPressed(0, 241)) then
				if (mkCurrentScreen == 6) then
            		mkCallScaleformFunction(Scaleform, 'SCROLL_PAGE', 40)
				end
            end

            if(mkAwaitingResult) then
            	if(IsScaleformMovieMethodReturnValueReady(mkReturnScaleform)) then
            		mkATMMouseSelection(GetScaleformMovieMethodReturnValueInt(mkReturnScaleform))
            	end
            end

            if(IsDisabledControlJustPressed(0, 188)) then
            	mkCallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 8)
            elseif(IsDisabledControlJustPressed(0, 187)) then
            	mkCallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 9)
            elseif(IsDisabledControlJustPressed(0, 189)) then
            	mkCallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 11)
            elseif(IsDisabledControlJustPressed(0, 190)) then
            	mkCallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 10)
            end

			DrawScaleformMovieFullscreen(Scaleform, 255, 255, 255, 255, 0)
		end
		Citizen.Wait(0)
	end
end)

function mkStartATMScaleform()
	mkLoadScaleform(mkScaleformID)
	mkATMMouseSelection(0)
end

function mkLoadScaleform(ID)
	while(not HasScaleformMovieFilenameLoaded(ID)) do
		RequestScaleformMovie(ID)
		Citizen.Wait(0)
	end

	Scaleform = RequestScaleformMovie(ID)
end

function mkATMMouseSelection(SelectionID)
	mkCallScaleformFunction(Scaleform, 'SET_INPUT_SELECT')
	if(mkCurrentScreen == 0) then
		if(SelectionID == 1) then
			if(mkPlayerBank > 0) then
				mkOpenWithdrawalScreen()
			else
				mkDisplayATMError('You have insufficient funds to make a withdrawal.')
			end
		elseif(SelectionID == 2) then
			if(mkPlayerCash > 0) then
				mkOpenDepositScreen()
			else
				mkDisplayATMError('You have insufficient cash to make a deposit.')
			end
		elseif(SelectionID == 3) then
			mkOpenTransactionScreen()
		elseif(SelectionID == 4) then
			mkCloseMenu()
		else
			mkOpenMenuScreen()
		end
	elseif(mkCurrentScreen == 1 or mkCurrentScreen == 2) then
		if(SelectionID == 4) then
			mkOpenMenuScreen()
		else
			mkDepositWithdrawal(mkButtonParams[SelectionID])
		end
	elseif(mkCurrentScreen == 3) then
		if(SelectionID == 1) then
			mkOpenTransactionPending()
			TriggerServerEvent('mkATM:Transaction', mkLastTransactionAmount, mkLastTransactionWasWithdrawal)
		else 
			if(mkLastTransactionWasWithdrawal) then
				mkOpenWithdrawalScreen()
			else
				mkOpenDepositScreen()
			end
		end
	elseif(mkCurrentScreen == 5) then
		mkOpenMenuScreen()
	elseif(mkCurrentScreen == 6) then
		if(SelectionID == 1) then
			mkOpenMenuScreen()
		end
	end
end

function mkOpenMenuScreen()
	mkCurrentScreen = 0
	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Choose a service.')
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Withdraw')
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, 'Deposit')
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, 'Transaction Log')
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Exit')
	mkCallScaleformFunction(Scaleform, 'DISPLAY_MENU')
end

function mkOpenWithdrawalScreen()
	mkCurrentScreen = 1

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Select the amount you wish to withdraw from this account.');

    mkSetupATMMoneyButtons(mkPlayerBank)
    mkCallScaleformFunction(Scaleform, 'DISPLAY_CASH_OPTIONS')

    mkLastTransactionWasWithdrawal = true
end

function mkOpenDepositScreen()
	mkCurrentScreen = 2

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Select the amount you wish to deposit into this account.');

    mkSetupATMMoneyButtons(mkPlayerCash)
    mkCallScaleformFunction(Scaleform, 'DISPLAY_CASH_OPTIONS')

    mkLastTransactionWasWithdrawal = false
end

function mkOpenTransactionScreen()
	mkCurrentScreen = 6

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Transaction Log');
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Back');

    if(#mkTransactions > 0) then
    	i = #mkTransactions + 1
    	for _, mkTransaction in pairs(mkTransactions) do
			if(mkTransaction['reason'] == 'Cash Withdrawn') then
				mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', i, 0, mkTransaction['amount'], mkTransaction['reason'] .. ' ' .. mkTransaction['date']:sub(0, 10))
			else
				mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', i, 1, mkTransaction['amount'], mkTransaction['reason'] .. ' ' .. mkTransaction['date']:sub(0, 10))
			end
			i = i - 1
    	end
    end

    mkCallScaleformFunction(Scaleform, 'DISPLAY_TRANSACTIONS')

    mkLastTransactionWasWithdrawal = false
end

function mkOpenConfirmationScreen(IsWithdrawal, Amount)
	mkCurrentScreen = 3

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	if(IsWithdrawal) then
    	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Do you wish to withdraw $'..mkMoneyAddCommas(Amount)..' from your account?');
	else
    	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Do you wish to deposit $'..mkMoneyAddCommas(Amount)..' into your account?');
	end
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Yes');
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, 'No');
    mkCallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE');
end

function mkOpenTransactionPending()
	mkCurrentScreen = 4

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Transaction Pending...');
    mkCallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE');
end

function mkOpenTransactionComplete()
	mkCurrentScreen = 5

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Transaction Complete');
    mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Back');
    mkCallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE');
end

function mkDisplayATMError(Error)
	mkCurrentScreen = 5

	mkUpdateDisplayBalance()

	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, Error)
	mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Back')
	mkCallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE')
end

function mkCloseMenu()
	mkUsingATM = false
	SetScaleformMovieAsNoLongerNeeded(Scaleform)
	Scaleform = nil

	ClearPedTasks(PlayerPedId())
end	

function mkDepositWithdrawal(Amount)
	if(mkCurrentScreen == 1) then
		mkOpenConfirmationScreen(true, Amount)
		mkLastTransactionAmount=Amount
	elseif(mkCurrentScreen == 2) then
		mkOpenConfirmationScreen(false, Amount)
		mkLastTransactionAmount=Amount
	elseif(mkCurrentScreen == 5) then
		mkOpenMenuScreen()
	end
end

function mkSetupATMMoneyButtons(Amount)
	if(Amount > 100000) then
		mkButtonParams = {}
		mkButtonParams[1] = 50
		mkButtonParams[2] = 500
		mkButtonParams[3] = 2500
		mkButtonParams[5] = 10000
		mkButtonParams[6] = 100000

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$2,500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, '$10,000')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 6, '$100,000')

		mkButtonParams[7] = Amount
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 7, '$'..mkMoneyAddCommas(Amount))
	elseif(Amount>10000) then
		mkButtonParams = {}
		mkButtonParams[1] = 50
		mkButtonParams[2] = 500
		mkButtonParams[3] = 2500
		mkButtonParams[5] = 10000

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$2,500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, '$10,000')

		mkButtonParams[6] = Amount
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 6, '$'..mkMoneyAddCommas(Amount))
	elseif(Amount>2500) then
		mkButtonParams = {}
		mkButtonParams[1] = 50
		mkButtonParams[2] = 500
		mkButtonParams[3] = 2500

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$2,500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		mkButtonParams[5] = Amount
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, '$'..mkMoneyAddCommas(Amount))
	elseif(Amount>500) then
		mkButtonParams = {}
		mkButtonParams[1] = 50
		mkButtonParams[2] = 500

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		mkButtonParams[3] = Amount

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$'..mkMoneyAddCommas(Amount))
	elseif(Amount>50) then
		mkButtonParams = {}
		mkButtonParams[1] = 50

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		mkButtonParams[2] = Amount

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$'..mkMoneyAddCommas(Amount))
	else
		mkButtonParams = {}

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		mkButtonParams[1] = Amount

		mkCallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$'..mkMoneyAddCommas(Amount))
	end
end

function mkWaitForATMAnim()
	Citizen.Wait(200)

	while GetScriptTaskStatus(PlayerPedId(), 0x7d8f4411) ~= 7 do
		Citizen.Wait(10)
	end

	mkPlayAnim('amb@prop_human_atm@male@idle_a', 'idle_b', -1, 8.0, 1)
end

function mkPlayAnim(Dictionary, Name, Duration, LeadIn, Flag)
	while(not HasAnimDictLoaded(Dictionary)) do
		RequestAnimDict(Dictionary)
		Citizen.Wait(0)
	end

	TaskPlayAnim(PlayerPedId(), Dictionary, Name, LeadIn, 8.0, Duration, Flag, 0, false, false, true)
end

function mkUpdateDisplayBalance()
	SetBankingInfo()
	mkCallScaleformFunction(Scaleform, 'DISPLAY_BALANCE', GetPlayerName(PlayerId()), 'Account balance ', mkPlayerBank)
end

function mkCallScaleformFunction(Scaleform, Function, ...)
	local arg={...}
	BeginScaleformMovieMethod(Scaleform, Function)
	for k, Argument in pairs(arg) do
		if (type(Argument) == 'number') then
			if(math.type(Argument) == 'float') then
				PushScaleformMovieMethodParameterFloat(Argument)
			else
				PushScaleformMovieMethodParameterInt(Argument)
			end
		elseif (type(Argument) == 'string') then
			PushScaleformMovieMethodParameterString(Argument)
		elseif (type(Argument) == 'bool') then
			PushScaleformMovieMethodParameterBool(Argument)
		end
	end
	EndScaleformMovieMethod()
end	

function mkMoneyAddCommas(Amount)
	if(type(Amount)=='number') then
		Amount = ''..Amount
	end
    return #Amount % 3 == 0 and Amount:reverse():gsub('(%d%d%d)', '%1,'):reverse():sub(2) or Amount:reverse():gsub('(%d%d%d)', '%1,'):reverse()
end	