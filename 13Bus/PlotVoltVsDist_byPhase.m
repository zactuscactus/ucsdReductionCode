
[a,OrderInd]=sort(powerFlowFullControl.Dist)
pfFc_dist=powerFlowFullControl.Dist(OrderInd);
pfFc_name=powerFlowFullControl.nodeName(OrderInd);
pfFc_volt=powerFlowFullControl.Voltage(OrderInd);
[~,rem]=strtok(pfFc_name,'.');
Ind1=find(ismember(rem,'.1')); Ind2=find(ismember(rem,'.2')); Ind3=find(ismember(rem,'.3'));
figure;plot(pfFc_dist(Ind1),pfFc_volt(Ind1),'k-o')
hold on;plot(pfFc_dist(Ind2),pfFc_volt(Ind2),'k-o')
hold on;plot(pfFc_dist(Ind3),pfFc_volt(Ind3),'k-o')

[a,OrderInd]=sort(powerFlowRedControl.Dist)
pfRc_dist=powerFlowRedControl.Dist(OrderInd);
pfRc_name=powerFlowRedControl.nodeName(OrderInd);
pfRc_volt=powerFlowRedControl.nodeName(OrderInd);
pfRc_volt=powerFlowRedControl.Voltage(OrderInd);
[~,rem]=strtok(pfRc_name,'.');
Ind1=find(ismember(rem,'.1')); Ind2=find(ismember(rem,'.2')); Ind3=find(ismember(rem,'.3'));
hold on;plot(pfRc_dist(Ind1),pfRc_volt(Ind1),':o')
hold on;plot(pfRc_dist(Ind2),pfRc_volt(Ind2),':o')
hold on;plot(pfRc_dist(Ind3),pfRc_volt(Ind3),':o')

[a,OrderInd]=sort(powerFlowFull.Dist)
pfF_dist=powerFlowFull.Dist(OrderInd);
pfF_name=powerFlowFull.nodeName(OrderInd);
pfF_volt=powerFlowFull.Voltage(OrderInd);
[~,rem]=strtok(pfF_name,'.');
Ind1=find(ismember(rem,'.1')); Ind2=find(ismember(rem,'.2')); Ind3=find(ismember(rem,'.3'));
figure;plot(pfFc_dist(Ind1),pfF_volt(Ind1),'k-o')
hold on;plot(pfFc_dist(Ind2),pfF_volt(Ind2),'k-o')
hold on;plot(pfFc_dist(Ind3),pfF_volt(Ind3),'k-o')

[a,OrderInd]=sort(powerFlowReduced.Dist)
pfR_dist=powerFlowReduced.Dist(OrderInd);
pfR_name=powerFlowReduced.nodeName(OrderInd);
pfR_volt=powerFlowReduced.Voltage(OrderInd);
[~,rem]=strtok(pfR_name,'.');
Ind1=find(ismember(rem,'.1')); Ind2=find(ismember(rem,'.2')); Ind3=find(ismember(rem,'.3'));
hold on;plot(pfR_dist(Ind1),pfR_volt(Ind1),':o')
hold on;plot(pfR_dist(Ind2),pfR_volt(Ind2),':o')
hold on;plot(pfR_dist(Ind3),pfR_volt(Ind3),':o')