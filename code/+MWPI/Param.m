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

global strDirBase;

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
            'blocksPerCond',	6,	...
			'RSVPLength',		5	... number of shapes in RSVP stream
            );
		P.exp.blocks = 2 .* P.exp.blocksPerCond;
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
    end
end
