function a = Area()
% GO.Stim.Area
% 
% Description:	calculate the area of each of the four stimuli
% 
% Syntax:	a = GO.Stim.Area()
% 
% Updated: 2013-09-24
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
[im,b]	= arrayfun(@(k) GO.Stim.Stimulus(k),(1:4)','uni',false);
a		= cellfun(@(im) sum(im(:)),b);
