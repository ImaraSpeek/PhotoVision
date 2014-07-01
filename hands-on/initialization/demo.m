% The ordering of the feature points in the feature point detector is:
%   1: LHS left eye
%   2: RHS left eye
%   3: LHS right eye
%   4: RHS right eye
%   5: LHS nose
%   6: middle nose
%   7: RHS nose
%   8: LHS mouth
%   9: RHS mouth
%
% The ordering of the shape points in the AAM is:
%


    % Initialize models
    init;
    load '../normal_aam.mat';
    shape_pcs = shape_pcs(:,1:4);               % we are only interested in a location fit (more detailed fit does not work without priors)

    % Get the points from the shape model that correspond to the feature points
    ind = [10 11 12 13 16 15 17 3 4];           % the mapping from feature points to shape points
    ind = [ind * 2 - 1; ind * 2];
    small_shape_mu  = shape_mu (ind(:));
    small_shape_pcs = shape_pcs(ind(:),:);

    % Loop over all images
    base_folder = '/Users/laurens/Desktop/AAMs/ARF/images';
    images = dir([base_folder '/*.jpg']);
    for i=1:length(images)

        % Perform basic face and feature point detection
        im = imread([base_folder '/' images(i).name]);
        [detections, points] = extfacedescs(opts, im, true);
        points = points(:)';
        drawnow

        % Compute optimal shape parameter initialization, given feature points
        p = (small_shape_pcs \ (points - small_shape_mu)')';
        cur_shape = shape_mu + sum(bsxfun(@times, p, shape_pcs), 2)';
        
        % Show AAM initialization        
        cd ..
        figure(2), plot_shape_model([], im, cur_shape);
        cd initialization
        drawnow
        pause
    end
