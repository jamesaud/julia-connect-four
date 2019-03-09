3
module Main

include("./game.jl")

function makeAiMove(mygame::game.Game)
    moves = game.available_moves(mygame)
    choice = rand(1:length(moves))
    move = moves[choice]
    return move
end

function runGame()
    mygame = game.initializeGame("Computer", "Human", 4, 5)
    display(mygame.board.state)
    println

    flag = true
    while !game.winner(mygame) && !game.finished(mygame)
        move =  flag ? makeUserMove(mygame) : makeAiMove(mygame)
        game.move(mygame, move)
        flag = !flag

        print("\n\nMade Move\n\n")
        display(mygame.board.state)
        println()
    end
    println("Game finished!")
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

runGame()

end
