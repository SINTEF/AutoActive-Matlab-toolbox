%% Cross country skiing example with ActivityPresenter
% Data from wearable microsensors such as inertial movement sensors (IMUs) 
% are revolutionizing the analysis of movement. It allows researchers to
% bring the lab to the field, resulting in more relevant data for the 
% analysis of movements in sports. However, there has been a lack of available
% tools to easily analyze the data. Especially, synchronizing the ground 
% truth video of the movement of an athlete with the recorded data from microsensors
% has been challenging. SINTEF have developed an open source AutoActive Research
% Environment (ARE) [1] consisting of easy-to-use software with a graphical user
% interface, ActivityPresenter, to visualize, synchronize, and organize data
% from sensors and cameras as well as a supporting MATLAB and python toolbox. 
% We demonstrate this software suite by sharing a dataset to analyze 
% sub-techniques in classical cross country skiing [2]. The data and code
% are available at https://www.sintef.no/projectweb/autoactive/code-example/.
%
% We recorded data from IMU sensors mounted on the arm and chest as well as 
% a video recording of a subject doing cross classical cross-country skiing.
% The raw accelerometer and gyroscope data was processed in MATLAB with 
% individual cycles of movements detected and labeled as described in [2]. 
% The processed IMU data and cycle indications as well as sub-technique labels
% were synchronized with the video and written to an AutoActiveZip (aaz) file 
% using the ARE MATLAB toolbox. 
%
% The processed data from the accelerometer on the chest is visualized in 
% ActivityPresenter together with the cycle identification. Annotations are
% visible as DIA (diagonal) in the bottom of the plot. The data and video 
% can be played as a movie or stepped through  frame-by-frame. Additional 
% annotations can be added by pre-selected keys per sub-techniques.
%
% This example illustrates how to read and syncronize raw IMU data from 
% Gaitup sensors, manipulate these data, and write the manipuated data 
% syncronized with video and export this to a .aaz file to be visualized in 
% ActivityPresenter. The example demonstrates first and foremost how to
% manipulate the data in MATLAB and how one can visualiz manipulated data 
% in the ActivityPresenter. 
%
% *Data:* The data in this example is automatically downloaded, but can be manually downloaded from 
% https://github.com/SINTEF/AutoActive-Matlab-toolbox/releases/download/v2.0.0_dataset/AutoActive_SampleData_xc_skiing.zip
%
% *Citationware:* This code and data is citationware. 
% If you use the data or code from this exampe you need to cite the following two papers:
%
% * [1] Albrektsen, S., Rasmussen, K. G. B., Liverud, A. E., Dalgard, S., Høgenes, J., Jahren, S. E., Kocbach J., Seeberg, T. M. (2022). The AutoActive Research Environment. Journal of Open Source Software, 7(72), 4061. https://doi.org/10.21105/joss.04061
% * [2] Rindal, O. M. H., Seeberg, T. M., Tjønnås, J., Haugnes, P., & Sandbakk, Ø. (2018). Automatic classification of sub-techniques in classical cross-country skiing using a machine learning algorithm on micro-sensor data. MDPI Sensors, 18(1). https://doi.org/10.3390/s18010075
%
% *Known issues when running this script*:
%
% * You need to be in the same "current folder" as the activityPresenter_cycles_examples.m script when running in MATLAB
% * You need to install the Physilog 5 Matlab Tool Kit by downloading from https://media.gaitup.com/Physilog5MatlabToolKit_v1_5_0.zip and put the extracted folder in the \AutoActive-Matlab-toolbox\MatlabToolbox\external folder
% * You need to have Python installed and awailable to MATLAB. Follow instructions on https://se.mathworks.com/help/matlab/matlab_external/install-supported-python-implementation.html
%
% Author: Ole Marius Hoel Rindal (olemarius@olemarius.net)
% Date: April 2022
% Latest update: 14.11.2022
%
%% Set up paths, download and unzip data
% We will first set up the necessary paths for the toolbox and the
% physiolog MATLAB toolkit do be able to read the IMU data from the gait up
% sensors. The data and video used in this example is downloaded from the
% url below to the github repository.

clear all;
close all;

% This file is in the toolbox, but this sets up the necessary paths
addpath(genpath('../../../../AutoActive-Matlab-toolbox/'));
% Please be sure that you have downloaded the Physilog 5 Matlab Tool Kit
% from https://research.gaitup.com/support/
% or https://media.gaitup.com/Physilog5MatlabToolKit_v1_5_0.zip and put it
% in the external folder
addpath('../../external/Physilog5MatlabToolKit_v1_5_0/');
% Add the compiled .jar file of the Activity Presenter Toolbox
jar_file = dir('../../jar/'); javaaddpath(['../../jar/',jar_file(3).name])

% Check if data is allready downloaded. If not, download and unzip!
data_path = 'example_data'
if ~isfile([data_path,'/raw_data/dataset_1_OMHR_compressed.mp4'])
    fprintf('Downloading and unzipping data...');
    data_url = "https://github.com/SINTEF/AutoActive-Matlab-toolbox/releases/download/v2.0.0_dataset/AutoActive_SampleData_xc_skiing.zip";
    mkdir(data_path);
    filename = "example_data/example_data.zip";
    websave(filename,data_url);
    unzip(filename,data_path);
    delete(filename)
    fprintf('...done!\n');
end

%% Read raw data from Gaitup Sensors
% Read the raw IMU data from the .BIN files downloaded into MATLAB structs
% using the autoactive Gaitup plugin. NB! This is dependent on the 
% Physilog5MatlabToolKit as specified in the paths above.

dataFolderGaitup = [data_path,'/raw_data/']; % path to data folder with the '.BIN' files
gaitup = autoactive.plugins.Gaitup(); % create the matlab struct to import the gaitup files to
gaitup = gaitup.loadFilesToFolder(dataFolderGaitup); 
fs = gaitup.sensorexample_data.raw_data.x0LA301.info.baseFrequency;

%% Filter data
% Create two Guasian filters with two different cutoff frequencies.
h = gaussfilter(10);
h_2 = gaussfilter(15);

% Analyze the filter responses of the two lowpass filters.
fft_length = 1024; 
x_axis = linspace(-fs/2,fs/2,fft_length);
figure;
plot(x_axis,fftshift(20*log10(abs((fft(h,fft_length))))),'LineWidth',2);hold on; 
plot(x_axis,fftshift(20*log10(abs((fft(h_2,fft_length))))),'LineWidth',2);
xlim([0 50]);ylabel('Magnitude [dB]');xlabel('Frequency [Hz]');
legend('Hard lowpass filter','Softer lowpass filter');
set(gca,'FontSize',15)

% Filter the accelerometer data with the first lowpass filter
acc_xaxis_filtered_hard = conv(gaitup.sensorexample_data.raw_data.x0ST283.accel.data_accel1,h,'same');
acc_yaxis_filtered_hard = conv(gaitup.sensorexample_data.raw_data.x0ST283.accel.data_accel2,h,'same');
acc_zaxis_filtered_hard = conv(gaitup.sensorexample_data.raw_data.x0ST283.accel.data_accel3,h,'same');
accel_time = gaitup.sensorexample_data.raw_data.x0ST283.accel.corrected_timestamps_accel1;

% Filter the gyroscope data with the second lowpass filter
gyro_xaxis_filtered_hard = conv(gaitup.sensorexample_data.raw_data.x0LA301.gyro.data_gyro1,h_2,'same');
gyro_yaxis_filtered_hard = conv(gaitup.sensorexample_data.raw_data.x0LA301.gyro.data_gyro2,h_2,'same');
gyro_zaxis_filtered_hard = conv(gaitup.sensorexample_data.raw_data.x0LA301.gyro.data_gyro3,h_2,'same');
gyro_time = gaitup.sensorexample_data.raw_data.x0LA301.gyro.corrected_timestamps_gyro1;

%% Detect cycles using gyro on arm
% The cycles are detected by finding the peaks of the hard filtered
% gyroscope data from the arm. The peaks corresponds to the arm beeing
% exteded all the way behind the athlete.
[peaks, amp] = peakseek(gyro_zaxis_filtered_hard,100,100);

% Create a cycle indicator plot alternating from 3.2 to -2 between every
% detected cycle. This results in a signal that can be plotted together
% with the original data with horizontal transitions indicating the cycles
cycle_indications = zeros(1,length(gyro_zaxis_filtered_hard));
for i = 1:length(peaks)-1
    if mod(i,2)
        cycle_indications(peaks(i):peaks(i+1)) = 3.2;
    else
        cycle_indications(peaks(i):peaks(i+1)) = -2;
    end
end

%% Plot result to investigate
% Plot the accelerometer from the chest, both a trace of the unfiltered
% data as well as the filtered data from all axes. The cycles are indicated
% with horizontal lines as well as numbers to indicate each individual cycle. 
% The second subplot si the gyroscope data from the arm, indicating the
% z-axis used to detect the cycles.
figure(2);clf;hold all;
subplot(211);hold all;
plot(accel_time,gaitup.sensorexample_data.raw_data.x0ST283.accel.data_accel1,'DisplayName','x-axis raw','LineWidth',2);
plot(accel_time,acc_xaxis_filtered_hard,'DisplayName','x-axis filtered','LineWidth',2);
plot(accel_time,acc_yaxis_filtered_hard,'DisplayName','y-axis filtered','LineWidth',2);
plot(gaitup.sensorexample_data.raw_data.x0ST283.accel.corrected_timestamps_accel1,acc_zaxis_filtered_hard,'DisplayName','z-axis filtered','LineWidth',2);
plot(gyro_time,cycle_indications,'DisplayName','cycle indicator');
for kk=1:length(peaks)
    text(gyro_time(peaks(kk)),3,num2str(kk));
end
ax(1) = gca; set(gca,'FontSize',15);
legend; xlim([750 790]);ylim([-2,3.1]);
title('Accelerometer data from chest');xlabel('Time');ylabel('Amplitude')
subplot(212);hold all;
plot(gyro_time,gyro_xaxis_filtered_hard,'DisplayName','x-axis','LineWidth',2);
plot(gyro_time,gyro_yaxis_filtered_hard,'DisplayName','y-axis','LineWidth',2);
plot(gyro_time,gyro_zaxis_filtered_hard,'DisplayName','z-axis','LineWidth',2);
plot(gyro_time(peaks),amp,'*','DisplayName','peak')
plot(gyro_time,cycle_indications*500,'DisplayName','cycle indicator');
title('Gyroscope data data from arm');xlabel('Time');ylabel('Amplitude')
legend('Location','se'); xlim([750 790]); ylim([-900 600]);
ax(2) = gca; set(gca,'FontSize',15);
linkaxes(ax,'x');
set(gcf,'Position',[0 0 1000 750]);

%% Create struct to be written to AutoActive Session
% Create two structs to be written to the Auto Active Zip (aaz) file. The
% first struct is the cycle indication the second struct is the filtered
% accelerated data. The time in the structs are the syncronization between
% the signals.
cycle_indicator = struct();                       
cycle_indicator.time = int64(gyro_time*1e6); % time in micro seconds          
cycle_indicator.cycle_indicator = cycle_indications';

filtered_acc_chest = struct();
filtered_acc_chest.time = int64(accel_time*1e6); % time in micro seconds  
filtered_acc_chest.x_axis = acc_xaxis_filtered_hard;
filtered_acc_chest.y_axis = acc_yaxis_filtered_hard;
filtered_acc_chest.z_axis = acc_zaxis_filtered_hard;


%% Add annotation
% Based on the plot in Figure 2 we manually annotate the classical cross
% country skiing subtechniques. We will only annotate the cycles that are:
% * DIA = Diagonal Stride,  annotation ID = 1
% * DP = Dobbel Poling,  annotation ID = 2
% * TCK = Tucking (Downhill), annotation ID = 3
DIA = [20:21 38:62 75:95];
DP = [23:35 98:109];
TCK = [68 97]; 

% Define an object of the annotation plugin for each subtechnique class. 
% We are using the mean time of a cycle as the time for the annotation
annotationProvider = autoactive.plugins.Annotation();
annotation_id = 1;
for cycle = DIA
    mean_time = mean([gyro_time(peaks(cycle))...
                      gyro_time(peaks(cycle+1))]);
    annotationProvider.addAnnotation(mean_time*1e6, annotation_id);
end
annotationProvider.setAnnotationInfo(annotation_id, 'Diagonal Stride', 'DIA', 'XC classical skiing diagonal stride');

annotation_id = 2;
for cycle = DP
    mean_time = mean([gyro_time(peaks(cycle))...
                      gyro_time(peaks(cycle+1))]);
    annotationProvider.addAnnotation(mean_time*1e6, annotation_id);
end
annotationProvider.setAnnotationInfo(annotation_id, 'Double Poling', 'DP', 'XC classical skiing double poling');

annotation_id = 3;
for cycle = TCK
    mean_time = mean([gyro_time(peaks(cycle))...
                      gyro_time(peaks(cycle+1))]);
    annotationProvider.addAnnotation(mean_time*1e6, annotation_id);
end
annotationProvider.setAnnotationInfo(annotation_id, 'Downhill Tucking', 'TCK', 'XC classical skiing downhill tucking');


%% Write to Auto Active .aaz file
% Finally, we are going to write the data we want to display in the
% Activity Presenter program in a Auto Active Zip .aaz file. We want to display
% the following data:
%   + cycle indication 
%   + filtered accelerometer data from the chest sensor
%   + synchronized video
%   + annotations of type of sub technique for each cycle

% Create Auto Active Activity Presenter session object
sw = autoactive.Session('XC Skiing');

% add the cycle indication to the session object.
sw.cycle_indicator = struct2table(cycle_indicator);
% mandatory metadata for archive
sw.cycle_indicator.Properties.VariableUnits{'time'} = 'Epocms';
sw.cycle_indicator.Properties.UserData = struct();        

% add filtered accelerometer data to the object
sw.filtered_acc_chest = struct2table(filtered_acc_chest);
sw.filtered_acc_chest.Properties.VariableUnits{'time'} = 'Epocms';
sw.filtered_acc_chest.Properties.UserData = struct();% mandatory metadata for archive

% add information of the video to be stored in the .aaz file
video = autoactive.Video();
video = video.addVideoToArchive([data_path,'/raw_data/dataset_1_OMHR_compressed.mp4']);
% calculate the video offset compared to the data
offset = accel_time(1)*1e6 + 7*10^6;
video = video.setStartTime(offset);
sw.video = video;

% Add annotations
sw.annotation = annotationProvider;

% create archive object and file with name "XC_skiing_with_cycles". This
% file can be read in the Activity Presenter software.
aw = autoactive.ArchiveWriter(['XC_skiing_with_cycles.aaz']);
% write session to archive
aw.saveSession(sw);
aw.close()        
clear aw;

%% Implementation of the Gaussian lowpass filter used
% The lowpass filter used in this is example is included for simplicity. It
% is a simple Gaussian lowpass filter used at two different cutoff
% frequencies. 
function gaussFilter = gaussfilter(sigma)
    fsize=sigma * 6;
    x = linspace(-fsize / 2, fsize / 2, fsize);
    gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
    gaussFilter = gaussFilter / sum (gaussFilter); % normalize
end