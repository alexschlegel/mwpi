function p = Param(varargin)
% MWPI.Param
% 
% Description:	get a mwpi parameter
% 
% Syntax:	p = MWPI.Param(f1,...,fN)
% 
% In:
% 	fK	- the the Kth parameter field
% 
% Out:
% 	p	- the parameter value
%
% Example:
%	p = MWPI.Param('color','back');
%
% Updated: 2015-05-26

% struct to hold param values
persistent P;

if isempty(P)
   InitializeP;
end

% get parameter value
p = P;
for k = 1:nargin
    field = varargin{k};
    switch class(field)
        case 'char'
            if isfield(p, field)
                p = p.(field);
            else
                p = [];
                return;
            end
        otherwise
            if iscell(p) % if we're indexing into a cell
                p = p{field};
            else
                p = [];
                return;
            end
    end
end

%----------------------------------------------------------------------%
    function InitializeP
        %--experiment parameters----------------------------------
        %--display parameters-------------------------------------
        P.color = struct(...
            'back',     'gray',     ...
            'fore',     'black',    ...
            'yes',      'green',    ...
            'no',       'red',      ...
            'text',     'black'     ...
            );
        P.text = struct(...
            'size',     [],     ...
            'family',   []      ...
            );
    end
end
