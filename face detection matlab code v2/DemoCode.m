function DemoCode

% Sample codes for PolyU palmprint images
Ps=[8,8,8];
Rs=[4,3,2];  
BlockSize = [16,32];
for i=1:length(Ps)
    patternMapping{i} = getmapping(Ps(i),'u2');
end
% Read three images
Gray1 = imread('PolyU001_1.bmp');
Gray2 = imread('PolyU001_2.bmp');
Gray3 = imread('PolyU002_1.bmp');
Gray1 = im2double(Gray1);
Gray1 = (Gray1-mean(Gray1(:)))/std(Gray1(:));
Gray2 = im2double(Gray2);
Gray2 = (Gray2-mean(Gray2(:)))/std(Gray2(:));
Gray3 = im2double(Gray3);
Gray3 = (Gray3-mean(Gray3(:)))/std(Gray3(:));
% Get features for three images
LBPFeature1 = GetMultiscaleLBP(Gray1,BlockSize,Rs,Ps,patternMapping,0);
LBPFeature2 = GetMultiscaleLBP(Gray2,BlockSize,Rs,Ps,patternMapping,0);
LBPFeature3 = GetMultiscaleLBP(Gray3,BlockSize,Rs,Ps,patternMapping,0);
D12 = distMATChiSquare(LBPFeature1,LBPFeature2)
D13 = distMATChiSquare(LBPFeature1,LBPFeature3)
D23 = distMATChiSquare(LBPFeature2,LBPFeature3)

% Sample codes for AR face images
Ps=[8,8,8];
Rs=[4,3,2];  
BlockSize = [20,26];
for i=1:length(Ps)
    patternMapping{i} = getmapping(Ps(i),'u2');
end
% Read three images
Gray1 = imread('AR001-1.tif');
Gray2 = imread('AR001-2.tif');
Gray3 = imread('AR002-1.tif');
Gray1 = im2double(Gray1);
Gray1 = (Gray1-mean(Gray1(:)))/std(Gray1(:));
Gray2 = im2double(Gray2);
Gray2 = (Gray2-mean(Gray2(:)))/std(Gray2(:));
Gray3 = im2double(Gray3);
Gray3 = (Gray3-mean(Gray3(:)))/std(Gray3(:));
% Get features for three images
LBPFeature1 = GetMultiscaleLBP(Gray1,BlockSize,Rs,Ps,patternMapping,1);
LBPFeature2 = GetMultiscaleLBP(Gray2,BlockSize,Rs,Ps,patternMapping,1);
LBPFeature3 = GetMultiscaleLBP(Gray3,BlockSize,Rs,Ps,patternMapping,1);
D12 = distMATChiSquare(LBPFeature1,LBPFeature2)
D13 = distMATChiSquare(LBPFeature1,LBPFeature3)
D23 = distMATChiSquare(LBPFeature2,LBPFeature3)

