function All(varargin)
% PercIm.Preprocess.All
%
% Description: Do all the preliminary preprocessing (mainly here as a record).
%
% Syntax: PercIm.Preprocess.All(<options>)
%
% In:
%   <options>:
%       cores: (12)
%       force: (false)
%
% Updated: 2016-06-06
% Copyright 2015 Alex Schlegel (schlegel@gmail.com) and Ethan Blackwood.  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

% fMRI data from Rolando
syncmri;
syncmri_new;

% Pull behavioral data to Helmholtz (should be there already, but just make sure)
sync_mwpi('pull','golgi');

PercIm.Preprocess.Organize(varargin{:});
PercIm.Preprocess.Functional(varargin{:});
PercIm.Preprocess.FreeSurfer(varargin{:});
PercIm.Preprocess.Masks(varargin{:});

end
