function [sfp,se]=exactsum(x)
% summing by expansion
se=x(1);
for i=2:length(x)
	se=grow_e(se,x(i));
end
se=compress2(se);se=purge(se);
if isempty(se),sfp=0;else,sfp=se(end);end
function h=grow_e(e,b)
tmp=b;m=length(e);
for i=1:m
	[tmp,h(i)]=sum_2(tmp,e(i));
end
h(m+1)=tmp;
function [x,y]=sum_2(a,b)
x=a+b;bv=x-a;av=x-bv;y=(a-av)+(b-bv);
function [x,y]=fsum_2(a,b)
x=a+b;y=b-(x-a);
function e=compress2(e)
m=length(e);tmp=e(m);bot=m;
for i=m-1:-1:1
	[tmp,q]=fsum_2(tmp,e(i));
	if q~=0
		e(bot)=tmp;bot=bot-1;tmp=q;
	end
end
e(bot)=tmp;top=1;
for i=bot+1:m
	[tmp,q]=fsum_2(e(i),tmp);
	if q~=0
		e(top)=q;top=top+1;
	end
end
e(top)=tmp;e(top+1:end)=[];
function e=purge(e)
e(find(e==0))=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%