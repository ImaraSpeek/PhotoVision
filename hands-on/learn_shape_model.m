function [mu, pcs, lambda, multipliers, prior] = learn_shape_model(base_folder, no_dims, no_images)
%LEARN_SHAPE_MODEL Learns an active shape model from annotated face data
%
%   [mu, pcs, lambda, multipliers, prior] = learn_shape_model(base_folder, no_dims, no_images)
%
% Learns an active shape model from annotated face data. The function
% expects that base_folder contains an 'images' folder and a 'points'
% folder, and that corresponding files have corresponding names. The
% function returns a mean active shape model mu and a set of principal
% components in shape space. The function also returns the multipliers that
% can required to compute the global shape similarity transform parameters.
% Alternatively, one may run the function on a dataset of shape vectors
% specified in point_list.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Dimensionality of shape model
    if ~exist('no_dims', 'var') || isempty(no_dims)
        no_dims = 20;
    end

    % Retrieve file lists
    [images, points, israw] = get_file_lists(base_folder);
    if israw
        im = readraw([base_folder '/images/' images(1).name]);
    else
        im = imread([base_folder '/images/' images(1).name]);
    end
    
    % Select a subset of images (if desired)
    if exist('no_images', 'var') && ~isempty(no_images)
        if isstruct(no_images)
            [foo, ind] = ismember({no_images.name}, {images.name});
            ind = ind(ind ~= 0)';
            images = images(ind);
            points = points(ind);
            no_images = length(images);
        else
            images = images(1:no_images);
            points = points(1:no_images);
        end
    else
        no_images = length(images);
    end
    
    % Read all shape files, and align using Procrustes alignment
    point_list = zeros(length(points), length(read_points_file(base_folder, points(1).name)));
    for i=1:no_images
        tmp = read_points_file(base_folder, points(i).name);
        if numel(tmp) == size(point_list, 2)
            point_list(i,:) = tmp;
            if max(point_list(i,:)) < 1
                point_list(i,:) = point_list(i,:) .* repmat([size(im, 2) size(im, 1)], [1 size(point_list, 2) / 2]);
            end
            if i > 1
                tmp_shape = [point_list(i, 1:2:end); point_list(i, 2:2:end)]';
                [err, tmp_shape] = procrustes(base_shape, tmp_shape);
                tmp_shape = tmp_shape'; 
                point_list(i,:) = tmp_shape(1:end);
            else
                base_shape = [point_list(1, 1:2:end); point_list(1, 2:2:end)]';
            end
        else
            warning(['File ' points(i).name ' does not have the right number of points.']);
        end
    end    
    
    % Prevent impossible solutions
    no_dims = min(no_dims, min(size(point_list)));
    
    % Compute mean of active shape model (= base shape)
    mu = mean(point_list, 1);
    
    % Compute PCs of active shape model
    point_list = bsxfun(@minus, point_list, mu);
    [M, lambda] = eig(point_list' * point_list);
    [lambda, ind] = sort(diag(lambda), 'descend');
    pcs = M(:,ind(1:no_dims));
    lambda = lambda(1:no_dims);
    
    % Construct shape vectors for global similarity transform
    q1 = mu'; 
    q1(1:2:end) = q1(1:2:end) - mean(q1(1:2:end)); 
    q1(2:2:end) = q1(2:2:end) - mean(q1(2:2:end));
    q1(1:2:end) = q1(1:2:end) ./ max(q1(1:2:end)); 
    q1(2:2:end) = q1(2:2:end) ./ max(q1(2:2:end));
    q2 = flipud(reshape(q1, [2 size(point_list, 2) / 2])); q2 = q2(:); q2(1:2:end) = -q2(1:2:end);
    q3 = repmat([1; 0], [size(point_list, 2) / 2 1]);
    q4 = repmat([0; 1], [size(point_list, 2) / 2 1]);
    [pcs, multipliers] = mgs([q1 q2 q3 q4 pcs]);
    multipliers = diag(multipliers(1:4, 1:4));
    
    % Normalize base shape (to have minimum value 1)
    mu(1:2:end) = mu(1:2:end) - min(mu(1:2:end)) + 1;
    mu(2:2:end) = mu(2:2:end) - min(mu(2:2:end)) + 1;    
        
    % Compute mean and covariance of parameter settings for training data
    if nargout > 4
        p = zeros(size(point_list, 1), no_dims + 4);
        for i=1:no_images
            p(i,:) = (pcs \ (point_list(i,:) - mu)')';
        end
        p = p(:,5:end);
        prior.mu = [zeros(1, 4) mean(p, 1)];
        p = bsxfun(@minus, p, mean(p, 1));
        prior.sigma = (p' * p) ./ size(p, 1);        
        prior.inv_sigma = [zeros(4, no_dims + 4); [zeros(no_dims, 4) inv(prior.sigma)]];
    end
    