F = dir;
matIdcs = cellfun(@(x) ~isempty(strfind(x,'.mat')),{F(:).name});
F = F(matIdcs);

ZThresh = 4;

ctlFish = {'Beth','Clara','Edna','Franny','Helen','Jennifer','Kate','Lorraine','Rebecca','Sophie','Violet'};
ctlResponse = []; ctlN = []; ctlV = []; ctlData = []; ctlG = [];
lpsResponse = []; lpsN = []; lpsV = []; lpsData = []; lpsG = [];
for i = 1:length(F)
	isCtl = sum(cellfun(@(x) ~isempty(strfind(F(i).name,x)),ctlFish))==1;
	isLPS = sum(cellfun(@(x) isempty(strfind(F(i).name,x)),ctlFish))==1;
	data = load(F(i).name);
	idcsResponders = find(max(data.AnalysedData.ZScore,[],2)>ZThresh);
	avgResponse = mean(data.AnalysedData.Responses(idcsResponders,:));
	for j = 1:8
		specResponders = find(data.AnalysedData.ZScore(:,j)>3);
		temp = mean(data.AnalysedData.AllResponses(specResponders,j+1,:,7:13),4);
		stimVar(j) = mean(std(temp,[],3));
	end

	if(isCtl)
		ctlResponse(end+1,:) = avgResponse;
		ctlN(end+1,:) = length(idcsResponders);
		ctlV(end+1,:) = stimVar;
		ctlData = [ctlData;data.AnalysedData.Responses];
		m = size(ctlN,1);
		N = size(data.AnalysedData.Responses,1);
		ctlG = [ctlG;m*ones(N,1)];
	else
		lpsResponse(end+1,:) = avgResponse;
		lpsN(end+1,:) = length(idcsResponders);
		lpsV(end+1,:) = stimVar;
		lpsData = [lpsData;data.AnalysedData.Responses];
		m = size(lpsN,1);
		N = size(data.AnalysedData.Responses,1);
		lpsG = [lpsG;m*ones(N,1)];
	end
end






errorbar(mean(ctlV),stderror(ctlV),'LineWidth',2,'Color','b'); hold on;
errorbar(mean(lpsV),stderror(lpsV),'LineWidth',2,'Color','r')


m = 15;
ctlHgram = zeros(ceil(512/m),ceil(512/m));
lpsHgram = zeros(ceil(512/m),ceil(512/m));
for f = 1:length(F)
	isCtl = sum(cellfun(@(x) ~isempty(strfind(F(f).name,x)),ctlFish))==1;
	isLPS = sum(cellfun(@(x) isempty(strfind(F(f).name,x)),ctlFish))==1;
	
	data = load(F(f).name);
	CDs = data.AnalysedData.RoiCoords;
	RPs = data.AnalysedData.Responses(:,9);
	tempGram = zeros(ceil(512/m),ceil(512/m));
	for i = 1:size(RPs,1)
		x = ceil(data.AnalysedData.RoiCoords(1,i)/m);
		y = ceil(data.AnalysedData.RoiCoords(2,i)/m);
		tempGram(x,y) = tempGram(x,y) + RPs(i);
	end

	if(isCtl)
		ctlHgram = ctlHgram + tempGram;
	else
		lpsHgram = lpsHgram + tempGram;
	end
end

figure;
subplot(1,2,1);
imagesc(ctlHgram)
set(gca,'CLim',[0,0.2])
subplot(1,2,2);
imagesc(lpsHgram)
set(gca,'CLim',[0,0.2])