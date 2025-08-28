function indvcmask = watershedcmask (QPI, cellClusMask)
% ----- Smoothen the QPI
smQPI=imopen(QPI,strel('disk',10));
% ----- Define masked QPI
phasMask=imcomplement(smQPI.*cellClusMask);
% - Force background to -inf
phasMask(phasMask==1) = -Inf;
% ----- Suppress peak Version2
% - Find regional peaks
maxRegMask = imdilate(imextendedmax(smQPI,0.01),strel('disk',10)).* QPI>0.15;
% - Force regional peaks to -inf
phasMask(maxRegMask) = -inf;
% ----- Watershed
sepMask = watershed(imhmin(phasMask,0.1));
% - Overlay with external mask for refinement
indvcmask = ((sepMask>1).*cellClusMask);
end

% -- Constrain peak Version1 
%{
% - Suppress shorter peaks
mPhasMask = imhmin(phasMask,0.03);
%}