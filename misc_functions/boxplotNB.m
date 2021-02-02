function h = boxplotNB(xCntr,Y,colorScheme,markersize)
	% X = (mod([1:length(Y)],4)-1.5)/15+xCntr;
	X = (3*rand(size(Y))-1.5)/15+xCntr;
	x = [min(X)-0.2,max(X)+0.2,max(X)+0.2,min(X)-0.2];
	y = [prctile(Y,25),prctile(Y,25),prctile(Y,75),prctile(Y,75)];
	F = fill(x,y,colorScheme);
	F.FaceAlpha = 0.1;
	F.EdgeColor = 'none';
	line([min(X)-0.2,max(X)+0.2],[nanmedian(Y),nanmedian(Y)],'Color','k','LineWidth',1);
	line([xCntr,xCntr],[prctile(Y,10),prctile(Y,25)],'Color','k','LineWidth',1);
	line([xCntr,xCntr],[prctile(Y,75),prctile(Y,90)],'Color','k','LineWidth',1);
	hold on;

	h = scatter(X,Y,markersize,colorScheme,'filled','MarkerFaceAlpha',0.4); hold on;
	scatter(xCntr,nanmean(Y),10+markersize,'w','filled','MarkerEdgeColor','k')