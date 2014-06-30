function [pos neg test] = multipie_data()
globals;

% Define training and testing images from each viewpoint
trainlist = [{1:50},{1:50},{1:50},{1:50},{1:50},{1:50},{1:300},{1:50},{1:50},{1:50},{1:50},{1:50},{1:50}];
testlist = [{51:100},{51:100},{51:100},{51:100},{51:100},{51:100},{301:600},{51:100},{51:100},{51:100},{51:100},{51:100},{51:100}];

assert(length(trainlist)==length(opts.mixture));
assert(length(testlist)==length(opts.mixture));

% MultiPIE home directory
multipiedir = '/home/dataset/multipie/';
% MultiPIE annotation files
annodir = '/home/dataset/multipie_annotation/';

% MultiPIE data info
load multipie;
assert(length(multipie)==length(opts.mixture));

% negative images
negims = 'INRIA/%.5d.jpg';
negfrs = 615:1832;

% build positive training samples
disp('Building positive training samples ...');
n = 0;
for i = 1:length(opts.mixture)
    gmixid = i;
    for j = 1:length(trainlist{i})
        % main part of the image/annotation file name
        nam = multipie(i).images{trainlist{i}(j)};
        % load landmark annotation
        load([annodir, nam ,'_lm.mat']);
        assert(size(pts,1)==multipie(i).nlandmark);
        n = n+1;

        % re-order the landmarks
        pos(n).pts = opts.mixture(gmixid).anno2treeorder*pts;

        % locate image
        [subID sesID recID camlabel1 camlabel2 imgID] = parsefilename(nam);
        pos(n).im = sprintf('%sdata/session%.2d/multiview/%.3d/%.2d/%.2d_%.1d/%s.png', ...
            multipiedir,sesID,subID,recID,camlabel1,camlabel2,nam);
        % make sure that this file exists
        assert(exist(pos(n).im,'file')==2);
        pos(n).gmixid = gmixid;
    end
end

% negative images
disp('Collecting negative training images info ...');
n = 0;
for fr = negfrs,
    n = n + 1;
    neg(n).im = sprintf(negims,fr);
end

% testing samples
disp('Building testing samples ...');
n = 0;
for i = 1:length(opts.mixture)
    gmixid = i;
    for j = 1:length(testlist{i})
        % main part of the image/annotation file name
        nam = multipie(i).images{testlist{i}(j)};
        
        % load landmark annotation
        load([annodir, nam ,'_lm.mat']);
        assert(size(pts,1)==multipie(i).nlandmark);
        n = n+1;
        
        % re-order landmarks
        test(n).pts = opts.mixture(gmixid).anno2treeorder*pts;

        % locate image
        [subID sesID recID camlabel1 camlabel2 imgID] = parsefilename(nam);
        test(n).im = sprintf('%sdata/session%.2d/multiview/%.3d/%.2d/%.2d_%.1d/%s.png', ...
            multipiedir,sesID,subID,recID,camlabel1,camlabel2,nam);
        
        % make sure that this file exists
        assert(exist(test(n).im,'file')==2);
        test(n).gmixid = gmixid;
    end
end

function [subID sesID recID camlabel1 camlabel2 imgID] = parsefilename(nam)
subID = str2double(nam(1:3));  % person ID
sesID = str2double(nam(5:6));
recID =  str2double(nam(8:9)); % expression
camlabel1 = str2double(nam(11:12));
camlabel2 = str2double(nam(13));
imgID = str2double(nam(15:16)); % lighting

