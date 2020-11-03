%  tinyxml2_mex - XML serializing/deserializing of MATLAB variables
%
%   tinyxml2_mex('save', XMLFILE, VARIABLE)
%   tinyxml2_mex('save', XMLFILE, VARIABLE, OPTIONS)
%       Save Matlab VARIABLE to XMLFILE
%
%   VARIABLE = tinyxml2_mex('load', XMLFILE)
%       Load XMLFILE as a Matlab VARIABLE
%
%   XMLSTRING = tinyxml2_mex('format', VARIABLE)
%   XMLSTRING = tinyxml2_mex('format', VARIABLE, OPTIONS)
%       Convert Matlab VARIABLE into and XMLSTRING
%
%   VARIABLE = tinyxml2_mex('parse', XMLSTRING)
%       Parse XMLSTRING and return it as a Matlab VARIABLE
%
%   tinyxml2_mex('version')
%       return version fo tinyxml2_mex
%
%       OPTIONS is a structure with fields:
%           fp_format_double  - double save format (default: '%lg')
%           fp_format_single  - flat save format  (default: '%g')
%           store_class       - save class of variables as attribute (default: true)
%           store_size        - save size of arrays as attribute (default: true)
%                               when false, array will be saved as a row
%                               vector
%           store_indexes     - save indexes of array as attribute (default: true)
%
% Example:
%   data = rand(5);
%   options.fp_format_double = '%.17le';   % format that preserves all double accuracy
%   options.fp_format_single = '%.7e';     % format that preserves all single accuracy
%   
%   tinyxml('save', 'mydata.xml', dat, options)
%
%  Author:  Ladislav Dobrovsky
%           ladislav.dobrovsky@gmail.com
%
%  Modifications:
%   2015-02-28     Peter van den Biggelaar    Handle structure similar to xml_load from Matlab Central
%   2015-03-05     Ladislav Dobrovsky         Function handles load/save  (str2func, func2str)
%   2015-03-05     Peter van den Biggelaar    Support N-dimension arrays
%   2015-03-07     Peter van den Biggelaar    version 0.9.0: Support N-D Complex doubles and Sparse matrices
%   2015-03-12     Peter van den Biggelaar    version 0.9.1: Fix Inf and NaN reading
%
%  see tinyxml2.h - Original code by Lee Thomason (www.grinninglizard.com)

function varargout = tinyxml2_wrap(varargin)

error('compile with:   mex tinyxml2_wrap.cpp tinyxml2.cpp')




% automatic compilation disabled

% If we reach this code, then no MEX function is available. Build it now.
%tinyxml2_mex_build

% When a mex-file is build on a network drive, it may not immediately be 
% seen by Windows. Update the path to prevent an infinite loop.
%rehash path
  
% now call the MEX function
%[varargout{1:nargout}] = tinyxml2_mex(varargin{:});
