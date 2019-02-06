3
module Main

include("./game.jl")

function makeAiMove(mygame::game.Game)
    y = size(mygame.board.state)[2]
    while true
        move = rand(1:y)
        try
            game.move(mygame, move)
            break
        catch error
        end
    end
end

function runGame()
    mygame = game.initializeGame("Computer", "Human", 4, 5)

    flag = 0
    while !game.winner(mygame) && !game.finished(mygame)
        if flag == 0
            makeUserMove(mygame)
            flag = 1
        else
            makeAiMove(mygame)
            flag = 0
        end
        display(mygame.board.state)
    end
    println("Game finished!")
end

function makeUserMove(mygame::game.Game)
    while true
        move = getUserInput()
        try
            game.move(mygame, move)
            break
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
