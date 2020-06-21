%Function used to encode the AC Runlength/Size based on the table provied

function [code_word] = Huffman_Encode_AC(Run_Length, Diff_Value, Huffman_Table)
    %https://www.w3.org/Graphics/JPEG/itu-t81.pdf pg 134
    
    %Obtain the Size value based on the amplitude (not binary!)
    Diff_Value = abs(Diff_Value);
    if(Diff_Value == 0) 
        SSSS = 0;
    elseif(Diff_Value == 1)
        SSSS = 1;
    else
        SSSS = ceil(log2(Diff_Value));
        if(ceil(log2(Diff_Value)) == log2(Diff_Value))
            SSSS = SSSS+1;
        end
    end
    if(SSSS == 10)
        SSSS = 'A';
    else
        SSSS = mat2str(SSSS);
    end
    
    Run_table = Huffman_Table(:,1);
    SSSS_table = Huffman_Table(:,2);

    %Obtain the indexes from the table where the runlength = input
    %runlength
    run_index = cell2mat(Run_table) == Run_Length;
    
    %Obtain the indexes from the table where the size = input
    %size
    size_index = cell2mat(SSSS_table) == SSSS;

    %Find the common index and obtain the binary representation
    common_index = and(run_index, size_index);
    code_word = Huffman_Table{common_index,4};
    
end
