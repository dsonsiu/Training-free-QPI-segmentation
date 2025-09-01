function newmskinfo = masklabel (inputmsk,cmpMsk)
newmskinfo = bwconncomp(inputmsk);
% Coordinates of cell mask
[ycell, xcell] = cellfun(@ind2sub,repmat({newmskinfo.ImageSize},1,newmskinfo.NumObjects),newmskinfo.PixelIdxList,'UniformOutput',false);
% Number of masks in obj
sumMsk = sum(cmpMsk,3);
mskn = cellfun(@(x) max(sumMsk(x)), newmskinfo.PixelIdxList);
% Mask ratio
mskRatio = cellfun(@(x) sum(sumMsk(x)==2)/sum(sumMsk(x)==1), newmskinfo.PixelIdxList);

% Find range of cluster
ymin = round(cellfun(@min,ycell));
ymax = round(cellfun(@max,ycell));
xmin = round(cellfun(@min,xcell));
xmax = round(cellfun(@max,xcell));
newmskinfo.mskrange = [ymin;ymax;xmin;xmax]';

% Find centre of clusters
cellceny = round(mean([ymin;ymax],1));
cellcenx = round(mean([xmin;xmax],1));
newmskinfo.mskcen = [cellceny;cellcenx]';
newmskinfo.mskobjsz = cellfun(@length,newmskinfo.PixelIdxList);
newmskinfo.mskn = mskn;
newmskinfo.mskRatio = mskRatio;

end