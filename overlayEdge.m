function img_output = overlayEdge(img, imgCMap, imgCAx, edgeMap, edgeRGB)
imgRGB = ind2rgb(uint8(mat2gray(img,imgCAx)*size(imgCMap,1)),imgCMap);
img_output = labeloverlay(imgRGB,edgeMap,'Colormap',edgeRGB);
end