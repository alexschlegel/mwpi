function Instructions(mwpi)
% mwpi.Instructions: show instructions sequence
%
% Syntax: mwpi.Instructions;
%
% Updated: 2015-11-20

ListenChar(2);

% text-only explanation

exp = mwpi.Experiment;

szHeader = num2str(MWPI.Param('text', 'szHeader'));
strNumTrials = num2str(MWPI.Param('practice', 'nBlock'));
% estimate the time for the run, by using the length of a trial plus some
% extra estimated rest time, and rounding up to the nearest 10 minutes
strTimeEstimate = num2str(round((MWPI.Param('practice','block','time') + 1500) ...
	* MWPI.Param('practice','nBlock') / (1000 * 60) + 5, -1));

strIntro = ['<size:' szHeader '>Instructions:\n</size>' ...
	'Your goal in this session is to train yourself on a simple memory task.\n' ...
	'You will do a total of ' strNumTrials ' trials, each of which ' ...
	'has the same format.\nYou may proceed at your own pace, and the session ' ...
	'should take around ' strTimeEstimate ' minutes to complete.'];
exp.Show.Instructions(strIntro);

strPrompt = ['<size:' szHeader '>Instructions (cont.):\n</size>' ...
	'Each trial starts with four images on the screen, two of which are highlighted with square frames. ' ...
	'Next, the images and one of the frames will disappear. You must remember the image ' ...
	'that has just disappeared from the inside of the remaining frame.'];
exp.Show.Instructions(strPrompt);

secRetention = num2str(MWPI.Param('practice','block','retention','time') / 1000);
strRetention = ['<size:' szHeader '>Instructions (cont.):\n</size>' ...
	'After the frame disappears, you will see a third image in the center of the screen. For the next ' ...
	secRetention ' seconds, it will periodically grow or shrink momentarily. '...
	'Each time this happens, quickly press <color:yellow>Y</color> if it grew ' ...
	'or <color:green>A</color> if it shrank.'];
exp.Show.Instructions(strRetention);

secTest = num2str(MWPI.Param('practice','block','test','tTest') / 1000);
strTest = ['<size:' szHeader '>Instructions (cont.):\n</size>' ...
	'Finally, you will be tested on your memory of the image you remembered ' ...
	'at the beginning. You will see four shapes, at the top, bottom, left and right '...
	'of the screen. You will have ' secTest ' seconds to indicate the location of the image ' ...
	'you remembered with the <color:yellow>Y</color>, <color:green>A</color>, ' ...
	'<color:blue>X</color>, or <color:red>B</color> key.'];
exp.Show.Instructions(strTest);

strFeedback = ['<size:' szHeader '>Instructions (cont.):\n</size>' ...
	'After the test, you will see the correct answer and feedback on your performance. ' ...
	'When you do the real experiment in the scanner, you will also see the current ' ...
	'level of your monetary reward, which adjusts according to your performance. ' ...
	'On each trial in the scanner, you will win ' StringMoney(100*MWPI.Param('reward','rewardPerBlock'), 'type', 'cent') ...
	' for a correct test answer or lose ' StringMoney(100*MWPI.Param('reward','penaltyPerBlock'), 'type', 'cent') ...
	' for an incorrect answer. You will also lose ' StringMoney(100*MWPI.Param('reward', 'fixationPenalty'), 'type', 'cent') ...
	' for each grow/shrink cue you miss.'];
exp.Show.Instructions(strFeedback);

colHint = MWPI.Param('text', 'colHint');
colHintRGBA = exp.Color.Get(colHint);
strExample = ['Next, you will do an example trial.\n The hints in ' ...
	'<color:' colHint '>' colHint '</color> are there to guide you and will not ' ...
	'appear after this trial.'];
exp.Show.Instructions(strExample);

%--- example run ----%

% create dummy parameter struct
sParam.promptClass = reshape([2 3 4 1], 1, 1, []);
sParam.cClass    = 3;
sParam.ucClass   = 1;
sParam.posCued   = 2;
sParam.posUncued = 4;
sParam.vClass    = 2;
sParam.posMatch  = 2;

kRun = 1;
kBlock = 1;
d = 0.05;
arrAbility = [0.05; 0.05; 0.05; 0.05];

seedCuedFig = mwpi.PrepTextures(sParam, kRun, kBlock, d, arrAbility);
hintSzVA = MWPI.Param('stim','size');
hintSzPX = round(exp.Window.va2px(hintSzVA));
hintFig = MWPI.Stimulus(sParam.cClass, seedCuedFig, d, hintSzPX, ...
	'base_color', colHintRGBA(1:3));
hintFig = hintFig.base;

hintOffset = MWPI.Param('stim', 'offset');

hintFigTexture = {'frame', 'retention', 'retentionLg', 'retentionSm', 'test'};

for kT = 1:numel(hintFigTexture)
	exp.Show.Text(['<color:' colHint '>Remember</color>'], ...
		[1.5*hintOffset,1.5*hintOffset - 0.6 * hintSzVA], 'window', hintFigTexture{kT});
	exp.Show.Image(hintFig, [1.5*hintOffset,1.5*hintOffset], 'window', hintFigTexture{kT}, ...
		'border', true, 'border_color', colHint);
end

% button hints
exp.Show.Text(['<color:' colHint '><size:1.5>Y</size></color>'], [0,-hintOffset], 'window', 'retentionLg');
exp.Show.Text(['<color:' colHint '><size:1.5>A</size></color>'], [0, hintOffset], 'window', 'retentionSm');
exp.Show.Text(['<color:' colHint '><size:1.5>B</size></color>'], [2*hintOffset,0], 'window', 'test');

% run!
exp.Scheduler.Pause;
mwpi.nCorrect = 0;
mwpi.Block(1,1, 'sParam', sParam);
exp.Scheduler.Resume;

% pause
tPause = MWPI.Param('trTime') * MWPI.Param('exp','block','feedback','time');
tNow = PTB.Now;
while PTB.Now < tNow + tPause
	exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_HIGH);
end

exp.Show.Instructions('Any questions? Ask before starting!', 'blank', true, 'next', 'start');

end