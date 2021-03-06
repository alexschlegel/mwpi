function res = Block(mwpi, kBlock, sParam, varargin)
% Block - do one MWPI block.
%
% Syntax: mwpi.Block(kRun, kBlock, <options>)
%
% In:
%   kBlock - the block number
%	sParam - the parameter struct for this block (see CalcParams)
%	<options>:
%		bProgress - (true) show progress indicator on the feedback screen
%
% Updated: 2016-01-27

opt = ParseArgs(varargin, 'bProgress', true);

exp = mwpi.Experiment;
strDomain	= conditional(mwpi.bPractice, 'practice', 'exp');
fTAbs		= conditional(mwpi.bPractice, @PTB.Now, @() exp.Scanner.TR);

res.bCorrect = [];
res.cClass = sParam.cClass;
res.vClass = sParam.vClass;
res.ucClass = sParam.ucClass;

% whether to reset serial port and response variable
bReset = true;
% for fixation tasks:
nFixYes = 0;
nFixNo  = 0;

% set up sequence

cF = {@DoPrompt
	  @DoRetention
	  @DoTest
	  @DoFeedback
	 };

 
tSequence = [	num2cell(cumsum([	MWPI.Param(strDomain,'block','prompt','time')
									MWPI.Param(strDomain,'block','retention','time')
									MWPI.Param(strDomain,'block','test','time')]))
				{@(tNow) deal(false, true)} % make sure it ends ahead of time
			];
		
[res.tStart, res.tEnd, res.tSequence, res.bAbort] = ...
	exp.Sequence.Linear(cF, tSequence, ...
	'tbase',	'sequence' ...
	);

%----------------------------------------------------------------------%
	function tAbs = DoPrompt(~, ~)
				
		tAbs = fTAbs();
%		tLast = tAbs;
		
% 		% debug
% 		if mwpi.bPractice
% 			disp(['prompt function started at ' num2str(tAbs) ' ms']);
% 		else
% 			disp(['prompt function started at TR ' num2str(tAbs)]);
% 		end
% 		% end debug

		cX = {	mwpi.sTexture.stim
				mwpi.sTexture.frame
			};
		
		tShow = [	{MWPI.Param(strDomain,'block','prompt','tStim')}
					{@(tNow) deal(false, true)} % make sure it ends ahead of time
				];
		
		res.prompt = struct;
		
		[res.prompt.tStart, res.prompt.tEnd, res.prompt.tShow, res.prompt.bAbort] = ...
			exp.Show.Sequence(cX, tShow, ...
			'tbase',	'sequence', ...
			'fixation',	false		...
			);
	end
%----------------------------------------------------------------------%
	function tAbs = DoRetention(tNow, tNext)
				
		tAbs = fTAbs();
%		tDiff = tAbs - tLast;
%		tLast = tAbs;
		
% 		% debug
% 		if mwpi.bPractice
% 			disp(['retention function started at ' num2str(tAbs) ' ms (+' num2str(tDiff) ')']);
% 		else
% 			disp(['retention function started at TR ' num2str(tAbs) '(+' num2str(tDiff) ')']);
% 		end
% 		% end debug
		
		% define some time functions
		fTElapsed = @() fTAbs() - tAbs;
		tDur = tNext - tNow;
		
		% show visual stimulus
		exp.Show.Texture(mwpi.sTexture.retention);
		exp.Window.Flip;
		
		% initialize things for the fixation task
		tShowFixation = cumsum( [	MWPI.Param(strDomain, 'fixation', 'tChange')
									MWPI.Param(strDomain, 'fixation', 'tRespond')
								]);
		tPreMin  = MWPI.Param(strDomain, 'fixation', 'tPreMin');
		tPreMax  = MWPI.Param(strDomain, 'fixation', 'tPreMax');
		tRestMin = MWPI.Param(strDomain, 'fixation', 'tRestMin');
		tRestMax = MWPI.Param(strDomain, 'fixation', 'tRestMax');
				
		kShrink      = exp.Input.Get('shrink');
		kGrow	     = exp.Input.Get('grow');
		strResponse  = 'responseud';
	
		tTaskStart = randBetween(tPreMin, tPreMax);
		sched = exp.Scheduler;
		
		res.retention = [];
		
		% time required for one fixation task
		tTask = MWPI.Param(strDomain, 'fixation', 'tTask');

		while tTaskStart < tDur - tTask
			
			% set up fixation task
			resOne.bGrow = randFrom([true, false]);
			kCorrect = cell2mat(conditional(resOne.bGrow, kGrow, kShrink));
			hTask = conditional(resOne.bGrow, mwpi.sTexture.retentionLg, mwpi.sTexture.retentionSm);			
			
			cXFixation = {	hTask
							mwpi.sTexture.retention
						  };
			 
			fWaitFixation = repmat({@(tNow, tNext) WaitTest(kCorrect, strResponse, tNow, tNext)}, 2,1);
			 
			bReset = true;
			
			% wait for a variable rest period
			while fTElapsed() < tTaskStart
				sched.Wait(sched.PRIORITY_CRITICAL);
			end			
			
			% do fixation task
			[resOne.tStart, resOne.tEnd, resOne.tShow, resOne.bAbort, ...
				resOne.bCorrect, resOne.kResponse, resOne.tResponse] = ...
				exp.Show.Sequence(cXFixation, tShowFixation, ...
				'tbase',	'sequence', ...
				'fixation',	false, ...
				'fwait',	fWaitFixation ...
				);
			
			% record results
			if isempty(resOne.bCorrect) || ~resOne.bCorrect{1}
				resOne.bCorrect = false;
				nFixNo = nFixNo + 1;
			else
				resOne.bCorrect = true;
				nFixYes = nFixYes + 1;
			end
			
			if isempty(res.retention)
				res.retention = resOne;
			else
				res.retention(end+1) = resOne;
			end
			
			tTaskStart = tTaskStart + tTask + randBetween(tRestMin, tRestMax);
		end
		
		% make sure serial port gets flushed again
		bReset = true;
		
		% save percent correct and show a log message
		res.fracFixationCorrect = (nFixYes / (nFixYes + nFixNo));
		pctFixationCorrect = round(100 * res.fracFixationCorrect);
		exp.AddLog(['fixations correct: ' num2str(nFixYes) '/' num2str(nFixYes + nFixNo) ...
			' (' num2str(pctFixationCorrect) '%)']);
	end
%----------------------------------------------------------------------%
	function tAbs = DoTest(~, ~)
		
		tAbs = fTAbs();
%		tDiff = tAbs - tLast;
%		tLast = tAbs;
		
% 		% debug
% 		if mwpi.bPractice
% 			disp(['test function started at ' num2str(tAbs) ' ms (+' num2str(tDiff) ')']);
% 		else
% 			disp(['test function started at TR ' num2str(tAbs) '(+' num2str(tDiff) ')']);
% 		end
% 		% end debug
		
		cX = {	%{'Blank','fixation',false}
				mwpi.sTexture.test
				%{'Blank','fixation',false}
			};
		
		tShow = ...cumsum([	MWPI.Param(strDomain,'block','test','tBlankPre')
							MWPI.Param(strDomain,'block','test','tTest');
							%MWPI.Param(strDomain,'block','test','tBlankPost')
						%]);
					
		posMatch = sParam.posMatch;
		
		dirCorrect = switch2(posMatch, ...
			1,	'up',		...
			2,	'right',	...
			3,	'down',		...
			4,	'left'		...
			);

		kCorrect    = cell2mat(exp.Input.Get(dirCorrect));
		strResponse = 'responselrud';

		fWait = {	%@WaitDefault
					@(tNow, tNext) WaitTest(kCorrect, strResponse, tNow, tNext)
					%@(tNow, tNext) WaitTest(kCorrect, strResponse, tNow, tNext)
				};
			
		res.test = struct;
		
		[res.test.tStart, res.test.tEnd, res.test.tShow, res.test.bAbort, ...
			res.test.bCorrect, res.test.kResponse, res.test.tResponse] = ...
			exp.Show.Sequence(cX, tShow, ...
			'tbase',	'sequence',	...
			'fixation',	false,		...
			'fwait',	fWait		...
			);
		
		if numel(res.test.bCorrect) > 0
			res.bCorrect = res.test.bCorrect{1};
		end
		
	end
%----------------------------------------------------------------------%
	function tAbs = DoFeedback(~, ~)
		
		tAbs = fTAbs();
%		tDiff = tAbs - tLast;
		
% 		% debug
% 		if mwpi.bPractice
% 			disp(['feedback function started at ' num2str(tAbs) ' ms (+' num2str(tDiff) ')']);
% 		else
% 			disp(['feedback function started at TR ' num2str(tAbs) '(+' num2str(tDiff) ')']);
% 		end
% 		% end debug
		
	% update correct total, reward, show feedback screen	
		
		% show feedback texture and updated reward
		strColYes = MWPI.Param('text','colYes');
		strColNo  = MWPI.Param('text','colNo');
		
		baseReward = MWPI.Param('reward', 'base');
		
		if res.bCorrect
			winFeedback = 'testYes';
			strCorrect = 'Yes!';
			strColor = strColYes;
			res.dRewardTest = MWPI.Param('reward','rewardPerBlock');
		elseif isempty(res.bCorrect)
			res.bCorrect = false;
			winFeedback = 'testNo';
			strCorrect = 'Too slow!';
			strColor = strColNo;
			res.dRewardTest = -min([MWPI.Param('reward','penaltyPerBlock'), ...
				mwpi.reward - baseReward]);
		else
			winFeedback = 'testNo';
			strCorrect = 'No!';
			strColor = strColNo;
			res.dRewardTest = -min([MWPI.Param('reward','penaltyPerBlock'), ...
				mwpi.reward - baseReward]);
		end
		
		rewardSubtotal = mwpi.reward + res.dRewardTest;
		
		% take fixation task into account				
		fRewardFixation = MWPI.Param('reward','fFixation');
		res.dRewardFixation = max([fRewardFixation(nFixYes, nFixNo), baseReward - rewardSubtotal]);
		bFixationFeedback = (nFixNo > 0);
		
		res.rewardPost = rewardSubtotal + res.dRewardFixation;
		mwpi.reward = res.rewardPost;
		
		if bFixationFeedback
			strFixationFeedback = ['<color:' strColNo '>' num2str(nFixNo) plural(nFixNo,' cue{,s} missed')];
			if ~mwpi.bPractice && res.dRewardFixation ~= 0
				strFixationFeedback = [strFixationFeedback ' (' StringMoney(res.dRewardFixation,'sign',true) ')'];
			end
			strFixationFeedback = [strFixationFeedback '</color>\n'];
		else
			strFixationFeedback = '';
		end
		
		% construct complete feedback string
		
		if opt.bProgress
			strProgressFeedback = ['Trials completed: ' num2str(kBlock) '/' num2str(mwpi.nBlock)];
		else
			strProgressFeedback = '';
		end
		
		if mwpi.bPractice
			strFeedback = ['<color:' strColor '>' strCorrect '</color>\n' ...
				strFixationFeedback strProgressFeedback];
		else
			strFeedback = ['<color:' strColor '>' strCorrect ' (' ...
				StringMoney(res.dRewardTest,'sign',true) ')</color>\n' strFixationFeedback ...
				'Current total: ' StringMoney(mwpi.reward) '\n' strProgressFeedback];
		end
		
		% show feedback in an empty area of the screen
		posMatch = sParam.posMatch;
		
		vertOffset = MWPI.Param('text','vertOffset');
		horzOffset = MWPI.Param('text','horzOffset');
		
		posFeedback = switch2(posMatch, ...
			1,	[0, vertOffset],  ...
			2,	[-.95*horzOffset, 0], ...
			3,	[0, -vertOffset], ...
			4,	[.95*horzOffset, 0]   ...
			);
		
		szFeedback = MWPI.Param('text', 'szFeedback');
        if mwpi.bPractice
            szFeedback = szFeedback/.7;
        end
        
		exp.Show.Text(['<size:' num2str(szFeedback) '>' strFeedback '</size>'], ...
			posFeedback, 'window', winFeedback);
		
		exp.Show.Texture(winFeedback);
		exp.Window.Flip;		
		
		% add a log message
		mwpi.nCorrect    = mwpi.nCorrect + res.bCorrect;
		charCorrect  = conditional(res.bCorrect,'y','n');
		strTally    = [num2str(mwpi.nCorrect) '/' num2str(kBlock)];
		
		exp.AddLog(['feedback (' charCorrect ', ' strTally ')']);
	end
%=====================================================================%

	function [bAbort, bCorrect, kResponse, tResponse] = WaitTest(kCorrect, strResponse, tNow,~)
		% In:
		%	kCorrect	= matrix of correct key(s)
		%	strResponse = string representing key set that is considered a response
		
		bAbort = false;
        
		persistent bResponse; % whether a response has been recorded
		
        % flush serial port once (and reset bResponse)
		if bReset
			if ~mwpi.bPractice
				exp.Input.State;
			end
			bResponse = false;
            bReset = false;
		end
		
		kResponse = [];
		tResponse = [];
		bCorrect = [];
		
		% check for a response
		if ~bResponse
			[bRespNow,~,~,kButton] = exp.Input.DownOnce(strResponse);

			if bRespNow
				kResponse = kButton;
				tResponse = tNow;
				bCorrect = all(ismember(kButton, kCorrect));
				bResponse = true;				
			end
		end
		
		exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_CRITICAL);
	end
end