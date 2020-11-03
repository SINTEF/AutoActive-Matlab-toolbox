classdef Video < autoactive.archive.Fileobject
    
    properties (Access = protected, Constant)
        type = 'no.sintef.video'
        version = 1
    end
    
    methods 
        function this = Video()
            this.extension = 'video';
            this.read_delayed = true;
            
            this.meta.is_world_clock = false;
            this.meta.start_time = 0;
            this.meta.time_scale = 1.0;
        end
        
        function this = addVideoToArchive(this, fNameFull)
            this = this.addContentFromFileToArchive(fNameFull);
            % this.meta.offset = 0;
        end
        
        function bool = storeVideoFromArchive(this, archiveReader, fNameFull)
            bool = this.loadContentFromArchiveToFile(archiveReader, fNameFull);
        end
        
        function start_time = getStartTime(this)
            start_time = this.meta.start_time;
        end
        
        function this = setStartTime(this, start_time)
            this.meta.start_time = start_time;
        end
        
        
        
    end
    
    methods (Access = protected, Hidden)
        % Special actions before save
        function this = toJsonStructPreHook(this, inPath, sessionId, archiveWriter)
            % Trig save of separate files
            this = this.saveToArchive(inPath, sessionId, archiveWriter);
        end
        
        % Special actions after load
        function this = fromJsonStructPostHook(this, sessionId, archiveReader)
            this = this.loadFromArchive(sessionId, archiveReader);
        end
        
    end
    
end
