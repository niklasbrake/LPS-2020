function h =plotwitherror(x,y,isstdrr,varargin)

	if(isstdrr)
		ymu = nanmean(y,2);
		% ymu = nanmedian(y,2);
		ylo = ymu-stderror(y')';
		yhi = ymu+stderror(y')';
	else
		ymu = nanmedian(y,2);
		% ylo = quantile(y,0.05,2);
		ylo = quantile(y,0.75,2);
		% yhi = quantile(y,0.95,2);
		yhi = quantile(y,0.25,2);
	end

	h = plot(x,ymu,varargin{:}); hold on;

	idcs = ~isnan(ymu);
	ylo = ylo(idcs);
	yhi = yhi(idcs);
	ymu = ymu(idcs);
	x = x(idcs);

	xfvec = [x,flip(x)];
	yfvec = [ylo;flip(yhi)];
	F = fill(xfvec(:),yfvec(:),'k');

	hold off;
	if(isempty(F))
		return;
	end
	F.FaceAlpha = 0.2;
	F.FaceColor = h.Color;
	F.EdgeColor = 'none';
