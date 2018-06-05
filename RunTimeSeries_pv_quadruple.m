%% step 1: Load full circuit 
clear
clc
cd c:/users/zactus/feederReduction/
p='c:\users\zactus\feederReduction\Alpine_75pen.dss';
tic


%% Step 2: Reduce
useSaved=0;
if ~useSaved

criticalBuses={'0355';'035510';'035510a';'035512';'03551201';'035513';'03551301';'03551301a';'03551304';'03551305';'03551306';'03551306a';'03551308';'03551308a';'03551311';'03551314';'03551318';'03551321';'03551322';'03551323';'03551324';'03551325';'03551327';'03551328';'03551328a';'03551333';'03551336';'03551337';'03551340';'03551341';'03551343';'03551346';'03551348';'03551350';'03551351';'03551353';'03551354';'03551355';'03551356';'03551357';'03551359';'03551361';'03551363';'03551365';'03551367';'03551368';'03551370';'03551371';'03551372';'03551374';'03551375';'03551379';'03551381';'03551382';'03551383';'03551383a';'03551385a';'03551387';'03551388';'03551389';'03551390';'03551393';'03551394a';'035515';'035516';'03551604';'035516a';'035517';'03551703';'03551704';'03551705';'03551706';'03551707';'03551708';'03551709';'03551710';'03551711';'03551713';'03551714';'03551715';'03551716';'035518';'03551803';'03552';'035520';'03552001';'035524';'035525';'03552501';'03552502';'03552503';'03552504';'03552508';'03552509';'03552510';'03552510a';'03552514';'03552515';'03552518';'03552521';'03552522';'03552523';'03552532';'03552534a';'03552536';'03552537';'03552537a';'03552541a';'03552544';'03552546';'03552547';'03552553';'03552555';'03552556';'03552562';'03552563';'03552564';'03552566';'03552570';'03552571';'03552571a';'03552572';'03552573';'03552574';'03552575';'03552576';'03552577';'03552578';'03552580';'03552581';'03552584a';'03552585';'03552587';'03552588';'03552589';'03552593';'03552594';'03552597';'03552598';'03552599';'035526';'03552601';'03552604';'03552606';'03552607';'03552608';'03552609';'03552610';'03552611';'03552612';'03552617';'03552618';'03552620';'03552621';'03552622';'03552625';'03552629';'03552631';'03552631a';'03552632';'03552636';'03552639';'03552639a';'03552641';'03552643';'03552644';'03552644a';'035527a';'035529';'03552902';'03553';'035532';'03553203a';'03553204';'03553205';'03553210';'035533';'03553303';'03553306';'03553307';'03553309';'03553310';'03553313';'03553314';'03553316';'03553317';'03553318';'03553322';'03553329';'03553331';'03553332';'03553336';'03553337';'03553337a';'03553338';'03553340';'035533a';'035534';'035535';'035536';'03553606';'03553607';'035538';'03553803';'03553805';'035538a';'035539';'035540';'03554002';'03554006';'03554007';'035541';'035542';'035542a';'035543';'03554301';'03554304';'03554305';'035544';'03554401';'03554401a';'03554402';'03554403';'03554405';'03554406';'03554409';'03554411';'03554412';'03554413';'03554415';'035546';'035548';'03554801';'03554802';'03554804';'03554807';'03554809';'035548a';'035549';'03554901';'03554902';'03554903';'03554904';'03554908';'03554912';'03554913';'03554916';'03555';'035550';'0355503';'035551';'035552';'035553';'035555';'03555504';'035556';'03555601';'03555604';'035557';'03555702';'035559';'03555a';'03556';'03558';'0355801';'03559';'0355902';'0355904';'0355905';'0355906';'0355907';'0355908';'0355908a';'0355910';'0355911';'0355912';'0355913';'0355915';'0355918';'0355923';'0355924';'0355925';'0355926';'0355927';'0355928';'0355930';'0355930a';'0355933';'0355933a';'0355934';'0355942';'0355949';'0355949a';'0355951';'sourcebus'};
cd c:/users/zactus/FeederReduction/
[circuit, circuit_orig, powerFlowFull, powerFlowReduced, pathToFile] = reducingFeeders_Final_SI(p,criticalBuses,[],1);

load('circuitMap.mat')

save('CircuitRed_ts_base.mat')
else
	load('CircuitRed_ts_base.mat')
end

%% Step 3: Load Sensitivites
load('Sensitivy_file_Alpine_75pen.mat')

%% Step 4: get loadshapes and solve full circuit
load('c:/users/Zactus/feederReduction/AlpineConf.mat');

cd c:/users/zactus/gridIntegration
def_addpath
cd c:/users/zactus/feederReduction/
c=circuit_orig;
dt=30;
%test PTDF for timeload('c:/users/Zactus/feederReduction/AlpineConf.mat');
global conf
timeStart='2014-11-21';
timeEnd='2014-11-21';

timeDay=cellstr(datestr(datenum(timeStart):1:datenum(timeEnd)));
conf.timeStart=timeStart;
conf.timeEnd=timeEnd;
conf.timeDay=timeDay;
fName='Alpine';
deploySite=conf.deployment;
circuit_orig.invcontrol(1).DeltaQ_factor=0.1;
% loop through days of simulation
for tId = 1:length(timeDay)
	tic
	tDay = timeDay{tId}; indent = '      ';
	fprintf('%sDay: %s\n',indent,tDay);
	
	% all time steps for simulation
	dt = 30; % in seconds
	t = datenum(tDay) : dt/24/3600 : (datenum(tDay) + 1 - dt/24/3600); % starting from midnight and end before midnight next day
	
	% load forecast GI profiles (only load the wanted profiles)
	fc = loadForecast( datestr(tDay,'yyyymmdd'), fName, conf.fcProfileId);
	if isempty(fc)
		fprintf('\n\nDay does not exist in forecast!\n\n')
		continue
	else
		% fill in the holes in data with appropriate methods when needed. Look into the fillForecastProfile for more details.
		cd c:/users/zactus/gridIntegration
		[fc,emptyProfId] = fillForecastProfile(fc,char(deploySite),fName,tDay);
		
		%map new pv systems
		for ii=1:length(Map)
			profileTmp(:,ii)=fc.profile(:,Map(ii));
		end
		fc.profile=profileTmp;
		profileTmp=[];
			
		% assign forecast profiles to pv systems
		[c_fc, fc2] = assignProfile(circuit_orig, 'pvsystem', fc, conf.fcProfileId, conf.fcTimeZone, t, conf.fcSmoothFactor );
		
		% get load profile data
		[loadProf, rawProf] = getLoadProfile(fName,conf.loadProfileId,tId);
		
		% assign load profiles to loads
		[c_fc, lp2] = assignProfile(c_fc, 'load', loadProf, conf.loadProfileId, conf.loadProfTZone, t, conf.loadProfSmooth);
		
		cd c:/users/zactus/feederReduction/
		% run simulation using OpenDSS engine
		res = dssSimulation_simple(c_fc, conf.mode, t, tDay, [],0);
		resControl = dssSimulation_simple_control(c_fc, conf.mode, t, tDay, [],0);

		% add info to result struct
		res.S_load=repmat([c_fc.load{:}.kw],length(t),1).*repmat(c_fc.loadshape(end).mult(1:length(t)),1,length(c_fc.load))+1i*repmat([c_fc.load{:}.kvar],length(t),1).*repmat(c_fc.loadshape(end).mult(1:length(t)),1,length(c_fc.load));
		res.S_PV=repmat([c_fc.pvsystem{:}.pmpp],length(t),1).*[c_fc.loadshape{1:end-1}.mult];
		
		%% calc ptdf
		%load
		ls_name=c_fc.load(1).Daily;
		ls_ind=find(ismemberi(c_fc.loadshape(:).name,ls_name));
		dP=c_fc.loadshape(ls_ind).mult(1:length(t));
		dP_all=repmat(dP,1,length(c_fc.load));
		
		%PV
		for ii=1:length(c_fc.pvsystem)
			ind=find(ismemberi(c_fc.loadshape(:).name,c_fc.pvsystem(ii).daily));
			dP_all(:,end+1)=c_fc.loadshape(ind).mult(1:length(t));
		end
		
		sens=[PTDF_l_real; PTDF_pv_real];
		%calc
		
		parfor jj=1:size(dP_all,1)
			dptmp=dP_all(jj,:);

			dP_lFull=1-repmat(dptmp,length(res.nodeName),1)';
			dVFull_l=zeros(size(dP_lFull));
			for ii=1:size(sens,3)-1
				dVFull_l=dVFull_l+(dP_lFull.^(size(sens,3)-ii)).*sens(:,:,ii);
			end
			
			if size(dVFull_l,1)>1
				dVFull_l=sum(dVFull_l);
			end
			
			V_predict(:,jj,tId)=sens(1,:,end)-dVFull_l;
			V_predict2(:,jj,tId)=V_o.Voltage(1,:)-dVFull_l;
		end
		S_load(:,:,tId)=res.S_load;
		S_PV(:,:,tId)=res.S_PV;
		V_real(:,:,tId)=res.Voltage';
		toc
	end
end

%% Step 5: Update loadshape for reduced circuit
fc_pv=[c_fc.loadshape{1:end-1}.mult];
fc_pv_red=fc_pv*circuit.Map_PVo_NODEo*circuit.Map_PVr_NODEo';
fc_ld_red=repmat(c_fc.loadshape(end).mult,1,length(circuit.load));
circuit.loadshape=dssloadshape;
for ii=1:size(fc_pv_red,2)
	circuit.loadshape(ii).name=['ls_pv' num2str(ii)];
	circuit.loadshape(ii).mult=fc_pv_red(:,ii);
	circuit.loadshape(ii).sinterval=30;
	circuit.loadshape(ii).Npts=length(fc_pv_red(:,ii));
	circuit.pvsystem(ii).daily=['ls_pv' num2str(ii)];
end

for ii=1:size(fc_ld_red,2)
	circuit.loadshape(end+1).name=['ls_ld' num2str(ii)];
	circuit.loadshape(end).mult=fc_ld_red(:,ii);
	circuit.loadshape(end).sinterval=30;
	circuit.loadshape(end).Npts=length(fc_ld_red(:,ii));
	circuit.load(ii).daily=['ls_ld' num2str(ii)];
end

for ii=1:length(circuit.invcontrol)
	ind=find(ismemberi(circuit.xycurve(:).name,circuit.invcontrol(ii).vvc_curve1));
	circuit.xycurve(ind).name=['curve_' num2str(ii)];
	circuit.invcontrol(ii).vvc_curve1=['curve_' num2str(ii)];
	circuit.invcontrol(ii).VarChangeTolerance=.025;
	circuit.invcontrol(ii).deltaQ_factor=.01;
end

%% Step 6: run Powerflow
data = dssSimulation_simple(circuit, conf.mode, t, tDay, [],0);
[ dataControl ] = dssSimulation_TS_control( circuit, conf.mode, t, V_predict,resControl.nodeName)

%% Step 7: error analysis

	for ii=1:length(dataControl.nodeName)
		Keep(ii)=find(ismemberi(resControl.nodeName,dataControl.nodeName(ii)));
	end

	voltDiff=(resControl.Voltage(:,Keep)-dataControl.Voltage)';
	[B,I]=sort(voltDiff);
	[diffV, ind]=max(abs(resControl.Voltage(:,Keep)-dataControl.Voltage));
	
		for ii=1:length(data.nodeName)
		Keep_noControl(ii)=find(ismemberi(res.nodeName,data.nodeName(ii)));
	end

	voltDiff_noControl=(res.Voltage(:,Keep)-data.Voltage)';
	
	save('OutputFromTS_Alpine_75pen.mat')