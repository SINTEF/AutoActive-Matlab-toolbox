javaaddpath('.\MatlabToolbox\jar\java-file-interface-1.0.0-jar-with-dependencies.jar')
% Read table and metadata from original AutoActive Archive
orig_ar = autoactive.ArchiveReader('testSine.aaz');

orig_sr = orig_ar.openSession('testSine');

orig_trig = orig_sr.Data.Trig;
orig_trigoff = orig_sr.Data.TrigOff;

% Read table and metadata from synced AutoActive Archive
sync_ar = autoactive.ArchiveReader('testSineSynced.aaz');

sync_sr = sync_ar.openSession('testSine');

sync_trig = sync_sr.Data.Trig;
sync_trigoff = sync_sr.Data.TrigOff;


% Print top
fprintf('orig_trig\n');
head(orig_trig,10)
fprintf('sync_trig\n');
head(sync_trig,10)
fprintf('sync_trigoff\n');
head(sync_trigoff,10)
fprintf('orig_trigoff\n');
head(orig_trigoff,10)

%% Check that the table data is synced
orig_cols = orig_trig.Properties.VariableNames;
sync_cols = sync_trigoff.Properties.VariableNames;


if (all(size(orig_cols) == size(sync_cols)))
    if (all(cellfun(@(a,b) strcmp(a,b), orig_cols, sync_cols)))
        for col = orig_cols
            colname = char(col);
            if (not(all(orig_trig.(colname) == sync_trigoff.(colname))))
                error(['Column ' colname ' has different data']);
            end
        end
    else
        error('Not equal column names');
    end
else
    error('Not the same number of columns');
end

disp('Readback of session ok');

clear ar;
