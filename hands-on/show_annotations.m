function show_annotations(base_folder)
%SHOW_ANNOTATIONS Shows all annotated images in the specified folder
%
%   show_annotations(base_folder)
%
% Shows all annotated images in the specified folder.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Retrieve file lists
    [images, points] = get_file_lists(base_folder);
    
    % Show all images
    h = [];
    for i=1:length(images)
        im = imread([base_folder '/images/' images(i).name]);
        if ndims(im) == 2
            im = repmat(im, [1 1 3]);
        end
        shape = read_points_file(base_folder, points(i).name);
        if max(shape) < 1
            shape = shape .* repmat([size(im, 2) size(im, 1)], [1 size(shape, 2) / 2]);
        end
        h = plot_shape_model(h, im, shape);
%         for j=1:length(shape) / 2
%             text(shape(j * 2 - 1), shape(j * 2), num2str(j));
%         end
        title(images(i).name);
        pause
    end