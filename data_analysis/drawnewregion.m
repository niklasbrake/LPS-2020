function drawnewregion(filepath,fig)

if(nargin<2)
	fig = plotLineMask(filepath);
end

warning('off','MATLAB:Figure:FigureSavedToMATFile');

c=clock;
timestamp = sprintf('%2d.%02d.%02d_%02dh%02d',c(1:end-1));
filename = ['DrawnRegion_' timestamp '.mat'];
ax = flip(fig.Children);
save(filename,'fig');

chTypes = arrayfun(@(x) x.Type,fig.Children(1).Children,'UniformOutput',false);
nRegions = sum(cellfun(@(x)strcmp('images.roi.polygon',x),chTypes));
iRegs = flip(find(cellfun(@(x)strcmp('images.roi.polygon',x),chTypes)));
for l = 1:nRegions
	for j = 1:4
		ch = fig.Children(j).Children(iRegs(l));
		eval(['p' int2str(j) ' = ch;']);
	end
	eval(['region' int2str(l) '= [p1,p2,p3,p4];']);
end

if(nRegions==0)
	fig.Name = [fig.Name ' | region1'];
else
	fig.Name = [fig.Name ', ' int2str(nRegions+1)];
end

clr = lines(nRegions+1);
clr = clr(end,:);
for j = 1:4
	disp(['Draw ROI for slice ' int2str(j) '.']);
	axes(ax(j));
	p=drawpolygon('LineWidth',1,'Color',clr,'Label',['region' int2str(nRegions+1)]);
	eval(['region' int2str(nRegions+1) '(j)=p;']);
end

for j = 1:nRegions+1
	save(filename,['region' int2str(j)],'-append')
	temp = getSelectedROIs(filepath,eval(['region' int2str(j)]),j);
	eval(['cells_region' int2str(j) '=temp;']);
	save(filename,['cells_region' int2str(j)],'-append');
end

save(filename,'fig','-append');

disp(['Saved in ' filename]);