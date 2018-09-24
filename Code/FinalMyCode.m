%% This code is modified by Md. Kamrul Hasan
%Erasmus Scholar on Medical Imaging and Applications
% Link: https://fr.mathworks.com/videos/medical-image-processing-with-matlab-81890.html?elqsid=1537713560421&potential_use=Student
%%
% Copyright of this code is 2004-2010 The MathWorks, Inc.
% My contribuitions are editing some functions and make it compatiable for
% MATLAB-2017a. 
%%
clear all      %no variables
close all   % no figures
clc         % empty command window
%% Read all the Images from the folder that contains dicom images (MRI).
fileFolder = fullfile(pwd,'DATAPATH');
dirOutput = dir(fullfile(fileFolder,'*.dcm'));
fileNames = {dirOutput.name};
%% DICOM images investigation.
information = dicominfo(fullfile(fileFolder,fileNames{1}));
% extract size info from metadata
voxel_size = [information.PixelSpacing; information.SliceThickness]';
%% Read slice images; populate XYZ matrix
hWaitBar = waitbar(0,'Reading all DICOM files. Please, Patient...........');
for i=length(fileNames):-1:1
  Image_file_name = fullfile(fileFolder,fileNames{i});
  DataImage(:,:,i) =uint16(dicomread(Image_file_name));
  waitbar((length(fileNames)-i)/length(fileNames))
end
delete(hWaitBar)
% monta=reshape(DataImage,[information.Width,information.Height,1,length(fileNames)]);
% montage(monta);
% set(gca,'clim',[0,100]);
%% Take the middle stack 
image=DataImage(:,:,30);
maxvalue=double(max(max(image)));
imtool(image,[0,maxvalue]);
imtool close all
mriAdjust=DataImage;
lowerBound=40;
upperBound=100;
mriAdjust(mriAdjust>=upperBound)=0;
mriAdjust(mriAdjust<=lowerBound)=0;
mriAdjust(175:end,:,:)=0;
black_white=logical(mriAdjust);
monta=reshape(black_white,[information.Width,information.Height,1,length(fileNames)]);
montage(monta);
% set(gca,'clim',[0,200]);
figure()
imshow(black_white(:,:,30))
structeringElement=ones([7 7 3]);
black_white=imopen(black_white,structeringElement);
figure()
imshow(black_white(:,:,30))
%% Now Determine the connected region using region properties.
labelMatrix = bwlabeln(black_white); 
RegionProp=regionprops(labelMatrix,'Area','Centroid');
% LL=labelMatrix(:,:,30)+1;
% cmap=hsv(length(RegionProp));
maxThreshold = [RegionProp.Area];
biggestArea = find(maxThreshold==max(maxThreshold));
mriAdjust(labelMatrix~=biggestArea)=0;
figure()
imshow(mriAdjust(:,:,30),[0,maxvalue])
close all
level=thresh_tool(uint16(mriAdjust(:,:,30)),'gray');
mriPartition=uint8(zeros(size(mriAdjust)));
mriPartition(mriAdjust>0 & mriAdjust<level)=2;
mriPartition(mriAdjust>=level)=3;
figure()
imshow(mriPartition(:,:,30),[0 0 0; 0 0 0; 0.25 0.25 0.25])
% middle=30;
% cm=brighten(jet(60),-0.5);
% figure('colormap',cm)
% contourslice(mriAdjust,[],[],middle)
% axis ij tight
% daspect([1,1,1])
close all
%% 3D rendering for the Visualization
tmp=text(128,200,'Rendering 3D: Please wait','horizontalalignment','center');
drawnow;
shg;
Ds=imresize(mriPartition,0.5,'nearest');
Ds=flipdim(Ds,1);
Ds=flipdim(Ds,2);
Ds=permute(Ds,[3,2,1]);
voxel_size2=voxel_size([1 2 3]).*[4 1 4];
white=isosurface(Ds,2.5);
gray=isosurface(Ds,1.5);
% h=figure('visible','off','windowstyle','normal');
patch(white,'FaceColor','r','EdgeColor','none');
patch(gray,'FaceColor','y','EdgeColor','none','FaceAlpha',0.5);
view(45,45); daspect(1./voxel_size2); 
axis off;
camlight(-100,-100);  lighting phong;
delete(tmp);
