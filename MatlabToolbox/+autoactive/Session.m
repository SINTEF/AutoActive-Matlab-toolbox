classdef Session < autoactive.archive.Dataobject & matlab.mixin.Copyable & handle
    properties
        sessionState
        basedOn
        archiveFilename
    end
    
    properties (Constant)
        sessionFilename = 'AUTOACTIVE_SESSION.json';
    end
    
    properties (Access = protected, Constant)
        type = 'no.sintef.session'
        version = 1

        sessionStateInit    = 1;
        sessionStateUpdated = 2;
        sessionStateSaved   = 3;
        sessionStateLoaded  = 4;
        sessionStateTextArr = {'Init' ,'Updated', 'Saved', 'Loaded'};
    end
    
    methods
        function this = Session(sessionName)
            this.meta.id = 'Not saved';
            this.user.created = datetime('now');
            this.sessionState = this.sessionStateInit;
            this.basedOn = containers.Map();
            this.archiveFilename = 'Not saved';
            
            if exist('sessionName','var')
                this.user.name = sessionName;
            else
                this.user.name = '';
            end
        end
        
        function id = getId(this)
            id = this.meta.id;
        end
        
        function text = sessionStateText(this)
            if this.sessionState < 1
                text = num2str(this.sessionState);
            elseif this.sessionState <= length(this.sessionStateTextArr)
                text = this.sessionStateTextArr{this.sessionState};
            else
                text = num2str(this.sessionState);
            end
            
        end
        
        function this = addBasedOn(this, sessionObj)
            assert(this.isLocked() == false, ...
                   ['ERROR - Cannot modify locked session with state: ' this.sessionStateText()]);
            
            assert(sessionObj.isLocked() == true, ... 
                   ['ERROR - Cannot reference session not in archive with state: ' this.sessionStateText()]);
               
            elem = struct();
            elem.id = sessionObj.meta.id;
            elem.name = sessionObj.name;
            elem.created = sessionObj.created;
            elem.archiveFilename = sessionObj.archiveFilename;
            this.basedOn(sessionObj.meta.id) = elem;
            
            this.sessionState = this.sessionStateUpdated;
        end
        
        function this = addElem(this, elemPath, elem)
            assert(this.isLocked() == false, ...
                   ['ERROR - Cannot modify locked session with state: ' this.sessionStateText()]);
            this = addElem@autoactive.archive.Dataobject(this, elemPath, elem);

            this.sessionState = this.sessionStateUpdated;
        end
        
        function this = save(this, archiveWriter)
            assert(this.isLocked() == false, ...
                   ['ERROR - Cannot save session with state: ' this.sessionStateText()]);
            
            % Prepare metadata
            this.meta.id = char(java.util.UUID.randomUUID());
            this.meta.based_on = this.basedOnMap2Array(this.basedOn);
            
            [platform, computername, username, addonstring, aaversion ] = this.locDisplayMatlabInformation();            
            this.meta.environment = struct();
            this.meta.environment.platform = platform;
            this.meta.environment.computername = computername;
            this.meta.environment.username = username;
            this.meta.environment.addons = addonstring;
            this.meta.environment.autoactive = aaversion;
            
            fprintf('Session <%s> - Writing data\n', this.user.name);
            
            % Reset caching of plugins assuring detection of new plugins
            autoactive.pluginregister.Register.reset();
            
            enrichedFolders = copy(this); % Make copy to keep replace natives invisible for this
            enrichedFolders = enrichedFolders.replaceNativesRec();
            jsonStruct = enrichedFolders.toJsonStructRec('',this.meta.id, archiveWriter);
            elemName = [this.meta.id '/' this.sessionFilename];
            archiveWriter.writeMetadata(elemName, jsonStruct);
            
            fprintf('Session <%s> - End\n', this.user.name);
            
            this.archiveFilename = archiveWriter.getFilename();
            this.sessionState = this.sessionStateSaved;
        end
        
        function this = load(this, sessionInfo, archiveReader)
            assert(this.isLocked() == false, ...
                ['ERROR - Cannot load into session with state: ' this.sessionStateText()]);
            
            this.meta.id = sessionInfo.id;
            this.user.name = sessionInfo.name;
            fprintf('Session <%s> - Reading data\n', this.meta.id);
            % Reset caching of plugins assuring detection of new plugins
            autoactive.pluginregister.Register.reset();

            filePath = [this.meta.id '/' this.sessionFilename];
            % Read the session metadata
            jsonStruct = archiveReader.readMetadata(filePath);

            
            % Check session format version
            sessionVersion = jsonStruct.meta.version;
            supportedVersion = false;
            
            if sessionVersion == this.version
                supportedVersion = true;
            end
            
            assert(supportedVersion, ...
                ['ERROR - Cannot load session with format version: ' sessionVersion]);
            
            
            
            this = this.fromJsonStructRec(jsonStruct ,this.meta.id , archiveReader);
            this = this.restoreNativesRec();

            % Fetch info from metadata
            this.archiveFilename = archiveReader.getFilename();
            this.basedOn = this.basedOnArray2Map(this.meta.based_on);

            fprintf('Session <%s> - End\n', this.meta.id);
            this.sessionState = this.sessionStateLoaded;
        end
        
        function delete(this)
        end
    end
    
    methods (Access = public, Hidden)
            % This is called by obj.* = *, obj(*) = *, and obj{*} = *
        function this = subsasgn(this, sub, value)
            assert(this.isLocked() == false, ...
                   ['ERROR - Cannot modify locked session with state: ' this.sessionStateText()]);

               this = subsasgn@autoactive.archive.Dataobject(this, sub, value);
            
            this.sessionState = this.sessionStateUpdated;
        end            
    end
    
    methods (Access = protected, Hidden)
        function boArr = basedOnMap2Array(~, boMap)
            k = keys(boMap);
            boArr = cell(length(k));
            for i = 1:length(k)
                boArr{i} = boMap(k{i});
            end
        end

        function boMap = basedOnArray2Map(~, boArrStruct)
            boMap = containers.Map();
            for i = 1:length(boArrStruct)
                boMap(boArrStruct(i).id) = boArrStruct(i);
            end
        end
        
    end
    
    
    methods (Access = private)

        % Method removed due to use of relative path
        %function prePath = prePath(this)
        %    %prePath = ['/' this.meta.id ];
        %    prePath = this.meta.id;
        %end
        function locked = isLocked(this)
            locked = (this.sessionState == this.sessionStateSaved) || ...
                   (this.sessionState == this.sessionStateLoaded);
        end
        
        function [platform, computername, username, addonstring, aaversion ] = locDisplayMatlabInformation(this)
            % LOCDISPLAYMATLABINFORMATION  Display general MATLAB installation
            % information as a header to the toolbox information section.
            
            %   Copyright 1984-2013 The MathWorks, Inc.

            % Find platform OS.
            platform = system_dependent('getos');
            if ispc
               platform = [platform, ' ', system_dependent('getwinsys')];
            elseif ismac
                [status, result] = unix('sw_vers');
                if status == 0
                    platform = strrep(result, 'ProductName:', '');
                    platform = strrep(platform, sprintf('\t'), '');
                    platform = strrep(platform, sprintf('\n'), ' ');
                    platform = strrep(platform, 'ProductVersion:', ' Version: ');
                    platform = strrep(platform, 'BuildVersion:', 'Build: ');
                end
            end
            
            computername = getenv('computername');
            username = getenv('username');

            % Construct header and display it.
            header = {sprintf('MATLAB %s: %s', getString(message('MATLAB:ver:Version')), version);
                      sprintf('MATLAB %s: %s', getString(message('MATLAB:ver:LicenseNumber')), license);
                      sprintf('%s: %s', getString(message('MATLAB:ver:OperatingSystem')), platform);
                      sprintf('Java %s: %s', getString(message('MATLAB:ver:Version')), version('-java'))};

            % Construct info about addons.
            addonstring = this.getAddonString();

            aaversion = sprintf('%s\n%s\n', autoactive.MatlabVersion, autoactive.JavaVersion);
        end
        
        function addonstring = getAddonString(this)
        
            addons = matlab.addons.installedAddons;
            addonstring = '';
            for i = 1:height(addons)
                addonstring = [ addonstring sprintf('%s   v%s\n', addons.Name(i), addons.Version(i))];
            end
        end
    
    end
end