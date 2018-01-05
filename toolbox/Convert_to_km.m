function [Output,units]=Convert_to_km(units, Input)


% if iscell(units)
% 	units=cell2mat(units);
% end
if iscell(Input)
	Input=cell2mat(Input);
end

units=lower(units);

if length(units)<length(Input)
	error('Vectors different size in unit conversion!')
end

Ind_kft=find(ismember(units,'kft'));
	Output(Ind_kft)=Input(Ind_kft)*0.3048;
Ind_mi=find(ismember(units,'mi'));
	Output(Ind_mi)=Input(Ind_mi)*1.60934;
Ind_km=find(ismember(units,'km'));
	Output(Ind_km)=Input(Ind_km);
Ind_m=find(ismember(units,'m'));
	Output(Ind_m)=Input(Ind_m)/1000;
Ind_ft=find(ismember(units,'ft'));
	Output(Ind_ft)=Input(Ind_ft)*.0003048;
Ind_in=find(ismember(units,'in'));
	Output(Ind_in)=Input(Ind_in)*2.54e-5;
Ind_cm=find(ismember(units,'cm'));
	Output(Ind_cm)=Input(Ind_cm)*1e-5;
Ind_none=find(ismember(units,'none'));
	Output(Ind_none)=Input(Ind_none);

Output=num2cell(Output);
units(:)={'km'};
% 
% if strcmp(units,'kft')
% 	Output=Input;
% elseif strcmp(units,'mi')
% 	Output=Input*5.280;
% elseif strcmp(units,'km')
% 	Output=Input*3.28084;
% elseif strcmp(units,'m')
% 	Output=Input*.00328084;
% elseif strcmp(units,'ft')
% 	Output=Input/1000;
% elseif strcmp(units,'in')
% 	Output=Input/12/1000;
% elseif strcmp(units,'cm')
% 	Output=Input/2.54/12/1000;
% elseif strcmp(units,'none')
% 	Output=Input;
% end
end