classdef garmin2AutoActive<handle
    %GARMIN2AUTOACTIVE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensorData = [];
        garmin2autoactiveStruct = [];
        dataFolder = '';
    end
    
    methods
        function obj = garmin2AutoActive(dataFolder)
            obj.sensorData = obj.getGarmin(dataFolder);
            obj.garmin2autoactiveStruct = obj.garmin2autoactive();
            obj.dataFolder = dataFolder;
        end
        
        function [gpsS] = getGarmin(obj,dataFolder)
            
            gpSS = dir([dataFolder,'*.tcx']);
            GpsFiles = {gpSS.name};
            gpsS = [];
            for i= 1:length(GpsFiles)
                GpsFile = [dataFolder, GpsFiles{i}];
                %temp = struct (setupGarminData([],GpsFile));
                temp = obj.obj2struct (setupGarminData([],GpsFile));
                
                temp.name = GpsFiles{i}(1:end-4);
                temp.filename = GpsFile;
                gpsS = [gpsS temp];
            end
            
        end
        
        function garmin2autoactiveS = garmin2autoactive(obj)
            %garmin2autoactiveS = [];
            for i = 1:length(obj.sensorData)
                
                gpsS = obj.sensorData(i);
                garmin2autoactiveS(i).meta.filename = gpsS.filename;
                
                varNamsT = (['posixTime [ms]' gpsS.tcxNames])';
                varNamsT = split(varNamsT,' ') ;
                varNams = varNamsT(:,1)';
                unitNams = varNamsT(:,2)';
                
                tt = array2table([gpsS.tcxTime gpsS.tcxData],'VariableNames',varNams);
                tt.Properties.VariableUnits = unitNams;
                % gpsDatTT = [gpsDatTT {tt}];
                
                garmin2autoactiveS(i).ComponentData.name = gpsS.name;
                garmin2autoactiveS(i).ComponentData.units = unitNams;
                garmin2autoactiveS(i).ComponentData.data = tt;
            end
        end
        
        
        %% tool
        % can also use struct directly on the object... throws a warning
        function output_struct = obj2struct(obj,object)
            properties = fieldnames(object);
            for i = 1:length(properties)
                val = object.(properties{i});
                output_struct.(properties{i}) = val;
            end
        end
        
        
        
    end
end
    
