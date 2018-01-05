function [circuit, circuit_orig, powerFlowFull, powerFlowReduced, pathToDss,voltDiff] = reducingFeeders_Final(pathToFile,criticalBuses,savePath,debug)
%% Feeder reduction code v2.6
%Written by Zack Pecenak 4/9/2017
%updated 5/23/17
%updated 9/20/17
%updated 11/14/17
%% Description:
%Inputs:

% 1) pathToFile - The path to the dss file which is to be reduced. This can
% either be a single file or a master dss which redirects to other files.
% All files must be in the same directory

% 2) criticalBuses - The vector of buses which are desired to be kept by
% the user.

% 3) savePath - (optional), path to which all data will be saved.

% 4) debug - (optional), this will run powerflow and see how well the
% reduction did on your feeder. If the reduction did not behave well it
% will serve as a way to debug why. A plot is generated comparing the two
% methods.




%% Todo
% Reading in
%Make it so the code reads the .dss file, if it has read the same file
%since no changes, load in variables (Ybus, PV, Load, etcc...)
%otherwise, grind through it all.
%Do this by date modified in DIr, we will probably have to save the last
%tiem we used this .dss file somewhere

% Load vminpu
%Right nwo there is no way to account for different load Vminpu in
%aggregation.

% capacitor subtraction from Ybus
%Just like transformer, we need to subtract our capascitors that we are
%keepign in the system from the ybus so that they are not written as
%reactors. we need to remove from Ybus in case any shutn capacitance is
%written into Ybus.

% VR
%Right now we keep all VR, maybe we can remove any that don't have buses
%downstream. We probably can actually, use same code as one used on trf

%% start code
Full=tic;
useSaved=1;

fprintf('\n-------------------------------------------------------------\n')
fprintf('\n                     Initializing circuit        \n')
fprintf('\n-------------------------------------------------------------\n')

%check to see if debug exists
inputs=who;
if ~ismemberi(inputs,'debug')
	debug=1;
end

name=regexp(pathToFile,'\\','split');
feeder=regexprep(name{end},'.dss','');

tic
fprintf('\nParsing Circuit: ')

if nargin<3 || isempty(savePath)
	savePath=[pwd '\' feeder '\'];
	if ~exist(savePath)
		mkdir(savePath);
	end
	
	if ~exist([pwd '\circuits\'])
		mkdir([pwd '\circuits\']);
	end
	
	if ~exist([pwd '\circuits\' feeder '_circuit.mat']) || ~useSaved
		circuit=dssparse(pathToFile);
		%Initialization
		%Check if substation is defined
		if isempty(find(ismemberi(circuit.transformer(:).sub,'y')))
			error('Substation not defined. Please make sub=y on appropriatte transformer .dss file')
		end
		
		if isfield(circuit,'loadshape')
			circuit=rmfield(circuit,'loadshape');
		end
		
		if isfield(circuit,'load')
			for ii=1:length(circuit.load)
				circuit.load(ii).yearly=[];
				circuit.load(ii).daily=[];
				circuit.load(ii).status=[];
				circuit.load(ii).numcust=[];
				circuit.load(ii).vmaxpu=[];
				circuit.load(ii).vminpu=[];
				circuit.load(ii).CVRvars=[];
				circuit.load(ii).CVRwatts=[];
				circuit.load(ii).Class=[];
				circuit.load(ii).xfkVA=[];
			end
		end
		
		if isfield(circuit,'generator')
			for ii=1:length(circuit.generator)
				circuit.generator(ii).yearly=[];
				circuit.generator(ii).daily=[];
				circuit.generator(ii).vminpu=[];
				circuit.generator(ii).vmaxpu=[];
				circuit.generator(ii).Class=[];
			end
		end
		
		for ii=1:length(circuit.transformer)
			circuit.transformer(ii).imag=0;
			circuit.transformer(ii).noloadloss=0;
		end
		
		% 	for ii=1:length(circuit.linecode)
		% 		if ~isempty(circuit.linecode(ii).r0)
		%
		% 			circuit.linecode(ii).c0=0;
		% 			circuit.linecode(ii).c1=0;
		% 		else
		% 			circuit.linecode(ii).cmatrix=zeros(circuit.linecode(ii).Nphases);
		% 		end
		% 	end
		% 	for ii=1:length(circuit.line)
		% 		if isempty(circuit.line(ii).linecode)
		% 			if ~isempty(circuit.line(ii).r0) && ~isnan(circuit.line(ii).r0)
		% 				circuit.line(ii).c0=0;
		% 				circuit.line(ii).c1=0;
		% 			else
		% 				circuit.line(ii).cmatrix=zeros(circuit.line(ii).phases);
		% 			end
		% 		end
		% 	end
		
		% 				circuit=rmfield(circuit,{'capcontrol','capacitor'})
		% 				circuit=rmfield(circuit,{'capcontrol'})
		
		
		save([pwd '\circuits\' feeder '_circuit.mat'],'circuit')
	else
		load([pwd '\circuits\' feeder '_circuit.mat'])
	end
else
	if ~exist([savePath feeder '_circuit.mat']) || ~useSaved
		circuit=dssparse(pathToFile);
		%Initialization
		%Check if substation is defined
		if isempty(find(ismemberi(circuit.transformer(:).sub,'y')))
			error('Substation not defined. Please make sub=y on appropriatte transformer .dss file')
		end
		
		if isfield(circuit,'loadshape')
			circuit=rmfield(circuit,'loadshape');
		end
		
		for ii=1:length(circuit.load)
			circuit.load(ii).yearly=[];
			circuit.load(ii).daily=[];
			circuit.load(ii).vminpu=[];
		end
		
		for ii=1:length(circuit.transformer)
			circuit.transformer(ii).imag=0;
			circuit.transformer(ii).noloadloss=0;
		end
		
		save([savePath feeder '_circuit.mat'],'circuit')
	else
		load([savePath feeder '_circuit.mat'])
	end
end

t_=toc;
fprintf('time elapsed %f\n',t_)



%% run debug sim
if debug
	tic
	fprintf('\nRunning simulation for comparison: ')
	if ~exist([savePath feeder '_sim.mat'])  || ~useSaved
		orig=tic;
		[ powerFlowFull ] = dssSimulation( circuit,[],1,[],[],0);
		FullTime=toc(orig);
		save([savePath feeder '_sim.mat'],'powerFlowFull')
	else
		load([savePath feeder '_sim.mat'])
	end
	
	t_=toc;
	fprintf('time elapsed %f\n',t_)
else
	powerFlowFull=[];
end


%% check which variables we have and set flags
[Flag]=isfield(circuit,{'load','pvsystem','capacitor','transformer','regcontrol','capcontrol','reactor','generator'});
circuit_orig=circuit;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Y-BUS   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('\nGetting Ybus: ')
if ~exist([savePath feeder '_Ybus.mat'])  || ~useSaved
	%remove shunt terms from load/pv
	
	
	if Flag(2)
		circuitBase=rmfield(circuit,'pvsystem');
	else
		circuitBase=circuit;
	end
	if Flag(1)
		circuitBase=rmfield(circuitBase,'load');
	end
	if Flag(8)
		circuitBase=rmfield(circuitBase,'generator');
	end
	if Flag(5)
		circuitBase=rmfield(circuitBase,'regcontrol');
	end
	if Flag(3)
		circuitBase=rmfield(circuitBase,'capacitor');
	end
	if Flag(6)
		circuitBase=rmfield(circuitBase,'capcontrol');
	end
	if exist('o')
		delete(o);
		clearvars o
	end
	[YbusOrderVect, YbusPhaseVect, Ycomb, Ybus, buslist]=getYbus(circuitBase);
	if exist('o')
		delete(o);
		clearvars o
	end
	[ YcombV, vmag,theta,volt_base,voltComplex]=getVolt(circuit);
	
	OrderRegen = getMatchingOrder(Ycomb,YcombV);
	
	YbusOrg=Ybus;
	% 	circuit_orig.Ybus=Ybus;
	% 	Zbus=inv(Ybus);
	Zbus=Ybus\eye(size(Ybus));
	% 	circuit_orig.Zbus=Zbus;
	%pu code was here, at bottom for now
	V2=volt_base.*exp(1i*theta');
	% 	V2=voltComplex/1000*sqrt(3);
	VoltVect=V2;
	V2=diag(V2);
	
	
	save([savePath feeder '_Ybus.mat'],'Ybus','YbusOrg','YbusOrderVect','YbusPhaseVect','Ycomb','buslist','Zbus','V2','VoltVect','volt_base');
else
	load([savePath feeder '_Ybus.mat']);
end

circuit.buslist.id=regexprep(buslist,'-','_');
circuit.buslist.coord=zeros(length(circuit.buslist.id),2);
t_=toc;
fprintf('time elapsed %f\n',t_)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Lines   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
fprintf('\nGetting Lines: ')
if ~exist([savePath feeder '_Lines.mat'])  || ~useSaved
	
	%Get lines and check if circuit is meshed!
	%remove liens that are not enabled.
	enabledBuses=find(~ismemberi(circuit.line(:).enabled,'false'));
	
	Lines(:,1)=strtok(circuit.line(enabledBuses).bus1,'.');
	Lines(:,2)=strtok(circuit.line(enabledBuses).bus2,'.');
	Lines(:,3)=circuit.line(enabledBuses).length;
	Lines(:,4)=circuit.line(enabledBuses).units;
	Lines(:,5)=circuit.line(enabledBuses).bus2;
	
	[Lines(:,3),Lines(:,4)]=Convert_to_km(Lines(:,4),Lines(:,3));
	
	%find lines that are switches
	Inds=[find(ismemberi(circuit.line(enabledBuses).switch,'true')) find(ismemberi(circuit.line(enabledBuses).switch,'yes'))];
	Lines(Inds,3)={.001};
	
	%set up matrix which stores distances to be used to retain lines distances
	valueSet = lower(strtok(Lines(:,1),'\.'));
	valueSet2 = lower(strtok(Lines(:,2),'\.'));
	keySet = lower(buslist);
	mapObj = containers.Map(keySet,1:length(keySet));
	Ind1=cell2mat(values(mapObj,valueSet));
	Ind2=cell2mat(values(mapObj,valueSet2));
	
	linInd=sub2ind(size(Ybus),Ind1,Ind2);
	distMat=zeros(size(Ybus));
	distMat(linInd)=cell2mat(Lines(:,3));
	linInd=sub2ind(size(Ybus),Ind2,Ind1);
	distMat(linInd)=cell2mat(Lines(:,3));
	
	save([savePath feeder '_Lines.mat'],'Lines','distMat')
else
	load([savePath feeder '_Lines.mat'])
end
t_=toc;
fprintf('time elapsed %f\n',t_)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Buslist    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('\nGetting Buslist: ')

for ii=1:length(buslist)
	Ind=find(strcmpi(buslist(ii),YbusOrderVect))';
	Node_number(Ind)=ii;
end

criticalNumbers=find(ismemberi(buslist,criticalBuses));
criticalNumbers=unique(criticalNumbers);
criticalBuses=buslist(criticalNumbers);

if ~iscolumn(criticalNumbers)
	criticalNumbers=criticalNumbers';
end

%Add sourcebus
t_=toc;
fprintf('time elapsed %f\n',t_)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     TOPO    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('\nGetting Topology: ')
if ~exist([savePath feeder '_initTopo.mat'])  || ~useSaved
	topo=zeros(max(Node_number),4);
	generation{1,1}=[];clear generation;  generation{1,1}=1; generation{1,4}=[];generation{1,5}=0; generation{1,6}=0;
	parent=1;
	topo(parent,1)=parent;
	[topo,generation]=topology_detect_large(topo,generation,Ybus,parent,Node_number,distMat);
	topo_view=topo;
	topo_view(find(topo_view(:,1)==0)',:)=[];
	c_new=0;
	generation_orig=generation;
	save([savePath feeder '_initTopo.mat'],'generation','topo','generation_orig');
else
	load([savePath feeder '_initTopo.mat']);
end
t_=toc;
fprintf('time elapsed %f\n',t_)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Capacitors    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This section is to keep the capacitors in the grid by adding the nodes that they are connected to.
if Flag(3)
	tic
	fprintf('\nAdding Capacitor Nodes: ')
	capNum1=[];
	capNum2=[];
	if ~exist([savePath feeder '_Cap.mat'])  || ~useSaved
		bus1=[];
		cap=circuit.capacitor;
		for ii=1:length(cap)
			bus1{ii}=cap(ii).bus1;
			bus2{ii}=cap(ii).bus2;
		end
		if ~iscolumn(bus1)
			bus1=bus1'; bus2=bus2';
		end
		bus1=strtok(bus1,'\.'); %CapNum=find(ismemberi(buslist,bus1));
		% 		criticalNumbers=[criticalNumbers; CapNum];
		bus2=strtok(bus2,'\.');
		capNum1=[find(ismemberi(buslist,bus2)); find(ismemberi(buslist,bus1))];
		% 		criticalNumbers=[criticalNumbers; CapNum];
		
		% 		criticalBuses=buslist(criticalNumbers);
		% 		clear bus1 bus2
		
		if Flag(6)
			capcon=circuit.capcontrol;
			for ii=1:length(capcon)
				buses=regexp(capcon(ii).Element,'\.','split');
				if strcmpi(buses{1},'line')
					LineNo=find(ismemberi({circuit.line{:}.Name},buses{2}));
					capConBuses1{ii}=strtok(circuit.line(LineNo).bus1,'.');
					capConBuses2{ii}=strtok(circuit.line(LineNo).bus2,'.');
				end
			end
			capNum2=reshape([find(ismemberi(buslist,capConBuses1)), find(ismemberi(buslist,capConBuses2))],[],1);
		end
		
		save([savePath feeder '_Cap.mat'],'capNum1','capNum2')
	else
		load([savePath feeder '_Cap.mat'])
	end
	
	criticalNumbers=[criticalNumbers; capNum1; capNum2];
	criticalBuses=buslist(criticalNumbers);
	
	t_=toc;
	fprintf('time elapsed %f\n',t_)
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     LOADS    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%here we preserve by load type!
if Flag(1)
	fprintf('Initialize loads: ')
	tic
	if ~exist([savePath feeder '_Load.mat'])  || ~useSaved
		ld=circuit.load;
		S_LD=zeros(length(YbusOrderVect),8);
		% 	kV_LD=zeros(length(YbusOrderVect),length(YbusOrderVect));
		Ra=(1/sqrt(3))*(cosd(-30)+1i*sind(-30));
		Rb=(1/sqrt(3))*(cosd(30)+1i*sind(30));
		
		for j=1:length(ld)
			[~,data] = char(ld(j));
			
			if ~isempty(data.Kw) && ~isempty(data.Kvar)
				s_ld=(data.Kw+1i*data.Kvar);
			elseif ~isempty(data.Kw) && ~isempty(data.Pf)
				P=data.Kw; pf=data.Pf; Q=sign(pf)*P*sqrt((1-pf^2)/pf^2);
				s_ld=P+1i*Q;
			elseif ~isempty(data.Kvar) && ~isempty(data.Pf)
				Q=data.Kvar; pf=data.Pf; P=Q/sqrt(((1-pf^2))/pf^2);
				s_ld=P+1i*Q;
			elseif ~isempty(data.Kw) && isempty(data.Kvar) && isempty(data.Pf)
				P=ld(j).kW; pf=ld(j).pf; Q=sign(pf)*P*sqrt((1-pf^2)/pf^2);
				s_ld=P+1i*Q;
			elseif isempty(data.Kw) && isempty(data.Kvar) && ~isempty(data.Pf)  && ~isempty(data.kVA)
				s=data.kVA; pf=data.Pf; P=pf*s; Q=sqrt(s^2-P^2);
				s_ld=P+1i*Q;
			else
				error('unknown load inputs')
			end
			
			
			if isempty(regexp(ld(j).bus1,'\.','match')) %3 PhaseInd
				Ind=find(ismemberi(YbusOrderVect,ld(j).bus1));
				S_LD(Ind,ld(j).model)=S_LD(Ind,ld(j).model)+s_ld/3;
				% 			kV_LD(Ind,Ind)=ld(j).kV/sqrt(3);
			elseif length(regexp(ld(j).bus1,'\.','match'))>1 %2 PhaseInd
				name=regexp(ld(j).bus1,'\.','split');
				numPhases=length(name)-1;
				% 			kV_LD(Ind,Ind)=ld(j).kV/sqrt(3);
				if numPhases==2 && strcmpi(ld(j).conn,'delta')
					%Figure out ratio of Y connected loads and assign current
					%correctly
					Ind1=find(ismemberi(Ycomb,[name{1} '.' name{2}]));
					Ind2=find(ismemberi(Ycomb,[name{1} '.' name{3}]));
					
					if strcmpi([name{2} '.' name{3}],'1.2')||strcmpi([name{2} '.' name{3}],'2.3')||strcmpi([name{2} '.' name{3}],'3.1')
						S_LD(Ind1,ld(j).model)=S_LD(Ind1,ld(j).model)+Ra*s_ld;
						S_LD(Ind2,ld(j).model)=S_LD(Ind2,ld(j).model)+Rb*s_ld;
					elseif strcmpi([name{2} '.' name{3}],'2.1')||strcmpi([name{2} '.' name{3}],'3.2')||strcmpi([name{2} '.' name{3}],'1.3')
						S_LD(Ind1,ld(j).model)=S_LD(Ind1,ld(j).model)+Rb*s_ld;
						S_LD(Ind2,ld(j).model)=S_LD(Ind2,ld(j).model)+Ra*s_ld;
					end
				else
					for ii=2:length(name)
						Ind=find(ismemberi(Ycomb,[name{1} '.' name{ii}]));
						S_LD(Ind,ld(j).model)=S_LD(Ind,ld(j).model)+s_ld/numPhases;
					end
				end
			else %1 PhaseInd
				Ind=find(ismemberi(Ycomb,ld(j).bus1));
				S_LD(Ind,ld(j).model)=S_LD(Ind,ld(j).model)+s_ld;
			end
			
		end
		
		save([savePath feeder '_Load.mat'],'S_LD')
	else
		load([savePath feeder '_Load.mat'])
	end
	t_=toc;
	fprintf('%.2f sec\n',t_)
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Gen    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%here we preserve by load type!
if Flag(8)
	fprintf('Initialize Generators: ')
	tic
	if ~exist([savePath feeder '_Gen.mat'])  || ~useSaved
		gen=circuit.generator;
		S_Gen=zeros(length(YbusOrderVect),8);
		% 	kV_LD=zeros(length(YbusOrderVect),length(YbusOrderVect));
		Ra=(1/sqrt(3))*(cosd(-30)+1i*sind(-30));
		Rb=(1/sqrt(3))*(cosd(30)+1i*sind(30));
		
		for j=1:length(gen)
			if gen(j).kVAr==0 && gen(j).kVA==0 && gen(j).kW>0 && gen(j).pf==1
				s_gen=gen(j).Kw;
			elseif gen(j).kVAr>0 && gen(j).kW>0
				s_gen=(gen(j).Kw+1i*gen(j).kVAr);
			elseif gen(j).kVAr>0 && gen(j).pf>0
				Q=gen(j).kVAr; pf=gen(j).pf; P=Q/sqrt(((1-pf^2))/pf^2);
				s_gen=P+1i*Q;
			elseif gen(j).kW>0 && gen(j).pf>0
				P=gen(j).kW; pf=gen(j).pf; Q=P*sqrt((1-pf^2)/pf^2);
				s_gen=P+1i*Q;
			elseif gen(j).kVA>0 && gen(j).pf>0
				S=gen(j).kVA; pf=gen(j).pf; P=pf*S; Q=sqrt(S^2-P^2);
				s_gen=P+1i*Q;
			elseif gen(j).kVA>0 && gen(j).kW>0
				S=gen(j).kVA; P=gen(j).kW; Q=sqrt(S^2-P^2);
				s_gen=P+1i*Q;
			elseif gen(j).kVA>0 && gen(j).kVAr>0
				S=gen(j).kVA; Q=gen(j).kVAr; P=sqrt(S^2-Q^2);
				s_gen=P+1i*Q;
			end
			
			
			if isempty(regexp(gen(j).bus1,'\.','match')) %3 PhaseInd
				Ind=find(ismemberi(YbusOrderVect,gen(j).bus1));
				S_Gen(Ind,gen(j).model)=S_Gen(Ind,gen(j).model)+s_gen/3;
				% 			kV_gen(Ind,Ind)=gen(j).kV/sqrt(3);
			elseif length(regexp(gen(j).bus1,'\.','match'))>1 %2 PhaseInd
				name=regexp(gen(j).bus1,'\.','split');
				numPhases=length(name)-1;
				% 			kV_gen(Ind,Ind)=gen(j).kV/sqrt(3);
				if numPhases==2 && strcmpi(gen(j).conn,'delta')
					%Figure out ratio of Y connected loads and assign current
					%correctly
					Ind1=find(ismemberi(Ycomb,[name{1} '.' name{2}]));
					Ind2=find(ismemberi(Ycomb,[name{1} '.' name{3}]));
					
					if strcmpi([name{2} '.' name{3}],'1.2')||strcmpi([name{2} '.' name{3}],'2.3')||strcmpi([name{2} '.' name{3}],'3.1')
						S_Gen(Ind1,gen(j).model)=S_Gen(Ind1,gen(j).model)+Ra*s_gen;
						S_Gen(Ind2,gen(j).model)=S_Gen(Ind2,gen(j).model)+Rb*s_gen;
					elseif strcmpi([name{2} '.' name{3}],'2.1')||strcmpi([name{2} '.' name{3}],'3.2')||strcmpi([name{2} '.' name{3}],'1.3')
						S_Gen(Ind1,gen(j).model)=S_Gen(Ind1,gen(j).model)+Rb*s_gen;
						S_Gen(Ind2,gen(j).model)=S_Gen(Ind2,gen(j).model)+Ra*s_gen;
					end
				else
					for ii=2:length(name)
						Ind=find(ismemberi(Ycomb,[name{1} '.' name{ii}]));
						S_Gen(Ind,gen(j).model)=S_Gen(Ind,gen(j).model)+s_gen/numPhases;
					end
				end
			else %1 PhaseInd
				Ind=find(ismemberi(Ycomb,gen(j).bus1));
				S_Gen(Ind,gen(j).model)=S_Gen(Ind,gen(j).model)+s_gen;
			end
			
		end
		
		save([savePath feeder '_Gen.mat'],'S_Gen')
	else
		load([savePath feeder '_Gen.mat'])
	end
	t_=toc;
	fprintf('%.2f sec\n',t_)
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     PV    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Flag(2)
	fprintf('Initialize PV systems: ')
	tic
	
	if ~exist([savePath feeder '_PV.mat'])  || ~useSaved
		pv=circuit.pvsystem;
		S_PV=zeros(length(YbusOrderVect),1);
		% 	kV_PV=zeros(length(YbusOrderVect),length(YbusOrderVect));
		
		for j=1:length(pv)
			P=pv(j).pf*pv(j).kVA; Q=sqrt(pv(j).kVA^2-P^2);
			pvPower=(P+1i*Q);
			
			
			if isempty(regexp(pv(j).bus1,'\.','match')) %3 PhaseInd
				Ind=find(ismemberi(YbusOrderVect,pv(j).bus1));
				S_PV(Ind)=S_PV(Ind)+pvPower/3;
				% 			kV_PV(Ind,Ind)=pv(j).kV/sqrt(3);
			elseif length(regexp(pv(j).bus1,'\.','match'))>1 %2 PhaseInd
				% 			kV_PV(Ind,Ind)=pv(j).kV/sqrt(3);
				name=regexp(pv(j).bus1,'\.','split');
				if length(name)==3 && strcmpi(pv(j).conn,'delta')
					%Figure out ratio of Y connected loads and assign current
					%correctly
					Ind1=find(ismemberi(Ycomb,[name{1} '.' name{2}]));
					Ind2=find(ismemberi(Ycomb,[name{1} '.' name{3}]));
					
					if strcmpi([name{2} '.' name{3}],'1.2')||strcmpi([name{2} '.' name{3}],'2.3')||strcmpi([name{2} '.' name{3}],'3.1')
						S_PV(Ind1)=S_PV(Ind1)+Ra*pvPower;
						S_PV(Ind2)=S_PV(Ind2)+Rb*pvPower;
					elseif strcmpi([name{2} '.' name{3}],'2.1')||strcmpi([name{2} '.' name{3}],'3.2')||strcmpi([name{2} '.' name{3}],'1.3')
						S_PV(Ind1)=S_PV(Ind1)+Rb*pvPower;
						S_PV(Ind2)=S_PV(Ind2)+Ra*pvPower;
					end
				else
					for ii=2:length(name)
						Ind=find(ismemberi(Ycomb,[name{1} '.' name{ii}]));
						S_PV(Ind)=S_PV(Ind)+pvPower/pv(j).phases;
					end
				end
			else %1 PhaseInd
				% 			kV_PV(Ind,Ind)=pv(j).kV;
				Ind=find(ismemberi(Ycomb,pv(j).bus1));
				S_PV(Ind)=S_PV(Ind)+pvPower;
			end
		end
		% 	kV_PV(find(YbusPhaseVect==2))=kV_PV(find(YbusPhaseVect==2)).*exp(1i*120*(pi/180));
		% 	kV_PV(find(YbusPhaseVect==3))=kV_PV(find(YbusPhaseVect==3)).*exp(-1i*120*(pi/180));
		save([savePath feeder '_PV.mat'],'S_PV')
	else
		load([savePath feeder '_PV.mat'])
	end
	t_=toc;
	fprintf('%.2f sec\n',t_)
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    X-frmrs    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Handling Transformers: ')
tic
if Flag(4)
	
	if ~exist([savePath feeder '_Xfrmrs.mat'])  || ~useSaved
		Trf_Ind=[]; regBusToKeep=[];
		trf=circuit.transformer;
		if Flag(5)
			rgc=circuit.regcontrol;
			if length(trf)>1
				Trf_Ind=find(ismemberi(trf(:).Name,rgc(:).transformer));
				busKeep=trf(Trf_Ind).buses;
				regBusToKeep=find(ismemberi(buslist,strtok([busKeep{:}],'\.')));
			elseif length(trf)==1
				Trf_Ind=1;
				busKeep=trf(Trf_Ind).buses;
				regBusToKeep=find(ismemberi(buslist,strtok([busKeep{:}],'\.')));
			end
			
		end
		trfKeep=[];
		for ii=1:length(trf)
			[bus,PhaseInd]=strtok(trf(ii).Buses,'.');
			trfBus(ii,1:length(bus))=bus;
			if any(~ismemberi(PhaseInd(2:end),PhaseInd(1))) || any(ismemberi(trf(ii).conn,'delta'))%Check to see if phases stay the same across Xfrmr or if delta conn
				trfKeep(ii)=ii;
			end
		end
		
		trfDown=trfBus(:,2:end); trfDown=trfDown(:); trfDown=trfDown(find(~cellfun(@isempty,trfDown)));
		trfDown_sub=trf(find(ismemberi(trf(:).sub,'y'))).buses;
		trfDown=[trfDown_sub(1); trfDown;];
		[~,trfDownInd]=ismemberi(trfDown,buslist);
		trfBus(cellfun(@isempty,trfBus))={'noBus'};
		
		save([savePath feeder '_Xfrmrs.mat'],'regBusToKeep','trfKeep','trfKeep','trfBus','Trf_Ind','trfDownInd','trfDown')
	else
		load([savePath feeder '_Xfrmrs.mat'])
	end
	trf=circuit.transformer;
	
	criticalNumbers=[criticalNumbers; regBusToKeep];
	criticalNumbers=unique(criticalNumbers);
	%code to make all parents into a single matrix
	c = generation(criticalNumbers,4)'; lens = sum(cellfun('length',c),1); ParentsMat = ones(max(lens),numel(lens)); ParentsMat(bsxfun(@le,[1:max(lens)]',lens)) = vertcat(c{:});
	
	%list of all xfrmrs who are candidates to be removed
	candidateToRemove=find(cellfun(@isempty,regexp(trf(:).Name,'Sub','match')));
	
	candidateToRemove=candidateToRemove(candidateToRemove~=find(~strcmpi(trf(:).sub,'No')));
	
	
	%find xfrms associatted with CB
	XfrmrKeep=unique([trfDownInd(find(ismemberi(trfDownInd,ParentsMat))); trfDownInd(find(ismemberi(trfDownInd,criticalNumbers)))]);
	[row, ~]=ind2sub(size(trfBus),find(ismemberi(trfBus(:,2:end),buslist(XfrmrKeep)))); XfrmrKeepInd=unique(row);
	candidateToRemove=candidateToRemove(find(~ismemberi(candidateToRemove,row)));
	
	%add buses on either side of Xfrmr to list of CB's
	for ii=1:length(row)
		criticalNumbers=[criticalNumbers; find(ismemberi(buslist,trf(row(ii)).buses))];
	end
	
	
	kVAvect=zeros(length(buslist),1);
	for ii=1:length(circuit.transformer)
		Buses=circuit.transformer(ii).Buses;
		IndBus1=find(ismemberi(buslist,strtok(Buses(1))));
		IndBus2=find(ismemberi(buslist,strtok(Buses(end),'.')));
		kVAvect(IndBus1)=cell2mat(circuit.transformer(ii).kVA(1));
		kVAvect(IndBus2)=cell2mat(circuit.transformer(ii).kVA(end));
	end
	% 	[~,l]=unique(trfBus(:,2));
	% 	kVAvect(find(ismemberi(buslist,trfBus(l,2))))=[trfKVA{sort(l)}];
	
	for ii=1:length(generation(:,1))
		busesInFront=generation{ii,4};
		if isempty(busesInFront) ||  kVAvect(ii)~=0
			continue
		end
		MatchInd=find(ismemberi(buslist,trfBus(find(ismemberi(trfBus(:,2),buslist(busesInFront))),2)));
		[~,k]=min([generation{ii,6}]-[generation{MatchInd,6}]);
		closestXfrmr=MatchInd(k);
		kVAvect(ii)=kVAvect(closestXfrmr);
	end
	
	%Remove from list of candidates
	candidateToRemove(find(ismemberi(candidateToRemove,Trf_Ind)))=[];
	
	%remove remaining transformers (not sub, reg, or delta with CB) from
	%circuit
	XfrmrToRmv=candidateToRemove;
	
	%actually delete those transformers (will be rewritten at a later point
	%if needed
	circuit.transformer(XfrmrToRmv)=[];
	
	%adding remaining Xfrmrs to CB
	rembus=[circuit.transformer{:}.buses]; rembus=unique(strtok(rembus(:),'\.'));
	rembus=find(ismemberi(buslist,rembus));
	criticalNumbers=[criticalNumbers; rembus];
	criticalNumbers=unique(criticalNumbers);
	criticalBuses=buslist(criticalNumbers);
	
end


t_=toc;
fprintf('%.2f sec\n',t_)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     TOPOGRAPHY NODES   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this will now also become a critical node. This is done by looking at the
% grandparents of each critical node and seeing if there are common nodes
% between two critical nodes. The closest common node is the one that is
% kept

tic
fprintf('\nGetting topogrophical critical Nodes (connection): ')
nn=length(criticalNumbers);
New_criticalNumbers2=[];


tic
if nn<2000
	for k=1:nn
		%get all buses from the critical bus to the substation
		CB_parents=cell2mat(generation(criticalNumbers(k),4));
		
		%get matrix of all other CB buses to substation
		c = generation(criticalNumbers(k+1:nn),4)';
		lens = sum(cellfun('length',c),1); innerCB_parents = ones(max(lens),numel(lens));
		innerCB_parents(bsxfun(@le,[1:max(lens)]',lens)) = vertcat(c{:});
		innerCB_parents=[criticalNumbers(k+1:nn) innerCB_parents']'; %add CB to list
		
		%get rid of rows that have the CB directly between it and the
		%substation
		[~,bb]=ind2sub(size(innerCB_parents),find(ismemberi(innerCB_parents,criticalNumbers(k))));
		innerCB_parents(:,bb)=1;
		innerCB_parents(find(~ismemberi(innerCB_parents,CB_parents)))=1;
		VectorOfCommonParents=innerCB_parents;
		
		%get one with minimum dfistance between the two
		[~,num]=max(cell2mat(reshape(generation(VectorOfCommonParents,5),size(VectorOfCommonParents))));
		if ~isempty(num)
			New_criticalNumbers2=[New_criticalNumbers2,VectorOfCommonParents(sub2ind(size(VectorOfCommonParents), num, [1:length(num)]))];
		end
	end
else
	parfor k=1:nn
		%get all buses from the critical bus to the substation
		CB_parents=cell2mat(generation(criticalNumbers(k),4));
		
		%get matrix of all other CB buses to substation
		c = generation(criticalNumbers(k+1:nn),4)';
		lens = sum(cellfun('length',c),1); innerCB_parents = ones(max(lens),numel(lens));
		innerCB_parents(bsxfun(@le,[1:max(lens)]',lens)) = vertcat(c{:});
		innerCB_parents=[criticalNumbers(k+1:nn) innerCB_parents']'; %add CB to list
		
		innerCB_parents(find(~ismemberi(innerCB_parents,CB_parents)))=1;
		VectorOfCommonParents=innerCB_parents;
		
		[~,num]=max(cell2mat(reshape(generation(VectorOfCommonParents,5),size(VectorOfCommonParents))));
		if ~isempty(num)
			New_criticalNumbers2=[New_criticalNumbers2,VectorOfCommonParents(sub2ind(size(VectorOfCommonParents), num, [1:length(num)]))];
		end
	end
end
criticalNumbers=vertcat(criticalNumbers, unique(New_criticalNumbers2'));

%Add sourcebus to CN
criticalNumbers=[criticalNumbers; find(ismemberi(buslist,'sourcebus'))];

%Add all substation equipment to list of critical buses
%criticalNumbers=[criticalNumbers; find(not(cellfun('isempty', strfind(lower(buslist), 'sub'))))];

criticalNumbers=unique(criticalNumbers); %get rid of repeat connections
criticalBuses=buslist(criticalNumbers);

t_=toc;
fprintf('time elapsed %f\n',t_)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REDUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actual Reduction Part
fprintf('\n-------------------------------------------------------------\n')
fprintf('\n                     Reducing circuit          \n')
fprintf('\n-------------------------------------------------------------\n')

tic
fprintf('\nReducing: ')

%find buses not in CB and remove from Zbus
YbusOrder_reduced=find(ismemberi(YbusOrderVect,criticalBuses));
Zbus_new=Zbus(YbusOrder_reduced,YbusOrder_reduced);

%get reduced V
Vreduced=V2(YbusOrder_reduced,YbusOrder_reduced);

%get up to date Ybus new
% Ybus_reduced=inv(Zbus_new);
Ybus_reduced=Zbus_new\eye(size(Zbus_new));
yRl=real(Ybus_reduced); yRl(abs(yRl)<1E-9)=0;
yIm=imag(Ybus_reduced); yIm(abs(yIm)<1E-9)=0;
Ybus_reduced=yRl+1i*yIm;



%keep track of order
volt_base_org=volt_base; buslist_org=buslist; YbusOrderVect_org=YbusOrderVect; YbusPhaseVect_org=YbusPhaseVect; Ycomb_org=Ycomb;
volt_base=volt_base(YbusOrder_reduced); buslist=criticalBuses; YbusOrderVect=YbusOrderVect(YbusOrder_reduced); YbusPhaseVect=YbusPhaseVect(YbusOrder_reduced); Ycomb=Ycomb(YbusOrder_reduced);
kVAvectReduced=kVAvect(criticalNumbers);

%get weighting based on impedence
W=Ybus_reduced*Zbus(YbusOrder_reduced,:);


%get weighting based on voltage and impedence product
W2=Vreduced*conj(W)*diag(1./diag(V2));

if Flag(1)
	S_LD_new=W2*S_LD;
	fprintf('\nDiff between total load before and after reduction: %f kW\n',sum(sum(S_LD))-sum(sum(S_LD_new)))
end
if Flag(2)
	S_PV_new=W2*S_PV;
	fprintf('\nDiff between pv before and after reduction: %f kW\n',sum(sum(S_PV))-sum(sum(S_PV_new)))
end
if Flag(8)
	S_Gen_new=W2*S_Gen;
	fprintf('\nDiff between pv before and after reduction: %f kW\n',sum(sum(S_Gen))-sum(sum(S_Gen_new)))
end

tRed=toc;
fprintf('%.2f sec\n',tRed)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWRITE CIRCUIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\n-------------------------------------------------------------\n')
fprintf('\n                     Re-writing circuit        \n')
fprintf('\n-------------------------------------------------------------\n')

tic
fprintf('\nGetting Updated Topology: ')

[generation,topo] = updateGeneration(generation,buslist, buslist_org);

t_=toc;
fprintf('%.2f sec\n',t_)

% topo=zeros(max(Node_number),4);
% generation{1,1}=[];clear generation;  generation{1,1}=1; generation{1,4}=[];generation{1,5}=0; generation{1,6}=0;
% parent=1;
% topo(parent,1)=parent;
% [topo,generation]=topology_detect_large(topo,generation,Ybus_reduced,parent,Node_number,distMat);
% topo_view=topo;
% topo_view(find(topo_view(:,1)==0)',:)=[];
% c_new=0;
% generation_orig=generation;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   CLEAN-UP   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
names=fieldnames(circuit);
keepFields={'load','buslist','circuit','capcontrol','transformer','capacitor','basevoltages','regcontrol','pvsystem','reactor'};
names=names(find(~ismemberi(names,keepFields)));


clear trfBus
for ii=1:length(names)
	circuit=rmfield(circuit,names{ii});
end
trf=circuit.transformer;

for ii=1:length(trf)
	if([trf(ii).kv{1}]==696969)
		continue
	else
		[bus,PhaseInd]=strtok(trf(ii).Buses,'.');
		trfBus(ii,1:length(bus))=bus;
		if trf(ii).phases==1
			trf_kV2(ii,1:length(trf(ii).kv))=cell2mat(trf(ii).kv)*sqrt(3);
		else
			trf_kV2(ii,1:length(trf(ii).kv))=cell2mat(trf(ii).kv);
		end
	end
end

%Get buses downstream of Vreg to allocate Vbase to load and PV
trfDown=trfBus(:,2:end); trfDown=trfDown(:); nonEmptyEntries=find(~cellfun(@isempty,trfDown)); trfDown=trfDown(nonEmptyEntries);
trfDown_sub=trf(find(ismemberi(trf(:).sub,'y'))).buses;
trfDown=[trfDown_sub(1); trfDown;];
trf_kV=trf_kV2(:,2:end); trf_kV=trf_kV(:); trf_kV=trf_kV(nonEmptyEntries);
trf_kV=[trf(find(ismemberi(trf(:).sub,'y'))).kV{1}; trf_kV];
[~,trfDownInd]=ismemberi(trfDown,buslist);
%remove trf without kV specifications, likely just Vreg's
trfBus(cellfun(@isempty,trfBus))={'noBus'};

%Reactor buses
rxBus1=[];
rxBus2=[];
if Flag(7)
	rxBus1=circuit.reactor(:).bus1;
	rxBus2=circuit.reactor(:).bus2;
end

%organize new voltage vector
VreducedVectAbs=abs(diag(Vreduced));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   LINES   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
fprintf('\n Writing Lines: ')

circuitNew=circuit;
if isfield(circuitNew,'regcontrol')
	circuitNew=rmfield(circuitNew,{'regcontrol'});
end
if isfield(circuitNew,'capcontrol')
	circuitNew=rmfield(circuitNew,{'capcontrol'});
end
if isfield(circuitNew,'capacitor')
	circuitNew=rmfield(circuitNew,{'capacitor'});
end
if isfield(circuitNew,'load')
	circuitNew=rmfield(circuitNew,{'load'});
end
if isfield(circuitNew,'generator')
	circuitNew=rmfield(circuitNew,'generator');
end
if isfield(circuitNew,'pvsystem')
	circuitNew=rmfield(circuitNew,'pvsystem');
end
[~, ~, YcombNew, YbusNew1]=getYbus(circuitNew);
OrderRegen = getMatchingOrder(YcombNew,Ycomb);

Ydiff_tmp=zeros(length(Ybus_reduced));
Ydiff_tmp(OrderRegen,OrderRegen)=YbusNew1;
YbusNew=Ydiff_tmp;

Ydiff=Ybus_reduced-YbusNew;

yRl=real(Ydiff); yRl(abs(yRl)<1E-7)=0;
yIm=imag(Ydiff); yIm(abs(yIm)<1E-7)=0;
Ydiff=yRl+1i*yIm;

count=0;
for ii=1:length(generation(:,1))
	Connected=cell2mat(generation(ii,2)); %bus2 nums in buslist
	Bus1=buslist(cell2mat(generation(ii,1))); %bus name <STRING>
	Bus1Ind=find(ismemberi(YbusOrderVect,Bus1)); %node numbers
	
	%Make sure Phases are in correct order in terms of PhaseInd
	[~,I]=sort(YbusPhaseVect(Bus1Ind));
	Bus1Ind=Bus1Ind(I);
	
	%for sunt capacitance
	%write shunt capacitance of the bus.
	
	for jj=1:length(Connected)
		Bus2=buslist(Connected(jj)); %bus name <STRING>
		Bus2Ind=find(ismemberi(YbusOrderVect,Bus2)); %node numbers
		[~,I]=sort(YbusPhaseVect(Bus2Ind)); Bus2Ind=Bus2Ind(I); %sorting by PhaseInd
		
		% 		downSide=find(ismemberi(trfBus(:,1),Bus1));
		% 		if Flag(7); downSide=[downSide; find(ismemberi(rxBus1,Bus1))]; end
		% 		upSide=find(ismemberi(trfBus(:,2:end),Bus2));
		% 		if Flag(7); upSide=[upSide;find(ismemberi(rxBus2,Bus2))]; end
		% 		Match=find(ismemberi(downSide,upSide));
		%Make sure it is not VR
		% 		if ~isempty(Match) | any(volt_base(Bus1Ind(1))>volt_base(Bus2Ind(1)))
		if any(volt_base(Bus1Ind(1))>volt_base(Bus2Ind(1)))
			continue
		else
			Bus1IndMod=Bus1Ind(find(ismemberi(YbusPhaseVect(Bus1Ind),YbusPhaseVect(Bus2Ind))));
			
			Yline=Ydiff(Bus1IndMod,Bus2Ind);
			MissingRows=find(sum(Yline)==0);
			Bus1IndMod(MissingRows)=[];
			Bus2Ind(MissingRows)=[];
			Yline(MissingRows,:)=[];
			Yline(:,MissingRows)=[];
			
			if isempty(Yline)
				continue
			end
			
			if ~isfield(circuit,'line')
				circuit.line(1)=dssline;
			else
				circuit.line(end+1)=dssline;
			end
			
			%now we can write the lines
			count=count+1;
			
			bus1BusInd=find(ismemberi(buslist,char(Bus1)));
			bus2BusInd=find(ismemberi(buslist,char(Bus2)));
			lengthVect(count)=generation{bus2BusInd,6}-generation{bus1BusInd,6};
			
			ImpMat=-inv(Yline)./(lengthVect(end));
			ImpMatReal=real(ImpMat);
			ImpMatReal(abs(ImpMatReal)<1E-8)=0;
			ImpMatImag=imag(ImpMat);
			ImpMatImag(abs(ImpMatImag)<1E-8)=0;
			
			circuit.line(end).Name=[char(Bus1) '_' char(Bus2)];
			circuit.line(end).Units='km';
			circuit.line(end).R1=[]; circuit.line(end).R0=[];
			circuit.line(end).X0=[]; circuit.line(end).X1=[];
			circuit.line(end).C0=[]; circuit.line(end).C1=[];
			circuit.line(end).Length=lengthVect(end);
			circuit.line(end).bus1=[char(Bus1) '.' strjoin(arrayfun(@(x) num2str(x),YbusPhaseVect(Bus1IndMod),'UniformOutput',false),'.')];
			circuit.line(end).bus2=[char(Bus2) '.' strjoin(arrayfun(@(x) num2str(x),YbusPhaseVect(Bus2Ind),'UniformOutput',false),'.')];
			circuit.line(end).Phases=length(Bus2Ind);
			
			if length(ImpMat)==1
				circuit.line(end).Rmatrix=['(' num2str(ImpMatReal(1,1),12) ')'];
				circuit.line(end).Xmatrix=['(' num2str(ImpMatImag(1,1),12) ')'];
				circuit.line(end).cmatrix=0;
			elseif length(ImpMat)==2
				circuit.line(end).Rmatrix=['(' num2str(ImpMatReal(1,1),12) '|' num2str(ImpMatReal(2,1:2),12)  ')'];
				circuit.line(end).Xmatrix=['(' num2str(ImpMatImag(1,1),12) '|' num2str(ImpMatImag(2,1:2),12)  ')'];
				circuit.line(end).cmatrix=zeros(2);
			else
				circuit.line(end).Rmatrix=['(' num2str(ImpMatReal(1,1),12) '|' num2str(ImpMatReal(2,1:2),12) '|' num2str(ImpMatReal(3,1:3),12) ')'];
				circuit.line(end).Xmatrix=['(' num2str(ImpMatImag(1,1),12) '|' num2str(ImpMatImag(2,1:2),12) '|' num2str(ImpMatImag(3,1:3),12) ')'];
				circuit.line(end).cmatrix=zeros(3);
			end
			
		end
	end
end
t_=toc;
fprintf('%.2f sec\n',t_)



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   Xfrmr   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % tic
% % fprintf('\n Writing Transformers: ')
% %
% % circuitNew=circuit;
% % if isfield(circuitNew,'regcontrol')
% % circuitNew=rmfield(circuitNew,{'regcontrol'});
% % end
% % if isfield(circuitNew,'capcontrol')
% % circuitNew=rmfield(circuitNew,{'capcontrol'});
% % end
% % if isfield(circuitNew,'capacitor')
% % circuitNew=rmfield(circuitNew,{'capacitor'});
% % end
% % if isfield(circuitNew,'load')
% % circuitNew=rmfield(circuitNew,{'load'});
% % end
% % if isfield(circuitNew,'generator')
% % circuitNew=rmfield(circuitNew,'generator');
% % end
% % if isfield(circuitNew,'pvsystem')
% % circuitNew=rmfield(circuitNew,'pvsystem');
% % end
% % [~, ~, YcombNew, YbusNew1]=getYbus(circuitNew);
% % OrderRegen = getMatchingOrder(YcombNew,Ycomb);
% %
% % Ydiff_tmp=zeros(length(Ybus_reduced));
% % Ydiff_tmp(OrderRegen,OrderRegen)=YbusNew1;
% % YbusNew=Ydiff_tmp;
% %
% % Ydiff=Ybus_reduced-YbusNew;
% %
% % yRl=real(Ydiff); yRl(abs(yRl)<1E-7)=0;
% % yIm=imag(Ydiff); yIm(abs(yIm)<1E-7)=0;
% % Ydiff=yRl+1i*yIm;
% %
% % count=0;
% % for ii=1:length(generation(:,1))
% % 	Connected=cell2mat(generation(ii,2)); %bus2 nums in buslist
% % 	Bus1=buslist(cell2mat(generation(ii,1))); %bus name <STRING>
% % 	Bus1Ind=find(ismemberi(YbusOrderVect,Bus1)); %node numbers
% %
% % 	%Make sure Phases are in correct order in terms of PhaseInd
% % 	[~,I]=sort(YbusPhaseVect(Bus1Ind));
% % 	Bus1Ind=Bus1Ind(I);
% %
% % 	%for sunt capacitance
% % 	%write shunt capacitance of the bus.
% % 	if ~strcmpi(Bus1,'sourcebus')
% %
% % 	end
% % 	for jj=1:length(Connected)
% % 		Bus2=buslist(Connected(jj)); %bus name <STRING>
% % 		Bus2Ind=find(ismemberi(YbusOrderVect,Bus2)); %node numbers
% % 		[~,I]=sort(YbusPhaseVect(Bus2Ind)); Bus2Ind=Bus2Ind(I); %sorting by PhaseInd
% %
% % 		downSide=find(ismemberi(trfBus(:,1),Bus1));
% % 		if Flag(7); downSide=[downSide; find(ismemberi(rxBus1,Bus1))]; end
% % 		upSide=find(ismemberi(trfBus(:,2:end),Bus2));
% % 		if Flag(7); upSide=[upSide;find(ismemberi(rxBus2,Bus2))]; end
% % 		Match=find(ismemberi(downSide,upSide));
% % 		%Make sure it is not VR
% % 		if isempty(Match) & any(volt_base(Bus1Ind(1))>volt_base(Bus2Ind(1)))
% %
% % 			%define new transformer
% % 			%get appropriatte kVA
% % 			circuit.transformer(end+1)=dsstransformer;
% %
% % 			if strcmpi(circuit.circuit.Name,'IEEE8500')
% % 				if strcmp(Bus2{end}(end),'a'); PhaseInd=1; end
% % 				if strcmp(Bus2{end}(end),'b'); PhaseInd=2; end
% % 				if strcmp(Bus2{end}(end),'c'); PhaseInd=3; end
% % 				Bus1IndMod=Bus1Ind(find(ismemberi(YbusPhaseVect(Bus1Ind),PhaseInd)));
% % 			else
% % 				Bus1IndMod=Bus1Ind(find(ismemberi(YbusPhaseVect(Bus1Ind),YbusPhaseVect(Bus2Ind))));
% % 			end
% %
% % 			if length(Bus1IndMod)==length(Bus2Ind)
% % 				%%
% % 				%need to account for the fact that two transformers can
% % 				%connect one bus, or more generically, accoutn for two and
% % 				%three phase transformers
% % 				%%
% % 				numWindings=2;
% %
% % 				%create B
% % 				B=zeros(numWindings,numWindings-1);
% % 				for i=1:numWindings
% % 					if i==1
% % 						for k=1:numWindings-1
% % 							B(i,k)=-1;
% % 						end
% % 					else
% % 						for k=1:numWindings-1
% % 							if k==i-1
% % 								B(i,k)=1;
% % 							else
% % 								B(i,k)=0;
% % 							end
% % 						end
% % 					end
% % 				end
% %
% % 				Vbase=[volt_base(Bus1IndMod(1)); volt_base(Bus2Ind(1))]/sqrt(3)*1000;
% %
% % 				%create An
% % 				A=zeros(2*numWindings,numWindings);
% % 				for i=1:numWindings
% % 					A(2*i-1,i)=1/Vbase(i);
% % 					A(2*i,i)=-1/Vbase(i);
% % 				end
% %
% % 				angleB1=round((angle(VoltVect(Bus1IndMod(1))))/(pi/6))*(pi/6);
% % 				angleB2=round((angle(VoltVect(Bus2Ind(1))))/(pi/6))*(pi/6);
% % 				if angleB1==angleB2
% %
% % 					%get %Impedance by reverse calculation
% % 					%gen Yprim
% % 					Yp=zeros(2*(length(Bus1IndMod)+1),2*(length(Bus1IndMod)+1));
% % 					Yp(1:length(Bus1IndMod),1:length(Bus1IndMod))=Ydiff(Bus1IndMod,Bus1IndMod);
% % 					Yp(length(Bus1IndMod)+2:2*length(Bus1IndMod)+1,1:length(Bus1IndMod))=Ydiff(Bus2Ind,Bus1IndMod);
% % 					Yp(1:length(Bus1IndMod),length(Bus1IndMod)+2:2*length(Bus1IndMod)+1)=Ydiff(Bus1IndMod,Bus2Ind);
% % 					Yp(length(Bus1IndMod)+2:2*length(Bus1IndMod)+1,length(Bus1IndMod)+2:2*length(Bus1IndMod)+1)=Ydiff(Bus2Ind,Bus2Ind);
% %
% % 					Yp(end,:)=-sum(Yp(length(Bus1IndMod)+2:end-1,:),1);
% % 					Yp(length(Bus1IndMod)+1,:)=-sum(Yp(1:length(Bus1IndMod),:),1);
% % 					Yp(:,end)=-sum(Yp(:,length(Bus1IndMod)+2:end-1),2);
% % 					Yp(:,length(Bus1IndMod)+1)=-sum(Yp(:,1:length(Bus1IndMod)),2);
% %
% % 					Yp(abs(Yp)<1E-6)=0;
% %
% % 					X=A*B;
% % 					zbase=(1/(1000*kVAvectReduced(ii)));
% % 					Zb=inv(inv(X'*X)*X'*Yp*X*inv(X'*X));
% %
% % 					%write transformer
% % 					circuit.transformer(end).name=['Xfrmr_con_' char(Bus1) '_' char(Bus2)];
% % 					circuit.transformer(end).Phases=length(Bus1IndMod);
% % 					circuit.transformer(end).buses={char(Bus1) char(Bus2)};
% % 					circuit.transformer(end).noloadloss=0;
% % 					circuit.transformer(end).imag=0;
% % 					circuit.transformer(end).Conns={'D' 'YG'};
% % 					circuit.transformer(end).windings=2;
% % 					circuit.transformer(end).kvs=[volt_base(Bus1IndMod(1)) volt_base(Bus2Ind(1))];
% %
% % 					circuit.transformer(end).rs=[round(real(Zb(1,1))/zbase*100/3/2*100)/100 round(real(Zb(1,1))/zbase*100/3/2*100)/100];
% % 					circuit.transformer(end).xhl=round(imag(Zb(1,1)/zbase*100/3)*100)/100;
% % 					circuit.transformer(end).kvas=[kVAvectReduced(ii); kVAvectReduced(Connected(jj))]';
% %
% % 				else
% %
% % 					%get %Impedance by reverse calculation
% % 					%gen Yprim
% % 					Yp=zeros(2*(length(Bus1IndMod)+1),2*(length(Bus1IndMod)+1));
% % 					Yp(1:length(Bus1IndMod),1:length(Bus1IndMod))=Ydiff(Bus1IndMod,Bus1IndMod);
% % 					Yp(length(Bus1IndMod)+2:2*length(Bus1IndMod)+1,1:length(Bus1IndMod))=Ydiff(Bus2Ind,Bus1IndMod);
% % 					Yp(1:length(Bus1IndMod),length(Bus1IndMod)+2:2*length(Bus1IndMod)+1)=Ydiff(Bus1IndMod,Bus2Ind);
% % 					Yp(length(Bus1IndMod)+2:2*length(Bus1IndMod)+1,length(Bus1IndMod)+2:2*length(Bus1IndMod)+1)=Ydiff(Bus2Ind,Bus2Ind);
% %
% % 					Yp(end,:)=-sum(Yp(length(Bus1IndMod)+2:end-1,:),1);
% % 					Yp(length(Bus1IndMod)+1,:)=sum(Yp(1:length(Bus1IndMod),:),1);
% % 					Yp(:,end)=-sum(Yp(:,length(Bus1IndMod)+2:end-1),2);
% % 					Yp(:,length(Bus1IndMod)+1)=sum(Yp(:,1:length(Bus1IndMod)),2);
% %
% % 					Yp(abs(Yp)<1E-6)=0;
% %
% %
% % 					%must calculate yt
% % 					%this si really jankity, must fix
% % 					Yt(1,1)=1/2*Yp(1,1); Yt(2,2)=1/2*Yp(2,2);
% % 					Yt(3,3)=Yp(5,5); Yt(4,4)=1/3*Yp(8,8);
% % 					Yt(2,1)=Yp(2,1); Yt(1,2)=Yp(1,2);
% % 					Yt(3,1)=Yp(5,1);Yt(1,3)=Yp(1,5);
% % 					Yt(4,1)=Yp(6,1); Yt(1,4)=Yp(6,1);
% % 					Yt(4,2)=Yp(5,1); Yt(2,4)=Yp(5,1);
% % 					Yt(3,2)=Yp(1,6); Yt(2,3)=Yp(6,1);
% % 					Yt(3,4)=Yp(8,7); Yt(4,3)=Yp(8,7);
% %
% % 					X=A*B;
% % 					zbase=(1/(1000*kVAvectReduced(ii)));
% % 					Zb=inv(inv(X'*X)*X'*Yt*X*inv(X'*X));
% %
% % 					%write transformer
% % 					circuit.transformer(end).name=['Xfrmr_con_' char(Bus1) '_' char(Bus2)];
% % 					circuit.transformer(end).Phases=length(Bus1IndMod);
% % 					circuit.transformer(end).buses={char(Bus1) char(Bus2)};
% % 					circuit.transformer(end).noloadloss=0;
% % 					circuit.transformer(end).imag=0;
% % 					circuit.transformer(end).Conns={'D' 'YG'};
% % 					circuit.transformer(end).windings=2;
% % 					circuit.transformer(end).kvs=[volt_base(Bus1IndMod(1)) volt_base(Bus2Ind(1))];
% %
% % 					circuit.transformer(end).rs=[round(real(Zb(1,1))/zbase*100/3/2*100)/100 round(real(Zb(1,1))/zbase*100/3/2*100)/100];
% % 					circuit.transformer(end).xhl=round(imag(Zb(1,1)/zbase*100/3)*100)/100;
% % 					circuit.transformer(end).kvas=[kVAvectReduced(ii); kVAvectReduced(Connected(jj))]';
% %
% % 				end
% %
% % 			else %basically for 3 winding transformers
% %
% % 				numWindings=length(Bus1IndMod)+length(Bus2Ind);
% %
% % 				%create B
% % 				B=zeros(numWindings,numWindings-1);
% % 				for i=1:numWindings
% % 					if i==1
% % 						for k=1:2
% % 							B(i,k)=-1;
% % 						end
% % 					else
% % 						for k=1:2
% % 							if k==i-1
% % 								B(i,k)=1;
% % 							else
% % 								B(i,k)=0;
% % 							end
% % 						end
% % 					end
% % 				end
% %
% % 				Vbase=[volt_base(Bus1IndMod); volt_base(Bus2Ind)]*1000/sqrt(3);
% %
% % 				%create An
% % 				A=zeros(2*numWindings,numWindings);
% % 				for i=1:numWindings
% % 					A(2*i-1,i)=1/Vbase(i);
% % 					A(2*i,i)=-1/Vbase(i);
% % 				end
% %
% % 				%get %Impedance by reverse calculation
% % 				%gen Yprim
% % 				Yp=zeros(6,6);
% % 				Yp(1:2,1:2)=sum(Ybus_reduced([Bus1IndMod],:),2);
% % 				Yp(3:4,1:2)=-Ybus_reduced(Bus1IndMod,Bus2Ind(1));
% % 				Yp(1:2,3:4)=-Ybus_reduced(Bus1IndMod,Bus2Ind(1));
% % 				Yp(5:6,1:2)=Ybus_reduced(Bus1IndMod,Bus2Ind(2));
% % 				Yp(1:2,5:6)=Ybus_reduced(Bus1IndMod,Bus2Ind(2));
% %
% % 				%need to differentiate between if it is final bus or if
% % 				%there is bus after. If there is, must subtract out that
% % 				%part
% % 				BusAfter=buslist(cell2mat(generation(Connected(jj),2)));
% % 				BusAfterInd=find(ismemberi(YbusOrderVect,BusAfter));
% %
% % 				if ~isempty(BusAfter)
% %
% % 					for ii=1:length(Bus2Ind)
% % 						SamePhaseInd=BusAfterInd(find(ismember(YbusPhaseVect(BusAfterInd),YbusPhaseVect(Bus2Ind(ii)))));
% % 						OppPhaseInd(ii)=BusAfterInd(find(~ismember(YbusPhaseVect(BusAfterInd),YbusPhaseVect(Bus2Ind(ii)))));
% % 						Yp(2*ii+1:2*ii+2,2*ii+1:2*ii+2)=Ybus_reduced([Bus2Ind(ii)],[Bus2Ind(ii)])+Ybus_reduced([Bus2Ind(ii)],SamePhaseInd);
% % 					end
% % 					Yp(3:4,5:6)=-1*(Ybus_reduced([Bus2Ind(2)],[Bus2Ind(1)])+Ybus_reduced([Bus2Ind(1)],OppPhaseInd(1)));
% % 					Yp(5:6,3:4)=-1*(Ybus_reduced([Bus2Ind(1)],[Bus2Ind(2)])+Ybus_reduced([Bus2Ind(2)],OppPhaseInd(2)));
% %
% % 				else
% % 					for ii=1:length(Bus2Ind)
% % 						Yp(2*ii+1:2*ii+2,2*ii+1:2*ii+2)=Ybus_reduced([Bus2Ind(ii)],[Bus2Ind(ii)]);
% % 					end
% % 					Yp(3:4,5:6)=-1*Ybus_reduced([Bus2Ind(2)],[Bus2Ind(1)]);
% % 					Yp(5:6,3:4)=-1*Ybus_reduced([Bus2Ind(1)],[Bus2Ind(2)]);
% %
% % 				end
% % 				Yp(2,:)=-Yp(2,:); Yp(3,:)=-Yp(3,:); Yp(5,:)=-Yp(5,:);
% % 				Yp(:,2)=-Yp(:,2); Yp(:,3)=-Yp(:,3); Yp(:,5)=-Yp(:,5);
% %
% % 				X=A*B;
% % 				zbase=(1/(1000*kVAvectReduced(Connected(jj))));
% % 				Zb=inv(inv(X'*X)*X'*Yp*X*inv(X'*X));
% %
% %
% % 				%write transformer
% % 				circuit.transformer(end).name=['Xfrmr_con_' char(Bus1) '_' char(Bus2)];
% % 				circuit.transformer(end).Phases=length(Bus1IndMod);
% % 				circuit.transformer(end).buses={[char(Bus1) '.' num2str(PhaseInd)],[char(Bus2) '.1.0'],[char(Bus2) '.0.2']};
% % 				circuit.transformer(end).noloadloss=0;
% % 				circuit.transformer(end).imag=0;
% % 				circuit.transformer(end).windings=3;
% % 				circuit.transformer(end).kvs=round(Vbase)'./1000;
% % 				circuit.transformer(end).rs=[round(real(Zb(2,1)/zbase*100)*100)/100 round((real(Zb(1,1)/zbase*100)-real(Zb(2,1)/zbase*100))*100)/100 round((real(Zb(2,2)/zbase*100)-real(Zb(2,1)/zbase*100))*100)/100];
% % 				circuit.transformer(end).xhl=round(imag(Zb(1,1)/zbase*100)*100)/100;
% % 				circuit.transformer(end).xht=round(imag(Zb(2,2)/zbase*100)*100)/100;
% % 				circuit.transformer(end).xlt=round((-2*(imag(Zb(2,1)/zbase*100)*100)/100+(imag(Zb(2,2)/zbase*100)*100)/100+(imag(Zb(1,1)/zbase*100)*100)/100)*100)/100;
% % 				circuit.transformer(end).kvas=[kVAvectReduced(Connected(jj)); kVAvectReduced(Connected(jj)); kVAvectReduced(Connected(jj))]';
% %
% %
% % 			end
% % 		end
% % 	end
% % end
% % t_=toc;
% % fprintf('%.2f sec\n',t_)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     SHUNT CAPACITORS   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('\nRe-writing shunt capacitors: ')

if ~strcmpi(circuit_orig.circuit.name,'ckt5')
	circuitNew=circuit;
	if isfield(circuitNew,'regcontrol')
		circuitNew=rmfield(circuitNew,{'regcontrol'});
	end
	if isfield(circuitNew,'capcontrol')
		circuitNew=rmfield(circuitNew,{'capcontrol'});
	end
	if isfield(circuitNew,'capacitor')
		circuitNew=rmfield(circuitNew,{'capacitor'});
	end
	if isfield(circuitNew,'load')
		circuitNew=rmfield(circuitNew,{'load'});
	end
	if isfield(circuitNew,'generator')
		circuitNew=rmfield(circuitNew,'generator');
	end
	if isfield(circuitNew,'pvsystem')
		circuitNew=rmfield(circuitNew,'pvsystem');
	end
	[~, ~, YcombNew, YbusNew]=getYbus(circuitNew);
	OrderRegen = getMatchingOrder(Ycomb,YcombNew);
	
	Ydiff=Ybus_reduced-YbusNew(OrderRegen,OrderRegen);
	
	yRl=real(Ydiff); yRl(abs(yRl)<1E-7)=0;
	yIm=imag(Ydiff); yIm(abs(yIm)<1E-7)=0;
	Ydiff=yRl+1i*yIm;
	
	for ii=1:length(buslist)
		BusInds=find(ismemberi(YbusOrderVect,buslist(ii)));
		r_jx=Ydiff(BusInds,BusInds);
		inv_r_jx=inv(r_jx);
		
		if ~any(any(isinf(inv_r_jx))) && sum(sum(imag(inv_r_jx))) && ~any(real(diag(r_jx))<0) && ~any(any(real(diag(diag(r_jx))-r_jx)<0))
			if ~isfield(circuit,'capacitor')
				circuit.capacitor(1)=dsscapacitor;
			else
				circuit.capacitor(end+1)=dsscapacitor;
			end
			
			circuit.capacitor(end).name=['addedShuntCap_' char(YbusOrderVect(BusInds(1)))];
			circuit.capacitor(end).phases=length(BusInds);
			circuit.capacitor(end).kvar=0;
			circuit.capacitor(end).bus1=[char(YbusOrderVect(BusInds(1))) '.' strjoin(arrayfun(@(x) num2str(x),YbusPhaseVect(BusInds),'UniformOutput',false),'.')];
			circuit.capacitor(end).kv=volt_base(BusInds(1))/sqrt(3);
			w=2*pi*60;
			circuit.capacitor(end).cmatrix=imag(r_jx)*(1/w)*1E6;
		end
	end
end
t_=toc;
fprintf('%.2f sec\n',t_)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     CAPACITORS   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fprintf('\nRe-writing capacitors: ')
%update capcontrol to match updated line names
if Flag(6)
	for ii=1:length(circuit.capcontrol)
		
		if ~isempty(circuit.capcontrol(ii).element)
			el=circuit.capcontrol(ii).element;
			if strcmpi(el(1:4),'line')
				el=el(6:end);
				lineInd=find(ismemberi(circuit_orig.line(:).name,el));
				bus1=strtok(circuit_orig.line(lineInd).bus1,'\.');
				bus2=strtok(circuit_orig.line(lineInd).bus2,'\.');
			end
		else
			CapInd=find(ismemberi(circuit.capacitor(:).name,{circuit.capcontrol(ii).Capacitor}));
			bus1=strtok(circuit.capacitor(CapInd).bus1,'\.');
			bus2=strtok(circuit.capacitor(CapInd).bus2,'\.');
		end
		
		if ~isempty(bus2)
			LineBus2=find(ismemberi(strtok(circuit.line(:).bus1,'.'),bus1));
			LineBus1=find(ismemberi(strtok(circuit.line(:).bus2,'.'),bus2));
			lineInd=LineBus2(find(ismemberi(LineBus2,LineBus1)));
			
			if isempty(lineInd)
				LineBus2=find(ismemberi(strtok(circuit.line(:).bus1,'.'),bus2));
				LineBus1=find(ismemberi(strtok(circuit.line(:).bus2,'.'),bus1));
				lineInd=LineBus2(find(ismemberi(LineBus2,LineBus1)));
			end
		else
			nextBus=generation{find(ismemberi(buslist,bus1)),2};
			prevBus=generation{find(ismemberi(buslist,bus1)),4};
			
			%if line exists to bus after cap bus, use that line, else use
			%line to previous bus.
			if isempty(nextBus)
				LineBus2=find(ismemberi(strtok(circuit.line(:).bus2,'.'),bus1));
				LineBus1=find(ismemberi(strtok(circuit.line(:).bus1,'.'),buslist(prevBus(1))));
			else
				LineBus1=find(ismemberi(strtok(circuit.line(:).bus1,'.'),bus1));
				LineBus2=find(ismemberi(strtok(circuit.line(:).bus2,'.'),buslist(nextBus(1))));
			end
			lineInd=LineBus2(find(ismemberi(LineBus2,LineBus1)));
		end
		
		circuit.capcontrol(ii).Element=['line.' circuit.line(lineInd).Name];
	end
end

t_=toc;
fprintf('%.2f sec\n',t_)



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     PV    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('S_PV_new','var')
	fprintf('Re-writing PV systems: ')
	tic
	
	NegInds=find(real(S_PV_new)<0);
	if ~exist('S_LD_new','var')
		S_LD_new=zeros(length(S_PV_new),1);
	end
	S_LD_new(NegInds,1)=S_LD_new(NegInds,1)-S_PV_new(NegInds);
	S_PV_new(NegInds)=0;
	
	
	count=0;
	circuit.pvsystem=dsspvsystem;
	WritePVs=find(abs(S_PV_new(:))>0.01);
	for ii=1:length(WritePVs)
		P=real(S_PV_new(WritePVs(ii))); P(abs(P)<1E-2)=0;
		Q=imag(S_PV_new(WritePVs(ii))); Q(abs(Q)<1E-2)=0;
		if P==0 &&Q==0
			continue
		end
		count=count+1;
		
		
		circuit.pvsystem(count)=dsspvsystem;
		circuit.pvsystem(count).Name=['PV_' char(Ycomb(WritePVs(ii)))];
		circuit.pvsystem(count).phases=1;
		circuit.pvsystem(count).irradiance=1;
		circuit.pvsystem(count).kV= round(volt_base(WritePVs(ii))/sqrt(3)*100)/100;
		circuit.pvsystem(count).bus1=Ycomb(WritePVs(ii));
		circuit.pvsystem(count).pmpp=P;
		circuit.pvsystem(count).kvar=Q;
		circuit.pvsystem(count).kVA=sqrt(P^2+Q^2);
		circuit.pvsystem(count).cutout=0;
		circuit.pvsystem(count).cutin=0;
		
	end
	
	t_=toc;
	fprintf('%.2f sec\n',t_)
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     LOADS    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('S_LD_new','var')
	fprintf('\nRe-writing loads: ')
	tic
	
	count=0;
	circuit.load=dssload;
	for loadModel=1:size(S_LD_new,2)
		WriteLoads=find(abs(S_LD_new(:,loadModel)));
		for ii=1:length(WriteLoads)
			P=real(S_LD_new(WriteLoads(ii),loadModel)); P(abs(P)<1E-2)=0;
			Q=imag(S_LD_new(WriteLoads(ii),loadModel)); Q(abs(Q)<1E-2)=0;
			if P==0 && Q==0 || P<0
				continue
			end
			count=count+1;
			
			if strcmpi(YbusOrderVect(WriteLoads(ii)),'X_15009_1')
				kill=1;
			end
			circuit.load(count)=dssload;
			circuit.load(count).Name=['Load ' char(Ycomb(WriteLoads(ii))) '_model_' num2str(loadModel)];
			circuit.load(count).phases=1;
			circuit.load(count).kV= round(volt_base(WriteLoads(ii))/sqrt(3)*100)/100;
			circuit.load(count).bus1=Ycomb(WriteLoads(ii));
			circuit.load(count).Kw=P;
			
			
% 			if strcmpi(circuit_orig.circuit.name,'EPRIK1') %|| strcmpi(circuit_orig.circuit.name,'IEEE8500')
% 				if Q~=0
% 					circuit.load(count).pf=sign(P*Q)*P/sqrt(P^2+Q^2);
% 				else
% 					circuit.load(count).pf=1;
% 				end
% 			else
				circuit.load(count).KVAr=Q;
% 			end
			circuit.load(count).model=loadModel;
			circuit.load(count).kVA=[];
		end
	end
	
	if count==0
		circuit.load=[];
	end
	t_=toc;
	fprintf('%.2f sec\n',t_)
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Gens    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('S_Gen_new','var')
	fprintf('\nRe-writing Gens: ')
	tic
	
	count=0;
	circuit.generator=dssgenerator;
	for genModel=1:size(S_Gen_new,2)
		WriteGens=find(abs(S_Gen_new(:,genModel)));
		for ii=1:length(WriteGens)
			P=real(S_Gen_new(WriteGens(ii),genModel)); P(abs(P)<1E-2)=0;
			Q=imag(S_Gen_new(WriteGens(ii),genModel)); Q(abs(Q)<1E-2)=0;
			if P==0 && Q==0 || P<0
				continue
			end
			count=count+1;
			
			circuit.generator(count)=dssgenerator;
			circuit.generator(count).Name=['Gen ' char(Ycomb(WriteGens(ii))) '_model_' num2str(genModel)];
			circuit.generator(count).phases=1;
			circuit.generator(count).kV= round(volt_base(WriteGens(ii))/sqrt(3)*100)/100;
			circuit.generator(count).bus1=Ycomb(WriteGens(ii));
			circuit.generator(count).Kw=P;
			% 			circuit.generator(count).pf=P/sqrt(P^2+Q^2);
			circuit.generator(count).KVAr=Q;
			circuit.generator(count).model=genModel;
			circuit.generator(count).kVA=[];
		end
	end
	
	if count==0
		circuit.load=[];
	end
	t_=toc;
	fprintf('%.2f sec\n',t_)
end

%% Update circuit info
circuit.circuit.Name=[circuit.circuit.Name '_Reduced'];
tmp=find(ismemberi(circuit.buslist.id,buslist));
circuit.buslist.id=circuit.buslist.id(tmp);
circuit.buslist.coord=circuit.buslist.coord(tmp,:);
pathToDss = WriteDSS(circuit,'OutputDSS',0,savePath);
t_reduct=toc(Full);
circuit.reductTime=tRed;
fprintf('total reduction: %.2f sec\n',t_reduct)

%% debugging code
if debug
	%store Ybus
	circuit.Ybus=Ybus_reduced;
	circuit.YbusOrder=Ycomb;
	
	t_reduct=toc(Full);
	if Flag(2)
		circuitBase=rmfield(circuit,'pvsystem');
	else
		circuitBase=circuit;
	end
	if Flag(1);
		circuitBase=rmfield(circuitBase,'load');
	end
	if Flag(5)
		circuitBase=rmfield(circuitBase,'regcontrol');
	end
	
	% 	p = WriteDSS(circuitBase,'Test',0,savePath);
	
	% circuit =rmfield(circuit,'reactor')
	
	% 	[YbusOrderVect2, YbusPhaseVect2, Ycomb2, Ybus_regenerated, ~,~]=getYbus(circuitBase);
	% 	[OrderRegen] = getMatchingOrder(Ycomb2,Ycomb);
	
	%plotting
	redd=tic;
	[ powerFlowReduced ] = dssSimulation( circuit,[],1,[],[],0);
	redTime=toc(redd);
	
	for ii=1:length(powerFlowReduced.nodeName)
		Keep(ii)=find(ismemberi(powerFlowFull.nodeName,powerFlowReduced.nodeName(ii)));
	end
	voltDiff=abs(powerFlowFull.Voltage(Keep)-powerFlowReduced.Voltage)';
	[B,I]=sort(voltDiff);
	powerFlowReduced.nodeName(I);
	[diffV, ind]=max(abs(powerFlowFull.Voltage(Keep)-powerFlowReduced.Voltage));
	[~,sorted ] =sort(powerFlowReduced.Dist);
	% 	figure;plot(voltDiff(sorted))
	% 	figure;plot(powerFlowFull.Dist,powerFlowFull.Voltage,'*')
	% 	hold on;plot(powerFlowReduced.Dist,powerFlowReduced.Voltage,'*')
	% 	myStr=['Max Error: ' num2str(max(voltDiff)) ' Vpu'];
	% 	hold on;text(.6,.1,myStr,'Units','normalized')
	%
	% 	figure;
	% 	treeplot_zkp(topo(:,2)')
	% 	[x,y] = treelayout(topo(:,2)');
	% 	for ii=1:length(x)
	% 	text(x(ii)+.01,y(ii)+.01,strrep(buslist(ii),'_',' '))
	% 	end
	% 	set(gca,'visible','off')
	% 	set(gca,'XtickLabel',[],'YtickLabel',[]);
	% 	legend('Bus','Line\Transformer')
	
	diffV
	
	for ii=1:length(YbusOrderVect_org)
		if YbusOrderVect_org{ii}(1)=='X' || YbusOrderVect_org{ii}(1)=='S'
			if  YbusOrderVect_org{ii}(end)=='A'
				YbusPhaseCreate(ii)=1;
			elseif YbusOrderVect_org{ii}(end)=='B'
				YbusPhaseCreate(ii)=2;
			elseif YbusOrderVect_org{ii}(end)=='C'
				YbusPhaseCreate(ii)=3;
			end
		else
			YbusPhaseCreate(ii)=YbusPhaseVect_org(ii);
		end
	end
	
	stopping=1;
	
	% 	figure;plot(powerFlowReduced.Dist*.3048,powerFlowReduced.Voltage,'r*',powerFlowFull.Dist(Keep),powerFlowFull.Voltage(Keep),'b*')
	% 	legend('Reduced','Original')
	% 	title('Matching Buses','fontsize',14)
	% 	xlabel('Distance to substation [km]','fontsize',14)
	% 	ylabel('Bus Voltage [V pu]','fontsize',14)
else
	powerFlowReduced=[];
end

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [Output]=Convert_to_kft(units, Input)
%
% if strcmp(units,'kft')
% 	Output=Input;
% elseif strcmp(units,'mi')
% 	Output=Input*5.280;
% elseif strcmp(units,'km')
% 	Output=Input*3.28084;
% elseif strcmp(units,'m')
% 	Output=Input*.00328084;
% elseif strcmp(units,'ft')
% 	Output=Input/1000;
% elseif strcmp(units,'in')
% 	Output=Input/12/1000;
% elseif strcmp(units,'cm')
% 	Output=Input/2.54/12/1000;
% elseif strcmp(units,'none')
% 	Output=Input;
% end
% end


% Function to get the feeder topology
% Created by Vahid R. Disfani

% topo:
% column 1: node #
% column 2: parent node #
% column 3: Number of children
% column 4: Number of downstream buses (grand children and so on)

% generation:
% column 1: Node #
% column 2: List of children
% column 3: List of downstream buses (grandchildren to the end points)
% column 4: List of grandparent nodes until the substation
% column 5: Distance from substation assuming that the distance of each line is 1 (number of grandparent nodes)



%% extra code
% 	%get Shuntless Circuit
% 	circuitShunt=circuitBase;
% 	for ii=1:length(circuitShunt.linecode)
% 		if ~isempty(circuitShunt.linecode(ii).r0)
%
% 			circuitShunt.linecode(ii).c0=0;
% 			circuitShunt.linecode(ii).c1=0;
% 		else
% 			circuitShunt.linecode(ii).cmatrix=zeros(circuitShunt.linecode(ii).Nphases);
% 		end
% 	end
% 	for ii=1:length(circuitShunt.line)
% 		if isempty(circuitShunt.line(ii).linecode)
% 			if ~isempty(circuitShunt.line(ii).r0) && ~isnan(circuitShunt.line(ii).r0)
% 				circuitShunt.line(ii).c0=0;
% 				circuitShunt.line(ii).c1=0;
% 			else
% 				circuitShunt.line(ii).cmatrix=zeros(circuitShunt.line(ii).phases);
% 			end
% 		end
% 	end
%
% 	[~, ~, YcombShuntless, YbusShuntless]=getYbus(circuitShunt);
% 	OrderRegen = getMatchingOrder(Ycomb,YcombShuntless);
% 	YbusShuntless=YbusShuntless(OrderRegen,OrderRegen);
% 	% 	ZbusShuntless=inv(YbusShuntless);
% 	ZbusShuntless=YbusShuntless\eye(size(Ybus));
%
% 	YbusJustShunt=YbusShuntless-Ybus;




% 		r_jx=Ybus_justShunt(Bus1Ind,Bus1Ind);
% 		inv_r_jx=inv(r_jx);
% 		inv_r_jx=inv(r_jx);


% 		if ~isinf(inv_r_jx)
% 			if ~isfield(circuit,'capacitor')
% 				circuit.capacitor(1)=dsscapacitor;
% 			else
% 				circuit.capacitor(end+1)=dsscapacitor;
% 			end
%
% 			circuit.capacitor(end).name=['addedShuntCap_' char(YbusOrderVect(Bus1Ind(1)))];
% 			circuit.capacitor(end).phases=length(Bus1Ind);
% 			circuit.capacitor(end).kvar=0;
% 			circuit.capacitor(end).bus1=[char(YbusOrderVect(Bus1Ind(1)))];
% 			circuit.capacitor(end).kv=round((VreducedVectAbs(Bus1Ind(1))/sqrt(3))*100)/100;
% 			w=2*pi*60;
% 			circuit.capacitor(end).cmatrix=imag(r_jx)*(1/w)*1E6;
%
% % 			if ~isfield(circuit,'line')
% 				circuit.line(1)=dssline;
% 			else
% 				circuit.line(end+1)=dssline;
% 			end
%
% 			circuit.line(end).name=['addedShuntLine_' char(YbusOrderVect(Bus1Ind(1)))];
% 			circuit.line(end).phases=length(Bus1Ind);
% 			circuit.line(end).bus1=[char(YbusOrderVect(Bus1Ind(1))) '.1.2.3'];
% 			circuit.line(end).bus2=[char(YbusOrderVect(Bus1Ind(1))) '.1.2.3'];
% 			circuit.line(end).Rmatrix=real(inv_r_jx);
% 			circuit.line(end).xmatrix=imag(inv_r_jx);
% 			circuit.line(end).cmatrix=0;
% 			circuit.line(end).length=1;
% 		end






% 		%add shunt capacitance to your load vectors
% 		for ii=1:length(buslist)
%
% 			YInds=find(ismemberi(YbusOrderVect,buslist(ii)));
%
% 			Yc=YbusJustShunt(YInds,YInds);
% 			V=VoltVect(YInds);
% 			if length(YInds)==3
% 				Vmat=[V(1) V(1)-V(2) V(1)-V(3);V(2)-V(1) V(2) V(2)-V(3); V(3)-V(1) V(3)-V(2) V(3)]./sqrt(3);
% 			elseif length(YInds)==2
% 				Vmat=[V(1) V(1)-V(2);V(2)-V(1) V(2)]./sqrt(3);
% 			else
% 				Vmat=[V(1)]./sqrt(3);
% 			end
% 			S_c=Vmat.*conj(Yc).*conj(Vmat);
%
% 			S_mat(YInds,YInds)=S_c;
% 			% 			for jj=1:length(YInds)
% 			% 				S_LD(YInds(jj),2)=S_LD(YInds(jj),2)+S_c(jj);
% 			% 			end
% 		end

% if ld(j).kVAr==0 && ld(j).kVA==0 && ld(j).kW>0 && ld(j).pf==1
% 				s_ld=ld(j).Kw;
% 			elseif abs(ld(j).kVAr)>0 && ld(j).kW>0
% 				s_ld=(ld(j).Kw+1i*ld(j).kVAr);
% 			elseif ld(j).kVAr>0 && abs(ld(j).pf)>0
% 				Q=ld(j).kVAr; pf=ld(j).pf; P=Q/sqrt(((1-pf^2))/pf^2);
% 				s_ld=P+1i*Q;
% 			elseif ld(j).kW>0 && abs(ld(j).pf)>0
% 				P=ld(j).kW; pf=ld(j).pf; Q=sign(pf)*P*sqrt((1-pf^2)/pf^2);
% 				s_ld=P+1i*Q;
% 			elseif ld(j).kVA>0 && abs(ld(j).pf)>0
% 				S=ld(j).kVA; pf=ld(j).pf; P=pf*S; Q=sqrt(S^2-P^2);
% 				s_ld=P+1i*Q;
% 			elseif ld(j).kVA>0 && ld(j).kW>0
% 				S=ld(j).kVA; P=ld(j).kW; Q=sqrt(S^2-P^2);
% 				s_ld=P+1i*Q;
% 			elseif ld(j).kVA>0 && ld(j).kVAr>0
% 				S=ld(j).kVA; Q=ld(j).kVAr; P=sqrt(S^2-Q^2);
% 				s_ld=P+1i*Q;
% 			end

