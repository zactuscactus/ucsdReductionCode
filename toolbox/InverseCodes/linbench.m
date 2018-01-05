function [A,b,xth,cdv]=linbench(n,cdref,kind)
% linbench computes  A, b & xth such that  A*xth=b with a specified condition number
%  A  & b having exact floating point entries and xth some properties as defined below
% standard call:
% [A,b,xth,cdv]=linbench(n,cdref,kind)
% 
% n       is the problem size
% cdref is the hoped condition number (2 norm)
% kind = 1 means xth must have exact floating point entries
% kind = 0 means xth has integer entries (default)
% kind =-1 means xth will be rationnal and contain its best floating point approximation
%
% A,b & xth the desired results if they exist
% cdv  the effective conditon number of A
%
% remarks
%  1 < cdref < 5e15 ~ 1/eps
%  b & xth may be empty if no data are found that meet expected conditions
%
%  Author A. Barraud 2006
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<3,kind=0;end
%perform initialization
cdref=min(max(1,cdref),5e15);nbit=16;nbit2=round(nbit/2);
%if kind==-1
if kind==1
    xth=round(2^nbit*(rand(n,1)-.5))*2^-nbit;
else
    xth=round(200*(rand(n,1)-.5));
end
%if kind>0,sc=round(100*rand(n,1))+1;else,sc=ones(n,1);end
if kind<0,sc=round(100*rand(n,1))+1;else,sc=ones(n,1);end
[A,cdv,k,ind]=setcond(n,cdref,nbit);
A=A*2^(-nbit2);
if ind==0
    b=A*xth;
else
    xth(n)=1;
    b=A(:,1:n-1)*xth(1:n-1)+A(:,n);
end
%verify that b entries are exact floating point number
er=0;
for k=1:n;
    [sfp,se]=exactsum(A(k,:)'.*xth);
    if length(se)>1,er=er+1;end%check if A*xth is a floating point vector
end
A=A*diag(sc);xth=xth./sc;
if er>0
    disp('b entries are not exactly floating point numbers, no generated data, too ill conditionned problem');
    xth=[];b=[];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
