%Function to perform the block match algorithm between the block and the
%search area passed as parameters. additional parameters include the block
%number (that is, the row and column index values of the row) and the
%search lengthss both in the vertical and in the horizontal direction. As
%output, the function gives the vertical and horizontal motion parameters

function [best_match_horiz, best_match_vert, best_mse] = Block_Matching_TDL(Block, Search_Area, block_row_position, block_col_position, search_dist)
       
    %Obtain the size of the macro block
    [block_rows, block_cols] = size(Block);
    
    %Obtain the size of the search area
    [search_rows, search_cols] = size(Search_Area);
    
    %inital values.
    best_mse = Inf;     
    
    %this will be used to break the loops if an mse of 0 is detected. an
    %mse of 0 indicates that an exact replica is found
    best_flag = false; 
    
    %inital radius and best motion vectors
    radius = 2^(ceil(log2(search_dist))-1);
    best_match_vert = 0;
    best_match_horiz = 0;
    
    current_centre_row = 0;
    current_centre_col = 0;
    
    %while there is no early termination or this is not the final iteration
    while(~best_flag)
        %if the radius is not equal to 1
        if(radius ~=1)
            %set the search vector
            search_vector = [best_match_horiz+0, best_match_vert+0;
                             best_match_horiz+0, best_match_vert+radius;
                             best_match_horiz+0, best_match_vert-radius;
                             best_match_horiz+radius, best_match_vert+0;
                             best_match_horiz-radius, best_match_vert+0;];
        else
            %otherwise
             best_flag = true;  %this iteration is the final iteration
             %search vector has 9 points
             search_vector = [best_match_horiz+0, best_match_vert+0;
                             best_match_horiz+0, best_match_vert+radius;
                             best_match_horiz+0, best_match_vert-radius;
                             best_match_horiz+radius, best_match_vert+0;
                             best_match_horiz-radius, best_match_vert+0;
                             best_match_horiz+radius, best_match_vert+radius;
                             best_match_horiz-radius, best_match_vert-radius;
                             best_match_horiz+radius, best_match_vert-radius;
                             best_match_horiz-radius, best_match_vert+radius;];
        end
        %for every point in the search vector
        for point = 1:size(search_vector,1)
            %obtain the search area indexes
            search_area_row = search_vector(point,1) + block_row_position;
            search_area_col = search_vector(point,2) + block_col_position;
            %skip, for corner cases
            if((search_area_row<=0) || (search_area_col<=0) || (search_area_row>search_rows-block_rows+1) || (search_area_col>search_cols-block_cols+1))
                continue;
            end
            
            %calcualte the mse
            mse = MSE(Block,Search_Area(search_area_row:search_area_row+block_rows-1,search_area_col:search_area_col+block_cols-1));
            
            %update if current mse is better than previous mse valus
            if(mse<best_mse)    
                best_mse = mse;     
                best_match_vert = search_vector(point,1);
                best_match_horiz = search_vector(point,2);
                
                % cannot get better than mse of 0 --> early termination
                if(mse ==0) 
                    best_flag = true;
                    break;
                end
           end
        end
        
        %the radius is updated if the minimum remains at the centre of
        %pattern
        if((best_match_vert == current_centre_row) && (best_match_horiz == current_centre_col))
            radius = ceil(radius/2);
        end
        
        %update the 'centre' co-ordinates which are used for the above
        %check
        current_centre_row = best_match_vert;
        current_centre_col = best_match_horiz;
    end
    
    

end