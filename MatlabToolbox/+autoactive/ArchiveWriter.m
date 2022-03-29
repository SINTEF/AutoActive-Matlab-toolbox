classdef ArchiveWriter < handle & autoactive.archive.Tracer

    properties
        path
    end
    
    properties (Access = private)
        JavaWriter
		isOpen
    end
    
    methods(Static)
        function ret = isLegalPath(str)
            ret = true;
            try
                java.io.File(str).toPath;
            catch
                ret = false;
            end
        end
    end
         
    
    methods
        function obj = ArchiveWriter(path)
            newpath = fullfile(pwd, path);
            if ~obj.isLegalPath(newpath)
                newpath = path;
                if ~obj.isLegalPath(newpath)
                    error("Error: Illegal archive path: '%s'", path);
                end
            end
                
            fprintf('ArchiveWriter <%s> - Open\n', path);
            obj.JavaWriter = no.sintef.autoactive.files.ArchiveWriter(newpath);
			obj.isOpen = true;
            obj.traceDisplay(true);
            
            obj.path = path;
        end
        
        function saveSession(obj, sessionHandle)
            sessionHandle.save(obj);
        end
        
        function filename = getFilename(obj)
            % Get the archive filename wo/path
            tmp = split(obj.path, '/');
            tmp = split(tmp(end), '\');
            tmp = tmp(end);
            filename = tmp{1};
        end
        
        function writeMetadata(obj, content, data)
            obj.trace(sprintf('Saving metadata <%s>\n', content));

            % Encode MATLAB datetimes to ISO8601 strings
            encoded = obj.metadataDatetimesEncode(data);
            % Convert MATLAB struct to JSON
            jsonstr = jsonencode(encoded);
            % Save in archive
            javaMethod('writeContentFromString', obj.JavaWriter, string(content), string(jsonstr));
        end
        
        function writeTextdata(obj, content, data)
            obj.trace(sprintf('Saving textdata <%s>\n', content));

            % Save in archive
            javaMethod('writeContentFromString', obj.JavaWriter, string(content), string(data));
        end
        
        function writeCopyContentFromFile(obj, content, path)
            obj.trace(sprintf('Saving data <%s> from <%s>\n', content, path));

            % Save in archive
            javaMethod('writeContentFromFile', obj.JavaWriter, string(content), string(path));
        end
        
        function writeTable(obj, content, data)
            obj.trace(sprintf('Saving table <%s>\n', content));
            
            % Find name and type of columns
            columns = length(data.Properties.VariableNames);
            names = strings(columns,1);
            types = strings(columns,1);
            for n=1:columns
                names(n) = string(data.Properties.VariableNames(n));
                colData = data{1,n};
                if isa(colData, 'int32')
                    types(n) = 'INT32';
                elseif isa(colData, 'int64')
                    types(n) = 'INT64';
                elseif isa(colData, 'single')
                    types(n) = 'FLOAT';
                elseif isa(colData, 'double')
                    types(n) = 'DOUBLE';
                elseif isa(colData, 'string')
                    types(n) = 'UTF8';
                else
                    warning('Unknown column type')
                end
            end
            
            % Create the Parquet table
            javaTable = no.sintef.autoactive.matlab.TableWriter(names, types, height(data));
            
            % Write columns
            for n=1:columns
                switch types(n)
                    case 'INT32'
                        javaMethod('writeIntColumn', javaTable, names(n), data{:,n});
                    case 'INT64'
                        javaMethod('writeLongColumn', javaTable, names(n), data{:,n});
                    case 'FLOAT'
                        javaMethod('writeFloatColumn', javaTable, names(n), data{:,n});
                    case 'DOUBLE'
                        javaMethod('writeDoubleColumn', javaTable, names(n), data{:,n});
                    case 'UTF8'
                        javaMethod('writeStringColumn', javaTable, names(n), data{:,n});
                end
            end
            
            % Close table, and write it to the archive
            javaMethod('close', javaTable);
            javaMethod('writeToArchive', javaTable, obj.JavaWriter, string(content));
        end
        
        function close(obj)
		
			if obj.isOpen
				obj.trace(sprintf('ArchiveWriter <%s> - Closing\n', obj.path));
				javaMethod('close', obj.JavaWriter);
				obj.isOpen = false;
			end
        end
        
        function delete(obj)
            obj.close();
        end
    end
    
    methods (Access = private)
        function encoded = metadataDatetimesEncode(obj, data)
            
            if (isdatetime(data))
                % Add local timezone if none is specified in value
                if (isempty(data.TimeZone))
                    data = datetime(data,'TimeZone','local');
                end
                % Create new datetime with correct format
                data = datetime(data, 'Format', autoactive.archive.Constants.ISO8601DateTimeFormat);
                % Format as string
                data = char(data);
            elseif (isstruct(data))
                for j = 1:numel(data)
                    for fieldcell = fieldnames(data)'
                        fieldname = char(fieldcell);

                        % Do conversion recursively
                        data(j).(fieldname) = obj.metadataDatetimesEncode(data(j).(fieldname));
                    end
                end
            end
            encoded = data;
            
        end
    end
end

