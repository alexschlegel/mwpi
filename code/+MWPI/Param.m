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
% Updated: 2015-06-24

% struct to hold param values
persistent P;

if isempty(P)
   P = InitializeP;
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

end

%----------------------------------------------------------------------%

function P = InitializeP
	%--experiment parameters----------------------------------
	P = struct;
	P.exp = struct(...
		'nRun',				10,	...
		'maxRun',			14, ...
		'blocks',			12,	...
		'RSVPLength',		5,	... number of shapes in RSVP stream
		'matchFrac',		0.3 ... average fraction of matches in RSVP
		);
	P.trTime = 2; % seconds
	P.time = struct(... all times in TRs
		'prerun',  	3,	...
		'rest',     4,  ...
		'preblock', 1,  ...
		'prompt',	1,	...
		'blank',	1,	...
		'task',		1,	... per RSVP shape
		'recall',	1,	...
		'postrun',  3   ...
		);
	P.time.taskAll = P.time.task * P.exp.RSVPLength;
	P.time.block = P.time.prompt + P.time.blank + ...
		P.time.taskAll + P.time.recall;
	P.time.run = P.time.prerun + P.time.postrun + ...
		P.exp.blocks * (P.time.preblock + P.time.block) + ...
		(P.exp.blocks - 1) * P.time.rest;
	%--display parameters-------------------------------------
	P.color = struct(...
		'back',     [127 127 127], ...
		'fore',     [0   0   0  ], ...
		'test',		[0   0   255], ...	
		'yes',      [0   255 0  ], ...
		'no',       [255 0   0  ], ...
		'text',     [0   0   0  ]  ...
		);
	P.text = struct(...
		'size',     3,     ... (d.v.a.)
		'family',   'Arial'...
		);
	P.size = struct(... d.v.a. unless otherwise indicated
		'stimpx',	200,	...
		'stim',		3,		...
		'offset',	-5, 	... vertical from center
		'textOffset',1      ... vertical from center
		);
	% copied from gridop
	P.shape = struct(...
		'rect'	, {{[0 1 1 1; 0 1 0 0; 0 1 0 0; 1 1 0 0],[1 1 1 1; 0 1 0 0; 0 1 0 0; 0 1 0 0]}}	, ...
		'polar'	, {{[1 1 0 1; 1 1 0 1; 0 1 0 0; 0 1 0 0],[0 0 1 0; 1 1 1 0; 1 1 0 0; 1 1 0 0]}}	, ...
		'rect_f', 0.94 ...
		);
end

