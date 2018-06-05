clear
p='c:\users\zactus\feederReduction\Alpine_SI.dss';
tic
%%% createPTDF
useSaved=1;
if ~useSaved

criticalBuses={'sourcebus'}
cd c:/users/zactus/FeederReduction/
[circuit, circuit_orig, powerFlowFull, powerFlowReduced, pathToFile] = reducingFeeders_Final_SI(p,criticalBuses,[],1);

k=load('Alpine_SI_orig_circuit')
All=strtok(circuit_orig.pvsystem(:).bus1,'.');
for ii=1:length(k.circuit.pvsystem)
	New=strtok(k.circuit.pvsystem(ii).bus1,'.');
	Inds=find(ismember(All,New));
	Map(Inds)=ii;
end

save('CircuitRed.mat')
else
	load('CircuitRed.mat')
end
load('c:/users/Zactus/feederReduction/AlpineConf.mat');
c=circuit_orig;
dt=30;
timeStart='2014-12-26';
timeEnd='2014-12-26 00:24:30';
% timeEnd='2014-12-26 00:08:30';

timeDay=cellstr(datestr(datenum(timeStart):1:datenum(timeEnd)));
tDay = timeDay{1}; indent = '      ';
t = datenum(timeStart) : dt/24/3600 : (datenum(timeEnd));

ls0=zeros(2880,1);
ls1=ones(2880,1);
ls2=ls1;
ls2(1:50)=linspace(1,.01,50);

c.loadshape(1)=dssloadshape;
c.loadshape(end).name='loadshape_unity';
c.loadshape(end).mult=ls1;
c.loadshape(end).Npts=2880;
c.loadshape(end).sInterval=30;
c.loadshape(end).Interval=1;

c.loadshape(2)=c.loadshape(end);
c.loadshape(end).name='loadshape_var';
c.loadshape(end).mult=ls2;
c.loadshape(end).Npts=2880;
c.loadshape(end).sInterval=30;
c.loadshape(end).Interval=1;

c.loadshape(3)=dssloadshape;
c.loadshape(end).name='loadshape_zero';
c.loadshape(end).mult=ls0;
c.loadshape(end).Npts=2880;
c.loadshape(end).sInterval=30;
c.loadshape(end).Interval=1;

for ii=1:length(c.load)
	c.load(ii).daily='loadshape_unity';
% 	c.load(ii).kw=c.load(ii).kw*4;
% 		c.load(ii).model=1;
% 	c.load(ii).daily='loadshape_var';

end
for ii=1:length(c.pvsystem)
	c.pvsystem(ii).daily='loadshape_unity';
	c.pvsystem(ii).irradiance=1;
% 	c.pvsystem(ii).model=1;
% 	c.pvsystem(ii).pmpp=c.pvsystem(ii).pmpp*4;
end

for ii=1:length(c.pvsystem)
% 	ii=616
	c.pvsystem(ii).daily='loadShape_var';
	res = dssSimulation_simple(c, conf.mode, t, tDay, [],0);
	%get equation relating to voltage vs loading
	for jj=1:size(res.Voltage,2)
		PTDF_pv(ii,jj,:)=polyfit(c.loadshape(2).mult(1:50),res.Voltage(:,jj),3);
	end

	c.pvsystem(ii).daily='loadshape_unity';
end
%%
for ii=1:length(c.load)
	ii
	c.load(ii).daily='loadShape_var';
	res = dssSimulation_simple(c, conf.mode, t, tDay, [],0);
	%get equation relating to voltage vs loading
	for jj=1:size(res.Voltage,2)
		PTDF_l(ii,jj,:)=polyfit(c.loadshape(2).mult(1:50),res.Voltage(:,jj),3);
	end

	c.load(ii).daily='loadshape_unity';
end
PTDF_l_real=PTDF_l;
PTDF_pv_real=PTDF_pv;
toc
save('Sensitivy_file_real.mat','PTDF_l_real','PTDF_pv_real')