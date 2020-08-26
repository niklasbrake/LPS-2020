function plotROIdetection(folder,sliceNo)
% plotROIdetection plots the ROIs detected in Slice image.
% 	plotROIdetection(folder,sliceNo) takes 2 inputs arguments,
% 		folder, which is the path to the experiment files, e.g.
% 		E:\Documents\Work\RuthazerLab\Data\Raw data 2020-01-14\Beth run1
% 		and sliceNo is the slice number you wish to plot, e.g. 3.


	[~,Fish] = fileparts(folder);
	I = imread(fullfile(folder,['Slice' int2str(sliceNo) '.tif']));
	% load(fullfile(folder,[Fish '.mat']));
	load(fullfile(folder,[Fish ' RoiMask.mat']));

	fig = figure('color','w');
	fig.Position(3) = fig.Position(4);

	axes('Position',[0.05,0.05,0.9,0.9]);
	imagesc(log(double(I))); % Log of intensity taken to better see cells
	colormap('gray'); % Colormap. Google MATLAB colormaps to see other options
	axis square;
	axis xy;
	hold on;

	RoiPoints = RoiMask(sliceNo).points;
	for i = 1:size(RoiPoints,1)
		k = convhull(RoiPoints{i,1},RoiPoints{i,2});
		h = plot(RoiPoints{i,1}(k),RoiPoints{i,2}(k), ...
			'color',[0,0,1], ... % Color RGB values
			'linewidth',0.1); % LineWidth
		h.Color(4) = 0.3; % Alpha value (opaqueness)
	end

	axis off;
