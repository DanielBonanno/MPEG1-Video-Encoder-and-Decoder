%Function used to decode DC Amplitude using the given Huffman
%table and input stream
function [dc_amplitude, length_to_remove] = Huffman_Decode_DC(input_stream, huffman_table)
    length_to_remove = 0;
    codeword = input_stream(:,1:2);
   
    %from the first 2 bits, try to decode Size
    if(strcmp(codeword,'00'))
        SSSS = 0;
        length_to_remove = length_to_remove + 2;
    elseif (strcmp(codeword, '01'))
        index = ismember(huffman_table(:,3), codeword);
        if(sum(index)==1)
            SSSS = huffman_table{index,1};
            length_to_remove = length_to_remove + 2;
        else
            %if it's not the first 2 bits, try the first 3
            codeword = input_stream(:,1:3);
            index = ismember(huffman_table(:,3), codeword);
            if(sum(index)==1)
                SSSS = huffman_table{index,1};
                length_to_remove = length_to_remove + 3;
            end
        end
    %if it is not one of the above
    else
       %obtain all the unique possible codeword lengths
        possible_lengths = unique(cell2mat(huffman_table(:,2)));
        for codelength = 1:size(possible_lengths,1)
            %for each possible length, read that amount of bits and try to
            %find it in the tables, until it is found
            current_length = possible_lengths(codelength);
            codeword = input_stream(:,length_to_remove+1:length_to_remove+current_length);
            index = ismember(huffman_table(:,3), codeword);
            if(sum(index)==1)
                SSSS = huffman_table{index,1};
                length_to_remove = length_to_remove+current_length;
                break;
            end
        end
    end
    
    %Read the ampltidude in binary, according to size
    amplitude_bin = input_stream(:,length_to_remove+1:length_to_remove+SSSS);
    length_to_remove = length_to_remove + SSSS;
    
    %decode the amplitude according to one's complement
    if(~isempty(amplitude_bin))
        %If ampltude is not 0 and amplitude in binary starts with 1, decode as is, otherwise, it is
        %negative
        if(strcmp(amplitude_bin(:,1),'1'))
            dc_amplitude = bin2dec(amplitude_bin);
        else
            amplitude_bin = amplitude_bin-'0';
            amplitude_bin = +(~amplitude_bin);
            amplitude_bin = mat2str(amplitude_bin);
            if(size(amplitude_bin,2)>1)
                amplitude_bin = amplitude_bin(2:end-1);
                amplitude_bin = amplitude_bin(1:2:end);
            end
            dc_amplitude = -bin2dec(amplitude_bin);
        end
    else
        %is no bits are read --> amplitude is 0
        dc_amplitude = 0;
    end
end
