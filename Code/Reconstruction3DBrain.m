%% This code is modified by Md. Kamrul Hasan
%Erasmus Scholar on Medical Imaging and Applications
% Link: https://fr.mathworks.com/videos/medical-image-processing-with-matlab-81890.html?elqsid=1537713560421&potential_use=Student
%%
% Copyright of this code is 2004-2010 The MathWorks, Inc.
% My contribuitions are editing some functions and make it compatiable for
% MATLAB-2017a. 
%%
clear all      %Delete all previous variables.
close all      %Close all the previous figures.
clc            %Erase command window
%% Read all the dicom images (MRI).
fileFolder = fullfile(pwd,'DATAPATH');
dirOutput = dir(fullfile(fileFolder,'*.dcm'));
fileNames = {dirOutput.name};
%% DICOM images investigation.
information = dicominfo(fullfile(fileFolder,fileNames{1}));
% extract voxel size 
voxel_size = [information.PixelSpacing; information.SliceThickness]';
%% Read slice images; populate XYZ matrix
hWaitBar = waitbar(0,'DICOM Images loading. Please, be patient...........');
for i=length(fileNames):-1:1
  Image_file_name = fullfile(fileFolder,fileNames{i});
  DataImage(:,:,i) =uint16(dicomread(Image_file_name));
  waitbar((length(fileNames)-i)/length(fileNames))
end
delete(hWaitBar)
%% Plot all the original MRI in montage.
monta=reshape(DataImage,[information.Width,information.Height,1,length(fileNames)]);
montage(monta);
set(gca,'clim',[0,100]);
title('Original MRI in montage')
%% Take any random image to plot using imtool to investigate.
image=DataImage(:,:,33);
maxvalue=double(max(max(image)));
imtool(image,[0,maxvalue]);
%% Thresholding and row subtraction. 
SegmentedBrainMRI=DataImage;
Threshold_lowerBound=40;
Threshold_upperBound=100;
SegmentedBrainMRI(SegmentedBrainMRI>=Threshold_upperBound)=0;
SegmentedBrainMRI(SegmentedBrainMRI<=Threshold_lowerBound)=0;
SegmentedBrainMRI(175:end,:,:)=0; %After 175, there is no brain portion in the given MRI.
black_white=logical(SegmentedBrainMRI);
%% Ploting after thresholding and binarization.
monta=reshape(black_white,[information.Width,information.Height,1,length(fileNames)]);
figure()
montage(monta);
% set(gca,'clim',[0,200]);
title('Montage after thresholding and Binarization')
figure()
imshow(black_white(:,:,30))
title('Single image after thresholding and Binarization')
%%
structeringElement=ones([7 7 3]);
black_white=imopen(black_white,structeringElement);
figure()
imshow(black_white(:,:,30))
%% Now Determine the connected region using region properties.
labelMatrix = bwlabeln(black_white); 
RegionProp=regionprops(labelMatrix,'Area','Centroid');
maxThreshold = [RegionProp.Area];
biggestArea = find(maxThreshold==max(maxThreshold));
SegmentedBrainMRI(labelMatrix~=biggestArea)=0;
figure()
imshow(SegmentedBrainMRI(:,:,30),[0,maxvalue])
title('Image after Region Properties')
%% Now need to partition white and gray materials of the brain. 
level=thresh_tool(uint16(SegmentedBrainMRI(:,:,30)),'gray');
mriPartition=uint8(zeros(size(SegmentedBrainMRI)));
mriPartition(SegmentedBrainMRI>0 & SegmentedBrainMRI<level)=2;
mriPartition(SegmentedBrainMRI>=level)=3;
figure()
imshow(mriPartition(:,:,30),[0,maxvalue]);
title('White and gray meterial partitioned Image')
%% Close all the figure before 3D visualization of the Brain.
close all
imtool close all
%% 3D rendering for the Visualization
tmp=text(128,200,'Rendering 3D: Please wait','horizontalalignment','center');
Ds=imresize(mriPartition,1/2,'nearest');
Ds=flip(Ds,1);
Ds=flip(Ds,2);
Ds=permute(Ds,[3,2,1]);
voxel_size2=voxel_size([1 2 3]).*[4 1 4];
white=isosurface(Ds,2.5);
gray=isosurface(Ds,1.5);
patch(white,'FaceColor','r','EdgeColor','none');
patch(gray,'FaceColor','y','EdgeColor','none','FaceAlpha',0.5);
view(45,45); daspect(1./voxel_size2); 
axis off;
camlight(-100,-100);  lighting phong;
delete(tmp);
%%