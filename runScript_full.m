clear
clc
tic
%set path
def_addpath
basePath=pwd;
savePath='P:\users\Zack\FR2_sims';
pathToFile=[ pwd '\8500-Node\Master.dss'];

%declare machine name for saving
machineName='local';

%get buslist for critical buses
o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear';
dssText.Command = ['Compile "' pathToFile '"'];
dssCircuit = o.ActiveCircuit;
circuit.buslist.id=regexprep(dssCircuit.AllBUSNames,'-','_');
buslist=circuit.buslist.id;
circuit.buslist.coord=zeros(length(circuit.buslist.id),2);
delete(o);
fclose('all');

for ii=1:25:length(buslist)
%set CB
cbNums=round((length(buslist)-1)*rand(ii,1))+1;
criticalBuses=buslist(cbNums);

%call reduction
cd(basePath)
[circuit] = reducingFeeders(pathToFile,criticalBuses)

%save reduction
save([savePath '\buses_' num2str(ii) '_' machineName '.mat'], 'circuit')
end

t_=toc;
fprintf('\nWhole code took %f seconds',t_)