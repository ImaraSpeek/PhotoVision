function [warpedImage] = warpImage(Image, originalMarks, desiredMarks)
% Warps Image so that orinal marked points are at the desired marked points and all other points 
%   are interpolated in correctly.
%
% Input: an Image to be warped, and two cell arrays of 1x2 matricies containing the x and y coordinates of the points 
%   on the image to be moved (originalMarks) and the positions where the points should be moved to (desiredMarks).
%
% Output: a warped Image in which the original points are at the desired points and all other points are moved corespondingly
%
% (c) Ethan Meyers 2002  emeyers@mit.edu


Image = double(Image);

[m, n] = size(Image);

xi = 1:n;
yi = 1:m;

% calls the helper function getPoints to vectors of the 
[x y zx, zy] = getPoints(Image, originalMarks, desiredMarks);

% interpolate all the points in the image based on the displacements calculated above
%displaceX = griddata(x, y, zx, xi', yi, 'cubic');   
%displaceY = griddata(x, y, zy, xi', yi, 'cubic'); 
displaceX = griddata(x, y, zx, xi', yi, 'cubic', {'QJ'});   
displaceY = griddata(x, y, zy, xi', yi, 'cubic', {'QJ'});


displaceX = round(displaceX);
displaceY = round(displaceY);


% removes and NaN from the griddata interpolation
displaceX(find(isnan(displaceX))) = 0; 
displaceY(find(isnan(displaceY))) = 0; 

% change back into matricies
displaceX = reshape(displaceX, m,n);
displaceY = reshape(displaceY, m,n);


% calc where each pixel should be remapped
[coordsX coordsY] = meshgrid(1:n, 1:m);

newCoordsX = coordsX + displaceX;
newCoordsY = coordsY + displaceY;

% adjust any pixels that might be out of range of the image
newCoordsX(find(newCoordsX < 1)) = 1; 
newCoordsX(find(newCoordsX > n)) = n; 
newCoordsY(find(newCoordsY < 1)) = 1; 
newCoordsY(find(newCoordsY > m)) = m; 


linearX = reshape(newCoordsX, 1, m*n); 
linearY = reshape(newCoordsY, 1, m*n); 

indecies = sub2ind([m,n], linearY, linearX);  

Image = reshape(Image, 1, n*m);

warpedImage = Image(indecies);
warpedImage = reshape(warpedImage, m, n);   % reshape back into an image

warpedImage = uint8(warpedImage);  % convert back to uint8





function [x, y, zx, zy]   =  getPoints(Image, originalMarks, desiredMarks)
% a helper function that calculates the displacements from the originalMarks to the desired marks in the x and y directions (zx and zy respectively),
%  and also returns vectors of all the x and y points.  This function also adds the corner points of the image these vectors of points which greatly
%  helps during interpolation/warping.


[m, n] = size(Image);

numPoints = size(originalMarks, 2);


for i = 1:numPoints
    
    zx(i) = originalMarks{i}(1) - desiredMarks{i}(1);   % x offset component of the displacement vector
    zy(i) = originalMarks{i}(2) - desiredMarks{i}(2);   % x offset component of the displacement vector

    x(i) = originalMarks{i}(1);
    y(i) = originalMarks{i}(2);
    
end

    % add corners before for better interpolation
    x(i+1) = 1;
    y(i+1) = 1;
    zx(i+1) = 0;
    zy(i+1) = 0;

    x(i+2) = 1;
    y(i+2) = m;
    zx(i+2) = 0;
    zy(i+2) = 0;        

    x(i+3) = n;
    y(i+3) = 1;
    zx(i+3) = 0;
    zy(i+3) = 0;
    
    x(i+4) = n;
    y(i+4) = m;
    zx(i+4) = 0;
    zy(i+4) = 0;
    