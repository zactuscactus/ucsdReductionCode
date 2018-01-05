%% load data 
x = excel2obj('data/Free Data Set/1-minute interval data/Home 05 - with solar PV and Electric Vehicle/Home 05_1min_2012-0903.xlsx');
%% plot data: usage power of the whole house
dt = 1/60/24;
t = dt:dt:1;
figure(10)
set(gcf,'position',[50 50 1200 900]);
set(gca,'fontsize',20);
plot(t,[x.Sheet1(:).gen_kW_],t,[x.Sheet1(:).use_kW_],t,[x.Sheet1(:).Grid_kVA_],t,[x.Sheet1(:).Grid_kW_],t,[x.Sheet1(:).CAR1_kW_],'linewidth',2);
l = legend('PV Gen, kW','Home Usage, kW','Net on Grid, kVA','Net on Grid, kW','EV consumption, kW','fontsize',20);
datetick
xlabel('Time of Day'),ylabel('Power');