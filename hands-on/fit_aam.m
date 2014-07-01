function [p, lambda, err, diverged, precomp] = fit_aam(p, im, shape_mu, shape_pcs, transf_mult, prior, appearance_mu, appearance_pcs, size_aam, precomp)
%FIT_AAM Performs fast inverse compositional algorithm to fit an AAM
%
%   [p, lambda, err, diverged, precomp] = fit_aam(p, im, shape_mu, shape_pcs, ...
%            transf_mult, appearance_mu, appearance_pcs, size_aam, precomp)
%
%   [p, lambda, err, diverged, precomp] = fit_aam(p, im, shape_mu, shape_pcs, ...
%            data_name, appearance_mu, appearance_pcs, size_aam, precomp)
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
    im = double(im) ./ 255;
    appearance_mu = reshape(appearance_mu, size_aam);
    
    % Perform precomputations
    if ~exist('precomp', 'var')
        
        % Perform Delaunay triangulization
        tri = delaunay(base_shape_x, base_shape_y);

        % Precompute gradients of template
        Ty = [zeros(1, width, 3); diff(appearance_mu, [], 1)];
        Tx = [zeros(height, 1, 3) diff(appearance_mu, [], 2)];
        
        % Remove border artefacts in template gradient
        [i1, i2] = meshgrid(1:size_aam(2), 1:size_aam(1));
        inh = repmat(bwmorph(reshape(inhull([i1(:) i2(:)], [base_shape_x base_shape_y]), [size_aam(1) size_aam(2)]), 'erode'), [1 1 3]);
        Ty(~inh) = 0;
        Tx(~inh) = 0;
        clear i1 i2

        % Precompute the Jacobian of the warping at p=0
        J = zeros(size_aam(1), size_aam(2), size_aam(3), 2, numel(p));
        J(:,:,1,:,:) = pw_linear_warp_jacobian(zeros(size(p)), shape_mu, shape_pcs, size_aam(1:2));
        for i=2:size_aam(3)
            J(:,:,i,:,:) = J(:,:,1,:,:);
        end
        
        % Precompute steepest descent images (without appearance variation)  
        desc_im = zeros(height, width, 3, 2, numel(p));
        for i=1:numel(p)
            desc_im(:,:,:,1,i) = Tx;
            desc_im(:,:,:,2,i) = Ty;
        end
        desc_im = desc_im .* J;
        clear J Tx Ty
        
%         % Modify steepest descent images to project out appearance variation
%         update = zeros(height, width, 3, 2, numel(p));
%         for i=1:size(appearance_pcs, 2)
%             appear_i = reshape(appearance_pcs(:,i), size_aam);
%             tmp = sum(sum(sum(bsxfun(@times, appear_i, desc_im), 1), 2), 3);
%             for j=1:2
%                 for k=1:numel(p)
%                     update(:,:,:,j,k) = update(:,:,:,j,k) + (appear_i .* tmp(:,:,:,j,k));
%                 end
%             end
%         end
%         desc_im = desc_im - update;
%         clear tmp appear_i update
        
        % Modify steepest descent images to project out appearance variation
        for i=1:size(appearance_pcs, 2)
            appear_i = reshape(appearance_pcs(:,i), size_aam);
            tmp = sum(sum(sum(bsxfun(@times, appear_i, desc_im), 1), 2), 3);
            for j=1:2
                for k=1:numel(p)
                    desc_im(:,:,:,j,k) = desc_im(:,:,:,j,k) - (appear_i .* tmp(:,:,:,j,k));
                end
            end
        end
        clear tmp appear_i
        % NOTE: The above code is a memory-conservative approximation!
        
        % Precompute the Gauss-Newton approximation to the Hessian
        tmp = reshape(desc_im, [height * width * 3 * 2 numel(p)]);
        invH = inv(tmp' * tmp);
        clear tmp

        % Precomputations to facilitate fast multiplication with error image
        desc_im = squeeze(sum(desc_im, 4));
        desc_im = reshape(desc_im, [height * width * 3 numel(p)]);

        % Store precomputation structure
        precomp.appearance_mu  = appearance_mu;
        precomp.appearance_pcs = appearance_pcs;
        precomp.desc_im        = desc_im;
        precomp.invH           = invH;
        precomp.tri            = tri';
        precomp.no_pixels      = sum(inh(:));
        clear desc_im invH update tri inh
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
        
        % Compute error image, and get rid of pixels outside base-shape
        error_im = compute_error_im(trans_im, appearance_mu);
        iter = iter + 1;
        
        % Perform closed-form parameter updates for shape mesh
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
        trans_im = pw_linear_warp(im, shape_mu, cur_shape, size_aam, precomp.precompY, precomp.precompX);
        error_im = compute_error_im(trans_im, appearance_mu);
        lambda = error_im(1:end) * appearance_pcs;
    end
    