%Function to obtain motion vectors between a current frame and a predictor
%frame
function [motion_vectors] = Motion_Estimation(Previous_Frame, Current_Frame, block_width, block_height, search_vert, search_horiz)
    motion_vectors = [];    
    Current_Frame = double(Current_Frame);
    Previous_Frame = double(Previous_Frame);
    %Obtain the frame width and height
    [frame_height, frame_width] = size(Current_Frame);
    
    %Segment current frame
    current_frame_blocks = Segment_Frame(Current_Frame, block_width, block_height);

    %This refers to the current macro block being used
    macro_block = zeros(block_height, block_width);
    
    %This refers to the current search area being used
    search_area = zeros(block_height+search_vert*2, block_width+search_horiz*2);
    
    %For every macro block
    for col = 1:frame_width/block_width
        for row =1:frame_height/block_height
            %Define the current macro block in the current frame
            macro_block = current_frame_blocks{row,col};
            
            %Define the coordinates of the top left corner of the macro
            %block in the frame. This is used for reference
            macro_block_col = (col-1)*block_width  + 1;
            macro_block_row = (row-1)*block_height + 1;
          
            
            %Obtain the Search Area start and stop values. These will be 
            %used to get the search area from the previous frame.
            %If statements are included for the corner cases
            search_area_col_start = macro_block_col-search_horiz; 
            if(search_area_col_start<1)
                search_area_col_start = 1;
            end
            
            %When defining the stop values -1 needs to be included due to
            %the way matlab indexes
            search_area_col_stop  = macro_block_col+(block_width-1)+search_horiz; 
            if(search_area_col_stop>frame_width)
                search_area_col_stop = frame_width;
            end
            
            search_area_row_start = macro_block_row-search_vert;
            if(search_area_row_start<1)
                search_area_row_start = 1;
            end
            
            search_area_row_stop  = macro_block_row+(block_height-1)+search_vert;
            if(search_area_row_stop>frame_height)
                search_area_row_stop = frame_height;
            end
            
            %obtain the search area from the previous frame
            search_area = Previous_Frame(search_area_row_start:search_area_row_stop,search_area_col_start:search_area_col_stop);
            
            %run the block matching algorithm between the current
            %macroblock and the defined search area and obtain the motion
            %vector
            %[Motion_Horiz, Motion_Vert, MSE] = Block_Matching(macro_block,search_area,macro_block_row,macro_block_col,search_area_row_start,search_area_col_start,search_vert, search_horiz);
            [Motion_Horiz, Motion_Vert, MSE] = Block_Matching_TDL(macro_block,search_area,macro_block_row,macro_block_col,search_vert);
            
            motion_vectors(end+1,1) = Motion_Vert;
            motion_vectors(end, 2) = Motion_Horiz;
            %CAN REMOVE!
            motion_vectors(end, 3) = MSE;

        end
    end
end