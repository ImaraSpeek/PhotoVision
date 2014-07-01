function captureWarpPoints(imageName)
% Usage:  createWarpPoints is a gui program that enables a user to create a cell array of [x y] points 
%  that can be used in the warpImage function to warp an image.  By clicking the mouse on the points in the loaded image window (which contains the
%  picture given by the argument "imageName"), that correspond to the points in the reference image, the points are recorded in a cell array 
%  and written to disk under the name "imageName".pts.mat.  To undo a recorded point, press the space button.
%
% Input:  the name of the image file that one wants to capture the points from
%
% Output:  A file of points will be written to disk under the name "imageName".pts.mat
%
% Note: one can change the reference image and/or the number of points to be recorded by replacing the files "refImage.jpg" and "refPoints.mat"
%
% (c) Ethan Meyers 2002  emeyers@mit.edu


% set the im preferences, so that image expands to the whole size of the frame
IPTSETPREF('ImshowBorder', 'tight');

% create the reference window
refFigure = figure(98);    
refImage = imread('refImage.jpg');


% load the reference points 
load refPoints;   
numPoints = size(refPoints, 2)
set(98, 'Position', [10,200,400,400]);


% puts the first reference point on the reference image
updateRef(1, refImage, refPoints)  


% creates the capture figure and loads the capture image on it
captureFigure = figure(76);
set(76, 'Position', [520, 0, 400,400]);
capImage = imread(imageName);
capImgHandle = imshow(capImage, 'truesize');


numPoints = size(refPoints,2);
i = 1;

% capture all the reference points...
while(i < numPoints + 2)      
   
    k = waitforbuttonpress;
    
    if i == (numPoints + 1)  % makes sure one last button press before saving (so that can undo last point if needed)
        break;
    end
    
    % if the mouse was pressed - get x, y coords and if valid update them
    if k == 0
        z = get(76, 'CurrentPoint');
        x = z(1);
        y = size(capImage, 1) - z(2);     
        
        points{i} = [x y];
        
        if valid(points, i) ~= 0
            i = i + 1;
            updateRef(i, refImage, refPoints);
            updateCap(i-1, capImage, points);
        end
        
    end
    
    
    %if a key was pressed, undo last mouse button press
    if k == 1
        if i > 1       
            i = i - 1;
            updateRef(i, refImage, refPoints);
            updateCap(i-1, capImage, points);
        end        
    end
    
end  % end while loop


% save fileName points;
fileName = [imageName '.pts.mat'];
save(fileName, 'points');    

close(98);
close(76);





% function tests if a given point is valid (i.e. if the point is not the same point as before and if the point is not totally off)
function bool = valid(points, index)
    
    px = points{index}(1);
    py = points{index}(2);
    
    % if click on the wrong image, won't update the point
    if (index > 1)
        ox = points{index - 1}(1);
        oy = points{index - 1}(2);
        
        if ((ox == px) & (oy == py))
            bool = 0;
            warning('wake up and watch where you are clicking');
            return
        end
    end    
   
    % if first click is off the image
    if ((index == 0) & px == 0 & py == 665)
        bool = 0;
        warning('wake up and watch where you are clicking');
        return
    end
    
    
    % could do one last check to make sure that i'm not totally spacing based on distance... (nah) will be obvious when i look at image
    
    
    bool = 1;
    
    
    



function updateRef(i, refImage, refPoints)
% a helper function that updates the reference image by putting a red dot at the next point that is to be recorded
    
    if i < (size(refPoints, 2) + 1)      % makes sure that last update call does not generate an error
        modRefImage = putPoint(refImage, refPoints{i});
        figure(98);
        refImgHandle = imshow(modRefImage, 'notruesize');
    
    end

    
    
function updateCap(i, capImage, points)
% a helper function that updates the image of which points should be captured by putting a red dot at the next point that is to be recorded
    for j = 1:i
        capImage = putPoint(capImage, points{j});
    end
    figure(76);
    imshow(capImage);
    
    
    
function pointImg = putPoint(img, point)
% a helper function that draws a red dot on the image img at point "point" (where point a 1 x 2 matrix)
    x = point(1);
    y = point(2);

    pointImg = img;

    if size(img, 3) < 2
        pointImg(:,:,2) = img;
        pointImg(:,:,3) = img;
    end
    
    pointImg(y-1:y+1, x-1:x+1,1) = 256;
    pointImg(y-1:y+1, x-1:x+1,2) = 1;
    pointImg(y-1:y+1, x-1:x+1,3) = 1;










