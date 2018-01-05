clc
clear all
close all

out_dir='/mnt/lab_24tb1/users/k8murray/solarcity/';
mkdir(out_dir)

t_start=datenum(2014,11,16,0,0,0);
t_end=datenum(2014,12,3,0,0,0);
% t_start=datenum(2014,11,20,0,0,0);
% t_end=datenum(2014,11,21,0,0,0);

target=siDeployment('PointLoma_solarcity');
[power, time] = solarcity_power(t_start, t_end, target);

gi=cell(size(power));
csk_gi=cell(size(power));
kt=cell(size(power));
dt = target.data_type{1};
for i=1:numel(gi)
	if ~isempty(time{i})
		gi{i} = [power{i}]/target.design.([dt 'nominal'])(i)*1000;
		csk = clearSkyIrradiance( target.ground.position, time{i}, target.design.([dt 'tilt'])(i), target.design.([dt 'azimuth'])(i));
		csk_gi{i}=csk.gi;
		kt{i}=gi{i}./csk_gi{i};
	end
end
kt_MAX=1.5;
x=vertcat(kt{:});
index=x>=0 & x<=kt_MAX;
x=x(index);
n=round(sqrt(numel(x)));
hist(x,n)
xlabel('kt')
ylabel('Counts')
title({['Histogram Data from ' datestr(t_start,'mm/dd/yy') ' to '  datestr(t_end,'mm/dd/yy') ];['Number of bins - ' num2str(n)]})
saveas(gcf,[out_dir 'PointLoma_solarcity_hist_all.fig'])

time_range=datenum(0,0,0,2,0,0);
for i=1:numel(kt)
	if ~isempty(time{i})
		sys_dir=[out_dir num2str(target.footprint.PVnames{i}) '_' num2str(i) '/'];
		mkdir(sys_dir)
		temp_time=time{i};
		temp_kt=kt{i};
		for j=1:numel(temp_time)
			index=temp_time>=temp_time(j)-time_range & temp_time<=temp_time(j);
			n=round(sqrt(numel(temp_time(index))));
			
			if n>3
				hist(temp_kt(index),n)
				xlabel('kt')
				ylabel('Counts')
				title({['Histogram Data from ' datestr(temp_time(j)-time_range,'mm/dd/yy HH:MM:SS') ' to '  datestr(temp_time(j),'mm/dd/yy HH:MM:SS') ];['Number of bins - ' num2str(n)]})
				file=['hist_' datestr(temp_time(j)-time_range,'yyyymmddHHMMSS') '_' datestr(temp_time(j),'yyyymmddHHMMSS')];
				saveas(gcf,[sys_dir file '.fig'])
				saveas(gcf,[sys_dir file '.png'])
			end
		end
	end
end