%Functon to segment a frame into blocks. The output is the blocks 
%(as a cell) and the input is the frame, the block width and the 
%block height

function [blocks] = Segment_Frame(frame, block_width, block_height)
    [frame_height, frame_width] = size(frame);
    %obtain 2 vectors, containing the dimentions for each block
    block_width_vector = repmat(block_width, 1, frame_width/block_width);
    block_height_vector = repmat(block_height, 1, frame_height/block_height);
    
    %split the frame into 8X8 blocks, which are stored in a cell
    blocks = mat2cell(frame, block_height_vector, block_width_vector);

end