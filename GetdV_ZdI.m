Ybus=dssCircuit.SystemY;
ineven=2:2:length(Ybus); inodd=1:2:length(Ybus);
Ybus=Ybus(inodd)+1i*Ybus(ineven); Ybus=reshape(Ybus,sqrt(length(Ybus)),sqrt(length(Ybus)));
Ycomb=dssCircuit.YNodeOrder;
Ycomb=dssCircuit.YNodeOrder;
[YbusOrderVect, YbusPhaseVect]=strtok(dssCircuit.YNodeOrder,'\.');
YbusPhaseVect=str2num(cell2mat(strrep(YbusPhaseVect,'.','')));
Zbus=inv(Ybus);

S_LD=zeros(length(Zbus),1);
dssLoads=dssCircuit.Loads;
%% set up S_LD
pelem = dssLoads.First;
while pelem>0
	dssCircuit.SetActiveElement(dssLoads.Name);
	BusName=dssCircuit.ActiveElement.BusNames;
	
	s_ld=dssLoads.kW+1i*dssLoads.kvar;
	
	if isempty(regexp(BusName{:},'\.','match')) %3 PhaseInd
				Ind=find(ismemberi(YbusOrderVect,BusName));
				S_LD(Ind)=S_LD(Ind)+s_ld/3;
			elseif length(regexp(BusName{:},'\.','match'))>1 %2 PhaseInd
				name=regexp(BusName{:},'\.','split');
				numPhases=length(name)-1;
				
				if numPhases==2 
					for ii=2:length(name)
						Ind=find(ismemberi(Ycomb,[name{1} '.' name{ii}]));
						S_LD(Ind)=S_LD(Ind)+s_ld/numPhases;
					end
				end
			else %1 PhaseInd
				Ind=find(ismemberi(Ycomb,BusName{:}));
				S_LD(Ind)=S_LD(Ind)+s_ld;
	end
			
	pelem = dssLoads.Next;
end

dV=abs(Zbus*((1-ConsumptionP)+1i*(1-ConsumptionQ)));
% 
% LD=sum(S_LD,2); %Change top include pv/gen
% I=conj(LD).*conj(1./diag(V2/sqrt(3)));
% Vvect=Zbus*I;
% NewV_pu=abs(((diag(V2)/sqrt(3))-Vvect./1000)./(diag(V2)/sqrt(3)));
% 
% for ii=1:length(Vvect)
% 	for jj=ii:length(Vvect)
% 		deltaV(ii,jj)=abs(Vvect(ii))-abs(Vvect(jj));
% 		deltaV_pu(ii,jj)=NewV_pu(ii)-NewV_pu(jj);
% 		deltaVactual(ii,jj)=powerFlowFull.Voltage(ii)-powerFlowFull.Voltage(jj);
% 	end
% end

%dV=ZdI

