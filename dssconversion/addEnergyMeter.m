function c = addEnergyMeter(c)
% put an energy meter at the substation if there isn't any energy meter
% in the circuit. Purpose: the distance for nodes and buses are
% calculated based on/ from this energy meter (actually closest energy
% meter)
if ~isfield(c,'energymeter')
    c.energymeter = dssenergymeter;
    c.energymeter.Name = 'substation';
    % find the element that connects to the sourcebus
    bus0 = c.circuit.bus1;
	if isempty(bus0)
		Ind=find(ismember(c.transformer(:).sub,'y'));
		bus0=c.transformer(Ind).bus(1);
	end
    if isfield(c,'transformer') % check transx first
        id = [];
        for i = 1:length(c.transformer)
            if ismember(cleanBus(lower(bus0)),cleanBus(lower(c.transformer(i).Buses)))
                id = i; break;
            end
        end
        if ~isempty(id)
            c.energymeter.element = ['transformer.' c.transformer(id).Name];
		elseif ~isempty(Ind)
			c.energymeter.element = ['transformer.' c.transformer(Ind).Name];
		else
            [~, id] = ismember(cleanBus(lower(bus0)),cleanBus(lower({c.line.bus1})));
            if id > 0
                c.energymeter.element = ['line.' c.line(id).Name];
            else
                [~, id] = ismember(cleanBus(lower(bus0)),cleanBus(lower({c.line.bus2})));
                if id > 0
                    c.energymeter.element = ['line.' c.line(id).Name];
                else
                    error('Can''t find the component that connects to sourcebus/substation, it isn''t line or transfomer! Please check again. If it''s another component besides line or transformer then the code is not currently able to handle it!');
                end
            end
        end
    else % then should be a line
        [~, id] = ismember(cleanBus(lower(bus0)),cleanBus(lower({c.line.bus1})));
        if id > 0
            c.energymeter.element = ['line.' c.line(id).Name];
        else
            [~, id] = ismember(cleanBus(lower(bus0)),cleanBus(lower({c.line.bus2})));
            if id > 0
                c.energymeter.element = ['line.' c.line(id).Name];
            else
                error('Can''t find the component that connects to sourcebus/substation, it isn''t line or transfomer! Please check again. If it''s another component besides line or transformer then the code is not currently able to handle it!');
            end
        end
    end
    c.energymeter.terminal = 1;
end
end