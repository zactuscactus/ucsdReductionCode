function [A,cdv,k,ind]=setcond(n,cdref,nbit)
% n       problem size
% cdref hoped A condition number
% nbit   minimum number of bits for A entries
% A      the desired matrix
% cdv   A condition number  cdref/2 < cdref < 2*cdref
% k       number of iterations 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cdr=2^round(log2(cdref));n2=2^(round(log2(n))+1);
coef=2^nbit;nbit2=round(nbit/2);
A0=round(coef*(rand(n)-.5));cdv=cond(A0);k=1;%initialization
if cdv>cdref/2&cdv<2*cdref,A=A0;ind=0;return;end%OK
if cdv > cdref%too ill condionned initialization
    alp=2^nbit2;w=ones(n,1);ind=0;
    while cdv > 2*cdref%decrease cond
        a=alp;
        alp=alp*nbit2;
        %forcing dominant diag
        ww=w*alp;A=A0+diag(ww);cdv=cond(A);k=k+1;
    end
    if cdv>cdref/2;return;end;%OK
    b=alp;
    [alp,kk]=findalp(@cdcritd,b,a,A0,cdref);
    [f,cdv,A]=cdcritd(alp,A0,cdref);
    k=k+kk;
    if cdv>cdref/2&cdv<2*cdref,A=A0;return;end%OK
end
%not enough ill condionned initialization
dp=A0(:,n);v=ones(n-1,1);A0(:,n)=[];d=A0*v;ind=1;
c0=n2/cdr;if c0>=1,c0=.5;end;alp0=1-c0;
alp0=2^(round(log2(cdref)/4));
%find an interval [a b] containing a solution
[a,b,k]=findab(@cdcrit,alp0,dp,d,A0,cdref);k=k+1;
%find a solution wihtin [a b]
[alp,kk]=findalp(@cdcrit,a,b,dp,d,A0,cdref);k=k+kk;
alpr=2^round(log2(alp));%round to 2^**
A=[A0,dp/alpr+alp*d];cdv=cond(A);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [a,b,k]=findab(fcn,alp0,varargin)
%find a bracketing interval by doubling step
alp=alp0;k=1;
f0=feval(fcn,alp,varargin{:});f=f0;
if f0>0
    b=alp;
    while f>0
        alp=alp/2;
        f=feval(fcn,alp,varargin{:});a=alp;k=k+1;
    end
else
    a=alp;
    while f<0
        alp=alp*2;
        f=feval(fcn,alp,varargin{:});b=alp;k=k+1;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [alp,k]=findalp(fcn,a,b,varargin)
%find a zero within [a b] by dichotomy
alp=(a+b)/2;
f=feval(fcn,alp,varargin{:});k=1;
while abs(f)>.9
    if f>0
        b=alp;
    else
        a=alp;
    end
    alp=(a+b)/2;
    f=feval(fcn,alp,varargin{:});k=k+1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [f,cdv,A]=cdcritd(alp,A0,cdref)
%shift eigenvalues criterion
W=round(alp)*eye(size(A0));
A=A0+W;cdv=cond(A);
f=log2(cdv/cdref);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [f,cdv,A]=cdcrit(alp,dp,d,A0,cdref)
%pseudo rank criterion
A=[A0,dp/max(1,alp)+alp*d];cdv=cond(A);
f=log2(cdv/cdref);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%