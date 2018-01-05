function [topo, generation]=topology_detect_large_vahid(topo,generation,Ybus,parent,Node_number)
[Nbus,Nbuscol]=size(Ybus);
nodes=find(Node_number(:,2)==parent);
adj_nodes=mod(find(Ybus(:,nodes)~=0)-.5,Nbus)+.5;

adj_bus=Node_number(adj_nodes,2);
[b1,m1,n1]=unique(adj_bus,'first');
adj_bus=adj_bus(sort(m1));
adj_bus(find(adj_bus==parent))=0;
for i=1:max(Node_number(:,2))
    adj_bus(find(adj_bus==topo(i,2)))=0;
end
adj_bus(find(adj_bus==0))=[];
generation{parent,1}=[];
generation{parent,2}=[];
if length(adj_bus~=0)
    for k=1:length(adj_bus)
        child=adj_bus(k);
        if max(max(topo(:,1:2)==child))==0
            topo(child,1)=child;
            topo(child,2)=parent;
            generation{child,3}=[parent;generation{parent,3}];
            [topo, generation]=topology_detect_large_vahid(topo,generation,Ybus,child,Node_number);
            topo(parent,3)=topo(parent,3)+1;
            topo(parent,4)=topo(parent,4)+topo(child,4)+1;
            generation{parent,1}=[generation{parent,1};child];
            generation{parent,2}=[generation{parent,2};child;generation{child,2}];
        end
    end
end
% topo(j,5:4+length(adj_bus))=adj_bus;
% topo(j,4)=sum(topo(adj_bus,4))+length(adj_bus);
% generation{j,1}=adj_bus;
% generation{j,2}=


