module algorithms

include("./game.jl")
include("./board.jl")
using .game
using Random


RANDOM_MOVE = -1
AI_TURN = nothing    

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

function minimax(mygame::game.Game, random_play=true)
    cur_depth = 0
    max_depth = 3
    cost, move = mm(cur_depth, max_depth, mygame, true, random_play)
    return move
end

function generate_possible_games(mygame::game.Game)
    moves = game.available_moves(mygame)
    new_games = game.Game[]

    # Make all new possible moves
    for move in moves
        new_game = deepcopy(mygame)
        game.move(new_game, move)
        push!(new_games, new_game)
    end 
    return new_games
end

# Returns (score, move) tuple
function mm(cur_depth::Int64, max_depth::Int64, mygame::game.Game, max_player=true, random_play=true)
    # max_player: whether the player is the max player or the min player
    if (cur_depth > max_depth) | game.winner(mygame) | game.finished(mygame)
        return evaluation(mygame, AI_TURN), mygame.lastMove
    end

    choices = []
    for gm in generate_possible_games(mygame)
        score, move = mm(cur_depth + 1, max_depth, gm, !max_player)
        push!(choices, (score=score, move=gm.lastMove.y))
    end

    # Random move score
    if random_play
        random_scores = []
        for gm in generate_possible_games(mygame)
            winner = game.winner(gm)                        # max_player won by making this move
            for g in generate_possible_games(mygame)
                if winner
                    score = max_player ? SCORES["win"] : SCORES["lose"]  
                else
                    score, _ = mm(cur_depth + 2, max_depth, gm, max_player)
                end
                push!(random_scores, score)
            end
        end
        random_score = sum(random_scores) / length(random_scores)
        push!(choices, (score=random_score, move=RANDOM_MOVE))
    end

    # Calculate whether player is min or max, and find the best move
    shuffle!(choices)   # Make different moves that are the same value
    fn(x) = x.score
    findfn = max_player ? findmax : findmin
    val, choice_index = findfn(map(fn, choices)) 
    best_move = choices[choice_index].move

    return val, best_move
end


function evaluation(mygame::game.Game, player_index)
    # player_index is the player index to use as the "max" player  
    if game.finished(mygame)
        return SCORES["draw"]                 
    end

    state = mygame.board.state
    fns = [game._checkVertical, game._checkDiagonal1, game._checkDiagonal2, game._checkHorizontal] 
    
    # Evaluate score for both players, then subtract
    players = mygame.players
    height, width = size(state)

    # Scores for each player
    scores = Dict{String, Float64}()
    for player in players
        scores[player.token] = 0
    end

    # Loop through board
    for i = 1:height; for j = 1:width

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
            connected = min(connected, 4)    # connection of 5, 6, 7, etc mean the same as 4
            score += SCORES[connected]
        end
        score -= length(fns) - 1             # Prevent counting the same [i, j] multiple times 
        # check_blanks is essiantly a tie breaker for moves - it's always better to have more connected pieces though
        score += game._checkBlanks(mygame, i, j) / 100    
        scores[token] += score
    end; end

    player_scores = Float64[]   # Scores for each player, set at the same index of the player
    for player in players
        push!(player_scores, scores[player.token])
    end

    max_player = player_scores[player_index] 
    enemy = sum(player_scores) - max_player
    return max_player - enemy
end

### MAIN CODE

function makeAiMove(mygame::game.Game, random_play=true)
    move = algorithms.minimax(mygame, random_play)
    return move
end

function runGame()
    global AI_TURN
    AI_TURN = 2
    RANDOM_PLAY = false
    
    players = ["Human", "Computer"]
    if AI_TURN == 1
        players = reverse(players)
    end
    mygame = game.initializeGame(players[1], players[2], 6, 7)
    display(mygame.board.state)
    println()

    users_turn = AI_TURN == 2   # Keep track of whose turn it is
    force_random_move = false    # Force random move for the next move

    while !game.winner(mygame) && !game.finished(mygame)

        # Force a random move
        if !force_random_move
            move =  users_turn ? makeUserMove(mygame) : makeAiMove(mygame, RANDOM_PLAY)
        end

        if force_random_move || move == RANDOM_MOVE                     
            move = game.randomMove(mygame)

            #  Change to true if the next player needs to make a random move, or false if it's the second player's move
            force_random_move = !force_random_move       
        end

        game.move(mygame, move)
        users_turn = !users_turn

        println()
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
    move = nothing
    while true
        move = getUserInput()
        if move == RANDOM_MOVE
            break
        end
        try
            game.validate_move_row(mygame, move)
            break
        catch error
            println(error)
        end
    end
    return move
    
end

function getUserInput()
    move = nothing
    while move == nothing
        print("Your move: ")
        try
            input = readline(stdin)
            move = parse(Int64, input)
        catch error
            println("Please enter a valid number")
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

