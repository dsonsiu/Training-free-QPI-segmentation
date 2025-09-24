function [cellImg,objInfo,labcellmask,labseedmask] = PhaseCut(QPI,pixsz)
%% User-defined parameters
Opt_clearborder = true;
phasThrs = 0.07;        % rad; Phase threshold for masking
SizeRange = [35 3.5e5]; % um sq; S
MaskMargin = 20;        % um
CellPhThres = 0.1;      % rad, Cell phase threshold

%% Stage 1: Thresholding
% ===== QPI Thresholding
phCellThres = QPI > phasThrs;
phcell = bwconncomp(phCellThres);
sz = cellfun(@length, phcell.PixelIdxList) .* (pixsz^2);
szcrit = (sz > SizeRange(1)) & (sz < SizeRange(2));
labelcell = labelmatrix(phcell);
cellIdx = find(szcrit);
phCellMask = ismember(labelcell,cellIdx);

% ===== Texture Thresholding
textMap = stdfilt(QPI,true(round(3/pixsz/2)*2+1));
[BgText_hist,edge_hist] = histcounts(textMap(~phCellMask));
[~,PeakText] = findpeaks(BgText_hist(2:end),'SortStr','descend','MinPeakProminence',range(BgText_hist)/100);
textThres = edge_hist(PeakText(1))*2;
dicCellMask1 = textMap > textThres;
dicCellMask2 = bwareaopen(dicCellMask1,floor(350/(pixsz^2)));
dicCellMask = imcomplement(bwareaopen(imcomplement(dicCellMask2),floor(350/(pixsz^2)))); % Fill the holes of correct sizes only

% ===== Construct Composite mask
complxMask = cat(3, dicCellMask,phCellMask);
cellMask = sum(complxMask,3) >= 1;

%% Stage 2: QPI-based Watershed
temp = bwconncomp(cellMask); fprintf('Watershed breaks %d objects into ', temp.NumObjects);
cellMask = watershedcmask(QPI,cellMask,pixsz);
temp = bwconncomp(cellMask); fprintf('%d objects\n', temp.NumObjects); temp = [];
if Opt_clearborder
    cellMask = imclearborder(cellMask);
end
% - Construct objInfo
objInfo = masklabel(cellMask,complxMask);
szthres = SizeRange / (pixsz^2);
mskmargin = floor(MaskMargin/pixsz);

% ===== Object filtering
% - Define size criteria
szCrit = int8(zeros(1,objInfo.NumObjects));
szCrit(objInfo.mskobjsz < szthres(1)) = -1;
szCrit(objInfo.mskobjsz > szthres(2) & objInfo.mskRatio < 1) = 1;
% - Define mask layer criteria
mlCrit = objInfo.mskRatio > 0.1;
% - Define phase value criterium
objInfo.maxPh = cellfun(@(x) max(QPI(x)), objInfo.PixelIdxList);
phCrit = objInfo.maxPh > CellPhThres;
% - Combine criteria
isSel = (szCrit==0) & mlCrit & phCrit;
% - Report number of removal
fprintf('Out of size range: %d, Not supported by >1 masks: %d, Max QP value <%.2f: %d. Total screened away: %d/%d\n', sum(szCrit~=0), sum(mlCrit==0), CellPhThres, sum(phCrit==0), sum(isSel==0), objInfo.NumObjects);
% - Apply criteria and update the object info
objInfo.PixelIdxList = objInfo.PixelIdxList(isSel);
objInfo.mskrange = objInfo.mskrange(isSel,:);
objInfo.mskcen = objInfo.mskcen(isSel,:);
objInfo.mskobjsz = objInfo.mskobjsz(isSel);
objInfo.mskn = objInfo.mskn(isSel);
objInfo.NumObjects = sum(isSel);

%% Stage 3: Edge Aware Active Contour Refining
% ===== Organize objects into structs
% - Convert to label matrix
objlabelmat = labelmatrix(objInfo);
% - Define constants for masking
tempscale.unit_x = pixsz;
% -  Crop and oragnize
cellini = cell(objInfo.NumObjects,1);
[crpcurobjmsk, crpComplxMsk, cellImg, cellObj, seedObj, crpCoor] = deal(cellini); clear cellini
disptxt = sprintf('Croppping individual cell: Cell 0000/0000'); fprintf(disptxt);
for obj_i = 1:objInfo.NumObjects
    if rand < 0.1 || (obj_i == objInfo.NumObjects)
        fprintf(repmat('\b',1,length(disptxt)));
        disptxt = sprintf('Croppping individual cell: Cell %04d/%04d',obj_i,objInfo.NumObjects); fprintf(disptxt);
    end
    % - Crop to the cell
    curseedmsk = objlabelmat == obj_i; % Confine to a seed
    crpCoor{obj_i} = objInfo.mskrange(obj_i,:) + [-mskmargin, mskmargin, -mskmargin, mskmargin]; % Crop coordinates
    % - Check if any of the coordinates exceed the range
    if crpCoor{obj_i}(1) < 1; crpCoor{obj_i}(1)=1; end
    if crpCoor{obj_i}(3) < 1; crpCoor{obj_i}(3)=1; end
    if crpCoor{obj_i}(2) > size(curseedmsk,1); crpCoor{obj_i}(2) = size(curseedmsk,1); end
    if crpCoor{obj_i}(4) > size(curseedmsk,2); crpCoor{obj_i}(4) = size(curseedmsk,2); end
    crpcurobjmsk{obj_i} = curseedmsk(crpCoor{obj_i}(1):crpCoor{obj_i}(2), crpCoor{obj_i}(3):crpCoor{obj_i}(4)); % Crop out the mask
    crpComplxMsk{obj_i} = complxMask(crpCoor{obj_i}(1):crpCoor{obj_i}(2), crpCoor{obj_i}(3):crpCoor{obj_i}(4), :);

    cellImg{obj_i}.QP = QPI(crpCoor{obj_i}(1):crpCoor{obj_i}(2), crpCoor{obj_i}(3):crpCoor{obj_i}(4));
    cellImg{obj_i}.CM = crpComplxMsk{obj_i};
    cellImg{obj_i}.pixsz = tempscale.unit_x;
    cellImg{obj_i}.imgsz = tempscale.unit_x*size(cellImg{obj_i}.QP);
end
fprintf('\n');

% ===== Boundary refinement loop
isEmptyObj = zeros(objInfo.NumObjects,1);
objPixList = objInfo.PixelIdxList;
wImgSz = objInfo.ImageSize;
% - Update progress mechanism
dataQ = parallel.pool.DataQueue;
fprintf('Single-cell segmentation and analysis..\n');dispProgress(0,objInfo.NumObjects); %Initialize
afterEach(dataQ, @dispProgress);
objtimer = tic;
% parfor (obj_i = 1:objInfo.NumObjects) % parfor
for obj_i = 1:objInfo.NumObjects
    warning('off');
    % ===== Segmentation refining
    cellImg{obj_i}.cmsk = cellMaskRefine(cellImg{obj_i},crpcurobjmsk{obj_i});
    cellImg{obj_i}.smsk = cellImg{obj_i}.cmsk & cellImg{obj_i}.CM(:,:,2);

    % ===== Fill up in the object array
    if sum(cellImg{obj_i}.cmsk,'all')==0
        isEmptyObj(obj_i) = 1;
        objPixList{obj_i} = 0;
    else
        % --- Fill in the cellObj and seedObj arrays
        cellObj{obj_i} = bwconncomp(cellImg{obj_i}.cmsk);
        seedObj{obj_i} = bwconncomp(cellImg{obj_i}.smsk);
        % --- Update the objInfo array
        [msky,mskx] = ind2sub(cellObj{obj_i}.ImageSize,cellObj{obj_i}.PixelIdxList{1});
        msky = msky + crpCoor{obj_i}(1)-1; mskx = mskx + crpCoor{obj_i}(3)-1;
        objPixList{obj_i} = sub2ind(wImgSz,msky,mskx);
    end

    % ----- Update progress
    send(dataQ,toc(objtimer));
end

% ===== Final screening
% - Pre-fill overlap map for checking overlapped cells
[~, ~, pixOvlapMap1] = fillLabelMask(objInfo,cellObj,seedObj,crpCoor);
ovlap_prop = zeros(objInfo.NumObjects,1); ObjSz = objInfo.mskobjsz;
ovlappix_idx = find(pixOvlapMap1>1);
% - Check overlapped proportion in each object
for obj_i = 1:objInfo.NumObjects
    ovlap_prop(obj_i) = sum(ismember(objPixList{obj_i},ovlappix_idx))/ObjSz(obj_i);
end
isOverlap = ovlap_prop > 0.7;
fprintf('\nScreen: Empty %d, Highly-overlapped %d\n',sum(isEmptyObj),sum(isOverlap));

% ----- Remove the highly-overlapped cells
cellObj = cellObj(~isOverlap & ~isEmptyObj);
cellImg = cellImg(~isOverlap & ~isEmptyObj);
seedObj = seedObj(~isOverlap & ~isEmptyObj);
crpCoor = crpCoor(~isOverlap' & ~isEmptyObj');
objPixList = objPixList(~isOverlap & ~isEmptyObj);
% - Update objInfo
objInfo.NumObjects = sum(~isOverlap & ~isEmptyObj);
objInfo.PixelIdxList = objPixList;
objInfo = updateObjInfo(objInfo);

%% Fill up the label masks
[labcellmask, labseedmask, ~] = fillLabelMask(objInfo,cellObj,seedObj,crpCoor);

end

%% Misc. functions
function dispProgress(recordT, totalW)
persistent TotalSeedNum curseed TotalTime disptxt
if nargin == 2 % Initialization
    TotalSeedNum = totalW;
    TotalTime = 0;
    curseed = 0;
    disptxt = sprintf('Cell %04d/%04d, Average time spent: %.2f sec',curseed,TotalSeedNum,TotalTime); fprintf(disptxt);
else
    curseed = curseed+1;
    TotalTime = recordT;
    if rand < 0.1 || (curseed == TotalSeedNum)
        fprintf(repmat('\b',1,length(disptxt)));
        disptxt = sprintf('Cell %04d/%04d, Average time spent: %.2f sec',curseed,TotalSeedNum,TotalTime/curseed); fprintf(disptxt);
    end
end
end