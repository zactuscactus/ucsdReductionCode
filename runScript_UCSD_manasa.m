clear
clc

pathToFile='C:\Users\Zactus\FeederReduction\UCSDcircuit1_PVcorr_undersizedinv.dss';

o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear';
dssText.Command = ['Compile "' pathToFile '"'];
dssCircuit = o.ActiveCircuit;
circuit.buslist.id=regexprep(dssCircuit.AllBUSNames,'-','_');
buslist=circuit.buslist.id;
circuit.buslist.coord=zeros(length(circuit.buslist.id),2);
delete(o);
clearvars o

	criticalBuses={'SDG&E_69kV','EAST_CAMPUS_1','EAST_CAMPUS_2','EAST_CAMPUS_3','MCSS_MA','MCSS_MB','MCSS_MC','N_CAMPUS_A',...
'N_CAMPUS_B','N_CAMPUS_C','REVELLE_1','REVELLE_2','SIO_1_SUB','SIO_2_SUB','PSA','PSB','SB_B2A','SS_92_ERC','SS_83_MC_12','SS_83_MC_15','BLDG_3B_12KV'...
'BLDG_3B_15','SS_15_ERC','SS_30_RC','SS_31_RC','SS_82_WC','SS_91_WC','SERF_BLDG_PRI','PSA_LINE_TG_1','PSB_LINE_TG_2','SG1_BUS','SS_50_SC','SS_104_WC'...
'SS_64_SIO','SS_20_EC','SS_93_ERC','EBU2_LAB_PRI','SS_51_EC','SS_57_ERC','SS_13_WC'};

% criticalBuses=buslist;
cd c:/users/zactus/FeederReduction/
[circuit, circuit_orig, ~, ~, p2,voltDiff] = reducingFeeders_UCSD(pathToFile,criticalBuses,[],1)

% treeplot(topo(:,2)')
% [x,y] = treelayout(topo(:,2)');
% for ii=1:length(x)
% text(x(ii),y(ii),buslist(ii))
% end