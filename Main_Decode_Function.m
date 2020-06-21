function Main_Decode_Parallel_Function(video_name, GOP, packet_size)

%load the workspace from the encoding
name = strcat(mat2str(video_name), '_Scaling1_SA8_GOP', mat2str(GOP));
load(name);

BER = 3*10^-4;

%set the input stream from the workspace
input_stream = final_binary_stream;

%set the vector where random errors is present
noise_vector = zeros(1,size((input_stream),2));
noise_indexes = randperm(size(input_stream,2), round(BER*size(input_stream,2)));
noise_vector(1,noise_indexes) = 1;

%obtain a vector which contain a 1 where an error is present in that packet
packetized_noise_vector = [];
for i = 1:packet_size:size(noise_vector,2)
    if(i+packet_size-1<size(noise_vector,2))
        if(sum(noise_vector(1,i:i+packet_size-1))>0)
            packetized_noise_vector(1,floor(i/packet_size)+1) = 1;
        else
            packetized_noise_vector(1,floor(i/packet_size)+1) = 0;
        end
    else
        if(sum(noise_vector(1,i:end))>0)
            packetized_noise_vector(1,floor(i/packet_size)+1) = 1;
        else
            packetized_noise_vector(1,floor(i/packet_size)+1) = 0;
        end
    end
end


%Definitions
y_height = 144;
y_width = 176;
uv_height = 72;
uv_width = 88;

block_height = 8;
block_width = 8;


Q_Intra = [ 8  16 19 22 26 27 29 34;
            16 16 22 24 27 29 34 37;
            19 22 26 27 29 34 34 38;
            22 22 26 27 29 34 37 40;
            22 26 27 29 32 35 40 48;
            26 27 29 32 35 40 48 58;
            26 27 29 34 38 46 56 69;
            27 29 35 38 46 56 69 83];
Q_Inter = ones(block_height, block_width)*16;

Table_Luma_DC = Huffman_Luminance_DC;
Table_Chroma_DC = Huffman_Chrominance_DC;
Table_Luma_AC = Huffman_Luminance_AC;
Table_Chroma_AC = Huffman_Chrominance_AC;

number_of_blocks_width_y = y_width/block_width;
number_of_blocks_width_uv = uv_width/block_width;

number_of_blocks_y = (y_height*y_width)/(block_height*block_width);
number_of_blocks_uv = (uv_height*uv_width)/(block_height*block_width);

previous_frame_y = zeros(y_height, y_width);
previous_frame_u = zeros(uv_height, uv_width);
previous_frame_v = zeros(uv_height, uv_width);

decoded_video = cell(0,3);

frame_counter = 1;
packet_counter = 1;
packet_pointer_old = 1;

%while there are still bits in the input stream, there is a frame
while(~isempty(input_stream))
    %the frames have 3 components
    for yuv = 1:3       
        %initialisations
        block_counter = 0;
        previous_dc = 0;
        rlc_list = cell(0,1);
        motion_vectors_list = [];
        motion_vectors_list(1,1) = 0;
        motion_vectors_list(1,2) = 0;
        
        if(yuv ==1)
            number_of_blocks = number_of_blocks_y;
            Table_DC = Table_Luma_DC;
            Table_AC = Table_Luma_AC;
        else
            number_of_blocks = number_of_blocks_uv;
            Table_DC = Table_Chroma_DC;
            Table_AC = Table_Chroma_AC;
        end
        %while we are still in the current channel and frame, decode a
        %block
        while(block_counter<number_of_blocks)

            block_counter = block_counter+1;
            input_stream_initial_length = size(input_stream,2);
            
            %start by decoding the dpcm DC value
            [dpcm_dc, length_to_remove] = Huffman_Decode_DC(input_stream, Table_DC);
            input_stream = input_stream(:,length_to_remove+1:end);
            
            %obtain the non-dpcm DC value
            current_dc = previous_dc+dpcm_dc;
            previous_dc = current_dc;
            
            %decode the runlength and amplitude of the AC block
            [runlength_amplitude, length_to_remove] = Huffman_Decode_AC(input_stream, Table_AC);
            input_stream = input_stream(:,length_to_remove+1:end);
            
            %if this is not an I-frame, obtain the motion vectors in a
            %similar manner to the DC
            if(mod(frame_counter,GOP) ~= 1)
                [dpcm_vertical, length_to_remove] = Huffman_Decode_DC(input_stream, Table_DC);
                input_stream = input_stream(:,length_to_remove+1:end);

                [dpcm_horizontal, length_to_remove] = Huffman_Decode_DC(input_stream, Table_DC);
                input_stream = input_stream(:,length_to_remove+1:end);

                current_vertical = motion_vectors_list(end,1)+dpcm_vertical;
                motion_vectors_list(end+1,1) = current_vertical;
                
                current_horizontal = motion_vectors_list(end-1,2)+dpcm_horizontal;
                motion_vectors_list(end,2) = current_horizontal;
            end
            
            %obtain 2 pointers, to check to which packets this block
            %belongs to
            input_stream_final_length = size(input_stream,2);
            packet_pointer_new = packet_pointer_old+(input_stream_initial_length - input_stream_final_length)-1;
            packet_index_1 = ceil(packet_pointer_old/packet_size);
            packet_index_2 = ceil(packet_pointer_new/packet_size);
            packet_pointer_old = packet_pointer_new;
            
            %initially, the block values are set to 0
            block_values = zeros(block_height, block_width);
            %if there are no errors, the actual values are decoded,
            %otherwise they are left as such
            if((sum(packetized_noise_vector(1,packet_index_1:packet_index_2)))==0)           
                ac_values_zigzag = [];
                %for every run in the block, fill in the ac values in
                %zigzag scan order
                for run = 1:size(runlength_amplitude,1)
                    current_run = runlength_amplitude(run,:);
                    if(current_run(1,2)~=0) %Cater for F/0.. do not add an extra 0 in this case!
                        ac_values_zigzag = [ac_values_zigzag zeros(1,current_run(1,1)) current_run(1,2)];
                    else
                        ac_values_zigzag = [ac_values_zigzag zeros(1,current_run(1,1))];
                    end
                end
                %make sure there are 63 ac coefficients (recall - 0/0 => end of
                %block, remaining are all 0s
                ac_values_zigzag = [ac_values_zigzag zeros(1,(block_height*block_width-1)-size(ac_values_zigzag,2))];
                
                %add the DC value
                values_zigzag = [current_dc ac_values_zigzag];
                %obtain the matrix representation of the values              
                block_values(Get_ZigZag_Indexes(block_height, block_width)) = values_zigzag;
                
                %perform de-quantisation accordingly
                if(mod(frame_counter,GOP) == 1)
                     block_values = round(block_values.*Q_Intra);
                else
                     block_values = round(block_values.*Q_Inter);
                end
            end
            
            %perform the inverse dct
            inv_dct = idct2(block_values);
            
            %put the block in the frame
            if(yuv ==1)
                frame_col = mod((block_counter-1),number_of_blocks_width_y)*block_width+1;
                frame_row = floor((block_counter-1)/number_of_blocks_width_y)*block_height+1;
            else
                frame_col = mod((block_counter-1),number_of_blocks_width_uv)*block_width+1;
                frame_row = floor((block_counter-1)/number_of_blocks_width_uv)*block_height+1;
            end          
            frame(frame_row:frame_row+block_height-1,frame_col:frame_col+block_width-1) = inv_dct;
           
        end
        motion_vectors_list = motion_vectors_list(2:end,:);
        %If the frame is not an I-frame
        %It means that the above is the residual error, which must be added
        %to the output of the motion compensated prediction output.
         if(mod(frame_counter,GOP) ~= 1)  
            if(yuv == 1)
                frame = frame+Motion_Compensation(double(previous_frame_y),block_width,block_height,motion_vectors_list);
            elseif(yuv==2)
                frame = frame+Motion_Compensation(double(previous_frame_u),block_width,block_height,motion_vectors_list);
            else
                frame = frame+Motion_Compensation(double(previous_frame_v),block_width,block_height,motion_vectors_list);
            end
         end
         
         %set the new predictor frame
         if(yuv == 1)
                previous_frame_y = uint8(frame);
         elseif(yuv==2)
                previous_frame_u = uint8(frame);
         else
                previous_frame_v = uint8(frame);
         end
        decoded_video(frame_counter,yuv) = {uint8(frame)};
        frame = [];

    end
    frame_counter = frame_counter+1;

end

%save the video stream
video_stream = [];
for frame = 1:size(decoded_video,1)
    for yuv = 1:3
        video_stream = [video_stream reshape(decoded_video{frame, yuv}',  [1,size(decoded_video{frame,yuv},1)*size(decoded_video{frame,yuv},2)])];
    end
end

name = strcat(mat2str(video_name), '_GOP', mat2str(GOP), '_PacketSize', mat2str(packet_size));
save(name);

fid = fopen(strcat(name,'.yuv'),'wb');
fwrite(fid,video_stream','uchar');
fclose(fid);
end
