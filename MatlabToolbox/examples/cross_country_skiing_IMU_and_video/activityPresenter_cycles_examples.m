%% Cross country skiing example with ActivityPresenter
% This example illustrates how to read and syncronize raw IMU data from 
% Gaitup sensors, manipulate these data, and write the manipuated data 
% syncronized with video and export this to a .aaz file to be visualized in 
% ActivityPresenter. The example demonstrates first and foremost how to
% manipulate the data in MATLAB and how one can visualiz manipulated data 
% in the ActivityPresenter. Specifically we read IMU data from the chest 
% and left arm and lowpass the accelerometer data from the chest, and do a
% hard lowpassfilter of the gyroscope data from the left arm. The peaks of 
% the filtered gyroscope data is detected to indicate the cycles of the
% cross country skiier as described in 
% Rindal, O. M. H., Seeberg, T. M., Tjønnås, J., Haugnes, P., & Sandbakk, Ø. (2018).
% Automatic classification of sub-techniques in classical cross-country skiing 
% using a machine learning algorithm on micro-sensor data. MDPI Sensors, 18(1). 
% https://doi.org/10.3390/s18010075

% ----------------------------------------------
% Citationware. This code and data is citationware. If you use the data or code from this exampe you need to cite the following two papers:
% Albrektsen, S., Rasmussen, K. G. B., Liverud, A. E., Dalgard, S., Høgenes, J., Jahren, S. E., … Seeberg, T. M. (2022). The AutoActive Research Environment. Journal of Open Source Software, 7(72), 4061. https://doi.org/10.21105/joss.04061
% Rindal, O. M. H., Seeberg, T. M., Tjønnås, J., Haugnes, P., & Sandbakk, Ø. (2018). Automatic classification of sub-techniques in classical cross-country skiing using a machine learning algorithm on micro-sensor data. MDPI Sensors, 18(1). https://doi.org/10.3390/s18010075
% ----------------------------------------------
%
% Author: Ole Marius Hoel Rindal (olemarius.rindal@sintef.no)
% Date: April 2022
% Latest update: 25.05.2022

clear all;
close all;

% This file is in the toolbox, but this sets up the necessary paths
addpath(genpath('..\..\..\..\AutoActive-Matlab-toolbox\'));
% Please be sure that you have downloaded the Physilog 5 Matlab Tool Kit
% from https://research.gaitup.com/support/
% or https://media.gaitup.com/Physilog5MatlabToolKit_v1_5_0.zip and put it
% in the external folder
addpath('..\..\external\Physilog5MatlabToolKit_v1_5_0\');
% Add the compiled .jar file of the Activity Presenter Toolbox
jar_file = dir('..\..\jar\'); javaaddpath(['..\..\jar\',jar_file(3).name])

% Data path to the raw data
data_path = 'D:\OneDrive\SINTEF\(SEP) Bevegelsesanalyse - datasett\ClassicalXCSkiing_Linderudkollen\raw_data\'
%% Read raw data from Gaitup Sensors
dataFolderGaitup = [data_path]; % path to data folder with the '.BIN' files
gaitup = autoactive.plugins.Gaitup(); % create the matlab struct to import the gaitup files to
gaitup = gaitup.loadFilesToFolder(dataFolderGaitup); 

%% Filter data
% Create two Guasian filters with two different cutoff 
h = gaussfilter(10);
h_2 = gaussfilter(15);

acc_xaxis_filtered_hard = conv(gaitup.sensor0ST283.accel.data_accel1,h,'same');
acc_yaxis_filtered_hard = conv(gaitup.sensor0ST283.accel.data_accel2,h,'same');
acc_zaxis_filtered_hard = conv(gaitup.sensor0ST283.accel.data_accel3,h,'same');

gyro_xaxis_filtered_hard = conv(gaitup.sensor0LA301.gyro.data_gyro1,h_2,'same');
gyro_yaxis_filtered_hard = conv(gaitup.sensor0LA301.gyro.data_gyro2,h_2,'same');
gyro_zaxis_filtered_hard = conv(gaitup.sensor0LA301.gyro.data_gyro3,h_2,'same');

%% Detect Cycles using gyro on arm
[peaks, amp] = peakseek(gyro_zaxis_filtered_hard,100,100);

cycle_indicator = zeros(1,length(gyro_zaxis_filtered_hard));
for i = 1:length(peaks)-1
    if mod(i,2)
        cycle_indicator(peaks(i):peaks(i+1)) = 3;
    else
        cycle_indicator(peaks(i):peaks(i+1)) = -2;
    end
end

%% Plot result to investigate
figure(1);clf;hold all;
subplot(211);hold all;
plot(gaitup.sensor0ST283.accel.corrected_timestamps_accel1,gaitup.sensor0ST283.accel.data_accel1,'DisplayName','x-axis raw');
plot(gaitup.sensor0ST283.accel.corrected_timestamps_accel1,acc_xaxis_filtered_hard,'DisplayName','x-axis filtered');
plot(gaitup.sensor0ST283.accel.corrected_timestamps_accel1,acc_yaxis_filtered_hard,'DisplayName','y-axis filtered');
plot(gaitup.sensor0ST283.accel.corrected_timestamps_accel1,acc_zaxis_filtered_hard,'DisplayName','z-axis filtered');
plot(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1,cycle_indicator,'DisplayName','cycle indicator');
for kk=1:length(peaks)
    text(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(kk)),3,num2str(kk));
end
ax(1) = gca;
legend; xlim([750 790])
title('Accelerometer data from chest');xlabel('Time');ylabel('Amplitude')
subplot(212);hold all;
plot(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1,gyro_xaxis_filtered_hard,'DisplayName','x-axis');
plot(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1,gyro_yaxis_filtered_hard,'DisplayName','y-axis')
plot(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1,gyro_zaxis_filtered_hard,'DisplayName','z-axis')
plot(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks),amp,'*','DisplayName','peak')
plot(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1,cycle_indicator*500,'DisplayName','cycle indicator');
title('Gyroscope data data from arm');xlabel('Time');ylabel('Amplitude')
legend; xlim([750 790])
ax(2) = gca;
linkaxes(ax,'x');

%% Create struct to be written to AutoActive Session
t = struct();                       % create struct
t.time = int64(gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1*1e6);          % create time vector in micro seconds
t.cycle_indicator = cycle_indicator';      % create sine vector

filtered_acc_chest = struct();
filtered_acc_chest.time = int64(gaitup.sensor0ST283.accel.corrected_timestamps_accel1*1e6);
filtered_acc_chest.x_axis = acc_xaxis_filtered_hard;
filtered_acc_chest.y_axis = acc_yaxis_filtered_hard;
filtered_acc_chest.z_axis = acc_zaxis_filtered_hard;


%% Add annotation
% Based on the plot in Figure 1 manually annotate the classical cross
% country skiing subtechniques
DIA = [20:21 38:62 75:95];
DP = [23:35 98:109];
TCK = [68 97]; 

annotationProvider = autoactive.plugins.Annotation();
annotation_id = 1;
for cycle = DIA
    mean_time = mean([gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(cycle))...
                      gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(cycle+1))]);
    annotationProvider.addAnnotation(mean_time*1e6, annotation_id);
end
annotationProvider.setAnnotationInfo(annotation_id, 'Diagonal Stride', 'DIA', 'XC classical skiing diagonal stride');

annotation_id = 2;
for cycle = DP
    mean_time = mean([gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(cycle))...
                      gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(cycle+1))]);
    annotationProvider.addAnnotation(mean_time*1e6, annotation_id);
end
annotationProvider.setAnnotationInfo(annotation_id, 'Double Poling', 'DP', 'XC classical skiing double poling');

annotation_id = 3;
for cycle = TCK
    mean_time = mean([gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(cycle))...
                      gaitup.sensor0LA301.gyro.corrected_timestamps_gyro1(peaks(cycle+1))]);
    annotationProvider.addAnnotation(mean_time*1e6, annotation_id);
end
annotationProvider.setAnnotationInfo(annotation_id, 'Downhill Tucking', 'TCK', 'XC classical skiing downhill tucking');


%%
% create session object
sw = autoactive.Session('XC Skiing');

% convert struct t to table and add autoactive session
sw.cycle_indicator = struct2table(t);                             
sw.cycle_indicator.Properties.VariableUnits{'time'} = 'Epocms';
sw.cycle_indicator.Properties.UserData = struct();        % mandatory metadata for archive

sw.filtered_acc_chest = struct2table(filtered_acc_chest);
sw.filtered_acc_chest.Properties.VariableUnits{'time'} = 'Epocms';
sw.filtered_acc_chest.Properties.UserData = struct();        % mandatory metadata for archive

video = autoactive.Video();
video = video.addVideoToArchive([data_path,'/dataset_1_OMHR_compressed.mp4']);
offset = gaitup.sensor0ST283.accel.corrected_timestamps_accel1(1)*1e6 + 7.5*10^6;
video = video.setStartTime(offset);
sw.video = video;

sw.annotation = annotationProvider;

% create archive object and file with name testSine.aaz
aw = autoactive.ArchiveWriter(['XC_skiing_with_cycles_test.aaz']);
% write session to archive
aw.saveSession(sw);
aw.close()        
clear aw;

%% Implementation of the Gaussian lowpass filter used

function gaussFilter = gaussfilter(sigma)
    fsize=sigma * 6;
    x = linspace(-fsize / 2, fsize / 2, fsize);
    gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
    gaussFilter = gaussFilter / sum (gaussFilter); % normalize
end