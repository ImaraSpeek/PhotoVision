function J = pw_linear_warp_jacobian(p, base_shape, shape_pcs, size_aam)
%PW_LINEAR_WARP_JACOBIAN Computes Jacobian of a piecewise linear warp
%
%   J = pw_linear_warp_jacobian(p, base_shape, shape_pcs, size_aam)
%
% Compute the Jacobian of the piecewise linear warp from the triangular mesh 
% base_shape to some other triangular mesh shape. The 3x1 vector size_aam 
% specifies the size of the appearance model.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Compute and normalize base shape
    base_shape = base_shape + sum(bsxfun(@times, p, shape_pcs), 2)';
    base_shape_x = base_shape(1:2:end)';
    base_shape_y = base_shape(2:2:end)';
    base_shape_x = base_shape_x - min(base_shape_x);
    base_shape_x = base_shape_x / max(base_shape_x);
    base_shape_y = base_shape_y - min(base_shape_y);
    base_shape_y = base_shape_y / max(base_shape_y);
    v = numel(base_shape_x);
    
    % Why do we need the normalization???
    
    % Compute Delaunay triangulation of base shape
    tri = delaunay(base_shape_x, base_shape_y);
    
    % Create lookup table for all pixels in a triangle
    [x, y] = meshgrid(0:1 / (size_aam(2) - 1):1, 0:1 / (size_aam(1) - 1):1);
    lookup = repmat(false, [size_aam(1) size_aam(2) size(tri, 1)]);
    for i=1:size(tri, 1)
        in = inhull([x(:) y(:)], [base_shape_x(tri(i,:)) base_shape_y(tri(i,:))]);
        lookup(:,:,i) = reshape(logical(in), [size_aam(1) size_aam(2)]);
    end
    
    % Compute alfa and beta matrices
    alfa = zeros(size_aam(1), size_aam(2), v);
    beta = zeros(size_aam(1), size_aam(2), v);
    for i=1:v
        
        % Loop over the triangles that correspond to vertex
        [r, c] = find(tri == i);
        for j=1:length(r)
            
            % Obtain triangle coordinates
            tri_r = tri(r(j),:);
            tri_r(tri_r == i) = [];
            xi = base_shape_x(i);
            yi = base_shape_y(i);
            xj = base_shape_x(tri_r(1));
            yj = base_shape_y(tri_r(1));
            xk = base_shape_x(tri_r(2));
            yk = base_shape_y(tri_r(2));
        
            % Compute the alfa and beta values
            alfa(:,:,i) = alfa(:,:,i) + ...
                          (lookup(:,:,r(j)) .* ...
                          (((x  - xi) * (yk - yi) - (y  - yi) * (xk - xi)) ./ ...
                           ((xj - xi) * (yk - yi) - (yj - yi) * (xk - xi))));
            beta(:,:,i) = beta(:,:,i) + ...
                          (lookup(:,:,r(j)) .* ...
                          (((y  - yi) * (xj - xi) - (x  - xi) * (yj - yi)) ./ ...
                           ((xj - xi) * (yk - yi) - (yj - yi) * (xk - xi))));
        end
    end
    
    % Compute Jacobian of warp w.r.t. change in vertex (dWdy = dWdx)
    dWdx = (1 - alfa - beta);  
    for i=1:v
        ind = (alfa(:,:,i) == 0 & beta(:,:,i) == 0);    % the Jacobian does not exist outside lookup
        tmp = dWdx(:,:,i);
        tmp(ind) = 0;
        dWdx(:,:,i) = tmp;
    end
    
    % Compute final Jacobian (contains 2 x #PCs images)
    shape_x = zeros(1, 1, v);
    shape_y = zeros(1, 1, v);
    J = zeros(size_aam(1), size_aam(2), 2, size(shape_pcs, 2));
    for i=1:size(shape_pcs, 2)
        shape_x(1,1,:) = shape_pcs(1:2:end, i);
        shape_y(1,1,:) = shape_pcs(2:2:end, i);    
        J(:,:,1,i) = sum(bsxfun(@times, dWdx, shape_x), 3);
        J(:,:,2,i) = sum(bsxfun(@times, dWdx, shape_y), 3);
    end
    