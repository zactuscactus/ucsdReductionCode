% p='c:\users\zactus\feederReduction\13Bus\IEEE13Nodeckt.dss';
% p='c:\users\zactus\feederReduction\4Bus-YY-Bal.dss';
p='C:\Program Files\OpenDSS\IEEETestCases\37Bus\ieee37.dss';
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
%% change P
% ConsumptionP=0.1*ones(length(dssCircuit.Loads.AllNames),1);
% 
% dssCircuit.Loads.First;
% for ii=1:1
% load_orig(ii)=dssCircuit.Loads.kw;
% kvarOrig=dssCircuit.Loads.kvar;
% dssCircuit.Loads.kvar=kvarOrig;
% dssCircuit.Loads.kw=dssCircuit.Loads.kw*ConsumptionP(ii);
% dP(ii)=load_orig(ii)*(1-ConsumptionP(ii));
% dssCircuit.Loads.kvar=kvarOrig;
% dssCircuit.Loads.Next;
% end

ConsumptionP_pf=0.1*ones(length(dssCircuit.Loads.AllNames),1);

dssCircuit.Loads.First;
for ii=1:1
load_orig(ii)=dssCircuit.Loads.kw;
% kvarOrig=dssCircuit.Loads.kvar;
% dssCircuit.Loads.kvar=kvarOrig;
dssCircuit.Loads.kw=dssCircuit.Loads.kw*ConsumptionP(ii);
dP_pf(ii)=load_orig(ii)*(1-ConsumptionP(ii));
% dssCircuit.Loads.kvar=kvarOrig;
dssCircuit.Loads.Next;
end
% %% change Q
% ConsumptionQ=0.1*ones(length(dssCircuit.Loads.AllNames),1);
% 
% dssCircuit.Loads.First;
% for ii=1:1
% kvar_orig(ii)=dssCircuit.Loads.kvar;
% dssCircuit.Loads.kvar=kvar_orig(ii)*ConsumptionQ(ii);
% dQ(ii)=kvar_orig(ii)*(1-ConsumptionQ(ii));
% dssCircuit.Loads.Next;
% end

%% solve
dssSolution.Solve;
Volt_p=dssCircuit.AllBusVmagPu;
% 
% %PREDICT FROM ptdf
% dPFull=repmat(dP,length(dssCircuit.AllNodeNames),1)';
% % dVFull_p=sum((dPFull.^3).*PTDF_p(:,:,1)+(dPFull.^2).*PTDF_p(:,:,2)+(dPFull).*PTDF_p(:,:,3));
% % dVFull_p=(dPFull.^3).*PTDF_p(:,:,1)+(dPFull.^2).*PTDF_p(:,:,2)+(dPFull).*PTDF_p(:,:,3);
% dVFull_p=zeros(size(dPFull));
% for ii=1:size(PTDF_p,3)-1
% 	dVFull_p=dVFull_p+(dPFull.^(size(PTDF_p,3)-ii)).*PTDF_p(:,:,ii);
% end
% 
% if size(dVFull_p,1)>1
% 	dVFull_p=sum(dVFull_p);
% end


dP_pfFull=repmat(dP_pf,length(dssCircuit.AllNodeNames),1)';
% dVFull_p=sum((dPFull.^3).*PTDF_p(:,:,1)+(dPFull.^2).*PTDF_p(:,:,2)+(dPFull).*PTDF_p(:,:,3));
% dVFull_p=(dPFull.^3).*PTDF_p(:,:,1)+(dPFull.^2).*PTDF_p(:,:,2)+(dPFull).*PTDF_p(:,:,3);
dVFull_pf=zeros(size(dP_pfFull));
for ii=1:size(PTDF_p,3)-1
	dVFull_pf=dVFull_pf+(dP_pfFull.^(size(PTDF_pf,3)-ii)).*PTDF_pf(:,:,ii);
end

if size(dVFull_pf,1)>1
	dVFull_pf=sum(dVFull_pf);
end

% %PREDICT FROM ptdf
% dQFull=repmat(dQ,length(dssCircuit.AllNodeNames),1)';
% % dVFull_q=sum((dQFull.^3).*PTDF_q(:,:,1)+(dQFull.^2).*PTDF_q(:,:,2)+(dQFull).*PTDF_q(:,:,3));
% % dVFull_q=sum((dQFull.^2).*PTDF_q(:,:,1)+(dQFull).*PTDF_q(:,:,2));
% % dVFull_q=sum((dQFull).*PTDF_q(:,:,1));
% dVFull_q=zeros(size(dQFull));
% for ii=1:size(PTDF_q,3)-1
% 	dVFull_q=dVFull_q+(dQFull.^(size(PTDF_q,3)-ii)).*PTDF_q(:,:,ii);
% end
% if size(dVFull_q,1)>1
% 	dVFull_q=sum(dVFull_q);
% end

% VoltPredict=V_o+dVFull_p+dVFull_q;
VoltPredict=V_o+dVFull_pf;

% VoltPredict=dVFull_p+dVFull_q;
% VoltPredict=dVFull_p;
figure;plot(VoltPredict)
hold on;plot(Volt_p)
legend('PTDF Predicted', 'Measured')
xlabel('Node')
ylabel('Voltage [pu]')
max(abs(Volt_p-VoltPredict))

% figure;plot(dVFull_p+dVFull_q)
figure;plot(dVFull_pf)
hold on;plot(-V_o+Volt_p)
legend('PTDF Predicted', 'Measured')
xlabel('Node')
ylabel('Voltage deviation from full load [pu]')
% max(abs(V_o-Volt_p+dVFull_p+dVFull_q))
max(abs(V_o-Volt_p+dVFull_pf))



% %% try dV=ZdI method
% p='c:\users\zactus\feederReduction\4Bus-YY-Bal_nl.dss';
% [Zbus, Ybus, Ycomb, YbusOrderVect, YbusPhaseVect, vBase] = getYbusNoLoad(p);
% 
% p='c:\users\zactus\feederReduction\4Bus-YY-Bal.dss';
% 
% global o;
% o = actxserver('OpendssEngine.dss');
% o.Start(0);
% dssText = o.Text;
% dssText.Command = 'Clear';
% cDir = pwd;
% dssText.Command = ['Compile "' p '"'];
% cd(cDir);
% dssText.Command = 'Set controlmode = off';
% dssText.Command = ['Set mode = snapshot' ];
% dssCircuit = o.ActiveCircuit;
% dssSolution = dssCircuit.Solution;
% dssSolution.MaxControlIterations=1000;
% dssSolution.MaxIterations=500;
% dssSolution.InitSnap; % Initialize Snapshot solution
% dssSolution.dblHour = 0.0;
% 
% S_LD=zeros(length(Zbus),1);
% C_LD=zeros(length(Zbus),1);
% dssLoads=dssCircuit.Loads;
% 
% pelem = dssLoads.First;
% ii=0;
% while pelem>0
% 	ii=ii+1;
% 	dssCircuit.SetActiveElement(dssLoads.Name);
% 	BusName=dssCircuit.ActiveElement.BusNames;
% 	
% 	s_ld=dssLoads.kW+1i*dssLoads.kvar;
% 	c_ld=ConsumptionP(ii)+1i*ConsumptionQ(ii);
% 	if isempty(regexp(BusName{:},'\.','match')) %3 PhaseInd
% 				Ind=find(ismemberi(YbusOrderVect,BusName));
% 				S_LD(Ind)=S_LD(Ind)+s_ld/3;
% 				C_LD(Ind)=C_LD(Ind)+c_ld/3;
% 			elseif length(regexp(BusName{:},'\.','match'))>1 %2 PhaseInd
% 				name=regexp(BusName{:},'\.','split');
% 				numPhases=length(name)-1;
% 				
% 				if numPhases==2 
% 					for ii=2:length(name)
% 						Ind=find(ismemberi(Ycomb,[name{1} '.' name{ii}]));
% 						S_LD(Ind)=S_LD(Ind)+s_ld/numPhases;
% 						C_LD(Ind)=C_LD(Ind)+c_ld/numPhases;
% 					end
% 				end
% 			else %1 PhaseInd
% 				Ind=find(ismemberi(Ycomb,BusName{:}));
% 				S_LD(Ind)=S_LD(Ind)+s_ld;
% 				C_LD(Ind)=C_LD(Ind)+c_ld;
% 	end
% 			
% 	pelem = dssLoads.Next;
% end
% 
% I=conj(S_LD).*conj(1./(vBase/1000));
% Vo=Zbus*I;
% Vn=Zbus*(I.*C_LD);
% dV=Vn-Vo;
% dv=abs(Zbus*(I-(I.*C_LD))./vBase);
%% calc dv
for ii=1:length(Volt_p)
	for jj=ii:length(Volt_p)
		voltReal(ii,jj)=Volt_p(ii)-Volt_p(jj);
		voltPTDF(ii,jj)=VoltPredict(ii)-VoltPredict(jj);
	end
end

figure;surf(voltReal-voltPTDF)
