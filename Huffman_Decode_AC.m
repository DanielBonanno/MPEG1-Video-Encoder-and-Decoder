%Function used to decode AC Runlength and Amplitude using the given Huffman
%table and input stream

function [runlength_amplitude, length_to_remove] = Huffman_Decode_AC(input_stream, huffman_table)  
  runlength_amplitude=[];
  length_to_remove = 0;
  
    %Keep running until an EOB is found
    while (true)
        %read the first bit
        first_bit = input_stream(:,length_to_remove+1);
        %the codeword has 3 bits. read them and find the index
        if(strcmp(first_bit,'0'))
            codeword = input_stream(:,length_to_remove+1:length_to_remove+2);
            index = ismember(huffman_table(:,4), codeword);
            length_to_remove = length_to_remove+2;
        %if the first bit is not 0
        else
            %obtain all the unique possible codeword lengths
            possible_lengths = unique(cell2mat(huffman_table(:,3)));
            %for each possible length, read that amount of bits and try to
            %find it in the tables, until it is found
            for codelength = 1:size(possible_lengths,1)
                current_length = possible_lengths(codelength);
                codeword = input_stream(:,length_to_remove+1:length_to_remove+current_length);
                index = ismember(huffman_table(:,4), codeword);
                if(sum(index)==1)
                    length_to_remove = length_to_remove+current_length;
                    break;
                end
            end
        end
        
        %given the index, obtain the size
        SSSS = huffman_table{index,2};
        SSSS = hex2dec(SSSS);
        %obtain also the runlength
        runlength_amplitude(end+1,1) = hex2dec(huffman_table{index,1});
        
        %If it is an EOB --> set 0,0
        if(SSSS == 0 && runlength_amplitude(end,1) == 0) 
            runlength_amplitude(end,2) = 0;
            break;
        end
        
        %Otherwise, read the ampltidude in binary, according to size
        amplitude_bin = input_stream(:,length_to_remove+1:length_to_remove+SSSS);
        length_to_remove = length_to_remove + SSSS;
        
        %decode the amplitude according to one's complement
        if(~isempty(amplitude_bin))
            %If ampltude is not 0 and amplitude in binary starts with 1, decode as is, otherwise, it is
            %negative
            if(strcmp(amplitude_bin(:,1),'1'))
                runlength_amplitude(end, 2) = bin2dec(amplitude_bin);
            else
               amplitude_bin = amplitude_bin-'0';
               amplitude_bin = +(~amplitude_bin);
               amplitude_bin = mat2str(amplitude_bin);
               if(size(amplitude_bin,2)>1)
                        amplitude_bin = amplitude_bin(2:end-1);
                        amplitude_bin = amplitude_bin(1:2:end);
               end
               runlength_amplitude(end, 2) = -bin2dec(amplitude_bin);
            end
        end
    end
end

