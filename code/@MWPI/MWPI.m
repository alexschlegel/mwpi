classdef MWPI < PTB.Object
% MWPI - Mental Workspace Perception vs. Imagery
%
% Description: the MWPI experiment object
%
% Syntax: mwpi = MWPI(<options>)
%
%           subfunctions:
%               Start(<options>):   start the object
%				Init:				set up the experiment
%               End:                end the object
%               PrepRun:            prepare an MWPI run
%               Run:                execute an MWPI run
%               DeleteRun:          delete data from a run (in case something bad happens)
%
% In:
%   <options>:
%       debug:      (0) the debug level
%
% Updated: 2015-06-24

    % PUBLIC PROPERTIES-------------------------------------------------%
    properties
		% objects
        Experiment;
		dm;		% subject.difficultymatch object, used only for fMRI runs
		
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
		arrow;
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
		s			= CalcParams(varargin)
		threshold	= CalcThreshold(res, sParam, kRun)
		p			= Param(varargin)
		level		= Stairstep(res, sParam, kRun, levelMin, levelMax, varargin)
		sStim		= Stimulus(class, seed, level, size, varargin)
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
            %opt.disable_key = false;
            opt.background = MWPI.Param('color','back');
            opt.text_size = MWPI.Param('text','size');
            opt.text_family = MWPI.Param('text','family');
            opt.text_color = MWPI.Param('text','colNorm');
            
            cOpt = opt2cell(opt);
            
            % create experiment
            mwpi.Experiment = PTB.Experiment(cOpt{:});
            mwpi.Start;
            
            % initialize experiment (sets reward and sParam)
            mwpi.Init;           
                      
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