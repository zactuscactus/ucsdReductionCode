%MainLinBench
answers=inputdlg({' Problem Size','Expected condition number',...
    'Solution type : Ineger(0), Exact floating point (-1), Rationnal(1)'},...
    'Benchmarking Linear Systems Solver',1,{'10','[1e2,1e5,1e8,1e11,1e14,1e15]','0'});
nc=char(answers{1});n=str2num(nc);
cdc=char(answers{2});cdref=str2num(cdc);
kc=char(answers{3});kind=str2num(kc);
for k=1:length(cdref)
    [A,b,xth,cd]=linbench(n,cdref(k),kind);
    if ~isempty(b)
        xm=A\b;xfp=Fp_syslin(A,b);tab=[xm,xth,xfp];
        disp(sprintf(' Problem size : %d',n))
        disp(sprintf(' Problem condition number : %5.2e',cd))
        disp('        Matlab solver            Exact Solution             Fp Solver')
        for kk=1:n
            disp(sprintf('%25.15e',tab(kk,:)))
        end
    end
    disp('------------------------------------------------------------------------------')
end