function LinearRegLogAll

warning('off','MATLAB:xlswrite:AddSheet');

F = dir;
 for i = 3:length(F)
			load(fullfile(F(i).name));
            
S = size(Significant_ROIs,1);
            
%Set stimulus values.

x = [0.0073, 0.0147, 0.0293, 0.0367, 0.0587, 0.0733, 0.1173, 0.1466, 0.1833, 0.2346, 0.2933]';
xlog = log10(x);
X = [ones(length(xlog),1) xlog];

Slopes = [];
Gof = [];
Strength = [];
XInt = [];
YInt = [];
ROInum = [];

   for j = 1:S
      y = Significant_ROIs(j,2:12)';   %Keep values for linear regression.
      b = X\y;                         %Calculate slope & Yint.
      yCalc = X*b;
      G = 1 - sum((y - yCalc).^2)/sum((y - mean(y)).^2); % Calculate goodness of fit.
        
            Slopes = [Slopes;b(2)];
            Gof = [Gof;G];
            YInt = [YInt;b(1)];
            ROInum = [ROInum;j];
            Strength = [Strength;Significant_ROIs(j,:)];
            
            Xi = -(b(1))/b(2);               %Calculate Xint.
            X2 = 10^Xi;
            XInt = [XInt;X2];
        
   end
Name = F(i).name(9:end);     
 
save(fullfile(['LinearReg' Name]),'Slopes','Gof','Strength','XInt','YInt');


% Write the results to Excel.

xlswrite(['LinearReg' Name '.xlsx'],[Slopes],'Slopes');
xlswrite(['LinearReg' Name '.xlsx'],[Gof],'GofF');
xlswrite(['LinearReg' Name '.xlsx'],[XInt],'XInt');
xlswrite(['LinearReg' Name '.xlsx'],[YInt],'YInt');
xlswrite(['LinearReg' Name '.xlsx'],[ROInum],'ROInum');
xlswrite(['LinearReg' Name '.xlsx'],[Strength],'Strength');
 end
end

