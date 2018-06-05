% p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
p='c:\users\zactus\feederReduction\4Bus-YY-Bal.dss';
% p='C:\Program Files\OpenDSS\IEEETestCases\37Bus\ieee37.dss';
global o;
o = actxserver('OpendssEngine.dss');
o.Start(0);
dssText = o.Text;
dssText.Command = 'Clear';
cDir = pwd;
dssText.Command = ['Compile "' p '"'];
cd(cDir);
dssText.Command = 'Set controlmode = off';
dssText.Command = 'set Algorithm=Newton';
dssText.Command = ['Set mode = snapshot' ];
dssCircuit = o.ActiveCircuit;
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=1000;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.dblHour = 0.0;

%% change P
ConsumptionP=.01*ones(length(dssCircuit.Loads.AllNames),1);
pelem=dssCircuit.Loads.First;
ii=0;
while pelem>0
	ii=ii+1;
load_orig(ii)=dssCircuit.Loads.kw;
dssCircuit.Loads.kw=dssCircuit.Loads.kw*ConsumptionP(ii);
dP(ii)=load_orig(ii)*(1-ConsumptionP(ii));
pelem=dssCircuit.Loads.Next;
end

%% solve
dssSolution.Solve;
Volt_p=dssCircuit.AllBusVmagPu;

dP_pFull=repmat(dP,length(dssCircuit.AllNodeNames),1)';
dVFull_p=zeros(size(dP_pFull));
for ii=1:size(PTDF_p,3)-1
	dVFull_p=dVFull_p+(dP_pFull.^(size(PTDF_p,3)-ii)).*PTDF_p(:,:,ii);
end

if size(dVFull_p,1)>1
	dVFull_p=sum(dVFull_p);
% 	dVFull_p=(prod(dVFull_p)).^(1/size(dVFull_p,1));
end

% VoltPredict=abs((V_o+dVFull_p+1i*dVFull_q)./vBase);
VoltPredict=abs(V_o+dVFull_p);
figure;plot(VoltPredict)
hold on;plot(abs(Volt_p))
legend('PTDF Predicted', 'Measured')
xlabel('Node')
ylabel('Voltage [pu]')
max(abs(Volt_p./vBase)-VoltPredict)

figure;plot(dVFull_p+1i*dVFull_q)
hold on;plot(-V_o+Volt_p)
legend('PTDF Predicted', 'Measured')
xlabel('Node')
ylabel('Voltage deviation from full load [pu]')
max(abs(V_o-Volt_p+abs(abs(dVFull_p+1i*dVFull_q)./vBase)))

%% calc dv
for ii=1:length(Volt_p)
	for jj=ii:length(Volt_p)
		voltReal(ii,jj)=Volt_p(ii)-Volt_p(jj);
		voltPTDF(ii,jj)=VoltPredict(ii)-VoltPredict(jj);
	end
end
figure;surf(voltReal-voltPTDF)
