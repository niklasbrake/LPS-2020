function LinearRegBrightAll

warning('off','MATLAB:xlswrite:AddSheet');

F = dir;
 for i = 3:length(F)
			load(fullfile(F(i).name));
            
S = size(Significant_ROIs,1);
            
%Set stimulus values.

x = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]';
X = [ones(length(x),1) x];

Slopes = [];
Gof = [];
Strength = [];
XInt = [];
YInt = [];

   for j = 1:S
      y = Significant_ROIs(j,2:11)';   
      b = X\y;                        %Calculate slope
      yCalc = X*b;
      G = 1 - sum((y - yCalc).^2)/sum((y - mean(y)).^2); % Calculate goodness of fit.
            Slopes = [Slopes;b(2)];
            Gof = [Gof;G];
            YInt = [YInt;b(1)];
            Strength = [Strength;Significant_ROIs(j,:)];
            
            Xi = -(b(1))/b(2);               %Calculate Xint.
            XInt = [XInt;Xi];
   end
Name = F(i).name(15:end);    
 
save(fullfile(['LinearReg' Name]),'Slopes','Gof','Strength','XInt');


% Write the results to Excel.

xlswrite(['LinearReg' Name '.xlsx'],[Slopes],1);
xlswrite(['LinearReg' Name '.xlsx'],[Gof],2);
xlswrite(['LinearReg' Name '.xlsx'],[XInt],3);
xlswrite(['LinearReg' Name '.xlsx'],[Strength],4);
end
end


