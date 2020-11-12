classdef Tracer < handle
    
    properties
        display
    end
    
    methods
        function obj = Tracer()
            obj.display = false;
        end
        
        function trace(obj, text)
            if obj.display
                fprintf('%s: %s', class(obj), text);
            end
        end
        
        function traceDisplay(obj, on)
            obj.display = on;
        end
        
    end
end

