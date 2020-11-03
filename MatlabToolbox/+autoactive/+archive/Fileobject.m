classdef (Abstract) Fileobject < autoactive.archive.Dataobject
    
    properties (Access = protected)
        extension = 'genfile'
        origName = 'noname'
        aaElemNameFullPath = '';
    end

    properties
        fileText
        read_delayed = true
    end
    
    methods (Access = protected)
        function this = Fileobject()
            this.fileText = 'No text added';
            this.meta.write_type = 'none';
        end
        
        function this = addText(this, fText, fName)
            assert(strcmp(this.meta.write_type, 'none'), 'addFileText() ERROR file already added to this object');
            this.fileText = fText;
            this.user.file_name_full = fName;
            this.meta.write_type = 'text';
        end
        
        function fText = getText(this)
            fText = this.fileText;
        end
        
        function this = addContentFromFileToArchive(this, fNameFull)
            assert(strcmp(this.meta.write_type, 'none'), 'addFilePath() ERROR file already added to this object');
            this.user.file_name_full = fNameFull;
            % Get more info about the file...
            fileInfo = dir(fNameFull);
            this.origName = fileInfo.name; % Use this name in archive
            f = this.newFolderFromStruct(fileInfo);
            this.user.file_details = f;
                
            this.meta.write_type = 'from_file';
        end
        
        function fText = loadTextFromArchive(this)
            this.fileText = archiveReader.readTextdata(this.aaElemNameFullPath);
            fText = this.fileText;
        end
        
        function bool = loadContentFromArchiveToFile(this, archiveReader, fNameFull)
            fileInfo = dir(fNameFull);
            if numel(fileInfo) == 0
                bool = archiveReader.readCopyContentToFile(this.meta.path, fNameFull);
            else
                bool = false;
                fprintf('ERROR - File <%s> exists ... cannot overwrite.\n', fNameFull);
            end
        end
        
        function this = saveToArchive(this, inPath, sessionId, archiveWriter)
            % Save content to separate file
            
            aaElemName = [inPath '/' this.origName];
            this.meta.attachments = {aaElemName};
            this.aaElemNameFullPath = [sessionId aaElemName];
            
            fprintf('Saving file to <%s>\n', this.aaElemNameFullPath);
            if strcmp(this.meta.write_type, 'text')
                archiveWriter.writeTextdata(this.aaElemNameFullPath, this.fileText)
                
            elseif strcmp(this.meta.write_type, 'from_file')
                archiveWriter.writeCopyContentFromFile(this.aaElemNameFullPath, this.user.file_name_full)
            end

        end

        function this = loadFromArchive(this, sessionId, archiveReader)
            % Load table data from separate file
            
            aaElemName = this.meta.attachments{1};
            this.aaElemNameFullPath = [sessionId aaElemName];
            
            if this.read_delayed
                fprintf('Postponed loading of file <%s>\n', this.aaElemNameFullPath);
                this.fileText = 'Postponed loading of file';
            else
                fprintf('Loading file from <%s>\n', this.aaElemNameFullPath);
                this.fileText = archiveReader.readTextdata(this.aaElemNameFullPath);
            end
        end
        
    end
    
end