function show_movie(base_folder, images, p, shape_model, lambda, appear_model, ind)
%SHOW_MOVIE Shows a tracking movie, given a list of images and parameters p
%
%   show_movie(base_folder, images, p, shape_model)
%   show_movie(movie, [], p, shape_model)
%   show_movie(base_folder, images, p, shape_model, lambda, appear_model, ind)
%   show_movie(movie, [], p, shape_model, lambda, appear_model, ind)
%
% Shows a tracking movie, given a list of images (thru base_folder and 
% images), parameters p, and a shape model(shape_mu and shape_pcs).
% Alternatively, one can specify the filename of movie (instead of using a
% collection of images). The tracked shape points are drawn on the image
% frames.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    if ~exist('ind', 'var') || isempty(ind)
        ind = ones(length(p), 1);
    end

    % Initialize video or frame reader
    precomp = [];
    h1 = []; h2 = [];
    if isempty(images)
        addpath('videoIO');
        setenv('LD_LIBRARY_PATH', '/usr/local/lib');
        vr = videoReader(base_folder, 'ffmpegDirect');
        info = get(vr);
        no_frames = info.numFrames;
    else
        no_frames = length(images);
    end

    % Loop over all images to plot
    for i=1:no_frames
        if isempty(images)
            next(vr); 
            im = deinterlace(getframe(vr));
        else
            im = imread([base_folder '/images/' images(i).name]);
        end 
        if ~isempty(p{i})
            if ~exist('appear_model', 'var') || isempty(appear_model)
                [h1, h2, precomp] = show_result_fit(h1, h2, im, p{1}, [], [], shape_model, [], precomp, ['Frame ' num2str(i)]);
            else
                [h1, h2, precomp] = show_result_fit(h1, h2, im, p{i}, lambda{i}, ind(i), shape_model, appear_model, precomp, ['Frame ' num2str(i)]);
            end
            pause
        else
            [h1, h2] = show_result_fit(h1, h2, im, [], [], [], [], [], precomp, ['Frame ' num2str(i)]);
        end
    end
    