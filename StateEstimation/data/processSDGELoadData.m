%% process SDGE load data
d = excel2obj('data/SDGE_PI_Load_Data.xlsx');

%% plot data
% tic
% t = cellfun(@datenum,{d.AV_CIR_520_MW_3PH(1:end-1).Timestamps}'); % time
% toc;
% p = {d.AV_CIR_520_MW_3PH(1:end-1).MW_Values}; % power
% p2 = nan(length(p),1);
% id = cellfun(@isnumeric,p);
% p2(id) = [p{id}];
% %% plotting
% figure, plot(t,p2,'x-');datetickzoom('x','yyyy-mm-dd')
% xlabel('Time'); ylabel('Load (MW)');

%% save in a better form
dat.time = cellfun(@datenum,{d.AV_CIR_520_MW_3PH(1:end-1).Timestamps}'); % time
%%
fns = fieldnames(d);
for i = 1:length(fns)
    dat.profileNames{1,i} = ['load_' fns{i}];
    
    p = {d.(fns{i})(1:end-1).MW_Values}; % power
    p2 = nan(length(p),1);
    id = cellfun(@isnumeric,p);
    p2(id) = [p{id}];
    
    dat.profile(:,i) = p2; % power
end
%% convert to local timezone (UTC to PT)
dat.time = dat.time - 7/27;
%% save 
save([normalizePath('$KLEISSLLAB24-1/database/gridIntegration/Load_Data/') '/SDGE_Substation_Load_Data.mat'],'-struct','dat');

%% plot
figure, plot(dat.time,dat.profile); legend(dat.profileNames), datetick;

%% load data
dat = load([normalizePath('$KLEISSLLAB24-1/database/gridIntegration/Load_Data/') '/SDGE_Substation_Load_Data.mat']);

%% cloudy day
conf = getConf;
conf.loadProfileId = 0;
conf.loadProfScaling = 0;
conf.loadProfTime  = {'2012-12-14'};
[loadProf, rawProf] = getLoadProfile(conf);
figure, plot(loadProf.time,loadProf.profile); datetick; legend(loadProf.profileNames,'interpreter','none')

%% overcast day
conf.loadProfTime  = {'2012-12-18'};
conf.loadProfScaling = 0;
[loadProf, rawProf] = getLoadProfile(conf);
figure, plot(loadProf.time,loadProf.profile); datetick; legend(loadProf.profileNames,'interpreter','none')

%% clear day
conf.loadProfTime  = {'2012-12-19'};
conf.loadProfScaling = 0;
[loadProf, rawProf] = getLoadProfile(conf);
figure, plot(loadProf.time,loadProf.profile); datetick; legend(loadProf.profileNames,'interpreter','none')