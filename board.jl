module gameboard

FILLER_CHAR = "-"

struct Board
    state::Array{String, 2}
end

function MakeBoard(width::Int64, height::Int64)
    board_size = fill(FILLER_CHAR, width, height)
    return Board(board_size)
end

end
