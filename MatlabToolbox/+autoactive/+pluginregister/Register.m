classdef (Abstract) Register
    properties (Access = private, Constant)
        jsonCache = autoactive.pluginregister.Cache();
        nativeCache = autoactive.pluginregister.Cache();
    end
    
    properties (Abstract, Constant)
        type
    end
    
    methods (Access = public, Static)
        function reset()
            autoactive.pluginregister.Register.jsonCache.reset();
            autoactive.pluginregister.Register.nativeCache.reset();
        end
        
        function resetNative()
            autoactive.pluginregister.Register.nativeCache.reset();
        end
        
        function resetJson()
            autoactive.pluginregister.Register.jsonCache.reset();
        end
        
        function pluginClass = createFromJsonType(typeName)
            cache = autoactive.pluginregister.Register.jsonCache;
            pluginRegisterClass = searchPackage(typeName, ...
                                                'autoactive.pluginregister.json', ...
                                                cache );
            if isempty(pluginRegisterClass)
                fprintf('Warning - pluginregister cannot find json plugin for <%s> ... defaulting to folder\n',  typeName); 
                
                % Defaulting using Folder
                typeName = 'no.sintef.folder';
                pluginRegisterClass = searchPackage(typeName, ...
                                                    'autoactive.pluginregister.json', ...
                                                    cache );
            end
            pluginClass = eval([pluginRegisterClass.Name, '.createObj(''', typeName, ''')']);
        end
        
        function pluginClass = createFromNativeType(typeName)
            cache = autoactive.pluginregister.Register.nativeCache;
            pluginRegisterClass = searchPackage(typeName, ...
                                                'autoactive.pluginregister.native', ...
                                                cache );
            assert(~isempty(pluginRegisterClass), ['Cannot find native plugin for type: ' typeName]);
            pluginClass = eval([pluginRegisterClass.Name, '.createObj(''', typeName, ''')']);
        end
        
        function bool = checkNativeType(typeName)
            cache = autoactive.pluginregister.Register.nativeCache;
            pluginRegisterClass = searchPackage(typeName, ...
                                                'autoactive.pluginregister.native', ...
                                                cache );
            if isempty(pluginRegisterClass)
                cache.map(typeName) = pluginRegisterClass; % Add to cache for speedup
                bool = false;
            else
                bool = true;
            end
        end
    end
end

function pluginRegisterClass = searchPackage(typeName, packageName, cache)
    if cache.map.isKey(typeName)
        pluginRegisterClass = cache.map(typeName);
    else
        pluginRegisterClass = searchPackageRecursively(meta.package.fromName(packageName), typeName);
        if ~isempty(pluginRegisterClass)
            cache.map(typeName) = pluginRegisterClass;
        end
    end
end

function pluginRegisterClass = searchPackageRecursively(package, typeName)
    pluginRegisterClass = [];
    % Check if current package contains the class
    for i = 1:numel(package.ClassList)
        class = package.ClassList(i);
        % Check that the class is not abstract
        if (~class.Abstract)
            % Check if it is a subclass of plugin
            if (any(class.SuperclassList == ?autoactive.pluginregister.Register))
                % Make sure it has set the type
                for j = 1:numel(class.PropertyList)
                    prop = class.PropertyList(j);
                    if (prop.Constant && prop.HasDefault && strcmp(prop.Name,'type'))
                        if (iscell(prop.DefaultValue))
                            for ci = 1:numel(prop.DefaultValue)
                                % Check that it supports the requested name
                                if (strcmp(typeName, prop.DefaultValue{ci}))
                                    pluginRegisterClass = class;
                                    return
                                end
                            end
                        else
                           fprintf('Warning - pluginregister <%s> has registered <%s> expected <cell>\n',  class.name, class(prop.DefaultValue)); 
                        end
                    end
                end
            end
        end
    end
    % Check sub-packages
    for i = 1:numel(package.PackageList)
        sub = package.PackageList(i);
        pluginRegisterClass = searchPackageRecursively(sub, typeName);
        if (~isempty(pluginRegisterClass))
            return
        end
    end
end
