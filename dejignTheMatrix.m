clear

syms d11 d12 d13 d14 d21 d22 d23 d24 d31 d32 d33 d34 d41 d42 d43 d44
syms E1 E2 E3 E4 E1c E2c E3c E4c
syms z11 z12 z13 z14 z22 z23 z24 z33 z34 z44
syms y11 y12 y21 y22
% Y=[1/z11+1/z12 -1/z12 0 0 ; -1/z12 1/z12+1/z22+1/z23 -1/z23 0 ; 0 -1/z23 1/z23+1/z33+1/z34 -1/z34 ; 0 0 -1/z34 1/z34+1/z44]
Y=[];
E=[E1; E2; E3; E4];
D=[d11 d12 d13 d14; d21 d22 d23 d24; d31 d32 d33 d34; d14 d24 d34 d44];

for ii=1:4
	for ll=1:4
		sum1=0;
		sum2=0;
		for jj=1:4
			sum1=sum1+Y(ii,jj)*E(jj);
		end
		for jj=2:4
			sum2=sum2+Y(ii,jj)*D(jj,ll);
		end
		
		Mat(ii,ll)=D(ii,ll)*sum1+E(ii)*sum2;
	end
end