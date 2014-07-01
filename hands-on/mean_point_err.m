function err = mean_point_err(shape1, shape2)
%MEAN_POINT_ERR Compute mean point-to-point error between two shapes
%
%   err = mean_point_err(shape1, shape2)
%
% Compute mean point-to-point error between two shapes. This function can
% be used to assess the quality of an AAM fit.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Retrieve point coordinates
    shape1_x = shape1(1:2:end);
    shape1_y = shape1(2:2:end);
    shape2_x = shape2(1:2:end);
    shape2_y = shape2(2:2:end);
    
    % Compute pairwise distances, and return its mean
    D = sqrt((shape1_x - shape2_x) .^ 2 + (shape1_y - shape2_y) .^ 2);
    err = mean(D);