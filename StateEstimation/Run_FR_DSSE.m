% FR state stimation
% clear
%% SDP
c = dssparse('C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS');
% c = dssparse('C:\Users\Vahid\Google Drive\UCSD\Zack\State Estimation\Zack\WLS Code\IEEETestCases\4Bus-DY-Bal\4Bus-YY-Bal.DSS');
critical_nodes={'611','652','675','692'};
% load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% [c] = FeederReduction_SE(critical_nodes,c,Z);
noise_level=0;

% if ~exist('pre_nl','var') ||noise_level~=pre_nl 
%     close all
    pre_nl=noise_level;
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
% end

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