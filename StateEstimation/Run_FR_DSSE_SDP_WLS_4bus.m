% FR state stimation
clear
%% SDP
warning('off','all')
warning
noise_level=0;
pathToFile='C:\Users\Zactus\feederReduction\TestFeeder4.dss';
c=dssparse(pathToFile);

o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear';
dssText.Command = ['Compile "' pathToFile '"'];
dssCircuit = o.ActiveCircuit;
c.buslist.id=regexprep(dssCircuit.AllBUSNames,'-','_');
buslist=c.buslist.id;
c.buslist.coord=zeros(length(c.buslist.id),2);

 pre_nl=noise_level;
% [Z,~,~,~,~,~,YcombOrig,~,~,~,~,~,~,~,~]=GenerateMeasurements(c,noise_level);
[Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,ybus,basekv,Ybase,true_volt]=GenerateMeasurements(c,noise_level);
% [Zo,Yko,Ykbaro,Do,Yklo,Yklbaro,Ycombo,volto,volt1o,Mo,Wo,ybuso,basekvo,Ybaseo,true_volto]=GenerateMeasurements(c,noise_level);
ZOrig=Z;

p = dsswrite(c,[],0,pwd); o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
dssText.Command = ['Compile "' p '"']; 
dssCircuit = o.ActiveCircuit;
Names=dssCircuit.AllBusNames;
Names{end+1}='source';
for ii=1:length(Z)
	Z{ii,6}=find(ismemberi(lower(Names),lower(strtok(Z(ii,2),'.'))));
	Z{ii,7}=find(ismemberi(lower(Names),lower(strtok(Z(ii,3),'.'))));
	if isempty(find(ismemberi(Ycomb,Z(ii,2))))
		stop=1;
	end
	Z{ii,2}=find(ismemberi(Ycomb,Z(ii,2)));
	Z{ii,3}=find(ismemberi(Ycomb,Z(ii,3)));
end

Z=cell2mat(Z);
Z(find(Z(:,1)==1),3)=0;
Z(find(Z(:,1)==2),3)=0;
Z(find(Z(:,1)==5),3)=0;
Z(find(Z(:,1)==1),7)=0;
Z(find(Z(:,1)==2),7)=0;
Z(find(Z(:,1)==5),7)=0;


tic
WLS_SDP_Result_Full=WLS_with_SDP_PF_Model(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt,Ycomb);
toc


%% reduce
numBuses=14;%round((length(c.buslist.id)-1)*rand(1))+1;
CB=c.buslist.id(1:4);
% CB=c.buslist.id(round((length(c.buslist.id)-1)*rand(numBuses,1))+1);
% CB=c.buslist.id(1:15);
cd C:\Users\Zactus\feederReduction\
delete('c:\users\zactus\feederReduction\circuits\TestFeeder4_circuit.mat')
rmdir('c:\users\zactus\feederReduction\TestFeeder4\','s')
% [circuit,circuit_orig,~,~,Z] = reducingFeeders_Final_SE(pathToFile,CB,[],1,ZOrig);
Zbefore=Z;
[circuit, circuit_orig, ~, ~, ~,~,~,Z] = reducingFeeders_Final_SE(pathToFile,CB,[],1,ZOrig);
% [circuit, circuit_orig, ~, ~, ~,~,~,~] = reducingFeeders_Final_SE(pathToFile,CB,[],1,ZOrig);

[Zactual,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,ybus,basekv,Ybase,true_volt]=GenerateMeasurements(circuit,noise_level);

p = dsswrite(c,[],0,pwd); o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
dssText.Command = ['Compile "' p '"']; 
dssCircuit = o.ActiveCircuit;
Names=dssCircuit.AllBusNames;
Names{end+1}='source';
for ii=1:length(Z)
	Z{ii,6}=find(ismemberi(lower(Names),lower(strtok(Z(ii,2),'.'))));
	Z{ii,7}=find(ismemberi(lower(Names),lower(strtok(Z(ii,3),'.'))));
	if isempty(find(ismemberi(Ycomb,Z(ii,2))))
		stop=1;
	end
	Z{ii,2}=find(ismemberi(Ycomb,Z(ii,2)));
	Z{ii,3}=find(ismemberi(Ycomb,Z(ii,3)));
end

Z=cell2mat(Z);
Z(find(Z(:,1)==1),3)=0;
Z(find(Z(:,1)==2),3)=0;
Z(find(Z(:,1)==5),3)=0;
Z(find(Z(:,1)==1),7)=0;
Z(find(Z(:,1)==2),7)=0;
Z(find(Z(:,1)==5),7)=0;

% Z(:,5)=1;

Z0=Z;
    
V_Meas=find(Z(:,1)==5);


Z=Z0;
% Z(find(abs(Z(:,4))<=1e-4),5)=1e-10;
% Z(find(abs(Z(:,4))<=1e-4),4)=1e-10;
% Z(:,5)=abs(Z(:,4)).*Z(:,5);
V_Meas=find(Z(:,1)==5);

% Z(find(Z(:,1)==1),:)=[];
% Z(find(Z(:,1)==4),:)=[];

node_bus=sortrows(unique([Z(:,[2,6]);Z(:,[3,7])],'rows'),1);
node_bus(find(ismember(node_bus,[0,0],'rows')),:)=[];
[topo,generation]=topology_detect(circuit,node_bus(1:end-3,:));
parent=topo(:,2); parent(1)=length(parent)+1;parent(end+1)=length(parent)+1;
%parent=[5;1;2;3;5];
%parent=ones(length(dssCircuit.AllBusNames)+1,1);
[State_Estimate]=Estimate_State(ybus,Z,dssCircuit,Ycomb,Ybase,true_volt)

tic
WLS_SDP_Result=WLS_with_SDP_PF_Model(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt,Ycomb);
toc

fprintf('Buses selected %.0f, max error %.3f', numBuses,max(abs(true_volt)-WLS_SDP_Result(:,1)))
