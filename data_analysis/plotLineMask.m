function [fig,CD,sliceDist] = plotLineMask(filepath,cond)

warning('off','stats:gmdistribution:FailedToConverge')

[~,name] = fileparts(filepath);
load(fullfile(filepath,['Analysed ' name '.mat']));
load(fullfile(filepath,[name ' RoiMask.mat']));

if(nargin<3)
	if(strfind(filepath,'Spatial')>0)
		cond = -1;
	elseif(strfind(filepath,'Brightness')>0)
		cond = 1;
	else
		return;
	end
end

if(cond==1)
	X = AnalysedData.Responses(:,1:11);
	S = linspace(0,1,11);
else
	X = AnalysedData.Responses(:,2:12);
	S = unique(StimulusData.Raw(:,3));
	% S = log(S(2:12))';
	S = 1:size(X,2);
end
score = zeros(length(X),3);
for i = 1:length(X)
	score(i,1) = corr(S',X(i,:)');
	score(i,2:3) = regress(X(i,:)',[S',ones(11,1)]);
end

Z = max(AnalysedData.ZScore,[],2);
% [zs,I] = sort(Z,'descend');
% k1 = I(1:200);
% k2 = score(k1,1);
% keep = k1(cond*k2>0.5);
keep = find(and(cond*score(:,1)>0.5,Z>2.5));


sliceDist = histcounts(AnalysedData.RoiCoords(3,keep),4);

co = AnalysedData.RoiCoords(:,keep);

fig = figure('color','w','ToolBar','none','name',[name ' | Selected ROIs (R2>0.5 and b>0)'],'NumberTitle','off');
scSize = get(0,'ScreenSize');
fig.Position(4) = 0.85*scSize(4);
fig.Position(3) = 0.85*scSize(4)/711*561;
fig.Position(2) = 0;

runT = 0;
for j = 1:length(RoiMask)
	RoiPoints = RoiMask(j).points;
	% subplot(2,2,j);
	[x,y] = ind2sub([2,2],j);
	ax(j) = axes('Position',[0.5*(x-1),0.5*(2-y),0.5,0.5]);
	for i = 1:length(RoiPoints)
		runT = runT+1;
		k = convhull(RoiPoints{i,1},RoiPoints{i,2});
		h = fill(RoiPoints{i,1}(k),RoiPoints{i,2}(k),'b', ...
			'linewidth',0.1); % LineWidth
		h.FaceAlpha = double(any(runT==keep));
		hold on;
	end
	xlim([1-25,512+25]);
	ylim([1-100,512+100]);
	text(1,-99,['Slice ' int2str(j)],'HorizontalAlignment', ...
			'left','VerticalAlignment','top');
	axis ij;
	set(gca,'DataAspectRatio',[1,1,1]);
	xticks([]);
	yticks([]);
	drawnow;

	
	z = find(co(3,:)==j);
	d = zeros(length(z),length(z));
	for i = 1:length(z)
		d(i,:) = vecnorm(co(1:2,z(i))-co(1:2,z),2);
	end
	CD(j) = sum(d(:))/((length(z)-1)*length(z));
	text(100,-99,sprintf('%04.1f',CD(j)),'HorizontalAlignment', ...
					'left','VerticalAlignment','top');


		% for k = 1:4
		% 	try
		% 		gm = fitgmdist(co(1:2,z)',k);
		% 		BIC(k) = gm.BIC;
		% 	catch
		% 		BIC(k)=Inf;
		% 	end
		% end
		% try
		% 	[~,k] = min(BIC);
		% 	gm = fitgmdist(co(1:2,z)',k);

		% 	[X,Y] = meshgrid(1:512,1:512);
		% 	Z = reshape(pdf(gm,[X(:),Y(:)]),512,512);
		% 	contour(X,Y,Z);

		% 	text(100,-99,[num2str(max(Z(:)))],'HorizontalAlignment', ...
		% 			'left','VerticalAlignment','top');

		% 	CD(j) = max(Z(:));
		% catch
		% 	CD(j) = 0;
		% end
end