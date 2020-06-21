%Read the video into a cell array.
%1 = Y, 2 = U, 3 = V

function [Frames] = Read_Video(filename, Y_width, Y_height, C_width, C_height)
    fid = fopen(filename, 'r');
    video  = fread(fid, 'uchar');
    fclose(fid);
    
    Frames = cell(0,3);   
    one_frame_pixels = Y_width*Y_height+2*C_width*C_height;
    number_of_frames = size(video,1)/one_frame_pixels;
    video = reshape(video, [one_frame_pixels,number_of_frames])';
    for frame = 1:number_of_frames
       Frames{end+1,1} = reshape(video(frame,1:Y_width*Y_height), [Y_width, Y_height])';
       used = Y_width*Y_height;
       Frames{end,2} = reshape(video(frame,used+1:used+C_width*C_height),C_width, C_height)';
       used = used + C_width*C_height;
       Frames{end,3} = reshape(video(frame,used+1:used+C_width*C_height), C_width, C_height)';
    end
end



