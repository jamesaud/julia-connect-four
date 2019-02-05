module game

include("./board.jl")
include("./player.jl")


struct Game
    board::board.Board
    players::Array{player.Player}
    turn::Int64                             # Index of the player array for who's turn it is
end


function move(game::Game, player::player.Player, x::Int64, y::Int64)
    state = game.board.state
    state[x, y] = player.token
end




b = board.MakeBoard(4, 5)
p1 = player.Player("Computer", "X")
p2 = player.Player("Human", "O")
mygame = Game(b, [p1, p2], 0)

move(mygame, p1, 2, 1)
println(mygame)


end
