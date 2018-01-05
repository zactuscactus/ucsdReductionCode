% FR state stimation


c = dssparse('C:\Users\Zactus\Documents\OpenDSS\OpenDSS\IEEETestCases\4Bus-DY-Bal\4Bus-DY-Bal.DSS');
critical_nodes={'611','652','675','692'};

noise_level=1;

[Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,Ybus,basekv]=GenMeasurements(c,noise_level);

for ii=1:length(Z)
	Z{ii,2}=find(ismember(Ycomb,Z(ii,2)));
	Z{ii,3}=find(ismember(Ycomb,Z(ii,3)));
end
Z=cell2mat(Z);
Z(find(Z(:,1)==1),3)=0;
Z(find(Z(:,1)==2),3)=0;
Z(find(Z(:,1)==5),3)=0;

V_Meas=find(Z(:,1)==5);

results=SDPDSE(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,W)
