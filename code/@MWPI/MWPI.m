classdef MWPI < PTB.Object
% MWPI - Mental Workspace Perception vs. Imagery
%
% Description: the MWPI experiment object
%
% Syntax: pi = MWPI(<options>)
%
%           subfunctions:
%               Start(<options>):   start the object
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
    end
    % PUBLIC PROPERTIES-------------------------------------------------%
    
    % PRIVATE PROPERTIES------------------------------------------------%
    properties (SetAccess=private, GetAccess=private)
        argin;
    end
    % PRIVATE PROPERTIES------------------------------------------------%
    
    % PUBLIC METHODS----------------------------------------------------%
    methods
        function pi = MWPI(varargin)
            pi = pi@PTB.Object([],'mwpi');
            
            pi.argin = varargin;
            
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
            
            % initialize experiment
            pi.Experiment = PTB.Experiment(cOpt{:});
            
            % start
            pi.Start;
        end
        %-----------------------------------------------------------%
        function End(pi,varargin)
            pi.Experiment.End(varargin{:});
        end
    end
end