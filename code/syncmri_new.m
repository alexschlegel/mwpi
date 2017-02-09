function syncmri_new(varargin)
% syncmri_new: Synchronize DICOM data from new location on rolando
%
% Syntax: syncmri_new([subjects])
%
% In: [subjects]: (<all with accession codes>) cell of subject codes to sync
%

global study strDirData

if isempty(study) || isempty(strDirData)
	error('A PrepXXX script must be called before running this function.');
end

if nargin == 1
    ifo = PercIm.SubjectInfo('subject',varargin{1});
elseif nargin == 0
    % all mri codes
    ifo = PercIm.SubjectInfo;
else
    error('Wrong number of input arguments');
end

cCodes = ifo.code.fmri_new;
cAccession = ifo.accession;

% get year, month and day from codes
cDate = cellfun(@(code) code(1:2) ,cCodes,'uni',false);
cMonth = cellfun(@(code) sprintf('%02d',month2num(code(3:5))), cCodes, 'uni',false);
cYear = cellfun(@(code) ['20' code(6:7)], cCodes, 'uni', false);

% mount rolando
[strDirRolando, tMount] = MountRolando;

cDirSourceRel = cellfun(@(y,m,d,a) DirAppend(y,m,d,a),...
    cYear, cMonth, cDate, cAccession, 'uni', false);
cDirSource = cellfun(@(dir) DirAppend(strDirRolando, dir), cDirSourceRel, 'uni', false);
strDirRaw = DirAppend(strDirData, 'raw');
cDirDest = cellfun(@(code) DirAppend(strDirRaw, code, 'DICOM'), cCodes, 'uni', false);

strPrompt	= sprintf('Detected the following source and destination directories:\nSource:\n%s\nDestination:\n%s\nContinue?',...
				join(cDirSourceRel,10)	, ...
				join(cDirDest,10)   	  ...
				);
res	= ask(strPrompt,'dialog',false,'choice',{'y','n'});

if ~isequal(res,'y')
	error('aborted.');
end

%sync!
	nDirSource	= numel(cDirSource);
	for kD=1:nDirSource
		SyncDir(cDirSource{kD},cDirDest{kD});
	end
UnmountRolando;
%------------------------------------------------------------------------------%
function [strDirRolando,tMount]	= MountRolando
	status('mounting rolando');
	
	%get a temporary directory
		strDirRolando	= GetTempDir;
	%mount rolando into it
		sshmount(...
			'user'			, 'tse'							, ...
			'host'			, 'rolando.cns.dartmouth.edu'	, ...
			'remote_dir'	, '/inbox/DICOM/'				, ...
			'local_dir'		, strDirRolando					  ...
			);
	
	tMount	= nowms;
end
%------------------------------------------------------------------------------%
function UnmountRolando
	status('unmounting rolando');
	
	%make sure we wait at least five seconds after mounting (i'm getting
	%device busy errors)
	while nowms < tMount + 5000
		WaitSecs(0.1);
	end
	
	sshumount(strDirRolando);
	
	%remove the temporary directory
		rmdir(strDirRolando);
end
%------------------------------------------------------------------------------%

function SyncDir(strSource, strDest)
	strSourceRel	= PathAbs2Rel(strSource,strDirRolando);
    
    status(['creating destination directory: ' strDest]);
    strCommand = sprintf('mkdir -p %s', strDest);
    RunBashScript(strCommand);
	
	status(['syncing dir: ' strSourceRel]);
	
    % strSource should have a trailing slash.
	strCommand	= sprintf('rsync -harvz %s %s', strSource, strDest);
	
	RunBashScript(strCommand);
end
%------------------------------------------------------------------------------%
end