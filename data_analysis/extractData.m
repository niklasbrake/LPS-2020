function header = extractData(Folder, ImageData, Register)

% header = extractData(Folder)
%   Takes experiment folder and outputs analysed image data
%   By default Register = 1
% header = extractData(header,ImageData)
%   Takes data.mat header and ImageData and analyzes it
% header = extractData(Folder,[],Register)
%   Takes experiment folder register 1 or 0. If Register = 1,
%   then the images are registered. Otherwise, there is no 
%   registration
%   
% 

  try

    switch nargin

    case {0,1,3}  % Analyse raw data

      % Register the images. Otherwise determiend by Register
      if(nargin == 1 || 0)
        Register = 1;
      end
      if(nargin == 0)
        Folder = uigetdir('Data Folder');
      end

      abort = 0;

      if(~exist(fullfile(Folder,'Episode001.h5')))
        disp([Folder ' is missing Episode001.h5']);
        abort = 1;
      end
      if(~exist(fullfile(Folder,'Experiment.xml')))
        disp([Folder ' is missing Experiment.xml']);
        abort = 1;
      end
      if(~exist(fullfile(Folder,'Image_0001_0001.raw')))
        disp([Folder ' is missing Image_0001_0001.raw']);
        abort = 1;
      end
      if(~exist(fullfile(Folder,'StimulusConfig.txt')))
        disp([Folder ' is missing StimulusConfig.txt']);
        abort = 1;
      end
      if(~exist(fullfile(Folder,'StimulusTimes.txt')))
        disp([Folder ' is missing StimulusTimes.txt']);
        abort = 1;
      end
      if(~exist(fullfile(Folder,'ThorRealTimeDataSettings.xml')))
        disp([Folder ' is missing ThorRealTimeDataSettings.xml']);
        abort = 1;
      end

      if(abort)
        return;
      else
        % Extract data from images
        [header1 ImageData] = getTimeSeries(Folder,Register);
        % Analyse extracted data
        header = analyseTimeSeries(header1, ImageData);
      end

    case 2  % Analyse data from ImageData
      header = analyseTimeSeries(Folder, ImageData);
    otherwise
      ME = MException('MATLAB:actionNotTaken','Invalid number of input arguments.');
      throw(ME);
    end

  catch Last_Error
    disp(getReport(Last_Error));
  end

end

function [header ImageData] = getTimeSeries(Folder,Register)
  Folder = char(Folder); % Fix bug with ImageJ when Folder path is a string
  
  % Get Folder name, save data with name 
  [Path ExperimentName] = fileparts(Folder);
  fileName = [ExperimentName '.mat'];

  % Add ImageJ library to JAVACLASSPATH
  jarDir = fullfile(fileparts(mfilename('fullpath')),'ext');
  javaaddpath(fullfile(jarDir,'MorphoLibJ_-1.3.1.jar'));
  javaaddpath(fullfile(jarDir,'ij-1.51n.jar'));
  import ij.process.*;
  import ij.*;

  % Extract experiment data from Experiment.xml file
  MetaData      = xml2struct(fullfile(Folder,'Experiment.xml'));
  ImageWidth    = str2num(MetaData.ThorImageExperiment.LSM.Attributes.pixelX);
  ImageHeight   = str2num(MetaData.ThorImageExperiment.LSM.Attributes.pixelY);
  FrameCount    = str2num(MetaData.ThorImageExperiment.Streaming.Attributes.frames);
  StepCount     = str2num(MetaData.ThorImageExperiment.ZStage.Attributes.steps);
  fps           = str2num(MetaData.ThorImageExperiment.LSM.Attributes.frameRate(1:5));
  FlyBackFrames = str2num(MetaData.ThorImageExperiment.Streaming.Attributes.flybackFrames);
  fieldSize     = str2num(MetaData.ThorImageExperiment.LSM.Attributes.fieldSize);
  zScale        = str2num(MetaData.ThorImageExperiment.ZStage.Attributes.stepSizeUM);
  zStart        = str2num(MetaData.ThorImageExperiment.ZStage.Attributes.startPos);

  if(StepCount == 1)
    FlyBackFrames = 0;
  end

  fps = fps/(StepCount+FlyBackFrames);
  ImagesPerSlice = FrameCount / (StepCount + FlyBackFrames);


  % Get projected Images for each slice. tform is 0 if no registration takes place
  [Average_Images tform] = zProjReg(fullfile(Folder,'Image_0001_0001.raw'),ImagesPerSlice,ImageWidth*ImageHeight,StepCount,FlyBackFrames,Register);

  % Save tform data
  save(fullfile(Folder,'tform.mat'), 'tform', 'Average_Images');
  
  header = struct('FileName', fileName, 'DataPath',Folder, 'Slices', StepCount, 'Frames', ...
    ImagesPerSlice, 'fps', fps,'FlyBackFrames',FlyBackFrames,'ImageWidth',ImageWidth, ...
    'ImageHeight',ImageHeight,'fieldSize',fieldSize,'zScale',zScale,'zStart',zStart);

  % Loop through each slice
  for Slice = 1:StepCount
   
    % Save .tifs and open them with ImageJ
    ImageName = fullfile(Folder,['Slice' int2str(Slice) '.tif']);
    imwrite(suint16(Average_Images(:,:,Slice)),ImageName,'tif');
    IJ.run('Open...', ['path=[' ImageName ']']);
    imp = WindowManager.getCurrentImage;

    % Get the Roi Manager 
    K = plugin.frame.RoiManager.getRoiManager;

    % Image analysis
    IJ.run('Subtract Background...', 'rolling=7 stack');
    imp.setProcessor( inra.ijpb.morphology.Morphology.whiteTopHat( getChannelProcessor(imp), inra.ijpb.morphology.strel.DiskStrel.fromRadius(6) ) );
    IJ.run('Enhance Contrast', 'saturated=0.35');
    IJ.setAutoThreshold(imp,'MinError dark');
    IJ.run('Convert to Mask');
    IJ.run('Remove Outliers...', 'radius=4 threshold=50 which=Dark');
    IJ.run('Watershed');
    IJ.run('Open');
    IJ.run('Analyze Particles...', 'clear add stack');
    IJ.run('Set Measurements...', 'mean redirect=None decimal=3');

    % Extract ROI coordinates
    rois = K.getRoisAsArray;
    if(length(rois) == 0)
      ME = MException('MATLAB:actionNotTaken','No ROIs detected!');
      throw(ME);
    end
    A = zeros(ImageHeight,ImageWidth,length(rois));
    RoiCoordinates = zeros(3,length(rois));
    RoiPoints = {};
    for r = 1:length(rois)
      roi = rois(r);
      points = roi.getContainedPoints;
      Coords = zeros(length(points),3);
      for p = 1:length(points)
        Coords(p,:) = [points(p).x points(p).y Slice];
      end
      RoiCoordinates(:,r) = mean(Coords,1)';
      RoiPoints{r,1} = Coords(:,1);
      RoiPoints{r,2} = Coords(:,2);
    end

    ImageData(Slice) = struct('Slice', Slice, 'Results', [], 'NumOfROIs',length(rois),'Average', ...
      Average_Images(:,:,Slice),'RoiCoordinates',RoiCoordinates,'tform',[],'RoiMask',[]);

    ImageData(Slice).RoiMask = RoiPoints;

    % Save tforms if no registration
    if(~iscell(tform))
      ImageData(Slice).tform = 0;
    else
      ImageData(Slice).tform = {tform{Slice,:}};
    end

    IJ.run('Close All');
    % delete(fullfile(Folder,['Slice' int2str(Slice) '.tif']));
  end

  % Measures average pixel value for each ROI
  Results = measure(fullfile(Folder,'Image_0001_0001.raw'), header, ImageData, tform);

  % Save measurements for each ROI
  for Slice = 1:StepCount
    ImageData(Slice).Results = Results{Slice};
  end  

  % Saves data differently depending on registeration
  if(~iscell(tform))
    header.FileName = [ExperimentName '-noReg.mat'];
    save(fullfile(Folder,[ExperimentName '-noReg.mat']), 'header', 'ImageData','-v7.3');
  else
    save(fullfile(Folder,fileName), 'header', 'ImageData','-v7.3');
  end

  delete(fullfile(Folder,'tform.mat'));
  K.reset();
  K.close();

end


function header = analyseTimeSeries(header, ImageData)

  Folder = header.DataPath;
  filename = header.FileName;
  datafile = fullfile(Folder,['Analysed ' filename]);

  % Read StimulusTimes.txt and StimulusConfig.txt.
  RawStimulusData = tabulate(readLines(fullfile(Folder,'StimulusTimes.txt')));

  StimConfigData  = tabulate(readLines(fullfile(Folder,'StimulusConfig.txt')));
  Config.StimuliCount   = StimConfigData(1,1);   Config.Number      = StimConfigData(2,1);
  Config.Repetitions    = StimConfigData(1,2);   Config.Height      = StimConfigData(2,2);
  Config.Type           = StimConfigData(1,3);   Config.Width       = StimConfigData(2,3);
  Config.DisplayLength  = StimConfigData(1,4);   Config.BottomPad   = StimConfigData(2,4);
  Config.RestLength     = StimConfigData(1,5);   Config.Area        = StimConfigData(2,5);
  Config.PlusMinus      = StimConfigData(1,6);   Config.Background  = StimConfigData(2,6);

  % Get capture times with ThorSync functions
  LoadSyncEpisode([Folder '\']);
  GenerateFrameTime;

  % Get length of experiment
  TimeLapse = frameTime(end);

  % Reorient data to ROI-oriented structure
  [RoiData RoiCoordinates] = getRoiData(ImageData);


  % Get time axis for each ROI time series
  FrameTimes = getTimeAxis(RoiData,frameTime,header.Slices,header.FlyBackFrames);

  % Get stimulus times calibrated to beginning of frame capture if applicable
  RawStimulusData(:,2) = RawStimulusData(:,2) + frameTime(1);
  StimulusTimes = RawStimulusData(:,2);

  for i = 1:length(ImageData)
    RoiMask{i} = ImageData(i).RoiMask;
  end

  % Normalize data with stimulus response
  types = unique(RawStimulusData(:,3));
  m = size(RawStimulusData,1)/length(types);
  window = [7:13];
  X = zeros(length(RoiData),length(types),m,25);
  for i = 1:length(RoiData)
      y = RoiData(i).Brightness;
      time = FrameTimes(i,:);
      tt = interp1(time,[1:length(time)],[time(1)+1; RawStimulusData(:,2);RawStimulusData(end,2)+5; time(end)-1],'nearest');
      for j = 1:length(tt)
        it = tt(j);
        bl(j) = mean(RoiData(i).Brightness(it-3:it+3));
      end
      bl2 = interp1(tt,bl,[1:length(time)],'linear');
      dFF0(i,:) = (y(:)-bl2(:))./abs(bl2(:));

      counter = zeros(1,length(types));
      for j = 1:length(RawStimulusData)
        t = find(RawStimulusData(j,3)==types);
        counter(t) = counter(t)+1;
        T = interp1(time,1:length(time),RawStimulusData(j,2),'next');
        XResponse(i,t,counter(t),:) = dFF0(i,T:T+24);
      end
      X = mean(XResponse(:,:,:,window),4);
      for t = 2:length(types)
        ZScore(i,t-1) = (mean(X(i,t,:))-mean(X(i,1,:)))/sqrt(var(X(i,t,:))/m+var(X(i,1,:))/m);
      end
      responses = mean(X,3);
  end

  % Save data in structures
  AnalysedData = struct('dFF0', dFF0,'Times', FrameTimes,'RoiCoords',RoiCoordinates,'Responses',responses, ...
    'AllResponses',XResponse,'ZScore',ZScore);
  StimulusData = struct('Raw',RawStimulusData,'Times',StimulusTimes,'Configuration',Config);
  header = struct('FileName',['Analysed ' filename], 'RoiCount', length(RoiData), 'StimuliCount', ...
    length(StimulusTimes),'TimeLapse', TimeLapse, 'FPS', header.fps, 'Frames', ...
    header.Frames, 'Slices', header.Slices,'ImageWidth',header.ImageWidth,'ImageHeight', ...
    header.ImageHeight, 'fieldSize',header.fieldSize, 'zScale',header.zScale, 'zStart',header.zStart, ...
    'FlyBackFrames', header.FlyBackFrames,'RoiMask',{RoiMask});

  % Save final analysed data
  save(datafile, 'header','AnalysedData','StimulusData','RoiData');

end