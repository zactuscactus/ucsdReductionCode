function results=SDPDSE_clean(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,W,Winit)
%% SDP-SE for Distribution System
%close all;

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

Nbus=length(Yk{1})/2;

% Forming the F matrix
clear F;

% F0: in documents of F{:,1} in coding indicates the coefficients of
% objective function
for i=1:NZ
    F{1+i,1}=-1;
end

% Definition of constraints: The column number of F{i,j}, i.e. j, indicates
% the (j-1)th constraint. 
% Structure of constraints: sum (F{i,j}.PSD_block(i))==c(j-1)
% where c denotes a column vector including the constant values of constraints

% Constraint on All Measurements
for i=1:NZ
    F{1+i,     1+i}=-Z(i,5).^2;
    F{1+NZ+i,1+i}=[1,0;0,0]; % element S11==alpha*sigma^2
    
    F{1,     1+NZ+i}=2*A{i};
    F{1+NZ+i,1+NZ+i}=[0,1;1,0]; % element S12+S21==2*(Z-AiW)

    F{1+NZ+i,1+2*NZ+i}=[0,0;0,1]; % element S22==1
end

% Constraint on SLACK BUSES, The angle of first bus==0
for i=1:2*Nbus
    F{1, 1+3*NZ+(i-1)*2+1}=zeros(2*Nbus,2*Nbus);
    F{1, 1+3*NZ+(i-1)*2+1}(i,2*Nbus-2)=1;
    F{1, 1+3*NZ+(i-1)*2+1}(2*Nbus-2,i)=1;
    F{1, 1+3*NZ+(i-1)*2+2}=zeros(2*Nbus,2*Nbus);
    F{1, 1+3*NZ+(i-1)*2+2}(i,2*Nbus-2)=-1;
    F{1, 1+3*NZ+(i-1)*2+2}(2*Nbus-2,i)=-1;
end

% Constraints on REASONABLE VOLTAGE VALUES, -2<=W<=2
% for i=Nbus-2%:2*Nbus
%     for j=Nbus-2%:2*Nbus
% %         F{1, 1+3*NZ+4*Nbus+(i-1)*2*Nbus+j}=zeros(2*Nbus,2*Nbus);
% %         F{1, 1+3*NZ+4*Nbus+(i-1)*2*Nbus+j}(i,j)=1;
%         F{1, 1+3*NZ+4*Nbus+1}=zeros(2*Nbus,2*Nbus);
%         F{1, 1+3*NZ+4*Nbus+1}(i,j)=1;
%     end
% end
% for i=Nbus-2%:2*Nbus
%     for j=Nbus-2%:2*Nbus
%         F{1, 1+3*NZ+4*Nbus+2}=zeros(2*Nbus,2*Nbus);
%         F{1, 1+3*NZ+4*Nbus+2}(i,j)=-1;
%     end
% end


% c: vector of constant values of constraints
% c=[zeros(NZ,1);2*Z(:,4);ones(NZ,1);zeros(4*Nbus,1);2*ones(2*4*Nbus^2,1);];
c=[zeros(NZ,1);2*Z(:,4);ones(NZ,1);zeros(4*Nbus,1)];
% c=[zeros(NZ,1);2*Z(:,4);ones(NZ,1);zeros(4*Nbus,1)];

% SDPA-M Properties
mDIM=length(c) ;  % Number of constraints
nBLOCK=1+2*NZ;  % Number of PSD blocks
bLOCKsTRUCT=[2*Nbus,ones(1,NZ),2*ones(1,NZ)];  % Structure of PSD blocks



% Set some initial points
% For initial point: all bus voltages are equal to 1pu<0

clear Y0;
clear X0;
clear x;
clear X;
clear Y;
%clear x0;
x0=zeros(mDIM,1);
Y0{1,1}=Winit;
for i=1:NZ
    Y0{1+i,1}=0;
    Y0{1+NZ+i,1}=[0,0;0,1];
end
option.maxIteration=10000;
option.epsilonStar=1e-15;
option.betaStar=.1;
option.betaBar=.2;
option.gammaStar=.9;
option.isSymmetric=1;
option.print='display';
% Solve the optimization problem
[objVal,x,X,Y,INFO] = sdpam(mDIM,nBLOCK,bLOCKsTRUCT,c,F,x0,[],Y0,option);



% Reconstruct the results for validation

W2=Y{1,1};

[V2, D2]=eig(W2);
[D2max,D2maxind]=max(diag(D2));
U2=sign(V2(1,D2maxind))*sqrt(D2max)*V2(:,D2maxind);
disp([sort(diag(D)),sort(diag(D2))]);

% Pinj=zeros(NP,1);
% Qinj=zeros(NP,1);
% for i=1:NP
%     Pinj(i)=trace(Yk{i}*W2);
%     Qinj(i)=trace(Ykbar{i}*W2);
% end
% 
% Pinj
% Qinj
% 
% disp('Eigen Values and Vectors')
% [V2,D2]=eig(W2);
% disp('Estimated U vector')
% Wnew=U2*U2';
% Eignew=eig(Wnew);
% Pinjnew=zeros(NP,1);
% Qinjnew=zeros(NP,1);
% for i=1:NP
%     Pinjnew(i)=trace(Yk{i}*Wnew);
%     Qinjnew(i)=trace(Ykbar{i}*Wnew);
% end
% % 
% % Pinjnew
% % Qinjnew
% EigenValues=[diag(D),diag(D2)]
% Voltage=[U,U2,(U-U2)]
% Pinject=[Pgen-bus(:,2),Pinj,Pgen-bus(:,2)-Pinj]
% Qinject=[Qgen-bus(:,3),Qinj,Qgen-bus(:,3)-Qinj]
voltage2=[[volt1(:,1);volt1(:,1)],U2];
voltage2_sorted=sortrows(voltage2,1);
voltage=[[volt1(:,1);volt1(:,1)],volt];
voltage_sorted=sortrows(voltage,1);
%close all;

% figure();
% subplot(221);plot([voltage_sorted(:,2),voltage2_sorted(:,2)]);

for i=1:NZ
    Measurements(i,1:2)=[trace(A{i}*W) trace(A{i}*W2)];
end

Umag=[volt1(:,1),abs(1i*volt(Nbus+1:2*Nbus)+volt(1:Nbus))];
%Udeg=[volt1(:,1),angle(1i*volt(Nbus+1:2*Nbus)+volt(1:Nbus))*180/pi-(atan(volt(Nbus+1:2*Nbus)./volt(1:Nbus))>0).*(volt1(:,1)==2)*180+(atan(volt(Nbus+1:2*Nbus)./volt(1:Nbus))<0).*(volt1(:,1)==3)*180];
Udeg=[volt1(:,1),angle(1i*volt(Nbus+1:2*Nbus)+volt(1:Nbus))*180/pi];
Udeg=Udeg-Udeg(1,2);
Umag2=[volt1(:,1),abs(1i*U2(Nbus+1:2*Nbus)+U2(1:Nbus))];
%Udeg2=[volt1(:,1),angle(1i*U2(Nbus+1:2*Nbus)+U2(1:Nbus))*180/pi-(atan(U2(Nbus+1:2*Nbus)./U2(1:Nbus))>0).*(volt1(:,1)==2)*180+(atan(U2(Nbus+1:2*Nbus)./U2(1:Nbus))<0).*(volt1(:,1)==3)*180];
Udeg2=[volt1(:,1),angle(1i*U2(Nbus+1:2*Nbus)+U2(1:Nbus))*180/pi];
Udeg2=Udeg2-Udeg2(1,2);
%Udeg2=Udeg2+volt1(1,5)+(volt1(1,1)==2)*120-(volt1(1,1)==3)*120;

results.voltage2=voltage2;
results.voltage=voltage;
results.Umag=Umag;
results.Udeg=mod(Udeg+180,360)-180;
results.Umag2=Umag2;
results.Udeg2=mod(Udeg2+180,360)-180;
results.Measurements=Measurements;

% Umag=sortrows(Umag,1);
% Udeg=sortrows(Udeg,1);
% Umag2=sortrows(Umag2,1);
% Udeg2=sortrows(Udeg2,1);

figure;
subplot(211);plot([Umag(:,2),Umag2(:,2)]);xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); legend({'Estimated' 'True'});
subplot(212);plot([Udeg(:,2),Udeg2(:,2)]);xlabel('Bus Number'); ylabel('Voltage Angle (degree)'); legend({'Estimated' 'True'});



