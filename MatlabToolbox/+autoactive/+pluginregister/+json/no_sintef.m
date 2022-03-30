classdef no_sintef < autoactive.pluginregister.Register
    properties (Constant)
        type = {'no.sintef.folder' ...
                'no.sintef.file' ...
                'no.sintef.gaitup' ...
                'no.sintef.garmin' ...
                'no.sintef.session' ...
                'no.sintef.source' ...
                'no.sintef.table' ...
                'no.sintef.video' ...
                'no.sintef.annotation' ...
               }
    end
    
    methods (Access = public, Static)
        function obj = createObj(typeName)
            switch(typeName)
                case 'no.sintef.folder' 
                    obj = autoactive.Folder();
                case 'no.sintef.file' 
                    obj = autoactive.File();
                case 'no.sintef.session' 
                    obj = autoactive.Session();
                case 'no.sintef.source' 
                    obj = autoactive.Source();
                case 'no.sintef.table' 
                    obj = autoactive.plugins.natives.Table();
                case 'no.sintef.gaitup'
                    obj = autoactive.plugins.Gaitup();
                case 'no.sintef.garmin'
                    obj = autoactive.plugins.Garmin();
                case 'no.sintef.annotation' 
                    obj = autoactive.plugins.Annotation();
                case 'no.sintef.video' 
                    obj = autoactive.Video();
            end
        end
    end
end

