function [canon_image,xL,yL,xR,yR] = canonicalImage(init_cropping)
% Description: This function gets approximate facial image (the output image of 'cropped_image'
% function) and extracts a 320x240 canonical image in which, 
%           the distance between eyes is fixed to 60 pixels, 
%           the distance between eyes line and upper limit is 144 pixels,
%           the distance between eyes line and lower limit is 176 pixels,
%           the distance between left eye and left border is 90 pixels,
%           and the distance between right eye and right border is 90 pixels too.
% It calls 'eyefinder' function of Copyright (c) 2003 Machin Perception Toolbox, University of
% California San Diego. For more detail, please refer to readme.txt.
 

% Arguments:  init_cropping     - Approximate facial image.
%
% Returns:    canon_image       - Canonical image, which meets the dimensional requirments of 
%                                 ISO standard for E-passport applications.                                 
%                                 In the case that the function is unable
%                                 to extract the canonical image, a 320x240
%                                 white plane will be produced.
%
%            (xL,yL)            - Coordinate of the left eye
%            (xR,yR)            - Coordinate of the right eye
%
% See also: EYEFINDER (MPT Toolbox)

% Original version by Amir Hossein Omidvarnia,  October 2007
% Email: aomidvar@ece.ut.ac.ir

try

    out = eyefinder(init_cropping);
    xL = fix(mean(out(1).left_eye_x));
    yL = fix(mean(out(1).left_eye_y));
    xR = fix(mean(out(1).right_eye_x));
    yR = fix(mean(out(1).right_eye_y));

    eyes_dist = xL-xR; % distance between two eyes
    eyes_line = floor((yL+yR)/2); % Eyes line
    ratio = 60/eyes_dist; % The ratio which make the distance of eyes in resized image fix to 60 pixels
                          % (according to ISO standard)
    resize_new = imresize(init_cropping, ratio);

    if( fix(ratio*eyes_line-144)<1 )
        bond_up = 1;
    else
        bond_up = fix(ratio*eyes_line)-144;
    end

    if( fix(ratio*eyes_line+175) > size(resize_new,1) )
        bond_down = ratio*eyes_line+175;
    else
        bond_down =  fix(ratio*eyes_line) + 175;
    end

    if( (fix(ratio*(xL))-90) < 1 )
        bond_left = 1;
    else
        bond_left = fix(ratio*(xR))-90;
    end

    if( (fix(ratio*(xR))+89) > size(resize_new,2) )
        bond_right = fix(ratio*(xL))+89;
    else
        bond_right = fix(ratio*(xL))+89;
    end

    canon_image = resize_new(  bond_up : bond_down, bond_left : bond_right , : );
    disp('Normalized image was constructed successfully!')
catch
    canon_image = 256*ones(320,240);
    disp('Normalized image cannot be constructed.')
end
