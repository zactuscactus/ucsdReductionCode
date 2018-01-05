function [Zdata]=Convert_Z_toWLSForm(Z)
%Transform Z from SDP form to WLS form
Ztmp=zeros(length(Z),8);

%First column is just a counter for number of measurements
Ztmp(:,1)=1:length(Z);

%Second column needs to be measurement type
VoltMeas=find(Z(:,1)==5);
Pinj=find(Z(:,1)==1);
Qinj=find(Z(:,1)==2);
Pline=find(Z(:,1)==3);
Qline=find(Z(:,1)==4);

Ztmp(:,2:end)=Z([VoltMeas; Pinj; Qinj; Pline; Qline],:);


Z1=Z([VoltMeas; Pinj; Qinj; Pline; Qline],:);


VoltMeas=find(Ztmp(:,2)==5);
Pinj=find(Ztmp(:,2)==1);
Qinj=find(Ztmp(:,2)==2);
Pline=find(Ztmp(:,2)==3);
Qline=find(Ztmp(:,2)==4);

% % %Remove redundent line measurements
% % RemP=[];
% % for i=1:length(Pline)
% % 	Pair=[Ztmp(Pline(i),3) Ztmp(Pline(i),4)];
% % 		for j =i+1:length(Pline)
% % 			Pair2=[Ztmp(Pline(j),3) Ztmp(Pline(j),4)];
% % 				if isequal(Pair,fliplr(Pair2))
% % 					RemP=[RemP; Pline(j)];
% % 				end
% % 		end
% % end
% % RemP=unique(RemP);
% % 
% % 
% % RemQ=[];
% % for i=1:length(Qline)
% % 	Pair=[Ztmp(Qline(i),3) Ztmp(Qline(i),4)];
% % 		for j =i+1:length(Qline)
% % 			Pair2=[Ztmp(Qline(j),3) Ztmp(Qline(j),4)];
% % 				if isequal(Pair,fliplr(Pair2))
% % 					RemQ=[RemQ; Qline(j)];
% % 				end
% % 		end
% % end
% % RemQ=unique(RemQ);
% % 
% % Ztmp([RemQ; RemP],:)=[];
% % Z1([RemQ; RemP],:)=[];

VoltMeas=find(Ztmp(:,2)==5);
Pinj=find(Ztmp(:,2)==1);
Qinj=find(Ztmp(:,2)==2);
Pline=find(Ztmp(:,2)==3);
Qline=find(Ztmp(:,2)==4);

Ztmp(VoltMeas,2)=1;
Ztmp(Pinj,2)=2;
Ztmp(Qinj,2)=3;
Ztmp(Pline,2)=4;
Ztmp(Qline,2)=5;

%Third column should be Measurent
Ztmp(:,3)=Z1(:,4);

%Fourth column should be bus from
Ztmp(:,4)=Z1(:,2);

%fifth column should be bus to
Ztmp(:,5)=Z1(:,3);

%Sixth column should be measurement error
Ztmp(:,6)=Z1(:,5);

%seventh column should be bus to
Ztmp(:,7)=Z1(:,6);

%seventh column should be bus to
Ztmp(:,8)=Z1(:,7);

%write it out
Zdata=Ztmp;

end