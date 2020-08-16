function ExtractSignROIsSpatial(R2)

warning('off','MATLAB:xlswrite:AddSheet');

F = dir;
for i = 3:length(F)
			load(fullfile(F(i).name));

%Check ZScore for each ROI against the significance level. Build a
%matrix of the all Responses from ROIs with at least one ZScore > R2.

Significant_ROIs = [];
ZScores = [];
Allresponses = [];


S = size(AnalysedData.ZScore,1);
N = size(AnalysedData.ZScore,2);
for j = 1:S
     temp = zeros(1,17);
     for k = 1:N
        if AnalysedData.ZScore(j,k) > R2
        temp(1,k)=1;
        end
     end
   if sum(temp) > 0
      Significant_ROIs = [Significant_ROIs;AnalysedData.Responses(j,:)];    
      ZScores = [ZScores;AnalysedData.ZScore(j,:)];
      Allresponses = [Allresponses;AnalysedData.AllResponses(j,:)];
   end
   
end


save(fullfile(['SignROIsSpatialOld' header.FileName(10:end)]),'Significant_ROIs','ZScores','Allresponses');


% Write the results to Excel.

xlswrite(['SignificantResponsesAvg_SpatialOld.xlsx'],Significant_ROIs,[(F(i).name)]);
xlswrite(['SignificantResponsesZ_SpatialOld.xlsx'],ZScores,[(F(i).name)]);
xlswrite(['SignificantResponsesAll_SpatialOld.xlsx'],Allresponses,[(F(i).name)]);
end 

end

