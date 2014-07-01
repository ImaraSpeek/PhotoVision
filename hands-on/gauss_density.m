function [dens, inv_sigma, factor] = gauss_density(x, mu, sigma, inv_sigma, factor)
%GAUSS_DENSITY Compute density of a vector under a multivariate Gaussian
%
%   dens = gauss_density(x, mu, sigma, inv_sigma, factor)
%   [dens, inv_sigma, factor] = gauss_density(x, mu, sigma)
%
% Compute density of the vector x under the multivariate Gaussian specified
% by mean mu and covariance sigma. For speed reasons, it is also possible
% to specify the inverse covariance matrix as well in inv_sigma, and the
% normalization factor in factor.
%
%
% (C) Laurens van der Maaten, 2009
% Delft University of Technology


    % Perform precomputations (if required)
    if ~exist('inv_sigma', 'var') || isempty(inv_sigma)
        inv_sigma = inv(sigma);
    end
    if ~exist('factor', 'var') || isempty(factor)
        factor = 1 / ((2 .* pi) .^ (length(mu) / 2) .* sqrt(det(sigma)));
    end

    % Compute density
    diff = x - mu;
    dens = factor .* exp(-.5 * diff * inv_sigma * diff');