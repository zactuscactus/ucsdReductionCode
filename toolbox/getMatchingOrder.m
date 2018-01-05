function [OrderVar1] = getMatchingOrder(Var1,Var2)

valueSet = lower(Var1);
keySet = lower(Var2);
mapObj = containers.Map(keySet,1:length(keySet));
OrderVar1=cell2mat(values(mapObj,valueSet));
% ReOrderVar1=Var1(OrderVar1);

end
