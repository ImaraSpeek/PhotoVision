function [p, lambda, err, diverged, precomp] = fit_aam_gray(p, im, shape_mu, shape_pcs, transf_mult, prior, appearance_mu, appearance_pcs, size_aam, precomp)
%FIT_AAM_GRAY Performs inverse compositional algorithm to fit an AAM
%
%   [p, lambda, err, diverged, precomp] = fit_aam_gray(p, im, shape_mu, shape_pcs, ...
%     prior, transf_mult, appearance_mu, appearance_pcs, size_aam, precomp)
%
%   [p, lambda, err, diverged, precomp] = fit_aam_gray(p, im, shape_mu, shape_pcs, ...
%     prior, data_name, appearance_mu, appearance_pcs, size_aam, precomp)
%
% Performs the inverse compositional algorithm to perform the fitting of an 
% AAM model to an image. The function takes the AAM as input, and optional 
% shape parameters p. The function returns the fitted shape parameters p, 
% the fitted appearance parameters lambda, the squared error of the 
% appearance fit, and a Boolean indicating whether the fitting procedure 
% has diverged.
% If the same AAM is used iteratively, the structure precomp may be
% employed to speed up computations.
%
% This function is a faster variant of FIT_AAM that uses only grayscale
% images.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Initialize shape, rotation, and location parameters
    if ~exist('p', 'var') || isempty(p)
        p = initialize_aam(im, shape_mu, shape_pcs, transf_mult);
        if isempty(p)
            lambda = [];
            err = Inf;
            diverged = true;
            if ~exist('precomp', 'var') 
                precomp = [];
            end
            return;
        end
    end

    % Initialize some variables
    min_iter = 5;
    max_iter = 30;
%     lambda = 0;                               % regularization parameter (for Gaussian prior)
    height = size_aam(1);
    width  = size_aam(2);
    base_shape_x = shape_mu(1:2:end)';
    base_shape_y = shape_mu(2:2:end)';
    iter = 0;
    
    % Make sure variables have correct format
    if size(p, 1) > 1
        p = p';
    end
    if ndims(im) > 2
        im = rgb2gray(im);
    end
    im = double(im) ./ 255;
    size_aam = size_aam(1:2);
    
    % Perform precomputations
    if ~exist('precomp', 'var') || isempty(precomp)
        
        % Perform Delaunay triangulation
        tri = delaunay(base_shape_x, base_shape_y);
        
        % Convert color AAM to grayscale AAM
        appearance_mu = mean(reshape(appearance_mu, [size_aam 3]), 3);
        appearance_pcs_gray = zeros(size(appearance_pcs, 1) / 3, size(appearance_pcs, 2));
        for i=1:size(appearance_pcs, 2)
            tmp = mean(reshape(appearance_pcs(:,i), [size_aam 3]), 3);
            appearance_pcs_gray(:,i) = tmp(:);
        end
        appearance_pcs = appearance_pcs_gray;
        clear appearance_pcs_gray
        
        % Orthogonalize the grayscale AAM
        appearance_pcs = mgs(appearance_pcs);

        % Precompute gradients of template
        Ty = [zeros(1, width); diff(appearance_mu, [], 1)];
        Tx = [zeros(height, 1) diff(appearance_mu, [], 2)];        
                
        % Remove border artefacts in template gradient
        [i1, i2] = meshgrid(1:size_aam(2), 1:size_aam(1));
        inh = bwmorph(reshape(inhull([i1(:) i2(:)], [base_shape_x base_shape_y]), [size_aam(1) size_aam(2)]), 'erode');
        Ty(~inh) = 0;
        Tx(~inh) = 0;
        
        % Center template gradients (good idea?)
        Ty = (Ty + [Ty(2:end,:); zeros(1, width)])  ./ 2; Ty = Ty(:);
        Tx = (Tx + [Tx(:,2:end)  zeros(height, 1)]) ./ 2; Tx = Tx(:);
        
        % Precompute the Jacobian of the warping at p=0
        J = pw_linear_warp_jacobian(zeros(size(p)), shape_mu, shape_pcs, size_aam);
        J = reshape(J, [width * height 2 numel(p)]);

        % Precompute steepest descent images (without appearance variation)
        desc_im = repmat([Tx Ty], [1 1 numel(p)]) .* J;
                
        % Modify steepest descent images to project out appearance variation
        update = zeros(height * width, 2, numel(p));
        for i=1:size(appearance_pcs, 2)
            appear_i = appearance_pcs(:,i);
            update = update + bsxfun(@times, repmat(appear_i, [1 2 numel(p)]), sum(bsxfun(@times, appear_i, desc_im), 1));
        end
        desc_im = desc_im - update;
        
        % Precompute the Gauss-Newton approximation to the Hessian
        desc_im = squeeze(sum(desc_im, 2));
        invH = inv(desc_im' * desc_im);
        
        % Store precomputation structure
        precomp.appearance_mu  = appearance_mu;
        precomp.appearance_pcs = appearance_pcs;
        precomp.desc_im        = desc_im;
        precomp.invH           = invH;
        precomp.tri            = tri';
        precomp.no_pixels      = sum(inh(:));
        clear desc_im invH update tmp tri inh
    else
        appearance_mu  = precomp.appearance_mu;
        appearance_pcs = precomp.appearance_pcs;
    end
    
    % Perform inverse compositional Lucas-Kanade iterations
    err = repmat(Inf, [max_iter 1]); 
    ps = cell(max_iter + 1, 1); ps{1} = p;
    while iter < max_iter %&& (iter < min_iter || err(iter - 1) - err(iter) > 0)
        
        % Compute current shape model
        cur_shape = shape_mu + sum(bsxfun(@times, p, shape_pcs), 2)';
        
        % Warp image given current shape model
        if ~isfield(precomp, 'precompY')
            [trans_im, precompY, precompX] = pw_linear_warp(im, shape_mu, cur_shape, size_aam);
            precomp.precompY = precompY;
            precomp.precompX = precompX;
        else
            trans_im = pw_linear_warp(im, shape_mu, cur_shape, size_aam, precomp.precompY, precomp.precompX);
        end
        
        % Compute error image
        error_im = compute_error_im(trans_im, appearance_mu);
        iter = iter + 1;

        % Perform parameter update for shape mesh
        delta_p = (error_im * precomp.desc_im) * precomp.invH;
        shape_mu_change = -sum(bsxfun(@times, delta_p, shape_pcs), 2)';
        cur_shape_change = compute_shape_change(shape_mu, shape_mu_change, cur_shape, precomp.tri);
        p = (cur_shape + cur_shape_change - shape_mu) * shape_pcs;
%         p = p - lambda * ((p - prior.mu) * prior.inv_sigma);
        ps{iter + 1} = p;
        
        % Store current error
        err(iter) = sum(error_im .^ 2) ./ precomp.no_pixels;
    end
    
    % Select best fit of the iterations
    [err, ind] = min(err);
    p = ps{ind};
    if ind == 1
        diverged = true;
    else
        diverged = false;
    end
    
    % Compute appearance parameters (closed-form)
    if nargout > 1
        cur_shape = shape_mu + sum(bsxfun(@times, p, shape_pcs), 2)';
        trans_im = pw_linear_warp(im, shape_mu, cur_shape, [size_aam 3], precomp.precompY, precomp.precompX);
        error_im = compute_error_im(trans_im, appearance_mu);
        lambda = error_im(1:end) * appearance_pcs;
    end
