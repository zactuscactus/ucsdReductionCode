%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                                
%     [sh,sl]=qdot(x,y,ch,cl) double length accumulator (quadruple precision)
%      inner product  comutation :
%      s   = x(1)*y(1)+ ... + x(n)*y(n) + c
%      basic call :
%      s=qdot(x,y)   or     s=qdot(x,y,c)                                     
%     dot products can be computed piece wise according to :                              
%     extended call      [sh,sl]=qdot(x,y,ch,cl)                                                                                                                                
%     #h     contains the higher bits of #
%     #l      contains the lower bits of #      
%
%     default values for ch and cl are 0.
%		    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sh,sl]=qdot(x,y,ch,cl)
if nargin < 4,cl=0;end;if nargin < 3,ch=0;end
n=length(x);sh=ch;sl=cl;
for k=1:n,[ph,pl]=qprod(x(k),y(k));[sh,sl]=qadd(sh,sl,ph,pl);end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ch,cl]=qprod(a,b)
% computes exactly a*b saves as 2 doubles ch & cl
[ah,al]=split(a);[bh,bl]=split(b);
ch=a.*b;cl=(((ah.*bh-ch)+ah.*bl)+bh.*al)+al.*bl;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xh,xl]=split(x)
% xh+xl==x such that xh & xl have 27 last bits set to 0
c=134217729;%c=2^27+1;implementation for IEEE machine
cx=c*x;xh=cx-(cx-x);xl=x-xh;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ch,cl]=qadd(ah,al,bh,bl)
% performs exaxt addition of 2 "double - double"
th=ah+bh;
if(abs(ah)>=abs(bh))
   tl=(((ah-th)+bh)+al)+bl;
else
   tl=(((bh-th)+ah)+bl)+al;
end
ch=th+tl;cl=(th-ch)+tl;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%