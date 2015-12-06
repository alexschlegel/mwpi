function level = Stairstep(res, sParam, kRun, levelMin, levelMax, varargin)
% MWPI.Stairstep: update the level for mwpi based on past results
%				  (only has access to results from current run;
%					stairstepping restarts for each run)
%				  Uses the parameter struct to tell which runs used which
%				  classes for the retained image, so it can update the
%				  level seperately for each class.
%
% Syntax: MWPI.Stairstep(res, sParam, kRun, levelMin, levelMax, <options>)
%
% In:
%	res:		the result struct array for the current run, containing
%				results from all blocks run so far within the run. In 
%				particular, must include fields "level" and "bCorrect".
%
%	sParam:		the experiment parameter struct (see MWPI.CalcParams)
%
%	kRun:		the run number
%
%	levelMin:	the minimum possible level
%
%	levelMax:	the maximum possible level
%
%	<options>:
%		acceleration:	(0.01)	this is the rate at which the amount the level
%						increments or decrements during winning or losing
%						streaks changes. For example, if the acceleration
%						is 0, the level always changes by one step at a time,
%						whereas if it is 1, the level will increase by 1 step,
%						then 2 steps, then 3 steps, etc. while the participant is in a
%						winning streak (i.e. the level changes "stairstep").
%
%		stickiness:		(1) this is the number of consecutive correct or
%						incorrect responses necessary for the level to
%						increase or decrease. For example, if the
%						stickiness is 1, the level will update on every
%						block, but if it is 2, it will only update every
%						other block during a winning streak. Must be
%						greater than 0.
%
%		step:			(0.01) the base step (level increases or decreases
%						by this amount plus some multiple of the acceleration,
%						depending on the streak)
%
% Out:
%	level:	the calculated new level
%
% Updated: 2015-11-03

arrClass = sParam.wClass(kRun, 1:numel(res));
lastClass = arrClass(end);

level = res(end).level;
level(lastClass) = UpdateOne(res(arrClass == lastClass), lastClass, levelMin, levelMax, varargin{:});

end

function level = UpdateOne(res, class, levelMin, levelMax, varargin)

opt = ParseArgs(varargin, ...
				'acceleration',	0.01,	...
				'stickiness',	1,		...
				'step',			0.01	...
				);
			
if opt.stickiness < 1
	error('stickiness must be greater than zero');
end

if isempty(res) || ~any(strcmp('level',fieldnames(res))) || ~any(strcmp('bCorrect',fieldnames(res)))
	error('invalid results struct provided');
end

if levelMin > levelMax
	error('invalid level range provided');
end

lastLevel   = res(end).level(class);
lastCorrect = res(end).bCorrect;

if numel(res) < opt.stickiness % no way the level will change
	level = lastLevel;
else
	streak = 1;
	while streak < opt.stickiness
		if res(end - streak).bCorrect ~= lastCorrect || res(end - streak).level(class) ~= lastLevel
			break;
		end
		streak = streak + 1;
	end
	
	if streak == opt.stickiness
		if numel(res) == opt.stickiness || res(end - opt.stickiness).bCorrect ~= lastCorrect
			% first change in this direction
			thisChange = opt.step;
		else
			lastChange = abs(lastLevel - res(end - opt.stickiness).level(class));
			thisChange = lastChange + opt.acceleration;
		end
		
		if lastCorrect
			level = min(levelMax, lastLevel + thisChange);
		else
			level = max(levelMin, lastLevel - thisChange);
		end
		
	else
		level = lastLevel;
	end
end
		

end