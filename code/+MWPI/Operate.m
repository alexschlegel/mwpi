function [rot,flip] = Operate(op,varargin)
% GO.Operate
% 
% Description:	calculate the output of an operation
% 
% Syntax:	[rot,flip] = GO.Operate(op,<options>)
% 
% In:
%	op			- the operation (1:4)
%	<options>:
%		map:		([1;3;2;4]) a 4x1 array specifying a mapping from (1:4) to
%					the actual operation, ordered as (CW,CCW,H,V)
%		initrot:	(0) the initial rotation
%		initflip:	(0) the initial flip
% 
% Out:
% 	rot		- the output rotation
%	flip	- the output flip
% 
% Updated: 2013-09-24
% Copyright 2013 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
opt	= ParseArgs(varargin,...
		'map'		, [1;3;2;4]	, ...
		'initrot'	, 0			, ...
		'initflip'	, 0			  ...
		);

switch opt.map(op)
	case 1%CW
		rot		= mod(opt.initrot+1,4);
		flip	= opt.initflip;
	case 2%CCW
		rot		= mod(opt.initrot-1,4);
		flip	= opt.initflip;
	case 3%H
		switch opt.initflip
			case 0
				rot		= opt.initrot;
				flip	= 'h';
			case 'h'
				rot		= opt.initrot;
				flip	= 0;
			case 'v'
				rot		= mod(opt.initrot+2,4);
				flip	= 0;
		end
	case 4%V
		switch opt.initflip
			case 0
				rot		= opt.initrot;
				flip	= 'v';
			case 'h'
				rot		= mod(opt.initrot+2,4);
				flip	= 0;
			case 'v'
				rot		= opt.initrot;
				flip	= 0;
		end
end
