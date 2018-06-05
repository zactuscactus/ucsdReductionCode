function [Zbus, Ybus, Ycomb, YbusOrderVect, YbusPhaseVect, vBase] = getYbusNoLoad(p);

global o;
o = actxserver('OpendssEngine.dss');
o.Start(0);
dssText = o.Text;
dssText.Command = 'Clear';
cDir = pwd;
dssText.Command = ['Compile "' p '"'];
cd(cDir);
dssText.Command = 'Set controlmode = off';
dssText.Command = ['Set mode = snapshot' ];
dssCircuit = o.ActiveCircuit;
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=1000;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.dblHour = 0.0;

vBase=dssCircuit.AllBusVolts;
ineven=2:2:length(vBase); inodd=1:2:length(vBase);
vBase=vBase(inodd)+1i*vBase(ineven); vBase=transpose(vBase);


Ybus=dssCircuit.SystemY;
ineven=2:2:length(Ybus); inodd=1:2:length(Ybus);
Ybus=Ybus(inodd)+1i*Ybus(ineven); Ybus=reshape(Ybus,sqrt(length(Ybus)),sqrt(length(Ybus)));
Ycomb=dssCircuit.YNodeOrder;
[YbusOrderVect, YbusPhaseVect]=strtok(dssCircuit.YNodeOrder,'\.');
YbusPhaseVect=str2num(cell2mat(strrep(YbusPhaseVect,'.','')));
Zbus=inv(Ybus);