classdef Annotation < autoactive.archive.Dataobject & handle
    
    properties (Access = protected, Constant)
        type = 'no.sintef.annotation'
        version = '1.0.0'
        AutoActiveType = 'Annotation'
    end
    
    methods (Access=public)
        function this = Annotation()
            this = this@autoactive.archive.Dataobject();
            this.user.('annotations') = struct('timestamp', {}, 'type', {});
            this.user.('annotationInfo') = containers.Map('KeyType', 'double','ValueType','any');
            this.user.('isWorldSynchronized') = false;
        end
        function this = addAnnotation(this, timestamp, annotationId)
            annotations = this.user.('annotations');
            annotations(end+1) = struct('timestamp', timestamp, 'type', annotationId);
            this.user.('annotations') = annotations;
        end
        function this = setAnnotationInfo(this, annotationId, name, tag, comment)
            annotationInfo = this.user.('annotationInfo');
            annotationInfo(annotationId) = struct('name', name, 'tag', tag, 'comment', comment);
            this.user.('annotationInfo') = annotationInfo;
        end
    end

    methods (Access = protected, Hidden)
        function jsonStruct = toJsonStructRec(this, inPath, sessionId, archiveWriter)
            % Annotations are saved in separate file
            fileName = '/Annotations/Annotations.json';
            
            % Matlab writes empty elements as [], fill all as '' instead
            annotationInfo = this.user.('annotationInfo');
            
            % There seems to be a bug with jsonencode where a single element
            % in a map is stored inside an additional list element.
            % Adding a second dummy annotation to avoid this.
            if annotationInfo.Count == 1
                annotationKeys = keys(annotationInfo);
                annotationId = annotationKeys{1} + 1;
                warning("Due to an inconsistency in Matlab's jsonencode there must be at least two elements. Adding empty annotation %d to prevent this.", annotationId)
                this.setAnnotationInfo(annotationId, "", "", "");
            end
            
            annotationKeys = keys(annotationInfo);
            
            
            for i = 1:length(annotationKeys)
                key = annotationKeys{i};
                info = annotationInfo(key);
                if ~ischar(info.name)
                    info.name = char(info.name);
                end
                if ~ischar(info.tag)
                    info.tag = char(info.tag);
                end
                if ~ischar(info.comment)
                    info.comment = char(info.comment);
                end
                annotationInfo(key) = info;
            end
            
            this.user.('annotationInfo') = annotationInfo;

            % Create a map with the keys as char instead of double (as it
            % is required by jsonencode)
            names = convertContainedStringsToChars(string(cell2mat(keys(annotationInfo))));
            annotationInfoCharKey = containers.Map(names, values(annotationInfo));
            
            
            annotationsStruct = struct();
            annotationsStruct.AutoActiveType = this.AutoActiveType;
            annotationsStruct.is_world_synchronized = this.user.('isWorldSynchronized');
            annotationsStruct.version = this.version;
            annotationsStruct.annotation_info = annotationInfoCharKey;
            annotationsStruct.annotations = this.user.('annotations');
            
            jsonAnnotations = jsonencode(annotationsStruct);
            archiveWriter.writeTextdata([sessionId fileName], jsonAnnotations);
            
            jsonStruct = struct();
            
            % Empty userdata
            jsonStruct.user = struct();
            
            % Put all the table metadata into the returned json
            jsonStruct.meta = struct();
            jsonStruct.meta.type = this.type;
            jsonStruct.meta.version = this.version;
            jsonStruct.meta.attachments = {fileName};
        end
        
        function this = fromJsonStructRec(this, jsonStruct, sessionId, archiveReader)
            attachmentName = jsonStruct.meta.attachments{1};
            attachmentPath = [sessionId attachmentName];
            annotationsJsonText = archiveReader.readTextdata(attachmentPath);
            annotationsJson = jsondecode(char(annotationsJsonText));
            
            if annotationsJson.AutoActiveType ~= this.AutoActiveType
                warning('Type (%s) different from expected (%s)', annotationsJson.AutoActiveType, this.AutoActiveType);
            end
            
            this.user.('isWorldSynchronized') = annotationsJson.is_world_synchronized;
            if annotationsJson.version ~= this.version
                warning('Annotation version (%s) different from expected (%s)', annotationsJson.version, this.version);
            end
            this.user.('annotations') = annotationsJson.annotations;
            annotationInfoStruct = annotationsJson.annotation_info;
            
            % As struct members can't have a numeric name, the json reader
            % prepends an 'x'. Removing this to create a lookup table.
            info_fields = fields(annotationInfoStruct);
            names = (1:length(info_fields));
            for i=1:length(info_fields)
                field = info_fields{i};

                if field(1) == 'x'
                    fieldname = field(2:end);
                else
                    fieldname = field;
                end
                names(i) = str2double(fieldname);
            end
            this.user.('annotationInfo') = containers.Map(names, struct2cell(annotationInfoStruct));
        end
    end
end
