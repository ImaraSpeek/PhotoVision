function [images, points, israw] = get_file_lists(base_folder)
%GET_FILE_LISTS Gets aligned lists of all images and point files
%
%   [images, points, israw] = get_file_lists(base_folder)
%
% Gets aligned lists of all images and point files. The function also
% returns a boolean indicating whether the images are in RAW format (in 
% which case READRAW should be used for reading).
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Retrieve file lists
    images = [dir([base_folder '/images/*.jpg']); dir([base_folder '/images/*.png'])];
    if isempty(images)
        images = dir([base_folder '/images/*.raw']);
        israw = true;
    else
        israw = false;
    end
    points = dir([base_folder '/points/*.pts']);
    
    % Fill two lists
    image_numbers = cell(length(images), 1);
    point_numbers = cell(length(points), 1);
    for i=1:length(images)
        image_numbers{i} = images(i).name(1:end-4);
    end
    for i=1:length(points)
        point_numbers{i} = points(i).name(1:end-4);
    end

    % Is we did not find points, just return the images
    if ~isempty(points)
        
        % Align two lists (assumes all filenames have the same length)
        point_numbers = char(point_numbers);
        image_numbers = char(image_numbers);    
        ind2 = zeros(length(images), 1);
        for i=1:length(ind2)
            d = bsxfun(@eq, point_numbers, image_numbers(i,:));
            tmp = find(all(d, 2), 1, 'first');
            if ~isempty(tmp)
                ind2(i) = tmp;
            end
        end
        ind = ind2;

        % Remove orphins
        images(ind == 0) = [];
        ind(ind == 0) = [];
        points = points(ind);
    end
    