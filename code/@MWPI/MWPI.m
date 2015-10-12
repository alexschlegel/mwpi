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
%		practice:	(false) we're doing practice rather than the real thing
%
% Updated: 2015-06-24

    % PUBLIC PROPERTIES-------------------------------------------------%
    properties
        Experiment;
		nRun;
		nBlock;  % per run
        sParam;
        bPractice;
                
        % running reward total
        reward;
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
                'debug'		,   0, ...
				'practice'	,	false ...
                );
            
            mwpi.argin = varargin;
            mwpi.bPractice = opt.practice;
			strDomain = conditional(opt.practice, 'practice', 'exp');
			mwpi.nRun = MWPI.Param(strDomain, 'nRun');
			mwpi.nBlock = MWPI.Param(strDomain, 'nBlock');
            
            opt.name = 'mwpi';
            opt.context = conditional(opt.practice,'psychophysics','fmri');
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
            mwpi.Experiment.End(varargin{:});
        end
    end
end