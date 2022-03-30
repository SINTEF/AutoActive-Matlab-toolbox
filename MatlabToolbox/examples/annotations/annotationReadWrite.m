clear
clc
%%

if isempty(what('autoactive'))
    disp('Adding the AutoActive Matlab Toolbox to path')
    addpath('.\MatlabToolbox\')
    javaaddpath('.\MatlabToolbox\jar\java-file-interface-1.0.0-jar-with-dependencies.jar')
end

%%

ar = autoactive.ArchiveReader('test/annot_test2.aaz');

sessionInfo = ar.listSessions;
session = ar.openSession(sessionInfo);

annotationProvider = session.AnnotationProvider;
annotations = annotationProvider.annotations;
annotationInfo = annotationProvider.annotationInfo;

for i = 1:length(annotations)
    annotation = annotations(i);
    disp(annotationInfo(annotation.type))
end


%%

annotation_id = 4;
annotationProvider.addAnnotation(((annotation.timestamp / 1e6) + 30) *1e6, annotation_id);
annotationProvider.setAnnotationInfo(annotation_id, '', 'XXX', '');


%%
writer = autoactive.ArchiveWriter('test/matlab-annot.aaz');
saveSession = autoactive.Session(session.name);
saveSession.AnnotationProvider = session.AnnotationProvider;
writer.saveSession(saveSession);
writer.close()