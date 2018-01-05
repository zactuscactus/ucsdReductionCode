function results=SDPDSE(Yk,Ykbar,Ykl,Yklbar,M,Z,volt1,volt,D,W)
%% SDP-SE for Distribution System
%close all;

% Polish Measurements
[NZ, NZ2]=size(Z);
ZP=zeros(0,3);
ZQ=zeros(0,3);
ZPL=zeros(0,4);
ZQL=zeros(0,4);
ZV=zeros(0,3);
for i=1:NZ
    if Z(i,1)==1
        ZP(end+1,:)=[Z(i,2),Z(i,4:5)];
    elseif Z(i,1)==2
        ZQ(end+1,:)=[Z(i,2),Z(i,4:5)];
    elseif Z(i,1)==3
        ZPL(end+1,:)=[Z(i,2:3),Z(i,4:5)];
    elseif Z(i,1)==4
        ZQL(end+1,:)=[Z(i,2:3),Z(i,4:5)];
    elseif Z(i,1)==5
        ZV(end+1,:)=[Z(i,2),Z(i,4).^2,Z(i,5)];
    end
end

Nbus=length(Yk{1})/2;

[NP,colP]=size(ZP);
[NQ,colQ]=size(ZQ);
[NPL,colPL]=size(ZPL);
[NQL,colQL]=size(ZQL);
[NV,colV]=size(ZV);
NZ=NP+NQ+NPL+NQL+NV;

mDIM=3*NZ+4*Nbus ;  % Number of constraints
nBLOCK=1+2*NZ;  % Number of PSD blocks
bLOCKsTRUCT=[2*Nbus,ones(1,NZ),2*ones(1,NZ)];  % Structure of PSD blocks

% Forming the F matrix
clear F;

% F0 in documents of F{:,1} in coding indicates the coefficients of
% objective function
for i=1:NZ
    F{1+i,1}=-1;
end

% Definition of constraints: The column number of F{i,j}, i.e. j, indicates
% the (j-1)th constraint. 
% Structure of constraints: sum (F{i,j}.PSD_block(i))==c(j-1)
% where c denotes a column vector including the constant values of constraints

% Constraint on Pinj Measurements
for i=1:NP
    F{1+i,   1+i}=-ZP(i,3)^2;
    F{1+NZ+i,1+i}=[1,0;0,0]; % element S11==alpha*sigma^2
    F{1,     1+NZ+i}=2*Yk{ZP(i,1)};
    F{1+NZ+i,1+NZ+i}=[0,1;1,0]; % element S12+S21==2*(Z-P)
    F{1+NZ+i,1+2*NZ+i}=[0,0;0,1]; % element S22==1
%     c((0:2)*NZ+i)=[0,ZP(i,2),1]';
end


% Constraint on Qinj Measurements
for i=1:NQ
    F{1+NP+i,   1+NP+i}=-ZQ(i,3)^2;
    F{1+NP+NZ+i,1+NP+i}=[1,0;0,0]; % element S11==alpha*sigma^2
    F{1,     1+NP+NZ+i}=2*Ykbar{ZQ(i,1)};
    F{1+NP+NZ+i,1+NP+NZ+i}=[0,1;1,0]; % element S12+S21==2*(Z-P)
    F{1+NP+NZ+i,1+NP+2*NZ+i}=[0,0;0,1]; % element S22==1
%     c((0:2)*NZ+NP+i)=[0,ZQ(i,2),1]';
end

% Constraint on V Measurements
for i=1:NV
    F{1+NP+NQ+i,   1+NP+NQ+i}=-ZV(i,3)^2;
    F{1+NP+NQ+NZ+i,1+NP+NQ+i}=[1,0;0,0]; % element S11==alpha*sigma^2
    F{1,           1+NP+NQ+NZ+i}=2*M{ZV(i,1)};
    F{1+NP+NQ+NZ+i,1+NP+NQ+NZ+i}=[0,1;1,0]; % element S12+S21==2*(Z-P)
    F{1+NP+NQ+NZ+i,1+NP+NQ+2*NZ+i}=[0,0;0,1]; % element S22==1
%     c((0:2)*NZ+NP+NQ+i)=[0,ZV(i,2),1]';
end

% Constraint on Pline Measurements
for i=1:NPL
    F{1+NP+NQ+NV+i,   1+NP+NQ+NV+i}=-ZPL(i,4)^2;
    F{1+NP+NQ+NV+NZ+i,1+NP+NQ+NV+i}=[1,0;0,0]; % element S11==alpha*sigma^2
    F{1,              1+NP+NQ+NV+NZ+i}=2*Ykl{ZPL(i,1),ZPL(i,2)};
    F{1+NP+NQ+NV+NZ+i,1+NP+NQ+NV+NZ+i}=[0,1;1,0]; % element S12+S21==2*(Z-P)
    F{1+NP+NQ+NV+NZ+i,1+NP+NQ+NV+2*NZ+i}=[0,0;0,1]; % element S22==1
%     c((0:2)*NZ+NP+NQ+NV+i)=[0,ZPL(i,3),1]';
end

% Constraint on Qline Measurements

for i=1:NQL
    F{1+NP+NQ+NV+NPL+i,   1+NP+NQ+NV+NPL+i}=-ZQL(i,4)^2;
    F{1+NP+NQ+NV+NPL+NZ+i,1+NP+NQ+NV+NPL+i}=[1,0;0,0]; % element S11==alpha*sigma^2
    F{1,                  1+NP+NQ+NV+NPL+NZ+i}=2*Yklbar{ZQL(i,1),ZQL(i,2)};
    F{1+NP+NQ+NV+NPL+NZ+i,1+NP+NQ+NV+NPL+NZ+i}=[0,1;1,0]; % element S12+S21==2*(Z-P)
    F{1+NP+NQ+NV+NPL+NZ+i,1+NP+NQ+NV+NPL+2*NZ+i}=[0,0;0,1]; % element S22==1
%     c((0:2)*NZ+NP+NQ+NV+NPL+i)=[0,ZQL(i,3),1]';
end

% Constraint on SLACK BUSES, The angle of first bus==0
for i=1:2*Nbus
    F{1, 1+3*NZ+(i-1)*2+1}=zeros(2*Nbus,2*Nbus);
    F{1, 1+3*NZ+(i-1)*2+1}(i,Nbus+1)=1;
    F{1, 1+3*NZ+(i-1)*2+1}(Nbus+1,i)=1;
    F{1, 1+3*NZ+(i-1)*2+2}=zeros(2*Nbus,2*Nbus);
    F{1, 1+3*NZ+(i-1)*2+2}(i,Nbus+1)=-1;
    F{1, 1+3*NZ+(i-1)*2+2}(Nbus+1,i)=-1;
end

% F{1, 1+3*NZ+3}=zeros(2*Nbus,2*Nbus);
% F{1, 1+3*NZ+3}(Nbus+2,Nbus+2)=1;
% F{1, 1+3*NZ+4}=zeros(2*Nbus,2*Nbus);
% F{1, 1+3*NZ+4}(Nbus+2,Nbus+2)=-1;
% F{1, 1+3*NZ+5}=zeros(2*Nbus,2*Nbus);
% F{1, 1+3*NZ+5}(Nbus+3,Nbus+3)=1;
% F{1, 1+3*NZ+6}=zeros(2*Nbus,2*Nbus);
% F{1, 1+3*NZ+6}(Nbus+3,Nbus+3)=-1;


% c: vector of constant values of constraints
c=[zeros(NZ,1);2*[ZP(:,2);ZQ(:,2);ZV(:,2);ZPL(:,3);ZQL(:,3)];ones(NZ,1);zeros(4*Nbus,1)];

% Set some initial points
% For initial point: all bus voltages are equal to 1pu<0

clear Y0;
clear X0;
clear x;
clear X;
clear Y;
%clear x0;
x0=zeros(mDIM,1);
%X0{1,1}=zeros(2*Nbus,2*Nbus);
Y0{1,1}=zeros(2*Nbus,2*Nbus);
Y0{1,1}(1:Nbus,1:Nbus)=eye(Nbus);
for i=1:NZ
    Y0{1+i,1}=0;
    Y0{1+NZ+i,1}=[0,0;0,1];
end
option.maxIteration=100;
option.epsilonStar=1e-7;
option.betaStar=.1;
option.betaBar=.2;
option.gammaStar=.9;
% Solve the optimization problem
[objVal,x,X,Y,INFO] = sdpam(mDIM,nBLOCK,bLOCKsTRUCT,c,F,x0,[],Y0,option);


% Reconstruct the results for validation

W2=Y{1,1};

[V2, D2]=eig(W2);
U2=sign(V2(1,end))*sqrt(D2(end,end))*V2(:,end);
[diag(D),diag(D2)]

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
close all;

figure();
subplot(221);plot([voltage_sorted(:,2),voltage2_sorted(:,2)]);


Umag=[volt1(:,1),sqrt(volt(1:Nbus).^2+volt(Nbus+1:2*Nbus).^2)];
Udeg=[volt1(:,1),atan(volt(Nbus+1:2*Nbus)./volt(1:Nbus))*180/pi-(atan(volt(Nbus+1:2*Nbus)./volt(1:Nbus))>0).*(volt1(:,1)==2)*180+(atan(volt(Nbus+1:2*Nbus)./volt(1:Nbus))<0).*(volt1(:,1)==3)*180];
Umag2=[volt1(:,1),sqrt(U2(1:Nbus).^2+U2(Nbus+1:2*Nbus).^2)];
Udeg2=[volt1(:,1),atan(U2(Nbus+1:2*Nbus)./U2(1:Nbus))*180/pi-(atan(U2(Nbus+1:2*Nbus)./U2(1:Nbus))>0).*(volt1(:,1)==2)*180+(atan(U2(Nbus+1:2*Nbus)./U2(1:Nbus))<0).*(volt1(:,1)==3)*180];

Udeg2=Udeg2+volt1(1,5)+(volt1(1,1)==2)*120-(volt1(1,1)==3)*120;

results.voltage2=voltage2;
results.voltage=voltage;
results.Umag=Umag;
results.Udeg=Udeg;
results.Umag2=Umag2;
results.Udeg2=Udeg2;

Umag=sortrows(Umag,1);
Udeg=sortrows(Udeg,1);
Umag2=sortrows(Umag2,1);
Udeg2=sortrows(Udeg2,1);


subplot(222);plot([Umag(:,2),Umag2(:,2)]);
subplot(223);plot([Udeg(:,2),Udeg2(:,2)]);



