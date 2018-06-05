clear
p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
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
dssText.Command = ['Set stepsize = 30s'];
dssText.Command = 'Set number = 1'; % number of time steps or solutions to run or the number of Monte Carlo cases to run.
dssCircuit = o.ActiveCircuit;
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=1000;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.dblHour = 0.0;

%% Run Base Simulation
% dssCircuit.Loads.First;
% for ii=1:15
% 	dssCircuit.Loads.kw=dssCircuit.Loads.kw*(kk/10);
% 	dssCircuit.Loads.Next;
% end

NodeOrder=dssCircuit.AllNodeNames;
dssSolution.Solve;
V_o=dssCircuit.AllBusVmagPu;

dssCircuit.Loads.First;
for ii=1:15
	loadOrig=dssCircuit.Loads.kw;
	kvarOrig=dssCircuit.Loads.kvar;
	dssCircuit.Loads.kw=0;
	dssCircuit.Loads.kvar=kvarOrig;
	dssSolution.Solve;
	Vp(ii,:)=dssCircuit.AllBusVmagPu;
	dVp(ii,:)=V_o-Vp(ii,:);
	dP(ii,:)=loadOrig;
	PTDF_p(ii,:)=dVp(ii,:)./dP(ii,:);
	dssCircuit.Loads.kw=loadOrig;
	dssCircuit.Loads.kvar=kvarOrig;
	dssCircuit.Loads.Next;
end

dssCircuit.Loads.First;
for ii=1:15
	loadOrig=dssCircuit.Loads.kvar;
	dssCircuit.Loads.kvar=0;
	dssSolution.Solve
	Vq(ii,:)=dssCircuit.AllBusVmagPu;
	dVq(ii,:)=V_o-Vq(ii,:);
	dQ(ii,:)=loadOrig;
	PTDF_q(ii,:)=dVq(ii,:)./dQ(ii,:);
	dssCircuit.Loads.kvar=loadOrig;
	dssCircuit.Loads.Next;
end
