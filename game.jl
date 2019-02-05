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
end

Game(board, players, turn) = Game(board, players, turn, Move(0, 0))

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


function move(game::Game, y::Int64)
    if !_insideBoard(game.board, 1, y)
        dim = size(game.board.state)
        throw(DomainError(y, "Outside board dimensions $dim"))
    end

    x = _findRow(game.board, y)
    if x == -1
        throw(DomainError(y, "No available moves in column $y"))
    end

    # Make move
    game.board.state[x, y] = game.players[game.turn].token
    game.lastMove = Move(x, y)
    changeTurn(game)
end


function changeTurn(game::Game)
    game.turn += 1
    if game.turn > length(game.players)
        game.turn = 1
    end
end


function initializeGame(playerName1::String, playerName2::String, width::Int64, height::Int64)
    if width < 0 || height < 0
        throw(DomainError((width, height), "board dimensions can't be negative"))
    end

    b = gameboard.MakeBoard(width, height)
    p1 = Player(playerName1, "X")
    p2 = Player(playerName2, "O")
    return Game(b, [p1, p2], 1)
end

function winner(game::Game)
    return false
end

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
    return count
end


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


mygame = initializeGame("Computer", "Human", 4, 5)
move(mygame, 1)
move(mygame, 1)


move(mygame, 3)
move(mygame, 3)
move(mygame, 3)


move(mygame, 4)
move(mygame, 4)
move(mygame, 4)
move(mygame, 4)


move(mygame, 2)
move(mygame, 2)
move(mygame, 2)
move(mygame, 1)
move(mygame, 1)

move(mygame, 5)
move(mygame, 5)
move(mygame, 5)
move(mygame, 5)
move(mygame, 2)
move(mygame, 3)


display(mygame.board.state)
x, y = mygame.lastMove.x, mygame.lastMove.y
println("Horz Count ", _checkHorizontal(mygame, x, y))
println("Vert Count ", _checkVertical(mygame, x, y))
println("DiagNegative ", _checkDiagonal1(mygame, x, y))
println("DiagPostive ", _checkDiagonal2(mygame, x, y))

end
