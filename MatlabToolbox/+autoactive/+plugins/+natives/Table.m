classdef Table < autoactive.archive.Dataobject
    
    properties (Access = protected, Constant)
        type = 'no.sintef.table'
        version = 1
    end
    properties
        tab;
    end
    
    methods 
        % Wrapper method overloaded for native support
        function this = wrapNative(this, native)
            assert(isa(native, 'table'), ['ERROR Native wrapper does not support native class <' class(native) '>']);
            this.tab = native;
        end
        
        % Wrapper method overloaded for native support
        function bool = isNativeWrapper(~)
            bool = true;
        end

        % Wrapper method required for native support
        function native = unwrapNative(this)
            native = this.tab;
        end
        
    end
    
    methods (Access = protected, Hidden)
        function jsonStruct = toJsonStructRec(this, inPath, sessionId, archiveWriter)
            jsonStruct = struct();
            % Empty userdata
            jsonStruct.user = struct();
            
            % Table data is saved in separate file
            elemName = [inPath '.parquet'];
            %fprintf('Saving table to <%s>\n', elemName);
            archiveWriter.writeTable([sessionId elemName], this.tab)

            % Put all the table metadata into the returned json
            jsonStruct.meta = struct();

            % default values
            jsonStruct.meta.is_world_clock = false;

            ud = this.tab.Properties.UserData;
            fields = fieldnames(ud);
            for i = 1:numel(fields)
                fieldName = fields{i};
                jsonStruct.meta.(fieldName) = ud.(fieldName);
            end
            
            jsonStruct.meta.type = this.type;
            jsonStruct.meta.version = this.version;
            jsonStruct.meta.units = this.tab.Properties.VariableUnits;
            jsonStruct.meta.attachments = {elemName};
        end
        
        function this = fromJsonStructRec(this, jsonStruct, sessionId, archiveReader)
            % Check that we have what we need
            if (~isfield(jsonStruct, 'user') || ~isa(jsonStruct.user, 'struct'))
                throwAsCaller(MException('AA:BadJSON','user is missing from json.'));
            end
            if (~isfield(jsonStruct, 'meta') || ~isa(jsonStruct.meta, 'struct'))
                throwAsCaller(MException('AA:BadJSON','meta is missing from json.'));
            end
            
            % Load table data from separate file
            elemName = jsonStruct.meta.attachments;
            %fprintf('Loading table from <%s>\n', elemName);
            this.tab = archiveReader.readTable([sessionId elemName{1}]);
            
            % Put all the metadata into the table
            fields = fieldnames(jsonStruct.meta);
            ud = struct();
            
            % default values
            ud.is_world_clock = false;
            
            for i = 1:numel(fields)
                switch(fields{i})
                    case 'type'
                        % Nothing to do
                    case 'version'
                        % TBD Block too high version
                    case 'units'
                        if iscell(class(jsonStruct.meta.units))
                            units = jsonStruct.meta.units;
                            this.tab.Properties.VariableUnits = units;
                        end
                    otherwise
                        ud.(fields{i}) = jsonStruct.meta.(fields{i});
                end
            end
            
            % Store userdata into table
            this.tab.Properties.UserData = ud;
        end
    end
    
end