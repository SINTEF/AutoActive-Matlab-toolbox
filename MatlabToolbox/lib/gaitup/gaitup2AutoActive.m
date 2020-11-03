classdef gaitup2AutoActive<handle
    properties
    fName ='';
    sensorData = [];
    gaitup2autoactiveStruct = [];
    
    dataFolder = '';
    end
    
    methods
        function obj = gaitup2AutoActive(dataFolder,deciredFreq)
            [sensorData] = obj.getGaitup(dataFolder,deciredFreq);            
            obj.sensorData = sensorData;    
            obj.dataFolder = dataFolder;
            obj.gaitup2autoactiveStruct = obj.gaitup2autoactive();
        end
            
         %% Matlab functions
        function [sensorData] = getGaitup(obj,dataFolder,deciredFreq)
           
            ImuFolder = dataFolder;           
            GaitUpFiles = dir([ImuFolder,'*.BIN']);
            fNames = {GaitUpFiles.name};
            openFiles = strcat(ImuFolder,fNames)';
            if length(openFiles) > 0
                try
                    [sensorData, header] = rawP5reader(openFiles(:),'sync');
                catch me
                    warning('could not load gaitup with <sync> ')
                    [sensorData, header] = rawP5reader(openFiles(:));
                end                                  
            else
                error(['cannot find *.BIN files in folder: ' dataFolder])
            end
        end
        
        function gaitup2autoactiveS = gaitup2autoactive(obj)        
            %re-organize and add units to the data
            metaL1 = {'header','filename','synchronized','longtermSynchronized'};
            ssN = {'corrected_timestamps','timestamps','data'};
            %unitM = containers.Map({19,20,21,25,26},{{'[g]','[g]','[g]'},{'[deg/s]','[deg/s]','[deg/s]'},{'hPa','C'},{'-'} ,{'-'}});
            unitM = containers.Map({19,20,21,25,26},{{'g','g','g'},{'deg/s','deg/s','deg/s'},{'hPa','C'},{'-'} ,{'-'}});
            for ss = 1:length(obj.sensorData)
                sens = ss;
                gaitupIMU = obj.sensorData(sens);
                gaitupIMUMeta = gaitupIMU.(metaL1{1});
                
                for i = 2:length(metaL1)
                    if isfield(gaitupIMU, metaL1{i})
                        gaitupIMUMeta = setfield(gaitupIMUMeta,metaL1{i},gaitupIMU.(metaL1{i}) );
                    end
                end
                gaitupIMUA(ss).meta = gaitupIMUMeta;
                
                % data and metadata sensor component
                
                for cT = 1:length(gaitupIMU.physilogData)
                    sType = cT;
                    ssRaw = gaitupIMU.physilogData(sType);
                    IMUComponent = ssRaw;
                    
                    sensDM =[];
                    varNames = {};
                    skipCount = 0;
                    for i = 1:length(ssN)
                        if isfield(ssRaw, ssN{i})
                            sensD = ssRaw.(ssN{i});
                            if isempty(sensD)
                                sensD = nan;
                            end
                        
                            sensDM = [sensDM sensD];
                            varN = repmat({[ssN{i},'_',ssRaw.name]},1,size(sensD,2) ) ;
                            aa = cellstr(num2str([1: length(varN) ]'));
                            varNames = [varNames strcat(varN',aa)'];
                            IMUComponent = rmfield(IMUComponent,ssN{i});
                        else
                            skipCount = skipCount + 1;
                        end
                    end

                    % Compensate for skipped column 'corrected_timestamps'
                    if skipCount == 0
                        units = [{'s', 's'}, unitM(ssRaw.type)];
                    else
                        units = [{'s'}, unitM(ssRaw.type)];
                    end
                    
                    tt = array2table(sensDM,'VariableNames',varNames);
                    if length(units) ==  length(varNames)
                        tt.Properties.VariableUnits = units;
                    end
                    IMUComponent = setfield(IMUComponent,'units',units);
                    IMUComponent = setfield(IMUComponent,'data',tt);
                    
                    gaitupIMUA(ss).ComponentData(cT) = IMUComponent;
                end
            end
            gaitup2autoactiveS = gaitupIMUA;
        
        end
        
        
        %% TODO Python tools, matlab - python - autoactive format        
        function datR = makeMatlabTabs(obj)
            ll =  length(obj.sensorData);
            datR = cell(ll,2);
            
            for ii =1:ll
                datT = cell(1,3);
                for jj = 1:length(datT)
                    dtt = obj.sensorData(ii).physilogData(jj);
                    dat = dtt.data;
                    tim = dtt.corrected_timestamps;
                    tabCont = [tim dat];
                    
                    varNames = {'timestamp'};
                    aa = num2str([1: length(dat(1,:)) ]');
                    C = cellstr(aa);
                    C2 = strcat(dtt.name,C);
                    varNames = [varNames; C2]';
                    tt = array2table(tabCont,'VariableNames',varNames) ;                 
                    datT{jj} = tt;
                end
                datR(ii,1) = {obj.sensorData(ii).header.bodyLocation};
                datR{ii,2} = datT;
            end            
        end  
        
        function write2parquet(obj,fileName)        
           dat =  obj.makeMatlabTabs();
           
           for i = 1:1           
               for j = 1:1
                   tabData = [];
                   for k = 1:1
                      tabData = dat{i,2}{j}{:,k};
                       varName = dat{i,2}{j}.Properties.VariableNames{k};
                   end
                   tabName = dat{i,2}{j}.Properties.VariableNames{end}(1:end-1);                   
               end
           end
           
        end
            
        function dat = collectTypeData(obj,sensor,type)
            
            dat = ([obj.sensorData(sensor).physilogData.type]==type)
            
            
           % obj.sensorData.()
%             
%             for i = 1:length(sensorData)
%                 pDat = sensorData(i).physilogData;
%                 pressTempDat = [];
%                 accGyrDat = [];
%             end
            
            
        end
        
        function addPythonLib(obj,pyFolder)
            comDir = pyFolder;
            fN = split(comDir,'\');
            pythonPath = [strjoin(fN(1:end),filesep),filesep,'Python' ] ;
            
            if count(py.sys.path,pythonPath) == 0    
                insert(py.sys.path,int32(0),pythonPath);
            end
            % test a local module
%             mod = py.importlib.import_module('devWritePa');
%             py.importlib.reload(mod);
        end
                        
    end
    
    
end
