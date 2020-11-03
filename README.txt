AutoActive Matlab toolbox
=========================

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

How to update the MatlabToolbox
1) Code to be included is located in the 'MatlabToolbox' folder
2) Download Gaitup Matlab ToolKit for Physilog®5 from https://research.gaitup.com/support/ and uncompress and copy the folder 
   Physilog5MatlabToolKit_vx_y_z with all files to MatlabToolbox\external
3) Update the Matlab toolkit source code with any changes
4) Update the version information in 'MatlabToolbox/+autoactive/MatlabVersion.m'
5) Start Matlab R2018b and make autoactive-matlab-toolbox active folder

--> ok hit

5) Right-click on folder MatlabToolbox and select 'Add to Path => Selected Folders and Subfolders'
6) Open the 'Package toolbox app' by double click on project file 'AutoActive.prj'
7) Update version information
8) Check that MATLAB path has nine entries + examples, remove .../help_p_files
9) Check that Java Class Path has one correct jar entry
10) Create package in menu 'Package => Package'
11) Save project in meny 'Save => Save'
12) Rename and copy release package to AutoActive Konsortium WP2 Software release workplace
13) Update ChangeLog in workspace
14) Commit changes in autoactive-matlab repository
14) Tag project in Stash with version number

How to install the toolbox in GUI
1) Open Matlab
2) Locate the folder with the file 'AutoActive.mltbx' and make it current folder in Matlab
3) Double click the file to install it.

How to install the toolbox in GUI
1) Open Matlab
2) Find the location of the .mltbx file 
3) Put the path into a string 
   tboxFile = 'C:\Users\...\...\autoactive-matlab\AutoActive.mltbx'
4) Install the toolbox 
   matlab.addons.toolbox.installToolbox(tboxFile)
