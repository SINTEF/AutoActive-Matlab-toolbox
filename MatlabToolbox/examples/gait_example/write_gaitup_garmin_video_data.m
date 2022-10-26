% Same example as in GettingStarted.mlx

% *Known issues when running this script*:
%
% * You need to be in the same "current folder" as this script when running in MATLAB (Different from GettingStarted.mlx where MatlabToolbox should be current folder!!)
% * You need to install the Physilog 5 Matlab Tool Kit by downloading from https://media.gaitup.com/Physilog5MatlabToolKit_v1_5_0.zip and put the extracted folder in the \AutoActive-Matlab-toolbox\MatlabToolbox\external folder

addpath(genpath('../../../../AutoActive-Matlab-toolbox/'));
% Please be sure that you have downloaded the Physilog 5 Matlab Tool Kit
% from https://research.gaitup.com/support/
% or https://media.gaitup.com/Physilog5MatlabToolKit_v1_5_0.zip and put it
% in the external folder
addpath('../../external/Physilog5MatlabToolKit_v1_5_0/');

UserFolder = pwd; % the current folder path (should be the AutoActive Matlab Toolbox folder for this example)
dataFolderGaitup = [UserFolder '\gaitup_imu\']; % path to data folder with the '.BIN' files
% dataFolderGaitup = [UserFolder '\examples\gait_example\gaitup_imu\']; % path to data folder with the '.BIN' files
gaitup = autoactive.plugins.Gaitup(); % create the matlab struct to import the gaitup files to
gaitup = gaitup.loadFilesToFolder(dataFolderGaitup); % load the files into this struct from the folder with the GaitUp '.BIN'-files

% Import the Catapult © '.CSV'-files using the autoactive csv import plugin:
dataFolderCatapult = [UserFolder '\catapult_imu\']; % path to data folder with the '.CSV' files
csv = autoactive.plugins.Csvimport(); % create the matlab struct to import the catapult '.CSV' files to
csv = csv.loadFilesToFolder(dataFolderCatapult); % load the files into this struct from the folder with the '.CSV' files

% Import the Garmin © '.tcx'-files using the autoactive garmin import plugin:
dataFolderGarmin = [UserFolder '\garmin_hr\']; % path to data folder with the '.tcx' files
garmin = autoactive.plugins.Garmin(); % create the matlab struct to import the garmin '.tcx' files to
garmin = garmin.loadFilesToFolder(dataFolderGarmin); % load the files into this struct from the folder with the '.tcx' files

% Import the video record using the autoactive video import plugin;
video_filename = [UserFolder '\video\gait_video.mp4']; % path to the video file
video = autoactive.Video(); % create the matlab struct to import the video to
video = video.addVideoToArchive(video_filename); % load the video into this struct

% Create an AutoActive session for the GaitUp©, Catapult©, Garmin© and video data:
% create session object
s = autoactive.Session('Gait_example');

% create Data folder for the Gaitup, Catapult, Garmin and video data:
s.gaitup = gaitup;
s.catapult = csv;
s.garmin = garmin;
s.video = video; 

% Write AAZ archive with the session 'Gait_example':
% create archive object and file with name MyTestSession.aaz
aw = autoactive.ArchiveWriter('Gait_example.aaz');

aw.traceDisplay(true);
s.save(aw);
aw.close();
clear aw