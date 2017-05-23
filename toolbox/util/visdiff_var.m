function visdiff_var(n1, n2)
% VISDIFF_VAR allows you to visually compare workspace variables
%
% Due to restrictions of the underlying java implementation, the variables
% being compared must exist in the base workspace
%
% Usage:
%	VISDIFF_VAR( varname1, varname2 )
%
% Note: VISDIFF_VAR is a wrapper around the java classes that MATLAB uses
% to compare binary .mat files.  This means that the functions it uses are
% undocumented and thus may stop working in a future release.
%
% See Also: visdiff


if(nargin < 2)
	error('visdiff_var:badInput','must specify two variable names');
elseif (~(ischar(n1) && ischar(n2)))
	error('visdiff_var:badInput','pass variables by NAME not value');
elseif (~evalin('base',sprintf('exist(''%s'',''var'') && exist(''%s'',''var'')',n1,n2)))
	error('visdiff_var:nonExistentVar','variables %s and %s must exist in the base workspace',n1,n2);
end

% create comparison sources
l = com.mathworks.comparisons.source.impl.VariableSource(n1,['evalin(''base'', ''' n1 ''')']);
r = com.mathworks.comparisons.source.impl.VariableSource(n2,['evalin(''base'', ''' n2 ''')']);

% and show the comparison
com.mathworks.comparisons.main.ComparisonUtilities.startComparison(l,r)

end
