function Instructions(mwpi)
% mwpi.Instructions: show instructions sequence
%
% Syntax: mwpi.Instructions;
%
% Updated: 2015-11-20

% text-only explanation

exp = mwpi.Experiment;

szHeader = num2str(MWPI.Param('text', 'szHeader'));

strPrompt = ['<size:' szHeader '>Instructions:\n</size>' ...
	'At the start of a trial, you will see two images on the screen. Next, ' ...
	'they will disappear and an arrow will appear. You must remember the image ' ...
	'that has just disappeared from the location indicated by the arrow.'];
exp.Show.Instructions(strPrompt);

secRetention = num2str(MWPI.Param('exp','block','retention','time')*MWPI.Param('trTime'));
strRetention = ['<size:' szHeader '>Instructions (cont.):\n</size>' ...
	'Next, you will see a third image in the center of the screen. For the next ' ...
	secRetention ' seconds, it will periodically grow or shrink momentarily. Each time this happens, quickly press <color:green>A</color> if it shrank ' ...
	'or <color:yellow>Y</color> if it grew.'];
exp.Show.Instructions(strRetention);

secTest = num2str(MWPI.Param('exp','block','test','tTest')*MWPI.Param('trTime'));
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
	'level of your monetary reward, which adjusts according to your performance.'];
exp.Show.Instructions(strFeedback);

colHint = MWPI.Param('text', 'colHint');
colHintRGBA = exp.Color.Get(colHint);
strExample = ['Next, you will do an example trial. The hints in ' ...
	'<color:' colHint '>light gray</color> are there to guide you and will not ' ...
	'appear after this trial.'];
exp.Show.Instructions(strExample);

%--- example run ----%

exp.Scanner.StartScan;

% create dummy parameter struct
sParam.lClass   = 1;
sParam.rClass   = 3;
sParam.wClass   = 3;
sParam.dClass   = 1;
sParam.cue	    = 2;
sParam.vClass   = 2;
sParam.posMatch = 2;

kRun = 1;
kBlock = 1;
d = 0.05;
arrAbility = [0.05; 0.05; 0.05; 0.05];

seedCuedFig = mwpi.PrepTextures(sParam, kRun, kBlock, d, arrAbility);
hintSzVA = MWPI.Param('stim','size');
hintSzPX = round(exp.Window.va2px(hintSzVA));
hintFig = MWPI.Stimulus(sParam.wClass, seedCuedFig, d, hintSzPX, ...
	'base_color', colHintRGBA(1:3));
hintFig = hintFig.base;

hintOffset = MWPI.Param('stim', 'offset');

hintFigTexture = {'arrow', 'retention', 'retentionLg', 'retentionSm'};

for kT = 1:numel(hintFigTexture)
	exp.Show.Text(['<color:' colHint '>Remember</color>'], ...
		[0,1.5*hintOffset - 0.6 * hintSzVA], 'window', hintFigTexture{kT});
	exp.Show.Image(hintFig, [0,1.5*hintOffset], 'window', hintFigTexture{kT}, ...
		'border', true, 'border_color', colHint);
end

% button hints
exp.Show.Text(['<color:' colHint '>Y</color>'], [0,-hintOffset], 'window', 'retentionLg');
exp.Show.Text(['<color:' colHint '>A</color>'], [0, hintOffset], 'window', 'retentionSm');
exp.Show.Text(['<color:' colHint '>B</color>'], [2*hintOffset,0], 'window', 'test');

mwpi.Block(1,1, 'sParam', sParam);

exp.Scanner.StopScan;

% pause
tPause = 1000 * MWPI.Param('trTime') + MWPI.Param('exp','block','feedback','time');
tNow = PTB.Now;
while PTB.Now < tNow + tPause
	exp.Scheduler.Wait(PTB.Scheduler.PRIORITY_HIGH);
end

exp.Show.Instructions('Any questions? Ask before starting!', 'blank', true, 'next', 'start');

end