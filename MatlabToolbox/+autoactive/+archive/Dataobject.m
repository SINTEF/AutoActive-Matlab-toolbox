classdef (Abstract,  HandleCompatible) Dataobject < matlab.mixin.CustomDisplay
    properties (Access = protected)
        meta = struct()
        user = struct()
    end
    
    properties (Access = protected, Constant, Abstract)
        % Each object type has its own unique name in JSON
        type

        % The version number describe the provided objects
        % Each object type has its own version in JSON
        % If the version is lower (older) it is known and should be handled
        version
    end

    properties (Access = protected, Constant)
        ExposedMethods = {'newFolder', 'newFolderFromStruct','wrapNative','isNativeWrapper'}
    end
    
    methods
        function list = listElem(this, elemPath)
            % Traverse the path to find the correct position to find elem
            elemPathCarr = split(elemPath,'/');
            elem = this.getElemFromObjRec(elemPathCarr, elemPath);
            
            % List the current elem
            list = struct();
            elemCount = 0;
            
            if isa(elem, 'autoactive.archive.Dataobject')
                fn = fieldnames(elem.user);
                for i = 1:length(fn)
                    fieldName = fn{i};
                    elemCount = elemCount + 1;
                    list(elemCount).type = class(elem.user.(fieldName));
                    list(elemCount).name = fieldName;
                end
            else
                elemCount = elemCount + 1;
                list(elemCount).name = '...';
                list(elemCount).type = class(elem);
            end
        end

        function list = listElemSub(this, elemPath)
            % Traverse the path to find the correct position to find elem
            tmpCarr = split(elemPath,'/');
            elemPathCarr = matlab.lang.makeValidName(tmpCarr);
            elem = this.getElemFromObjRec(elemPathCarr, elemPath);
            indentCount = 0;
            % List the current elem and its sub
            [sub] = elem.listElemSubRec(indentCount+1);
            s = sprintf('%sName:%s Type:%s\n', this.indent(indentCount), elemPath, class(elem));
            list = [s sub];
        end

        function this = addElem(this, elemPath, elem)
            % Traverse the path to find the correct position to add elem
            tmpCarr = split(elemPath,'/');
            elemPathCarr = matlab.lang.makeValidName(tmpCarr);
            this = this.addElemToObjRec(elemPathCarr, elemPath, elem);
        end
        
        function elem = getElem(this, elemPath)
            % Traverse the path to find the correct position to get elem
            tmpCarr = split(elemPath,'/');
            elemPathCarr = matlab.lang.makeValidName(tmpCarr);
            elem = this.getElemFromObjRec(elemPathCarr, elemPath);
        end

        function aaTime = convEpochMsToAaTime(this, epochMs)
            % Convert timeformat to epoch microsec format used in AAZ file tables
            epochMsInt64 = int64(epochMs);
            aaTime = epochMsInt64 * 1000; % Convert to uSeconds
        end
        
        function aaTime = convEpochToAaTime(this, epoch)
            % Convert timeformat to .NET time used in AAZ file tables
           epochInt64 = int64(epoch);
           aaTime = this.convEpochMsTimeToAaTime(epochInt64 * 1000);
        end
    end
    
    methods (Access = public, Hidden)
        function this = Dataobject()
            %fprintf('Creating Dataobject of type: %s\n',  this.type);
        end
        
        function fObj = newFolder(~)
            fObj = autoactive.Folder();
        end
        
        
        function fObj = newFolderFromStruct(this, stru)
            fObj = this.newFolder();

            fields = fieldnames(stru);
            for i = 1:numel(fields)
                fieldName = fields{i};
                fObj.user.(fieldName) = stru.(fieldName);
            end
        end
        
        % This is called to list properties for tab-completion
        function names = properties(this)
            names = fieldnames(this.user);
        end
        
        % This is called by obj.*, obj(*), and obj{*}
        function varargout = subsref(this, sub)
            % () and {} not supported
            if (strcmp(sub(1).type,'()'))
                throwAsCaller(MException('AA:BadIndexType','() indexing not supported'));
            elseif (strcmp(sub(1).type,'{}'))
                throwAsCaller(MException('AA:BadIndexType','{} indexing not supported'));
            end
            
            try
                % . () is a method call
                if (numel(sub) > 1 && strcmp(sub(2).type,'()'))
                    % Use the built-in handler
                    [varargout{1:nargout}] = builtin('subsref', this, sub);
                    return
                end
                
                % If referring to an existing field that is another dataobject
                % dataobject and it is part of a longer chain
                if (numel(sub) > 1 && isfield(this.user, sub(1).subs))
                    if (isa(this.user.(sub(1).subs),'autoactive.archive.Dataobject'))
                        if (length(sub) > 1)
                            % Call the subsasgn of that object
                            [varargout{1:nargout}] = this.user.(sub(1).subs).subsref(sub(2:end));
                            return
                        end
                    end
                end
                
                % If not, use the built-in method to read from User struct
                [varargout{1:nargout}] = builtin('subsref', this.user, sub);
            catch me
                display(getReport(me))
                throwAsCaller(me)
            end
        end
        
        % This is called by obj.* = *, obj(*) = *, and obj{*} = *
        function this = subsasgn(this, sub, value)
            % () and {} not supported
            if (strcmp(sub(1).type,'()'))
                throwAsCaller(MException('AA:BadIndexType','() indexing not supported'));
            elseif (strcmp(sub(1).type,'{}'))
                throwAsCaller(MException('AA:BadIndexType','{} indexing not supported'));
            end
            
            % Check if someone is trying to assign to a method
            if (any(strcmp(this.ExposedMethods, sub(1).subs)))
                throwAsCaller(MException('AA:BadIndex',['Cannot assign to ', sub(1).subs, '.']));
            end
            
            try
                % If assigning to an existing field that is another dataobject
                % dataobject and it is part of a longer chain
                if (isfield(this.user, sub(1).subs))
                    if (isa(this.user.(sub(1).subs),'autoactive.archive.Dataobject'))
                        if (length(sub) > 1)
                            % Call the subsasgn of that object
                            this.user.(sub(1).subs) = this.user.(sub(1).subs).subsasgn(sub(2:end), value);
                            return
                        end
                    end
                end
                
                % If not, use the built-in method to assign to User struct
                this.user = builtin('subsasgn', this.user, sub, value);
            catch me
                display(getReport(me))
                throwAsCaller(me)
            end
        end
        
        % Default wrapper method to be overloaded for native support
        function this = wrapNative(this, native)
            assert(false, ['ERROR Native wrapper functionality is not supported by class <' class(this) '>']);
            this.tab = native;
        end
        
        % Default wrapper method to be overloaded for native support
        function bool = isNativeWrapper(~)
            bool = false;
        end
        
        
        
    end
    
    methods (Access = protected)
        function header = getHeader(this)
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(this);
            fields = ' with no fields.';
            if (~isempty(fieldnames(this.user)))
                fields = ' with fields:';
            end
            header = sprintf('  %s\n', [className, fields]);
        end
        
        function groups = getPropertyGroups(this)
            groups = matlab.mixin.util.PropertyGroup(this.user);
        end
    end
    
    methods (Access = protected, Hidden)
        function ret = indent(~, indentCount)
            ret = blanks(indentCount * 3);
        end
        
        function list = listElemSubRec(this, indentCount)
            % List the current elem and its sub
            list = '';
            
            if isa(this, 'autoactive.archive.Dataobject')
                fn = fieldnames(this.user);
                for i = 1:length(fn)
                    fieldName = fn{i};
                    name = fieldName;
                    if isa(this.user.(fieldName), 'autoactive.archive.Dataobject')
                        sub = this.user.(fieldName).listElemSubRec(indentCount+1);
                    else
                        sub = '';
                    end
                    s = sprintf('%sName:%s Type:%s\n', this.indent(indentCount), name, class(this.user.(fieldName)));
                    list = [list s sub];
                end
            end
        end
        
        %% ****************************************************************
        function elem = getElemFromObjRec(this, elemPathCarr, elemPath) 
            elem = this;

            if length(elemPath) == 0
                return
            end

            if ~isempty(elemPathCarr)
                %numElems = numel(inStruct);
                pathStep = elemPathCarr{1};
                
                fn = fieldnames(this.user);
                for i = 1:length(fn)
                    fieldName = fn{i};

                    if strcmp(fieldName, pathStep)
                        % Field exists ...
                        if length(elemPathCarr) > 1
                            % Go deeper ... recursivly
                            elemPathCarr(1) = []; % Remove one element from path
                            elem = this.user.(pathStep).getElemFromObjRec(elemPathCarr, elemPath); 
                            return
                        else
                            elem = this.user.(pathStep);
                            return
                        end
                    end
                end
                % No match found ... 
                assert(false, 'Path cannot be found')

            else
                % Path empty ... return result
            end
        end
        
        %% ****************************************************************
        function this = addElemToObjRec(this, elemPathCarr, elemPath, elem) 

            if ~isempty(elemPathCarr)
                %numElems = numel(this.user);
                pathStep = elemPathCarr{1};
                
                fn = fieldnames(this.user);
                for i = 1:length(fn)
                    fieldName = fn{i};
                    if strcmp(fieldName, pathStep)
                        % Field exists ...
                        assert(isa(this.user.(fieldName), 'autoactive.archive.Dataobject') == true, 'elemPath is already in use by an element')

                        % It is an data this ... search recursivly
                        elemPathCarr(1) = []; % Remove one element in path
                        this.user.(pathStep) = this.user.(pathStep).addElemToObjRec(elemPathCarr, elemPath, elem); 
                        return
                    end
                end
                
                %% No match found ... make it from here
                if length(elemPathCarr) > 1
                    % Add data this ... recursivly
                    elemPathCarr(1) = []; % Remove one element in path
                    newFolder = this.newFolder();
                    this.user.(pathStep) = newFolder.addElemToObjRec(elemPathCarr, elemPath, elem); 
                else
                    % Only the name is left to add
                    this.user.(pathStep) = elem;
                end
            else
                assert(false, 'Path is already in use by substruct or placed at root')
            end
        end

        function replacedData = replaceNativesRec(this)
            replacedData = this;
            fields = fieldnames(replacedData.user);
            for i = 1:numel(fields)
                fieldName = fields{i};
                fieldVal = replacedData.user.(fieldName);
                
                if (isa(fieldVal, 'autoactive.archive.Dataobject'))
                    % Search recursivly
                    dataObj = fieldVal.replaceNativesRec();
                    replacedData.user.(fieldName) = dataObj;
                else
                    % Check if native wrapper plugin exists
                    fieldClassName = class(fieldVal);
                    classSupported = autoactive.pluginregister.Register.checkNativeType(fieldClassName);
                    if (classSupported)
                        % Wrap native into plugin
                        wrapperObj = autoactive.pluginregister.Register.createFromNativeType(fieldClassName);
                        wrapperObj = wrapperObj.wrapNative(fieldVal);
                        replacedData.user.(fieldName) = wrapperObj;
                    end
                end
            end
        end
        
        function restoredData = restoreNativesRec(this)
            restoredData = this;
            fields = fieldnames(restoredData.user);
            for i = 1:numel(fields)
                fieldName = fields{i};
                fieldVal = restoredData.user.(fieldName);
                    
                if (isa(fieldVal, 'autoactive.archive.Dataobject'))
                    if (fieldVal.isNativeWrapper())
                        restoredData.user.(fieldName) = fieldVal.unwrapNative();
                    else
                        restoredData.user.(fieldName) = fieldVal.restoreNativesRec();
                    end
                end
            end
        end
        
        % Default method to be overloaded for special actions before save
        function this = toJsonStructPreHook(this, inPath, sessionId, archiveWriter)
        end
        
        function jsonStruct = toJsonStructRec(this, inPath, sessionId, archiveWriter)
            % Fix object dependent stuff before save
            this = this.toJsonStructPreHook(inPath, sessionId, archiveWriter);
            
            % Put all the Meta and User fields into the returned json
            jsonStruct = struct('meta', this.meta, 'user', this.user);
            jsonStruct.meta.type    = this.type;
            jsonStruct.meta.version = this.version;
            % Call toJsonStructRec of embedded dataobjects
            fields = fieldnames(jsonStruct.user);
            for i = 1:numel(fields)
                fieldName = fields{i};
                
                inPathNext = [inPath '/' fieldName];

                if (isa(jsonStruct.user.(fieldName), 'autoactive.archive.Dataobject'))
                    jsonElem = jsonStruct.user.(fieldName).toJsonStructRec(inPathNext, sessionId, archiveWriter);
                    jsonElem.meta.type = jsonStruct.user.(fieldName).type;
                    jsonStruct.user.(fieldName) = jsonElem; % Just to be sure
                end
            end
        end
        
        % Default method to be overloaded for special actions after load
        function this = fromJsonStructPostHook(this, sessionId, archiveReader)
        end
        
        function this = fromJsonStructRec(this, jsonStruct, sessionId, archiveReader)
            % Check that we have what we need
            if (~isfield(jsonStruct, 'user') || ~isa(jsonStruct.user, 'struct'))
                throwAsCaller(MException('AA:BadJSON','user is missing from json.'));
            end
            if (~isfield(jsonStruct, 'meta') || ~isa(jsonStruct.meta, 'struct'))
                throwAsCaller(MException('AA:BadJSON','meta is missing from json.'));
            end
            % Copy all Meta and User fields from json
            this.meta = jsonStruct.meta;
            this.user = jsonStruct.user;

            % Fix object dependent stuff after load
            this = this.fromJsonStructPostHook(sessionId, archiveReader);
            
            % Create dataobjects from embedded objects with a 'type' field
            fields = fieldnames(this.user);
            for i = 1:numel(fields)
                field = this.user.(fields{i});
                if (isfield(field, 'meta') && isfield(field.meta, 'type'))
                    newPrototype = autoactive.pluginregister.Register.createFromJsonType(field.meta.type);
                    newElem = newPrototype.fromJsonStructRec(field, sessionId, archiveReader);
                    this.user.(fields{i}) = newElem;
                end
            end
        end
    end
    
end

