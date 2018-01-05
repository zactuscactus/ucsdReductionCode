function [ Ycomb, vmag,theta,volt_base,voltComplex]=getVolt(circuit)

%Created by Zachary K. Pecenak on 6/18/2016

%Example input
% load('c:\users\zactus\gridIntegration\results\ValleyCenter_wpv_existing.mat')
% Bus_upstream={'03551325'};
% or Bus_upstream=c.buslist.id(ceil(length(c.buslist.id)*rand(1,1))) this is a random bus
% [c] = FeederReduction(Bus_upstream,c);
%Check both inputs are met

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get Ybus from OpenDSS for feeder.
fprintf('\nGetting YBUS and buslist from OpenDSS: ')
tic



%load the circuit and generate the YBUS
p = WriteDSS(circuit,'test',0,pwd); o = actxserver('OpendssEngine.dss');
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

[YbusOrderVect, YbusPhaseVect]=strtok(dssCircuit.YNodeOrder,'\.');
YbusPhaseVect=str2num(cell2mat(strrep(YbusPhaseVect,'.','')));
Ycomb=dssCircuit.YNodeOrder;

voltComplex=dssCircuit.YNodeVarray;
ineven=2:2:length(voltComplex); inodd=1:2:length(voltComplex);
voltComplex=voltComplex(inodd)+1i*voltComplex(ineven);

vmag=abs(voltComplex)*sqrt(3)/1000;
theta=round((angle(voltComplex))/(pi/6))*(pi/6);


OrderRegen = getMatchingOrder(dssCircuit.AllNodeNames,Ycomb);
vpu=dssCircuit.AllBusVmagPu;

volt_base=vmag./vpu(OrderRegen);
volt_base=round(volt_base*1000)/1000;

if isfield(circuit,'basevoltages')
	baseKv=circuit.basevoltages;
else
	baseKv=unique(cell2mat([circuit.transformer{:}.kV]));
end

if length(baseKv)>1
	baseKvMat=repmat(baseKv,length(vmag),1);
	VoltDiff = bsxfun(@minus,baseKvMat,volt_base');
	[~,Ind]=min(abs(VoltDiff),[],2);
	volt_base=baseKvMat(sub2ind(size(baseKvMat),[1:size(Ind,1)]',Ind));
else
	volt_base=repmat(baseKv,length(vmag),1);
end

delete(o);
clearvars o
t_=toc;
fprintf('time elapsed %f\n',t_)
end