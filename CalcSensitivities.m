clear
p='c:\users\zactus\feederReduction\4Bus-YY-Bal.dss';
% p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
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

NodeOrder=dssCircuit.AllNodeNames;
dssSolution.Solve;
V_o=dssCircuit.AllBusVmagPu;

pelem=dssCircuit.Loads.First;
ii=0;
while pelem>0
	ii=ii+1;
	loadOrig=dssCircuit.Loads.kw;
	kvarOrig=dssCircuit.Loads.kvar;
	kkCount=0;
	for kk=5000:-1:1
		kkCount=kkCount+1;
		loadNew=loadOrig*(kk/5000);
		dssCircuit.Loads.kw=loadNew;
		dssCircuit.Loads.kvar=kvarOrig;
		dssSolution.Solve;
		loadDiff(kkCount)=loadOrig-loadNew;
		Vp(kkCount,:,ii)=dssCircuit.AllBusVmagPu;
	end
	dssCircuit.Loads.kw=loadOrig;
	dssCircuit.Loads.kvar=kvarOrig;
	pelem=dssCircuit.Loads.Next;
	
	%get equation relating to voltage vs loading
	for jj=1:size(Vp,2)
		PTDF_p(ii,jj,:)=polyfit(loadDiff',Vp(:,jj,ii),3);
	end
end