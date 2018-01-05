% FR state stimation
clear
close all
%% WLS
% FeederName='C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS';
% FeederName='C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\13Bus\IEEE13Nodeckt.dss'
FeederName='C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\34bus\ieee34Mod1.dss'

% FeederName='C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS';
c = dssparse(FeederName);

FeederNum=regexp(strtok(FeederName,'.'),'\','split');FeederNum=FeederNum{end};
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
 
[State_Estimate]=Estimate_State(ybus,zdata,[],dssCircuit,Ycomb,Ybase,true_volt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SDP
noise_level=0;

[Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,ybus,basekv,Ybase,true_volt]=GenMeasurements_tmp(c,noise_level);
for ii=1:length(Z)
	Z{ii,2}=find(ismember(Ycomb,Z(ii,2)));
	Z{ii,3}=find(ismember(Ycomb,Z(ii,3)));
end
Z=cell2mat(Z);
Z(find(Z(:,1)==1),3)=0;
Z(find(Z(:,1)==2),3)=0;
Z(find(Z(:,1)==5),3)=0;
Z0=Z;


Z=Z0;
Z(find(abs(Z(:,4))<=1e-4),5)=1e-10;
Z(find(abs(Z(:,4))<=1e-4),4)=1e-10;
Z(:,5)=abs(Z(:,4)).*Z(:,5);
V_Meas=find(Z(:,1)==5);


tic
% Initialize W
Vinit = ones(length(true_volt),1).*exp(1i*round(angle(true_volt)/(pi/6))*(pi/6));
Winit=[real(Vinit);imag(Vinit)]*[real(Vinit);imag(Vinit)]';
Winit=W;
results=SDPDSE_clean(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,W,Winit)
toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %% Combined
% % 
% % % [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W]=GenMeasurements(c,noise_level);
% % [Z,~,~,~,~,~,Ycomb,~,~,~,~,ybus,basekv,Ybase,true_volt]=GenMeasurements_tmp(c,noise_level);
% % 
% % p = dsswrite(c,[],0,[]); o = actxserver('OpendssEngine.dss');
% % dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
% % dssText.Command = ['Compile "' p '"']; 
% % dssCircuit = o.ActiveCircuit;
% % Names=dssCircuit.AllBusNames;
% % Names{end+1}='source';
% % 
% % for ii=1:length(Z)
% % 	Z{ii,6}=find(ismember(lower(Names),lower(strtok(Z(ii,2),'.'))));
% % 	Z{ii,7}=find(ismember(lower(Names),lower(strtok(Z(ii,3),'.'))));
% % 	Z{ii,2}=find(ismember(Ycomb,Z(ii,2)));
% % 	Z{ii,3}=find(ismember(Ycomb,Z(ii,3)));
% % end
% % Z=cell2mat(Z);
% % Z(find(Z(:,1)==1),3)=0;
% % Z(find(Z(:,1)==2),3)=0;
% % Z(find(Z(:,1)==5),3)=0;
% % Z(find(Z(:,1)==1),7)=0;
% % Z(find(Z(:,1)==2),7)=0;
% % Z(find(Z(:,1)==5),7)=0;
% % V_Meas=find(Z(:,1)==5);
% % 
% % [zdata]=Convert_Z_toWLSForm(Z);
% % true_volt2=results.Umag2(:,2).*exp(1i*results.Udeg2(:,2));
% % [State_Estimate]=Estimate_State(ybus,zdata,[],dssCircuit,Ycomb,Ybase,true_volt2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting

figure;
subplot(211);plot([State_Estimate(:,1)],'b*'); xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); 
hold on
subplot(212);plot([State_Estimate(:,2)],'b*'); xlabel('Bus Number'); ylabel('Voltage Angle (degree)');
hold on;

subplot(211);plot(1:length(results.Umag2(:,2)),results.Umag2(:,2),'go',1:length(results.Umag(:,2)),results.Umag(:,2),'k','linewidth',2);legend({'WLS' 'SDP' 'True'},'location','best');
title(['Feeder ' FeederNum])
subplot(212);plot(1:length(results.Udeg2(:,2)),results.Udeg2(:,2),'go',1:length(results.Udeg(:,2)),results.Udeg(:,2),'k','linewidth',2); %legend({'WLS' 'SDP' 'True'});

