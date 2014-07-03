function im = readraw(filename)
%READRAW Read raw image from ARF dataset
%
%   im = readraw(filename)
%
% Reads an image that is in RAW format.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Read the raw image
    h = fopen(filename, 'r');
    im = permute(reshape(uint8(fread(h, [768 576 * 3], 'uint8')), [768 576 3]), [2 1 3]);
    fclose(h);