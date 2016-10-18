function s = Masks()
% PercIm.Masks
% 
% Description:	get a struct of mask names
% 
% Syntax:	s = PercIm.Masks()
% 
% Updated: 2015-03-23 as MWL.Masks
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
s.ci	=	{
				'dlpfc'
				'fef'
				'ppc'
				'pcu'
				'loc'
				'occ'
			};

s.motor	=	{
				'pmv'
				'pmd'
				'sma'
				'pre_sma'
				'primary_motor'
				'somatosensory'
				'cerebellum'
			};

s.all	= [s.motor; s.ci];

sOrig	= s;
s.left	= structtreefun(@(c) cellfun(@(str) [str '_left'],c,'uni',false),sOrig);
s.right	= structtreefun(@(c) cellfun(@(str) [str '_right'],c,'uni',false),sOrig);