function faces = face_detection(base_folder)
%FACE_DETECTION Performs face detection for all images in a folder
%
%   faces = face_detection(base_folder)
%   faces = face_detection(movie)
%   faces = face_detection(im)
%
% Performs face detection for all images in a folder, or for all frames in 
% the specified movie, or for the specified image.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Perform Viola & Jones face detection (and tracking for sequences)
    if ~isnumeric(base_folder)
        if base_folder(end - 3) ~= '.'
            images = [dir([base_folder '/*.jpg']); dir([base_folder '/*.png'])];
            files = cell(length(images), 1);
            for i=1:length(images)
                files{i} = [base_folder '/' images(i).name];
            end
            faces = FaceTrack(files, 'haarcascade_frontalface_alt.xml');
        else
            movie = base_folder;
            faces = FaceTrackVideo(movie, 'haarcascade_frontalface_alt.xml'); 
        end
    else
        im = base_folder;
        faces = FaceDetect(im, 'haarcascade_frontalface_alt.xml');
    end
