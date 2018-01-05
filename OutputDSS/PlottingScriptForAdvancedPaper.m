alpine=load('c:\users\zactus\feederReduction\OutputDSS\Alpine_max_mean.mat');
ckt5=load('c:\users\zactus\feederReduction\OutputDSS\ckt5_max_mean.mat');
ckt7=load('c:\users\zactus\feederReduction\OutputDSS\ckt7_max_mean.mat');
j1=load('c:\users\zactus\feederReduction\OutputDSS\J1_max_mean.mat');
k1=load('c:\users\zactus\feederReduction\OutputDSS\k1_max_mean.mat');
m1=load('c:\users\zactus\feederReduction\OutputDSS\m1_max_mean.mat');
ucsd=load('c:\users\zactus\feederReduction\OutputDSS\UCSD_max_mean.mat');
IEEE=load('c:\users\zactus\feederReduction\OutputDSS\8500_max_mean.mat');



figure;semilogy(1-(alpine.CB./max(alpine.CB)),alpine.Vmax,'*')
hold on;semilogy(1-(k1.CB./max(k1.CB)),k1.Vmax,'*')
hold on;semilogy(1-(ckt7.CB./max(ckt7.CB)),ckt7.Vmax,'*')
hold on;semilogy(1-(m1.CB./max(m1.CB)),m1.Vmax,'*')
hold on;semilogy(1-(ckt5.CB./max(ckt5.CB)),ckt5.Vmax,'*')
% hold on;semilogy(1-(ucsd.CB./max(ucsd.CB)),ucsd.Vmax,'*')
hold on;semilogy(1-(j1.CB./max(j1.CB)),j1.Vmax,'*')
hold on;semilogy(1-(IEEE.CB./max(IEEE.CB)),IEEE.Vmax,'*')
% legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','UCSD','Feeder J1','IEEEE 8500','location','sw')
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','Feeder J1','IEEEE 8500','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('max( V_{full}-V_{reduced} )','fontsize',12)

figure;semilogy(1-(alpine.CB./max(alpine.CB)),alpine.Vmean,'*')
hold on;semilogy(1-(k1.CB./max(k1.CB)),k1.Vmean,'*')
hold on;semilogy(1-(ckt7.CB./max(ckt7.CB)),ckt7.Vmean,'*')
hold on;semilogy(1-(m1.CB./max(m1.CB)),m1.Vmean,'*')
hold on;semilogy(1-(ckt5.CB./max(ckt5.CB)),ckt5.Vmean,'*')
hold on;semilogy(1-(ucsd.CB./max(ucsd.CB)),ucsd.Vmean,'*')
hold on;semilogy(1-(j1.CB./max(j1.CB)),j1.Vmean,'*')
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','UCSD','Feeder J1','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('mean( V_{full}-V_{reduced} )','fontsize',12)



figure;semilogy(1-(alpine.CB./max(alpine.CB)),alpine.time,'*')
hold on;semilogy(1-(k1.CB./max(k1.CB)),k1.red_time,'*')
hold on;semilogy(1-(ckt7.CB./max(ckt7.CB)),ckt7.red_time,'*')
hold on;semilogy(1-(m1.CB./max(m1.CB)),m1.red_time,'*')
hold on;semilogy(1-(ckt5.CB./max(ckt5.CB)),ckt5.red_time,'*')
% hold on;semilogy(1-(ucsd.CB./max(ucsd.CB)),ucsd.red_time,'*')
hold on;semilogy(1-(j1.CB./max(j1.CB)),j1.red_time,'*')
hold on;semilogy(1-(IEEE.CB./max(IEEE.CB)),IEEE.red_time,'*')
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','Feeder J1','IEEE 8500','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('Reduction time (s)','fontsize',12)

figure;semilogy(1-(alpine.CB./max(alpine.CB)),alpine.time_red./alpine.time_full,'*')
hold on;semilogy(1-(k1.CB./max(k1.CB)),k1.time_red./k1.time_full,'*')
hold on;semilogy(1-(ckt7.CB./max(ckt7.CB)),ckt7.time_red./ckt7.time_full,'*')
hold on;semilogy(1-(m1.CB./max(m1.CB)),m1.time_red./m1.time_full,'*')
hold on;semilogy(1-(ckt5.CB./max(ckt5.CB)),ckt5.time_red./ckt5.time_full,'*')
hold on;semilogy(1-(ucsd.CB./max(ucsd.CB)),ucsd.time_red./ucsd.time_full,'*')
hold on;semilogy(1-(j1.CB./max(j1.CB)),j1.time_red./j1.time_full,'*')
hold on;semilogy(1-(IEEE.CB./max(IEEE.CB)),IEEE.time_red./IEEE.time_full,'*')
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','Feeder J1','IEEE 8500','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('Sim Time Full / Sim Time Redued [-]','fontsize',12)
ylim([0 1])

figure;plot(max(alpine.CB),max(alpine.Vmax),'*')
hold on;plot(max(k1.CB),max(k1.Vmax),'*')
hold on;plot(max(ckt7.CB),max(ckt7.Vmax),'*')
hold on;plot(max(m1.CB),max(m1.Vmax),'*')
hold on;plot(max(ckt5.CB),max(ckt5.Vmax),'*')
hold on;plot(max(ucsd.CB),max(ucsd.Vmax),'*')
hold on;plot(max(j1.CB),max(j1.Vmax),'*')

figure;plot(max(alpine.CB),alpine.Vmax(end),'*')
hold on;plot(max(k1.CB),k1.Vmax(end),'*')
hold on;plot(max(ckt7.CB),ckt7.Vmax(end),'*')
hold on;plot(max(m1.CB),m1.Vmax(end),'*')
hold on;plot(max(ckt5.CB),ckt5.Vmax(end),'*')
hold on;plot(max(ucsd.CB),ucsd.Vmax(end),'*')
hold on;plot(max(j1.CB),j1.Vmax(end),'*')

Inds=[504,347,3,1469,1379,810,1393];
Vmag=[alpine.Vmax(1),k1.Vmax(1),ckt7.Vmax(1),m1.Vmax(3),ckt5.Vmax(4),ucsd.Vmax(end),j1.Vmax(2)];
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','UCSD','Feeder J1','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('V_{full}-V_{reduced}','fontsize',12)


figure;plot(504,alpine.Vmax(1),'*')
hold on;plot(347,k1.Vmax(1),'*')
hold on;plot(3,ckt7.Vmax(1),'*')
hold on;plot(1469,m1.Vmax(3),'*')
hold on;plot(1379,ckt5.Vmax(10),'*')
hold on;plot(810,ucsd.Vmax(end),'*')
hold on;plot(1393,j1.Vmax(2),'*')
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','UCSD','Feeder J1','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('V_{full}-V_{reduced}','fontsize',12)

figure;plot(504,alpine.Vmean(1),'*')
hold on;plot(347,k1.Vmean(1),'*')
hold on;plot(3,ckt7.Vmean(1),'*')
hold on;plot(1469,m1.Vmean(3),'*')
hold on;plot(1379,ckt5.Vmean(10),'*')
hold on;plot(810,ucsd.Vmean(end),'*')
hold on;plot(1393,j1.Vmean(2),'*')
legend('Uitlity A','Feeder K1','EPRI 7','Feeder M1',' EPRI 5','UCSD','Feeder J1','location','sw')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('V_{full}-V_{reduced}','fontsize',12)

figure;plot(504,max(alpine.Vmax),'*')
hold on;plot(347,max(k1.Vmax),'*')
hold on;plot(3,max(ckt7.Vmax),'*')
hold on;plot(1469,max(m1.Vmax),'*')
hold on;plot(1379,max(ckt5.Vmax),'*')
hold on;plot(810,max(ucsd.Vmax),'*')
hold on;plot(1393,max(j1.Vmax),'*')

%data cleaning
alpine.CB(72)=[]; alpine.Vmax(72)=[]; alpine.Vmean(72)=[];
alpine.CB_old(64)=[];  alpine.Vmax_old(64)=[]; alpine.Vmean_old(64)=[];
alpine.CB_old(2)=[];  alpine.Vmax_old(2)=[]; alpine.Vmean_old(2)=[];

figure;semilogy(1-(alpine.CB./max(alpine.CB)),alpine.Vmax,'b*', 1-(alpine.CB./max(alpine.CB)),alpine.Vmean,'bo')
hold on;semilogy(1-(alpine.CB_old./max(alpine.CB_old)),alpine.Vmax_old,'r*',1-(alpine.CB_old./max(alpine.CB_old)),alpine.Vmean_old,'ro')
legend('Max node error', 'Mean node error','Max node error - reference [12]','Mean node error - reference [12]')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('V_{full}-V_{reduced}','fontsize',12)

alpine=load('c:\users\zactus\feederReduction\OutputDSS\Alpine_max_mean.mat');

figure;plot(1-(alpine.CB./max(alpine.CB)),alpine.time,'b*')
hold on;plot(1-(alpine.CB_old./max(alpine.CB_old)),alpine.time_old,'r*')
legend('Proposed Methodology','reference [12]')
xlabel('Buses Removed / Total Buses','fontsize',12)
ylabel('Reduction time (s)','fontsize',12)

