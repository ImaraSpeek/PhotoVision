function LBPFeature = GetMultiscaleLBP(Image,BlockSize,Rs,Ps,patternMapping,BoundaryFlag)
% Author Zhenhua Guo, Lei Zhang and David Zhang
% Date June 11, 2010
% Version 1.0
% Get multiscale LBP histogram
% Input Image: Image for extracting features
%       BlockSize: the size of each block
%       patternMapping: the mapping of LBP patterns
%       Rs: the radius of multiscale
%       Ps: the neighborhoods of multiscale
%       BoundaryFlag: two kinds of selection on dealing with boundary effect

if nargin<2
    BlockSize = [32,32];
end
if nargin<3
    Rs = [4,3,2]; % The radius is from small to big
end
if nargin<4
    Ps = [8,8,8];
end
if nargin<5
    for i=1:length(Ps)
        patternMapping{i} = Getmapping(Ps(i),'u2'); % Get LBP mapping for different radiuses        
    end
end
for i=1:length(Ps)    
    patternNum(i) = max(patternMapping{i});
end
if nargin<6
    BoundaryFlag = 1; % As the effective size of LBP map is differrent for differernt radiuses, some boundary regions could not provide LBP for big radius. 
    % BoundaryFlag=1 for keeping boundary region, BoundaryFlag=0 for removing boundary region
end

BlockNum(1) = size(Image,1)/BlockSize(1);
BlockNum(2) = size(Image,2)/BlockSize(2);
 
LBPFeature = [];

for m=1:BlockNum(1)
    for n=1:BlockNum(2)
        subGray = Image((m-1)*BlockSize(1)+1:m*BlockSize(1),(n-1)*BlockSize(2)+1:n*BlockSize(2));
                
        if BoundaryFlag == 1
            % Get LBP mapping for different radiuses
            for j=1:length(Ps)
                LBPTemp{j} = lbp_new(subGray,Rs(j),Ps(j),patternMapping{j},'x');
                LBPTemp{j} = double(LBPTemp{j});
            end
            % Extend LBP map for big radius, and define the pattern of these boundary pixels
            % as non-uniform patterns for further processing
            size1 = size(LBPTemp{length(Ps)});
            for j=1:length(Ps)-1
                size2 = size(LBPTemp{j});
                size12Diff = (size1-size2)/2;
                LBPTempNew = LBPTemp{j};
                LBPTemp{j} = ones(size1)*patternNum(j); % Extend the LBP map and make all pixels as non-uniform patterns
                LBPTemp{j}(1+size12Diff(1):size1(1)-size12Diff(1),1+size12Diff(2):size1(2)-size12Diff(2)) = LBPTempNew; % Validate the pattern of the central part
            end                 
        else
            LBPTemp{1} = lbp_new(subGray,Rs(1),Ps(1),patternMapping{1},'x');
            LBPTemp{1} = double(LBPTemp{1});
            size1 = size(LBPTemp{1});
            % Get LBP mapping for different radiuses and remove boundary regions
            for j=2:length(Ps)
                LBPTemp{j} = lbp_new(subGray,Rs(j),Ps(j),patternMapping{j},'x');
                size2 = size(LBPTemp{j});
                size12Diff = (size2-size1)/2;
                LBPTemp{j} = LBPTemp{j}(1+size12Diff(1):size2(1)-size12Diff(1),1+size12Diff(2):size2(2)-size12Diff(2));
                LBPTemp{j} = double(LBPTemp{j});
            end                               
        end
        % Get Hierachial Multiscale LBP Histogram
        Threshold = patternNum(1);
        idxMat = LBPTemp{1}==Threshold;
        for j=2:length(Ps)
            LBPTemp{1}(idxMat) = LBPTemp{1}(idxMat)+LBPTemp{j}(idxMat);
            if j<length(Ps)
                Threshold = Threshold+patternNum(j);
                idxMat = LBPTemp{1}==Threshold;
            end
        end
        LBPFeature = [LBPFeature,hist(LBPTemp{1}(:),0:sum(patternNum))];
    end
end