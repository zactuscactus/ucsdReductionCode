function [power, time] = solarcity_power(t_start, t_end, target)

if ~exist('t_start','var') || isempty(t_start)
	t_start=datenum(2014,11,18,14,0,0);
end
if ~exist('t_end','var') ||isempty(t_end)
	t_end=datenum(2014,11,18,15,0,0);
end
if ~exist('target','var') || isempty(target)
	target=siDeployment('PointLoma_solarcity');
end
if ~isfield(target,'power_file')
	target.power_file=[siNormalizePath('$KLEISSLLAB24-1') '/database/gridIntegration/SolarCity/raw_GSA-236.mat'];
end
if ~isfield(target,'system_ID_file')
	target.system_ID_file=[siNormalizePath('$KLEISSLLAB24-1') '/database/gridIntegration/SolarCity/raw_GSA-236_inverters.mat'];
end


power=cell(1,numel(target.footprint.PVnames));
time=cell(1,numel(target.footprint.PVnames));

x = load(target.system_ID_file,'InverterID','InstallationID');
inv2solar_LUT=[x.InverterID x.InstallationID];
y = load(target.power_file,'raw_time','raw_power','inverter_ID');

%adjust for UTC
UTC_adjust=0;datenum(0,0,0,8,0,0);
for i=1:numel(target.footprint.PVnames)
	if isnumeric(target.footprint.PVnames{i})
		PVsystem=target.footprint.PVnames{i};
		index=PVsystem==inv2solar_LUT(:,2);
		inverters=inv2solar_LUT(index,1);
		if ~isempty(index) && sum(index)==1
		index=inverters==inverter_ID;
		temp_power=raw_power(index);
		temp_time=raw_time(index)+UTC_adjust;
		index=temp_time>=t_start & temp_time<=t_end;
		power{i}=temp_power(index);%/1000;  %Pass as kW as other functionsexpect kW power information
		time{i}=temp_time(index);
		
		end
		
		%originally setup to try and do multiple invertes, now only use for
		%single inverter and hopefully we will comeup with something for
		%multipleinveters
% 		temp_time=cell(numel(inverters));
% 		temp_power=cell(numel(inverters));
% 		for j=1: numel(inverters)
% 		index=inverters(j)==inverter_ID;
% 		temp_time{j}=raw_time(index);
% 		temp_power{j}=raw_power(index);
% 		if numel(inverters)>1
% 			keyboard
% 		end
% 		end
	
	else
		power{i}=[];
		time{i}=[];
	end
	
end
end