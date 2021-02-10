% function [lineParams,pvalues] = analyzeSliceSpatial(folder1,folder2)

folder1 = 'E:\Documents\Work\RuthazerLab\Data\Analysed Spatial frequency\CTL';
folder2 = 'E:\Documents\Work\RuthazerLab\Data\Analysed Spatial frequency\LPS';

folder{1} = folder1;
folder{2} = folder2;

x = [0.0010,0.0030,0.0050,0.0060, ...
0.0100,0.0130,0.0200,0.0250, ...
0.0310,0.0400,0.0500,0.0630, ...
0.1000,0.1250,0.2000]';
x = log(x);

lineParams = cell(2,4);
M = cell(2,4);
noise = cell(2,4);
XsaveC = []; XsaveC2 = {[],[],[],[]};
XsaveL = []; XsaveL2 = {[],[],[],[]};
for k = 1:length(folder)

	F = dir(folder{k});
	F = F(3:end); F = F([F(:).isdir]);

	for i = 1:length(F)
		filepath = fullfile(folder{k},F(i).name);
		[~,name] = fileparts(filepath);
		load(fullfile(filepath,['Analysed ' name '.mat']));

		for sln = 1:4
			Z = max(AnalysedData.ZScore,[],2);
			Z = AnalysedData.ZScore(:,1);
			[zs,I] = sort(Z,'descend');
			slice4 = find(AnalysedData.RoiCoords(3,:)==sln);
			% keep = intersect(slice4,I(1:200));
			keep = intersect(slice4,I(1:200));

			X = AnalysedData.Responses(keep,2:end-1);
			S = 2:14;
			R = [];
			for j = 1:length(keep)
				R(j) = corr(S',X(j,2:14)','type','spearman');
			end
			keep2 = find(R<-0.5);
			X = AnalysedData.Responses(keep(keep2),:);

			if(k==1)
				XsaveC = vertcat(XsaveC,X);
				NC(i,sln) = length(keep2);
				XsaveC2{sln} = vertcat(XsaveC2{sln},mean(X,1));
				for l = 1:size(X,1)
					[coeffC{i,sln}(l,:),RC{i,sln}(l)] = FitThreshold(x,X(l,2:16));
				end
			else
				XsaveL = vertcat(XsaveL,X);
				NL(i,sln) = length(keep2);
				XsaveL2{sln} = vertcat(XsaveL2{sln},mean(X,1));
				for l = 1:size(X,1)
					[coeffL{i,sln}(l,:),RL{i,sln}(l)] = FitThreshold(x,X(l,2:16));
				end
			end
		end
	end
end


figure('color','w');
CAll = []; LAll = [];
LRAll = []; CRAll = [];
for i = 1:4
	L = vertcat(coeffL{:,i});
	C = vertcat(coeffC{:,i});

	RLL = horzcat(RL{:,i})';
	RCC = horzcat(RC{:,i})';
	for k = 1:3
		id1 = find(isoutlier(C(:,k))); C(id1,:) = [];
		RCC(id1,:) = [];
		id2 = find(isoutlier(L(:,k))); L(id2,:) = [];
		RLL(id2,:) = [];
		subplot(3,4,i+4*(k-1));
		boxplotNB(1,C(:,k),'b',6);
		boxplotNB(2,L(:,k),'r',6);
		xlim([0.5,2.5]);
		xticks(1:2); xticklabels({'CTL','LPS'});
		p = ranksum(C(:,k),L(:,k));
		if(p<0.01)
			title(sprintf('p = %.2d',p));
		elseif(p<0.1)
			title(sprintf('p = %.3f',p));
		else
			title(sprintf('p = %.2f',p));
		end
		switch k
			case 1, ylim([-0.3,0.05]);
			case 2, ylim([-0.1,0.2]);
			case 3, ylim([-6,0]);
		end
		box off;
		set(gca,'TickDir','out');
		set(gca,'LineWidth',1);
	end
	xlabel(sprintf('Slice %d',i));
	LAll = [LAll;L]; LRAll = [LRAll;RLL];
	CAll = [CAll;C]; CRAll = [CRAll;RCC];
end
subplot(3,4,1); ylabel('Slope');
subplot(3,4,5); ylabel('Noise Level');
subplot(3,4,9); ylabel('Noise Threshold');


figure('color','w');
for k = 1:3
	subplot(3,1,k);
	boxplotNB(1,CAll(:,k),'b',6);
	boxplotNB(2,LAll(:,k),'r',6);
	xlim([0.5,2.5]);
	xticks(1:2); xticklabels({'CTL','LPS'});
	p = ranksum(CAll(:,k),LAll(:,k));
	if(p<0.01)
		title(sprintf('p = %.2d',p));
	elseif(p<0.1)
		title(sprintf('p = %.3f',p));
	else
		title(sprintf('p = %.2f',p));
	end
	switch k
		case 1, ylim([-0.3,0.05]);
		case 2, ylim([-0.1,0.2]);
		case 3, ylim([-6,0]);
	end
	box off;
	set(gca,'TickDir','out');
	set(gca,'LineWidth',1);
end
subplot(3,1,1); ylabel('Slope');
subplot(3,1,2); ylabel('Noise Level');
subplot(3,1,3); ylabel('Noise Threshold');


disp('---------Comparing------------')
disp(folder1);
disp(folder2);
disp('------------------------------')

S = log(unique(StimulusData.Raw(:,3)));

fprintf('\n');
figure('color','w')
for i = 2:16
	boxplotNB(10*S(i)-0.75/2,XsaveC(:,i),'b',6);
end
for i = 2:16
	boxplotNB(10*S(i)+0.75/2,XsaveL(:,i),'r',6);
	p = ranksum(XsaveC(:,i),XsaveL(:,i));
	fprintf('%.0f pixels/cycle: p = %0.3f.',exp(-S(i)),p);
	if(p<0.05/11)
		fprintf('*');
	end
	fprintf('\n');
end
xlim([-74,-13])
xticks(-70:10:-10)
xticklabels(-7:-1)
box off
set(gca,'TickDir','out')
set(gca,'LineWidth',1);	
xlabel('Spatial Frequency (log cycles/pixel)');
ylabel('Response');

t = linspace(-7.4,-1.3,1e3);
coeff = median(CAll);
h(3)=plot(10*t,(t-coeff(3)).*(t<=coeff(3))*coeff(1)+coeff(2),'b','LineWidth',1);
coeff = median(LAll);
h(4)=plot(10*t,(t-coeff(3)).*(t<=coeff(3))*coeff(1)+coeff(2),'r','LineWidth',1);

h(1) = plot(nan,nan,'.b','MarkerSize',15);
h(2) = plot(nan,nan,'.r','MarkerSize',15);
L = legend(h,{'CTL','LPS'});
L.ItemTokenSize = [10,15];