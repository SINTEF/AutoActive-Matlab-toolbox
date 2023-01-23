# AutoActive Matlab toolbox
Updated 23 January 2023

SINTEF - https://www.sintef.com

## License
Apache License Version 2.0

## Description
AutoActive Research Environment Toolbox provides support for writing and reading AutoActive Archives (AAZ) of multiple sensor data and video records. The toolbox also includes support for data import from different sensor types (e.g. Garmin, GaitUp, Catapult) and formats (e.g. gpx, csv). Annotations is supported to mark specific part of video and data and is useful as input for machine learning and data analysis.

AAZ archives can be created, viewed and synchronized in ActivityPresenter, and can be read and written in MATLAB and ActivityPresenter as well as Python. The AutoActive Research Environment Toolbox provides the connection between ActivityPresenter used for data exploration/viewing/time synchronization and MATLAB used for data pre- and postprocessing and data analysis.   

The toolbox uses ArchiveWriter and ArchiveReader to write and read AAZ archives, respectively. The toolbox supports the transformations necessary for converting between MATLAB formats and the AAZ storage formats, its behaviour is like a struct element when using it in a MATLAB script. The toolbox is plugin based which means that the user can easily extend the toolbox to support their own use-cases by adding custom plugins. 

## System Requirements
AutoActive Research Environment Toolbox requires a Matlab version r2018b or newer.

The ffmpeg toolbox is required for synchronizing multiple videos within an archive, please see "MultipleVideoSync" documentation in the toolbox.

## Features
- Import of sensor data from multiple sensor types and formats including videos
- Read and write AAZ archives from/to ActivityPresenter
- Conversion between AAZ formats and MATLAB formats
- Merging of data and video from multiple sensor systems for time synchronization and data analysis/viewing
- Adding annotations to datasets, see examples

## Examples
Multiple examples are given in the GettingStarted section in the Matlab toolbox.
Examples can also be found online here:

https://github.com/SINTEF/AutoActive-Matlab-toolbox/tree/master/MatlabToolbox/examples

A comprehensive example with cross country skiing data is documented here:

https://www.sintef.no/projectweb/autoactive/code-example/

## Download and install the AutoActive Matlab toolbox
A binary distribution of the Matlab toolbox can be downloaded as an "Asset" for the releases at the toolbox Github page:

https://github.com/SINTEF/AutoActive-Matlab-toolbox

Open the ".mltbx" file in Matlab to install the toolbox.