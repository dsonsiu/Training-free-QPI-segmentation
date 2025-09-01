addpath('PhaseCut\');
%% Load data to be segmented
InputImg = imread('Data\\Example3.tiff');
QPIrange = [0 2.965];
bitDepth = 16;
pixsz = 0.4145;
% ----- Convert the image back into array with QPI scale
QPI = single(InputImg)/(2^bitDepth-1)*range(QPIrange)+min(QPIrange);

%% Phase cut
tic
[cellImg,objInfo,labcellmask,labseedmask] = PhaseCut(QPI,pixsz);
toc

%% Export data
% ----- Save variables
save("Example3.mat","cellImg","objInfo","labcellmask","labseedmask",'-v7.3');

%% Export results in images
QPIdispRange = [0 1]; % rad
% - Save combined mask
combineMsk = (labcellmask > 0) + (labseedmask > 0) ;
imwrite( ind2rgb(uint8(mat2gray(combineMsk)*size(bone,1)),bone) , 'CombinedMask_Eg3.png');
% - Save overlayed cell boundary
cellEdge = imdilate(imgradient(labcellmask)>0,strel('disk',3));
imgOvl = overlayEdge(QPI, cmap_BluWRed, QPIdispRange, cellEdge, [1,0,0]);
imwrite( imgOvl ,'OverlayedCellEdge_Eg3.png');
% - Save Labeled mask
imwrite( ind2rgb(uint8(mat2gray(labcellmask)*(size(nebula,1)+1)),[0,0,0;nebula]),'LabelMask_Eg3.png');

