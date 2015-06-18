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
% Updated: 2015-05-26

    % PUBLIC PROPERTIES-------------------------------------------------%
    properties
        Experiment;
		nRun;
		nBlock;  % per run
		RSVPLength;
		stim;    % 32 x 1 array of stimulus images
		
		% block design properties (generated with Init):
		blockType;  % nRun x nBlock char array: 'v' = visual, 'w' = working memory
		wShape; % nRun x nBlock int array; shape shown at start and end of block
		vShape; % nRun x nBlock int array; shape shown during block
		target; % nRun x nBlock int array; correct shape for each block
		rsvp;   % nRun x nBlock x RSVPLength int array for RSVP stream
		match;  % nRun x nBlock x RSVPLength int array; whether each RSVP shape is a match
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
            opt.context = conditional(opt.debug==2,'psychophysics','fmri');
            opt.tr = MWPI.Param('time','tr');
            opt.input_scheme = 'lr';
            
            % window
            opt.background = MWPI.Param('color','back');
            opt.text_size = MWPI.Param('text','size');
            opt.text_family = MWPI.Param('text','family');
            
            cOpt = opt2cell(opt);
            
            % create experiment
            mwpi.Experiment = PTB.Experiment(cOpt{:});
            
            % start
            mwpi.Start;
			
			mwpi.nRun = MWPI.Param('exp','runs');
			mwpi.nBlock = MWPI.Param('exp','blocks');
			mwpi.RSVPLength = MWPI.Param('exp','RSVPLength');
			
			% if not done yet, initialize block design
			if ~isfield(mwpi.Experiment.Info.GetAll, 'mwpi')
				mwpi.Init;
				mwpi.Experiment.Info.Set('mwpi','runsComplete',0);
			else
				% load existing values
				mwpi.blockType = mwpi.Experiment.Info.Get('mwpi','blockType');
				mwpi.wShape = mwpi.Experiment.Info.Get('mwpi','wShape');
				mwpi.vShape = mwpi.Experiment.Info.Get('mwpi','vShape');
				mwpi.target = mwpi.Experiment.Info.Get('mwpi','target');
				mwpi.rsvp = mwpi.Experiment.Info.Get('mwpi','rsvp');
				mwpi.match = mwpi.Experiment.Info.Get('mwpi','match');
			end
			
			% generate stimuli
			colFore = mwpi.Experiment.Color.Get(MWPI.Param('color','fore'));
			colBack = mwpi.Experiment.Color.Get(opt.background);
			mwpi.stim = arrayfun(@(ind) MWPI.Stim.Stimulus(ind,colFore(1:3), ...
 				colBack(1:3)), (0:31)', 'uni', false);
        end
        %-----------------------------------------------------------%
		function Init(mwpi)
			% generate the sequence of v/w blocks, target shapes, and RSVP stream.
			param.wShape = (1:32);
			param.vShape = (1:32);
			for i = 1:mwpi.RSVPLength
				param.(['rsvp',num2str(i)]) = (1:10);
			end
			
			[mwpi.blockType,param] = blockdesign('vw',mwpi.nBlock/2,mwpi.nRun,param);
			mwpi.wShape = param.wShape;
			mwpi.vShape = param.vShape;			
			mwpi.target = arrayfun(@(type,wshp,vshp) conditional(type == 'w',wshp,vshp),...
				mwpi.blockType, mwpi.wShape, mwpi.vShape);
			
			% just used to decide whether each RSVP shape is a match
			rsvpNum = arrayfun(@(i) param.(['rsvp',num2str(i)]), ...
				1:mwpi.RSVPLength,'uni',false);
			% the RSVP stream
			mwpi.rsvp = arrayfun(@(i) arrayfun(@(rsvpn,target) ...
				conditional(rsvpn <= 3, target, randi(32)),...
				rsvpNum{i}, mwpi.target), 1:mwpi.RSVPLength,'uni',false);
			
			% whether the target matches the rsvp stream
			mwpi.match = arrayfun(@(i) mwpi.rsvp{i} == mwpi.target, ...
				1:mwpi.RSVPLength, 'uni',false);
			
			mwpi.rsvp = cat(3,mwpi.rsvp{:});
			mwpi.match = cat(3,mwpi.match{:});
			
			% save
			mwpi.Experiment.Info.Set('mwpi','blockType',mwpi.blockType);
			mwpi.Experiment.Info.Set('mwpi','wShape',mwpi.wShape);
			mwpi.Experiment.Info.Set('mwpi','vShape',mwpi.vShape);
			mwpi.Experiment.Info.Set('mwpi','target',mwpi.target);
			mwpi.Experiment.Info.Set('mwpi','rsvp',mwpi.rsvp);
			mwpi.Experiment.Info.Set('mwpi','match',mwpi.match);
		end
		%-----------------------------------------------------------%
        function End(mwpi,varargin)
            mwpi.Experiment.End(varargin{:});
        end
    end
end