%Generate Huffman Chominance Table for DC Size

function [table] = Huffman_Chrominance_DC()
    %https://www.w3.org/Graphics/JPEG/itu-t81.pdf pg 149
    table = cell(12,3);
    
    for category = 0:11
        table{category+1, 1} = category;
    end
       
	table{1,3} 	= '00';
    table{2,3}	= '01';
    table{3,3}	= '10';
    table{4,3} 	= '110';
    table{5,3} 	= '1110';
    table{6,3} 	= '11110';
    table{7,3} 	= '111110';
    table{8,3} 	= '1111110';
    table{9,3} 	= '11111110';
    table{10,3} = '111111110';
    table{11,3} = '1111111110';
    table{12,3} = '11111111110';
                    
   for code_length = 1:12
        table{code_length,2} = size(table{code_length,3},2);
   end
end
