function video = read_movie(filename, frames)
%READ_MOVIE Reads a bunch of frames from a video
%
%   video = read_movie(filename, frames)
%
% Reads the specified frame numbers from the movie in filename. If frames
% is not specified, the entire video is read. The function requires a
% working installation of ffmpeg or DirectShow, and of videoIO. The user
% may need to specify the library path to ffmpeg.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Make sure Matlab can find ffmpeg (change for your computer)
    setenv('LD_LIBRARY_PATH', '/usr/local/lib');
    
    % Open video
    vr = videoReader(filename, 'ffmpegDirect');
    info = get(vr);
    
    % Make sure we get the right number of frames
    if ~exist('frames', 'var')
        frames = 1:info.numFrames;
    end
    if any(frames > info.numFrames | frames < 1)
        frames(frames > info.numFrames | frames < 1) = [];
        warning('Non-existing frame numbers were specified. These are removed!');
    end
    frames = frames - 1;
       
    % Allocate memory for the video
    video = zeros(info.height, info.width, 3, length(frames), 'uint8');
    
    % Read and show video
    for i=1:length(frames)
      
        % Jump to right position
        if i == 1 || frames(i) - frames(i - 1) == 1
            next(vr);
        else 
            seek(vr, frames(i));
        end
        
        % Get and show frame
        video(:,:,:,i) = getframe(vr);
    end
    
    % Close video-file
    close(vr);
