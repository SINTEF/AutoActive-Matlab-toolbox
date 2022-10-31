% *Known issues when running this script*:
% * You need to be in the same "current folder" as this script when running in MATLAB

clear
clc
%% Add necessary paths

if isempty(what('autoactive'))
    disp('Adding the AutoActive Matlab Toolbox to path')
%     addpath('.\MatlabToolbox\')
    addpath(genpath('../../../../AutoActive-Matlab-toolbox/'));

    % Add the compiled .jar file of the Activity Presenter Toolbox
    jar_file = dir('../../jar/'); javaaddpath(['../../jar/',jar_file(3).name])
%     javaaddpath('.\MatlabToolbox\jar\java-file-interface-1.0.0-jar-with-dependencies.jar')
end

%% Read aaz file created in 'create_annotations.m'

% ar = autoactive.ArchiveReader('test/annot_test2.aaz');
ar = autoactive.ArchiveReader('matlab-annot.aaz');

sessionInfo = ar.listSessions;
session = ar.openSession(sessionInfo);

annotationProvider = session.AnnotationProvider;
annotations = annotationProvider.annotations;
annotationInfo = annotationProvider.annotationInfo;

for i = 1:length(annotations)
    annotation = annotations(i);
    disp(annotationInfo(annotation.type))
end


%% Add annotations

annotation_id = 4;
annotationProvider.addAnnotation(((annotation.timestamp / 1e6) + 30) *1e6, annotation_id);
annotationProvider.setAnnotationInfo(annotation_id, '', 'XXX', '');

% annotations = annotationProvider.annotations;  % To see added annotations

%% Save new annotations
% writer = autoactive.ArchiveWriter('test/matlab-annot.aaz');
writer = autoactive.ArchiveWriter('matlab-annot.aaz');
saveSession = autoactive.Session(session.name);
saveSession.AnnotationProvider = session.AnnotationProvider;
writer.saveSession(saveSession);
writer.close()