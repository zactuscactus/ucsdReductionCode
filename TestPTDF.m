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
dssCircuit = o.ActiveCircuit;
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=1000;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.dblHour = 0.0;
% ConsumptionP=rand(15,1);
ConsumptionP=[0.553887065791275;0.680065530083361;0.367189905317367;0.239290606193545;0.578923492459094;0.866887054672508;0.406776760215226;0.112615141025047;0.443845836726957;0.300184401213900;0.401386853814493;0.833363563453134;0.403628662773607;0.390175938130607;0.360448893378945];
ConsumptionP=zeros(15,1);
ConsumptionP=.05*ones(15,1);

dssCircuit.Loads.First;
for ii=1:15
load_orig(ii)=dssCircuit.Loads.kw;
kvarOrig=dssCircuit.Loads.kvar;
dssCircuit.Loads.kvar=kvarOrig;
dssCircuit.Loads.kw=dssCircuit.Loads.kw*ConsumptionP(ii);
dP(ii)=load_orig(ii)*(1-ConsumptionP(ii));
dssCircuit.Loads.kvar=kvarOrig;
dssCircuit.Loads.Next;
end
dssSolution.Solve;
Volt_p=dssCircuit.AllBusVmagPu;
%PREDICT FROM ptdf
dPFull=repmat(dP,1,41);
dVFull_p=sum(dPFull.*PTDF_p);
VoltPredict=V_o-dVFull_p;
figure;plot(VoltPredict)
hold on;plot(Volt_p)
title('Only Change P')
legend('PTDF Predicted', 'Measured')
xlabel('Node')
ylabel('Voltage [pu]')
%% only change Q
p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
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
ConsumptionQ=rand(15,1);
% ConsumptionQ=[0.140255359269444;0.260130194112440;0.0868151008658337;0.429397337085805;0.257282784769860;0.297555384151118;0.424858411704626;0.119207259421287;0.495066923800459;0.706407227537561;0.243573372680951;0.785070081934006;0.0740895768609269;0.393883426981697;0.00339412296430741];
ConsumptionQ=.1*ones(15,1);
ConsumptionQ=.05*ones(15,1);
dssCircuit.Loads.First
for ii=1:15
load_orig(ii)=dssCircuit.Loads.kvar;
dssCircuit.Loads.kvar=dssCircuit.Loads.kvar*ConsumptionQ(ii);
dQ(ii)=load_orig(ii)*(1-ConsumptionQ(ii));
dssCircuit.Loads.Next;
end
dssSolution.Solve;
Volt_q=dssCircuit.AllBusVmagPu;
%PREDICT FROM ptdf
dQFull=repmat(dQ,1,41);
dVFull_q=sum(dQFull.*PTDF_q);
VoltPredict=V_o-dVFull_q;
figure;plot(VoltPredict)
hold on;plot(Volt_q)
legend('PTDF Predicted', 'Measured')
title('Only Change Q')
xlabel('Node')
ylabel('Voltage [pu]')
%% Change Both
p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
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
%1) Change Real Power
dssCircuit.Loads.First
for ii=1:15
load_orig(ii)=dssCircuit.Loads.kw;
kvarOrig=dssCircuit.Loads.kvar;
dssCircuit.Loads.kvar=kvarOrig;
dssCircuit.Loads.kw=dssCircuit.Loads.kw*ConsumptionP(ii);
dP(ii)=load_orig(ii)*(1-ConsumptionP(ii));
dssCircuit.Loads.kvar=kvarOrig;
dssCircuit.Loads.Next;
end
dssCircuit.Loads.First
for ii=1:15
load_orig(ii)=dssCircuit.Loads.kvar;
dssCircuit.Loads.kvar=dssCircuit.Loads.kvar*ConsumptionQ(ii);
dQ(ii)=load_orig(ii)*(1-ConsumptionQ(ii));
dssCircuit.Loads.Next;
end
dssSolution.Solve;
Volt_pq=dssCircuit.AllBusVmagPu;
%4) Predict votlage of modified circuit based on PTDF
dPFull=repmat(dP,1,41); dVFull_p=sum(dPFull.*PTDF_p);
dQFull=repmat(dQ,1,41); dVFull_q=sum(dQFull.*PTDF_q);
VoltPredict=V_o-(dVFull_p+dVFull_q);
%5) plot
figure;plot(VoltPredict)
hold on;plot(Volt_pq)
title('Change P and Q')
legend('PTDF Predicted', 'Measured')
xlabel('Node')
ylabel('Voltage [pu]')