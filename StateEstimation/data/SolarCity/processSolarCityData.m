%% 
% x = excel2obj([normalizePath('$KLEISSLLAB24-1') '\database\gridIntegration\SolarCity\GSA-236.csv']);

%% seperate by inverterID
% invId = unique([x.GSA_236.InverterID]);
% [~,invDatId] = ismember([x.GSA_236.InverterID],invId);
% invDat = struct;
% for i = 1:length(invId)
%     invDat(i).id = invId(i);
%     datId = find(invDatId==i);
%     invDat(i).time = [x.GSA_236(datId).Measured]';
%     invDat(i).energy = [x.GSA_236(datId).Output];
% end

%% load data pre-processed by Keenan
x = load(normalizedPath('$KLEISSLLAB24-1\database\gridIntegration\SolarCity\raw_GSA-236.mat'));
invId = unique([x.inverter_ID]);
[~,invDatId] = ismember([x.inverter_ID],invId);
invDat = struct;
for i = 1:length(invId)
    invDat(i).id = invId(i);
    datId = find(invDatId==i);
    invDat(i).time = x.raw_time(datId)';
    invDat(i).energy = x.raw_power(datId)';
end

%% remove duplicate
for i = 1:length(invId)
    d = diff(invDat(i).energy);
    toRemoveId = 1 + find(d==0);
    toKeepId = setdiff(1:length(invDat(i).time),toRemoveId);
    invDat(i).time = invDat(i).time(toKeepId);
    invDat(i).energy = invDat(i).energy(toKeepId);
    invDat(i).pow = diff(invDat(i).energy)./diff(invDat(i).time)/24;
    invDat(i).numDat = length(invDat(i).time);
end

%% plot some high frequency data sites
id =find([invDat.numDat]>9000);
for i = id
    figure, plot(invDat(i).time(2:end),invDat(i).pow); datetickzoom;
    figure; plot(invDat(i).time(2:end),invDat(i).energy(2:end)-invDat(i).energy(2)); datetickzoom;
    xlabel('Time [MM/DD]'); ylabel('Power [kW]');
end
l = linkprop(findobj([3 4],'type','axes'),'xlim');
%% number of data points/ site survey
% 1 data point/ <1.25 minute
a(1) = sum([invDat.numDat]/(16*8*60)>=.8); 
% 1 data point/ 1.25-2.8 min
a(2) = sum([invDat.numDat]/(16*8*60)>=.36 & [invDat.numDat]/(16*8*60)<.8);
% 1 data point/ 2.8-
a(3) = sum([invDat.numDat]/(16*8*60)>=.16 & [invDat.numDat]/(16*8*60)<.36); 
a(4) = sum([invDat.numDat]/(16*8*60)<.16);

%% PLOT #PVinverters V.S. data frequency
figure, hist([invDat.numDat]/(16*8*60),1000);
set(gcf,'position',[560   528   560   420]);
xlabel('Number of data points per minute [-]');
ylabel('Number of inverters [-]');
%% write data to excel
% id =find([invDat.numDat]>9000);
% invDat2 = invDat(id(1:2)); 
% d = invDat2;
% for i = 1:length(d)
%     a = cell(length(d(i).time),3);
%     t = datestr(d(i).time,31);
%     for j = 1:length(d(i).time)
%         a{j,1} = t(j,:);
%         a{j,2} = d(i).energy(j);
%         if j < length(d(i).time)
%             a{j,3} = d(i).pow(j);
%         else
%             a{j,3} = [];
%         end
%     end
%     a = [{'time','energy','power'}; a];
%     xlswrite(['scdat' num2str(id(i)) '.xls'],a);
% end
%     