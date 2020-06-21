%Function used to encode the DC Size based on the table provied
function [code_word] = Huffman_Encode_DC(Diff_Value, Huffman_Table)
    %https://www.w3.org/Graphics/JPEG/itu-t81.pdf pg 134
    Diff_Value = abs(Diff_Value);
    
    %Obtain the Size value based on the amplitude (not binary!)
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
    
    %Find its binary representation from the tables
    SSSS_table = Huffman_Table(:,1);
    code_word = Huffman_Table{cell2mat(SSSS_table) == SSSS,3};
end
