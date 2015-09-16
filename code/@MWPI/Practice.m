function Practice(mwpi)
% Practice - do an MWPI practice session.
%
% Syntax: mwpi.Practice
%
% Updated: 2015-09-03

chunkLen = MWPI.Param('practice','chunkLen');
chunkFreq = MWPI.Param('practice','freq');

tWaitRest = MWPI.Param('practice','tWaitRest');
tWaitFeedback = MWPI.Param('practice','tWaitFeedback');

sRun = mwpi.PrepRun;
kBlock = 1;
nCorrect = 0;
res = [];

exp = mwpi.Experiment;

% initialize texture handles
sHandle.prompt = exp.Window.OpenTexture('prompt');
sHandle.task = exp.Window.OpenTexture('task');
sHandle.probe = exp.Window.OpenTexture('probe');
sHandle.probeYes = exp.Window.OpenTexture('probeYes');
sHandle.probeNo = exp.Window.OpenTexture('probeNo');

% % turn on keyboard listening
% ListenChar(2);

for k = 1:numel(chunkLen)
	
	for m = 1:chunkFreq(k)
		
		mwpi.Mapping('wait','true');
		for n = 1:chunkLen(k)
			
			DoRest(PTB.Now,tWaitRest);
			exp.AddLog(['starting block ' num2str(kBlock)]);
			newRes = mwpi.Block(sRun, kBlock, sHandle);
			
			if isempty(res)
				res = newRes;
			else
				res(end+1) = newRes;
			end
			
			DoFeedback(newRes.bCorrect, PTB.Now, tWaitFeedback);
			
			kBlock = kBlock + 1;
			
		end
	end
end

% save results
exp.Info.Set('mwpi','practiceRes',res);
exp.AddLog('results saved');

% % enable keyboard
% ListenChar(1);

%---------------------------------------------------------------------%

 function DoFeedback(bCorrect, tStart, tWait)
        % show feedback screen
        
		% add a log message
		nCorrect    = nCorrect + bCorrect;
		strCorrect  = conditional(bCorrect,'y','n');
		strTally    = [num2str(nCorrect) '/' num2str(kBlock)];

		exp.AddLog(['feedback (' strCorrect ', ' strTally ')']);

		% show feedback texture and updated reward
		if bCorrect
			winFeedback = 'probeYes';
			strFeedback = 'Yes!';
			strColor = MWPI.Param('text','colYes');
		else
			winFeedback = 'probeNo';
			strFeedback = 'No!';
			strColor = MWPI.Param('text','colNo');
		end

		strText = ['<color:' strColor '>' strFeedback '</color>'];

		exp.Show.Text(strText,[0,MWPI.Param('text','offset')], ...
			'window', winFeedback);
      
        exp.Show.Texture(winFeedback);
        exp.Window.Flip;
		
		while PTB.Now < tStart + tWait
			exp.Scheduler.Wait;
		end
		
 end
%---------------------------------------------------------------------%
	function DoRest(tStart, tWait)
		% tStart, tWait in ms
		exp.Show.Blank;
		exp.Window.Flip;
		
		mwpi.PrepTextures(sRun, kBlock);
		
		while PTB.Now < tStart + tWait
			exp.Scheduler.Wait;
		end
	end
end