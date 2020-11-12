classdef JavaReader < handle
    
    properties
        jobj
        path
    end
    
    
    methods
        function obj = JavaReader(path)
            %fprintf('JavaReader <%s> - Open\n', path);
            obj.jobj = no.sintef.autoactive.files.ArchiveReader(path);
            obj.path = path;
        end
        
        function close(obj)
            %fprintf('JavaReader <%s> - Closing\n', obj.path);
            javaMethod('close', obj.jobj);
        end

        function delete(obj)
            obj.close();
        end
    end
    
end

