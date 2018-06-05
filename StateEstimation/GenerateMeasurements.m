function [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,Ybus,volt_base,Ybase,voltComplex]=GenerateMeasurements(circuit,noise_level)
%% Generate measurements used in SE problem
%Z is a matrix of measurements
%row 1: type 1 - Pinj
%       type 2 - Qinj
%		type 3 - Pline
%		type 4 - Qline
%		type 5 - V
%row 2: bus from
%row 3: bus to
%row 4: value pu
%ro

%% get Ybus
[~, ~, Ycomb, Ybus, ~]=getYbus(circuit,1);

%% get Voltage
[ ~, ~,~,voltComplex,volt_base_complex,volt_base,~]=getVoltReal(circuit);

voltComplex(end+1:end+3)=circuit.circuit.basekv*exp(1i*([0;-120;120]+circuit.circuit.angle)*pi/180)*1000/sqrt(3);
Theta=angle(voltComplex);
volt_base_complex(end+1:end+3)=circuit.circuit.basekv*exp(1i*([0;-120;120]+circuit.circuit.angle)*pi/180)*1000/sqrt(3);
volt_base(end+1:end+3)=circuit.circuit.basekv*1000/sqrt(3);
[Nbus,Nbus2]=size(Ybus);

power_base=1000000;
Zbase=volt_base*volt_base'/power_base;
Ybase=(1./Zbase);

voltComplex=transpose(voltComplex./volt_base);
Ybus=Ybus./Ybase;

%% set up measurement
%[Bus#, REAL PART, IMAG PART, pu, angle]
volt1=[real(voltComplex),imag(voltComplex)];
volt1(:,2:3)=volt1;
volt1(:,1)=1:length(volt1);
volt1(:,5)=round(angle(voltComplex*180/pi/30)*180/pi);

% get circuit
p = WriteDSS(circuit,'test',0,pwd); o = actxserver('OpendssEngine.dss');
o.reset;
dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
dssText.Command = ['Compile "' p '"']; dssCircuit = o.ActiveCircuit;
dssText.Command = 'Set controlmode = off';
dssText.Command = ['Set mode = snapshot'];
dssText.Command = ['Set stepsize = 30s'];
dssText.Command = 'Set number = 1';
dssSolution = dssCircuit.Solution;
dssSolution.MaxControlIterations=300;
dssSolution.MaxIterations=500;
dssSolution.InitSnap; % Initialize Snapshot solution
dssSolution.Solve;

e=eye(Nbus);
e2=eye(2*Nbus);
for k=1:Nbus
	yk{k}=sparse(e(:,k)*e(:,k)'*Ybus);
	Yk{k}=sparse(0.5*[ real(yk{k})+real(yk{k})', imag(yk{k})'-imag(yk{k})   ;
		  imag(yk{k})-imag(yk{k})', real(yk{k})+real(yk{k})'  ]);
		
	Ykbar{k}=sparse(-0.5*[ imag(yk{k})+imag(yk{k})', real(yk{k})-real(yk{k})'   ;
		     real(yk{k})'-real(yk{k}), imag(yk{k})+imag(yk{k})'  ]);
	
	M{k}=sparse(e2(:,k)*e2(k,:)+e2(:,Nbus+k)*e2(Nbus+k,:));
end
Ykl{Nbus,Nbus}=[];

AllElements=dssCircuit.AllElementNames;
for elem=1:length(AllElements)
	if any(ismember(strsplit(AllElements{elem},'.'),'Line')) || any(ismember(strsplit(AllElements{elem},'.'),'Vsource')) || any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
		dssCircuit.SetActiveElement(AllElements{elem});
		Yprim=dssCircuit.ActiveElement.Yprim;
		Yprim0=Yprim(1:2:end)+1i*Yprim(2:2:end);
		NewYprimLength=sqrt(length(Yprim0));
		Yprim=reshape(Yprim0,[NewYprimLength,NewYprimLength]);
		
		busname1=strsplit(dssCircuit.ActiveElement.BusNames{1,:},'.');
		if length(busname1)==1
			busname1(2:4)={'1','2','3'};
		end
		if strcmpi(busname1(2),{'0'}) && strcmpi(busname1(1),{'sourcebus'})
			busname1(1)={'source'};
			busname1(2:4)={'1','2','3'};
		end
		nodeorder1=zeros(length(busname1)-1,1);
		for j=2:length(busname1)
			nodeorder1(j-1)=find(ismember(lower(Ycomb),lower([busname1{1} '.' busname1{j}])));
		end
		
		busname2=strsplit(dssCircuit.ActiveElement.BusNames{2,:},'.');
		if length(busname2)==1
			busname2(2:4)={'1','2','3'};
		end
		if strcmpi(busname2(2),{'0'}) && strcmpi(busname2(1),{'sourcebus'})
			busname2(1)={'source'};
			busname2(2:4)={'1','2','3'};
		end
		nodeorder2=zeros(length(busname2)-1,1);
		for j=2:length(busname2)
			nodeorder2(j-1)=find(ismember(lower(Ycomb),lower([busname2{1} '.' busname2{j}])));
		end
		
		Ybus_elem=sparse(Nbus,Nbus);
		if any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
			Yprim=Yprim([1:length(nodeorder1),length(nodeorder1)+2:2*length(nodeorder1)+1],[1:length(nodeorder1),length(nodeorder1)+2:2*length(nodeorder1)+1]);
		end
		Ybus_elem([nodeorder1,nodeorder2],[nodeorder1,nodeorder2])=Yprim;
		Ybus_elem=Ybus_elem./Ybase;
		for nodeid=1:length(nodeorder1)
			k=nodeorder1(nodeid);
			l=nodeorder2(nodeid);
			ykl{k,l}=sparse(e(:,k)*e(:,k)'*Ybus_elem);
			Ykl{k,l}=sparse(0.5*[ real(ykl{k,l})+real(ykl{k,l})', imag(ykl{k,l})'-imag(ykl{k,l})   ;
				imag(ykl{k,l})-imag(ykl{k,l})', real(ykl{k,l})+real(ykl{k,l})'  ]);
			Yklbar{k,l}=sparse(-0.5*[ imag(ykl{k,l})+imag(ykl{k,l})', real(ykl{k,l})-real(ykl{k,l})'   ;
				real(ykl{k,l})'-real(ykl{k,l}), imag(ykl{k,l})+imag(ykl{k,l})'  ]);
			
			l=nodeorder1(nodeid);
			k=nodeorder2(nodeid);
			ykl{k,l}=sparse(e(:,k)*e(:,k)'*Ybus_elem);
			Ykl{k,l}=sparse(0.5*[ real(ykl{k,l})+real(ykl{k,l})', imag(ykl{k,l})'-imag(ykl{k,l})   ;
				imag(ykl{k,l})-imag(ykl{k,l})', real(ykl{k,l})+real(ykl{k,l})'  ]);
			Yklbar{k,l}=sparse(-0.5*[ imag(ykl{k,l})+imag(ykl{k,l})', real(ykl{k,l})-real(ykl{k,l})'   ;
				real(ykl{k,l})'-real(ykl{k,l}), imag(ykl{k,l})+imag(ykl{k,l})'  ]);
			
		end
	end
	
end
volt=volt1(:,2:3);
volt=volt(:);
W=volt*volt';
[V,D]=eig(W);
%% Measurement Values calculation & Create Measurement Matrices
Pinj=zeros(Nbus,2);
Qinj=zeros(Nbus,2);
Vbus=zeros(Nbus,2);
Pline=sparse(Nbus,Nbus);
Qline=sparse(Nbus,Nbus);
Sline=zeros(0,4);
for ii=1:Nbus
	Pinj(ii,:)=[ii,trace(Yk{ii}*W)];
	Qinj(ii,:)=[ii ,trace(Ykbar{ii}*W)];
	Vbus(ii,:)=[ii, trace(M{ii}*W)];
	for jj=ii+1:Nbus
		if ~isempty(Ykl{ii,jj})
			Pline(ii,jj)=trace(Ykl{ii,jj}*W);
			Qline(ii,jj)=trace(Yklbar{ii,jj}*W);
			Pline(jj,ii)=trace(Ykl{jj,ii}*W);
			Qline(jj,ii)=trace(Yklbar{jj,ii}*W);
			if ~isempty(Ykl{ii,jj}~=0)
				Sline(end+1,:)=[ii,jj,trace(Ykl{ii,jj}*W),trace(Yklbar{ii,jj}*W)];
				Sline(end+1,:)=[jj,ii,trace(Ykl{jj,ii}*W),trace(Yklbar{jj,ii}*W)];
			end
		end
	end
end
[Nbranchx2, col]=size(Sline);
Nbranch=Nbranchx2/2;
Z1=[ones(Nbus,1),(1:Nbus)',zeros(Nbus,1),Pinj(:,2),0.015*ones(Nbus,1)];
Z2=[2*ones(Nbus,1),(1:Nbus)',zeros(Nbus,1),Qinj(:,2),.015*ones(Nbus,1)];
Z3=sortrows([3*ones(2*Nbranch,1),Sline(:,1:3),.02*ones(2*Nbranch,1)],2);
Z4=sortrows([4*ones(2*Nbranch,1),Sline(:,[1,2,4]),.02*ones(2*Nbranch,1)],2);
Z5=[5*ones(Nbus,1),Vbus(:,1),zeros(Nbus,1),sqrt(Vbus(:,2)),.01*ones(Nbus,1)];
Z5(end-2:end,5)=Z5(end-2:end,5)/100;

Z=[Z1;Z2;Z5;Z3;Z4];
[NZZ, NZZcol]=size(Z);

% Adding noise to the measurements
noise=Z(:,5).*abs(Z(:,4)).*randn(NZZ,1);
%         noise=Z(:,5).*randn(NZZ,1);
% %
Znoise=Z;
Znoise(:,4)=Z(:,4)+noise_level*noise;
Znoise(2*Nbus+(1),4)=Z(2*Nbus+(1),4);

Z=Znoise;
Z((Z(:,3)==0),3)=1;
Z=num2cell(Z);
tmp=Ycomb([Z{:,3}]);
Z(:,3)=tmp;
tmp=Ycomb([Z{:,2}]);
Z(:,2)=tmp;

%remove Xfrmr Measurement
for kk=1:length(circuit.transformer)
	trfBus=circuit.transformer(kk).buses;
	lineInds=[find([Z{:,1}]==3) find([Z{:,1}]==4)];

	Bus1MeasFrom=find(strcmpi(strtok(Z(:,2),'.'),strtok(trfBus(1),'.')));
	Bus1MeasTo=find(strcmpi(strtok(Z(:,3),'.'),strtok(trfBus(1),'.')));
	Bus2MeasFrom=find(strcmpi(strtok(Z(:,2),'.'),strtok(trfBus(2),'.')));
	Bus2MeasTo=find(strcmpi(strtok(Z(:,3),'.'),strtok(trfBus(2),'.')));
	
	Ind=[Bus1MeasFrom(find(ismemberi(Bus1MeasFrom,Bus2MeasTo))); Bus2MeasFrom(find(ismemberi(Bus2MeasFrom,Bus1MeasTo)))];
	Z(lineInds(find(ismemberi(lineInds,Ind))),:)=[];
	
end

end