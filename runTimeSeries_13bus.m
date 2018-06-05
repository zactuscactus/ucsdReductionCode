% code to run timeseries

%% step 1: Load full circuit 
clear
clc
% p='c:\users\zactus\feederReduction\4Bus-YY-Bal.dss';
p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
% p='c:\users\zactus\feederReduction\37Bus\ieee37.dss';
% p='c:\users\zactus\feederReduction\123Bus\IEEE123Master.dss';
% p='c:\users\zactus\feederReduction\Alpine_SI.dss';
global o;
o = actxserver('OpendssEngine.dss');
o.Start(0);
dssText = o.Text;
dssText.Command = 'Clear';
cDir = pwd;
dssText.Command = ['Compile "' p '"'];
cd(cDir);
dssText.Command = 'Set controlmode = off';
dssText.Command = ['Set mode = snapshot'];
dssText.Command = ['Set stepsize = 30s'];
dssText.Command = 'Set number = 1'; % number of time steps or solutions to run or the number of Monte Carlo cases to run.
dssCircuit = o.ActiveCircuit;
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=1000;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.dblHour = 0.0;

%% Step 2: Reduce
% criticalBuses={'sourcebus','799','709','775','701','702','705','713','703','727','730','704','714','720','742','712','706','725','707','724','722','708','733','732','731','710','735','736','711','740','718','744','734','737','738','728','729','799r','741'};%,'741'
% criticalBuses={'150','150r','149','1','2','3','7','4','5','6','8','12','9','13','9r','14','34','18','11','10','15','16','17','19','21','20','22','23','24','25','25r','26','28','27','31','33','29','30','250','32','35','36','40','37','38','39','41','42','43','44','45','47','46','48','49','50','51','151','52','53','54','55','57','56','58','60','59','61','62','63','64','65','66','67','68','72','97','69','70','71','73','76','74','75','77','86','78','79','80','81','82','84','83','85','87','88','89','90','91','92','93','94','95','96','98','99','100','450','197','101','102','105','103','104','106','108','107','300','135','152','160r','160','61s','300_open','94_open','610'};%'109','110','111','112','113','114'
criticalBuses={'sourcebus','650','rg60','633','634','671','645','646','611','652','670','632','680','684','675'}%,'692'}
% useSaved=0;
% if ~useSaved

% criticalBuses={'sourcebus'}
cd c:/users/zactus/FeederReduction/
[circuit, circuit_orig, powerFlowFull, powerFlowReduced, pathToFile] = reducingFeeders_Final_SI(p,criticalBuses,[],1);

% k=load('Alpine_SI_orig_circuit')
% All=strtok(circuit_orig.pvsystem(:).bus1,'.');
% for ii=1:length(k.circuit.pvsystem)
% 	New=strtok(k.circuit.pvsystem(ii).bus1,'.');
% 	Inds=find(ismember(All,New));
% 	Map(Inds)=ii;
% end
% 
% save('CircuitRed.mat')
% else
% 	load('CircuitRed.mat')
% end
%% step 3: calc sensitivities
dssText.Command = ['Compile "' p '"'];
dssText.Command = 'Set controlmode = off';
dssSolution.MaxControlIterations=1000;
dssSolution.MaxIterations=500;
dssSolution.Solve;
V_o=powerFlowFull.Voltage;
NodeOrder=powerFlowFull.nodeName;
tic 
pelem=dssCircuit.Loads.First;
ii=0;
while pelem>0
	ii=ii+1;
	loadOrig(ii)=dssCircuit.Loads.kw;
	kvarOrig=dssCircuit.Loads.kvar;
	kkCount=0;
	for kk=100:-1:1
		kkCount=kkCount+1;
		loadNew=loadOrig(ii)*(kk/500);
		dssCircuit.Loads.kw=loadNew;
		dssCircuit.Loads.kvar=kvarOrig;
		dssSolution.Solve;
		loadDiff(kkCount)=loadOrig(ii)-loadNew;
		Vp(kkCount,:,ii)=dssCircuit.AllBusVmagPu;
	end
	dssCircuit.Loads.kw=loadOrig(ii);
	dssCircuit.Loads.kvar=kvarOrig;
	pelem=dssCircuit.Loads.Next;
	
	%get equation relating to voltage vs loading
	for jj=1:size(Vp,2)
		PTDF_p(ii,jj,:)=polyfit(loadDiff',Vp(:,jj,ii),3);
	end
end
toc
%% step 4: define loadshape and solve full circuit
% load loadshape
% load('c:/users/Zactus/feederReduction/AlpineConf.mat');
% global conf
% timeStart='2014-12-26';
% timeEnd='2014-12-27';
% timeDay=cellstr(datestr(datenum(timeStart):1:datenum(timeEnd)));
% fName='Alpine';
% deploySite=conf.deployment;
% loop through days of simulation
% for tId = 1:length(timeDay)
% 	tDay = timeDay{tId}; indent = '      ';
% 	fprintf('%sDay: %s\n',indent,tDay);
% 	
% 	all time steps for simulation
% 	dt = 30; % in seconds
% 	t = datenum(tDay) : dt/24/3600 : (datenum(tDay) + 1 - dt/24/3600); % starting from midnight and end before midnight next day
% 	
% 	load forecast GI profiles (only load the wanted profiles)
% 	fc = loadForecast( datestr(tDay,'yyyymmdd'), fName, conf.fcProfileId);
% 	if isempty(fc)
% 		fprintf('\n\nDay does not exist in forecast!\n\n')
% 		continue
% 	else
% 		fill in the holes in data with appropriate methods when needed. Look into the fillForecastProfile for more details.
% 		[fc,emptyProfId] = fillForecastProfile(fc,char(deploySite),fName,tDay);
% 		
% 		map new pv systems
% 		for ii=1:length(Map)
% 			profileTmp(:,ii)=fc.profile(:,Map(ii));
% 		end
% 		fc.profile=profileTmp;
% 		
% 		assign forecast profiles to pv systems
% 		[c_fc, fc2] = assignProfile(circuit_orig, 'pvsystem', fc, conf.fcProfileId, conf.fcTimeZone, t, conf.fcSmoothFactor );
% 		
% 		get load profile data
% 		[loadProf, rawProf] = getLoadProfile(fName,conf.loadProfileId,tId);
% 		
% 		assign load profiles to loads
% 		[c_fc, lp2] = assignProfile(c_fc, 'load', loadProf, conf.loadProfileId, conf.loadProfTZone, t, conf.loadProfSmooth);
% 		
% 		run simulation using OpenDSS engine
% 		res = dssSimulation1(c_fc, [], t, tDay, [],0);
% 		add info to result struct
% 		res.time = t; res.conf = conf; res.feederName = fName; res.feederSetup = fdSetup; res.feederOption = fdOpt; res.timeDay = tDay; res.penLevel = pen; res.penLevActual = penLevActual;
% 		
% 		save([fn],'-struct','res');
% 		fprintf(['%sSimulation result saved: ' fn '\n\n',indent]);
% 	end
% end
% K=[1 .6 .2 .6 1];

[ powerFlowFullControl ] = dssSimulationControl( circuit_orig,[],1,[],[],0);
[ powerFlowFull2 ] = dssSimulation1( circuit_orig,[],1,[],[],0);
V_full=powerFlowFull2.Voltage;
V_full_Control=powerFlowFullControl.Voltage;

%% step 5: apply dv  and write file
[dssFile, circuit] = ApplyCurves(circuit,circuit_orig,PTDF_p,NodeOrder,loadOrig,V_o)

%% step 6: define circuit and simulation
[ powerFlowRedControl ] = dssSimulationControl( circuit,[],1,[],[],0);
[ powerFlowRed2 ] = dssSimulation1( circuit,[],1,[],[],0);
V_red=powerFlowRed2.Voltage;
V_red_Control=powerFlowRedControl.Voltage;

%% step 7: Calc differences
for ii=1:length(powerFlowRed2.nodeName)
	Keep(ii)=find(ismemberi(powerFlowFull2.nodeName,powerFlowRed2.nodeName(ii)));
end

voltDiff=abs(V_full(Keep)-V_red)'
voltDiff_Control=abs(V_full_Control(Keep)-V_red_Control)'