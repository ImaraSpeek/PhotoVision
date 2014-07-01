function show_model(shape_model, appear_model)
%SHOW_MODEL Shows plots of the shape and appearance models in an AAM
%
%   show_model(shape_model, appear_model)
%
% Shows plots of the mean shape and appearance, and the corresponding
% principal components in the specified active appearance model.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    close all

    % Plot shape model
    if exist('shape_model', 'var') && ~isempty(shape_model)
        figure(1);
        set(gcf, 'Position', [4 -17 1277 701]);
        
        % Plot shape mean
        im = reshape(appear_model.appearance_mu, appear_model.size_aam);
        subplot(3, 6, 1);
        plot_shape_model([], im, shape_model.shape_mu);
        title('Shape mean');
        
        % Plot first principal components
        for i=1:min(3 * 6 - 1, size(shape_model.shape_pcs, 2))
            subplot(3, 6, i + 1);
            plot_shape_model([], im, shape_model.shape_mu); hold on
            quiver(shape_model.shape_mu(1:2:end)', shape_model.shape_mu(2:2:end)', shape_model.shape_pcs(1:2:end, i), shape_model.shape_pcs(2:2:end, i));
            if i < 5 || ~isfield(shape_model, 'lambda')
                title(['Shape PC #' num2str(i)]);
            else
                title(['Shape PC #' num2str(i) ' (weight ' num2str(shape_model.lambda(i - 4)) ')']);
            end
        end
    end
    
    % Plot appearance model
    if exist('appear_model', 'var') && ~isempty(appear_model)     
        
        % Plot ech model in a separate figure
        no_models = numel(appear_model.mixing);
        for j=1:no_models
        
            % Initialize
            figure(j + 1);
            set(gcf, 'Position', [4 -17 1277 701]);
            appear_mu  = appear_model.appearance_mu + (appear_model.moppca_means(:,j)' * appear_model.appearance_pcs');
            appear_pcs = appear_model.appearance_pcs * appear_model.moppca_pcs(:,:,j);

            % Plot appearance mean
            im = reshape(appear_mu, appear_model.size_aam);
            im = im -  min(im(:));
            im = im ./ max(im(:));
            im = uint8(im .* 255);
            subplot(3, 8, 1);
            imshow(im);
            title ('Appearance mean');

            % Plot first principal components
            for i=1:min(3 * 8 - 1, size(appear_pcs, 2))
                im = reshape(appear_pcs(:,i), appear_model.size_aam);
                im = im -  min(im(:));
                im = im ./ max(im(:));
                im = uint8(im .* 255);
                subplot(3, 8, i + 1);
                imshow(im);
                if isfield(appear_model, 'lambda')
                    title(['Appearance PC #' num2str(i) ' (weight ' num2str(appear_model.lambda(i, j)) ')']);
                else
                    title(['Appearance PC #' num2str(i)]);
                end
            end
        end
    end
    