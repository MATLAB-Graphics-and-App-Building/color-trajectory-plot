classdef colorTrajectoryPlot < matlab.graphics.chartcontainer.ChartContainer & ...
        matlab.graphics.chartcontainer.mixin.Colorbar
    %colorTrajectoryPlot Create a multi-color trajectory plot
    %   colorTrajectoryPlot(x,y) create a multi-color line plot following
    %   the 2D path specified by the coordinates x and y using the index of
    %   each coordinate to determine the color of the line. x and y must be
    %   numeric vectors of equal length.
    %
    %   colorTrajectoryPlot(x,y,c) create a multi-color line plot following
    %   the 2D path specified by the coordinates x and y using values from
    %   c to determine the color of the line at each coordinate. x, y, and
    %   c must be numeric vectors of equal length.
    %
    %   colorTrajectoryPlot() create a multi-color line plot using only
    %   name-value pairs.
    %
    %   colorTrajectoryPlot(___,Name,Value) specifies additional options
    %   for the multi-color line plot using one or more name-value pair
    %   arguments. Specify the options after all other input arguments.
    %
    %   colorTrajectoryPlot(parent,___) creates the multi-color line plot
    %   in the specified parent.
    %
    %   h = colorTrajectoryPlot(___) returns the colorTrajectoryPlot
    %   object. Use h to modify properties of the plot after creating it.
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    properties
        % x-coordinates of the trajectory.
        XData (:,1) double = []
        
        % y-coordintaes of the trajectory.
        YData (:,1) double = []
        
        % Data used to determine the color of the line.
        ColorData (:,1) double = []
        
        % Title of the plot.
        TitleText (:,1) string = ""
        
        % Subtitle of the plot.
        SubtitleText (:,1) string = ""
        
        % Line width of the trajectory.
        LineWidth (1,1) {mustBeNumeric, mustBePositive} = 0.5
        
        % Label on the colorbar.
        ColorbarLabel (:,1) string = ""
    end
    
    properties (Dependent)
        % Colormap Colormap used to convert `ColorData` into colors.
        Colormap (:,3) double {mustBeNonempty, mustBeInRange(Colormap,0,1)} = get(groot, 'factoryFigureColormap')
        
        % Limits used to convert `ColorData` into colors.
        ColorLimits (1,2) double {mustBeLimits} = [0 1]
        
        % Mode for the color limits.
        ColorLimitsMode (1,:) char {mustBeAutoManual} = 'auto'
    end
    
    properties (Access = protected)
        SaveAxesState struct = []
    end
    
    properties (Access = private, Transient, NonCopyable)
        TrajectoryLine (:,1) matlab.graphics.primitive.Patch
    end
    
    methods
        function obj = colorTrajectoryPlot(varargin)
            %
            
            % Initialize list of arguments
            args = varargin;
            leadingArgs = cell(0);
            
            % Check if the first input argument is a graphics object to use as parent.
            if ~isempty(args) && isa(args{1},'matlab.graphics.Graphics')
                % colorTrajectoryPlot(parent, ___)
                leadingArgs = args(1);
                args = args(2:end);
            end
            
            % Check for optional positional arguments.
            if ~isempty(args) && isnumeric(args{1})
                if numel(args) >= 2 && mod(numel(args), 2) == 0 ...
                        && isnumeric(args{2})
                    % colorTrajectoryPlot(x, y, Name, Value)
                    x = args{1};
                    y = args{2};
                    
                    % Verify x and y are the same length.
                    assert(numel(x) == numel(y), ...
                        'colorTrajectoryPlot:DataLengthMismatch',...
                        'y must be the same length as x.');
                    
                    % Add x and y to the input arguments.
                    leadingArgs = [leadingArgs {'XData', x, 'YData', y}];
                    args = args(3:end);
                elseif numel(args) >= 3 && mod(numel(args), 2) == 1 ...
                        && isnumeric(args{2}) && isnumeric(args{3})
                    % colorTrajectoryPlot(x, y, c, Name, Value)
                    x = args{1};
                    y = args{2};
                    c = args{3};
                    
                    % Verify x and y are the same length.
                    assert(numel(x) == numel(y), ...
                        'colorTrajectoryPlot:DataLengthMismatch',...
                        'y must be the same length as x.');
                    
                    % Verify x and c are the same length.
                    assert(numel(c) == numel(y), ...
                        'colorTrajectoryPlot:DataLengthMismatch',...
                        'c must be the same length as x.');
                    
                    % Add x, y, and c to the input arguments.
                    leadingArgs = [leadingArgs {'XData', x, 'YData', y, 'ColorData', c}];
                    args = args(4:end);
                else
                    error('colorTrajectoryPlot:InvalidSyntax', 'Specify both x and y coordinates.');
                end
            end
            
            % Combine positional arguments with name/value pairs.
            args = [leadingArgs args];
            
            % Call superclass constructor method
            obj@matlab.graphics.chartcontainer.ChartContainer(args{:});
            
            % Supress output unless it is requested.
            if nargout == 0
                clear obj
            end
        end
    end
    
    methods (Access = protected)
        function setup(obj)
            % Configure the axes.
            ax = obj.getAxes();
            ax.NextPlot = 'replacechildren';
            ax.DataAspectRatio = [1 1 1];
            ax.Box = 'on';
            ax.XTick = [];
            ax.YTick = [];
            axis(ax,'tight')
            
            % Create a patch to show the trajectory.
            obj.TrajectoryLine = patch(ax, 'Faces',[], 'Vertices', [], ...
                'FaceColor', 'none', 'EdgeColor', 'interp');
            
            % Restore any saved axes state.
            loadAxesState(obj)
        end
        
        function update(obj)
            % Verify that the data properties are consistent with one
            % another.
            showChart = verifyDataProperties(obj);
            obj.TrajectoryLine.Visible = showChart;
            
            % Abort early if not visible due to invalid data.
            if ~showChart
                return
            end
            
            % Update the vertices and faces on the patch.
            obj.TrajectoryLine.Vertices = [obj.XData obj.YData; NaN NaN];
            obj.TrajectoryLine.Faces = 1:numel(obj.XData)+1;
            
            % Update the color of the patch.
            colorData = obj.ColorData;
            if isempty(colorData)
                colorData = (1:numel(obj.XData))';
            end
            obj.TrajectoryLine.FaceVertexCData = [colorData; NaN];
            
            % Update the patch line width.
            obj.TrajectoryLine.LineWidth = obj.LineWidth;
            
            % Update the title/subtitle and colorbar label.
            title(getAxes(obj), obj.TitleText, obj.SubtitleText);
            if obj.ColorbarVisible
                ylabel(getColorbar(obj), obj.ColorbarLabel);
            end
        end
        
        function showChart = verifyDataProperties(obj)
            % XData and YData must be the same length.
            n = numel(obj.XData);
            showChart = numel(obj.YData) == n;
            if ~showChart
                warning('colorTrajectoryPlot:DataLengthMismatch',...
                    'YData must be the same length as XData.');
                return
            end
            
            % ColorData and must be empty or the same length as XData.
            showChart = isempty(obj.ColorData) || numel(obj.ColorData) == n;
            if ~showChart
                warning('colorTrajectoryPlot:DataLengthMismatch',...
                    'ColorData must be empty or the same length as XData.');
                return
            end
        end
        
        function loadAxesState(obj)
            state = obj.SaveAxesState;
            
            if isfield(state, 'Colormap')
                obj.Colormap = state.Colormap;
            end
            
            if isfield(state, 'ColorLimits')
                obj.ColorLimits = state.ColorLimits;
            end
            
            if isfield(state, 'ColorbarVisible') && state.ColorbarVisible
                obj.ColorbarVisible = state.ColorbarVisible;
            end
            
            % Reset the SaveAxesState for the next save.
            obj.SaveAxesState = [];
        end
        
        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                % List for array of objects
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                % List for scalar object
                propList = cell(1,0);
                
                % Add the title, if not empty or missing.
                nonEmptyTitle = obj.TitleText ~= "" & ~ismissing(obj.TitleText);
                if any(nonEmptyTitle)
                    propList = {'TitleText'};
                end
                
                % Add the subtitle, if not empty or missing.
                nonEmptySubtitle = obj.SubtitleText ~= "" & ~ismissing(obj.SubtitleText);
                if any(nonEmptySubtitle)
                    propList{end+1} = 'SubtitleText';
                end
                
                % Add either ColorData or XData and YData.
                if isempty(obj.ColorData)
                    propList(end+1:end+2) = {'XData','YData'};
                else
                    propList(end+1:end+3) = {'ColorData','ColorLimits','ColorbarLabel'};
                end
                
                groups = matlab.mixin.util.PropertyGroup(propList);
            end
        end
    end
    
    methods
        function title(obj, varargin)
            [t, st] = title(getAxes(obj), varargin{:});
            obj.TitleText = t.String;
            obj.SubtitleText = st.String;
        end
        
        function subtitle(obj, varargin)
            ax = getAxes(obj);
            st = subtitle(ax, varargin{:});
            obj.SubtitleText = st.String;
        end
    end
    
    methods
        function set.Colormap(obj, map)
            ax = getAxes(obj);
            ax.Colormap = map;
        end
        
        function map = get.Colormap(obj)
            ax = getAxes(obj);
            map = ax.Colormap;
        end
        
        function set.ColorLimits(obj, limits)
            ax = getAxes(obj);
            ax.CLim = limits;
        end
        
        function limits = get.ColorLimits(obj)
            ax = getAxes(obj);
            limits = ax.CLim;
        end
        
        function set.ColorLimitsMode(obj, mode)
            ax = getAxes(obj);
            ax.CLimMode = mode;
        end
        
        function mode = get.ColorLimitsMode(obj)
            ax = getAxes(obj);
            mode = ax.CLimMode;
        end
        
        function state = get.SaveAxesState(obj)
            state = obj.SaveAxesState;
            
            if isempty(state)
                % Create a 1x1 struct.
                state = struct();
                
                % Add fields to the struct for each axes property to store.
                ax = getAxes(obj);
                if ax.ColormapMode == "manual"
                    state.Colormap = obj.Colormap;
                end
                
                if obj.ColorLimitsMode == "manual"
                    state.ColorLimits = obj.ColorLimits;
                end
                
                state.ColorbarVisible = obj.ColorbarVisible;
            end
        end
    end
end

function mustBeLimits(limits)

if numel(limits) ~= 2 || limits(2) <= limits(1)
    throwAsCaller(MException('colorTrajectoryPlot:InvalidLimits', 'Specify limits as two increasing values.'))
end

end

function mustBeAutoManual(mode)

mustBeMember(mode, {'auto','manual'})

end
