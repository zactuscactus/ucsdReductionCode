% FR state stimation
% clear
%% SDP
warning('off','all')
warning
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\13Bus\IEEE13Nodeckt.dss');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS');
c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\34Bus\IEEE34Mod1.DSS');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\123Bus\IEEE123Master.DSS');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\8500-Node\Master.DSS');
critical_nodes={'611','652','675','692'};
% load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% [c] = FeederReduction_SE(critical_nodes,c,Z);
noise_level=0;

% if ~exist('pre_nl','var') ||noise_level~=pre_nl 
%     close all
    pre_nl=noise_level;
    [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,ybus,basekv,Ybase,true_volt]=GenMeasurements_tmp(c,noise_level);

% end
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

% Z(:,5)=1;

Z0=Z;
    
V_Meas=find(Z(:,1)==5);


Z=Z0;
% Z(find(abs(Z(:,4))<=1e-4),5)=1e-10;
% Z(find(abs(Z(:,4))<=1e-4),4)=1e-10;
% Z(:,5)=abs(Z(:,4)).*Z(:,5);
V_Meas=find(Z(:,1)==5);

% Z(find(Z(:,1)==1),:)=[];
% Z(find(Z(:,1)==4),:)=[];

node_bus=sortrows(unique([Z(:,[2,6]);Z(:,[3,7])],'rows'),1);
node_bus(find(ismember(node_bus,[0,0],'rows')),:)=[];
[topo,generation]=topology_detect(c,node_bus(1:end-3,:));
parent=topo(:,2); parent(1)=length(parent)+1;parent(end+1)=length(parent)+1;
generation(end+1,:)={1, [1;generation{1}],[]}
%parent=[5;1;2;3;5];
%parent=ones(length(dssCircuit.AllBusNames)+1,1);
tic
WLS_SDP_Result=WLS_with_SDP_PF_Model(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt);
toc
% pause(5);
% close all
% tic
% WLS_SDP_Result=WLS_with_SDP_PF_Model_distributed(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt,parent);
% toc
% 
tic
WLS_SDP_Result=WLS_with_SDP_PF_Model_distributed_final(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt,parent,generation);
toc
