classdef MWPI < PTB.Object
% MWPI - Mental Workspace Perception vs. Imagery
%
% Description: the MWPI experiment object
%
% Syntax: mwpi = MWPI(<options>)
%
% Upon creation of the MWPI object, the user is asked whether this is a
% practice session (psychophysics) or not (fMRI). A large amount of the
% methods' functionality depends on this choice.
%
%         user-callable methods:
%           Run:                execute an MWPI run (practice or fMRI)
%			SimTest:			execute the similarity test (to be used
%								during anatomical scans)
%           End:                close textures and end the object
%			Param (static):		get an experiment parameter
%
%		  internal methods:
%           Start:               start the object
%			Init:				 set up the experiment
%			CalcParams (static): generate a set of session-specific
%								 counterbalanced parameters (stimulus
%								 classes, positions, etc.)
%			GenSeeds (static):	 utility function to generate some rng seeds
%			Stimulus (static):	 generate a visual stimulus, along with info
%			PrepTextures:		 prepare the off-screen textures for a new
%								 block
%			Block:				 run one block (i.e. a trial)
%			Instructions:		 show an instruction sequence, including a
%								 demo block with on-screen hints
%			Practice:			 do a practice run
%			FmriRun:			 do an fMRI run
%
% In:
%   <options>:
%       debug:      (0) the debug level
%
% Updated: 2016-01-29

    % PUBLIC PROPERTIES-------------------------------------------------%
    properties
		% objects
        Experiment;
		dm;		% subject.difficultymatch object, used only for fMRI runs
		assess; % subject.assess object, used only for practice runs
		
		% parameters
		nRun;
		nBlock;  % per run
        sParam;
        bPractice;
                
        % updated each block
        reward;	   % (only for fMRI)
		currD;	   % (only for fMRI - current difficulty to show stimuli, updates with each new d coming from dm)
		nCorrect;  % per run
		
		% visuals
		sTexture;
    end
    % PUBLIC PROPERTIES-------------------------------------------------%
    
    % PRIVATE PROPERTIES------------------------------------------------%
    properties (SetAccess=private, GetAccess=private)
        argin;
    end
    % PRIVATE PROPERTIES------------------------------------------------%
    
    % STATIC METHODS----------------------------------------------------%
	methods (Static)
		s				= CalcParams(varargin)
		p				= Param(varargin)
		[sStim, ifo]	= Stimulus(class, seed, level, size, varargin)
		arrSeed			= GenSeeds(varargin)
	end
	
	% INSTANCE METHODS-------------------------------------------------%
    methods
        function mwpi = MWPI(varargin)
            mwpi = mwpi@PTB.Object([],'mwpi');
            
            % build opt struct for experiment
            opt = ParseArgs(varargin, ...
                'debug'		,   0 ...
                );
            
			opt.practice = askyesno('Is this a training session?','dialog',false);
			
            mwpi.argin = varargin;
            mwpi.bPractice = opt.practice;
			strDomain = conditional(opt.practice, 'practice', 'exp');
			mwpi.nRun = MWPI.Param(strDomain, 'nRun');
			mwpi.nBlock = MWPI.Param(strDomain, 'run', 'nBlock');
            
            opt.name = 'mwpi';
            opt.context = conditional(opt.practice,'psychophysics','fmri');
            opt.tr = MWPI.Param('trTime');
            opt.input_scheme = 'lrud';
            opt.disable_key = false;
            opt.background = MWPI.Param('color','back');
            opt.text_size = MWPI.Param('text','size');
            opt.text_family = MWPI.Param('text','family');
            opt.text_color = MWPI.Param('text','colNorm');
            
            cOpt = opt2cell(opt);
            
            % create experiment
            mwpi.Experiment = PTB.Experiment(cOpt{:});
            mwpi.Start;
            
            % initialize experiment (sets reward and sParam)
            mwpi.Init(opt.debug);           
                      
        end
        %-----------------------------------------------------------%
        function End(mwpi,varargin)
			
			% close textures			
			cellfun(@(tName) mwpi.Experiment.Window.CloseTexture(tName), ...
				fieldnames(mwpi.sTexture));
			mwpi.Experiment.Window.AddLog('Textures closed.');
			
            mwpi.Experiment.End(varargin{:});
			
			if ~mwpi.bPractice
				disp(['Total reward: ' StringMoney(mwpi.reward)]);
			end
        end
    end
end