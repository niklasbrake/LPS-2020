function fit2Hill(folder1)

F = dir(folder1);
F = F(3:end);
F = F([F(:).isdir]);

X = [];
Z = [];
for i = 1:length(F)
	filepath = fullfile(folder1,F(i).name);
	[~,name] = fileparts(filepath);
	load(fullfile(filepath,['Analysed ' name '.mat']));
	X = [X;AnalysedData.Responses];
	Z = [Z;AnalysedData.ZScore];
	N(i) = size(AnalysedData.Responses,1);
end
% Normalize to the null response
X = X(:,2:end-1) - X(:,1);

% Get spatial frequencies for each stimulus
pix2ang = 1/(22.5*sin(1*pi/180)/sin(89*pi/180));
xData = log(pix2ang*[0.0010;0.0030;0.0050;0.0060;0.0100; ...
0.0130;0.0200;0.0250;0.0310;0.0400; ...
0.0500;0.0630;0.1000;0.1250;0.2000])/log(10);

% Fit sigmoidal curve to the response profile of each cell
ft = fittype(@(a1,a2,a3,a4,x) a1 + a2./(1+exp((x-a3)/a4)));
coeff = zeros(4,size(X,1));
R = zeros(size(X,1),1);
h = waitbar(0);
sp = [min(X,[],2),max(X,[],2),-2*ones(length(X),1),0.2*ones(length(X),1)];
for i = 1:size(X,1)
	waitbar(i/size(X,1),h)
	ytemp = X(i,:);
	[FT,gof] = fit(xData(:),ytemp(:),ft,'StartPoint',sp(i,:), ...
					'Lower',[-30,0,-6,0],'Upper',[30,30,0,Inf]);
	R(i) = gof.rsquare;
	coeff(:,i) = coeffvalues(FT);
end


delete(h)

save(fullfile(folder1,'fits.mat'),'R','coeff','X','N');