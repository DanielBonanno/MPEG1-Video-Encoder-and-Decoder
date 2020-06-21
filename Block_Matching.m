%Function to perform the block match algorithm between the block and the
%search area passed as parameters.
function [motion_horiz, motion_vert, best_mse] = Block_Matching(Block, Search_Area, block_row_position, block_col_position, search_row_position, search_col_position)
    
    %Obtain the size of the search area
    [search_rows, search_cols] = size(Search_Area);
    
    %Obtain the size of the macro block
    [block_rows, block_cols] = size(Block);
    
    %inital values. these variable will contain the motion vector
    %parameters as well as the mse. if the mse of the nth iteration is
    %better than the n-1th iteration, these parameters get updated
    
    motion_horiz = 0;   %Initial values set to 0
    motion_vert = 0;
    best_mse = Inf;     
    
    %this will be used to break the loops if an mse of 0 is detected. an
    %mse of 0 indicates that an exact replica is found.
    best = false;       
    
    %for all the possible blocks in the search area
    for col = 1:search_cols-block_cols+1
            for row = 1:search_rows-block_rows+1  
                
                %calculate MSE for the current chosen block in the search
                %area
                mse = MSE(Block,Search_Area(row:row+block_rows-1,col:col+block_rows-1));
                
                %if the mse for this block is better than any previous
                %mse calcualted, update the parameters
                if(mse < best_mse)
                    
                    %set the motion vectors, by using the co-ordinates of
                    %the block and search area
                    motion_vert =  search_row_position+(row-1)-block_row_position;
                    motion_horiz = search_col_position+(col-1)-block_col_position;      

                    %check for early termination
                    if(mse == 0)
                        best = true;
                        break;
                    end
                    if(best == true)
                        break;
                    end
                    best_mse = mse;
                end 
            end
    end
end