function [canon_image, init_cropping] = faceNormalization(im)
% Description: This function gets a scanned facial image and produces a
% normalized image, according to ISO standard.
%
% Argument:   im                - Initial scanned image matrix in sizes A4,
%                                 Bussinusess Card etc, produced by 
%                                 a desktop scanner, so that the facial 
%                                 still image is located at the top-left 
%                                 corner of scaning plane (please refer to the manual).
%
% Returns:    canon_image       - Canonical image, output of 'canonical_image'
%                                 function, which meets the requirments of 
%                                 ISO standard for E-passport applications 
%                                 (please refer to manual for mor details).
%
%             init_cropping     - Approximate facial image, output of
%                                 'cropped_image' function, in which the 
%                                 positions of eyes are highlighted. In this stage, 
%                                 the approximate region of still image is 
%                                 cropped from scanning plane and passed to 
%                                 'canonical_image' function for eye finding and final
%                                 normalization.
% See also: CROPPED_IMAGE, CANONICAL_IMAGE

% Original version by Amir Hossein Omidvarnia,  October 2007
% Email: aomidvar@ece.ut.ac.ir
init_cropping = croppedImage(im); % Extracts an inaccurate facial image from scanning plane
[canon_image, xL, yL, xR, yR] = canonicalImage( init_cropping ); % Produsces an accurate canonical image
init_cropping(yL-5:yL+5,xL-5:xL+5,:) = 255; % Highlights positions of the left eye
init_cropping(yR-5:yR+5,xR-5:xR+5,:) = 255; % Highlights positions of the right eye
