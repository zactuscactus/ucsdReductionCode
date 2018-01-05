function [WLS_SDP_Result]=WLS_with_SDP_PF_Model(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,true_volt,Ycomb)

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

while tol>1e-5
    for k=1:NZ
        h(k)=E'*A{k}*E;
        H(k,:)=E'*(2*A{k});  %  H(k,:)=E'*(A{k}+A{k}');
    end
    r = z - h;
    %% Objective3 Function Calculation
    % Gain Matrix, Gm..
    Gm = H'*Meas*H;

    %Objective Function..
    J = sum(Meas*r.^2);  

    % State Vector..
    dE = (Gm)\(H'*Meas*r);
    E = E + dE;
    Vcmplx=E(1:n_nodes)+1i*E(n_nodes+1:2*n_nodes);
    del=angle(Vcmplx);
    del=del-del(1);
    Vmag=abs(Vcmplx);
    Vd=real(Vmag.*exp(1i*del));
    Vq=imag(Vmag.*exp(1i*del));
    E=[Vd;Vq];

    Verr(iter,:)=Vmag-Vmag0;
    Delerr(iter,:)=mod(del-del0+pi,2*pi)-pi;
    %% Book keeping
    iter = iter + 1;
    tol = max(abs(dE));

%     figure(1);
%     subplot(2,2,1);plot(Verr); xlabel('Iterations'); ylabel('Voltage Magnitude Error (pu)');
%     subplot(2,2,2);plot(Delerr*180/pi); xlabel('Iterations'); ylabel('Voltage Angle Error (degree)');

    disp(['---------- #Iterarions == ' num2str(iter) ' -----------------------------------']);	
    if iter>100
        break
    end
    
end
figure;
subplot(2,2,1);plot(Verr); xlabel('Iterations'); ylabel('Voltage Magnitude Error (pu)');
subplot(2,2,2);plot(Delerr*180/pi); xlabel('Iterations'); ylabel('Voltage Angle Error (degree)');
subplot(2,2,3);plot([Vmag,Vmag0]); xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); legend({'Estimated' 'True'});
subplot(2,2,4);plot([del,del0]*180/pi); xlabel('Bus Number'); ylabel('Voltage Angle (degree)'); legend({'Estimated' 'True'});

CvE = diag(inv(H'*Meas*H)); % Covariance matrix..

Del = mod(180/pi*del+180,360)-180;
WLS_SDP_Result = [Vmag Del]; % Bus Voltages and angles..
disp('-------- State Estimation ------------------');
disp('--------------------------');
disp('| Bus |    V   |  Angle  | ');
disp('| No  |   pu   |  Degree | ');
disp('--------------------------');
for m = 1:n_nodes
fprintf('%s', Ycomb{m}); fprintf('  %8.4f', Vmag(m)); fprintf('   %8.4f', Del(m)); fprintf('\n');
end
disp('---------------------------------------------');
        