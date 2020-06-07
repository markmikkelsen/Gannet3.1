function [currentVersion, newVersionAvailable] = VersionCheck(silent, currentVersion)
% Code adopted from Yair Altman's export_fig toolbox
% (https://github.com/altmany/export_fig)

persistent lastCheckTime

if nargin < 2
    loadFile = which('GannetLoad.m');
    fileID = fopen(loadFile, 'rt');
    if fileID == -1
        error('Can''t read %s.', loadFile);
    end
    str = fread(fileID, Inf, '*uchar');
    fclose(fileID);
    str = char(str(:)');
    expression = '(?<field>MRS_struct.version.Gannet = )''(?<version>.*?)''';
    out = regexp(str, expression, 'names');
    currentVersion = out.version;    
    if nargin < 1
        silent = 0;
    end
end

newVersionAvailable = 0;
if nargin < 2 || isempty(lastCheckTime) || etime(clock, lastCheckTime) > 86.4e3
    url = 'https://raw.githubusercontent.com/richardedden/Gannet3.1/master/GannetLoad.m';
    try
        str = readURL(url);
        expression = '(?<field>MRS_struct.version.Gannet = )''(?<version>.*?)''';
        out = regexp(str, expression, 'names');
        latestVersion = out.version;        
        if ~strcmp(latestVersion, currentVersion)
            newVersionAvailable = 1;
            msg = ['\nA newer version of Gannet (%s) is available. ' ...
                   'Your are currently using version %s.\n' ...
                   'You can download the newer version from GitHub or run UpdateGannet to install it directly.\n'];
            msg = hyperlink('https://github.com/richardedden/Gannet3.1', 'GitHub', msg);
            msg = hyperlink('matlab:UpdateGannet', 'UpdateGannet', msg);
            if ~silent
                fprintf(msg, latestVersion, currentVersion);
            end
        end
    catch
        % ignore
    end
    lastCheckTime = clock;
end

    function str = readURL(url)
        try
            str = char(webread(url));
        catch err %if isempty(which('webread'))
            if isempty(strfind(err.message,'404'))
                v = version;   % '9.6.0.1072779 (R2019a)'
                if v(1) >= '8' % '8.0 (R2012b)'
                    str = urlread(url, 'Timeout',5); %#ok<URLRD>
                else
                    str = urlread(url); %#ok<URLRD> % R2012a or older (no timeout parameter)
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



