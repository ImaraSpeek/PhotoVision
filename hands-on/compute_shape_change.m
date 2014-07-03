function shape_change = compute_shape_change(base_shape, base_shape_change, shape, tri)
%COMPUTE_SHAPE_CHANGE Estimate shape change from base shape change
%
%   shape_change = compute_shape_change(base_shape, base_shape_change,
%   shape, tri)
%
% The function estimates the change shape_change of the mesh shape from the
% change base_shape_change of the base mesh base_shape. It does so by
% applying the warp base_shape -> shape to base_shape + base_shape_change.


    % For compatibility with C-code
    tri = tri';

    % Normalize base shape
    shape_x = shape(1:2:end)';
    shape_y = shape(2:2:end)';
    base_shape_x = base_shape(1:2:end)';
    base_shape_y = base_shape(2:2:end)';
    base_shape_change_x = base_shape_change(1:2:end)';
    base_shape_change_y = base_shape_change(2:2:end)';
    v = length(base_shape_x);
    
    % Obtain triangle coordinates of base mesh
    xi = base_shape_x(tri(:,1));
    yi = base_shape_y(tri(:,1));
    xj = base_shape_x(tri(:,2));
    yj = base_shape_y(tri(:,2));
    xk = base_shape_x(tri(:,3));
    yk = base_shape_y(tri(:,3));

    % Construct points for which to compute warps: s0 + delta s0
    x = base_shape_x(tri) + base_shape_change_x(tri);
    y = base_shape_y(tri) + base_shape_change_y(tri);

    % Compute the alfa and beta values for s0 + delta s0
    alfa = bsxfun(@rdivide, bsxfun(@times, bsxfun(@minus, x, xi), yk - yi) - bsxfun(@times, bsxfun(@minus, y, yi), xk - xi), ...
                    ((xj - xi) .* (yk - yi) - (yj - yi) .* (xk - xi)));
    beta = bsxfun(@rdivide, bsxfun(@times, bsxfun(@minus, y, yi), xj - xi) - bsxfun(@times, bsxfun(@minus, x, xi), yj - yi), ...
                    ((xj - xi) .* (yk - yi) - (yj - yi) .* (xk - xi)));
    
    % Obtain triangle coordinates of target mesh s
    xi = shape_x(tri(:,1));
    yi = shape_y(tri(:,1));
    xj = shape_x(tri(:,2));
    yj = shape_y(tri(:,2));
    xk = shape_x(tri(:,3));
    yk = shape_y(tri(:,3));

    % Compute warped shape change due to current triangle: delta s
    new_shape_x = bsxfun(@plus, xi, bsxfun(@times, alfa, xj - xi) + bsxfun(@times, beta, xk - xi)) - shape_x(tri);
    new_shape_y = bsxfun(@plus, yi, bsxfun(@times, alfa, yj - yi) + bsxfun(@times, beta, yk - yi)) - shape_y(tri);

    % Sum shape changes delta s
    shape_change_x = accumarray(tri(:), new_shape_x(:)) ./ accumarray(tri(:), ones(numel(tri), 1));
    shape_change_y = accumarray(tri(:), new_shape_y(:)) ./ accumarray(tri(:), ones(numel(tri), 1));
    shape_change = reshape([shape_change_x'; shape_change_y'], [v * 2 1])';
    