classdef Source < autoactive.archive.Fileobject
    
    properties (Access = protected, Constant)
        type = 'no.sintef.source'
        version = 1
    end
    
    methods 
        function this = Source()
            this.extension = 'm';
            this.read_delayed = false;
        end
        
        function this = addSourceChar(this, sText, fName)
            this = this.addText(sText, fName);
            this.user.language = 'MATLAB';
        end
        
        function this = addSourceFromFile(this, fNameFull)
            this = this.addContentFromFileToArchive(fNameFull);
            this.user.language = 'MATLAB';
        end
        
        function sText = getSourceChar(this)
            sText = char(this.getText());
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