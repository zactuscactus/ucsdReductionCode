[ControlIter,Element,Action,VAVGPU10224,VPRIORPU0,kvar] = importEventLog('c:\users\zactus\gridIntegration\tmp\newFR\Alp_mod_Reduced_EventLog.Txt', 1, inf);
kVarRecordInd=find(~cellfun(@isempty,kvar));

%delete other entries
kvar=kvar(kVarRecordInd);
ControlIter=ControlIter(kVarRecordInd);
Element=Element(kVarRecordInd);

%remove text
kvar=cellfun(@str2num,regexprep(kvar,'KVAR= ',''));
ControlIter=cellfun(@str2num,regexprep(ControlIter,'ControlIter=',''));
Element=regexprep(Element,'Element=InvControl.invfor','');

valueSet = lower(Element);
keySet = lower(circuit.pvsystem(:).name);
mapObj = containers.Map(keySet,1:length(keySet));
MatchOrder=(cell2mat(values(mapObj,valueSet)));

Q=zeros(length(circuit.pvsystem),max(ControlIter));

for ii=1:length(circuit.pvsystem)
	Ind=find(MatchOrder==ii);
	Q(ii,ControlIter(Ind))=kvar(Ind);
	[MaxIter,Index]=max(ControlIter(Ind));
	Q(ii,MaxIter+1:end)=kvar(Ind(Index));
end

figure;plot(Q')
xlabel('Iteration [-]','fontsize',12)
ylabel('Q [kVAr]','fontsize',12)


