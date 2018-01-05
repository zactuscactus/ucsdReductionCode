function [State_Estimate]=Estimate_State(ybus,zdata,bpq,dssCircuit,Ycomb,Ybase)

% Power System State Estimation using Weighted Least Square Method..
%Zack Pecenak
if nargin==2
	bpq=zeros(size(ybus));
end
bpq=zeros(size(ybus));
%% Variable declaration
n_nodes = max(max(zdata(:,4)),max(zdata(:,5))); % Get number of nodes..
type = zdata(:,2); % Type of measurement, Vi - 1, Pi - 2, Qi - 3, Pij - 4, Qij - 5, Iij - 6..
z = zdata(:,3); % Measuement values..
fbus = zdata(:,4); % From bus..
tbus = zdata(:,5); % To bus..
Ri = diag(zdata(:,6)); % Measurement Error..
Meas=inv(Ri);	%Inverse of Mearuement uncertainty
Free_angles=n_nodes-3;
V = ones(n_nodes,1); % Initialize the bus voltages..
del = zeros(n_nodes,1); % Initialize the bus angles..
del(2:3:end)=-2/3*pi;
del(3:3:end)=2/3*pi;
E = [del(4:end); V];   % State Vector..
G = real(ybus);
B = imag(ybus);

vi = find(type == 1); % Index of voltage magnitude measurements..
ppi = find(type == 2); % Index of real power injection measurements..
qi = find(type == 3); % Index of reactive power injection measurements..
pf = find(type == 4); % Index of real powerflow measurements..
qf = find(type == 5); % Index of reactive powerflow measurements..

nvi = length(vi); % Number of Voltage measurements..
npi = length(ppi); % Number of Real Power Injection measurements..
nqi = length(qi); % Number of Reactive Power Injection measurements..
npf = length(pf); % Number of Real Power Flow measurements..
nqf = length(qf); % Number of Reactive Power Flow measurements..

% AllbusFlow=[zdata(:,7) zdata(:,8)];

% V(fbus(vi)) = z(vi);

% Initialize using the final answer
dssSolution = dssCircuit.Solution;
dssSolution.Solve;
VCmplx=dssCircuit.AllBusVolt'; 
volt0=VCmplx(1:2:end)+1i*VCmplx(2:2:end);
del0=[angle(volt0);0;-2*pi/3;2*pi/3];
% del=round(del0/(pi/6))*(pi/6);
%del = [-2.33489585917814e-05;-2.09441901666936;2.09437065497153;-0.00507989822710897;-2.10063304446144;2.08717023356580;-0.588577017498225;-2.67758701230995;1.50745268858999;-0.682121374456394;-2.76333169159061;1.41088705847706;0; -2*pi/3; 2*pi/3];
E = [del(1:end-3); V];   % State Vector..
%% Iteration
iter = 1;
tol = 5;
% figure;
while(tol > 1e-4)
    
	%% Measurement calculation based on estimated V and Theta
    %Measurement Function, h
    h1 = V(fbus(vi),1);
    h2 = zeros(npi,1);
    h3 = zeros(nqi,1);
    h4 = zeros(npf,1);
    h5 = zeros(nqf,1);
	
	%Real Power Injection iteration
%      for i = 1:npi
%         m = fbus(ppi(i));
%         for k = 1:n_nodes
%             h2(i) = h2(i) + V(m)*V(k)*(G(m,k)*cos(del(m)-del(k)) + B(m,k)*sin(del(m)-del(k)));
%         end
% 	 end
%     
% 	%reactive
%     for i = 1:nqi
%         m = fbus(qi(i));
%         for k = 1:n_nodes
%             h3(i) = h3(i) + V(m)*V(k)*(G(m,k)*sin(del(m)-del(k)) - B(m,k)*cos(del(m)-del(k)));
%         end
% 	end

	
	
% Vahid' code on injection and power flow measurements
Vcmp=V.*exp(1i*del);
S=Vcmp.*conj(ybus*Vcmp);

for i = 1:npi
	h2(i)=real(S(zdata(ppi(i),4)));
	h3(i)=imag(S(zdata(ppi(i),4)));
end



% Ybus_elem=zeros(Nbus,Nbus);
if ~isempty(pf) || ~isempty(qf)
	AllElements=dssCircuit.AllElementNames;
	for elem=1:length(AllElements)
		if any(ismember(strsplit(AllElements{elem},'.'),'Line')) || any(ismember(strsplit(AllElements{elem},'.'),'Vsource')) || any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
			
			dssCircuit.SetActiveElement(AllElements{elem});
			
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
			
			for j=1:length(nodeorder1)
				measind1(j)=(find(ismember([zdata(pf,4) zdata(pf,5)],[nodeorder1(j) nodeorder2(j)],'rows')));
				measind2(j)=(find(ismember([zdata(pf,5) zdata(pf,4)],[nodeorder1(j) nodeorder2(j)],'rows')));
			end
			if ~isempty(measind1)
				Yprim0=dssCircuit.ActiveElement.Yprim;
				Yprim1=Yprim0(1:2:end)+1i*Yprim0(2:2:end);
				NewYprimLength=sqrt(length(Yprim1));
				Yprim2=reshape(Yprim1,[NewYprimLength,NewYprimLength]);
				Yprim3=Yprim2(1:length(nodeorder1),1:length(nodeorder2))./Ybase(nodeorder1,nodeorder1);
				
				V1=V(nodeorder1).*exp(1i*del(nodeorder1));
				V2=V(nodeorder2).*exp(1i*del(nodeorder2));
				
				S1=V1.*conj(Yprim3*(V1-V2));
				P1=real(S1);
				Q1=imag(S1);
				
				h4(measind1)=P1;
				h5(measind1)=Q1;
			end
			if ~isempty(measind2)
				Yprim0=dssCircuit.ActiveElement.Yprim;
				Yprim1=Yprim0(1:2:end)+1i*Yprim0(2:2:end);
				NewYprimLength=sqrt(length(Yprim1));
				Yprim2=reshape(Yprim1,[NewYprimLength,NewYprimLength]);
				Yprim3=Yprim2(1:length(nodeorder1),1:length(nodeorder2))./Ybase(nodeorder1,nodeorder1);
				
				V1=V(nodeorder1).*exp(1i*del(nodeorder1));
				V2=V(nodeorder2).*exp(1i*del(nodeorder2));
				
				S2=V2.*conj(Yprim3*(V2-V1));
				P2=real(S2);
				Q2=imag(S2);
				
				h4(measind2)=P2;
				h5(measind2)=Q2;
			end
		end
	end
end
%		Ybus=Ybus_elem./Ybase;

% Original code
	
	%Real power flow iteration
%     for i = 1:npf
%         m = fbus(pf(i));
%         n = tbus(pf(i));
% % 		if i==20
% % 			stop=1;
% % 		end
% % 		
% 		h4(i) = -V(m)^2*G(m,n) - V(m)*V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
% % 		
% % % 		%Buses that power are flowing from and to
% % % 		BusFlow=[zdata(pf(i),7) zdata(pf(i),8)];
% % % 		
% % % 		%Find complete line, so that you can account for flow to all phases
% % % 		I = find(ismember(AllbusFlow(pf,:),BusFlow,'rows'));I=pf(I);
% % 		I=pf(find(zdata(pf,7)==zdata(pf(i),7)))
% % 		k_old=0;
% % 		for j=1:length(I)
% % 		k=fbus(I(j));
% % 		l=tbus(I(j));
% % 		if k~=m | l~=n
% % 			if min(~ismember(k_old,k))
% %        %Powerflow to all phases of self
% % 		h4(i) = h4(i)-V(m)*V(k)*(-G(m,k)*cos(del(m)-del(k)) - B(m,k)*sin(del(m)-del(k)));
% % 			k_old=[k_old k];
% % 			end
% % 		%Powerflow to all phases of from line
% % 		h4(i) = h4(i)-V(m)*V(l)*(-G(m,l)*cos(del(m)-del(l)) - B(m,l)*sin(del(m)-del(l)));
% % 		end
% % 		end
% 	end
% 		%A test to check if power flows through entire line. That is power
% 		%from node 10-7 is also affected by PF from node 10-8, 10-9, 10-11,
% 		%10-12
% 
% 	
% 	
% 	%Reactive power flow iteration
%     for i = 1:nqf
%         m = fbus(qf(i));
%         n = tbus(qf(i));
%         h5(i) = -V(m)^2*(-B(m,n)+bpq(m,n)) - V(m)*V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
%     end
    
    h = [h1; h2; h3; h4; h5];
    
    % Residue..
    r = z - h;
    
	%% Jacobian with respect to estimated values
    % Jacobian..
    % H11 - Derivative of V with respect to angles.. All Zeros
    H11 = zeros(nvi,Free_angles);

    % H12 - Derivative of V with respect to V.. 
    H12 = zeros(nvi,n_nodes);
	H12=diag(ones(length(H12),1));
	
	
    % H21 - Derivative of Real Power Injections with Angles..
    H21 = zeros(npi,Free_angles);
    for i = 1:npi
        m = fbus(ppi(i));
        for k = 1:(Free_angles)
            if k+1 == m
                for n = 1:n_nodes
                    H21(i,k) = H21(i,k) + V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                end
                H21(i,k) = H21(i,k) - V(m)^2*B(m,m);
            else
                H21(i,k) = V(m)* V(k+1)*(G(m,k+1)*sin(del(m)-del(k+1)) - B(m,k+1)*cos(del(m)-del(k+1)));
            end
        end
    end
    
    % H22 - Derivative of Real Power Injections with V..
    H22 = zeros(npi,n_nodes);
    for i = 1:npi
        m = fbus(ppi(i));
        for k = 1:(n_nodes)
            if k == m
                for n = 1:n_nodes
                    H22(i,k) = H22(i,k) + V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                end
                H22(i,k) = H22(i,k) + V(m)*G(m,m);
            else
                H22(i,k) = V(m)*(G(m,k)*cos(del(m)-del(k)) + B(m,k)*sin(del(m)-del(k)));
            end
        end
    end
    
    % H31 - Derivative of Reactive Power Injections with Angles..
    H31 = zeros(nqi,Free_angles);
    for i = 1:nqi
        m = fbus(qi(i));
        for k = 1:(Free_angles)
            if k+1 == m
                for n = 1:n_nodes
                    H31(i,k) = H31(i,k) + V(m)* V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                end
                H31(i,k) = H31(i,k) - V(m)^2*G(m,m);
            else
                H31(i,k) = V(m)* V(k+1)*(-G(m,k+1)*cos(del(m)-del(k+1)) - B(m,k+1)*sin(del(m)-del(k+1)));
            end
        end
    end
    
    % H32 - Derivative of Reactive Power Injections with V..
    H32 = zeros(nqi,n_nodes);
    for i = 1:nqi
        m = fbus(qi(i));
        for k = 1:(n_nodes)
            if k == m
                for n = 1:n_nodes
                    H32(i,k) = H32(i,k) + V(n)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
                end
                H32(i,k) = H32(i,k) - V(m)*B(m,m);
            else
                H32(i,k) = V(m)*(G(m,k)*sin(del(m)-del(k)) - B(m,k)*cos(del(m)-del(k)));
            end
        end
    end
    
    % H41 - Derivative of Real Power Flows with Angles..
    H41 = zeros(npf,Free_angles);
    for i = 1:npf
        m = fbus(pf(i));
        n = tbus(pf(i));
        for k = 1:(Free_angles)
            if k+1 == m
                H41(i,k) = V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
            else if k+1 == n
                H41(i,k) = -V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                else
                    H41(i,k) = 0;
                end
            end
        end
    end
    
    % H42 - Derivative of Real Power Flows with V..
    H42 = zeros(npf,Free_angles);
    for i = 1:npf
        m = fbus(pf(i));
        n = tbus(pf(i));
        for k = 1:n_nodes
            if k == m
                H42(i,k) = -V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
            else if k == n
                H42(i,k) = -V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
                else
                    H42(i,k) = 0;
                end
            end
        end
    end
    
    % H51 - Derivative of Reactive Power Flows with Angles..
    H51 = zeros(nqf,Free_angles);
    for i = 1:nqf
        m = fbus(qf(i));
        n = tbus(qf(i));
        for k = 1:(Free_angles)
            if k+1 == m
                H51(i,k) = -V(m)* V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
            else if k+1 == n
                H51(i,k) = V(m)* V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
                else
                    H51(i,k) = 0;
                end
            end
        end
    end
    
    % H52 - Derivative of Reactive Power Flows with V..
    H52 = zeros(nqf,n_nodes);
    for i = 1:nqf
        m = fbus(qf(i));
        n = tbus(qf(i));
        for k = 1:n_nodes
            if k == m
                H52(i,k) = -V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n))) - 2*V(m)*(-B(m,n)+ bpq(m,n));
            else if k == n
                H52(i,k) = -V(m)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                else
                    H52(i,k) = 0;
                end
            end
        end
    end
    
    % Measurement Jacobian, H..
    H = [H11 H12; H21 H22; H31 H32; H41 H42; H51 H52];
    
	%% Objective3 Function Calculation
    % Gain Matrix, Gm..
    Gm = H'*Meas*H;
    
    %Objective Function..
    J = sum(Meas*r.^2);  
    
    % State Vector..
    dE = inv(Gm)*(H'*Meas*r);
    E = E + .1*dE;
    del(1:end-3) = E(1:Free_angles);  
    V = E(Free_angles+1:end);
	
	Verr(iter,:)=V-z(vi);
	Delerr(iter,:)=del-del0;
	%% Book keeping
    iter = iter + 1;
    tol = max(abs(dE));
	
% 	plot(iter,tol,'*');
% 	hold on
	
	figure(1);plot(Verr);
	figure(2);plot(Delerr);
	if mod(iter,10)==0
		pause;
	end
	
disp(['---------- #Iterarions == ' num2str(iter) ' -----------------------------------']);	
	if iter>1000
		break
	end
end
%% Print out
CvE = diag(inv(H'*Meas*H)); % Covariance matrix..

Del = 180/pi*del;
State_Estimate = [V Del]; % Bus Voltages and angles..
disp('-------- State Estimation ------------------');
disp('--------------------------');
disp('| Bus |    V   |  Angle  | ');
disp('| No  |   pu   |  Degree | ');
disp('--------------------------');
for m = 1:n_nodes
    fprintf('%4g', m); fprintf('  %8.4f', V(m)); fprintf('   %8.4f', Del(m)); fprintf('\n');
end
disp('---------------------------------------------');