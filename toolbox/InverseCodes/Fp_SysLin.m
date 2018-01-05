function [X,iflag,it]=Fp_SysLin(A,B)
%   Solves "exactly" the standard Linear equations  A.X = B          
%   Fp_SysLin is forward stable !
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   usage :     X = Fp_SysLin(A,B)
%          [X,iflag] = Fp_SysLin(A,B)
%   or [X,iflag,it] = Fp_SysLin(A,B)
%
%   Matrices A, B & X are real.  
%   iflag ==  2, X zero residual
%           ==  1, X has all its decimal places correct
%           ==  0, poor convergence, ill conditionned A, and or X is probably very ill scaled
%           == -1 bad final convergence probably too ill conditionned problem
%           == -2 too ill condionned problem 
%           == -3 no convergence probably too ill condionned problem
%   it            Number of iterations
%
%%   Routines called :  qdot (dll) or .m
%%
%%   Author : Alain Barraud
%%
%%   Last update May-2004
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
previous=warning;warning off;lastwarn('');%save old status 
X=[];iflag=1;it=0;%initialisation
[na,ma]=size(A);[nb,mb]=size(B);
if (ma ~= na)|(nb ~= na),error('A is not square or B dimensions do not agree!');end
%end of verifications
if na<1|nb<1,return;end%nothing to do
%
t=53;base=2;c=log10(base);ct=c*t;cmax=base^(t-1);%IEEE arith (mantissa length & base)
[U,S,V]=svd(A);d=diag(S);c=d(1)/d(na);d=repmat(d,1,mb);
if c > cmax,iflag=-2;return,end
U=U';
X=svd_solv(U,V,d,B);%standard solution via svd
xk = norm(X,1);dk = xk;itmax=t;%initialisation
R=rlin(A,X,B);if norm(R,1)==0,iflag=2;return;end%the best it can be done
while it <= itmax%loop until convergence
      DX=svd_solv(U,V,d,R);dkm1 = dk;dk = norm(DX,1);
      if it ==2,tmp=dkm1/dk;
          if tmp<3,iflag=-2;return%too ill condionned problem
          else,itmax=ct/log10(tmp)+1;end
      end
      it = it +1;X = X + DX;xk = norm(X,1);R=rlin(A,X,B);
      if norm(R,1)==0,iflag=2;return;end%no more progress possible
      if max(max(abs(DX)./(abs(X)+double(X==0))))<eps&it>1,
          iflag = 1;return;%best possible precision
      end
      if (0.5*dk > dkm1)&(it>2),iflag=-1;return;end%bad convergence 
end;
if dk<=eps*xk,iflag=0;%probably too badly scaled problem
else,iflag=-3;end;%no convergence probably too ill condionned problem
warning(previous)%reset old status
function R=rlin(A,X,B)
%Compute R=B-A*X, calls qdot 
[m,n]=size(B);R=zeros(m,n);
for i=1:m;for j=1:n
    R(i,j)=qdot(-A(i,:),X(:,j),B(i,j));%C dll for efficiency
end;end
function x=svd_solv(U,V,d,b)
z=U*b;x=V*(z./d);
%%%%%%%%%%%%%%%%% end of Fp_SysLin %%%%%%%%%%%%%%