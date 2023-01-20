% Run this script before 'read_archive_sine_sync.m'. In this script a aaz
% file called 'testSine.aaz' will be created. This file will need to be
% opened in Activity presenter, synchronized and saved again as
% 'testSineSynced.aaz' before running 'test_archive_sine_sync.m'

% *Known issues when running this script*:
%
% * You need to be in the same "current folder" as the activityPresenter_cycles_examples.m script when running in MATLAB



% javaaddpath('.\MatlabToolbox\jar\java-file-interface-2.0.1-jar-with-dependencies.jar')
jar_file = dir('../../jar/'); javaaddpath(['../../jar/',jar_file(3).name])

%************ Fetch source code and put it into a source object ************
source_obj = autoactive.Source();
this_script = mfilename('fullpath');
source_obj = source_obj.addSourceFromFile([this_script '.m']);

%************ Create first sine table and make it a table ************

t = struct();
t.time = (0:1e5:100*1e6)';
t.sine = sin(2*pi*t.time/1e6);
t.cosi = cos(2*pi*t.time/1e6);
t.time = int64(t.time);

Trig_table = struct2table(t);
Trig_table.Properties.VariableUnits{'time'} = 'Epocms'; 
Trig_table.Properties.UserData = struct();

%************ Create offset sine table and make it a table ************

t_off = t;
t_off.time = int64(t_off.time + 1e7);

TrigOff_table = struct2table(t_off);
TrigOff_table.Properties.VariableUnits{'time'} = 'Epocms'; 
TrigOff_table.Properties.UserData = struct();

%************ Assemble a session ************

sw = autoactive.Session('testSine');
sw.Data = autoactive.Folder();
sw.Data.Trig = Trig_table;

sw.Data.TrigOff = TrigOff_table;

sw.source = source_obj;

%************ Write session to an archive ************

aw = autoactive.ArchiveWriter('testSine.aaz');
aw.saveSession(sw);
aw.close()
clear aw;


% Read table and metadata from AutoActive Archive
ar = autoactive.ArchiveReader('testSine.aaz');

list = ar.listSessions();

sr = ar.openSession('testSine');

t_rd = sr.Data.Trig;
%t_rd = sr.Data.TrigOff;
rdCols = t_rd.Properties.VariableNames;


% Print top
head(t_rd,20);

%% Check that the table data is the same
t_wr = sw.Data.Trig; 
wrCols = t_wr.Properties.VariableNames;


if (all(size(wrCols) == size(rdCols)))
    if (all(cellfun(@(a,b) strcmp(a,b), wrCols, rdCols)))
        for col = wrCols
            colname = char(col);
            if (not(all(t_wr.(colname) == t_rd.(colname))))
                error(['Column ' colname ' has different data']);
            end
        end
    else
        error('Not equal column names');
    end
else
    error('Not the same number of columns');
end

display('Readback of session ok');

crc_res = ar.checkCrc();

clear ar;
