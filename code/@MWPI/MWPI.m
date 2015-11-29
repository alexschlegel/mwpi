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
        Experiment;
		nRun;
		nBlock;  % per run
        sParam;
        bPractice;
                
        % updated each block
        reward;
		level;
		nCorrect; % per run
		
		arrow;
		sTexture;
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
			if opt.debug == 2 || opt.practice
				opt.scanner_simulate = true;
			end
% 			if opt.practice
% 				opt.event_hide = {'scanner'};
% 			end
            opt.tr = MWPI.Param('time','tr');
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
            mwpi.Init;           
                      
        end
        %-----------------------------------------------------------%
        function End(mwpi,varargin)
			
			% close textures			
			cellfun(@(tName) mwpi.Experiment.Window.CloseTexture(tName), ...
				fieldnames(mwpi.sTexture));
			mwpi.Experiment.Window.AddLog('Textures closed.');
			
            mwpi.Experiment.End(varargin{:});
        end
    end
end