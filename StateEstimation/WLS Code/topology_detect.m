function [topo,generation]=topology_detect(c,node_bus)

[~,~,~,Ybus]=getYbus(c);

topo=zeros(max(node_bus(:,2)),4);
try;clear generation; end; generation{1,1}=[];generation{1,2}=[];generation{1,3}=[];
parent=1;
topo(parent,1)=parent;
[topo,generation]=topology_detect_large_vahid(topo,generation,Ybus,parent,node_bus);

topo_view=topo;
topo_view(find(topo_view(:,1)==0)',:)=[];