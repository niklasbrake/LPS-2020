function [coeff,R] = FitThreshold(x, y)

[xData, yData] = prepareCurveData( x, y );

c0 = -4;
dc = 0.6;
c00 = c0;
sz = size(xData);
b = ones(sz);

X = zeros(sz); X(xData<c0) = xData(xData<c0)-c0;
[~,~,~,~,stats0] = regress(yData,[X,b]);

while dc > 1e-2;
	c1 = c0-dc;
	c2 = c0+dc;
	

	X = zeros(sz); 	X(xData<c1) = xData(xData<c1)-c1;
	[~,~,~,~,stats1] = regress(yData,[X,b]);

	X = zeros(sz); 	X(xData<c2) = xData(xData<c2)-c2;
	[~,~,~,~,stats2] = regress(yData,[X,b]);


	if(stats1(1) >= stats0(1))
		if(c1==c00)
			dc = dc/2;
		end
		c00 = c0;
		c0 = c1;
		stats0 = stats1;	
	elseif(stats2(1) >= stats0(1))
		if(c2==c00)
			dc = dc/2;
		end
		c00 = c0;
		c0 = c2;
		stats0 = stats2;
	else
		dc = dc/2;
	end
end
			
X = zeros(sz); X(xData<c0) = xData(xData<c0)-c0;
[coeff,~,~,~,stats0] = regress(yData,[X,b]);
coeff = [coeff;c0];
R = stats0(1);