module Main

include("./game.jl")

function makeAiMove(game::game.Game)
    y = size(game.board.state)[1]
    return rand(1:y)
end

function runGame()
    mygame = game.initializeGame("Computer", "Human", 4, 5)

    while !game.winner(mygame)
        makeUserMove(mygame)
        display(mygame.board.state)
    end

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
