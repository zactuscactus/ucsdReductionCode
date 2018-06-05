%code to calc dv from consumption, generate curve, and write dss file
function [dssFile, circuit] = ApplyCurves_full(circuit,circuit_orig,PTDF_p,NodeOrder,loadOrig,V_o)

%% setp 1 calc V
for ii=1:length(circuit_orig.load)
	load(ii)=circuit_orig.load(ii).kw;
	dP_pf(ii)=loadOrig(ii)-load(ii);
end

dP_pfFull=repmat(dP_pf,length(NodeOrder),1)';
dVFull_pf=zeros(size(dP_pfFull));
for ii=1:size(PTDF_p,3)-1
	dVFull_pf=dVFull_pf+(dP_pfFull.^(size(PTDF_p,3)-ii)).*PTDF_p(:,:,ii);
end

if size(dVFull_pf,1)>1
	dVFull_pf=sum(dVFull_pf);
end

dVFull_pf=V_o+dVFull_pf
%% step 2 calc DV
%inputs: PTDF, current consumption
curveNames=circuit.xycurve(:).name;
for ii=1:length(circuit.invcontrol)
	buses=regexp(circuit.invcontrol(ii).name,'_','split');
	buses=buses([2,4]);
	dv(ii)=dVFull_pf(find(ismemberi(NodeOrder,buses(1))))-dVFull_pf(find(ismemberi(NodeOrder,buses(2))));
	
	%change inverter
	curveInd=find(ismemberi(curveNames,circuit.invcontrol(ii).vvc_curve1));
	circuit.xycurve(curveInd).xarray=circuit.xycurve(curveInd).xarray+dv(ii);
end

dssFile = WriteDSS(circuit,[],0,pwd,[]);