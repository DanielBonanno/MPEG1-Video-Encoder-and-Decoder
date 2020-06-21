%Function to perform motion compensated predicition given a frame and a set
%of motion vectors
function [predicted_frame] = Motion_Compensation(Previous_Frame, block_width, block_height, Motion_Vectors)
    %Obtain the frame width and height
    [frame_height, frame_width] = size(Previous_Frame);
    
    block = 0;
    %For every macro block
    for col = 1:frame_width/block_width
        for row =1:frame_height/block_height
            block = block+1;
            %Define the coordinates of the top left corner of the macro
            %block in the frame. This is used for reference
            macro_block_col = (col-1)*block_width  + 1;
            macro_block_row = (row-1)*block_height + 1;
            
            motion_vert = Motion_Vectors(block, 1);
            motion_horiz = Motion_Vectors(block, 2);
            
            %obtain the predicted frame macro blocks from the predictor 
            %frame by using the motion vector
            predicted_frame_blocks{row,col} = Previous_Frame(macro_block_row+motion_vert:macro_block_row-1+block_height+motion_vert,macro_block_col+motion_horiz:macro_block_col-1+block_height+motion_horiz);
        end
    end
    %Combine all the macroblocks to obtain the predicted frame
    predicted_frame = cell2mat(predicted_frame_blocks);
end