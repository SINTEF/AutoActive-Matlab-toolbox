## How to build the AutoActive Matlab toolbox
This repository conatins files needed to make a Matlab toolbox for AutoActive
How to update the java jar file
There is two java projects that contributes to the toolbox.
1) The main project java-file-interface, located in the folder Java.
2) A renamed version of Apache Commons Compress (org.apache.commons.compress2) to avoid version conflicts in Matlab installation, located in the folder Compress2
1) Open the maven projects in NetBeans using JDK 1.8.
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
   Physilog5MatlabToolKit_vx_y_z with all files to MatlabToolbox\external (included in the toolbox from version 2.1, currently not available from GaitUp)
3) Update the Matlab toolkit source code with any changes
4) Update the version information in 'MatlabToolbox/+autoactive/MatlabVersion.m'
5) Start Matlab R2022a and make autoactive-matlab-toolbox active folder
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

