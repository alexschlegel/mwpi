function im = StimArray(varargin)
% GO.Stim.StimArray
% 
% Description:	render all the stimuli together
% 
% Syntax:	im = GO.Stim.StimArray(<options>)
% 
% In:
%	<options>:
%		map:	(see GO.Stim.Stimulus)
% 
% Out:
% 	im	- the stimulus image
% 
% Updated: 2015-03-06
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
opt	= ParseArgs(varargin,...
		'map'	, []	  ...
		);

s	= GO.Param('size','stim');
pad	= 10;
col	= im2double(GO.Param('color','back'));
im	= arrayfun(@(k) imPad(GO.Stim.Stimulus(k,'map',opt.map),col,s+pad,s+pad),1:4,'uni',false);
im	= cat(2,im{:});
