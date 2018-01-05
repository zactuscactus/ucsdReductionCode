            function [State_Estimate]=Estimate_State(ybus,zdata,bpq,dssCircuit,Ycomb,Ybase,true_volt)

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
            Free_angles=n_nodes-1;
            V = ones(n_nodes,1); % Initialize the bus voltages..
            del=round(angle(true_volt)/(pi/6))*(pi/6);
            % del = zeros(n_nodes,1); % Initialize the bus angles..
            % del(2:3:end)=-2/3*pi;
            % del(3:3:end)=2/3*pi;
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



            % Initialize using the final answer
            V0 = abs(true_volt);
            del0=angle(true_volt);
% % 
%             V=V0+1e-1;
%             del=del0;
            E = [del(2:end); V];   % State Vector..
            %% Iteration
            iter = 1;
            tol = 5;
            % figure;

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
                        clear measind1pf measind2pf measind1qf measind2qf
                        for j=1:length(nodeorder1)
                            try
                                measind1pf(j)=(find(ismember([zdata(pf,4) zdata(pf,5)],[nodeorder1(j) nodeorder2(j)],'rows')));
                            catch
                                measind1pf(j)=0;
                            end
                            try
                                measind2pf(j)=(find(ismember([zdata(pf,5) zdata(pf,4)],[nodeorder1(j) nodeorder2(j)],'rows')));
                            catch
                                measind2pf(j)=0;
                            end
                            try
                                measind1qf(j)=(find(ismember([zdata(qf,4) zdata(qf,5)],[nodeorder1(j) nodeorder2(j)],'rows')));
                            catch
                                measind1qf(j)=0;
                            end
                            try
                                measind2qf(j)=(find(ismember([zdata(qf,5) zdata(qf,4)],[nodeorder1(j) nodeorder2(j)],'rows')));
                            catch
                                measind2qf(j)=0;
                            end
                        end
                        Yprim0=dssCircuit.ActiveElement.Yprim;
                        Yprim1=Yprim0(1:2:end)+1i*Yprim0(2:2:end);
                        NewYprimLength=sqrt(length(Yprim1));
                        Yprim2=reshape(Yprim1,[NewYprimLength,NewYprimLength]);
                        Yprim3=Yprim2(1:length(nodeorder1),1:length(nodeorder2))./Ybase(nodeorder1,nodeorder1);

                        Nodeorder1{elem}=nodeorder1;
                        Nodeorder2{elem}=nodeorder2;
                        Measind1pf{elem}=measind1pf;
                        Measind2pf{elem}=measind2pf;
                        Measind1qf{elem}=measind1qf;
                        Measind2qf{elem}=measind2qf;
                        YPrim3{elem}=Yprim3;
                        YPrim_comp{elem}=zeros(n_nodes);
                        if any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
                            YPrim_comp{elem}([nodeorder1,nodeorder2],[nodeorder1,nodeorder2])=Yprim2([1:length(nodeorder1),length(nodeorder1)+2:2*length(nodeorder1)+1],[1:length(nodeorder1),length(nodeorder1)+2:2*length(nodeorder1)+1]);
                            YPrim_comp{elem}=YPrim_comp{elem}./Ybase;
                        else
                            YPrim_comp{elem}([nodeorder1,nodeorder2],[nodeorder1,nodeorder2])=Yprim2;
                            YPrim_comp{elem}=YPrim_comp{elem}./Ybase;
                        end

                    end
                end
            end

            while(tol > 1e-3)

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
                h3(i)=imag(S(zdata(qi(i),4)));
            end



            % Ybus_elem=zeros(Nbus,Nbus);
            if ~isempty(pf) || ~isempty(qf)
                for elem=1:length(AllElements)
                    if any(ismember(strsplit(AllElements{elem},'.'),'Line')) || any(ismember(strsplit(AllElements{elem},'.'),'Vsource')) || any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
                            Vcmplx=V.*exp(1i*del);
                            S=Vcmplx.*conj(YPrim_comp{elem}*Vcmplx);
                            P=real(S);
                            Q=imag(S);
                            h4(Measind1pf{elem}(find(Measind1pf{elem}~=0)))=P(Nodeorder1{elem}(find(Measind1pf{elem}~=0)));
                            h5(Measind1qf{elem}(find(Measind1qf{elem}~=0)))=Q(Nodeorder1{elem}(find(Measind1qf{elem}~=0)));
                            h4(Measind2pf{elem}(find(Measind2pf{elem}~=0)))=P(Nodeorder2{elem}(find(Measind2pf{elem}~=0)));
                            h5(Measind2qf{elem}(find(Measind2qf{elem}~=0)))=Q(Nodeorder2{elem}(find(Measind2qf{elem}~=0)));
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


                H41 = zeros(npf,Free_angles);
                H51 = zeros(nqf,Free_angles);
                H410 = zeros(npf,Free_angles);
                            for i=1:npf
                    m = fbus(pf(i));
                    n = tbus(pf(i));
            % H41 - Derivative of Real Power Flows with Angles..
                    for k = 1:(Free_angles)
                        if k+1 == m
                            H410(i,k) = V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                        else if k+1 == n
                            H410(i,k) = -V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                            else
        %                                             H41(i,k) = 0;
                            end
                        end
                    end
                            end
                H42 = zeros(npf,n_nodes);
                H52 = zeros(nqf,n_nodes);
                H420 = zeros(npf,n_nodes);
                            for i=1:npf
                    m = fbus(pf(i));
                    n = tbus(pf(i));
            % H41 - Derivative of Real Power Flows with Angles..
                                    for k = 1:n_nodes
                                        if k == m
                                            H420(i,k) = -V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
                                        else if k == n
                                            H420(i,k) = -V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
                                            else
    %                                             H42(i,k) = 0;
                                            end
                                        end
                                    end
                            end

                if ~isempty(pf) 
                    for elem=1:length(AllElements)
                        if any(ismember(strsplit(AllElements{elem},'.'),'Line')) || any(ismember(strsplit(AllElements{elem},'.'),'Vsource')) || any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
        %                         Vcmplx=V.*exp(1i*del);
        %                         S=Vcmplx.*conj(YPrim_comp{elem}*Vcmplx);
        %                         P=real(S);
        %                         Q=imag(S);
        %                         h4(Measind1{elem})=P(Nodeorder1{elem});
        %                         h5(Measind1{elem})=Q(Nodeorder1{elem});
        %                         h4(Measind2{elem})=P(Nodeorder2{elem});
        %                         h5(Measind2{elem})=Q(Nodeorder2{elem});
                                    G = real(YPrim_comp{elem});
                                    B = imag(YPrim_comp{elem});    
    % 
                            for node = 1:length(Nodeorder1{elem})
                            i=find(all([fbus(pf),tbus(pf)]'==repmat([Nodeorder1{elem}(node),Nodeorder2{elem}(node)],length(tbus(pf)),1)'));
                                if ~isempty(i)
                                    m = fbus(pf(i));
                                for k = 1:(Free_angles)
                                    if k+1 == m
                                        for n = 1:n_nodes
                                            H41(i,k) = H41(i,k) + V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                                        end
                                        H41(i,k) = H41(i,k) - V(m)^2*B(m,m);
                                    else
                                        H41(i,k) = V(m)* V(k+1)*(G(m,k+1)*sin(del(m)-del(k+1)) - B(m,k+1)*cos(del(m)-del(k+1)));
                                    end
                                end
                                for k = 1:(n_nodes)
                                    if k == m
                                        for n = 1:n_nodes
                                            H42(i,k) = H42(i,k) + V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                                        end
                                        H42(i,k) = H42(i,k) + V(m)*G(m,m);
                                    else
                                        H42(i,k) = V(m)*(G(m,k)*cos(del(m)-del(k)) + B(m,k)*sin(del(m)-del(k)));
                                    end
                                end

    %                                 for   n = [Nodeorder1{elem}(node),Nodeorder2{elem}(node)]
    %                         % H41 - Derivative of Real Power Flows with Angles..
    %                                 %for k = 1:(Free_angles)
    %                                     if k+1 == m
    %                                         H41(i,k) = V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    %                                     end
    %                                         %else if k+1 == n
    % %                                    try
    % %                                        k=n-1;
    % %                                         H41(i,k) = H41(i,k)-V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    % %                                    end
    %                                    %    else
    % %                                             H41(i,k) = 0;
    %                                     %    end
    %                                     %end
    %                                 %end
    %                         % H42 - Derivative of Real Power Flows with V..
    %                                 %for k = 1:n_nodes
    %                                  %   if k == m
    %                                  k=m;
    %                                         H42(i,k) = H42(i,k)-V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
    %                                   %  else if k == n
    % %                                   k=n;
    % %                                   try
    % %                                         H42(i,k) = H42(i,k)-V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
    % %                                   end
    %                                   %      else
    % %                                             H42(i,k) = 0;
    %                                    %     end
    %                                    % end
    %                                % end
    %                                 end
                            i=find(all([tbus(pf),fbus(pf)]'==repmat([Nodeorder1{elem}(node),Nodeorder2{elem}(node)],length(tbus(pf)),1)'));
                                if ~isempty(i)
                                    m = fbus(pf(i));
                                for k = 1:(Free_angles)
                                    if k+1 == m
                                        for n = 1:n_nodes
                                            H41(i,k) = H41(i,k) + V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
                                        end
                                        H41(i,k) = H41(i,k) - V(m)^2*B(m,m);
                                    else
                                        H41(i,k) = V(m)* V(k+1)*(G(m,k+1)*sin(del(m)-del(k+1)) - B(m,k+1)*cos(del(m)-del(k+1)));
                                    end
                                end
                                for k = 1:(n_nodes)
                                    if k == m
                                        for n = 1:n_nodes
                                            H42(i,k) = H42(i,k) + V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                                        end
                                        H42(i,k) = H42(i,k) + V(m)*G(m,m);
                                    else
                                        H42(i,k) = V(m)*(G(m,k)*cos(del(m)-del(k)) + B(m,k)*sin(del(m)-del(k)));
                                    end
                                end
                                end
    %                             if ~isempty(i)
    %                                 m = fbus(pf(i))
    %                                 for   n = [Nodeorder1{elem}(node),Nodeorder2{elem}(node)]
    %                         % H41 - Derivative of Real Power Flows with Angles..
    %                             %    for k = 1:(Free_angles)
    %                              %       if k+1 == m
    %                             
    %                              try
    %                                     k=m-1;
    %                                         H41(i,k) = H41(i,k)+V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    %                              end
    %                              %       else if k+1 == n
    % %                             try
    % %                                 k=n-1;
    % %                                         H41(i,k) = H41(i,k)-V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    % %                             end
    %                             %          else
    % %                                             H41(i,k) = 0;
    %                               %          end
    %                               %      end
    %                              %   end
    %                         % H42 - Derivative of Real Power Flows with V..
    %                                % for k = 1:n_nodes
    %                                 %    if k == m
    %                                 k=m;
    %                                 try
    %                                         H42(i,k) = H42(i,k)-V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
    %                                 end
    %                                 %    else if k == n
    % %                                 k=n;
    % %                                         H42(i,k) = H42(i,k)-V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
    % %                                %         else
    % %                                             H42(i,k) = 0;
    %                                %         end
    %                                %     end
    %                                % end
    %                                 end
    %                             end
                            end

        %                     % H42 - Derivative of Real Power Flows with V..
        %                     for i = 1:npf
        %                         m = fbus(pf(i));
        %                         n = tbus(pf(i));
        %                         for k = 1:n_nodes
        %                             if k == m
        %                                 H42(i,k) = -V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
        %                             else if k == n
        %                                 H42(i,k) = -V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
        %                                 else
        %                                     H42(i,k) = 0;
        %                                 end
        %                             end
        %                         end
        %                     end

                        end
                    end
                end
                end
                
                if ~isempty(qf) 
                    for elem=1:length(AllElements)
                        if any(ismember(strsplit(AllElements{elem},'.'),'Line')) || any(ismember(strsplit(AllElements{elem},'.'),'Vsource')) || any(ismember(strsplit(AllElements{elem},'.'),'Transformer'))
        %                         Vcmplx=V.*exp(1i*del);
        %                         S=Vcmplx.*conj(YPrim_comp{elem}*Vcmplx);
        %                         P=real(S);
        %                         Q=imag(S);
        %                         h4(Measind1{elem})=P(Nodeorder1{elem});
        %                         h5(Measind1{elem})=Q(Nodeorder1{elem});
        %                         h4(Measind2{elem})=P(Nodeorder2{elem});
        %                         h5(Measind2{elem})=Q(Nodeorder2{elem});
                                    G = real(YPrim_comp{elem});
                                    B = imag(YPrim_comp{elem});    
    % 
                            for node = 1:length(Nodeorder1{elem})
                            i=find(all([fbus(qf),tbus(qf)]'==repmat([Nodeorder1{elem}(node),Nodeorder2{elem}(node)],length(tbus(qf)),1)'));
                                if ~isempty(i)
                                    m = fbus(qf(i));
                                for k = 1:(Free_angles)
                                    if k+1 == m
                                        for n = 1:n_nodes
                                            H51(i,k) = H51(i,k) + V(m)* V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                                        end
                                        H51(i,k) = H51(i,k) - V(m)^2*G(m,m);
                                    else
                                        H51(i,k) = V(m)* V(k+1)*(-G(m,k+1)*cos(del(m)-del(k+1)) - B(m,k+1)*sin(del(m)-del(k+1)));
                                    end
                                end
                                for k = 1:(n_nodes)
                                    if k == m
                                        for n = 1:n_nodes
                                            H52(i,k) = H52(i,k) + V(n)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
                                        end
                                        H52(i,k) = H52(i,k) - V(m)*B(m,m);
                                    else
                                        H52(i,k) = V(m)*(G(m,k)*sin(del(m)-del(k)) - B(m,k)*cos(del(m)-del(k)));
                                    end
                                end

    %                                 for   n = [Nodeorder1{elem}(node),Nodeorder2{elem}(node)]
    %                         % H41 - Derivative of Real Power Flows with Angles..
    %                                 %for k = 1:(Free_angles)
    %                                     if k+1 == m
    %                                         H41(i,k) = V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    %                                     end
    %                                         %else if k+1 == n
    % %                                    try
    % %                                        k=n-1;
    % %                                         H41(i,k) = H41(i,k)-V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    % %                                    end
    %                                    %    else
    % %                                             H41(i,k) = 0;
    %                                     %    end
    %                                     %end
    %                                 %end
    %                         % H42 - Derivative of Real Power Flows with V..
    %                                 %for k = 1:n_nodes
    %                                  %   if k == m
    %                                  k=m;
    %                                         H42(i,k) = H42(i,k)-V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
    %                                   %  else if k == n
    % %                                   k=n;
    % %                                   try
    % %                                         H42(i,k) = H42(i,k)-V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
    % %                                   end
    %                                   %      else
    % %                                             H42(i,k) = 0;
    %                                    %     end
    %                                    % end
    %                                % end
    %                                 end
                            i=find(all([tbus(qf),fbus(qf)]'==repmat([Nodeorder1{elem}(node),Nodeorder2{elem}(node)],length(tbus(qf)),1)'));
                                if ~isempty(i)
                                    m = fbus(qf(i));
                                for k = 1:(Free_angles)
                                    if k+1 == m
                                        for n = 1:n_nodes
                                            H51(i,k) = H51(i,k) + V(m)* V(n)*(G(m,n)*cos(del(m)-del(n)) + B(m,n)*sin(del(m)-del(n)));
                                        end
                                        H51(i,k) = H51(i,k) - V(m)^2*G(m,m);
                                    else
                                        H51(i,k) = V(m)* V(k+1)*(-G(m,k+1)*cos(del(m)-del(k+1)) - B(m,k+1)*sin(del(m)-del(k+1)));
                                    end
                                end
                                for k = 1:(n_nodes)
                                    if k == m
                                        for n = 1:n_nodes
                                            H52(i,k) = H52(i,k) + V(n)*(G(m,n)*sin(del(m)-del(n)) - B(m,n)*cos(del(m)-del(n)));
                                        end
                                        H52(i,k) = H52(i,k) - V(m)*B(m,m);
                                    else
                                        H52(i,k) = V(m)*(G(m,k)*sin(del(m)-del(k)) - B(m,k)*cos(del(m)-del(k)));
                                    end
                                end
                                end
    %                             if ~isempty(i)
    %                                 m = fbus(pf(i))
    %                                 for   n = [Nodeorder1{elem}(node),Nodeorder2{elem}(node)]
    %                         % H41 - Derivative of Real Power Flows with Angles..
    %                             %    for k = 1:(Free_angles)
    %                              %       if k+1 == m
    %                             
    %                              try
    %                                     k=m-1;
    %                                         H41(i,k) = H41(i,k)+V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    %                              end
    %                              %       else if k+1 == n
    % %                             try
    % %                                 k=n-1;
    % %                                         H41(i,k) = H41(i,k)-V(m)* V(n)*(-G(m,n)*sin(del(m)-del(n)) + B(m,n)*cos(del(m)-del(n)));
    % %                             end
    %                             %          else
    % %                                             H41(i,k) = 0;
    %                               %          end
    %                               %      end
    %                              %   end
    %                         % H42 - Derivative of Real Power Flows with V..
    %                                % for k = 1:n_nodes
    %                                 %    if k == m
    %                                 k=m;
    %                                 try
    %                                         H42(i,k) = H42(i,k)-V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
    %                                 end
    %                                 %    else if k == n
    % %                                 k=n;
    % %                                         H42(i,k) = H42(i,k)-V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
    % %                                %         else
    % %                                             H42(i,k) = 0;
    %                                %         end
    %                                %     end
    %                                % end
    %                                 end
    %                             end
                            end

        %                     % H42 - Derivative of Real Power Flows with V..
        %                     for i = 1:npf
        %                         m = fbus(pf(i));
        %                         n = tbus(pf(i));
        %                         for k = 1:n_nodes
        %                             if k == m
        %                                 H42(i,k) = -V(n)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n))) - 2*G(m,n)*V(m);
        %                             else if k == n
        %                                 H42(i,k) = -V(m)*(-G(m,n)*cos(del(m)-del(n)) - B(m,n)*sin(del(m)-del(n)));
        %                                 else
        %                                     H42(i,k) = 0;
        %                                 end
        %                             end
        %                         end
        %                     end

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
                dE = (Gm)\(H'*Meas*r);
                E = E + dE;
                del(2:end) = E(1:Free_angles);  
                V = E(Free_angles+1:end);

                Verr(iter,:)=V-V0;
                Delerr(iter,:)=mod(del-del0+pi,2*pi)-pi;
                %% Book keeping
                iter = iter + 1;
                tol = max(abs(dE));

            % 	plot(iter,tol,'*');
            % 	hold on


%                 if mod(iter,1)==0
%                     figure(1);plot(Verr);
%                     figure(2);plot(Delerr*180/pi);
%                     pause;
%                 end

            disp(['---------- #Iterarions == ' num2str(iter) ' -----------------------------------']);	
                if iter>100
                    break
                end
            end
            %% Print out
                figure;
                subplot(2,2,1);plot(Verr); xlabel('Iterations'); ylabel('Voltage Magnitude Error (pu)');
                subplot(2,2,2);plot(Delerr); xlabel('Iterations'); ylabel('Voltage Angle Error (degree)');
                subplot(2,2,3);plot([V,V0]); xlabel('Bus Number'); ylabel('Voltage Magnitude (pu)'); legend({'Estimated' 'True'});
                subplot(2,2,4);plot([del,del0]); xlabel('Bus Number'); ylabel('Voltage Angle (degree)'); legend({'Estimated' 'True'});
                
                CvE = diag(inv(H'*Meas*H)); % Covariance matrix..

            Del = mod(180/pi*del+180,360)-180;
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