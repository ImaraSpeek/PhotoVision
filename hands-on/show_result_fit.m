function [h1, h2, precomp] = show_result_fit(h1, h2, im, p, lambda, ind, shape_model, appear_model, precomp, cur_title)
%SHOW_RESULT_FIT Shows a fitting result with shape and appearance fits
%
%   [h1, h2] = show_result_fit(h1, h2, im, p, lambda, shape_model, appearance_model, precomp, cur_title)
%   [h1, h2, precomp] = show_result_fit(h1, h2, im, p, lambda, shape_model, appearance_model, [], cur_title)
%
% Shows a fitting result with shape and appearance fits. The fit parameters
% are specified through p and lambda, whereas the active appearance model
% is specified through shape_model and appearance_model.
% The handles h1 and h2 are used to update the plots, please specify an
% empty matrix if they are unknown.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    if isempty(ind)
        ind = 1;
    end
    if ndims(im) == 2
        im = repmat(im, [1 1 3]);
    end

    % Make shape plot
    subplot(1, 2, 1);
    if ~isempty(p)
        cur_shape = shape_model.shape_mu + sum(bsxfun(@times, p, shape_model.shape_pcs), 2)';
        h1 = plot_shape_model(h1, im, cur_shape);
    else
        h1 = plot_shape_model(h1, im);
    end
    if exist('cur_title', 'var') && ~isempty(cur_title)
%         title(cur_title);
    end

    % Make appearance plot
    subplot(1, 2, 2);
    if ~isempty(p) && ~isempty(lambda)
        
        % Transform the pPCA model into image domain
        if ~exist('precomp', 'var') || isempty(precomp)
            no_models = size(appear_model.moppca_means, 2);
            precomp = cell(no_models, 1);
            for i=1:no_models
                precomp{i}.appear_mu  = appear_model.appearance_mu + (appear_model.moppca_means(:,i)' * appear_model.appearance_pcs');
                precomp{i}.appear_pcs = appear_model.appearance_pcs * appear_model.moppca_pcs(:,:,i);
            end
        end
        
        % Make sure the appearance is not too big for memory
        if max(abs(cur_shape)) < 1500
        
            % Compute appearance image and warp it onto original
            appearance = reshape(precomp{ind}.appear_mu(:) + sum(bsxfun(@times, lambda, precomp{ind}.appear_pcs), 2), appear_model.size_aam);
            offset = [min(cur_shape(1:2:end)) min(cur_shape(2:2:end))];
            cur_shape(1:2:end) = 1 + cur_shape(1:2:end) - offset(1);
            cur_shape(2:2:end) = 1 + cur_shape(2:2:end) - offset(2);
            trans_im = pw_linear_warp(appearance, cur_shape, shape_model.shape_mu, [ceil(max(cur_shape(2:2:end))) ceil(max(cur_shape(1:2:end))) 3]);
            h2 = plot_aam_model(h2, im, trans_im, round(offset));
        else
            h2 = plot_shape_model(h2, im);
        end
    else
        h2 = plot_shape_model(h2, im);
    end
    if exist('cur_title', 'var') && ~isempty(cur_title)
%         title(cur_title);
    end
