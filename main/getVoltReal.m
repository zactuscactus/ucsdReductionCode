function [ Ycomb, vmag,theta,voltComplex,volt_base_complex,volt_base,volt_base_angle]=getVoltReal(circuit)

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

%get base values
volt_base_complex=dssCircuit.YNodeVarray;
ineven=2:2:length(volt_base_complex); inodd=1:2:length(volt_base_complex);
volt_base_complex=volt_base_complex(inodd)+1i*volt_base_complex(ineven);

volt_base=abs(volt_base_complex);
volt_base_angle=angle(volt_base_complex);

% get real Values
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

delete(o);
clearvars o
t_=toc;
fprintf('time elapsed %f\n',t_)
end