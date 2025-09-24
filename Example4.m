addpath('PhaseCut\');
%% Load data to be segmented
InputImg = imread('Data\\Example4.png');
QPIrange = [0 .35];
bitDepth = 8;
pixsz = 0.1207;
% ----- Convert the image back into array with QPI scale
QPI = imgaussfilt(single(InputImg)/(2^bitDepth-1)*range(QPIrange)+min(QPIrange),3);

%% Phase cut
tic
[cellImg,objInfo,labcellmask,labseedmask] = PhaseCut(QPI,pixsz);
toc

%% Export data
% ----- Save variables
save("Example3.mat","cellImg","objInfo","labcellmask","labseedmask",'-v7.3');

%% Export results in images
QPIdispRange = [0 .35]; % rad
% - Save combined mask
combineMsk = (labcellmask > 0) + (labseedmask > 0) ;
imwrite( ind2rgb(uint8(mat2gray(combineMsk)*size(bone,1)),bone) , 'CombinedMask_Eg4.png');
% - Save overlayed cell boundary
cellEdge = imdilate(imgradient(labcellmask)>0,strel('disk',3));
imgOvl = overlayEdge(QPI, cmap_BluWRed, QPIdispRange, cellEdge, [1,0,0]);
imwrite( imgOvl ,'OverlayedCellEdge_Eg4.png');
% - Save Labeled mask
imwrite( ind2rgb(uint8(mat2gray(labcellmask)*(size(nebula,1)+1)),[0,0,0;nebula]),'LabelMask_Eg4.png');

