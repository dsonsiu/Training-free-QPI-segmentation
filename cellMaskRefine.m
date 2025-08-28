function newMsk = cellMaskRefine(img, oMsk)
%% Description
% To refine the mask edge

%% Main function
% ===== Extend the mask to include the edges
ImgGrad = fibermetric(imgradient(img.QP));
negMsk = imerode(sum(img.CM,3)>0 & ~oMsk,strel('disk',10));
oMsk1 = oMsk + (ImgGrad>0.02); % Extend the mask with edge
% ===== Screen away noise that is not linked to the original mask
objinfo = masklabel(oMsk1>0 & ~negMsk, oMsk1.*~negMsk);
isMskN = objinfo.mskn > 1; isSize = objinfo.mskobjsz > 2000;
isMain = find(isMskN & isSize);
objinfo.PixelIdxList = objinfo.PixelIdxList(isMain);
objinfo.NumObjects = length(isMain);

oMsk2 = labelmatrix(objinfo);
oMsk3 = imclose(oMsk2,strel('disk',25));
oMsk4 = imfill(oMsk3,'holes');

% ===== First segment
ACMask = activecontour(ImgGrad, oMsk4, 10, 'Chan-Vese', 'ContractionBias',0);
% --- Enforce negative mask again
ACMask = ACMask & (~negMsk);
% --- Write in object
mskobj = bwconncomp(ACMask);

% ===== Second segment
if mskobj.NumObjects > 2
    ACMask = activecontour(ImgGrad,oMsk,'edge','SmoothFactor',0.01,'ContractionBias',0);
end
% Specify to one cell
if sum(ACMask,'all') ~= 0
    newMsk = selCell(ACMask,oMsk);
else
    newMsk = ACMask;
    return
end


end

function selMask = selCell(Msk, oMsk)
% ----- Select the targeted cell/seed by overlapping
OMskObj = bwconncomp(oMsk);
MskObj = bwconncomp(Msk);
OvlPxNum = cellfun(@(x) sum(ismember(OMskObj.PixelIdxList{1},x)),MskObj.PixelIdxList);
% - Specify targeted cell/seed
[~,TgCell_i] = max(OvlPxNum);
% - Construct new mask with the targeted cell/seed
TgMskObj = MskObj;
TgMskObj.PixelIdxList = MskObj.PixelIdxList(TgCell_i);
TgMskObj.NumObjects = 1;
selMask = labelmatrix(TgMskObj)>0;

end

%{
ACMask_temp = false(size(oMsk4,1),size(oMsk4,2),11);
ACMask_temp(:,:,1) = oMsk4;
figure; tiledlayout(1,10,'TileSpacing','none');
for i = 1:10
    ACMask_temp(:,:,i+1) = activecontour(ImgGrad, oMsk4, i, 'Chan-Vese', 'ContractionBias',0);
    nexttile;
    imagesc(boundarymask(ACMask_temp(:,:,i)));
end
%}