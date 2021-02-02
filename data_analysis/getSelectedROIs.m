function selectedROIs = getSelectedROIs(filepath,region,regionNo)

warning('off','MATLAB:xlswrite:AddSheet');

cond = -1;

%  Keep only that are significantly responding
[~,name] = fileparts(filepath);
load(fullfile(filepath,['Analysed ' name '.mat']));

if(cond==-1)
	X = AnalysedData.Responses(:,1:11);
else
	X = AnalysedData.Responses(:,1:11);
end
score = zeros(length(X),3);
for i = 1:length(X)
	score(i,1) = corr(linspace(0,1,11)',X(i,:)');
	score(i,2:3) = regress(X(i,:)',[linspace(0,1,11)',ones(11,1)]);
end

keep = find(and(score(:,1)>0.5,cond*score(:,2)>0));

in = [];
for j = 1:4
	co = AnalysedData.RoiCoords; 
	idcsTemp = find(co(3,:)==j);
	co = co(:,idcsTemp);
	in = [in,idcsTemp(find(inpolygon(co(1,:),co(2,:),region(j).Position(:,1),region(j).Position(:,2))))];
end



selectedROIs.idcs = in(:);
selectedROIs.coords = AnalysedData.RoiCoords(:,in)';
selectedROIs.R = score(in,1);
selectedROIs.slope = score(in,2);
selectedROIs.intercept = -score(in,3)./score(in,2);
selectedROIs.response = X(in,:);
selectedROIs.zscores = AnalysedData.ZScore(in,:);


filename = [name ' Region' int2str(regionNo) '.xlsx'];
T1 = table(selectedROIs.idcs,selectedROIs.R,selectedROIs.slope, ...
	selectedROIs.intercept,'VariableNames',{'Cell_ID','R_2','slope','x_int'});
writetable(T1,filename,'Sheet','All Cells','Range','B2')
T2 = table(selectedROIs.idcs,selectedROIs.response,'VariableNames',{'Cell_ID','Responses'});
writetable(T2,filename,'Sheet','All Responses','Range','B2')
T3 = table(selectedROIs.idcs,selectedROIs.zscores,'VariableNames',{'Cell_ID','Z_Scores'});
writetable(T3,filename,'Sheet','All Z-Scores','Range','B2')


in2 = find(and(max(selectedROIs.zscores,[],2)>2.5,selectedROIs.R>0.5));
T1 = table(selectedROIs.idcs(in2),selectedROIs.R(in2),selectedROIs.slope(in2), ...
	selectedROIs.intercept(in2),'VariableNames',{'Cell_ID','R_2','slope','x_int'});
writetable(T1,filename,'Sheet','Selected Cells','Range','B2')