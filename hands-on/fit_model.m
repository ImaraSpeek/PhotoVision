function [p, lambda, err, ind, diverged, precomp] = fit_model(p, lambda, im, shape_model, appear_model, type, precomp)
%FIT_MODEL General function to fit various types of AAM models
%
%   [p, lambda, err, ind, diverged, precomp] = fit_model(p, lambda, im, shape_model, ...
%                                              appear_model, type, precomp)
%
% This is a general function that can handle various types of AAM models.
% It takes as input an image, a shape model, an appearance model, and
% optionally initial parameter p and lambda and/or a precomputation
% structure precomp. The parameter type can take values 'color' or 'gray'
% defining the fitting type (default = 'gray').
% The function returns the fitted parameters in p and lambda, the error of 
% fit, the index of the optimal appearance mixture component, and
% optionally a precomputation structure precomp.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology

    
    if ~exist('type', 'var') || isempty(type)
        type = 'gray';
    end

    % Initialize some variables
    no_models = numel(appear_model.mixing);
    ps = cell(no_models, 1);
    lambdas = cell(no_models, 1);
    err = zeros(no_models, 1);
    diverged = repmat(false, [no_models 1]);
    if ~exist('precomp', 'var')
        precomp = cell(no_models, 1);
    end
    
    % Initialize models (note initialization is the same for all models)
    if ~exist('p', 'var') || isempty(p)
        p = initialize_aam(im, shape_model.shape_mu, shape_model.shape_pcs, shape_model.transf_mult);
    end

    % Fit the appearance model for all models
    for i=1:no_models

        % Transform current pPCA model into image domain
        if isempty(precomp{i})
            appear_mu  = appear_model.appearance_mu + (appear_model.moppca_means(:,i)' * appear_model.appearance_pcs');
            appear_pcs = appear_model.appearance_pcs * appear_model.moppca_pcs(:,:,i);
        else
            appear_mu  = precomp{i}.appearance_mu;
            appear_pcs = precomp{i}.appearance_pcs;
        end

        % Fit the active appearance model
        if strcmpi(type, 'gray')
            if isempty(precomp{i})
                [ps{i}, lambdas{i}, err(i), diverged(i), precomp{i}] = fit_aam_gray(p, im, shape_model.shape_mu, shape_model.shape_pcs, shape_model.transf_mult, shape_model.prior, ...
                                                                        appear_mu, appear_pcs, appear_model.size_aam);
            else
                [ps{i}, lambdas{i}, err(i), diverged(i)]             = fit_aam_gray(p, im, shape_model.shape_mu, shape_model.shape_pcs, shape_model.transf_mult, shape_model.prior, ...
                                                                        appear_mu, appear_pcs, appear_model.size_aam, precomp{i});
            end
        elseif strcmpi(type, 'color')
            if isempty(precomp{i})
                [ps{i}, lambdas{i}, err(i), diverged(i), precomp{i}] = fit_aam(p, im, shape_model.shape_mu, shape_model.shape_pcs, shape_model.transf_mult, shape_model.prior, ...
                                                                        appear_mu, appear_pcs, appear_model.size_aam);
            else
                [ps{i}, lambdas{i}, err(i), diverged(i)]             = fit_aam(p, im, shape_model.shape_mu, shape_model.shape_pcs, shape_model.transf_mult, shape_model.prior, ...
                                                                        appear_mu, appear_pcs, appear_model.size_aam, precomp{i});
            end
        else
            error('Unknown color type defined.');
        end
    end

    % Select best model
    [err, ind] = min(err);
    p = ps{ind};
    lambda = lambdas{ind};
    diverged = diverged(ind);
    
    