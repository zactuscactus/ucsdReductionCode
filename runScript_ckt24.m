clear
clc

% pathToFile='C:\Users\Zactus\FeederReduction\UCSDcircuit.dss';
% pathToFile='C:\Users\Zactus\FeederReduction\simple8500.dss';
% pathToFile='C:\Users\Zactus\FeederReductionRepo\8500-Node\Master.dss';
% pathToFile='c:\users\zactus\gridIntegration\Alpine.dss';
% pathToFile='C:\Users\Zactus\FeederReductionRepo\ckt5\Master_ckt5.dss';
% pathToFile='c:\users\zactus\FeederReductionRepo\123Bus\IEEE123Master.dss';
% pathToFile='c:\users\zactus\FeederReduction\13Bus\IEEE13Nodeckt.dss';
pathToFile='C:\Users\Zactus\FeederReduction\feederJ1\Master_J1.dss';
% delete('UCSDcircuit\UCSDcircuit_sim.mat','UCSDcircuit/UCSDcircuit_load.mat','circuits\UCSDcircuit_circuit.mat')

o = actxserver('OpendssEngine.dss');
dssText = o.Text; dssText.Command = 'Clear';
dssText.Command = ['Compile "' pathToFile '"'];
dssCircuit = o.ActiveCircuit;
circuit.buslist.id=regexprep(dssCircuit.AllBUSNames,'-','_');
buslist=circuit.buslist.id;
circuit.buslist.coord=zeros(length(circuit.buslist.id),2);
delete(o);
clearvars o

% 	buslist(find(ismember(buslist,'633')))=[];
criticalBuses=buslist;
% 	criticalBuses=circuit.buslist.id([2, 3,5]);


% 	criticalBuses=circuit.buslist.id([1,100,200,500]);
% 	criticalBuses={'M1108378','M1026695','sourcebus','m1026657','n1136663','221_282819','R18242','R42246','R42247','R20185'};
% 	criticalBuses={'sourcebus','m1026657','n1136663','221_282819'};

	%alpine
% criticalBuses={'03551327','03551328','03551328a','03551323','035513','03552577','035525','03554809'};%'035544','035545','03554807'
% criticalBuses={'03554809','035525','03551328','03551328a','03552577'};

% 	kill=find(~cellfun(@isempty,regexp(buslist,'x')));
% 	kill(1:4)=[];
% 	BuslistRem=buslist(kill); criticalBuses=BuslistRem;
% 	buslist(kill)=[]; 
% 	criticalBuses=buslist;
% criticalBuses=circuit.buslist.id([2;3;5;420;421;460;477;479;481;483;485;465;464;467;469;471;473;475;195;187;178;165;166;668;147;143;144;149;152;154;157;750;963;1233;964;1234;797;663;662;807;929;1192;927;1190;928;1191;272;256;253;252;262;264;745;1228;260;93;94;1188;105;1181;697;1068;274;258;251;248;244;245;294;292;290;288;286;282;279;249;234;235;311;312;330;329;301;302;318;317;237;236;276;277;704;705;1022;707;1134;284;283;103;104;1102;939;1206;1084;295;793;959;1229;1044;240;678;679;1020;794;1085;307;308;314;316;323;324;326;299;300;778;1147;796;844;1021;767;824;1104;656;657;1132;658;1133;756;886;887;1120;888;1121;1122;411;412;728;660;89;90;1200;766;935;1201;661;1135;729;415;416;708;872;1091;819;820;926;1189;1030;1083;741;742;943;1210;944;1211;1031;1139;664;349;160;159;115;116;95;96;99;184;140;141;863;1075;864;1076;775;834;1008;710;802;849;1035;855;1062;856;1063;889;1123;179;816;1246;181;827;878;1105;879;1106;669;81;80;142;1109;670;881;884;645;352;167;168;348;188;189;833;1007;835;1009;916;1174;367;368;379;384;388;387;732;861;1073;895;1130;837;1013;896;1131;644;646;647;785;821;948;1217;899;1140;900;1141;901;1142;836;1011;885;1117;905;1150;995;1194;986;987;486;43;44;49;21;12;13;18;34;64;748;960;1230;962;1232;67;990;1262;992;1264;994;1266;36;37;438;441;55;56;9;10;11;61;831;1089;832;1088;59;53;29;30;432;431;433;640;648;650;652;654;806;997;1172;804;981;1171;930;135;136;137;931;1196;701;134;133;980;979;74;1268;489;570;595;599;450;449;456;628;123;120;119;508;515;525;4;5;623;620;621;752;1047;753;1048;1049;531;538;544;547;548;723;876;1098;877;1099;557;556;560;565;561;84;82;83;706;1060;1059;85;86;1087;1086;684;1058;566;682;683;1107;1057;574;576;578;581;579;91;92;1116;722;1202;582;583;584;87;88;1046;585;744;952;1221;953;1222;954;1223;743;949;1218;950;1219;951;1220;632;911;1162;912;1163;913;1164;230;228;226;223;208;205;204;210;131;132;1125;659;685;686;687;690;1256;691;1255;688;692;1258;693;1257;689;1259;902;1146;739;969;1242;970;1243;971;1244;498;495;494;221;220;219;171;172;174;773;633;634;1026;635;1027;680;1069;217;215;127;128;129;130;1066;858;1065;857;1064;212;196;197;199;138;139;1112;202;790;898;1138;740;940;1207;941;1208;942;1209;225;503;520;528;534;540;546;344;343;818;936;1203;938;1205;505;511;510;518;507;514;524;530;536;542;550;555;554;559;563;572;575;577;580;784;786;1161;904;1149;761;882;1114]);
% criticalBuses=circuit.buslist.id;
%  criticalBuses=circuit.buslist.id([2,3]);	
% criticalBuses={'E_7_18_17','E_7_17_17','E_7_16_17','E_7_15_17','E_7_13_14','E_7_13_14','E_7_12_14','E_7_12_14','E_7_11_14','BUS_NC_14','E_7_C_NC2','E_7_B_NC2','E_5_W_NC2','E_5_E_NC2','E_7_5_NC2','E_7_4_NC2','E_7_3_NC2','E_7_2_NC2','E_7_1_NC2','EAST_CAMPUS_2','e_7_10_2_11','e_1_9_1_11','E_7_C_8','ss_23_wc', 'N_CAMPUS_B'};

% count=0;
% 
% for jj=1:2
% inds=1:10:length(buslist);
% for ii=inds
% 	count=count+1;
% 
% 	criticalBuses=buslist(round((length(buslist)-1)*rand(ii,1))+1);
% 	
% 	while length(unique(criticalBuses))<ii
% 		criticalBuses=[unique(criticalBuses); buslist(round((length(buslist)-1)*rand(ii-length(unique(criticalBuses)),1))+1)];
% 	end
	
	
	cd c:/users/zactus/FeederReduction/
	[circuit, circuit_orig, ~, ~, ~,voltDiff] = reducingFeeders_play_3_12_13_2017(pathToFile,criticalBuses,[],1)
% 	Vmax(count)=max(voltDiff);
% 	Vmean(count)=mean(voltDiff);
% 	CB(count)=ii;
% end
% end
% figure;plot(1-(CB./length(buslist)),Vmax,'*',1-(CB./length(buslist)),Vmean,'*')
