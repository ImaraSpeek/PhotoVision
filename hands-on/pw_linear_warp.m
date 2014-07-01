function [warped_appear, precompY, precompX] = pw_linear_warp(appearance, base_shape, shape, size_aam, precompY, precompX)
%PW_LINEAR_WARP Computes a piecewise linear warp of appearance onto shape
%
%   warped_appear = pw_linear_warp(appearance, base_shape, shape, size_aam)
%   [warped_appear, precompY, precompX] = pw_linear_warp(appearance, base_shape, shape, size_aam)
%   warped_appear = pw_linear_warp(appearance, base_shape, shape, size_aam, precompY, precompX)
%
% Computes a piecewise linear warping of the specified appearance onto
% base_shape, assuming shape is the reference frame for appearance. The
% appearance image with shape model shape is thus piecewise linearly warped 
% onto base_shape. The function uses an implementation employing Barycentric
% coordinates, of which large portions are implemented in C.
% If many warps with the same base_shape (and same-size images) are
% performed, the structs precompY and precompX should be employed.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology
  

    % Compute displacements
    diff = (base_shape - shape)';
    diff_x = diff(1:2:end);
    diff_y = diff(2:2:end);
    
    % Compute where pixels should be obtained from
    if exist('precompY', 'var')
        
        % Compute where each pixel should be obtained from
        newCoordsY = linear_interpol2(diff_y, precompY.tri, precompY.w, precompY.in, precompY.yi, size(appearance, 1));
        newCoordsX = linear_interpol2(diff_x, precompX.tri, precompX.w, precompX.in, precompX.xi, size(appearance, 2));
    else
        
        % Computing warping displacements
        [xi, yi] = meshgrid(1:size_aam(2), 1:size_aam(1));
        [displaceY, precompY] = linear_warp(base_shape(1:2:end), base_shape(2:2:end), diff_y, xi, yi);
        [displaceX, precompX] = linear_warp(base_shape(1:2:end), base_shape(2:2:end), diff_x, xi, yi); 
        precompY.yi = yi;
        precompX.xi = xi;
        
        % Compute where each pixel should be obtained from
        newCoordsY = minus_bordercheck(precompY.yi, displaceY, precompY.in, size(appearance, 1));
        newCoordsX = minus_bordercheck(precompX.xi, displaceX, precompY.in, size(appearance, 2));
    end    
        
    % Put the pixels into the right position    
    if ndims(appearance) == 2
        warped_appear = do_warp(appearance, newCoordsX, newCoordsY, precompY.in, size_aam);
    else
        warped_appear = reshape(do_warp_color(appearance, newCoordsX, newCoordsY, precompY.in, size_aam), size_aam);
    end
end

    
    
function [zi, precomp] = linear_warp(x, y, z, xi, yi)
%LINEAR_WARP Triangle-based affine warp with linear interpolation
%
% This function performs an affine warp with linear interpolation. Most
% importantly, the function returns the triangle assignments and
% Barycentric coordinates for the warp, which may be re-used if one is
% repeatedly warping onto the same shape. LINEAR_INTERPOL and
% LINEAR_INTERPOL2 take these arguments as input.
%
%
%   Reference: David F. Watson, "Contouring: A guide
%   to the analysis and display of spacial data", Pergamon, 1994.


    % Initialize some variables
    xi = xi(:); yi = yi(:);
    x = x(:); y = y(:);

    % Triangularize the data
    tri = delaunayn([x y]);

    % Find the nearest triangle
    t = tsearch(x, y, tri, xi, yi);

    % Only keep the relevant triangles
    out = isnan(t);
    t(out) = 1;
    tri = tri(t,:); 

    % Compute Barycentric coordinates (w): page 78 in Watson
    x_tri = x(tri);
    y_tri = y(tri);
    del = (x_tri(:,2) - x_tri(:,1)) .* (y_tri(:,3) - y_tri(:,1)) - ... 
          (x_tri(:,3) - x_tri(:,1)) .* (y_tri(:,2) - y_tri(:,1));
    x_tri = bsxfun(@minus, x_tri, xi);
    y_tri = bsxfun(@minus, y_tri, yi);
    w = zeros(size(tri));
    w(:,3) = (x_tri(:,1) .* y_tri(:,2) - ... 
              x_tri(:,2) .* y_tri(:,1));
    w(:,2) = (x_tri(:,3) .* y_tri(:,1) - ... 
              x_tri(:,1) .* y_tri(:,3));
    w(:,1) = (x_tri(:,2) .* y_tri(:,3) - ... 
              x_tri(:,3) .* y_tri(:,2));
    w = bsxfun(@rdivide, w, del);
    w(repmat(out, [1 3])) = 0;
    
    % Performs: zi = round(sum(z(tri) .* w, 2));
    zi = linear_interpol(z, tri, w, ~out);

    % Store precomputed values
    if nargout > 1
        precomp.w = w;
        precomp.tri = tri;
        precomp.in = ~out;
    end
end

        