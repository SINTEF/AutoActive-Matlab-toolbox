# AutoActive Matlab toolbox
Updated 18 May 2021

SINTEF - https://www.sintef.com

## License
Apache License Version 2.0

## Description
AutoActive Research Environment Toolbox provides support for writing and reading AutoActive Archives (AAZ) of multiple sensor data and video records. The toolbox also includes support for data import from different sensor types (e.g. Garmin, GaitUp, Catapult) and formats (e.g. gpx, csv). 

AAZ archives can be created, viewed and synchronized in ActivityPresenter, and can be read and written in MATLAB and ActivityPresenter as well as Python. The AutoActive Research Environment Toolbox provides the connection between ActivityPresenter used for data exploration/viewing/time synchronization and MATLAB used for data pre- and postprocessing and data analysis.   

The toolbox uses ArchiveWriter and ArchiveReader to write and read AAZ archives, respectively. The toolbox supports the transformations necessary for converting between MATLAB formats and the AAZ storage formats, its behavior is like a struct element when using it in a MATLAB script. The toolbox is plugin based which means that the user can easly extend the toolbox to support their own use-cases by adding custom plugins. 

## System Requirements
AutoActive Research Environment Toolbox requires a Matlab version r2018b or newer.

The ffmpeg toolbox is required for synchromizing multiple videos within an archive, please see "MultipleVideoSync" documentation.

## Features
- Import of sensor data from multiple sensor types and formats including videos
- Read and write AAZ archives from/to ActivityPresenter
- Convertion between AAZ formats and MATLAB formats
- Merging of data and video from multiple sensor systems for time synchronziation and data analysis/viewing

## Examples
Multiple examples are given in the GettingStarted section in the Matlab toolbox.

## How to build the AutoActive Matlab toolbox
This repository conatins files needed to make a Matlab toolbox for AutoActive
How to update the java jar file
There is two java projects that contributes to the toolbox.
  The main project java-file-interface.
     Located in the folder Java
  A renamed version of Apache Commons Compress (org.apache.commons.compress2) to avoid version conflicts in Matlab installation.
     Located in the folder Compress2
1) Open the maven projects in NetBeans, Eclipse or similar
2) Build the Compress2 project without running the tests. 
     Select Tools->Options->Java->Maven : Check "Skip tests for any build executors not directly releated to testing"
     Avoid doing changes to source code. This should be a clean renamed copy.
3) Open the project in the java folder ('java-file-interface')
4) Update the version information in file 'Version.java' and 'pom.xml' if any update.
5) Build the java-file-interface project
6) Remove any old jar file in 'MatlabToolbox/jar' directory
7) Copy the new jar file 'Java/target/java-file-interface....jar-with-dependencies.jar' to 'MatlabToolbox/jar' directory

## How to update the MatlabToolbox
1) Code to be included is located in the 'MatlabToolbox' folder
2) Download Gaitup Matlab ToolKit for Physilog®5 from https://research.gaitup.com/support/ and uncompress and copy the folder 
   Physilog5MatlabToolKit_vx_y_z with all files to MatlabToolbox\external
3) Update the Matlab toolkit source code with any changes
4) Update the version information in 'MatlabToolbox/+autoactive/MatlabVersion.m'
5) Start Matlab R2018b and make autoactive-matlab-toolbox active folder
6) Right-click on folder MatlabToolbox and select 'Add to Path => Selected Folders and Subfolders'
7) Open the 'Package toolbox app' by double click on project file 'AutoActive.prj'
8) Update version information
9) Check that MATLAB path has eight entries + examples, (remove .../help_p_files if any)
10) Check that Java Class Path has one correct jar entry
11) Create package in menu 'Package => Package'
12) Save project in meny 'Save => Save'
13) Rename and copy release package for distribution
14) Update ChangeLog file
15) Commit changes in autoactive-matlab-toolbox repository
16) Tag project with version number in git

## How to install the Matlab toolbox in the Matlab GUI
1) Open Matlab
2) Locate the folder with the file 'AutoActive.mltbx' and make it current folder in Matlab
3) Double click the file to install it.

## How to install the Matlab toolbox without using the Matlab GUI
1) Open Matlab
2) Find the location of the .mltbx file 
3) Put the path into a string 
   tboxFile = 'C:\Users\...\...\autoactive-matlab\AutoActive.mltbx'
4) Install the toolbox 
   matlab.addons.toolbox.installToolbox(tboxFile)
