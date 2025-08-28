function ObjInfo = updateObjInfo(ObjInfo)
% Coordinates of cell mask
[ycell, xcell] = cellfun(@ind2sub,repmat({ObjInfo.ImageSize},1,ObjInfo.NumObjects),ObjInfo.PixelIdxList,'UniformOutput',false);

% Find range of cluster
ymin = round(cellfun(@min,ycell));
ymax = round(cellfun(@max,ycell));
xmin = round(cellfun(@min,xcell));
xmax = round(cellfun(@max,xcell));
ObjInfo.mskrange = [ymin;ymax;xmin;xmax]';

% Find centre of clusters
% cellceny = round(cellfun(@mean,ycell));
% cellcenx = round(cellfun(@mean,xcell));
cellceny = round(mean([ymin;ymax],1));
cellcenx = round(mean([xmin;xmax],1));
ObjInfo.mskcen = [cellceny;cellcenx]';
ObjInfo.mskobjsz = cellfun(@length,ObjInfo.PixelIdxList);
end