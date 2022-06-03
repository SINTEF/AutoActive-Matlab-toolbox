clear
clc
%%

if isempty(what('autoactive'))
    disp('Adding the AutoActive Matlab Toolbox to path')
    addpath('.\MatlabToolbox\')
    javaaddpath('.\MatlabToolbox\jar\java-file-interface-1.0.0-jar-with-dependencies.jar')
end

%%
annotationProvider = autoactive.plugins.Annotation();

%%
annotation_id = 42;
annotationProvider.addAnnotation(0 * 1e6, annotation_id);
annotationProvider.addAnnotation((10 + 30) * 1e6, annotation_id);
annotationProvider.addAnnotation((20 + 30) * 1e6, annotation_id);
annotationProvider.addAnnotation((30 + 30) * 1e6, annotation_id);
annotationProvider.setAnnotationInfo(annotation_id, 'Annotation A', 'A', 'Just a test');

for i=1:3
    annotationProvider.addAnnotation(10 * i * 1e6, i);
    annotationProvider.setAnnotationInfo(i, sprintf('Annotation %d', i), sprintf('%d', i), '');
end

%%
writer = autoactive.ArchiveWriter('test/matlab-annot.aaz');
saveSession = autoactive.Session('Annotation Test');
saveSession.AnnotationProvider = annotationProvider;
writer.saveSession(saveSession);
writer.close()