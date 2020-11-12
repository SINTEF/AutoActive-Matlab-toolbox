classdef no_sintef < autoactive.pluginregister.Register
    properties (Constant)
        type = {'table' ...
               }
    end
    
    methods (Access = public, Static)
        function obj = createObj(typeName)
            switch(typeName)
                case 'table' 
                    obj = autoactive.plugins.natives.Table();
            end
            
        end
    end
end

