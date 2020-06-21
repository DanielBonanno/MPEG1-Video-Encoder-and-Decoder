% This function is used to perform run length coding on the discrete
% cosine transform coefficnets after they are read in a zig-zag fashion

function [RLC] = RLC(vector)
    RLC = cell(size(vector,1), 2); % 1 = Run, 2 = Amplitude 
    
    %for every block
    for block = 1:size(vector,1)
        current_block_coeff = vector(block, :);
        
        %a series of runs and amplitudes are required
        zero_counter = 0;
        run = [];
        amplitude = [];
        for coeff = 1:size(vector,2)
            %if the this coefficient is 0
            if(current_block_coeff(1,coeff) == 0)
                %Check for end of block
                if(sum(abs(current_block_coeff(1,coeff:end))) == 0)
                    run = [run; dec2hex(0)];
                    amplitude = [amplitude; 0];
                    break;
                else
                    %increment the zero counter
                    zero_counter = zero_counter+1;
                    %Check for ZRL
                    if(zero_counter == 15)
                        run = [run; dec2hex(15)];
                        amplitude = [amplitude; 0];
                        zero_counter = 0;
                    end
                end
            %otherwise, set the run and ampltiude and reset the
            %zero_counter
            else
                run = [run; dec2hex(zero_counter)];
                amplitude = [amplitude; current_block_coeff(1,coeff)];  
                zero_counter = 0;
            end
        end
        RLC{block, 1} = run;
        RLC{block, 2} = amplitude;
    end
    
end