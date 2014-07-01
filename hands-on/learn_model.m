function [shape_model, appear_model] = learn_model(base_folder, shape_dims, k, appearance_dims, no_images)
%LEARN_MODEL Learns an active shape and appearance model
%
%   [shape_model, appear_model] = learn_model(base_folder, shape_dims, k, appearance_dims, no_images)
%   [shape_model, appear_model] = learn_model(base_folder, shape_dims, k, appearance_dims, images)
%
% Learns an active shape and appearance model with the specified properties.
% The images and points are assumed to stored in base_folder. The number of
% shape and appearance dimensions, as well as the number of mixture
% components k in the appearance model need to be specified. If required,
% one may specify the number of images or an image list on which to train
% the model.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    if ~exist('shape_dims', 'var') || isempty(shape_dims)
        shape_dims = 5;
    end
    if ~exist('appearance_dims', 'var') || isempty(appearance_dims)
        appearance_dims = 40;
    end
    if ~exist('no_images', 'var')
        no_images = [];
    end

    % Learn shape model
    disp(['Learning shape model with ' num2str(shape_dims) ' parameters...']);
    [shape_mu, shape_pcs, lambda, transf_mult, prior] = learn_shape_model(base_folder, shape_dims, no_images);
    shape_model.shape_mu    = shape_mu;
    shape_model.shape_pcs   = shape_pcs;
    shape_model.lambda      = lambda ./ max(lambda);
    shape_model.transf_mult = transf_mult;
    shape_model.prior       = prior; 
    
    % Learn appearance model
    disp(['Learning ' num2str(k) ' appearance model(s) with ' num2str(appearance_dims) ' parameters...']);
    [appearance_mu, appearance_pcs, moppca_means, moppca_pcs, mixing, size_aam] = learn_appear_model(base_folder, shape_mu, k, appearance_dims, no_images);
    appear_model.appearance_mu  = appearance_mu;
    appear_model.appearance_pcs = appearance_pcs;
    appear_model.moppca_means = moppca_means;
    appear_model.moppca_pcs   = moppca_pcs;
    appear_model.mixing       = mixing;
    appear_model.size_aam       = size_aam;
%     appear_model.lambda         = lambda ./ max(lambda);
%     appear_model.prior          = prior;
    