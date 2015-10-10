
-- TODO
-- cvars
-- multi answer cards
-- reshuffling



local cag_Players = {}
local cag_WhiteCards = {}
local cag_BlackCards = {}
local cag_WhiteCardsAvailable = {}
local cag_CardsPickedThisRound = {}
local cag_CurrentStatus = 0
local cag_CurrentCzar = null
local cag_CzarIdx = 0
local cag_CurrentQuestionIdx = 0

local cag_AllowCzarToPlay = true
local cag_MinPlayers = 3
local cag_TimeBetweenRounds = 60
local cag_TimeToPickCard = 45
local cag_HideTextFromNonPlayers = false
local cag_HideCmdsFromPlayers = true

function cag_ProcessRawCardData()
	print ("CAG1 loading data")

	local cardData = util.JSONToTable(file.Read( "carddata/raw.txt", "LUA" ) )
	for k, v in pairs(cardData) do
		print(k,v)
		if v.cardType == "A" then
			table.insert(cag_WhiteCards, v)
		end
		
		if v.cardType == "Q" then
			table.insert(cag_BlackCards, v)
		end
	end
	
	file.Write( "whitecards.txt", util.TableToJSON(cag_WhiteCards, true) )
	file.Write( "blackcards.txt", util.TableToJSON(cag_BlackCards, true) )

end
--cag_ProcessRawCardData()


function cag_LoadCards()
	print ("[CaG] Loading cards....")
	local cardData = util.JSONToTable(file.Read( "carddata/cards.txt", "LUA" ) )
	for k, v in pairs(cardData) do
		
		v.text = string.Replace( v.text, "\\", "" )
		v.text = string.Replace( v.text, "&reg;", "" )
		v.text = string.Replace( v.text, "&trade;", "" )
		v.text = string.Replace( v.text, "&copy;", "" )
		
		if v.cardType == "A" then
			table.insert(cag_WhiteCards, v)
		end
		
		if v.cardType == "Q" then
			table.insert(cag_BlackCards, v)
		end
	end
	
	--cag_WhiteCards = util.JSONToTable(file.Read( "carddata/whitecards.txt", "LUA" ) )
	--cag_BlackCards = util.JSONToTable(file.Read( "carddata/blackcards.txt", "LUA" ) )
	
	print ("[CaG] Done Loading cards")
end

function cag_CommandChat( ply, text, public )
	local result = text
	if cag_HideCmdsFromPlayers == true then result = "" end
	
	if (string.sub(string.lower(text), 1, 9) == "!cag help" or string.lower(text) == "!cag") then
		cag_SimpleMsg("Welcome to Cards Against GMod. All commands are chat-based...", ply)
		cag_SimpleMsg("!cag - or - !cag help : this list", ply)
		cag_SimpleMsg("!cag in : join the game", ply)
		cag_SimpleMsg("!cag out : leave the game", ply)
		cag_SimpleMsg("!cag cards : view your current cards", ply)
		cag_SimpleMsg("!cag use # : submit card(s) as answers", ply)
		cag_SimpleMsg("!cag players : list the current players", ply)
		cag_SimpleMsg("!cag czar : list the current Card Czar", ply)
		cag_SimpleMsg("!cag winner # : pick a winner (Card Czar only)", ply)
		--cag_SimpleMsg("!cag status : current round status", ply)
		
		return result
    end
	
	if (string.sub(string.lower(text), 1, 11) 	== "!cag winner") then
		if (ply ~= cag_CurrentCzar) then
			cag_SimpleMsg("But you're not the Czar!", ply)
			return result
		end
		
		local args = string.Explode( " ", text )
		cag_PickAWinner(tonumber(args[3]))
		return result
    end
	
	if (string.sub(string.lower(text), 1, 15) 	== "!cag forceround") then
		cag_NewRound(true)
		return result
    end
	
	if (string.sub(string.lower(text), 1, 15) 	== "!cag forcereset") then
		cag_Reset()
		return result
    end
	
    if (string.sub(string.lower(text), 1, 7) == "!cag in" and ply.PlayingCAG == false) then
		cag_SimpleMsg(ply:Nick().. " is now playing CaG. Say !cag for info." )
		cag_SetPlayerPlayStatus(ply, true)
		return result
    end
	
	if (string.sub(string.lower(text), 1, 8) 	== "!cag out" and ply.PlayingCAG == true) then
		cag_SimpleMsg(ply:Nick().. " is no longer playing CaG" )
		cag_SetPlayerPlayStatus(ply, false)
		return result
    end
	
	if (string.sub(string.lower(text), 1, 10) == "!cag cards") then
		if (ply == cag_CurrentCzar and cag_AllowCzarToPlay == false) then
			cag_SimpleMsg("But you're the Czar!", ply)
			return result
		end
		
		for k,v in pairs(ply.CurrentCAGCards) do
			cag_SimpleMsg(k..") "..v.text, ply)
		end
		return result
    end
	
	if (string.sub(string.lower(text), 1, 12) == "!cag players") then
		for k,v in pairs(cag_Players) do
			if v ~= nil then cag_SimpleMsg(v:Name(), ply) end
		end
		return result
    end
	
	
	if (string.sub(string.lower(text), 1, 8) == "!cag use") then
		if (ply == cag_CurrentCzar and cag_AllowCzarToPlay == false) then
			cag_SimpleMsg("But you're the Czar!", ply)
			return result
		end
		
		local args = string.Explode( " ", text )
		for i = 3,#args do
			idx = tonumber(args[i])
			local card = ply.CurrentCAGCards[idx]
			cag_SimpleMsg("Your answer: ".. card.text, ply)
			table.remove(ply.CurrentCAGCards, idx)
			card.PlayedBy = ply
			table.insert(cag_CardsPickedThisRound, card)
		end
		
		cag_GiveCards(ply)
		return result
    end
	
	if (string.sub(string.lower(text), 1, 9) == "!cag czar") then
		if (cag_CurrentCzar == null) then
			cag_SimpleMsg("There is currently no czar", ply)
		else
			cag_SimpleMsg("The current czar is "..cag_CurrentCzar:Name())
		end
		
		return result
	end
	
end
hook.Add( "PlayerSay", "cag_CommandChatPlayerSay", cag_CommandChat )

function cag_PlayerDisconnected( ply )
	cag_SetPlayerPlayStatus(ply, false)
end
hook.Add( "PlayerDisconnected", "cag_PlayerDisconnected", cag_PlayerDisconnected )


function cag_PlayerInitialSpawn( ply )
	ply.PlayingCAG = false
	--ply.IsCurrentCardCzar = false
end
hook.Add( "PlayerInitialSpawn", "cag_PlayerInitialSpawn", cag_PlayerInitialSpawn )

function cag_SetPlayerPlayStatus(ply, status)

	if (status == false) then
	
	
		if ply.PlayingCAG == true then
			ply.PlayingCAG = false
			ply.CurrentCAGCards = null
			--cag_Players[ply:SteamID()] = nil
			table.RemoveByValue(cag_Players, ply)
		end
		
		if (ply == cag_CurrentCzar) then  -- damn!
			cag_SimpleMsg("The current czar left!!" )
			cag_NewRound()
		end
	else
		if ply.PlayingCAG == false then
			ply.PlayingCAG = true
			ply.CurrentCAGCards = null
			--cag_Players[ply:SteamID()] = ply
			table.insert(cag_Players, ply)
			cag_GiveCards(ply)
			
			
			if (cag_CurrentStatus == 0) then -- waiting players, see if we can start!
				cag_NewRound()
			end
					
		end
	end
	
	ply.PlayingCAG = status
end


function cag_GiveCards(ply)
	if (ply.CurrentCAGCards == null) then
		ply.CurrentCAGCards = {}
	end
	
	local cardsNeeded = 10 - table.Count(ply.CurrentCAGCards)
	if (table.Count(cag_WhiteCardsAvailable) < cardsNeeded) then
		print ("Oh shit! Not enough cards!")
		cag_Reset()
	end
	
	for i = 1, cardsNeeded do
		idx = math.random(table.Count(cag_WhiteCardsAvailable))
		table.insert(ply.CurrentCAGCards, cag_WhiteCardsAvailable[idx])
		table.remove(cag_WhiteCardsAvailable, idx)
	end
	
	print(cardsNeeded)
	cag_SimpleMsg("You received " .. cardsNeeded .. " new white card(s). Say !cag cards to see them." , ply )
	
end

function cag_SimpleMsg(msg, ply)

	if (ply ~= nil) then -- individual
		cag_AddText(ply, Color(255,0,0,255), "[CaG] ", Color(255,255,0,255), msg)
	else
		local tgt = nil
		if cag_HideTextFromNonPlayers == true then tgt = cag_Players end
		cag_AddText(tgt, Color(255,0,0,255), "[CaG] ", Color(0,255,255,255), msg)
	end
	
	ply  =  nil
	
end

function cag_PickCzar()

	cag_CzarIdx = cag_CzarIdx + 1
	cag_CurrentCzar = nil
	
	if cag_CzarIdx > #cag_Players then
		cag_CzarIdx = 1
	end
	cag_CurrentCzar = cag_Players[cag_CzarIdx]
	
	--[[idx = 0
	for k,v in pairs(cag_Players) do
		idx = idx + 1
		if idx >= cag_CzarIdx and cag_CurrentCzar == nil and v ~= nil  then
			cag_CurrentCzar = v;
			cag_CzarIdx = idx
		end
	end
	
	if (cag_CurrentCzar == nil) then
		cag_CzarIdx = 0
		idx = 0
		for k,v in pairs(cag_Players) do
			idx = idx + 1
			if idx >= cag_CzarIdx and cag_CurrentCzar == nil and v ~= nil then
				cag_CurrentCzar = v;
				cag_CzarIdx = idx
			end
		end
	end]]

		
	
	if (cag_CurrentCzar ~= nil) then
		cag_SimpleMsg("The new Card Czar is "..cag_CurrentCzar:Name())
		cag_CurrentStatus = 1 -- have a czar
	else
		cag_SimpleMsg("Ruh-roh! Couldn't pick a czar!")
		cag_CurrentStatus = -1 -- no czar, error
	end
end

function cag_NewRound(forced)

	if (forced == nil) then forced = false end
	
	local cnt = table.Count(cag_Players)
	if (cnt < cag_MinPlayers and forced == false) then
		cag_CurrentStatus = 0
		cag_SimpleMsg("Waiting on ".. cag_MinPlayers - cnt .. " more player(s)...")
		return
	end



	cag_PickCzar()
	if (cag_CurrentStatus == 1) then
		cag_CurrentStatus = 2 -- playing
		if (cag_CurrentCzar ~= nil) then
		
			cag_CurrentQuestionIdx = nil
			-- for now, only choose single answer questions
			while (cag_CurrentQuestionIdx == nil) do
				cag_CurrentQuestionIdx = math.random(#cag_BlackCards)
				if (cag_BlackCards[cag_CurrentQuestionIdx].numAnswers > 1) then cag_CurrentQuestionIdx = nil end
			end
		
	
			cag_SimpleMsg("Here's your question:  " .. cag_BlackCards[cag_CurrentQuestionIdx].text)
			cag_CardsPickedThisRound = {}
			cag_SimpleMsg("Players, you have ".. cag_TimeToPickCard .." seconds to submit an answer.")
			timer.Create( "CAG1AnswerTimer", cag_TimeToPickCard, 1, cag_HandleAnswers )
		end
	else 
		cag_Reset() -- something went wrong.  Reset
	end
end

function cag_Init()
	cag_LoadCards()
	cag_Reset()
end

function cag_Reset()
	cag_SimpleMsg("CaG has been reset. Player will need to rejoin.")

	cag_WhiteCardsAvailable = table.Copy(cag_WhiteCards)
	cag_Players = {}
	cag_CardsPickedThisRound = {}
	cag_CurrentStatus = 0 -- waiting for players
	cag_CurrentCzar = null
	cag_CzarIdx = 0
end


function cag_HandleAnswers()
	local del = 1
	
	timer.Simple(2 * del, function()  -- make it dramatic!
		cag_SimpleMsg("Ok, folks.. here are your answers!")
	end)
	
	del = del + 1
	
	timer.Simple(2 * del, function()  -- make it dramatic!
		cag_SimpleMsg("Q:  " .. cag_BlackCards[cag_CurrentQuestionIdx].text)
	end)
	
	for k,v in pairs(cag_CardsPickedThisRound) do
		del = del + 1
		timer.Simple(2 * del, function()  -- make it dramatic!
			cag_SimpleMsg("A #"..k.." :  " .. v.text)
		end)
	end
	
	del = del + 1
	timer.Simple(2 * del, function()  -- make it dramatic!
		cag_SimpleMsg("Card Czar (".. cag_CurrentCzar:Name() .."), choose a winner!")
	end)
	
end


function cag_PickAWinner(idx)
	local msg = "The Czar chooses:  "..cag_CardsPickedThisRound[idx].text ..". Congratulations, "..cag_CardsPickedThisRound[idx].PlayedBy:Name()
	cag_SimpleMsg(msg)
	cag_SimpleMsg("Next round in ".. cag_TimeBetweenRounds .." seconds.")
	timer.Simple(cag_TimeBetweenRounds, function() cag_NewRound() end)
end

cag_Init()








