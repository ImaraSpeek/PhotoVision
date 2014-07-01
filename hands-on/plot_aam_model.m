function h = plot_aam_model(h, im, appearance, offset, shape)
%PLOT_AAM_MODEL Plots the specified active appearance model on the image
%
%   h = plot_aam_model(h, im, appearance, offset, shape)
%
% The function plots the specified active appearance model on the image im.
% The shape is showed is plot_shape is set to true (default = false);
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Preprocess image and appearance image
    if ~isinteger(im)
        im = uint8(round(im * 255));
    end
    if ~isinteger(appearance)
        appearance = uint8(round(appearance * 255));
    end
    
    % Alter image to include appearance
    if all(offset > 1) && offset(2) + size(appearance, 1) - 1 < size(im, 1) && offset(1) + size(appearance, 2) - 1 < size(im, 2)
        cur_content = im(offset(2):offset(2) + size(appearance, 1) - 1, offset(1):offset(1) + size(appearance, 2) - 1,:);
        ind = (appearance == 0);
        appearance(ind) = cur_content(ind);
        im(offset(2):offset(2) + size(appearance, 1) - 1, offset(1):offset(1) + size(appearance, 2) - 1,:) = appearance;
    end
    
    % Show appearance image
    if ~exist('h', 'var') || isempty(h)
        h = imshow(im);
        set(h, 'EraseMode', 'none');
    else
        set(h, 'CData', im);
    end
    
%     % Show shape if requested (should be implemented like PLOT_SHAPE_MODEL)
%     if exist('shape', 'var') && ~isempty(shape)
%         hold on
%         shape_x = shape(1:2:end);
%         shape_y = shape(2:2:end);
%         tri = delaunay(shape_x, shape_y);
%         scatter(shape_x, shape_y);
%         triplot(tri, shape_x, shape_y);
%         hold off
%     end
    