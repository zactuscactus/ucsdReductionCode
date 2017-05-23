function [Lia,Locb] = ismemberi(A,B,ident)


A=lower(A);
B=lower(B);

if nargin<3
	[Lia,Locb] = ismember(A,B);
else
	[Lia,Locb] = ismember(A,B,ident);
end