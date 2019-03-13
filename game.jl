module game

include("./board.jl")


struct Player
    name::String
    token::String
end

struct Move
    x::Int64
    y::Int64
end

mutable struct Game
    board::gameboard.Board
    players::Array{Player}
    turn::Int64                             # Index of the player array for who's turn it is
    lastMove::Move
    randomPlay::Bool                        # Whether random move is enabled
end

function currentPlayer(mygame::Game)
    return mygame.players[mygame.turn]
end

function previousPlayer(mygame::Game)
    return mygame.players[previousTurn(mygame)]
end

function nextPlayer(mygame::Game)
    return mygame.players[nextTurn(mygame)]
end

function previousTurn(mygame::Game)
    turn = mygame.turn - 1
    if turn == 0
        turn = length(mygame.players)
    end
    return turn
end

function nextTurn(mygame::Game)
    turn = mygame.turn + 1
    if turn > length(mygame.players)
        turn = 1
    end
    return turn
end

function randomMove(mygame::Game)::Integer
    moves = available_moves(mygame)
    choice = rand(1:length(moves))
    move = moves[choice]
    return move 
end

function moveRandom(mygame::Game, number_of_moves=1)
    # number_of_moves: number of sequential moves. 2 is the given rule to force the next player to move
    # can be set to 1 to manually make the move, and do some analysis in between
    for _ = 1:number_of_moves
        y = randomMove(mygame)
        move(mygame, y)
    end
end

# Create a better API for Game
Game(board, players) = Game(board, players, 1, Move(1, 1), true)   
Game(board, players, randomPlay) = Game(board, players, 1, Move(1, 1), randomPlay)

# Returns a list containing all available columns to move
function available_moves(board::gameboard.Board)
    y = size(board.state)[2]
    available = Int64[]
    for i = 1:y
        if board.state[1, i] == gameboard.FILLER_CHAR
            push!(available, i)
        end
    end
    return available
end

function available_moves(game::Game)
    return available_moves(game.board)
end

# Returns the next free X coordinate for a row, given a column, or false if there is no move
function _findRow(board::gameboard.Board, y::Int64)
    if _overlapsPiece(board, 1, y)
        return -1
    end

    x = 1
    board_height = size(board.state)[1]
    while x <= board_height && !_overlapsPiece(board, x, y)
        x += 1
    end
    return x - 1
end


function _insideBoard(board::gameboard.Board, x::Int64, y::Int64)
    width, height = size(board.state)
    x_valid = 0 < x <= width
    y_valid = 0 < y <= height
    return x_valid && y_valid
end

function _overlapsPiece(board::gameboard.Board, x::Int64, y::Int64)
    return board.state[x, y] != gameboard.FILLER_CHAR
end


# Returns row where move y should end up at. Throws an error if move isn't valid.
function validate_move_row(game::Game, y::Int64)
    if !_insideBoard(game.board, 1, y)
        dim = size(game.board.state)
        throw(DomainError(y, "Outside board dimensions $dim"))
    end

    x = _findRow(game.board, y)
    if x == -1
        throw(DomainError(y, "No available moves in column $y"))
    end
    return x
end

function move(game::Game, y::Int64)
    x = validate_move_row(game, y)

    # Make move
    game.board.state[x, y] = game.players[game.turn].token
    game.lastMove = Move(x, y)
    changeTurn(game)
end


function changeTurn(game::Game)
    game.turn = nextTurn(game)
end


function initializeGame(playerName1::String, playerName2::String, width::Int64, height::Int64, randomPlay::Bool=true)
    if width < 0 || height < 0
        throw(DomainError((width, height), "board dimensions can't be negative"))
    end
    b = gameboard.MakeBoard(width, height)
    p1 = Player(playerName1, "X")
    p2 = Player(playerName2, "O")
    return Game(b, [p1, p2], randomPlay)
end

# Determines whether the LAST move is a winning move
function winner(game::Game)
    x, y = game.lastMove.x, game.lastMove.y
    if game.board.state[x, y] == gameboard.FILLER_CHAR
        return false
    end
    a = _checkVertical(game, x, y)
    b = _checkHorizontal(game, x, y)
    c = _checkDiagonal1(game, x, y)
    d = _checkDiagonal2(game, x, y)
    return any(x -> x >= 4, [a, b, c, d])
end

# Determines whether the game board is full
function finished(game::Game)
    cols = collect(1:size(game.board.state)[2])
    return all(i -> _findRow(game.board, i)==-1, cols)
end

# Finds number of connected pieces given the last move
function _checkVertical(game::Game, x::Int64, y::Int64)
    state = game.board.state
    token = state[x, y]
    board_height = size(state)[1]
    count = 1

    # Below
    for i = x+1:board_height
        if state[i, y] != token
            break
        end
        count += 1
    end

    # Above
    for i = x-1:-1:1
        if state[i, y] != token
            break
        end
        count += 1
    end

    return count
end


function _checkBlanks(game::Game, x::Int64, y::Int64)
    state = game.board.state
    token = state[x, y]
    board_width, board_height = size(state)[2], size(state)[1]
    count = 0

    left = x, y - 1
    right = x, y + 1
    down = x + 1, y
    up = x - 1, y
    
    for (i, j) in [left, right, up, down]
        if i < 1 || j < 1 || i > board_height || j > board_width
            continue
      
        elseif state[i, j] == gameboard.FILLER_CHAR
            count += 1
        end
    end
    # Down
    return count
end

# Finds number of connected pieces given the last move
function _checkDiagonal1(game::Game, x::Int64, y::Int64)
    state = game.board.state
    token = state[x, y]
    board_width, board_height = size(state)[2], size(state)[1]
    count = 1

    # Left/up diagonal
    i, j = x-1, y-1
    while i > 0 && j > 0
        if state[i, j] != token
            break
        end
        count += 1; i -= 1; j -= 1
    end

    # Right/down diagonal
    i, j = x+1, y+1
    while i <= board_height && j <= board_width
        if state[i, j] != token
            break
        end
        count += 1; i += 1; j += 1
    end
    return count
end

# Finds number of connected pieces given the last move
function _checkDiagonal2(game::Game, x::Int64, y::Int64)
    state = game.board.state
    token = state[x, y]
    board_height, board_width = size(state)
    count = 1

    # Left/down diagonal
    i, j = x+1, y-1
    while i <= board_height && j > 0
        if state[i, j] != token
            break
        end
        count += 1; i += 1; j -= 1
    end

    # Right/up diagonal
    i, j = x-1, y+1
    while i > 0 && j < board_width
        if state[i, j] != token
            break
        end
        count += 1; i -= 1; j += 1
    end
    return count
end

# Finds number of connected pieces given the last move
function _checkHorizontal(game::Game, x::Int64, y::Int64)
    state = game.board.state
    token = state[x, y]
    board_width = size(state)[2]
    count = 1

    # Check left
    for i = y-1:-1:1
        if state[x, i] != token
            break
        end
        count += 1
    end

    for i = y+1:board_width
        if state[x, i] != token
            break
        end
        count += 1
    end
    return count
end
end
