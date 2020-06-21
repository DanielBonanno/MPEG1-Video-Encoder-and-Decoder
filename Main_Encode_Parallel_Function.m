function Main_Encode_Parallel_Function(video_name, quantization_scaling, search_area, GOP)
filename = strcat('Test_Videos/', mat2str(video_name), '.yuv');

%Frame Resolutions
y_height = 144;
y_width = 176;
uv_height = 72;
uv_width = 88;

%Definitions
block_height = 8;
block_width = 8;

Q_Intra = quantization_scaling.* [ 8  16 19 22 26 27 29 34;
            16 16 22 24 27 29 34 37;
            19 22 26 27 29 34 34 38;
            22 22 26 27 29 34 37 40;
            22 26 27 29 32 35 40 48;
            26 27 29 32 35 40 48 58;
            26 27 29 34 38 46 56 69;
            27 29 35 38 46 56 69 83];
Q_Inter = quantization_scaling.*ones(block_height, block_width)*16;
search_vert = search_area;
search_horiz = search_area;

%Huffman Tables
Table_Luma_DC = Huffman_Luminance_DC;
Table_Chroma_DC = Huffman_Chrominance_DC;
Table_Luma_AC = Huffman_Luminance_AC;
Table_Chroma_AC = Huffman_Chrominance_AC;

%Read the video file and obtain the number of frames
video = Read_Video(filename, y_width, y_height, uv_width, uv_height);
number_of_frames = size(video,1);

binary_stream = '';
video_binary_stream = cell(number_of_frames,1);

%For every Frame and YUV Component
for frame = 1:number_of_frames
    for yuv = 1:3
        current_frame = video{frame,yuv};
        %Obtain the predcited frame (If I-frame --> predicted is all 0s)
        %Obtain also the motion vectors (If I-frame --> [])
        if(mod(frame,GOP) == 1)
            predicted_frame = zeros(size(current_frame));
            motion_vectors = [];
        else          
            if(yuv == 1)
                motion_vectors = Motion_Estimation(stored_frame_y, current_frame, block_width,block_width,search_vert,search_horiz);
                predicted_frame = Motion_Compensation(stored_frame_y,block_width,block_height,motion_vectors);
            elseif(yuv==2)
                motion_vectors = Motion_Estimation(stored_frame_u, current_frame, block_width,block_width,search_vert,search_horiz);
                predicted_frame = Motion_Compensation(stored_frame_u,block_width,block_height,motion_vectors);
            else
                motion_vectors = Motion_Estimation(stored_frame_v, current_frame, block_width,block_width,search_vert,search_horiz);
                predicted_frame = Motion_Compensation(stored_frame_v,block_width,block_height,motion_vectors);
            end
        end
        
        %Obtain the residual error and segment it into blocks
        predicted_frame  = double(predicted_frame);
        error = current_frame - predicted_frame;
        segmented_error = Segment_Frame(error, block_width, block_height);
        
        %For every block, obtain the DCT values and quantize accordingly
        dct_segmented_error = cellfun(@dct2, segmented_error,'UniformOutput', false);
        quantized_dct_segmented_error = cell(size(dct_segmented_error,1), size(dct_segmented_error,2));
        inv_quantized_dct_segmented_error = cell(size(dct_segmented_error,1), size(dct_segmented_error,2));
        for length = 1:size(dct_segmented_error,1)
            for width = 1:size(dct_segmented_error, 2)
                if(mod(frame,GOP) == 1)
                    quantized_dct_segmented_error{length,width} = round(dct_segmented_error{length,width}./Q_Intra);
                    inv_quantized_dct_segmented_error{length,width} = quantized_dct_segmented_error{length,width}.* Q_Intra;
                else
                    quantized_dct_segmented_error{length,width} = round(dct_segmented_error{length,width}./Q_Inter);
                    inv_quantized_dct_segmented_error{length,width} = quantized_dct_segmented_error{length,width}.* Q_Inter;
                end
            end
        end
        
        %perform zig-zag scanning on each block
        zig_zag_indexes = Get_ZigZag_Indexes(block_width, block_height);
        blocks_along_y = size(quantized_dct_segmented_error, 1);
        blocks_along_x = size(quantized_dct_segmented_error, 2);
        zig_zag_dct = zeros(blocks_along_y*blocks_along_x, block_width*block_height);
        for block_y = 1:blocks_along_y
            for block_x = 1:blocks_along_x
                current_block = quantized_dct_segmented_error{block_y, block_x};
                zig_zag_dct(blocks_along_x*(block_y-1)+block_x, :) = current_block(zig_zag_indexes);
            end
        end
        
        %split into dc and ac coefficients
        dc_coefficients = zig_zag_dct(:,1);
        ac_coefficients = zig_zag_dct(:, 2:end);
        
        %obtain dpcm encoded dct coefficients
        dc_coefficients = [0; dc_coefficients];
        dpcm_dc = dc_coefficients(2:end) - dc_coefficients(1:end-1);
        
        %obtain rlc representation of ac coefficients
        rlc_ac = RLC(ac_coefficients);
        
        %obtain dpcm representation of motion vectors
        motion_vectors = [[0 0 0]; motion_vectors];
        dpcm_motion_vectors = motion_vectors(2:end,:) - motion_vectors(1:end-1,:);
        
        %obtain the binary representations - Entropy Coding
        binary_dc = cell(size(dpcm_dc,1),1);   %1 = SIZE in binary, 2 = AMPLITUDE in 1s comp
        binary_ac = cell(size(rlc_ac,1),1);   %1 = RUNLENGHT/SIZE in binary, 2 = AMPLITUDE in 1s comp    
        binary_motion_vec = cell(size(motion_vectors,1),1); %1 = vertical, %2 = horizontal
        
        %for DC
        parfor block = 1:size(dpcm_dc,1)
            %obtain entropy coded DC Size
            if(yuv == 1)
                binary_dc{block, 1} = Huffman_Encode_DC(dpcm_dc(block), Table_Luma_DC);
            else
                binary_dc{block, 1} = Huffman_Encode_DC(dpcm_dc(block), Table_Chroma_DC);
            end
            
            %Encode the Amplitude using one's complement
            if(dpcm_dc(block)~=0)
                bin_val = dec2bin(abs(dpcm_dc(block)))-'0';
                if(dpcm_dc(block)<0)
                    bin_val = +(~bin_val);
                end
                bin_val = mat2str(bin_val);
                if(size(bin_val,2)>1)
                    bin_val = bin_val(2:end-1);
                    bin_val = bin_val(1:2:end);
                end
                binary_dc{block,1} = strcat(binary_dc{block,1},bin_val);
            end
        end
        
        %for AC
        parfor block = 1:size(rlc_ac,1)  
            all_runs = rlc_ac(block,:);
            run_lengths = all_runs{:,1};
            run_amplitude = all_runs{:,2};
            %for every run in the current block
            for run = 1:size(run_lengths,1) 
                current_length = run_lengths(run,1);
                current_amplitude = run_amplitude(run,1);
                %Encode the Runlength/Size representation    
                if(yuv == 1)
                    binary_ac{block,1} = strcat(binary_ac{block,1},Huffman_Encode_AC(current_length,current_amplitude, Table_Luma_AC));
                else
                    binary_ac{block,1} = strcat(binary_ac{block,1},Huffman_Encode_AC(current_length,current_amplitude, Table_Chroma_AC));
                end
                
                %Encode the Amplitude using one's complement
                if(current_amplitude ~= 0 )
                    bin_val = dec2bin(abs(current_amplitude))-'0';
                    if(current_amplitude<0)
                        bin_val = +(~bin_val);
                    end
                    bin_val = mat2str(bin_val);
                    if(size(bin_val,2)>1)
                        bin_val = bin_val(2:end-1);
                        bin_val = bin_val(1:2:end);
                    end
                    binary_ac{block,1} = strcat(binary_ac{block,1},bin_val);
                end
            end
            %Ensure it ends in 0/0
            if(run_lengths(end,1)~=0) && (run_amplitude(end,1) ~=0)
                if(yuv == 1)
                    binary_ac{block,1} = strcat(binary_ac{block,1},'1010');
                else
                    binary_ac{block,1} = strcat(binary_ac{block,1},'00');
                end
            end
        end
        
        %If it is not an I-Frame, obtain the Entropy Coded DPCM motion
        %vector
        if(~(mod(frame,GOP) == 1))           
            parfor block = 1:size(dpcm_motion_vectors,1)
                vertical = dpcm_motion_vectors(block,1);
                horizontal = dpcm_motion_vectors(block,2);
                
                %First for vertical motion vector
                %obtain entropy coded Size
                if(yuv == 1)
                    binary_motion_vec{block, 1} = Huffman_Encode_DC(vertical, Table_Luma_DC);
                else
                    binary_motion_vec{block, 1} = Huffman_Encode_DC(vertical, Table_Chroma_DC);
                end

                %Encode the Vertical Amplitude using one's complement
                if(vertical~=0)
                    bin_val = dec2bin(abs(vertical))-'0';
                    if(vertical<0)
                        bin_val = +(~bin_val);
                    end
                    bin_val = mat2str(bin_val);
                    if(size(bin_val,2)>1)
                        bin_val = bin_val(2:end-1);
                        bin_val = bin_val(1:2:end);
                    end
                    binary_motion_vec{block,1} = strcat(binary_motion_vec{block,1},bin_val);
                end
                
                %Then for the horizontal
                %obtain entropy coded Size
                if(yuv == 1)
                    binary_motion_vec{block, 1} = strcat(binary_motion_vec{block, 1}, Huffman_Encode_DC(horizontal, Table_Luma_DC));
                else
                    binary_motion_vec{block, 1} = strcat(binary_motion_vec{block, 1}, Huffman_Encode_DC(horizontal, Table_Chroma_DC));
                end
            
                %Encode the Horizontal Amplitude using one's complement
                if(horizontal~=0)
                    bin_val = dec2bin(abs(horizontal))-'0';
                    if(horizontal<0)
                        bin_val = +(~bin_val);
                    end
                    bin_val = mat2str(bin_val);
                    if(size(bin_val,2)>1)
                        bin_val = bin_val(2:end-1);
                        bin_val = bin_val(1:2:end);
                    end
                    binary_motion_vec{block,1} = strcat(binary_motion_vec{block,1},bin_val);
                end
            end    
        end              
      
      %Obtain a binary stream for every frame, made up of all the blocks in
      %a frame, store it in video_binary stream and reset the binary_stream
      %variable for the next frame
      for block = 1:size(dpcm_dc,1)
           if(mod(frame,GOP) == 1)
                binary_stream = strcat(binary_stream, binary_dc{block,1}, binary_ac{block,1});
           else
                binary_stream = strcat(binary_stream, binary_dc{block,1}, binary_ac{block,1}, binary_motion_vec{block,1});
           end
      end
      %NOTE: Here concatenation is required since every frame has 3
      %components. Therefore, we have Y binary stream, U binary stream and
      %V binary stream in same cell
       video_binary_stream{frame,1} = strcat(video_binary_stream{frame,1},binary_stream);
       binary_stream = '';
      
      %Perform the inverse dct on each quantized dct block 
       inv_dct_segmented_error = cellfun(@idct2, inv_quantized_dct_segmented_error,'UniformOutput', false);
       inv_dct_error = cell2mat(inv_dct_segmented_error);
       
       %obtain the next predictor frame (what the decoder has) from which
       %motion vectors can be calculted (this is used in step 1)
       if(yuv == 1)
            stored_frame_y = uint8(predicted_frame + inv_dct_error);
       elseif(yuv==2)
            stored_frame_u = uint8(predicted_frame + inv_dct_error);
       else
            stored_frame_v = uint8(predicted_frame + inv_dct_error);
       end
               
    end
end

%obtain a final representation for the whole video
final_binary_stream = [video_binary_stream{:,1}];

%save workspace
name = strcat(mat2str(video_name), '_Scaling', mat2str(quantization_scaling), '_SA', mat2str(search_area), '_GOP', mat2str(GOP));
save(name);
end