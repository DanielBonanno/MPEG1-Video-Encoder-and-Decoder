%Function to obtain the Mean Square Error (MSE) between 2 matricies
%The output is the MSE and the input is the 2 matricies over which the MSE
%is to be calculated
function [MSE] = MSE(Current_Block, Predictor_Block)
    [block_height, block_width] = size(Current_Block);
    total_pixels = block_height*block_width;
    MSE = [sum(sum((Current_Block - Predictor_Block).^2))]/total_pixels;  
end