% Load data. These parameter values were estimated using the fit2Sig function
CTL = load('E:\Documents\Work\RuthazerLab\Data\Analysed Spatial Frequency\CTL\fits5.mat');
CTL2 = load('E:\Documents\Work\RuthazerLab\Data\2020 data\Spatial frequency\Uninjected untreated\fits5.mat');

LPS = load('E:\Documents\Work\RuthazerLab\Data\Analysed Spatial Frequency\LPS\fits5.mat');
LPS2 = load('E:\Documents\Work\RuthazerLab\Data\2020 data\Spatial frequency\Uninjected LPS treated\fits5.mat');

% Screen pixels to visual angle
pix2ang = 1/(22.5*sin(1*pi/180)/sin(89*pi/180));
xData = log(pix2ang*[0.0010;0.0030;0.0050;0.0060;0.0100; ...
0.0130;0.0200;0.0250;0.0310;0.0400; ...
0.0500;0.0630;0.1000;0.1250;0.2000])/log(10);

% Combine 2017 and 2020 data
CTL.X = [CTL.X;CTL2.X]; % Avg. DeltaF/F responses to each stimulus
CTL.R = [CTL.R;CTL2.R]; % Goodness of fit to sigmoidal curve
CTL.coeff = [CTL.coeff,CTL2.coeff]; % Estimated parameters
CTL.regionIdcs = [CTL.regionIdcs;sum(CTL.N)+CTL2.regionIdcs]; % Indices of cells in the neuropil (for reviewer comment)
CTL.N = [CTL.N,CTL2.N]; % Number of cells from each fish

LPS.X = [LPS.X;LPS2.X];
LPS.R = [LPS.R;LPS2.R];
LPS.coeff = [LPS.coeff,LPS2.coeff];
LPS.regionIdcs = [LPS.regionIdcs;sum(LPS.N)+LPS2.regionIdcs];
LPS.N = [LPS.N,LPS2.N];

% Set colours in plots to blue and red for untreated and treated, resp.
clr1 = [0,0,1];
clr2 = [1,0,0];

% Get fish numbers of each row of the concatenated matrix
G1 = [];
for i = 1:length(CTL.N);
	G1 = [G1;i*ones(CTL.N(i),1)];
end
G2 = [];
for i = 1:length(LPS.N);
	G2 = [G2;i*ones(LPS.N(i),1)];
end

% Remove CTL fish 7, because it is an outlier in terms of number of responding cells
idx = 7;
CTL.regionIdcs(and(CTL.regionIdcs>sum(CTL.N(1:idx-1)),CTL.regionIdcs<=sum(CTL.N(1:idx)))) = [];
CTL.X(G1==idx,:) = [];
CTL.coeff(:,G1==idx) = [];
CTL.R(G1==idx) = [];
CTL.N(idx) = [];
G1(G1==idx) = [];
G1(G1>idx) = G1(G1>idx)-1;


% Goodness of fit threshold of 0.85
rThresh = 0.85;

% Only take cells with R>0.85, and with SF50 within range of frequencies presented as stimuli
idcs1 = find(and(and(CTL.R'>rThresh,CTL.coeff(3,:)>xData(1)),CTL.coeff(3,:)<xData(end)));
idcs2 = find(and(and(LPS.R'>rThresh,LPS.coeff(3,:)>xData(1)),LPS.coeff(3,:)<xData(end)));

% Remove cells with a slope factor that is too steep (chosen to be 0.0075)
ft = @(a,x) a(1) + a(2)./(1+exp((x-a(3))/a(4)));
t = linspace(-7,1,1e3);
y1 = zeros(length(t),length(idcs1));
idc1N = ones(length(idcs1),1);
for i = 1:length(idcs1)
	if(CTL.coeff(4,idcs1(i))<7.5e-3)
		idc1N(i) = 0;
		continue;
	end
	y1(:,i) = ft([0,1,CTL.coeff(3:4,idcs1(i))'],t);
end
y2 = zeros(length(t),length(idcs2));
idc2N = ones(length(idcs2),1);
for i = 1:length(idcs2)
	if(LPS.coeff(4,idcs2(i))<7.5e-3)
		idc2N(i) = 0;
		continue;
	end
	y2(:,i) = ft([0,1,LPS.coeff(3:4,idcs2(i))'],t);
end
idcs1 = idcs1(find(idc1N));
idcs2 = idcs2(find(idc2N));

% Only take cells from the neuropil
% idcs1 = intersect(idcs1,CTL.regionIdcs);
% idcs2 = intersect(idcs2,LPS.regionIdcs);

% Plot top panel
fig = figure('color','w','units','centimeters');
fig.Position = [0,0,6,5];
ax = axes('Position',[0.175 0.17 0.78 0.52]);
	plot(t,y1,'color',[clr1,0.025],'LineWidth',0.2); 
	hold on;
	plot(t,y2,'color',[clr2,0.025],'LineWidth',0.2);
	plot(t,ft([0,1,0,0]'+[0,0,1,1]'.*median(CTL.coeff(:,idcs1),2),t),'LineWidth',1,'color',clr1); 
	plot(t,ft([0,1,0,0]'+[0,0,1,1]'.*median(LPS.coeff(:,idcs2),2),t),'LineWidth',1,'color',clr2);

	box off
	set(gca,'TickDir','out');
	set(gca,'LineWidth',1);
	xlabel(['Spatial Frequency (cycles/' char(176) ')']);
	ylabel('\DeltaF (Norm.)')
	set(gca,'FontSize',7);
	set(gca,'FontName','Arial Narrow');
	xlim([-3,0*log(0.5)/log(10)]);
	xticks([-3:0]);
	xticklabels([0.001,0.01,0.1,1]);
	xlabel(['Spatial Frequency (cycles/' char(176) ')']);
	set(gca,'xminortick','on');
	xax = get(gca,'xaxis');
	xax.MinorTickValues = log([0.001:0.001:0.01,0.02:0.01:0.1,0.2:0.1:1])/log(10);

% Plot bottom panel
ax = axes('Position',[0.175 0.74 0.78 0.25]);
	h=histogram(CTL.coeff(3,idcs1),'BinWidth',0.025,'Normalization','pdf');
	h.EdgeAlpha = 0;
	h.FaceColor = clr1;
	m = max(h.Values);
	hold on;
	h=histogram(LPS.coeff(3,idcs2),'BinWidth',0.025,'Normalization','pdf');
	h.EdgeAlpha = 0;
	h.FaceColor = clr2;
	m = max(m,max(h.Values));
	p=ranksum(CTL.coeff(3,idcs1),LPS.coeff(3,idcs2));

	M1 = median(CTL.coeff(3,idcs1));
	M2 = median(LPS.coeff(3,idcs2));
	scatter(M1,1.05*m,7,clr1,'filled','Marker','v');
	scatter(M2,1.05*m,7,clr2,'filled','Marker','v');

	if(p<0.05)
		text(max(M1,M2)+0.3,1.05*m,sprintf('** p = %.5f',p),'FontSize',7,'FontName', ...
			'Arial Narrow','VerticalAlignment','middle', ...
				'HorizontalAlignment','left');
	else
		text(max(M1,M2)+0.3,1.05*m,sprintf('p = %.5f',p),'FontSize',7,'FontName', ...
			'Arial Narrow','VerticalAlignment','middle', ...
				'HorizontalAlignment','left');
	end
	N(1,1) = length(unique(G1));
	N(1,2) = length(idcs1);
	N(2,1) = length(unique(G2));
	N(2,2) = length(idcs2);
	text(-3.5,m+0.1,sprintf('Untreated (n=%d, %d)',N(1,1),N(1,2)), ...
			'FontSize',7,'FontName','Arial Narrow','color',clr1);
	
	text(-3.5,m-0.5,sprintf('LPS treated (n=%d, %d)',N(2,1),N(2,2)), ...
		'FontSize',7,'FontName','Arial Narrow','color',clr2);
	xlim([-3,0*log(0.5)/log(10)]);
	ylim([0,1.2*m]);
	set(gca,'LineWidth',1)
	set(gcf,'color','w')
	box off;
	xticklabels({});
	set(get(gca,'yaxis'),'visible','off');
	set(gca,'TickDir','out');
	set(gca,'FontSize',7);
	set(gca,'FontName','Arial Narrow');
	xticks([-3:0]);


% set(fig,'PaperPositionMode','Auto','PaperUnits', ...
% 	'centimeters','PaperSize',[fig.Position(3),fig.Position(4)], ...
% 	'Renderer','Painters');
% print('E:\Documents\Work\RuthazerLab\Manuscript Revision\Figures\Final Figures\summary.pdf','-dpdf');

% Get number of responding cells from each fish
N1 = []; N2 = [];
for i = 1:length(CTL.N)
	N1(i) = sum(G1(idcs1)==i);
end
for i = 1:length(LPS.N)
	N2(i) = sum(G2(idcs2)==i);
end

% Plot number of cells from each fish.
fig = figure('color','w','units','centimeters');
fig.Position = [0,0,6,5];
	boxplotNB(1,N1,'b',12);
	boxplotNB(2,N2,'r',12);

	 [~,p] = ttest2(N1,N2);
	xticks([1,2])
	xticklabels({'CTL','LPS'})
	box off
	set(gca,'TickDir','out')
	set(gca,'LineWidth',1)
	xlim([0.5,2.5]);
	title(sprintf('p = %f',p))
	ylabel('# ROIs R>0.85')