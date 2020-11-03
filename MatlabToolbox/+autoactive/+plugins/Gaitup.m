classdef Gaitup < autoactive.archive.Dataobject
    
    properties (Access = protected, Constant)
        type = 'no.sintef.gaitup'
        version = 1
    end
    
    methods 
        function this = loadFilesToFolder(this, dataFolder)

            disp( 'start reading gaitup data')
            %% get gaitup data
            gaitupObj = gaitup2AutoActive(dataFolder,[]);
            
            %% reorganize the data
            gaitup2autoactiveS = gaitupObj.gaitup2autoactive();
            
            disp( 'done reading gaitup data')
            

            disp( 'start organizing gaitup data')
            
            for jj = 1: length(gaitup2autoactiveS)
                sensor = jj;    
                sensorId = split(gaitup2autoactiveS(sensor).meta.filename,'\'); % there is a tag for this, but seems to be more info in the filename
                sensorId = sensorId{end}(1:end-4);

                % Write metadata
                inMeta = gaitup2autoactiveS(sensor).meta;
                tabNMeta = ['sensor',sensorId, '/info'];          
                this = this.addElem(tabNMeta, inMeta);
                
                %curr_time = datetime;
                %curr_epoch = posixtime(curr_time);

                for i = 1:length(gaitup2autoactiveS(sensor).ComponentData)
                    % data table
                    intable = gaitup2autoactiveS(sensor).ComponentData(i).data;
                    timetab = intable(:,1);
                    timetab.Properties.VariableNames = {'time'};
                    timetab.time = int64(timetab.time * 1000000);

                    intableTime = [timetab intable];
                    tabN = ['sensor',sensorId,'/',...
                        gaitup2autoactiveS(sensor).ComponentData(i).name];          
                    
                    % Add units to the table
                    unitN = gaitup2autoactiveS(sensor).ComponentData(i).units;
                    unitN = ['us' unitN];
                    colNames = intableTime.Properties.VariableNames;
                    for cni = 1:length(colNames)
                        intableTime.Properties.VariableUnits{colNames{cni}} = unitN{cni};
                    end

                    userdata = struct();
                    userdata.is_world_clock = false;
                    % userdata.index = {intableTime.Properties.VariableNames{1}};
                    % userdata.offset = 0;
                    intableTime.Properties.UserData = userdata;

                    this = this.addElem(tabN, intableTime);
                end    
            end
            
            disp( 'done organizing gaitup data')

        end
        
        %function table = getTable(this, tableName)
        %    table = this.user.data.(tableName);
        %end
        
        %function nameArr = listTableNames(this)
        %    nameArr = cell(0);
        %    elems = this.listElemSub('');
        %    count = 1;
        %    for i = 1:length(elems)
        %        elem = elems(i);
        %        if strcmp(elem.type, 'table')
        %            nameArr{count} = elem.name;
        %            count = count + 1;
        %        end
        %    end
        %end
        
    end
    
    
end