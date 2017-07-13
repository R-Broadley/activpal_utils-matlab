function Data = load_datx(filePath, varargin)
%LOAD_DATX Opens the raw data files from activpal devices
%   SYNTAX:
%       Data = load_datx(filePath)
%       Data = load_datx(filePath, 'Name', 'Value')
%
%   DESCRIPTION:
%       Data = load_datx(filePath) - loads data from binary activpal data files.
%
%       Data = load_datx(filePath, 'Name', 'Value') - modifies the output using
%                   Name, Value pair arguments.
%           Named arguments:
%               'units' - Specify the units for accelerometer data.
%                         Accepted values are: 'g' (default), 'ms-2', 'raw'
%
%   OUTPUT:
%       A structure with two fields:
%           signals - a table with 4 columns (dateTime, x, y, z)
%           meta - a structure containing the metadata
%       The fields of the meta structure are:
%           bitdepth - 8bits or 10bits
%           resolution - ±2g, ±4g or ±8g (g = 9.81 ms-2)
%           hz - the sample frequency
%           axes - the number of axes recorded
%           startTime - the start time of the recording
%           stopTime - the stop time of the recording
%           duration - the length of the recording (Matlab duration type)
%           stopCondition - Trigger, Immediately, Set Time
%           startCondition - Memory Full, Low Battery, USB, Programmed Time
%
%   EXAMPLE:
%       [fileName, fileDir] = uigetfile( ...
%           {'*.datx; *.dat', 'activPAL Files (*.dat, *.datx)'}, ...
%           'Select an activPAL data file' );
%       filePath = fullfile(fileDir, fileName);
%       Data = activpal_utils.load_datx(filePath);
%
%   For more information, see <a href="matlab:web(...
%   'https://github.com/R-Broadley/activpal_utils-matlab/wiki/Documentation'...
%   )">activpal_utils wiki</a>
%
%   Requires Matlab version 8.2 (2013b) or later.
%
%   Copyright: R Broadley 2017
%
%   License: GNU General Public License version 2.
%            A copy of the General Public License version 2 should be included
%            with this code. If not, see <a href="matlab:web(...
%            'https://www.gnu.org/licenses/gpl-2.0.html'...
%            )"> GNU General Public License version 2</a>.


    % Check matlab version supported
    if verLessThan('matlab', '8.2')
        msgID = 'MATLAB:VersionError';
        msgText = 'Matlab version is too old to support load_datx';
        ME = MException(msgID, msgText);
        throw(ME);
    end

    % Imports
    import activpal_utils.helper_functions.get_file_ext
    import activpal_utils.validation.check_file

    % Defaults
    defaultUnits = 'g';

    % Input validation functions
    checkFilePath = @(x) check_file(x, 'validExt', {'.datx', '.dat'});
    checkUnits = @(x) ischar(x) && any(strcmp(x, {'g', 'ms-2', 'raw'}));

    % Parse inputs
    p = inputParser;
    addRequired(p, 'filePath', checkFilePath);
    addParameter(p, 'units', defaultUnits, checkUnits);
    parse(p, filePath, varargin{:});

    % Get inputs
    filePath = p.Results.filePath;
    units = p.Results.units;

    % Get file extension
    fileExt = get_file_ext(filePath);

    % Determine length of header
    headerEndMap = containers.Map({'.datx', '.dat'}, {1024, 1023});
    headerEnd = headerEndMap(fileExt);

    % Open file
    f = fopen(filePath, 'r');
    fileContents = uint8(transpose(fread(f)));
    fclose(f);

    % Identify firmware
    firmware = uint64(fileContents(40)) * 255 + uint64(fileContents(18));
    % Identify if file uses compression
    compression = fileContents(37);  % True(1) / False(0)

    % Extract Metadata
    Data.meta = extract_metadata(fileContents(1:headerEnd));
    % Locate Tail
    tailStart = locate_tail(fileContents, headerEnd, fileExt);
    % Extract accelerometer data
    fbodyInd = headerEnd + 1 : tailStart - 1;
    signals = extract_accdata( fileContents(fbodyInd), firmware, ...
                               compression );

    % Check number of data points
    signals = check_length(signals, Data.meta, filePath);

    % Remove invalid rows
    signals = clean(signals, 254);
    signals = clean(signals, 255);

    if ~strcmp(units, 'raw')
        % Convert binary values to g
        signals = (double(signals) - 127) / 63;
    end
    if strcmp(units, 'ms-2')
        % Convert from g to ms-2
        signals = signals * 9.81;
    end

    % Generate time stamps
    nsec = (1 : length(signals)) * (1 / double(Data.meta.hz));
    timeStamps = (Data.meta.startTime + seconds(nsec))';

    Data.signals = table( timeStamps, ...
                          signals(:,1), signals(:,2), signals(:,3), ...
                          'VariableNames', {'dateTime', 'x', 'y', 'z'} );

    Data.signals.Properties.VariableUnits = [ {'datetime'}, ...
                                              repmat({units}, 1, 3) ];
end


function tailStart = locate_tail(fileContents, headerEnd, fileExt)
    if strcmp(fileExt, '.datx')
        tailStart = strfind(fileContents, [116 97 105 108]);
        tailStart = tailStart(end);
    elseif strcmp(fileExt, '.dat')
        tailStart = find( (fileContents(headerEnd : end - 7)== 0) & ...
                          (fileContents(headerEnd + 1 : end - 6) == 0) & ...
                          (fileContents(headerEnd + 2 : end - 5) >= 1) & ...
                          (fileContents(headerEnd + 3 : end - 4) == 0) & ...
                          (fileContents(headerEnd + 4 : end - 3) == 0) & ...
                          (fileContents(headerEnd + 5 : end - 2) >= 1) & ...
                          (fileContents(headerEnd + 6 : end - 1) >= 1) & ...
                          (fileContents(headerEnd + 7 : end) == 0), 1 );
        tailStart = tailStart + headerEnd;
    end
end


function Metadata = extract_metadata(header)
    if header(39) < 128
        Metadata.bitdepth = 8;
        resolutionByte = header(39);
    else
        Metadata.bitdepth = 10;
        resolutionByte = header(39) - 128;
    end

    resolutionMap = containers.Map({0, 1, 2}, {2, 4, 8});
    Metadata.resolution = resolutionMap(resolutionByte);

    Metadata.hz = header(36);

    axesMap = containers.Map({0, 1}, {3, 1});
    Metadata.axes = axesMap(header(281));

    Metadata.startTime = datetime( uint64(header(262)) + 2000, header(261), ...
                                   header(260), header(257), header(258), ...
                                   header(259) );

    Metadata.stopTime = datetime( uint64(header(268)) + 2000, header(267), ...
                                  header(266), header(263), header(264), ...
                                  header(265) );

    Metadata.duration = Metadata.stopTime - Metadata.startTime;

    startConditionMap = containers.Map( {0, 1, 2}, ...
                                        {'Trigger', 'Immediately', 'Set Time'} );
    Metadata.startCondition = startConditionMap(header(269));

    stopConditionMap = containers.Map( {0, 3, 64, 128}, ...
                                       {'Memory Full', 'Low Battery', 'USB', ...
                                        'Programmed Time'} );
    Metadata.stopCondition = stopConditionMap(header(276));
end


function accelerometerData = extract_accdata(fbody, firmware, compression, naxes)
    if naxes ~= 3
        msgID = 'load_datx:fileError';
        msgText = ['Reading data from uniaxial recordings has not been ' ...
                   'implemented yet.\n' ...
                   'Please report this to the developers at:\n' ...
                   'https://github.com/R-Broadley/activpal_utils-matlab/issues'
                   '\n Affected file: \n %s'];
        ME = MException(msgID, msgText, filePath);
        throw(ME);
    end

    % Check length of data is divisible by naxes
    remainder = rem(length(fbody), naxes);
    if remainder ~= 0
        fbody = fbody(1 : end - remainder);
        warning( strcat('Length of data_stream is not divisible ', ...
                        ' by the number of axes in ',...
                        ' [',obj.file_path,']. Either the file ',...
                        ' tail has not have been completed removed ',...
                        ' or some accelerometer data has been removed.') );
    end

    % Reshape fbody to n by naxes
    fbody = reshape(fbody, naxes, [])';

    % Decompress
    if compression && firmware > 217
        accelerometerData = decompress(fbody);
    elseif compression
        accelerometerData = old_decompress(fbody);
    end
end


function decompressedData = decompress(inputData)
    import activpal_utils.helper_functions.repeat_row

    compressedLoc = find(inputData(:, 1) == 0 & inputData(:, 2) == 0);
    compressionN = double(inputData(compressedLoc, 3));

    rowMultiplier = ones(length(inputData), 1);
    rowMultiplier(compressedLoc - 1) = compressionN + 1;
    rowMultiplier(compressedLoc) = 0;

    decompressedData = repeat_row(inputData, rowMultiplier);
end


function decompressedData = old_decompress(inputData)
    import activpal_utils.helper_functions.repeat_row

    compressedLoc = find(inputData(:, 1) == 0 & inputData(:, 2) == 0);
    compressionN = double(inputData(compressedLoc, 3)) + 1;

    starts = diff([0; compressedLoc]);
    starts(starts == 1 ) = 0;
    starts(starts > 0) = 1;
    edges = diff([starts; 1]);
    startInd = find(edges < 0);
    endInd = find(edges > 0);
    for i = 1:length(startInd)
        compressionN(startInd(i)) = sum(compressionN(startInd(i) : endInd(i)));
    end

    rowMultiplier = ones(length(inputData), 1);
    rowMultiplier(compressedLoc - 1) = compressionN + 1;
    rowMultiplier(compressedLoc) = 0;

    decompressedData = repeat_row(inputData, rowMultiplier);
end


function signals = check_length(signals, meta, filePath)
    nsamples = length(signals);
    nexpected = seconds(meta.duration) * double(meta.hz);
    diffSamples = nsamples - nexpected;
    threshold = 5 * 60 * double(meta.hz);  % 5 minutes
    if diffSamples < threshold  && diffSamples > 0  % diff < 5 minutes && +
        % Shorten signals to length specified in duration
        signals = signals(1 : nexpected, :);
    elseif diffSamples > -threshold  && diffSamples < 0  % diff < 5 minutes && -
        % Keep signals as is but give warning
        msgText = ['There are fewer data points than expected in file:\n' ...
                   '%s \n' ...
                   'Please check the signals data and meta.Duration ' ...
                   'and report this to the developers at:\n' ...
                   'https://github.com/R-Broadley/activpal_utils-matlab/issues'];
        warning(msgText, filePath);
    else
        % Raise error due to large discrepancy
        msgID = 'load_datx:fileError';
        msgText = ['There are fewer data points than expected in file:\n' ...
                   '%s \n' ...
                   'Please report this to the developers at:\n' ...
                   'https://github.com/R-Broadley/activpal_utils-matlab/issues'];
        ME = MException(msgID, msgText, filePath);
        throw(ME);
    end
end


function cleanedData = clean(inputData, value)
    [rows2remove, ~] = find(inputData == value);
    cleanedData = inputData;

    % If no rows2remove return (out = in)
    if isempty(rows2remove)
        return;
    end

    rows2remove = unique(rows2remove);
    for i = 1 : length(rows2remove)
        r = rows2remove(i);
        cleanedData(r, :) = cleanedData(r - 1, :);
    end
end
