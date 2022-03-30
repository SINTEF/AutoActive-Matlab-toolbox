classdef ArchiveReader < handle & autoactive.archive.Tracer
    
    properties
        path
        contents
    end
    
    methods
        function obj = ArchiveReader(path)
            newpath = fullfile(pwd, path);
            if ~isfile(newpath)
                newpath = path;
                if ~isfile(newpath)
                    error("Error: The archive '%s' was not found", path);
                end
            end
                
            obj.path = newpath;
            obj.traceDisplay(true);
            obj.contents = obj.getContents();
        end
        
        function filename = getFilename(obj)
            % Get the archive filename wo/path
            tmp = split(obj.path, '/');
            tmp = split(tmp(end), '\');
            tmp = tmp(end);
            filename = tmp{1};
        end
        
        function list = checkCrc(obj)
            list = struct();
            fileCount = 0;
             
            obj.trace(sprintf('Checking files in archive <%s>\n', obj.path));

            % Read from archive
            jr = autoactive.archive.JavaReader(obj.path);
            fileNames = javaMethod('getContents', jr.jobj);
            iter = fileNames.iterator();
            while iter.hasNext()
                fileCount = fileCount + 1;
                
                fileName = iter.next();
                crcOk = javaMethod('checkCrc', jr.jobj, fileName);
                chkStr = 'Check ok ';
                if ~crcOk
                    chkStr = 'Check failed ';
                end
                    
                obj.trace(sprintf('   <%s> File:<%s>\n', chkStr, fileName));
                
                list(fileCount).fileName = fileName;
                list(fileCount).crcOk = crcOk;
            end
            obj.trace('Done');
            
        end
        
        function list = listSessions(obj)
            list = struct();
            sessionCount = 0;
            entries = obj.contents;
            for i = 1:length(entries)
                filePath = entries{i};
                filePathElems = split(filePath,'/');

                if strcmp(filePathElems{2}, autoactive.Session.sessionFilename)
                    % Found a session metadata file
                    sessionCount = sessionCount + 1;
                    
                    list(sessionCount).id = filePathElems{1};
                    % Find the session name
                    da = obj.readMetadata(filePath);
                    list(sessionCount).name = da.user.name;

                    % list(sessionCount)
                end
            end
        end
        
        function sd = openSession(obj, sessionInfo, id)
            if isa(sessionInfo, 'struct')
                si = sessionInfo;
            elseif isa(sessionInfo, 'char')
                si = struct();
                si.id = '';
                si.name = sessionInfo;
            else
                error('Cannot interpret sessionInfo');
            end
            
            if exist('id','var')
                si.id = id;
            end
            
            loadedSession = false;
            list = obj.listSessions();
            for i = 1:length(list)
                idMatch = false;
                nameMatch = false;
                if isempty(si.id)
                    % No id given ... take any
                    idMatch = true;
                else
                    if strcmp(si.id, list(i).id)
                        idMatch = true;
                    end
                end

                if isempty(si.name)
                    % No name given ... take any
                    nameMatch = true;
                else
                    if strcmp(si.name, list(i).name)
                        nameMatch = true;
                    end
                end

                if idMatch && nameMatch
                    if ~loadedSession
                        % First match
                        loadedSession = true;

                        % Read the complete session 
                        sd = autoactive.Session();
                        sd = sd.load(list(i), obj);
                    else
                        assert(false, 'There are several sessions with the same name in this archive. Specify session using id');
                    end
                end
                
            end
            assert(loadedSession, 'Cannot find session. Use autoactive.ArchiveReader.listSessions() to find available sessions');
        end
            
            
        
        function data = readMetadata(obj, content)
            obj.trace(sprintf('Loading metadata <%s>\n', content));

            % Read from archive
            jr = autoactive.archive.JavaReader(obj.path);
            jsonstr = javaMethod('getContentAsString', jr.jobj, string(content));
            % Convert JSON to MATLAB struct
            encoded = jsondecode(char(jsonstr));
            % Decode MATLAB datetimes from ISO8601 strings
            data = obj.metadataDatetimesDecode(encoded);
        end
        
        function data = readTextdata(obj, content)
            obj.trace(sprintf('Loading textdata <%s>\n', content));

            % Read from archive
            jr = autoactive.archive.JavaReader(obj.path);
            data = javaMethod('getContentAsString', jr.jobj, string(content));
        end
        
        function bool = readCopyContentToFile(obj, content, path)
            obj.trace(sprintf('Copying data <%s> to <%s>\n', content, path));

            % Read from archive
            jr = autoactive.archive.JavaReader(obj.path);
            bool = javaMethod('copyContentToFile', jr.jobj, string(content), string(path));
        end
        
        function data = readTable(obj, content)
            obj.trace(sprintf('Loading table <%s>\n', content));
            
            % Open the content as a file
            jr = autoactive.archive.JavaReader(obj.path);
            javaContent = javaMethod('getContent', jr.jobj, string(content));
            
            % Parse the content as table
            javaTable = no.sintef.autoactive.matlab.TableReader(javaContent);
            
            % Get column names
            columns = string(javaMethod('getColumnNames', javaTable));
            types = strings(size(columns));
            
            % Create the MATLAB table
            data = table();
            
            % Add all the columns
            for n=1:length(columns)
                types(n) = javaMethod('getColumnType', javaTable, columns(n));
                charname = char(columns(n));
                switch types(n)
                    case 'INT32'
                        data.(charname) = javaMethod('getIntColumn', javaTable, columns(n));
                    case 'INT64'
                        data.(charname) = javaMethod('getLongColumn', javaTable, columns(n));
                    case 'FLOAT'
                        data.(charname) = javaMethod('getFloatColumn', javaTable, columns(n));
                    case 'DOUBLE'
                        data.(charname) = javaMethod('getDoubleColumn', javaTable, columns(n));
                    case 'UTF8'
                        data.(charname) = javaMethod('getStringColumn', javaTable, columns(n));
                    otherwise
                        warning('Unknown column type')
                end
            end
        end

        function delete(obj)
            % Nothing to do
        end
    end
    
    methods (Access = private)
        function content = getContents(obj)
            jr = autoactive.archive.JavaReader(obj.path);
            contentSet = javaMethod('getContents', jr.jobj);
            % Convert to Matlab string array
            l = javaMethod('size', contentSet);
            contentList = javaMethod('toArray', contentSet, javaArray('java.lang.String', l));
            content = string(contentList);
        end
        
        function decoded = metadataDatetimesDecode(obj, data)

            if (ischar(data) && ~isempty(data))
                % Could be a ISO8601 datetime string
                try
                    data = datetime(data, 'InputFormat', autoactive.archive.Constants.ISO8601DateTimeFormat, 'TimeZone', 'local');
                catch
                end
            elseif (isstruct(data))
                for j = 1:numel(data)
                    for fieldcell = fieldnames(data)'
                        fieldname = char(fieldcell);

                        % Do conversion recursively
                        data(j).(fieldname) = obj.metadataDatetimesDecode(data(j).(fieldname));
                    end
                end
            end
            % Save decoded (or originial) values to output struct
            decoded = data;
        end
        
    end
end

