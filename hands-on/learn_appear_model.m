function [mu, M, means, pcs, mixing, size_aam, prior] = learn_appear_model(base_folder, base_shape, k, no_dims, no_images)
%LEARN_APPEAR_MODEL Learns multiple appearance models using MoPPCA
%
%   [mu, M, means, pcs, mixing, size_aam, prior] = learn_appear_model(base_folder, base_shape, k, no_dims, no_images)
%
% Learns multiple appearance models from annotated face data using MoPPCA. 
% The function expects that base_folder contains an 'images' folder and a 
% 'points' folder, and that corresponding files have corresponding names. 
% The function returns the mean of the appearance models in means, and the 
% principal components in pcs. The MoPPCA model lives in a linear subspace
% of the original image space, which is defines by mean mu and linear
% mapping M. The vector size_aam indicated the size of the resulting
% appearance images.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Dimensionality of appearance model
    if ~exist('no_dims', 'var') || isempty(no_dims)
        no_dims = 50;
    end

    % Retrieve file lists
    [images, points, israw] = get_file_lists(base_folder);
    ind = randperm(length(images));
    images = images(ind);
    points = points(ind);
    
    % Store which pixels are inside the base shape's convex hull
    base_shape_x = base_shape(1:2:end)';
    base_shape_y = base_shape(2:2:end)';
    size_aam = [ceil(max(base_shape_y)) ceil(max(base_shape_x)) 3];
       
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
    
    % Make sure we don't run out of memory (1 GB max)
    if no_images * prod(size_aam) * 8 > 1e9
        no_images = ceil(1e9 / (prod(size_aam) * 8));
        warning(['Reducing to ' num2str(no_images) ' images in PCA preprocessing...']);
    end
    
    % Loop over all files
    X = zeros(no_images, prod(size_aam));
    point_list = zeros(no_images, length(read_points_file(base_folder, points(1).name)));
    for i=1:no_images
            
        % Read image and retrieve face shape
        if ~israw
            im = imread([base_folder '/images/' images(i).name]);
        else
            im = readraw([base_folder '/images/' images(i).name]);
        end
        im = double(im) ./ 255;
        if ndims(im) == 2
            im = repmat(im, [1 1 3]);
        end
        point_list(i,:) = read_points_file(base_folder, points(i).name);
        if max(point_list(i,:)) < 1
            point_list(i,:) = point_list(i,:) .* repmat([size(im, 2) size(im, 1)], [1 size(point_list, 2) / 2]);
        end
        
        % Normalize face image (perform linear warp to base shape)
        if i == 1
            [trans_im, precompY, precompX] = pw_linear_warp(im, base_shape, point_list(i,:), size_aam);
        else
            trans_im = pw_linear_warp(im, base_shape, point_list(i,:), size_aam, precompY, precompX);
        end
        trans_im = trans_im(1:end);
        X(i,:) = trans_im;
    end
    
    % Prevent impossible solutions
    no_dims = min(no_dims, min(size(X)));
    
    % Compute mean of appearance images
    mu = mean(X, 1);
    
    % Perform PCA on appearance images (for computational reasons)
    if k == 1
        init_dims = no_dims;
    else
        init_dims = 3 * no_dims;
    end
    X = bsxfun(@minus, X, mu);
    [M, lambda] = eig((1 / size(X, 1)) * (X * X'));
    [lambda, ind] = sort(diag(lambda), 'descend');
    M = M(:,ind(1:min(init_dims, size(X, 1))));   
    lambda = lambda(1:min(init_dims, size(X, 1)));
    M = bsxfun(@times, X' * M, (1 ./ sqrt(size(X, 1) .* lambda))');
    
%     % Project out camera gain and offset
%     offset = mu';
%     offset = offset ./ sqrt(sum(offset .^ 2));
%     gain = ones(numel(mu), 1);
%     gain(mu == 0) = 0;
%     gain = gain ./ sqrt(sum(gain .^ 2));
%     M = mgs([offset gain M]);
%     M = M(:,3:end);
    
    % Perform PCA mapping on all training data
    if no_images == length(images) || k == 1
        mappedX = X * M;
        clear X
    else                                                        % we can use all training images now!
        clear X
        mappedX = zeros(length(images), size(M, 2));        
        for i=1:length(images)
            
            % Read image, warp it to the base shape, and perform PCA
            if ~israw
                im = imread([base_folder '/images/' images(i).name]);
            else
                im = readraw([base_folder '/images/' images(i).name]);
            end
            im = double(im) ./ 255;
            if ndims(im) == 2
                im = repmat(im, [1 1 3]);
            end
            point = read_points_file(base_folder, points(i).name);
            trans_im = pw_linear_warp(im, base_shape, point, size_aam, precompY, precompX);
            trans_im = trans_im(1:end) - mean(trans_im(:));
            mappedX(i,:) = trans_im * M;
        end
    end
    
    % Fit a mixture of probabilistic PCA models to the preprocessed data
    if k > 1
        [logl, MoFA, Q] = mfa(mappedX', no_dims, k, true, false, true);
        means = MoFA.M;
        pcs   = MoFA.W;
%         means = [zeros(2, size(MoFA.M, 2)); MoFA.M];
%         pcs = [repmat([[1 0; 0 1]; zeros(size(MoFA.W, 1), 2)], [1 1 size(MoFA.W, 3)]) [zeros(2, size(MoFA.W, 2), size(MoFA.W, 3)); MoFA.W]];
        for i=1:k
            pcs(:,:,i) = mgs(pcs(:,:,i));
        end
        mixing = MoFA.mix;
    else
        means = zeros(no_dims, 1);
        pcs = eye(no_dims);
%         means = zeros(no_dims + 2, 1);
%         pcs = eye(no_dims + 2);
        mixing = 1;
    end
    
%     % In the fitting, we do need to camera gain and offset components
%     M = [offset gain M];
    
    % Learn Mixture of Gaussian prior over appearance parameters
    if nargout > 6
        prior = [];
%         lambda = zeros(no_images, no_dims);
%         for i=1:no_images
%             if ~israw
%                 im = imread([base_folder '/images/' images(i).name]);
%             else
%                 im = readraw([base_folder '/images/' images(i).name]);
%             end
%             im = double(im) ./ 255;
%             if ndims(im) == 2
%                 im = repmat(im, [1 1 3]);
%             end
%             trans_im = pw_linear_warp(im, base_shape, point_list(i,:), size_aam, precompY, precompX);
%             error_im = compute_error_im(trans_im, mu);
%             lambda(i,:) = error_im(1:end) * pcs;
%         end
%         prior.mu = mean(lambda, 1);
%         lambda = bsxfun(@minus, lambda, mean(lambda, 1));
%         prior.sigma = (lambda' * lambda) ./ size(lambda, 1);        
%         prior.inv_sigma = inv(prior.sigma);
%         prior.mixing = mixing;
    end
    