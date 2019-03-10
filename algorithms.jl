module algorithms

include("./game.jl")
include("./board.jl")
using .game

SCORES = Dict{Union{String, Integer}, Integer}(
    "win" => 1000,
    "lose" => -1000,
    "draw" => 0,

    # For connecting multiple pieces
    4 => 1000,
    3 => 3,
    2 => 2,
    1 => 1,
)

function minimax(mygame::game.Game)
    cur_depth = 0
    max_depth = 3
    cost, move = mm(cur_depth, max_depth, mygame)
    return move
end


# Returns (score, move) tuple
function mm(cur_depth::Int64, max_depth::Int64, mygame::game.Game, hero=true)
    if (cur_depth > max_depth) | game.winner(mygame) | game.finished(mygame)
        # Always considered 'max' for player 1
        return evaluation(mygame), mygame.lastMove
    end


    moves = game.available_moves(mygame)
    new_games = game.Game[]

    # Make all new possible moves
    for move in moves
        new_game = deepcopy(mygame)
        game.move(new_game, move)
        push!(new_games, new_game)
    end 

    # Recursive
    choices = []
    for gm in new_games
        score, _ = mm(cur_depth + 1, max_depth, gm, !hero)
        push!(choices, (score=score, move=gm.lastMove.y))
    end

    # TODO: Find the right choice for minimax
    fn(x) = x.score  # Gets the cost from the returned (cost, move) tuple
    findfn = hero ? findmax : findmin
    
    val, choice_index = findfn(map(fn, choices)) 
    
    best_move = choices[choice_index].move
    return val, best_move
end


function evaluation(mygame::game.Game, hero_index=2)  
    if game.finished(mygame)
        return 0
    end

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
        score -= length(fns) - 1             # Prevent counting the same [i, j] multiple times 
        scores[token] += score
    end; end

    player_scores = Integer[]   # Scores for each player, set at the same index of the player
    for player in players
        push!(player_scores, scores[player.token])
    end

    hero = player_scores[hero_index] 
    enemy = sum(player_scores) - hero
    return hero - enemy
end

### MAIN CODE

function randomMove(mygame::game.Game)
    moves = game.available_moves(mygame)
    choice = rand(1:length(moves))
    move = moves[choice]
    return move 
end

function makeAiMove(mygame::game.Game)
    #move = randomMove(mygame)
    move = algorithms.minimax(mygame)
    return move
end

function runGame()
    mygame = game.initializeGame("Human", "Computer", 4, 5)
    display(mygame.board.state)
    println()

    flag = true
    while !game.winner(mygame) && !game.finished(mygame)
        move =  flag ? makeUserMove(mygame) : makeAiMove(mygame)
        game.move(mygame, move)
        flag = !flag

        print("\n\nMade Move\n\n")
        display(mygame.board.state)
        println()
    end

    if game.winner(mygame)
        msg = string(game.previousPlayer(mygame).name, " wins!")
    else
        msg = "It's a draw." 
    end
    println("Game finished! $msg")
end

function makeUserMove(mygame::game.Game)
    while true
        move = getUserInput()
        try
            game.validate_move_row(mygame, move)
            return move
        catch error
            println(error)
        end
    end
    
end

function getUserInput()
    move = nothing
    while true
        print("Your move: ")
        try
            move = readline(stdin)
            move = parse(Int64, move)
            break
        catch error
            println("Please enter a valid column number")
        end
    end
    return move
end

# mygame = game.initializeGame("Computer", "Human", 4, 5)
# game.move(mygame, 1)
# game.move(mygame, 2)
# game.move(mygame, 1)
# game.move(mygame, 2)
# game.move(mygame, 1)
# game.move(mygame, 2)
# game.move(mygame, 1)

# display(mygame.board.state)
# println()
# println(evaluation(mygame))




runGame()
end

