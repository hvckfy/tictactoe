local uuid = require('uuid')
local fiber = require('fiber')

local SPACE_GAMES_SESSION_ID = 1
local SPACE_GAMES_STATUS = 2
local SPACE_GAMES_FIELD = 3
local SPACE_GAMES_METAINFO = 4
local SPACE_GAMES_PLAYER1 = 5
local SPACE_GAMES_PLAYER2 = 6
local SPACE_GAMES_TIMESTAMP = 7

local space = box.schema.space.create('tictactoegames', {if_not_exists = true})
space:format({
    {name = 'session_id', type = 'uuid'},                   -- id of session uint
    {name = 'status', type = 'string'},                     -- status of game new or inprogress
    {name = 'field', type = 'array'},                       -- field array that contains state of current field starts with: [[0,0,0],[0,0,0],[0,0,0]]
    {name = 'metainfo', type = 'unsigned'},                 -- metainfo of turn
    {name = 'player1', type = 'unsigned'},                  -- id of player 1
    {name = 'player2', type = 'unsigned'},                  -- id of player 2
    {name = 'timestamp', type = 'unsigned'}                 -- UNIX timestamp
})

space:create_index('primary', {
    parts = {'session_id'},
    type = 'hash',
    if_not_exists = true
})

space:create_index('ctime', {
    parts = {{'status'},{'timestamp'}},
    type = 'tree',
    if_not_exists = true
})

local SPACE_PLAYERS_PLAYER_ID = 1
local SPACE_PLAYERS_SESSION_ID = 2
local SPACE_PLAYERS_TIMESTAMP = 3

local space = box.schema.space.create('tictactoeplayers', {if_not_exists = true})
space:format({
    {name = 'player_id', type = 'unsigned'},
    {name = 'session_id', type = 'uuid'},
    {name = 'timestamp', type = 'unsigned'}
})


space:create_index('primary', {
    parts = {'player_id'},
    type = 'hash',
    if_not_exists = true
})

function getSessionID(playerID)
    local tuple = box.space.tictactoeplayers.index.primary:get(playerID)
    if tuple ~= nil then
            return tuple[SPACE_PLAYERS_SESSION_ID]
    end
    return nil    
end

function GetOldestGames()
    return box.space.tictactoegames.index.ctime:select({'new',nil})
end

function CreateNewPlayer(playerid, sessionid)
    local new_player ={
        [SPACE_PLAYERS_PLAYER_ID] = playerid,
        [SPACE_PLAYERS_SESSION_ID] = sessionid,
        [SPACE_PLAYERS_TIMESTAMP] = math.floor(fiber.time())  
    }
    box.space.tictactoeplayers:insert(new_player)    
end

local function CreateNewGame(playerid)
    local new_game = {
        [SPACE_GAMES_SESSION_ID] = uuid.new(),
        [SPACE_GAMES_STATUS] = 'new',
        [SPACE_GAMES_FIELD] = {{0,0,0},{0,0,0},{0,0,0}},
        [SPACE_GAMES_METAINFO] = 1,
        [SPACE_GAMES_PLAYER1] = 0,
        [SPACE_GAMES_PLAYER2] = 0,
        [SPACE_GAMES_TIMESTAMP] = math.floor(fiber.time())  
    }
    CreateNewPlayer(playerid,new_game[SPACE_GAMES_SESSION_ID])
    local offset = SPACE_GAMES_PLAYER1
    if math.random(1,2) == 1 then
        offset = SPACE_GAMES_PLAYER2
    end
    new_game[offset] = playerid
    return box.space.tictactoegames:insert(new_game)    
end

local function BindOldestGame(playerid)
    local games_tuple = GetOldestGames()
    if games_tuple[1]==nil then
        return nil
    end
    local game = games_tuple[1] -- get the first tuple from the result
    local offset = SPACE_GAMES_PLAYER2
    if game[SPACE_GAMES_PLAYER2] ~= 0 then
        offset = SPACE_GAMES_PLAYER1
    end
    local key = game[SPACE_GAMES_SESSION_ID] -- get the primary key (session_id)
    local ops = {
        {'=', offset, playerid}, -- update operation: set offset to playerid
        {'=', SPACE_GAMES_STATUS, 'inprogress'} -- update operation: set status to 'inprogress'
    }
    CreateNewPlayer(playerid,game[SPACE_GAMES_SESSION_ID])
    return box.space.tictactoegames:update(key, ops)
end

function FindGame(playerID)
    local existingSession = getSessionID(playerID)
    if existingSession ~= nil then
        return "You already have a game, if you want to end it, use /endgame"
    end
    local oldgame = BindOldestGame(playerID)
    if oldgame ~= nil then
        return oldgame
    end
    local newgame = CreateNewGame(playerID)
    return newgame
end

local function DeleteGame(SessionID)
    box.space.tictactoegames:delete(SessionID)
end

local function DeletePlayer(PlayerID)
    box.space.tictactoeplayers:delete(PlayerID)
end

function GetSecondPlayerID(playerid)
    local SessionID = getSessionID(playerid)
    if SessionID == nil then
        return nil
    end
    local game_tuple = box.space.tictactoegames.index.primary:get(SessionID)
    if game_tuple == nil then
        return nil
    end
    local Player1ID = game_tuple[SPACE_GAMES_PLAYER1]
    local Player2ID = game_tuple[SPACE_GAMES_PLAYER2]
    if playerid == Player1ID then
        return Player2ID
    elseif playerid == Player2ID then
        return Player1ID
    end
    return nil
end

function EndGame(PlayerID)
    local SessionID = getSessionID(PlayerID)
    if SessionID == nil then
        return "You have no game at moment"
    end
    local Player2ID = GetSecondPlayerID(PlayerID)
    DeleteGame(SessionID)
    DeletePlayer(PlayerID)
    DeletePlayer(Player2ID)
    return "Your existing game was deleted. \nUse /startgame to start a new game"
end

--Player1 always set X or O first, so in metainfo we
--always contains number of a turn, 
--first we re checking if player really is already in game
--then we re checking if its players turn using metainfo
--and if its his turn we update field with 1 if playerid 
--is player1 and with 2 if playerid is player2
--we will ask for function in python message handler

function set(PlayerID, row, col)
    local SessionID = getSessionID(PlayerID)
    if SessionID == nil then
        return "Game not found \nUse /startgame to find a new game"
    end
    local game_tuple = box.space.tictactoegames.index.primary:get(SessionID)
    if game_tuple == nil then
        return "Game not found \nUse /startgame to find a new game"
    end
    if game_tuple[SPACE_GAMES_STATUS] ~= 'inprogress' then
        return "Game is not in progress"
    end
    local Player1ID = game_tuple[SPACE_GAMES_PLAYER1]
    local Player2ID = game_tuple[SPACE_GAMES_PLAYER2]
    local metainfo = game_tuple[SPACE_GAMES_METAINFO]
    local field = game_tuple[SPACE_GAMES_FIELD]
    local is_player_turn = false
    local value
    if PlayerID == Player1ID then
        value = 1
        if metainfo % 2 == 1 then
            is_player_turn = true
        end
    elseif PlayerID == Player2ID then
        value = 2
        if metainfo % 2 == 0 then
            is_player_turn = true
        end
    end
    if not is_player_turn then
        return "It's not your turn"
    end
    if field[row][col]~=0 then
        return "This place already filled"
    end
    field[row][col] = value
    local ops = {
        {'=', SPACE_GAMES_FIELD, field},          -- update operation: set field
        {'=', SPACE_GAMES_METAINFO, metainfo + 1} -- update operation: increment metainfo
    }
    box.space.tictactoegames:update(SessionID, ops)
    return box.space.tictactoegames.index.primary:get(SessionID)
end
