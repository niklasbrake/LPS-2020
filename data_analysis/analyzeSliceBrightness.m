function [lineParams,pvalues] = analyzeSliceBrightness(folder1,folder2)


folder{1} = folder1;
folder{2} = folder2;


lineParams = cell(2,4);
noise = cell(2,4);
XsaveC = [];
XsaveL = [];
for k = 1:length(folder)

	F = dir(folder{k});
	F = F(3:end); F = F([F(:).isdir]);

	for i = 1:length(F)
		filepath = fullfile(folder{k},F(i).name);
		[~,name] = fileparts(filepath);
		load(fullfile(filepath,['Analysed ' name '.mat']));

		for sln = 1:4
			Z = max(AnalysedData.ZScore,[],2);
			[zs,I] = sort(Z,'descend');
			slice4 = find(AnalysedData.RoiCoords(3,:)==sln);
			keep = intersect(slice4,I(1:200));

			% keep = intersect(slice4,find(Z>2.5));

			X = AnalysedData.Responses(keep,:);
			S = (0:10)/10;
			score = [];
			for j = 1:length(keep)
				score(j,1) = corr(S',X(j,:)');
				score(j,2:3) = regress(X(j,:)',[S',ones(size(S'))]);
				score(j,3) = -score(j,3)/score(j,2);
			end
			keep2 = find(score(:,1)>0.5);
			lineParams{k,sln} = [lineParams{k,sln};score(keep2,:)];
			noise{k,sln} = [noise{k,sln};X(keep2,1)];

			X = X(keep2,:);

			if(k==1)
				XsaveC = vertcat(XsaveC,X);
			else
				XsaveL = vertcat(XsaveL,X);
			end
		end
	end
end

disp('---------Comparing------------')
disp(folder1);
disp(folder2);
disp('------------------------------')

fprintf('\n');
figure('color','w')
for i = 1:size(XsaveC,2)
	boxplotNB(2*i-0.75/2,XsaveC(:,i),'b',6);
end
for i = 1:size(XsaveL,2)
	boxplotNB(2*i+0.75/2,XsaveL(:,i),'r',6);
	p = ranksum(XsaveC(:,i),XsaveL(:,i));
	if(i==1)
		fprintf('Negative Control: p = %0.3f.',p);
	else
		fprintf('Brightness Level %d: p = %0.3f.',i-1,p);
	end
	if(p<0.05/11)
		fprintf('*');
	end
	fprintf('\n');
end
xticks(2:2:22)
xticklabels(0:10)
box off
set(gca,'TickDir','out')
set(gca,'LineWidth',1);	
xlabel('Brightness Level');
ylabel('Response');

h(1) = plot(nan,nan,'.b','MarkerSize',15);
h(2) = plot(nan,nan,'.r','MarkerSize',15);
L = legend(h,{'CTL','LPS'});
L.ItemTokenSize = [10,15];

fprintf('\n');
disp('-----------Slope--------------')
figure('color','w')
subplot(2,1,1);
	for i = 1:4
		for k = 1:2
			boxplotNB(2*i+0.75*(k-1.5),lineParams{k,i}(:,2),[k==2,0,k==1],6);
		end
		p = ranksum(lineParams{1,i}(:,2),lineParams{2,i}(:,2));
		fprintf('Slice %d: p = %0.3f.',i,p);
		if(p<0.05/4)
			fprintf('*');
		end
		fprintf('\n');
		pvalues(1,i) = p;
	end
xticks(2:2:8);
xticklabels(1:4);
xlabel('Slice');
ylabel('Slope')
box off; set(gca,'TickDir','out'); set(gca,'LineWidth',1);
fprintf('\n');
disp('-----------X-Int--------------')
subplot(2,1,2);
	for i = 1:4
		for k = 1:2
			boxplotNB(2*i+0.75*(k-1.5),lineParams{k,i}(:,3),[k==2,0,k==1],6);
		end
		[~,p] = ttest2(lineParams{1,i}(:,3),lineParams{2,i}(:,3));
		fprintf('Slice %d: p = %0.3f.',i,p);
		if(p<0.05/4)
			fprintf('*');
		end
		fprintf('\n');
		pvalues(2,i) = p;
	end
xticks(2:2:8);
xticklabels(1:4);
xlabel('Slice');
ylabel('X-Int')
box off; set(gca,'TickDir','out'); set(gca,'LineWidth',1);