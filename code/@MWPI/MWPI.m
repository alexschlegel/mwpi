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
        
        % mappings
        figMap;
        opMap;
        
        % running reward total
        reward;
        % images
        arrow = [];
        op = {};
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
            
            mwpi.nRun = MWPI.Param('exp','nRun');
			mwpi.nBlock = MWPI.Param('exp','nBlock');
            
            mwpi.argin = varargin;
            
            % build opt struct for experiment
            opt = ParseArgs(varargin, ...
                'debug'		,   0, ...
				'practice'	,	false ...
                );
            opt.name = 'mwpi';
            opt.context = conditional(opt.practice,'psychophysics','fmri');
            opt.tr = MWPI.Param('time','tr');
            opt.input_scheme = 'lr';
            opt.disable_key = false;
            opt.background = MWPI.Param('color','back');
            opt.text_size = MWPI.Param('text','size');
            opt.text_family = MWPI.Param('text','family');
            opt.text_color = MWPI.Param('text','colNorm');
            
            cOpt = opt2cell(opt);
            
            % create experiment
            mwpi.Experiment = PTB.Experiment(cOpt{:});
            mwpi.Start;
            
            % hack to get the joystick to work (the triggers don't seem to
            % work)
            if strcmp(mwpi.Experiment.Info.Get('experiment','input'),'joystick')
                mwpi.Experiment.Input.Set('left','lupper');
                mwpi.Experiment.Input.Set('right','rupper');
            end
            
            % initialize experiment
            mwpi.Init;           
                      
        end
        %-----------------------------------------------------------%
        function End(mwpi,varargin)
            mwpi.Experiment.End(varargin{:});
        end
    end
end