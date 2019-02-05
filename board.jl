module board


struct Board
    state::Array{String, 2}
end

function MakeBoard(width::Int64, height::Int64)
    board_size = fill("", width, height)
    return Board(board_size)
end

# board = MakeBoard(4, 5)
# println(board)

end
