module algorithms

include("./game.jl")
include("./board.jl")

SCORES = Dict{Union{String, Integer}, Integer}(
    "win" => 1000,
    "lose" => -1000,
    "draw" => 0,

    # For connecting multiple pieces
    4 => 1000,
    3 => 3,
    2 => 2,
    1 => 1
)

function minimax(mygame::game.Game)
    cur_depth = 0
    max_depth = 3

    cost = mm(cur_depth, max_depth, mygame)
end

function mm(cur_depth::Int64, max_depth::Int64, mygame::game.Game)
    moves = game.available_moves(mygame)
    new_games = game.Game[]
    for move in moves
        new_game = deepcopy(mygame)
        game.move(new_game, move)
        push!(new_games, new_game)
    end 
end


function evaluation(mygame::game.Game)
    state = mygame.board.state
    fns = [game._checkVertical, game._checkDiagonal1, game._checkDiagonal2, game._checkHorizontal] 

    # Evaluate score for both players, then subtract
    players = mygame.players
    row, col, = size(state)

    # Scores for each player
    scores = Dict{String, Integer}()
    for player in players
        scores[player.token] = 0
    end

    # Loop through board
    for i = 1:row; for j = 1:col
        token = state[i, j]
        
        if token == gameboard.FILLER_CHAR 
            continue
        end

        # Otherwise, it's a player's character, so calculate SCORES
        # Currently, calculating connected pieces multiple times but that should be okay
        # A three connection will be calculated three times, two connection two times, 1 connection 1 time
        # So 3*3, 2*2, 1*1 weighting to the scores
        score = 0
        for fn in fns
            connected = fn(mygame, i, j)
            connected = min(connected, 4)    # connection of 5, 6, 7, etc don't mean anything
            score += SCORES[connected]
        end
        println(score)
        scores[token] += score
    end; end

    player_scores = Integer[]   # Scores for each player, set at the same index of the player
    for player in players
        push!(player_scores, scores[player.token])
    end

    return player_scores
end


mygame = game.initializeGame("Computer", "Human", 4, 5)
game.move(mygame, 1)
game.move(mygame, 2)
game.move(mygame, 1)

display(mygame.board.state)
println()
println(evaluation(mygame))

end