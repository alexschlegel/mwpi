classdef MWPI < PTB.Object
% MWPI - Mental Workspace Perception vs. Imagery
%
% Description: the MWPI experiment object
%
% Syntax: mwpi = MWPI(<options>)
%
%           subfunctions:
%               Start(<options>):   start the object
%				Init:				calculate block design
%               End:                end the object
%               Run:                execute a MWPI run
%
% In:
%   <options>:
%       debug:      (0) the debug level
%
% Updated: 2015-06-24

    % PUBLIC PROPERTIES-------------------------------------------------%
    properties
        Experiment;
		nRun; % number of runs expected to be performed
		maxRun; % a bit higher than nRun, in case something gets interrupted and we need some new runs.
		nBlock;  % per run
		RSVPLength;
		stim;    % 32 x 1 cell of stimulus images
		stimYes; % stim but colored green
		stimNo;  % stim but colored red
        indH;    % indices of stimuli flipped horizontally (e.g. stim(indH(1)) = stim(1) flipped horizontally)
        indV;    % indices of stimuli flipped vertically
        indR;    % indices of stimuli rotated right
        indL;    % indices of stimuli rotated left
		runsComplete; % runsComplete(n) == 1 if run n has been completed.
		
		% block design properties (generated with Init):
		blockType;  % maxRun x nBlock char array: 'V' = visual, 'W' = working memory
		wShape; % maxRun x nBlock int array; shape shown at start and end of block
		vShape; % maxRun x nBlock int array; shape shown during block
		rShape; % maxRun x nBlock int array; shape shown during recall
		target; % maxRun x nBlock int array; correct shape for each block
		rsvp;   % maxRun x nBlock x RSVPLength int array for RSVP stream
		match;  % maxRun x nBlock x RSVPLength logical array; whether each RSVP shape is a match
		rMatch; % maxRun x nBlock logical array; true if rShape == wShape
    end
    % PUBLIC PROPERTIES-------------------------------------------------%
    
    % PRIVATE PROPERTIES------------------------------------------------%
    properties (SetAccess=private, GetAccess=private)
        argin;
    end
    % PRIVATE PROPERTIES------------------------------------------------%
    
    % PUBLIC METHODS----------------------------------------------------%
    methods
        function mwpi = MWPI(varargin)
            mwpi = mwpi@PTB.Object([],'mwpi');
            
            mwpi.argin = varargin;
            
            % parse the inputs
            opt = ParseArgs(varargin, ...
                'debug' ,   0 ...
                );
            opt.name = 'mwpi';
            opt.context = 'fmri';
            opt.tr = MWPI.Param('time','tr');
            opt.input_scheme = 'lr';			
            
            % window
            opt.background = MWPI.Param('color','back');
            opt.text_size = MWPI.Param('text','size');
            opt.text_family = MWPI.Param('text','family');
            
            cOpt = opt2cell(opt);
            
            % create experiment
            mwpi.Experiment = PTB.Experiment(cOpt{:});
            mwpi.Start;
			
			% define keys
			mwpi.Experiment.Input.Set('response',{'left','right'});
			mwpi.Experiment.Input.Set('match','left');
			mwpi.Experiment.Input.Set('noMatch','right');
			
			mwpi.nRun = MWPI.Param('exp','nRun');
			mwpi.maxRun = MWPI.Param('exp','maxRun');
			mwpi.nBlock = MWPI.Param('exp','blocks');
			mwpi.RSVPLength = MWPI.Param('exp','RSVPLength');
			
			% if not done yet, initialize block design
			if ~isfield(mwpi.Experiment.Info.GetAll, 'mwpi')
				mwpi.Init;
				mwpi.Experiment.Info.Set('mwpi','runsComplete',[]);
				mwpi.runsComplete = [];
			else
				% load existing values
				
				mwpi.blockType = mwpi.Experiment.Info.Get('mwpi','blockType');
				mwpi.wShape = mwpi.Experiment.Info.Get('mwpi','wShape');
				mwpi.vShape = mwpi.Experiment.Info.Get('mwpi','vShape');
				mwpi.rShape = mwpi.Experiment.Info.Get('mwpi','rShape');
				mwpi.target = mwpi.Experiment.Info.Get('mwpi','target');
				mwpi.rsvp = mwpi.Experiment.Info.Get('mwpi','rsvp');
				mwpi.match = mwpi.Experiment.Info.Get('mwpi','match');
				mwpi.rMatch = mwpi.Experiment.Info.Get('mwpi','rMatch');
				mwpi.runsComplete = mwpi.Experiment.Info.Get('mwpi','runsComplete');
			end
			
			% generate stimuli
			colFore = mwpi.Experiment.Color.Get(MWPI.Param('color','fore'));
			colYes = mwpi.Experiment.Color.Get(MWPI.Param('color','yes'));
			colNo = mwpi.Experiment.Color.Get(MWPI.Param('color','no'));
			colBack = mwpi.Experiment.Color.Get(opt.background);
			
            [mwpi.stim, cIndH, cIndV, cIndR, cIndL] = ...
                arrayfun(@(ind) MWPI.Stim.Stimulus(ind,colFore(1:3), ...
 				colBack(1:3)), (1:32)', 'uni', false);
            
            mwpi.indH = cell2mat(cIndH);
            mwpi.indV = cell2mat(cIndV);
            mwpi.indR = cell2mat(cIndR);
            mwpi.indL = cell2mat(cIndL);
            
			mwpi.stimYes = arrayfun(@(ind) MWPI.Stim.Stimulus(ind,colYes(1:3), ...
 				colBack(1:3)), (1:32)', 'uni', false);
			mwpi.stimNo = arrayfun(@(ind) MWPI.Stim.Stimulus(ind,colNo(1:3), ...
 				colBack(1:3)), (1:32)', 'uni', false);
        end
        %-----------------------------------------------------------%
        function End(mwpi,varargin)
            mwpi.Experiment.End(varargin{:});
        end
    end
end