% Set up global variables used throughout the code

addpath learning
addpath detection

% directory for caching models, intermediate data, and results
cachedir = 'cache/';
if ~exist(cachedir,'dir'),
    system(['mkdir -p ' cachedir]);
end

figdir = [cachedir 'figdir/'];
if ~exist(figdir,'dir'),
    system(['mkdir -p ' figdir]);
end

% information of the dataset, define mixture structures
multipie_init;
