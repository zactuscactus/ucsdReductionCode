% FR state stimation
% clear
%% WLS
c = dssparse('C:\Users\Zactus\feederReduction\4Bus-YY-Bal\4Bus-YY-Bal.DSS');

critical_nodes={'611','652','675','692'};
% load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% [c] = FeederReduction_SE(critical_nodes,c,Z);
noise_level=0;

	
% [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W]=GenMeasurements(c,noise_level);
[Z,~,~,~,~,~,Ycomb,~,~,~,~,ybus,basekv,Ybase,true_volt]=GenMeasCode(c,noise_level);

p = dsswrite(c,[],0,[]); o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
dssText.Command = ['Compile "' p '"']; 
dssCircuit = o.ActiveCircuit;
Names=dssCircuit.AllBusNames;
Names{end+1}='source';

for ii=1:length(Z)
	Z{ii,6}=find(ismember(lower(Names),lower(strtok(Z(ii,2),'.'))));
	Z{ii,7}=find(ismember(lower(Names),lower(strtok(Z(ii,3),'.'))));
	Z{ii,2}=find(ismember(Ycomb,Z(ii,2)));
	Z{ii,3}=find(ismember(Ycomb,Z(ii,3)));
end
Z=cell2mat(Z);
Z(find(Z(:,1)==1),3)=0;
Z(find(Z(:,1)==2),3)=0;
Z(find(Z(:,1)==5),3)=0;
Z(find(Z(:,1)==1),7)=0;
Z(find(Z(:,1)==2),7)=0;
Z(find(Z(:,1)==5),7)=0;
V_Meas=find(Z(:,1)==5);

[zdata]=Convert_Z_toWLSForm(Z);
 
[State_Estimate]=Estimate_State(ybus,zdata,[],dssCircuit,Ycomb,Ybase,true_volt);