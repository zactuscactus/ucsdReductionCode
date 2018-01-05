% FR state stimation
clear
%% WLS
% c = dssparse('C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\13Bus\IEEE13Nodeckt_zack.dss');
c = dssparse('C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS');
critical_nodes={'611','652','675','692'};
% load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% [c] = FeederReduction_SE(critical_nodes,c,Z);
noise_level=1;

	
% [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W]=GenMeasurements(c,noise_level);
[Z,~,~,~,~,~,Ycomb,~,~,~,~,ybus,basekv,Ybase,dssCircuit]=GenMeasurements(c,noise_level);

for ii=1:length(Z)
	Z{ii,2}=find(ismember(Ycomb,Z(ii,2)));
	Z{ii,3}=find(ismember(Ycomb,Z(ii,3)));
end
Z=cell2mat(Z);
Z(find(Z(:,1)==1),3)=0;
Z(find(Z(:,1)==2),3)=0;
Z(find(Z(:,1)==5),3)=0;
V_Meas=find(Z(:,1)==5);

[zdata]=Convert_Z_toWLSForm(Z);
% zdata(find(zdata(:,2)==4),:)=[];
% zdata(find(zdata(:,2)==5),:)=[];
%  
[State_Estimate]=Estimate_State(ybus,zdata,[],dssCircuit,Ycomb,Ybase);

% %% SDP
% % c = dssparse('C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\13Bus\IEEE13Nodeckt_zack.dss');
% c = dssparse('C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS');
% critical_nodes={'611','652','675','692'};
% % load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% % [c] = FeederReduction_SE(critical_nodes,c,Z);
% noise_level=1;
% 
% 	
% % [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W]=GenMeasurements(c,noise_level);
% [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,ybus,basekv]=GenMeasurements_tmp(c,noise_level);
% 
% for ii=1:length(Z)
% 	Z{ii,2}=find(ismember(Ycomb,Z(ii,2)));
% 	Z{ii,3}=find(ismember(Ycomb,Z(ii,3)));
% end
% Z=cell2mat(Z);
% Z(find(Z(:,1)==1),3)=0;
% Z(find(Z(:,1)==2),3)=0;
% Z(find(Z(:,1)==5),3)=0;
% 
% V_Meas=find(Z(:,1)==5);
% 
% % results=SDPDSE(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,W)
% [zdata]=Convert_Z_toWLSForm(Z);
%  
% [State_Estimate]=Estimate_State(ybus,zdata);