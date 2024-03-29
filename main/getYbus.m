function [YbusOrderVect, YbusPhaseVect, Ycomb, Ybus, buslist]=getYbus(circuit,addSource)

%Created by Zachary K. Pecenak on 6/18/2016

%Example input
% load('c:\users\zactus\gridIntegration\results\ValleyCenter_wpv_existing.mat')
% Bus_upstream={'03551325'};
% or Bus_upstream=c.buslist.id(ceil(length(c.buslist.id)*rand(1,1))) this is a random bus
% [c] = FeederReduction(Bus_upstream,c);
%Check both inputs are met

if nargin<2
	addSource=0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get Ybus from OpenDSS for feeder.
fprintf('\nGetting YBUS and buslist from OpenDSS: ')
tic
if isfield(circuit,'pvsystem')
	circuit=rmfield(circuit,'pvsystem');
end
if isfield(circuit,'load')
	circuit=rmfield(circuit,'load');
end
if isfield(circuit,'regcontrol')
	circuit=rmfield(circuit,'regcontrol');
end


%load the circuit and generate the YBUS
p = WriteDSS(circuit,[circuit.circuit.name 'test'],0,pwd); o = actxserver('OpendssEngine.dss');
o.reset;
dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
dssText.Command = ['Compile "' p '"']; dssCircuit = o.ActiveCircuit;
dssText.Command = 'Set controlmode = off';
dssText.Command = ['Set mode = snapshot'];
dssText.Command = ['Set stepsize = 30s'];
dssText.Command = 'Set number = 1';
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=300;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.dblHour = 0.0;
dssSolution.Solve;
%Convert the Ybus to a matrix

for ii=1:1000
	try
		Ybus=dssCircuit.SystemY;
		break
	catch
		warning('Get Ybus Failed, trying one more time')
		delete(o);
		clearvars o
		
		p = WriteDSS(circuit,[circuit.circuit.name 'test'],0,pwd); o = actxserver('OpendssEngine.dss');
		o.reset;
		dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
		dssText.Command = ['Compile "' p '"']; dssCircuit = o.ActiveCircuit;
		dssText.Command = 'Set controlmode = off';
		dssSolution = dssCircuit.Solution;
		dssSolution.MaxControlIterations=100;
		dssSolution.MaxIterations=100;
		dssSolution.InitSnap; % Initialize Snapshot solution
		dssSolution.dblHour = 0.0;
		dssSolution.Solve;
	end
end
ineven=2:2:length(Ybus); inodd=1:2:length(Ybus);
Ybus=Ybus(inodd)+1i*Ybus(ineven); Ybus=reshape(Ybus,sqrt(length(Ybus)),sqrt(length(Ybus)));

[YbusOrderVect, YbusPhaseVect]=strtok(dssCircuit.YNodeOrder,'\.');
YbusPhaseVect=str2num(cell2mat(strrep(YbusPhaseVect,'.','')));
Ycomb=dssCircuit.YNodeOrder;
buslist=regexprep(dssCircuit.AllBUSNames,'-','_');

if addSource
	% Add sourcebus to circuit
	Ycomb(end+1:end+3)={'source.1' 'source.2' 'source.3'};
	dssCircuit.SetActiveElement('Vsource.SOURCE');
	Yprim = dssCircuit.ActiveElement.Yprim;
	Yprim0=Yprim(1:2:end)+1i*Yprim(2:2:end);
	NewYprimLength=sqrt(length(Yprim0));
	Yprim1=reshape(Yprim0,[NewYprimLength,NewYprimLength]);
	Yprim1(1:3,1:3)=0;
	Ybusnew=Ybus;
	Ybusnew(end+1:end+3,end+1:end+3)=0;
	Ybusnew([1:3,end-2:end],[1:3,end-2:end])=Ybusnew([1:3,end-2:end],[1:3,end-2:end])+Yprim1;
	Ybus=Ybusnew;
end

delete(o);
clearvars o
t_=toc;
fprintf('time elapsed %f\n',t_)
end