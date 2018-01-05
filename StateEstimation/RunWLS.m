% FR state stimation
% clear
%% WLS
c = dssparse('C:\Users\Zactus\feederReduction\4Bus-YY-Bal\4Bus-YY-Bal.DSS');

critical_nodes={'611','652','675','692'};
% load('c:\users\zactus\FeederReductionRepo\StateEstimation\Z_New.mat');
% [c] = FeederReduction_SE(critical_nodes,c,Z);
noise_level=0;

	
% [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W]=GenMeasurements(c,noise_level);
[Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,Ybus,basekv,Ybase,volt00]=GenMeasCode(c,noise_level);

