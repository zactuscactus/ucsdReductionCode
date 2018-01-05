function [Z,Yk,Ykbar,D,Ykl,Yklbar,Ycomb,volt,volt1,M,W,Ybus,basekv]=GenMeasurements_withload(circuit,noise_level)
 
%load the circuit and generate the YBUS
	p = dsswrite(circuit_woPV,[],0,[]); o = actxserver('OpendssEngine.dss');
	dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
	dssText.Command = ['Compile "' p '"']; 
    dssCircuit = o.ActiveCircuit;
	volt00(end+1:end+3)=circuit.circuit.basekv*exp(1i*([0;-120;120]+circuit.circuit.angle)*pi/180)*1000/sqrt(3);

[Nbus,Nbus2]=size(Ybus);

current0=zeros(Nbus,1);
current0(1:3)=Yprim1(4:6,4:6)*circuit.circuit.basekv*exp(1i*([0;-120;120]+circuit.circuit.angle)*pi/180)*1000/sqrt(3);

basekv=[115000; 4160; 480]./sqrt(3);
RealV=dssCircuit.AllBusVmag;
volt_base=[];
for ii=1:length(RealV)
	[~,ind]=min(abs(basekv-RealV(ii)));
	volt_base=[volt_base; basekv(ind)]; 
end
volt_base(end+1:end+3)=basekv(1)*ones(3,1);
volt_base=volt_base.*exp(1i*30*round(angle(volt00*180/pi/30)*pi/180));
power_base=1000000;
Zbase=volt_base*volt_base'/power_base;
Ybase=(1./Zbase);
	dssSolution = dssCircuit.Solution;
    dssSolution.Solve;
    VCmplx=dssCircuit.AllBusVolt'; 
    volt0=VCmplx(1:2:end)+1i*VCmplx(2:2:end);

%reorder V
Vorder=dssCircuit.AllNodeNames;

for ii=1:length(Vorder)
	ind=find(ismember(lower(Ycomb),lower(Vorder{ii})));
	volt00(ind,1)=volt0(ii);
end

%%
volt00=volt00./volt_base;
Ybus=Ybus./Ybase;

% volt00=volt_rating;
volt1=[real(volt00),imag(volt00)]; 
volt1(:,2:3)=volt1;
%[Bus#, REAL PART, IMAG PART, pu, angle]
volt1(:,1)=1:length(volt1);
volt1(:,5)=round(angle(volt00*180/pi/30)*180/pi);


	if isfield(circuit,'pvsystem')
		circuit_woPV=rmfield(circuit,'pvsystem');
	else
		circuit_woPV=circuit;
	end
	if isfield(circuit,'load');
		circuit_woPV=rmfield(circuit_woPV,'load');
	end
	if isfield(circuit,'storage');
		circuit_woPV=rmfield(circuit_woPV,'storage');
	end
	%load the circuit and generate the YBUS
	p = dsswrite(circuit_woPV,[],0,[]); o = actxserver('OpendssEngine.dss');
	dssText = o.Text; dssText.Command = 'Clear'; cDir = pwd;
	dssText.Command = ['Compile "' p '"']; 
    dssCircuit = o.ActiveCircuit;
	Ybus=dssCircuit.SystemY;
	
	%Convert the Ybus to a matrix
	ineven=2:2:length(Ybus); inodd=1:2:length(Ybus);
	Ybus=Ybus(inodd)+1i*Ybus(ineven); Ybus=reshape(Ybus,sqrt(length(Ybus)),sqrt(length(Ybus)));
	Ybus=sparse(Ybus);
	%get buslist in order of Ybus and rearrange
	busnames=regexp(dssCircuit.YNodeOrder,'\.','split');
	YbusOrderVect=[busnames{:}]'; YbusOrderVect(find(cellfun('length',YbusOrderVect)==1))=[];
	YbusPhaseVect=[busnames{:}]'; YbusPhaseVect(find(cellfun('length',YbusPhaseVect)>1))=[]; YbusPhaseVect=str2double(YbusPhaseVect);
	Ycomb=strcat(YbusOrderVect,'.', num2str(YbusPhaseVect));


Ycomb(end+1:end+3)={'source.1' 'source.2' 'source.3'};
    dssCircuit.SetActiveElement('Vsource.SOURCE');
    Yprim = dssCircuit.ActiveElement.Yprim;
    Yprim0=Yprim(1:2:end)+1i*Yprim(2:2:end);
    NewYprimLength=sqrt(length(Yprim0));
    Yprim1=reshape(Yprim0,[NewYprimLength,NewYprimLength]);
    Yprim1(1:3,1:3)=0;
    Ybusnew=Ybus;
    Ybusnew(end+1:end+3,end+1:end+3)=0;
    Ybusnew([1:3,end-2:end],[1:3,end-2:end])=Ybusnew([1:3,end-2:end],[1:3,end-2:end])+Yprim1;
    Ybus=Ybusnew;


 for i=1:1
%         sub_index{i}=zeros(0,1);
%         for j=1:length(sub{i})
%             sub_index{i}(end+1:end+length(find(Node_number(:,2)==sub{i}(j))))=find(Node_number(:,2)==sub{i}(j));
%         end
%         Ybus=sparse(length(sub_index{i}),length(sub_index{i}));
%         for j=1:length(sub_index{i})
%             Ybus(j,:)=Ybus(sub_index{i}(j),sub_index{i}');
%             Ybus(j,j)=0;
%             Ybus(j,j)=sum(Ybus(sub_index{i}(j),:))-sum(Ybus(j,:));
%         end

        e=eye(Nbus);
        e2=eye(2*Nbus);
        for k=1:Nbus
            yk{k}=sparse(e(:,k)*e(:,k)'*Ybus);
            Yk{k}=sparse(0.5*[ real(yk{k})+real(yk{k})', imag(yk{k})'-imag(yk{k})   ;
                imag(yk{k})-imag(yk{k})', real(yk{k})+real(yk{k})'  ]);


            Ykbar{k}=sparse(-0.5*[ imag(yk{k})+imag(yk{k})', real(yk{k})-real(yk{k})'   ;
                real(yk{k})'-real(yk{k}), imag(yk{k})+imag(yk{k})'  ]);
            M{k}=sparse(e2(:,k)*e2(k,:)+e2(:,Nbus+k)*e2(Nbus+k,:));
%             for l=1:Nbus
%                 ykl{k,l}=sparse(e(:,k)*Ybus(k,l)*e(:,k)'-e(:,k)*Ybus(k,l)*e(:,l)');
% 
%                 Ykl{k,l}=sparse(0.5*[  real(ykl{k,l}) + real(ykl{k,l})',    imag(ykl{k,l})'- imag(ykl{k,l})    ;
%                     imag(ykl{k,l})- imag(ykl{k,l})',    real(ykl{k,l}) + real(ykl{k,l})'    ]);
% 
%                 %         Ykl2(2*Nbus*(k-1)+1:2*Nbus*k,2*Nbus*(l-1)+1:2*Nbus*l)=ykl{k,l};
% 
%                 Yklbar{k,l}=sparse(-0.5*[  imag(ykl{k,l})+ imag(ykl{k,l})',    real(ykl{k,l}) - real(ykl{k,l})'   ;
%                     real(ykl{k,l})'- real(ykl{k,l}),    imag(ykl{k,l})'+ imag(ykl{k,l}) ]);
% 
%                 %         Ykl2bar(2*Nbus*(k-1)+1:2*Nbus*k,2*Nbus*(l-1)+1:2*Nbus*l)=Yklbar{k,l};
%             end
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
%         Z3=[3*ones(Nbranch,1),Sline(1:2:end,1:2),Sline(1:2:end,3),.02*ones(Nbranch,1);
%             3*ones(Nbranch,1),Sline(2:2:end,1:2),Sline(2:2:end,3),.02*ones(Nbranch,1)];
        Z3=sortrows([3*ones(2*Nbranch,1),Sline(:,1:3),.02*ones(2*Nbranch,1)],2);
%         Z4=[4*ones(Nbranch,1),Sline(1:2:end,1:2),Sline(1:2:end,4),.02*ones(Nbranch,1);
%             4*ones(Nbranch,1),Sline(2:2:end,1:2),Sline(2:2:end,4),.02*ones(Nbranch,1)];
        Z4=sortrows([4*ones(2*Nbranch,1),Sline(:,[1,2,4]),.02*ones(2*Nbranch,1)],2);
        Z5=[5*ones(Nbus,1),Vbus(:,1),zeros(Nbus,1),sqrt(Vbus(:,2)),.01*ones(Nbus,1)];
        Z=[Z1;Z2;Z5;Z3;Z4];
        [NZZ, NZZcol]=size(Z);

        % Adding noise to the measurements
        noise=Z(:,end).*randn(NZZ,1);
        % %
        Znoise=Z;
        Znoise(:,4)=Z(:,4)+noise_level*noise;
        Znoise(2*Nbus+(1),4)=Z(2*Nbus+(1),4);
 end
Z((Z(:,3)==0),3)=1;
Z=num2cell(Z);
tmp=Ycomb([Z{:,3}]);
Z(:,3)=tmp;
tmp=Ycomb([Z{:,2}]);
Z(:,2)=tmp;
% Z(find(strcmp(strtok(Z(:,2),'\.'),'source')),:)=[];
% Z(find(strcmp(strtok(Z(:,3),'\.'),'source')),:)=[];

% Keep=Z(115:end,2:3);
% [keep,KEEP]=strtok(Keep,'\.');
% for ii=1:length(KEEP)
% Yay(ii)=strcmp(KEEP(ii,1),KEEP(ii,2));
% end
% Meas=Z;
% Meas(114+find(~Yay),:)=[];
% Z=Meas;



end