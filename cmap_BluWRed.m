function cm_data=cmap_BluWRed(m)
% === Description
% Blue gradient colormap
% Default 256 levels
cm = [103,0,31;
    178,24,43;
    214,96,77;
    244,165,130;
    253,219,199;
    247,247,247;
    209,229,240;
    146,197,222;
    67,147,195;
    33,102,172;
    5,48,97]/255;
cm = flipud(cm);

anchorpt = ([1:size(cm,1)]-1)/(size(cm,1)-1)*255;
cm = interp1(anchorpt,cm,0:255);
if nargin < 1
    cm_data = cm;
else
    hsv=rgb2hsv(cm);
    cm_data=interp1(linspace(0,1,size(cm,1)),hsv,linspace(0,1,m));
    cm_data=hsv2rgb(cm_data);
  
end
end