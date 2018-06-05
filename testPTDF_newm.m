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

vBase=dssCircuit.AllBusVolts;
ineven=2:2:length(vBase); inodd=1:2:length(vBase);
vBase=vBase(inodd)+1i*vBase(ineven); vBase=vBase;
%% change P
ConsumptionP_pf=.01*ones(length(dssCircuit.Loads.AllNames),1);
% ConsumptionP_pf(1)=1;
% ConsumptionP_pf(2:end)=1;
pelem=dssCircuit.Loads.First;
ii=0;
while pelem>0
	ii=ii+1;
load_orig(ii)=dssCircuit.Loads.kw;
dssCircuit.Loads.kw=dssCircuit.Loads.kw*ConsumptionP_pf(ii);
dP_pf(ii)=load_orig(ii)*(1-ConsumptionP_pf(ii));
pelem=dssCircuit.Loads.Next;
end

%% solve
dssSolution.Solve;
Volt_p=dssCircuit.AllBusVolts;
ineven=2:2:length(Volt_p); inodd=1:2:length(Volt_p);
Volt_p=Volt_p(inodd)+1i*Volt_p(ineven);% Volt_p=abs(Volt_p./vBase);

dP_pFull=repmat(dP_pf,length(dssCircuit.AllNodeNames),1)';
dVFull_p=zeros(size(dP_pFull));
dVFull_q=zeros(size(dP_pFull));
for ii=1:size(PTDF_p,3)-1
	dVFull_p=dVFull_p+(dP_pFull.^(size(PTDF_p,3)-ii)).*PTDF_p(:,:,ii);
	dVFull_q=dVFull_q+(dP_pFull.^(size(PTDF_q,3)-ii)).*PTDF_q(:,:,ii);
end

if size(dVFull_p,1)>1
	dVFull_p=sum(dVFull_p);
	dVFull_q=sum(dVFull_q);
end

VoltPredict=abs((V_o+dVFull_p+1i*dVFull_q)./vBase);
figure;plot(VoltPredict)
hold on;plot(abs(Volt_p./vBase))
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
