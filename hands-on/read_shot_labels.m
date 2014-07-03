function [labels, lablist] = read_shot_labels(filename)
%READ_SHOT_LABELS Reads the specified shot labels file
%
%   labels = read_shot_labels(filename)
%   [labels, lablist] = read_shot_labels(filename)
%   
% Reads the specified shot labels file (made using the shot labeller). The
% function can also return a list of all possible shot labels.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology

    
    X = load(filename);
    labels = X(:,2);
    if nargout > 1
        lablist = unique(labels);
    end
    