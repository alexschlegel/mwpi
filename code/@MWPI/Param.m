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
	P = struct;
	
	%global strDirBase;
    
    SCALING_FACTOR = 0.6;
    
	%--stimulus parameters-------------------------------------
    P.stim = struct( ...
		'class',		(1:4)',	...
		'size',			SCALING_FACTOR*5.75, ...
		'offset',		SCALING_FACTOR*5.75, ...
        'sizeBorder',   SCALING_FACTOR*1/6,  ...
		'dmin',			0,		...
		'dmax',			0.5		...
		);	
	classComb	 = arrayfun(@(first) arrayfun(@(second) [first second], ...
						P.stim.class, 'uni', false), P.stim.class, 'uni', false);
	P.stim.classComb = cellnestflatten(classComb);
	
	P.arrow = struct(...
		'size',		3	...
		);
	
	%--sequence parameters----------------------------------

	P.trTime = 2000; % milliseconds
	% all remaining times are in trs.
	
	P.exp = struct(...
			'nRun',			12,		...
			'minLevel',		0,		...
			'maxLevel',		1,		...
			'startLevel',	[0.30 % fallback; normally get from subject info (see Init)
							 0.30
							 0.30
							 0.30] ...
			);
		
	P.exp.block = struct;
		P.exp.block.prompt = struct(...
			'time',		2 	 ...
			);
			P.exp.block.prompt.tStim	 = P.exp.block.prompt.time/2;
			P.exp.block.prompt.tPostStim = P.exp.block.prompt.time - P.exp.block.prompt.tStim;
			P.exp.block.prompt.tBlank	 = 0; %P.exp.block.prompt.tPostStim/5;
			P.exp.block.prompt.tFrame	 = P.exp.block.prompt.tPostStim - P.exp.block.prompt.tBlank;
		
		P.exp.block.retention = struct(...
			'time',	5		...
			);
		
		P.exp.block.test = struct(...
			'tBlankPre',	0,	...
			'tTest',		1,	...
			'tBlankPost',	0	...
			);
			P.exp.block.test.time = P.exp.block.test.tBlankPre + ...
									P.exp.block.test.tTest + ...
									P.exp.block.test.tBlankPost;
			
		P.exp.block.feedback = struct(...
			'time',	1	  ...
			);
	
	P.exp.block.time = P.exp.block.prompt.time + ...
					   P.exp.block.retention.time + ...
					   P.exp.block.test.time + ...
					   P.exp.block.feedback.time;
	
	P.exp.rest.time = 4;
	P.exp.post.time = 2;
    
	P.exp.run.nCondRep = 1; % number of times to repeat the 16 class combinations
	P.exp.run.nBlock =	numel(P.stim.classComb) * P.exp.run.nCondRep;
	P.exp.run.time = (P.exp.block.time + P.exp.rest.time) * P.exp.run.nBlock + ...
					 P.exp.post.time;
				 
	P.exp.nBlock = P.exp.run.nBlock * P.exp.nRun;
	P.exp.time   = P.exp.run.time   * P.exp.nRun;
	P.exp.nBlockPerClass = P.exp.nBlock / numel(P.stim.class);
				 
	% parameter modifications for the practice run:

	P.practice = struct(...
        'nRun',				1,		...
		'nBlockPerClass',	25,		...
		'tPreBlock',		2000,	... time to wait before each block (in ms)
		'tFbPause',			500,	... time to pause before allowing user to start next trial
		'startLevel',		[0.30
							 0.30
							 0.30
							 0.30]  ...
	);
	P.practice.run.nBlock = numel(P.stim.class) * P.practice.nBlockPerClass;
	P.practice.nBlock = P.practice.run.nBlock * P.practice.nRun;
	P.practice.block = structtreefun(@(t) t * P.trTime, P.exp.block);
    
% fixation task
	P.fixation = struct(...
		'growMult',		1.05,	... size multiplier for growing
		'shrinkMult',	0.95		... size multiplier for shrinking
		);
	
	% time parameters for fMRI run
	P.exp.fixation = struct(...
		'tChange',		0.1,	...
		'tRespond',		0.5,	...
		'tRestMin',		0		...
		);
	P.exp.fixation.tRestMax = 1.5 - P.exp.fixation.tRespond;
	P.exp.fixation.tPreMin  = P.exp.fixation.tRespond + P.exp.fixation.tRestMin;
	P.exp.fixation.tPreMax  = P.exp.fixation.tRespond + P.exp.fixation.tRestMax;
	P.exp.fixation.tTask    = P.exp.fixation.tChange + P.exp.fixation.tRespond;
	
	% time parameters for practice run
	P.practice.fixation = structfun(@(t) t * P.trTime, P.exp.fixation, 'uni',false);
    
	%--display parameters-------------------------------------
	P.color = struct(...
		'back',     [127 127 127], ...
		'fore',     [0   0   0  ], ...
		'yes',      [0   255 0  ], ...
		'no',       [255 0   0  ] ...
		);
	P.text = struct(...
		'size',			1,   ... (d.v.a.)
		'szHeader',		1.5, ...
		'szFeedback',	SCALING_FACTOR*0.75,...
        'szInst',       SCALING_FACTOR*0.8,...
		'family',		'Arial',...
        'vertOffset',   SCALING_FACTOR*4,      ...
		'horzOffset',	SCALING_FACTOR*6,		...
		'contOffset',	10,		...
        'colNorm',		'black',...
        'colYes',		'green',...
        'colNo',		'red',  ...
		'colHint',		'white', ...
        'sizeDone',		SCALING_FACTOR*3.5,    ... (d.v.a.)
        'colDone',		'red',  ...
		'instrOffset',	3		... (d.v.a.)
		);

    %--input parameters---------------------------------------
    P.key = struct(...
        'responseud',		{{'up','down'}}, ...
		'responselrud',		{{'left','right','up','down'}}, ...
		'shrink',			'down',				...
		'grow',				'up',				...
		'abort',			'key_escape'		... abort SimTest
        );
	
	%--psychometric curve parameters---------------------------------
	P.curve = struct(...
		'thresholdPerformance',	0.75,	...
		'xmin',					0,		...
		'xmax',					1,	...
		'xstep',				0.02,	...
		'chancePerformance',	0.25	...
		);
	%--reward parameters-------------------------------------------
	    P.reward = struct(...
        'base'  ,			30, ...
		'expected',			40, ...
        'max'   ,			50, ...
		'fixationPenalty',	0.01	... penalty per wrong fixation task
        );
    P.reward.rewardPerBlock		= (P.reward.max - P.reward.base) / P.exp.nBlock;
	
	nExpectedCorrect		= P.curve.thresholdPerformance * P.exp.nBlock;
	nExpectedIncorrect		= P.exp.nBlock - nExpectedCorrect;
	expectedTotalPenalty	= nExpectedCorrect * P.reward.rewardPerBlock + P.reward.base - P.reward.expected;
	
    P.reward.penaltyPerBlock	= expectedTotalPenalty / nExpectedIncorrect;
	P.reward.fFixation			= @(nYes, nNo) -P.reward.fixationPenalty * nNo;

	%--similarity test parameters-------------------------------------
	% all times in seconds
	P.simtest = struct (...
		'colRank',	'white' ...
	);
	
	%--file parameters--------------------------------------------
% 	P.path = struct(...
% 		'arrow',	PathUnsplit(DirAppend(strDirBase, 'img'),'arrow','bmp') ...
% 	);
end

