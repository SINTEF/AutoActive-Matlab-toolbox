classdef Csvimport < autoactive.Folder
    
    methods 
        function epochMs = convHmssToEpochMs(this, hmss)
            len = length(hmss);
            epochMs = zeros(len,1);
            
            fprintf('Converting %d rows..', len);
            for i = 1 : len
                if rem(i,50000) == 0
                    fprintf('%d..', i);
                end
                % Expected character format 'M:S.SS' or 'H:M:S.SS'

                c_split = strsplit(hmss{i}, ':');
                c_split_len = length(c_split);
    
                if c_split_len == 2
                    h = 0;
                    m = str2double(c_split{1});
                    s = str2double(c_split{2});
                else
                    h = str2double(c_split{1});
                    m = str2double(c_split{2});
                    s = str2double(c_split{3});
                end
                epochMs(i) = ((h * 3600) + (m * 60) + s) * 1000;
            end
            fprintf('done\n');
        end
        
        function this = loadFile(this, dataFolder, fileName)

            fullPath = [dataFolder, fileName];
            disp( ['Reading file ' fileName ])
            rawTable = readtable(fullPath);
            fprintf('Found table with %d rows and %d columns.\n', size(rawTable, 1), size(rawTable, 2));
            
            if ismember('Time', rawTable.Properties.VariableNames)==true
                % Rename time column
                rawTable.Properties.VariableNames{'Time'} = 'String_time';
                % Calculate new time column in AutoActive format
                disp( 'Rename column Time to String_time')
                disp( 'Calulating new Time column')
                epochTime = this.convHmssToEpochMs(rawTable.String_time);
                time = this.convEpochMsToAaTime(epochTime);
                newTable = [table(time) rawTable]; 
            end
            
            disp( 'scanning csv data')
            
            % Text format is not supported in AutoActive tables
            % Remove colums with text format.
            colNames = newTable.Properties.VariableNames;
            for colNum = 1 : length(colNames)
                colName = colNames{colNum};
                colType = class(newTable.(colName));
                if strcmp(colType, 'cell')
                    display(['Removing text column: ' colName])
                    newTable.(colName) = [];
                else 
                    display(['Keeping column: ' colName ' type: ' colType] )
                end
            end
            
            % create userdata
            userdata = struct();
            userdata.is_world_clock = false;
            newTable.Properties.UserData = userdata;

            % place table in folder
            this.user.full_table = newTable;
            this.user.filename = fileName;
            this.user.data_folder = dataFolder;
            disp( 'done scanning csv data')
        end
        
        function aaFolder = loadFilesToFolder(this, dataFolder)

            aaFolder = autoactive.Folder();
            
            %% Find files
            files = dir([dataFolder,'*.csv']);
            file_names = {files.name};
            
            for i= 1:length(file_names)
                csvObj = this.loadFile(dataFolder, file_names{i});
                tabN = file_names{i}(1:end-4);
                aaFolder = aaFolder.addElem(tabN, csvObj);
            end

        end
    end
end
