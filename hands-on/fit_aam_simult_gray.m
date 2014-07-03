function [p, lambda, precomp] = fit_aam_simult_gray(p, lambda, im, shape_mu, shape_pcs, transf_mult, appearance_mu, appearance_pcs, size_aam, precomp)
%FIT_AAM_SIMULT_GRAY Performs inverse compositional algorithm to fit an AAM
%
%   [p, lambda, precomp] = fit_aam_simult_gray(p, lambda, im, shape_mu, shape_pcs, ...
%            transf_mult, appearance_mu, appearance_pcs, size_aam, precomp)
%
% Performs the simultaneous inverse compositional algorithm to perform 
% the fitting of an AAM model to an image. The function takes the AAM as
% input, and optional shape parameters p. The function returns the fitted
% shape parameters p, the fitted location parameters q, and the fitted
% appearance parameters lambda.
% If the same AAM is used iteratively, the structure precomp may be
% employed to speed up computations.
%
% This function is like FIT_AAM_GRAY but it updates the appearance
% parameters in each iteration (= much slower).
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Initialize shape parameters
    if ~exist('p', 'var') || isempty(p)
        p = initialize_aam(im, shape_mu, shape_pcs, transf_mult);
        if isempty(p)
            return;
        end
    end
    if ~exist('lambda', 'var') || isempty(lambda)
        lambda = zeros(1, size(appearance_pcs, 2));
    end

    % Initialize some variables
    max_iter = 25;
    height = size_aam(1);
    width  = size_aam(2);
    base_shape_x = shape_mu(1:2:end)';
    base_shape_y = shape_mu(2:2:end)';
    err = repmat(Inf, [max_iter 1]);
    ps = zeros(max_iter, numel(p));
%     cur_shape_change = Inf;
    iter = 0;
    
    % Make sure variables have correct format
    if size(p, 1) > 1
        p = p';
    end
    if ndims(im) > 2
        im = mean(double(im), 3);
    end
    im = im ./ 255;
    size_aam = size_aam(1:2);
    
    % Perform precomputations
    if ~exist('precomp', 'var')
        
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
                
        % Precompute mask to remove border artefacts in template gradient
        [i1, i2] = meshgrid(1:size_aam(2), 1:size_aam(1));
        inh = bwmorph(reshape(inhull([i1(:) i2(:)], [base_shape_x base_shape_y]), [size_aam(1) size_aam(2)]), 'erode');
        
        % Precompute apppearance PC vector gradients
        A_gradX = zeros(size(appearance_pcs));
        A_gradY = zeros(size(appearance_pcs));
        for i=1:size(appearance_pcs, 2)
            
            % Compute gradients of appearance vectors
            tmp = reshape(appearance_pcs(:,i), size_aam);
            Ty = [zeros(1, width); diff(tmp, [], 1)];
            Tx = [zeros(height, 1) diff(tmp, [], 2)];  
            Ty(~inh) = 0;
            Tx(~inh) = 0;
        
            % Center template gradients
            Ty = (Ty + [Ty(2:end,:); zeros(1, width)])  ./ 2;
            Tx = (Tx + [Tx(:,2:end)  zeros(height, 1)]) ./ 2;
            
            % Store appearance gradients
            A_gradY(:,i) = Ty(:);
            A_gradX(:,i) = Tx(:);
        end
        
        % Precompute appearance mean gradient
        Ty = [zeros(1, width); diff(tmp, [], 1)];
        Tx = [zeros(height, 1) diff(tmp, [], 2)];  
        Ty(~inh) = 0; Ty = (Ty + [Ty(2:end,:); zeros(1, width)])  ./ 2; Ty = Ty(:);
        Tx(~inh) = 0; Tx = (Tx + [Tx(:,2:end)  zeros(height, 1)]) ./ 2; Tx = Tx(:);
        
        % Precompute the Jacobian of the warping at p=0
        J = pw_linear_warp_jacobian(zeros(size(p)), shape_mu, shape_pcs, size_aam);
        J = reshape(J, [height * width 2 numel(p)]);

        % Store precomputation structure
        precomp.appearance_mu  = appearance_mu;
        precomp.appearance_pcs = appearance_pcs;
        precomp.J              = J;
        precomp.Ty             = Ty;
        precomp.Tx             = Tx;
        precomp.A_gradY        = A_gradY;
        precomp.A_gradX        = A_gradX;
        precomp.tri            = tri';
        clear desc_im invH update tmp tri
    else
        appearance_mu  = precomp.appearance_mu;
        appearance_pcs = precomp.appearance_pcs;
    end
    
    % Perform inverse compositional Lucas-Kanade iterations
    while iter < max_iter %&& mean(abs(cur_shape_change)) > .05 
        
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
                
        % Store error and p-values for post-selection
        iter = iter + 1;
        err(iter) = sum(error_im .^ 2);
        ps(iter,:) = p;
        
        % Compute gradient of appearance image
        Ax = precomp.Tx + sum(bsxfun(@times, lambda, precomp.A_gradX), 2);
        Ay = precomp.Ty + sum(bsxfun(@times, lambda, precomp.A_gradY), 2);        
        
        % Compute steepest descent images
        desc_im = [squeeze(sum(repmat([Ax Ay], [1 1 numel(p)]) .* precomp.J, 2)) appearance_pcs];
        
        % Precompute the Gauss-Newton approximation to the Hessian
        invH = inv(desc_im' * desc_im);
                
        % Compute parameter updates
        delta_q = (error_im * desc_im) * invH;
        delta_p = delta_q(1:numel(p));
        delta_l = delta_q(1+numel(p):end);
        
        % Perform parameter update for shape mesh
        shape_mu_change = -sum(bsxfun(@times, delta_p, shape_pcs), 2)';
        cur_shape_change = compute_shape_change(shape_mu, shape_mu_change, cur_shape, precomp.tri);
        p = (cur_shape + cur_shape_change - shape_mu) * shape_pcs;
        
        % Perform parameter update for appearance
        lambda = lambda + delta_l;
    end

    % Select best fit (post-selection)
    [err, ind] = min(err);
    p = ps(ind,:);
    
    % Compute appearance parameters (closed-form)
    if nargin > 1
        cur_shape = shape_mu + sum(bsxfun(@times, p, shape_pcs), 2)';
        trans_im = pw_linear_warp(im, shape_mu, cur_shape, [size_aam 3], precomp.precompY, precomp.precompX);
        error_im = compute_error_im(trans_im, appearance_mu);
        lambda = error_im(1:end) * appearance_pcs;
    end
