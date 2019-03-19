module algorithms

include("./game.jl")
include("./board.jl")
using .game
using Random
using Statistics

RANDOM_MOVE = -1
MONTO_CARLO_DURATION = 4

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

function minimax(mygame::game.Game, random_play)
    cur_depth = 0
    max_depth = 4
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
function mm(cur_depth::Int64, max_depth::Int64, mygame::game.Game, hero=true, random_play=false)
    
    # Hero is the max_player
    if (cur_depth > max_depth) | game.winner(mygame) | game.finished(mygame)
        # Always considered 'max' for player 1. Sooner wins are better.
        return evaluation(mygame) - cur_depth, mygame.lastMove
    end

    # Recursive
    choices = []
    for gm in generate_possible_games(mygame)
        score, _ = mm(cur_depth + 1, max_depth, gm, !hero)
        push!(choices, (score=score, move=gm.lastMove.y))
    end

    # Random Move
    if random_play
        random_scores = []
        for gm in generate_possible_games(mygame)
            winner = game.winner(gm)                        # max_player won by making this move
            for g in generate_possible_games(mygame)
                if winner                                   # Won/lost on the last move
                    score = evaluation(mygame) - cur_depth
                else      
                    score, _ = mm(cur_depth + 2, max_depth, gm, hero)
                end
                push!(random_scores, score)
            end
        end
        random_score = mean(random_scores)   # Take the average score
        push!(choices, (score=random_score, move=RANDOM_MOVE))
    end

    
    shuffle!(choices)   # Make different moves that are the same value
    fn(x) = x.score  # Gets the cost from the returned (cost, move) tuple
    findfn = hero ? findmax : findmin
    
    val, choice_index = findfn(map(fn, choices)) 
    
    best_move = choices[choice_index].move
    return val, best_move
end


function evaluation(mygame::game.Game, hero_index=2)  
    if game.finished(mygame) # Tie
        return 0
    end

    state = mygame.board.state
    fns = [game._checkVertical, game._checkDiagonal1, game._checkDiagonal2, game._checkHorizontal] 

    # Evaluate score for both players, then subtract
    players = mygame.players
    row, col, = size(state)

    # Scores for each player
    scores = Dict{String, Float64}()
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

        # check_blanks is essiantly a tie breaker for moves - it's always better to have more connected pieces though
        score += game._checkBlanks(mygame, i, j) / 10    
        scores[token] += score
    end; end

    player_scores = Float64[]   # Scores for each player, set at the same index of the player
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

function makeAiMove(mygame::game.Game, random_play)
    # move = minimax(mygame, random_play)
    move = monteCarloSimulation(mygame)
    return move
end

function runGame()
    mygame = game.initializeGame("Human", "Computer", 6, 7)
    display(mygame.board.state)
    println()

    users_turn = true
    force_random_move = false    # Force random move for the next move
    RAND_PLAY = false

    while !game.winner(mygame) && !game.finished(mygame)
        if !force_random_move
            move = users_turn ? makeUserMove(mygame) : makeAiMove(mygame, RAND_PLAY)
        end

        if force_random_move || (move == RANDOM_MOVE)    
            move = game.randomMove(mygame)
            force_random_move = !force_random_move #  Change to true if the next player needs to make a random move, or false if it's the second player's move
        end
        
        show(move)
        game.move(mygame, move)
        users_turn = !users_turn

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
        if move == RANDOM_MOVE
            return RANDOM_MOVE
        end
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


#### MONTE CARLO
WIN = 1
LOSE = -1
TIE = 0


struct MonteCarlo
    states     # Dictionary of {board: stats}
    game
end


function makeMonteCarlo(mygame)
    mc = MonteCarlo(Dict(), mygame)
    add_state(mygame, mc.states)
    return mc
end


mutable struct Stats
    game::Any            # Type game.Game
    wins::Integer  
    losses::Integer  
    ties::Integer    
    parents::Any  # Set of states
    children::Any # Set of states
end


function add_state(mygame, states, parent=nothing)
    # If state doesn't exist yet, add it
    state = mygame.board.state
    stats = get(states, state, 0)

    if stats == 0  # Doesn't exist yet
        stats = Stats(deepcopy(mygame), 0, 0, 0, Set(), Set())
        states[mygame.board.state] = stats
    end

    if parent != nothing
        push!(states[parent].children, state)
        push!(stats.parents, parent)
    end
end


# Return the end state from a random simulation, and whether there is a winner
function simulation(state, states)
    mygame = states[state].game
    mygame = deepcopy(mygame)
    turn = mygame.turn

    # EXPANSION 
    game.moveRandom(mygame)
    add_state(mygame, states, state)

    if game.winner(mygame)
        return turn, mygame.board.state
    elseif game.finished(mygame)        # Tie Game
        return 0, mygame.board.state
    else
        # SIMULATE UNTIL END STATE
        return simulation(mygame.board.state, states)
    end
end


function backpropogation(state, states, outcome)
    # TIE, WIN, AND LOSS
    @assert -1 <= outcome <= 1

    for pstate in states[state].parents
        pstat = states[pstate]
        if outcome == WIN
            pstat.wins += 1
        elseif outcome == LOSE
            pstat.losses += 1
        elseif outcome == TIE
            pstat.ties += 1
        end

        # RECURSIVELY BACKPROP UP THE TREE
        backpropogation(pstate, states, outcome)
    end
end

function simulate_and_backprop(mc::MonteCarlo)
    winner, end_state = simulation(mc.game.board.state, mc.states)

    if winner == mc.game.turn
        outcome = WIN
    elseif winner == game.nextTurn(mc.game)
        outcome = LOSE
    elseif winner == 0
        outcome = TIE
    else
        outcome = nothing
    end

    # UPDATE AND BACKPROP
    backpropogation(end_state, mc.states, outcome)
    return winner, end_state
end


function policyMove(mc::MonteCarlo)
    curr_state = mc.game.board.state
    curr_stats = mc.states[curr_state]

    # Don't make an immediately stupid move
    for state in curr_stats.children
        stats = mc.states[state]
        if game.winner(stats.game)
            return stats.game.lastMove.y
        end
    end
    return nothing
end

function policyDontMove(mc::MonteCarlo)
    curr_state = mc.game.board.state
    curr_stats = mc.states[curr_state]

    # Don't make an immediately stupid move
    bad_moves = []
    for state1 in curr_stats.children
        for state2 in mc.states[state1].children
            stats = mc.states[state2]

            # If player lost the game, don't make the move
            if game.winner(stats.game)
                push!(bad_moves, stats.game.lastMove.y)
            end
        end
    end
    return bad_moves
end

function nextBestMove(mc::MonteCarlo)

    # SELECTION
    policy_move = policyMove(mc)
    if policy_move != nothing
        return policy_move
    end

    bad_moves = policyDontMove(mc)
    # END SELECTION

    curr_state = mc.game.board.state
    curr_stats = mc.states[curr_state]
    best_win_rate, best_move = -1, -1

    # LOOK AT STATS FROM SIMULATION 
    for state in curr_stats.children
        stats = mc.states[state]
        wins, losses = stats.wins, stats.losses
        win_rate = wins / (wins + losses)
        move = stats.game.lastMove.y

        if move in bad_moves
            continue
        elseif win_rate > best_win_rate
            best_win_rate = win_rate
            best_move = move  
        end 
    end
    return best_move
end

function monteCarloSimulation(mygame)
    mygame = deepcopy(mygame)
    mc = makeMonteCarlo(mygame)

    duration = MONTO_CARLO_DURATION # seconds
    start = finish = time()
    while finish - start < duration
        finish = time()
        simulate_and_backprop(mc)
    end 

    move = nextBestMove(mc)
    return move
end

runGame()
end

