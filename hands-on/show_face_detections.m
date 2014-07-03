function show_face_detections(base_folder, faces)
%SHOW_FACE_DETECTIONS Shows a series of face detections
%
%   show_face_detections(base_folder, faces)
%   show_face_detections(movie, faces)
%
% Shows a series of face detections. The face detections can be produced 
% using the FACE_DETECTION function.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    close all
    addpath('videoIO');

    % Find out whether we have a movie or not
    tmp = dir(base_folder);
    if ~tmp(1).isdir
        movie = true;
    else
        movie = false;
    end

    % Open the movie or get image file list
    if movie
        vr = videoReader(base_folder, 'ffmpegDirect');
        info = get(vr);
        no_frames = info.numFrames;
    else
        images = [dir([base_folder '/*.jpg']); dir([base_folder '/*.png'])];
        no_frames = length(images);
    end
    
    % Loop over all frames
    for i=1:no_frames
        
        % Get current frame
        if movie
            next(vr);
            im = getframe(vr);
        else
            im = imread([base_folder '/' images(i).name]);
        end
        
        % Show or update image
        if ~exist('h', 'var') || isempty(h)
            h = imshow(im);
            set(h, 'EraseMode', 'none');
        else
            for j=1:length(h2)
                delete(h2(j));
            end
            set(h, 'CData', im);
        end
        hold on
        
        % Draw rectangles for face detections
        cur_faces = faces{i};
        h2 = zeros(size(cur_faces, 2), 1);
        for j=1:size(cur_faces, 2)          
            face = cur_faces(:,j);
            if ~isempty(face)
                h2(j) = rectangle('Position', [face(1) face(3) face(2) - face(1) face(4) - face(3)], 'EdgeColor', [1 0 0]);
            end
        end
        drawnow
    end
    
    % Close movie
    if movie
        close(vr);
    end
    