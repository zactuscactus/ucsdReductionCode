% code to run timeseries

%% step 1: Load full circuit 
clear
% p='c:\users\zactus\feederReduction\4Bus-YY-Bal.dss';
p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';

%% Step 2: Reduce
criticalBuses={'sourcebus','650','rg60','633','634','671','645','646','611','652','670','632','680','684'}%,'692'}
cd c:/users/zactus/FeederReduction/
[circuit, circuit_orig, powerFlowFull, powerFlowReduced, pathToFile] = reducingFeeders_Final_SI(p,criticalBuses,[],1)

%% step 3: calc sensitivities
V_o=powerFlowFull.Voltage;
NodeOrder=powerFlowFull.nodeName;

for ii=1:length(circuit.load)
	loadOrig(ii)=circuit.load(ii).kw;
	kkCount=0;
	for kk=500:-1:1
		kkCount=kkCount+1;
		loadNew=loadOrig(ii)*(kk/500);
		circuit.load(ii).kw=loadNew;
		[ pf ] = dssSimulation( circuit,[],1,[],[],0);

		loadDiff(kkCount)=loadOrig(ii)-loadNew;
		Vp(kkCount,:,ii)=pf.Voltage;
	end
	
	%get equation relating to voltage vs loading
	for jj=1:size(Vp,2)
		PTDF_p(ii,jj,:)=polyfit(loadDiff',Vp(:,jj,ii),3);
	end
end

%% step 4: define loadshape and solve full circuit
K=[1 .6 .2 .6 1];

[ powerFlowFullControl ] = dssSimulationControl( circuit_orig,[],1,[],[],0);
[ powerFlowFull2 ] = dssSimulation( circuit_orig,[],1,[],[],0);
V_full=powerFlowFull2.Voltage;
V_full_Control=powerFlowFullControl.Voltage;

%% step 5: apply dv  and write file
[dssFile, circuit] = ApplyCurves(circuit,circuit_orig,PTDF_p,NodeOrder,loadOrig,V_o)

%% step 6: define circuit and simulation

[ powerFlowRedControl ] = dssSimulationControl( circuit,[],1,[],[],0);
[ powerFlowRed2 ] = dssSimulation( circuit,[],1,[],[],0);
V_red=powerFlowRed2.Voltage;
V_red_Control=powerFlowRedControl.Voltage;

%% step 7: Calc differences
for ii=1:length(powerFlowRed2.nodeName)
	Keep(ii)=find(ismemberi(powerFlowFull2.nodeName,powerFlowRed2.nodeName(ii)));
end

voltDiff=abs(V_full(Keep)-V_red)'
voltDiff_Control=abs(V_full_Control(Keep)-V_red_Control)'