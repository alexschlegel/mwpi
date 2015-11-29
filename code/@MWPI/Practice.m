function Practice(mwpi, kRun)
% Practice - do an MWPI practice session.
%
% Syntax: mwpi.Practice(kRun)
%
% In:
%	kRun: which run to execute
%
% Updated: 2015-09-03

exp = mwpi.Experiment;

% turn on keyboard listening
ListenChar(2);

% scanner simulation starts
exp.Scanner.StartScan; 

mwpi.nCorrect = 0;
res = [];
fUpdateLevel = MWPI.Param('practice','fUpdateLevel');

contOffset = MWPI.Param('text', 'contOffset');

tPreBlock = MWPI.Param('practice','tPreBlock');
tPreRun   = MWPI.Param('practice','tPreRun');

tStart = PTB.Now;
while PTB.Now < tStart + tPreRun
	exp.Scheduler.Wait;
end

for kBlock = 1:mwpi.nBlock

	DoRest(PTB.Now,tPreBlock);
	exp.AddLog(['starting block ' num2str(kBlock)]);

	newRes = mwpi.Block(kRun, kBlock);	
	newRes.level = mwpi.level;
	
	if isempty(res)
		res = newRes;
	else
		res(end+1) = newRes;
	end
	
	% update level
	mwpi.level = fUpdateLevel(res, mwpi.sParam, kRun);
	
	% pause
	tPause = MWPI.Param('practice', 'tFbPause');
	tNow = PTB.Now;
	while PTB.Now < tNow + tPause
		exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_HIGH);
	end
	
	% add continue prompt
	fbTexture = conditional(newRes.bCorrect, 'testYes', 'testNo');
	strContinue = 'Press any key to continue.';
	exp.Show.Text(strContinue, [0,contOffset], 'window', fbTexture);
	exp.Show.Texture(fbTexture);
	exp.Window.Flip;
	
	% wait for a key to be pressed
	while ~exp.Input.Down('any')
		exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
	end
	
end

% finish
exp.Scanner.StopScan;
exp.AddLog('Training run complete');
exp.Show.Text('Practice Finished!\nPlease wait for experimenter.');
exp.Window.Flip;

% enable keyboard
ListenChar(0);

% save results
sRun.res = res;
sRuns = exp.Info.Get('mwpi','run');
if isempty(sRuns)
	sRuns = sRun;
else
	sRuns(kRun) = sRun;
end
exp.Info.Set('mwpi','run',sRuns);
exp.Info.Set('mwpi','currLevel',mwpi.level);
exp.Info.AddLog('Results saved.');

% calculate threshold
bCalc = exp.Prompt.YesNo('Calculate subject''s threshold levels?', ...
	'mode', 'command_window');
if bCalc
	threshold = MWPI.CalcThreshold(res, mwpi.sParam, kRun);
	exp.Subject.Set('threshold', threshold);
	exp.Subject.AddLog('Threshold saved to subject info.');
end

%---------------------------------------------------------------------%
	function DoRest(tStart, tWait)
		% tStart, tWait in ms
		exp.Show.Blank;
		exp.Window.Flip;
		
		mwpi.PrepTextures(mwpi.sParam, kRun, kBlock, mwpi.level);
		
		while PTB.Now < tStart + tWait
			exp.Scheduler.Wait;
		end
	end
end