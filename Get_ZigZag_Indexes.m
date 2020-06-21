% Function used to obtain an index matrix which will be used to read a
% matrix in a zig-zag fashion. As input, it takes the dimentions of the
% matrix. As output, it gives the index matrix.

function [index_vector] = Get_ZigZag_Indexes(block_width, block_height)
    %create the element number matrix.
    index_vector = reshape(1:block_width*block_height, [block_height,block_width]); 
    %flip left to right, get the diagonals, flip left to right again 
    index_vector = fliplr(spdiags(fliplr(index_vector)));

    %odd columns are flipped upside down. to choose only the odd columns,
    %indexing is done on the columns starting from 2 with a step of 2
    index_vector(:,1:2:end) = flipud(index_vector(:,1:2:end) );

    %0 elements are eliminated by indexing all non-zero elements and the 
    %vector is generated
    index_vector = [index_vector(index_vector~=0)]';                    

end