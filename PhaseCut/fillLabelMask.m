function [labcellmask, labseedmask, pixOvlapMap] = fillLabelMask(objInfo,cellObj,seedObj,crpCoor)
%% Initialize the masks
[labcellmask, labseedmask, pixOvlapMap]= deal(uint16(zeros(objInfo.ImageSize)));

%% Loop through the cell objects
for obj_i = 1:length(cellObj)
    if ~isempty(cellObj{obj_i})
        [ycur, xcur] = ind2sub(cellObj{obj_i}.ImageSize, cellObj{obj_i}.PixelIdxList{1});
        labcellmask(sub2ind(objInfo.ImageSize,ycur+crpCoor{obj_i}(1)-1,xcur+crpCoor{obj_i}(3)-1)) = obj_i;
        pixOvlapMap(sub2ind(objInfo.ImageSize,ycur+crpCoor{obj_i}(1)-1,xcur+crpCoor{obj_i}(3)-1)) = pixOvlapMap(sub2ind(objInfo.ImageSize,ycur+crpCoor{obj_i}(1)-1,xcur+crpCoor{obj_i}(3)-1))+1;
    end
    if ~isempty(seedObj{obj_i})
        for seed_i = 1:length(seedObj{obj_i}.PixelIdxList)
            [ycur, xcur] = ind2sub(seedObj{obj_i}.ImageSize, seedObj{obj_i}.PixelIdxList{seed_i});
            labseedmask(sub2ind(objInfo.ImageSize,ycur+crpCoor{obj_i}(1)-1,xcur+crpCoor{obj_i}(3)-1)) = obj_i;
        end
    end
end
end