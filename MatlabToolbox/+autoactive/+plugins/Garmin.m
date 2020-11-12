classdef Garmin < autoactive.archive.Dataobject
    
    properties (Access = protected, Constant)
        type = 'no.sintef.garmin'
        version = 1
    end
    
    methods 
        function this = loadFile(this, dataFolder, fileName)

            GpsFile = [dataFolder, fileName];
            gpsS = setupGarminData([],GpsFile);

            varNamsT = (['time us' 'posixTime ms' gpsS.tcxNames])';
            varNamsT = split(varNamsT,' ') ;
            varNams = varNamsT(:,1)';
            unitNams = varNamsT(:,2)';
            aaTime = this.convEpochMsToAaTime(gpsS.tcxTime);
            % Import as separate tables because the arrays have different data types
            intable_1 = array2table(aaTime,'VariableNames',varNams(1));
            intable_2 = array2table(gpsS.tcxTime,'VariableNames',varNams(2));
            intable_3 = array2table(gpsS.tcxData,'VariableNames',varNams(3:end));
            intable = [intable_1 intable_2 intable_3];
            intable.Properties.VariableUnits = unitNams;
            disp( 'done reading garmin data')

            disp( 'start organizing garmin data')
            % write garimin files

            userdata = struct();
            userdata.is_world_clock = true;
            %userdata.index = {intable.Properties.VariableNames{1}};
            %userdata.offset = 0;
            intable.Properties.UserData = userdata;

            this.user.full_table = intable;
            this.user.filename = fileName;
            this.user.data_folder = dataFolder;
            disp( 'done organizing garmin data')

        end
        
        function aaFolder = loadFilesToFolder(this, dataFolder)

            aaFolder = autoactive.Folder();
            
            %% Find files
            gpSS = dir([dataFolder,'*.tcx']);
            GpsFiles = {gpSS.name};
            
            for i= 1:length(GpsFiles)
                garminObj = this.loadFile(dataFolder, GpsFiles{i});
                tabN = GpsFiles{i}(1:end-4);
                aaFolder = aaFolder.addElem(tabN, garminObj);
            end

        end
    end
end
