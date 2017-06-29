function ext = get_file_ext(filePath)
%GET_FILE_EXT Returns the extension of the given file path
%   SYNTAX:
%       ext = get_file_ext(filePath)
%
%   Copyright: R Broadley 2017
%
%   License: GNU General Public License version 2.
%            A copy of the General Public License version 2 should be included
%            with this code. If not, see <a href="matlab:web(...
%            'https://www.gnu.org/licenses/gpl-2.0.html'...
%            )"> GNU General Public License version 2</a>.


    [~, ~, ext] = fileparts(filePath);
end
