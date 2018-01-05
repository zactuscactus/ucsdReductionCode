function [WLS_SDP_Result]=WLS_with_SDP_PF_Model_distributed(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt,parent)

% Polish Measurements

[NZ, NZ2]=size(Z);
A{NZ}=[];
for i=1:NZ
    if Z(i,1)==1
        A{i}=Yk{Z(i,2)};
    elseif Z(i,1)==2
        A{i}=Ykbar{Z(i,2)};
    elseif Z(i,1)==3
        A{i}=Ykl{Z(i,2),Z(i,3)};
    elseif Z(i,1)==4
        A{i}=Yklbar{Z(i,2),Z(i,3)};
    elseif Z(i,1)==5
        A{i}=M{Z(i,2)};
        Z(i,4)=Z(i,4).^2;
    end
%    disp([trace(A{i}*W)-Z(i,4)]);
end
z=Z(:,4);
Ri = diag(Z(:,5)); % Measurement Error..
Meas=inv(Ri);	%Inverse of Mearuement uncertainty
%Meas=eye(NZ,NZ);

n_nodes=length(A{1})/2;
Vmag0=abs(true_volt);
del0=angle(true_volt);
del0=del0-del0(1);

Vd0=real(Vmag0.*exp(1i*del0));
Vq0=imag(Vmag0.*exp(1i*del0));

Vmag = ones(n_nodes,1); % Initialize the bus voltages..
del=round(del0/(pi/6))*(pi/6);
Vd=real(Vmag.*exp(1i*del));
Vq=imag(Vmag.*exp(1i*del));
V=[Vd;Vq];
h=zeros(NZ,1);
H=zeros(NZ,2*n_nodes);

E=V;

iter = 1;
tol = 5;
Buses=sort(unique([Z(:,6);Z(:,7)]));
Buses(find(Buses==0))=[];
EE=repmat(V,1,length(Buses));
DEL=repmat(del,1,length(Buses));
VMAG=repmat(Vmag,1,length(Buses));
dEE=zeros(2*n_nodes,length(Buses));

lambda=ones(length(Buses),1);
%lambda([11,27],1)=0.05; % for  34-bus
%lambda([3,60,65])=0.05;  % for 123-bus
figy=ceil(sqrt(length(Buses)));
figx=ceil(length(Buses)/figy);
for busId=1:length(Buses)
    bus=Buses(busId);
    dE=zeros(2*n_nodes,1);
    E=EE(:,busId);
    nodes=sort(unique([Z(find(Z(:,6)==bus),2);Z(find(Z(:,7)==bus),3);]));
    nodes(find(nodes==0))=[];
    Nodes{busId}=nodes;

    Meas_select=sort(unique([find(ismember(Z(:,2),nodes));find(ismember(Z(:,3),nodes))]));   % Indices of measurements related to the selected Bus 
    neighbor_nodes{busId}=sort(unique([Z(Meas_select,2);Z(Meas_select,3)]));
    neighbor_nodes{busId}(find(neighbor_nodes{busId}==0))=[];
    Meas_select=sort(unique([Meas_select;find(ismember(Z(:,1:2),[5*ones(length(neighbor_nodes{busId}),1),neighbor_nodes{busId}],'rows'))]));
    neighbor_buses{busId}=sort(unique([Z(Meas_select,6);Z(Meas_select,7)]));
    neighbor_buses{busId}(find(neighbor_buses{busId}==0))=[];
end
while tol>1e-4
    for busId=1:length(Buses)
        if length(neighbor_buses{busId})>2
            bus=Buses(busId);
            dE=zeros(2*n_nodes,1);
            E=EE(:,busId);
            nodes=sort(unique([Z(find(Z(:,6)==bus),2);Z(find(Z(:,7)==bus),3);]));
            nodes(find(nodes==0))=[];
            Nodes{busId}=nodes;

            Meas_select=sort(unique([find(ismember(Z(:,2),nodes));find(ismember(Z(:,3),nodes))]));   % Indices of measurements related to the selected Bus 
            neighbor_nodes{busId}=sort(unique([Z(Meas_select,2);Z(Meas_select,3)]));
            neighbor_nodes{busId}(find(neighbor_nodes{busId}==0))=[];
            Meas_select=sort(unique([Meas_select;find(ismember(Z(:,1:2),[5*ones(length(neighbor_nodes{busId}),1),neighbor_nodes{busId}],'rows'))]));
            neighbor_buses{busId}=sort(unique([Z(Meas_select,6);Z(Meas_select,7)]));
            neighbor_buses{busId}(find(neighbor_buses{busId}==0))=[];


            h=zeros(length(Meas_select),1);
            H=zeros(length(Meas_select),2*length(neighbor_nodes{busId}));

            Inds_affect=[neighbor_nodes{busId};n_nodes+neighbor_nodes{busId}];
            for k=1:length(Meas_select)
                meas_Ind=Meas_select(k);
                h(k)=E(Inds_affect)'*(A{meas_Ind}(Inds_affect,Inds_affect))*E(Inds_affect);
    %             h(k)=E'*(A{meas_Ind})*E
                H(k,:)=E(Inds_affect)'*(2*A{meas_Ind}(Inds_affect,Inds_affect));  %  H(k,:)=E'*(A{k}+A{k}');
            end
            r = z(Meas_select) - h;
            %% Objective3 Function Calculation
            % Gain Matrix, Gm..
            Ri = diag(Z(Meas_select,5)); % Measurement Error..
            Meas=inv(Ri);	%Inverse of Mearuement uncertainty

            Gm = H'*Meas*H;

            %Objective Function..
            J = sum(Meas*r.^2);  

            % State Vector..
            if any (isnan((Gm)\(H'*Meas*r))) || any(isnan((Gm)\(H'*Meas*r))>1e30)
%                 disp('NAN');
            else
                dE(Inds_affect) = (Gm)\(H'*Meas*r);
            end
            E=E+lambda(busId)*dE;
            Vcmplx=E(1:n_nodes)+1i*E(n_nodes+1:2*n_nodes);
            del=angle(Vcmplx);
            del=del-del(Nodes{parent(bus)}(1))+DEL(Nodes{parent(bus)}(1),parent(bus));
            Vmag=abs(Vcmplx);
            try
                if max(abs(dE))<.5 && abs((del(Nodes{busId}(1))-del(Nodes{busId}(2)))-(del0(Nodes{busId}(1))-del0(Nodes{busId}(2))))>pi/2
                    del=round(del0/(pi/6))*pi/6;
                    lambda(busId)=lambda(busId)/2;
                    disp(['++++++++++ Warning: Negative sequence identified on bus (agent) #' num2str(busId) '.']);
                    disp(['++++++++++ LAMBDA is updated. Its new value: ' num2str(lambda(busId))]);
                elseif max(abs(dE))<.5 && abs((del(Nodes{busId}(1))-del(Nodes{busId}(3)))-(del0(Nodes{busId}(1))-del0(Nodes{busId}(3))))>pi/2
                    del=round(del0/(pi/6))*pi/6;
                    lambda(busId)=lambda(busId)/2;
                    disp(['++++++++++ Warning: Negative sequence identified on bus #' num2str(busId) '.']);
                    disp(['++++++++++ LAMBDA is updated. Its new value: ' num2str(lambda(busId))]);
                end
                if any(Vmag>5)
                    Vmag(:)=VMAG(:,busId);
                end
            end

            Vd=real(Vmag.*exp(1i*del));
            Vq=imag(Vmag.*exp(1i*del));
            E=[Vd;Vq]; 
            dEE(Inds_affect,busId)=dE(Inds_affect);
            EE(Inds_affect,busId)=E(Inds_affect);
            DEL(:,busId)=del;
            VMAG(:,busId)=Vmag;
            Verr(iter,:,busId)=Vmag-Vmag0;
            Delerr(iter,:,busId)=mod(del-del0+pi,2*pi)-pi;

        else
            EE(:,busId)=EE(:,parent(busId));
            DEL(:,busId)=DEL(:,parent(busId));
            VMAG(:,busId)=VMAG(:,parent(busId));
            Verr(iter,:,busId)=Vmag-Vmag0;
            Delerr(iter,:,busId)=mod(del-del0+pi,2*pi)-pi;
%             figure(1);
%             subplot(figy,figx,busId);plot(squeeze(Verr(:,neighbor_nodes{busId},busId))); xlabel('Iterations'); ylabel('Voltage Magnitude Error (pu)'); title(['Bus ' num2str(busId)]);
%             figure(2);
%             subplot(figy,figx,busId);plot(squeeze(Delerr(:,neighbor_nodes{busId},busId))*180/pi); xlabel('Iterations'); ylabel('Voltage Angle Error (degree)'); title(['Bus ' num2str(busId)]);
%             figure(3);
%             subplot(figy,figx,busId);plot([Vmag(neighbor_nodes{busId}),Vmag0(neighbor_nodes{busId})]); xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); legend({'Estimated' 'True'}); title(['Bus ' num2str(busId)]);
%             figure(4);
%             subplot(figy,figx,busId);plot([del(neighbor_nodes{busId}),del0(neighbor_nodes{busId})]*180/pi); xlabel('Bus Number'); ylabel('Voltage Angle (degree)'); legend({'Estimated' 'True'}); title(['Bus ' num2str(busId)]);
        end
    end
%     for busId=1:length(Buses)
%         bus=Buses(busId);
%         V_neighbors=VMAG(Nodes{busId},busId);
%         DEL_neighbors=DEL(Nodes{busId},busId);
%         for j=1:length(neighbor_buses{busId})
%             if neighbor_buses{busId}(j)~=bus && max(abs(dEE(:,neighbor_buses{busId}(j))))<.1 ...
%                     && max(abs(dEE(:,busId)))<.1 &&  iter>1 
%                 V_neighbors=[V_neighbors,VMAG(Nodes{busId},neighbor_buses{busId}(j))];
%                 DEL_neighbors=[DEL_neighbors,DEL(Nodes{busId},neighbor_buses{busId}(j))];
%             end
%         end
%         N_neighbors=size(V_neighbors,2)-1;
%         if N_neighbors>=1
%             V_updated=sum([V_neighbors(:,1)*(1-N_neighbors*1/(N_neighbors+1)), V_neighbors(:,2:end)*(1/(N_neighbors+1))],2);
%             DEL_updated=sum([DEL_neighbors(:,1)*(1-N_neighbors*1/(N_neighbors+1)), DEL_neighbors(:,2:end)*(1/(N_neighbors+1))],2);
%             Vd=real(V_updated.*exp(1i*DEL(Nodes{busId},busId)));
%             Vq=imag(V_updated.*exp(1i*DEL(Nodes{busId},busId)));
% %             Vd=real(V_updated.*exp(1i*DEL_updated));
% %             Vq=imag(V_updated.*exp(1i*DEL_updated));
%             EE([Nodes{busId},n_nodes+Nodes{busId}],busId)=[Vd;Vq];
%             for j=1:length(neighbor_buses{busId})
%                 if max(abs(dEE(:,neighbor_buses{busId}(j))))<.1  && max(abs(dEE(:,busId)))<.1
%                     V_updated=sum([V_neighbors(:,1)*(1-N_neighbors*1/(N_neighbors+1)), V_neighbors(:,2:end)*(1/(N_neighbors+1))],2);
%                     Vd=real(V_updated.*exp(1i*DEL(Nodes{busId},neighbor_buses{busId}(j))));
%                     Vq=imag(V_updated.*exp(1i*DEL(Nodes{busId},neighbor_buses{busId}(j))));
%                     EE([Nodes{busId},n_nodes+Nodes{busId}],neighbor_buses{busId}(j))=[Vd;Vq];
%                 end
%             end
%         end
%     end
            

%     Weight=zeros(2*n_nodes,length(Buses));
%     for busId=1:length(Buses)
%         Weight([Nodes{busId};Nodes{busId}+n_nodes],neighbor_buses{busId})=1/3/length(neighbor_buses{busId});
%         Weight([Nodes{busId};Nodes{busId}+n_nodes],busId)= 1-(length(neighbor_buses{busId})-1)/3/length(neighbor_buses{busId});
%     end
%     for busId=1:length(Buses)
%         dEE_busId=dEE([Nodes{busId};Nodes{busId}+n_nodes],neighbor_buses{busId}).*Weight([Nodes{busId};Nodes{busId}+n_nodes],neighbor_buses{busId});
% %         dEE_busId(find(abs(dEE_busId)>100))=0;
%         dE([Nodes{busId};Nodes{busId}+n_nodes]) = mean(dEE_busId,2);
%     end
%     dE=dEE(:,2)
%     max(max(abs(dEE)))
%    E = E + dE;


    %% Book keeping
    iter = iter + 1;
    [tol,idx] = max(max(abs(dEE)));


    if mod(iter,1)==0
        for busId=1:length(Buses)
            figure(1);
            subplot(figy,figx,busId);plot(squeeze(Verr(:,neighbor_nodes{busId},busId))); %xlabel('Iterations'); ylabel('Voltage Magnitude Error (pu)'); title(['Bus ' num2str(busId)]);
            figure(2);
            subplot(figy,figx,busId);plot(squeeze(Delerr(:,neighbor_nodes{busId},busId))*180/pi); %xlabel('Iterations'); ylabel('Voltage Angle Error (degree)'); title(['Bus ' num2str(busId)]);
            figure(3);
            subplot(figy,figx,busId);plot([Vmag0(neighbor_nodes{busId}),VMAG(neighbor_nodes{busId},busId)]); %xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); legend({'Estimated' 'True'}); title(['Bus ' num2str(busId)]);
            figure(4);
            subplot(figy,figx,busId);plot([del0(neighbor_nodes{busId}),DEL(neighbor_nodes{busId},busId)]*180/pi); %xlabel('Bus Number'); ylabel('Voltage Angle (degree)'); legend({'Estimated' 'True'}); title(['Bus ' num2str(busId)]);
        end
        pause(2);
    end
    disp(['---------- #Iterarions == ' num2str(iter) ' -----------------------------------']);	
    if iter>1000
        break
    end
    
end
% figure;
% subplot(2,2,1);plot(Verr); xlabel('Iterations'); ylabel('Voltage Magnitude Error (pu)');
% subplot(2,2,2);plot(Delerr*180/pi); xlabel('Iterations'); ylabel('Voltage Angle Error (degree)');
% subplot(2,2,3);plot([Vmag,Vmag0]); xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); legend({'Estimated' 'True'});
% subplot(2,2,4);plot([del,del0]*180/pi); xlabel('Bus Number'); ylabel('Voltage Angle (degree)'); legend({'Estimated' 'True'});

CvE = diag(inv(H'*Meas*H)); % Covariance matrix..

Del = mod(180/pi*del+180,360)-180;
WLS_SDP_Result = [Vmag Del]; % Bus Voltages and angles..
disp('-------- State Estimation ------------------');
disp('--------------------------');
disp('| Bus |    V   |  Angle  | ');
disp('| No  |   pu   |  Degree | ');
disp('--------------------------');
for m = 1:n_nodes
    fprintf('%4g', m); fprintf('  %8.4f', Vmag(m)); fprintf('   %8.4f', Del(m)); fprintf('\n');
end
disp('---------------------------------------------');
        