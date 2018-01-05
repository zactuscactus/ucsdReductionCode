%%
clc
clear all
close all

t_start=datenum(2014,11,29,0,0,0);
t_end=datenum(2014,11,30,0,0,0);
% t_start=datenum(2014,11,20,0,0,0);
% t_end=datenum(2014,11,21,0,0,0);

%% 
target=siDeployment('PointLoma_solarcity');
target.power_file = [siNormalizePath('$KLEISSLLAB24-1') strrep(target.power_file,'/mnt/lab_24tb1','')];
target.system_ID_file = [siNormalizePath('$KLEISSLLAB24-1') strrep(target.system_ID_file,'/mnt/lab_24tb1','')];
[power, time] = solarcity_power(t_start, t_end, target);
figure
bad=[];
bad=[23,24,37];
for i=1:numel(power)
	
	if any(i==bad)
		continue
	end
	temp_power=power{i};
	
	temp_time=time{i};
	if ~isempty(temp_power)
		temp_power=diff(temp_power)./(diff(temp_time)*24);
		if max(temp_power)>0.05
		end
		plot(temp_time(1:end-1),temp_power,'-')
		hold all
		
	end
	
end
datetick('x')
ylabel('Power [kW]')


%plot(x)