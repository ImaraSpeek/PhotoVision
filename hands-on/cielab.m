function [L, a, b] = cielab(RGB, direction)
%CIELAB Conversion from RGB to CIELab
%
%	[L, a, b] = cielab(RGB, 'ToLab')
%   [R, G, B] = cielab(Lab, 'ToRGB')
%
% Converts the given R, G, B image into the CieL*a*b* color space, or vice
% versa. The first call is the default
% The advantage of the CieL*a*b* color space is its perceptual linearity.
%
%
% (C) Laurens van der Maaten, 2007
% Universiteit Maastricht

    if ~exist('direction', 'var')
        direction = 'ToLab';
    end
    
    % Convert to CieL*a*b*
    if strcmp(direction, 'ToLab')
        Lab = colorspace('RGB->Lab', double(RGB));
        L = Lab(:,:,1); a = Lab(:,:,2); b = Lab(:,:,3);
    else
        Lab = colorspace('Lab->RGB', double(RGB));
        L = Lab(:,:,1); a = Lab(:,:,2); b = Lab(:,:,3);
    end
    
    % Apply scaling within domain [0, 255]
    scaling = max([max(max(L)) max(max(a)) max(max(b))]);
    L = 255 * L ./ scaling;
    a = 255 * a ./ scaling;
    b = 255 * b ./ scaling;