function [h, im] = plot_shape_model(h, im, shape)
%PLOT_SHAPE_MODEL Plots the specified active shape model on the image
%
%   h = plot_shape_model(h, im, shape)
%
% The function plots the specified active shape model on the image im.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Preprocess image
    if ~isinteger(im)
        im = im - min(im(:));
        im = im / max(im(:));
        im = uint8(round(im * 255));
    end
    
    % Alter image to include annotations
    if exist('shape', 'var') && ~isempty(shape)
        x = shape(1:2:end)';
        y = shape(2:2:end)';
        im = plot_annotations(im, x, y);
    end

    % Plot or update annotated image
    if ~exist('h', 'var') || isempty(h)
        h = imshow(im);
        set(h, 'EraseMode', 'none');
    else
        set(h, 'CData', im);
    end 
    
%     for i=1:numel(x)
%         th = text(x(i), y(i), num2str(i));
%         set(th, 'Color', [1 0 0]);
%     end
        
    drawnow
end


% Function that alters image pixels to reveal annotations
function im = plot_annotations(im, x, y)

    % Round feature point locations
    x = round(x);
    y = round(y);
    
    % Turn locations into small crosses
    x = [x; x - 1; x - 2; x - 3; x - 4; x - 5; x + 1; x + 2; x + 3; x + 4; x + 5; x    ; x    ; x    ; x    ; x    ; x    ; x    ; x    ; x    ; x];
    y = [y; y    ; y    ; y    ; y    ; y    ; y    ; y    ; y    ; y    ; y    ; y - 1; y - 2; y - 3; y - 4; y - 5; y + 1; y + 2; y + 3; y + 4; y + 5];
    ind = (y < 1) | (y > size(im, 1)) | (x < 1) | (x > size(im, 2));
    x(ind) = [];
    y(ind) = [];
    
    % Make the crosses bigger (for publishing)
    ind = y + (x - 1) * size(im, 1);
    tf = repmat(false, [size(im, 1) size(im, 2)]);
    tf(ind) = true;
    tf = bwmorph(tf, 'dilate', 1);
    ind = find(tf);
    
    % Plot locations of feature points
    im(ind + 0 * size(im, 1) * size(im, 2)) = 255;
    for c=1:size(im, 3) - 1
        im(ind + c * size(im, 1) * size(im, 2)) = 0;
    end
end

    