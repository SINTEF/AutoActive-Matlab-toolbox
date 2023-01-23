close all, clear all, clc
javaaddpath('.\MatlabToolbox\jar\java-file-interface-2.0.1-jar-with-dependencies.jar')
addpath('C:\YourWorkPath')
%Read Data from existing archive
ar = autoactive.ArchiveReader('YourArchive.aaz');
list = ar.listSessions();
sr = ar.openSession(list.name);

%Get Gaitup data
dataFolderGaitup = 'C:\YourWorkPath\Gaitup\';
gaitup = autoactive.plugins.Gaitup();
gaitup = gaitup.loadFilesToFolder(dataFolderGaitup);

%Get Videos
offset = sr.Video1.getStartTime();
video_start_time_archive = getStartTimeAsEpoch('C:\YourWorkPath\YourFirstVideo.mp4');

video_start_time_new_video = getStartTimeAsEpoch('C:\YourWorkPath\YourSecondVideo.mp4');
time_between_org_videos = video_start_time_new_video - video_start_time_archive; 
offset_new_video = offset + (time_between_org_videos*1000000);

video_old = autoactive.Video();
video_old = video_old.addVideoToArchive('C:\YourWorkPath\YourFirstVideo.mp4');
video_old = video_old.setStartTime(offset);


video_new = autoactive.Video();
video_new = video_new.addVideoToArchive('C:\YourWorkPath\YourSecondVideo.mp4');
video_new = video_new.setStartTime(1*offset_new_video);


%Get soruce
source_obj = autoactive.Source();
this_script = mfilename('fullpath');
source_obj = source_obj.addSourceFromFile([this_script '.m']);


%Store data as a aaz file
aw = autoactive.ArchiveWriter('videosyncNewWorks.aaz');
sw = autoactive.Session(list.name);
sw.Gaitup = gaitup;
sw.video1 = video_old;
sw.video2 = video_new;
sw.source = source_obj;

sw.save(aw)
aw.close()




