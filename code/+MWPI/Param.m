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
        P.exp = struct(...
            'runs',				10,	...
            'blocks',			12,	...
			'RSVPLength',		5	... number of shapes in RSVP stream
            );
        P.trTime = 2; % seconds
        P.time = struct(... all times in TRs
			'pre',		2,	... before first block
			'rest',     5,  ...
            'prompt',	1,	...
			'blank',	1,	...
			'task',		1,	... per RSVP shape
			'recall',	1	...
			);
		P.time.block = P.time.prompt + P.time.blank + ...
			P.exp.RSVPLength .* P.time.task + P.time.recall;
		P.time.run = P.time.pre + P.exp.blocks .* P.time.block + ...
			(P.exp.blocks - 1) .* P.time.rest;
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
		P.size = struct(... d.v.a. unless otherwise indicated
			'stimpx',	200,	...
			'stim',		3,		...
			'letter',	3,		...
			'offset',	5		...
			);
		% copied from gridop
		P.shape = struct(...
			'rect'	, {{[0 1 1 1; 0 1 0 0; 0 1 0 0; 1 1 0 0],[1 1 1 1; 0 1 0 0; 0 1 0 0; 0 1 0 0]}}	, ...
			'polar'	, {{[1 1 0 1; 1 1 0 1; 0 1 0 0; 0 1 0 0],[0 0 1 0; 1 1 1 0; 1 1 0 0; 1 1 0 0]}}	, ...
			'rect_f', 0.94 ...
			);
    end
end
