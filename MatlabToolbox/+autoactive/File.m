classdef File < autoactive.archive.Fileobject
    
    properties (Access = protected, Constant)
        type = 'no.sintef.file'
        version = 1
    end
    
    methods 
        function this = File()
            this.extension = 'file';
            this.read_delayed = true;
        end
        
        function this = addFileToArchive(this, fNameFull)
            this = this.addContentFromFileToArchive(fNameFull);
        end
        
        function bool = storeFileFromArchive(this, archiveReader, fNameFull)
            bool = this.loadContentFromArchiveToFile(archiveReader, fNameFull);
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