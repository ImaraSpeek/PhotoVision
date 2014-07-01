%ARF_EXPERIMENT Fits independent AAMs to all images in the ARF dataset
%
%   arf_experiment
%
% Fits independent AAMs to all images in the ARF dataset. This function
% initializes using Viola & Jones and Everingham's detector for every
% image.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    close all
    clear all

    % Initialize
    %base_folder = '/Users/laurens/Desktop/Research/Computer vision/AAMs/ARF';
    base_folder = 'H:\My Documents\MATLAB\hands-on\hands-on\ARF';
    data_name = 'ARF';
    h1 = []; h2 = [];

    % Load face shape and appearance models
    k = 2;
    if isempty(dir([base_folder '/arf_aam_' num2str(k) '.mat']))
        [shape_model, appear_model] = learn_model(base_folder, 10, k, 30);
        save([base_folder '/arf_aam_' num2str(k) '.mat'], 'shape_model', 'appear_model');
    else
        load([base_folder '/arf_aam_' num2str(k) '.mat']);
    end
    if exist('data_name', 'var')
        shape_model.transf_mult = data_name;
    end
    
    % Retrieve file lists
    [images, points, israw] = get_file_lists(base_folder);
    
    % Initialize some variables
    p      = cell(length(images), 1);
    lambda = cell(length(images), 1); 
    ind   = zeros(length(images), 1);
    err   = zeros(length(images), 1);               % MSE of appearance fit
    err2  = zeros(length(images), 1);               % point-to-point error of shape fit
    
    % Start tracking
    tic
    for i=1:length(images)
        
        % Fit AAM to current image
        disp(['Image ' num2str(i) ' from ' num2str(length(images)) '...']);
        if israw
            im = readraw([base_folder '/images/' images(i).name]);
        else
            im = imread([base_folder '/images/' images(i).name]);
        end
        if i == 1
            [p{i}, lambda{i}, err(i), ind(i), diverged, precomp] = fit_model([], [], im, shape_model, appear_model, 'color');
        else
            [p{i}, lambda{i}, err(i), ind(i), diverged] = fit_model([], [], im, shape_model, appear_model, 'color', precomp);
        end
        
        % We can only proceed if we found a fit
        if ~isempty(p{i})

            % Compute divergence between fit and ground truth
            cur_shape = shape_model.shape_mu + sum(bsxfun(@times, p{i}, shape_model.shape_pcs), 2)';
            true_shape = read_points_file(base_folder, points(i).name);
            err2(i) = mean_point_err(cur_shape, true_shape);

            % Show result fit
            if i == 1
                [h1, h2, plot_precomp] = show_result_fit(h1, h2, im, p{i}, lambda{i}, ind(i), shape_model, appear_model);
            else
                [h1, h2]               = show_result_fit(h1, h2, im, p{i}, lambda{i}, ind(i), shape_model, appear_model, plot_precomp);
            end

            % Save results
            imwrite(get(h1, 'CData'), [base_folder '/fits/shape_' images(i).name '.png']); 
            imwrite(get(h2, 'CData'), [base_folder '/fits/appear_' images(i).name '.png']);
        end
        disp(['Point-to-point error of fit: ' num2str(err2(i))]);
        disp(['Mean error so far: ' num2str(sum(err2) / i)]);
    end
    t = toc;
    
    % Gather performance statistics 
    disp(['Processed images at ' num2str(length(images) / t) ' FPS.']);
    disp(['Mean point-to-point error: ' num2str(mean(err2))]);
    save([base_folder '/arf_fits_k=' num2str(k) '.mat'], 'p', 'lambda', 'images', 'err', 'err2', 'ind');
    