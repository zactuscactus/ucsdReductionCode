% FR state stimation
% clear
%% WLS
%c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\34Bus\IEEE34Mod1.DSS');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\13Bus\IEEE13Nodeckt.dss');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\37Bus\IEEE37.dss');
c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\123Bus\IEEE123Master.dss');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\IEEE 30 Bus\master.dss');
% c.line(1).C0=0;
% c.line(1).C1=0;
% c.line(2).C0=0;
% c.line(2).C1=0;

critical_nodes={'611','652','675','692'};
% load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% [c] = FeederReduction_SE(critical_nodes,c,Z);
noise_level=0;

	
% [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W]=GenMeasurements(c,noise_level);
[Z,~,~,~,~,~,Ycomb,~,~,~,~,ybus,basekv,Ybase,true_volt]=GenMeasurements_tmp(c,noise_level);

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
% zdata(find(zdata(:,2)==4),:)=[];
% zdata(find(zdata(:,2)==5),:)=[];
tic
[State_Estimate]=Estimate_State(ybus,zdata,[],dssCircuit,Ycomb,Ybase,true_volt);
toc

%% tried to fast-decouple the process, but not successful yet
% tic
% [State_Estimate]=Estimate_State_fastdecoupled(ybus,zdata,[],dssCircuit,Ycomb,Ybase,true_volt);
% toc