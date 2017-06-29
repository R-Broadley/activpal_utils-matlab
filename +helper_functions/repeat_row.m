function outputData = repeat_row(inputData, n)
%REPEAT_ROW Adds n copies of each row in inputData
%   SYNTAX:
%       outputData = repeat_row(inputData, n)
%
%   DESCRIPTION:
%       outputData = repeat_row(inputData, n)
%           If n is a scalar the output will contain n copies of each row.
%           If n is a vector each row in inputData will appear n(i) times in
%               outputData. The length of n must equal the length of inputData.
%
%   EXAMPLE:
%       inputData = [1 2 3; 4 5 6; 7 8 9];
%       n = [1 0 3];
%       outputData = repeat_row(inputData, n)
%       outputData =
%            1     2     3
%            7     8     9
%            7     8     9
%            7     8     9
%
%   Copyright: R Broadley 2017
%
%   License: GNU General Public License version 2.
%            A copy of the General Public License version 2 should be included
%            with this code. If not, see <a href="matlab:web(...
%            'https://www.gnu.org/licenses/gpl-2.0.html'...
%            )"> GNU General Public License version 2</a>.


    if verLessThan('matlab', '8.5')
        outputData = repeat_row_pre_2015(inputData, n);
    else
        outputData = repelem(inputData, n, 1);
    end
end


function output = repeat_row_pre_2015(input, n)
%repeat_row_pre_2015 Impliments some of the behavior of the repelem function
%introduced in 2015a. It creates a copy of the input array where each row
%in the input is copied a specified number of times.


    if isvector(n) == true && iscolumn(n) == false
        n = transpose(n);
    end

    a = cumsum([1; n]);
    rowInc = accumarray(a, 1);
    cpRow = cumsum(rowInc(1 : end - 1));
    output = input(cpRow, :);
end
