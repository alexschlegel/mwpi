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
                'debug' ,   0 ...
                );
            opt.name = 'mwpi';
            opt.context = 'fmri';
            opt.tr = MWPI.Param('time','tr');
            opt.input_scheme = 'lr';			
            opt.background = MWPI.Param('color','back');
            opt.text_size = MWPI.Param('text','size');
            opt.text_family = MWPI.Param('text','family');
            
            cOpt = opt2cell(opt);
            
            % create experiment
            mwpi.Experiment = PTB.Experiment(cOpt{:});
            mwpi.Start;
            
            % initialize experiment
            mwpi.Init;           
                      
        end
        %-----------------------------------------------------------%
        function End(mwpi,varargin)
            mwpi.Experiment.End(varargin{:});
        end
    end
end