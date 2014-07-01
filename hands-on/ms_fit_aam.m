function [p, lambda, precomp] = ms_fit_aam(p, lambda, im, shape_model, appear_model, scales, precomp)
%MS_FIT_AAM Fits an AAM using multi-scale inverse compositional fitting
%
%   [p, lambda, precomp] = ms_fit_aam(p, lambda, im, shape_model, ...
%                                           appear_model, scales, precomp)
%
% Performs the multi-scale inverse compositional algorithm to perform 
% the fitting of an AAM model to an image. The function takes the AAM as
% input, and optional shape parameters p. The function returns the fitted
% shape parameters p and the fitted appearance parameters lambda. This
% function operates similarly to FIT_AAM, except it uses multi-scale
% fitting for robustness and speed.
%
% If the same AAM is used iteratively, the structure precomp may be
% employed to speed up computations. The function currently uses
% FIT_AAM_GRAY for fitting on each scale.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Compute coarse-scale AAM model
    no_scales = length(scales);
    if ~exist('precomp', 'var') || isempty(precomp)
        
        % Construct coarse scale appearance mean images by downsampling
        precomp = cell(no_scales, 1);
        for i=1:no_scales
            tmp = downsample(reshape(appear_model.appearance_mu, appear_model.size_aam), scales(i));
            precomp{i}.appearance_mu = tmp(:);            
            precomp{i}.size_aam = appear_model.size_aam;
            precomp{i}.size_aam(1:2) = ceil(precomp{i}.size_aam(1:2) ./ (2 ^ (scales(i) - 1)));
        end
        
        % Construct coarse-scale appearance PC images by downsampling
        for i=1:no_scales
            precomp{i}.appearance_pcs = zeros(numel(precomp{i}.appearance_mu), size(appear_model.appearance_pcs, 2));
            for j=1:size(appear_model.appearance_pcs, 2)
                tmp = downsample(reshape(appear_model.appearance_pcs(:,j), appear_model.size_aam), scales(i));
                precomp{i}.appearance_pcs(:,j) = tmp(:);
            end
        end
        
        % Construct coarse-scale shape models
        for i=1:no_scales
            precomp{i}.shape_mu  = shape_model.shape_mu ./ (2 ^ (scales(i) - 1));
            precomp{i}.shape_pcs = shape_model.shape_pcs;
        end        
    end
    
    % Construct coarse-scale images by downsampling
    ims = cell(no_scales, 1);
    for i=1:no_scales
        ims{i} = downsample(im, scales(i));
    end
    
    % Correct values of p to live in coarsest scale
    if ~isempty(p)
        p = p ./ (2 ^ (scales(1) - 1));
        % what to do with the prior here???
    end
    
    % Perform AAM fitting in a coarse-to-fine manner
    for i=1:no_scales
        if i > 1
            p = p * (2 ^ (scales(i - 1) - scales(i)));
        end
        
        % Code for 'normal' inverse compositional algorithm
        if ~isfield(precomp{i}, 'precomp')
            [p, lambda, precomp{i}.precomp] = fit_aam_gray(p, ims{i}, precomp{i}.shape_mu, precomp{i}.shape_pcs, shape_model.transf_mult, shape_model.prior, precomp{i}.appearance_mu, precomp{i}.appearance_pcs, precomp{i}.size_aam);
        else
            if i == no_scales
                [p, lambda] = fit_aam_gray(p, ims{i}, precomp{i}.shape_mu, precomp{i}.shape_pcs, shape_model.transf_mult, shape_model.prior, precomp{i}.appearance_mu, precomp{i}.appearance_pcs, precomp{i}.size_aam, precomp{i}.precomp);
            else
                p = fit_aam_gray(p, ims{i}, precomp{i}.shape_mu, precomp{i}.shape_pcs, shape_model.transf_mult, shape_model.prior, precomp{i}.appearance_mu, precomp{i}.appearance_pcs, precomp{i}.size_aam, precomp{i}.precomp);
            end
        end
    end
                
    % Correct p in case we don't fit on finest scale
    p = p * (2 ^ (scales(end) - 1));
end


% Function to downsample image
function im = downsample(im, scale)
    im = im(1:2 ^ (scale - 1):end,1:2 ^ (scale - 1):end,:);
end
    
    
        
