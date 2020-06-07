function UpdateGannet
% Code adopted from Yair Altman's export_fig toolbox
% (https://github.com/altmany/export_fig) and SPM12

% First, check if a new version of Gannet is available; exit otherwise
[currentVersion, newVersionAvailable] = VersionCheck(1);
if ~newVersionAvailable
    fprintf('\nYour version of Gannet (%s) is the latest version.\n\n', currentVersion);
    return
end

% Present a warning to the user
opts.Default = 'No';
opts.Interpreter = 'tex';
answer = questdlg({['\fontsize{12}WARNING: Running UpdateGannet will replace the contents ' ...
    'of the current Gannet folder in the search path.'] ...
    '' ...
    ['{\color{red}Do NOT use this updater if you cloned the Gannet GitHub repository ' ...
    'using git or GitHub Desktop. Pull the latest commits in the usual way instead.}'] ...
    '' ...
    'Do you wish to continue?'}, 'Update Gannet', 'Yes', 'No', opts);
switch answer
    case 'Yes'
        fprintf('\nUpdating Gannet...\n\n');
    case 'No'
        fprintf('\nExiting updater...\n\n');
        return
end

% Remove Gannet directory from the search path
gannetPath = fileparts(which(mfilename('fullpath')));
searchPath = textscan(path, '%s', 'delimiter', pathsep);
searchPath = searchPath{1};
i = strncmp(gannetPath, searchPath, length(gannetPath));
searchPath(i) = [];
searchPath = strcat(searchPath, pathsep);
path(strcat(searchPath{:}));

% Download the latest version of Gannet
zipURL = 'https://github.com/richardedden/Gannet3.1/archive/master.zip';
targetFolder = fullfile(pwd, ['tmp_' randsample(['A':'Z','0':'9'],6)]);
mkdir(targetFolder);
targetFilename = fullfile(targetFolder, datestr(now,'yyyy-mm-dd.zip'));
websave(targetFilename, zipURL);
newFilenames = unzip(targetFilename, targetFolder);

% Delete current Gannet folder and replace with the new one
rmdir(gannetPath,'s');
movefile(newFilenames{1}, gannetPath);
rmdir(targetFolder,'s');

% Add new Gannet directory to search path
addpath(gannetPath);

% Notify the user and rehash
url = 'https://raw.githubusercontent.com/richardedden/Gannet3.1/master/GannetLoad.m';
str = readURL(url);
expression = '(?<field>MRS_struct.version.Gannet = )''(?<version>.*?)''';
out = regexp(str, expression, 'names');
latestVersion = out.version;
fprintf('\nSuccessfully updated Gannet to version %s!\n\n', latestVersion);
rehash;

    function str = readURL(url)
        try
            str = char(webread(url));
        catch err
            if isempty(strfind(err.message,'404'))
                v = version;   % '9.6.0.1072779 (R2019a)'
                if v(1) >= '8' % '8.0 (R2012b)'
                    str = urlread(url, 'Timeout', 5); %#ok<*URLRD>
                else
                    str = urlread(url); % R2012a or older (no timeout parameter)
                end
            else
                rethrow(err);
            end
        end
        if size(str,1) > 1  % ensure a row-wise string
            str = str';
        end
    end

end


