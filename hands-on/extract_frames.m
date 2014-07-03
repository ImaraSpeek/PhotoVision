function extract_frames(movie, image_folder, shot_labels, frontal_shots, debat_number)
%EXTRACT_FRAMES Extracts frames from movie and saves them as images
%
%   extract_frames(movie, image_folder, shot_labels, frontal_shots, debat_number)
%
% Extracts frames from the specified movie and saves them as images in the
% folder image_folder. If show_labels and frontal_shots are provided, only
% selected frames are extracted.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    close all
    addpath('videoIO');
    
    % Open debat movie
    vr = videoReader(movie, 'ffmpegDirect');
    info = get(vr);
    no_frames = info.numFrames;
    
    % Make sure we have shot labels
    if ~exist('shot_labels', 'var') || isempty(shot_labels)
        shot_labels = ones(no_frames, 1);
    end
    if ~exist('frontal_shots', 'var') || isempty(frontal_shots)
        frontal_shots = 1;
    end
    if ~exist('debat_number', 'var') || isempty(debat_number)
        debat_number = 'unknown';
    end
    
    % Open image folder
    if isempty(dir(image_folder))
        mkdir(image_folder);
    end
    if exist('shot_labels', 'var')
        shot_lablist = unique(shot_labels);
    end
    
    % Start extracting frames
    for i=1:no_frames
        
        if ~rem(i, 500)
            disp(['Processing frame ' num2str(i) ' of ' num2str(no_frames) '...']);
        end
        
        % Get new frame
        next(vr);
        im = getframe(vr);
        
        % Only process frontal face shots (if specified)
        extract_frame = false;
        if exist('shot_labels', 'var') && exist('frontal_shots', 'var')
            if ismember(shot_labels(i), frontal_shots)
                extract_frame = true;
            end
        else
            extract_frame = true;
        end
        
%         % Show frame
%         if ~exist('h', 'var') || isempty(h)
%             h = imshow(im);
%             set(h, 'EraseMode', 'none');
%         else
%             set(h, 'CData', im);
%         end
%         drawnow
%         title(['Frame ' num2str(i) ', shot ' num2str(shot_labels(i))]);
 
        % Write frame into image file
        if extract_frame
            tmp = ['0000' num2str(i)]; tmp = tmp(end - 4:end); 
            imwrite(deinterlace(im), [image_folder '/images/' debat_number '_frame_' tmp '.png']);
        end
    end
    
    % Close video file
    close(vr);
        