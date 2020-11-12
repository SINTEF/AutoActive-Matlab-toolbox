classdef setupGarminData<handle
    
    properties
        IDTest = 0;
        tcxNames = {'dist m','altitude m','latitude deg','longitude deg','HR bpm','speed m/s'};
        dateFormat = 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX'
        tcxData = [];
        tcxTime = [];
    end
    
    methods
        function obj = setupGarminData(testIDString,tcxFile)
            %             if strcmp(testIDString,'Meraker2017' )
            %                 obj.IDTest = 2;
            %                 obj.dateFormat = 'yyyy-MM-dd''T''HH:mm:ssXXX';
            %
            %             elseif strcmp(testIDString,'ISense2017' )
            %                 obj.IDTest = 1;
            %                 obj.dateFormat = 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX';
            %             else
            %                 obj.IDTest = 0;
            %                 obj.dateFormat = 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX';
            %             end
            %             readGarminData(obj,tcxFile);
            
     
            
            formats = { 'yyyy-MM-dd''T''HH:mm:ss.SSSXXX','yyyy-MM-dd''T''HH:mm:ssXXX'};
            for i = 1:2
                oldI = obj.IDTest;
                oldF = obj.dateFormat;
                try
                    obj.IDTest = i;
                    obj.dateFormat = formats{i};
                    readGarminData(obj,tcxFile);
                catch
                    obj.IDTest =oldI;
                    obj.dateFormat = oldF;
                    disp('testing two GPS formats')
                end
            end
        end
        
        function files = getFiles(obj,folder)
            tcxFiles = dir([folder,'*.tcx']);
            fNames = {tcxFiles.name};
            openFiles = strcat(floder,fNames)';
        end
        
        %% read data
        function readGarminData(obj,gpsFile)
            tcxdat = tinyxml2_wrap('load', gpsFile);
            
            if obj.IDTest == 2
                tcxDatSC = tcxdat.Courses.Course;
            elseif (obj.IDTest == 1)||(obj.IDTest == 0)
                tcxDatSC = [tcxdat.Activities.Activity.Lap]; %assuming only one lap
            end
            
            % Read the data
            % distanse should be available tcxDatS.Track(i).Trackpoint.DistanceMeters,...
            tempC = {};
            tempCVel = {};
            for mm= 1:length(tcxDatSC)
                tcxDatS = tcxDatSC(mm);
                for i = 1:length(tcxDatS.Track)
                    try
                        % check if HrVal
                        if isfield(tcxDatS.Track(i).Trackpoint,'HeartRateBpm')
                            hrVal = tcxDatS.Track(i).Trackpoint.HeartRateBpm.Value;
                        else
                            hrVal = '0';
                        end
                       
                        
                        temp = {...
                            tcxDatS.Track(i).Trackpoint.Time,...
                            tcxDatS.Track(i).Trackpoint.AltitudeMeters,...
                            tcxDatS.Track(i).Trackpoint.Position.LatitudeDegrees,...
                            tcxDatS.Track(i).Trackpoint.Position.LongitudeDegrees,...
                            hrVal};
                        tempC = [tempC;temp];
                        
                        if isfield(tcxDatS.Track(i).Trackpoint,'DistanceMeters')
                            %names with : makes anoying syntax 
                            speedS = getfield(tcxDatS.Track(i).Trackpoint.Extensions,'ns3:TPX'); 
                            speed = getfield(speedS,'ns3:Speed');
                            
                            temp2 ={... 
                            tcxDatS.Track(i).Trackpoint.Time,...
                            tcxDatS.Track(i).Trackpoint.DistanceMeters,...
                            speed};
                         tempCVel = [tempCVel;temp2];
                        end 
                    catch e
                        disp('missingDats')
                    end
                end
            end
            
            t = datetime(tempC(:,1),'InputFormat',obj.dateFormat,'TimeZone','UTC');
            tcxTime = posixtime(t)*1000;
            % discard nonunique times
            [C,ia,ic] = unique(tcxTime);
            tcxTime = tcxTime(ia);
            tcxData = str2double(tempC(ia,2:end));
            
            if length(tempCVel)==length(t)
                distSpeed = str2double(tempCVel(ia,2:end));
                tcxData = [distSpeed(:,1), tcxData, distSpeed(:,2) ];
            else
                
                %distance calculation'
                LMuGH = [tcxData(:,[3,2])*pi/180 tcxData(:,1)]; %radian methods
                
                distCalc = calcDist(obj, LMuGH);
                tcxData = [distCalc,tcxData];
                
                % speed calculation
                dt = (tcxTime(2:end)-tcxTime(1:end-1))/1000;
                speed = (tcxData(2:end,1)-tcxData(1:end-1,1))./dt;
                tcxData = [tcxData,[0;speed]];
            end
            
            
            obj.tcxTime = tcxTime;
            obj.tcxData = tcxData;
        end
        
        %% Coordinate methods
        function distCalc = calcDist(obj, LMuGH)
            
            init = repmat(LMuGH(1,:),length(LMuGH(:,1)),1 );
            % simple window filter (3 sampels)
            b = [0.2 0.6 0.2];
            a = 1;
            DLMuGH = filter(b,a,LMuGH - init);
            LMuGH = DLMuGH + init;
            
            XYZ = llh2ecef(obj,LMuGH);
            DXYZ = diff(XYZ);
            ddist = sqrt(sum(DXYZ.^2,2));
            ddist(ddist<0.2) =0;
            distCalc = [0;cumsum(ddist)];
            
        end
        
        function XYZ = llh2ecef(obj,LMuGH)
            %based on fossens mss
            
            l = LMuGH(:,1);%long
            mu = LMuGH(:,2);%lat
            h = LMuGH(:,3);
            
            r_e = 6378137; % WGS-84 data
            r_p = 6356752;
            e = 0.08181979099211;
            
            N = r_e^2./sqrt( (r_e*cos(mu)).^2 + (r_p*sin(mu)).^2 );
            N = N(:);
            
            x = (N+h).*cos(mu).*cos(l);
            y = (N+h).*cos(mu).*sin(l);
            z = (N.*(r_p/r_e).^2 + h).*sin(mu);
            
            XYZ = [x,y,z];
        end
        
    end
    
end

