function [init_cropping,Lx,Ux,Ly,Uy] = croppedImage(im)
% Description: This function gets a scanned facial image and gives approximate left,
% right, up and down limits of cropped still image, as well as the cropped image.
%
% Argument :  im                - Initial scanned image matrix in sizes A4,
%                                 Bussinusess Card etc, produced by 
%                                 a desktop scanner, so that the facial 
%                                 still image is located at the top-left 
%                                 corner of scaning plane (please refer to
%                                 the manual).
% 
% Returns:    init_cropping     - Approximate facial image.
%
%             Lx                - Left border
%             Ux                - Right border
%             Ly                - Upper limit
%             Uy                - Lower limit
%

% Original version by Amir Hossein Omidvarnia,  October 2007
% Email: aomidvar@ece.ut.ac.ir

im = imadjust(im,[.05 .05 0.05; .95 .95 0.95],[]);
im2 = im(:,:,1);
im2(im2>240) = 255; % Graininess removing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cropping image

x = sum(im2); % x-profile
x = x.^2;
x = smooth(x);
xthresh = max(x) - 0.02*(max(x) - min(x));
x1 = x < xthresh;

y = sum(im2,2); % y-profile
y = y.^2;
y = smooth(y);
ythresh = max(y) - 0.02*(max(y) - min(y));
y1 = y < ythresh;

temp = find(x1==1);
if(isempty(temp))
    Lx = 1;
    disp('Warning (1): Cropped image may not be appropriate. ----> Left border');
else
    Lx = temp(1);
end

if(isempty(temp))
    Ux = length(x1)/2;
    disp('Warning (2): Cropped image may not be appropriate. ----> Right border');
else
    for i = length(x1)-10:-1:1
        if(x1(i)==1)
            Ux = i;
            break
        end
    end
end

temp = find(y1==1);
if(isempty(temp))
    Ly = 1;
    disp('Warning (3): Cropped image may not be appropriate. ----> Upper limit');
else
    Ly = temp(1);
end

if(isempty(temp))
    Uy = length(y1)/2;
    disp('Warning (4): Cropped image may not be appropriate. ----> Lower border');
else
    for i = length(y1)-10:-1:1
        if(y1(i)==1)
            Uy = i;
            break
        end
    end
end

init_cropping = im(min(Ly,Uy):max(Ly,Uy),min(Lx,Ux):max(Lx,Ux),:); %%%%% Croped image