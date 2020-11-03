classdef Cache < handle
    properties
        map = containers.Map();
    end
    
    methods 
        function obj = Cache()
            obj.map = containers.Map();
        end
        
        function reset(this)
            this.map = containers.Map();
        end
    end
end
