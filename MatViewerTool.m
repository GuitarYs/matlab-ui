classdef MatViewerTool < matlab.apps.AppBase
    % 实验数据可视化处理工具 - MATLAB版本
    
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        
        % 主分割器区域
        MainGridLayout          matlab.ui.container.GridLayout
        
        % 左侧：数据目录区域 
        DirPanel                matlab.ui.container.Panel
        DirTree                 matlab.ui.container.Tree
        SelectPathBtn           matlab.ui.control.Button
        RefreshBtn              matlab.ui.control.Button
        CurrentPathLabel        matlab.ui.control.Label
        
        % 中间：Excel信息区域
        ExcelPanel              matlab.ui.container.Panel
        ExcelTable              matlab.ui.control.Table
        SubdirListBox           matlab.ui.control.ListBox
        BgInfoTitleLabel        matlab.ui.control.Label
        SubdirTitleLabel        matlab.ui.control.Label
        
        % 右侧：图像显示区域
        ImagePanel              matlab.ui.container.Panel
        ImageAxes               matlab.ui.control.UIAxes
        StatusLabel             matlab.ui.control.Label
        InfoLine1Label          matlab.ui.control.Label  % 新增：第一行信息
        InfoLine2Label          matlab.ui.control.Label  % 新增：第二行信息
        
        % 控制按钮
        ImportBtn               matlab.ui.control.Button
        WaveformBtn             matlab.ui.control.Button
        OriginalBtn             matlab.ui.control.Button
        DbBtn                   matlab.ui.control.Button
        Mesh3DBtn               matlab.ui.control.Button
        DbMesh3DBtn             matlab.ui.control.Button
        SARBtn                  matlab.ui.control.Button
        AutoPlayBtn             matlab.ui.control.Button
        ExportBtn               matlab.ui.control.Button
        
        % 滑动条和帧控制
        FrameSlider             matlab.ui.control.Slider
        PrevBtn                 matlab.ui.control.Button
        NextBtn                 matlab.ui.control.Button
        FrameInfoLabel          matlab.ui.control.Label
        JumpCombo               matlab.ui.control.DropDown
        JumpInput               matlab.ui.control.EditField
        JumpBtn                 matlab.ui.control.Button
        PlayModeCombo           matlab.ui.control.DropDown 
        IntervalSpinner         matlab.ui.control.Spinner 
        FrameStepSpinner        matlab.ui.control.Spinner  
            
        % 字段显示表格
        FieldTable              matlab.ui.control.Table
        
        % 字段勾选区域
        FieldCheckPanel         matlab.ui.container.Panel
        SelectAllBtn            matlab.ui.control.Button
        DeselectAllBtn          matlab.ui.control.Button
        FrameInputField         matlab.ui.control.EditField
        FrameStatusLabel        matlab.ui.control.Label
        FieldCheckboxPanel      matlab.ui.container.Panel
        
        % 数据存储
        MatFiles                cell
        MatData                 cell
        CurrentIndex            double
        AllFields               cell
        FieldCheckboxes         cell
        FrameInfoText           matlab.ui.control.TextArea
        FieldText               matlab.ui.control.TextArea
        
        % 路径配置
        CurrentDataPath         char
        SelectedExperiment      char
        
        % 自动播放
        AutoPlayTimer           timer
        AutoPlayActive          logical
        AutoPlayInterval        double
        
        % 域Excel字段
        DomainFieldList         cell
        FieldDisplayNames       cell        % 从第一级目录Excel读取的字段显示名称
        FieldUnits              cell        % 从字段名中提取的单位（如"(m)"）

        % 预处理相关
        PreprocessingList       cell        % 预处理配置列表
        PreprocessingResults    cell        % 预处理结果缓存 {原始, 预处理1, 2, 3}
        CurrentPrepIndex        double      % 当前选中的预处理索引（1-4，1为原图）
        
        % 预处理控制组件
        ShowOriginalCheck       matlab.ui.control.CheckBox  % 保留原图复选框
        ShowPrep1Btn            matlab.ui.control.Button    % CFAR检测按钮
        ShowPrep2Btn            matlab.ui.control.Button    % 非相参积累按钮
        ShowCoherentBtn         matlab.ui.control.Button    % 非相参识别按钮
        ShowDetectionBtn        matlab.ui.control.Button    % 多维识别按钮
        DynamicPrepPanel        matlab.ui.container.Panel   % 动态预处理面板
        PrepTagPanel            matlab.ui.container.Panel   % 预处理标签面板
        AddPrepBtn              matlab.ui.control.Button
        ClearPrepBtn            matlab.ui.control.Button
        ShowPrep3Btn            matlab.ui.control.Button    % 预处理3按钮
        
        % 多视图显示
        ImageAxes1              matlab.ui.control.UIAxes
        ImageAxes2              matlab.ui.control.UIAxes
        ImageAxes3              matlab.ui.control.UIAxes
        ImageAxes4              matlab.ui.control.UIAxes
        CloseBtn2               matlab.ui.control.Button  % 添加
        CloseBtn3               matlab.ui.control.Button  % 添加
        CloseBtn4               matlab.ui.control.Button  % 添加
        MultiViewPanel          matlab.ui.container.Panel        
    end
    
    methods (Access = public)
        
        function app = MatViewerTool
            % 构造函数 - 创建和配置组件
            
            % 初始化属性
            app.MatFiles = {};
            app.MatData = {};
            app.CurrentIndex = 1;
            app.AllFields = {};
            app.FieldCheckboxes = {};
            app.CurrentDataPath = '';  % 默认路径
            app.SelectedExperiment = '';
            app.AutoPlayActive = false;
            app.AutoPlayInterval = 5;  % 5秒
            app.DomainFieldList = {};
            app.FieldDisplayNames = {};
            app.FieldUnits = {};

            app.PreprocessingList = {};
            app.PreprocessingResults = {};
            app.CurrentPrepIndex = 1;  % 默认显示原图
            
            % 创建 UIFigure 和组件
            createComponents(app);
            
            % 注册 app
            registerApp(app, app.UIFigure);
            
            if nargout == 0
                clear app
            end
        end
        
        function delete(app)
            % 删除 app 时的清理
            if ~isempty(app.AutoPlayTimer) && isvalid(app.AutoPlayTimer)
                stop(app.AutoPlayTimer);
                delete(app.AutoPlayTimer);
            end
            delete(app.UIFigure);
        end
    end
    
    methods (Access = private)
        
        function createComponents(app)
            % 创建 UIFigure 和所有组件
            
            % 创建主窗口
            app.UIFigure = uifigure('Visible', 'off');
            % 获取屏幕大小并设置默认窗口大小（还原时的大小）
            screenSize = get(0, 'ScreenSize');
            app.UIFigure.Position = [100 100 screenSize(3)*0.8 screenSize(4)*0.8];
            app.UIFigure.Name = '实验数据可视化处理工具';
            app.UIFigure.Icon = 'logo.png'; 
            
            % 创建主网格布局 (1行3列)
            app.MainGridLayout = uigridlayout(app.UIFigure, [1, 3]);
            app.MainGridLayout.ColumnWidth = {'1.1x', '1.4x', '7x'};
            app.MainGridLayout.RowHeight = {'1x'};
            app.MainGridLayout.Padding = [5 5 5 5];
            app.MainGridLayout.ColumnSpacing = 5;
            
            % 创建左侧：数据目录区域
            createDirectoryArea(app);
            
            % 创建中间：Excel信息区域
            createExcelInfoArea(app);
            
            % 创建右侧：图像和字段显示区域
            createRightPanel(app);
            
            % 显示窗口
            app.UIFigure.Visible = 'on';
            
            % 初始化数据目录
            setupDataDirectory(app);
        end
        
        function createDirectoryArea(app)
            % 创建数据目录区域
            
            app.DirPanel = uipanel(app.MainGridLayout);
            app.DirPanel.Title = '📁 数据目录';
            app.DirPanel.FontWeight = 'bold';
            app.DirPanel.FontSize = 12;
            app.DirPanel.Layout.Row = 1;
            app.DirPanel.Layout.Column = 1;
            
            % 内部布局
            dirLayout = uigridlayout(app.DirPanel, [5, 1]);
            dirLayout.RowHeight = {30, 40, '1x', 60, 30};
            dirLayout.Padding = [5 5 5 5];
            
            % 选择路径按钮
            app.SelectPathBtn = uibutton(dirLayout, 'push');
            app.SelectPathBtn.Text = '选择路径';
            app.SelectPathBtn.Layout.Row = 1;
            app.SelectPathBtn.Layout.Column = 1;
            app.SelectPathBtn.ButtonPushedFcn = @(~,~) selectDataPath(app);
            
            % 当前路径标签
            app.CurrentPathLabel = uilabel(dirLayout);
            app.CurrentPathLabel.Text = '';
            app.CurrentPathLabel.WordWrap = 'on';
            app.CurrentPathLabel.Layout.Row = 2;
            app.CurrentPathLabel.Layout.Column = 1;
            
            % 目录树
            app.DirTree = uitree(dirLayout);
            app.DirTree.Layout.Row = 3;
            app.DirTree.Layout.Column = 1;
            app.DirTree.SelectionChangedFcn = @(~,event) onDirectorySelect(app, event);
            
            % 说明文字
            infoLabel = uilabel(dirLayout);
            infoLabel.Text = sprintf('选中具体实验后\n点击导入按钮\n加载对应数据');
            infoLabel.HorizontalAlignment = 'center';
            infoLabel.Layout.Row = 4;
            infoLabel.Layout.Column = 1;
            
            % 刷新按钮
            app.RefreshBtn = uibutton(dirLayout, 'push');
            app.RefreshBtn.Text = '更新目录';
            app.RefreshBtn.Layout.Row = 5;
            app.RefreshBtn.Layout.Column = 1;
            app.RefreshBtn.ButtonPushedFcn = @(~,~) refreshDirectory(app);
        end
        
        function createExcelInfoArea(app)
            % 创建Excel信息区域
            
            app.ExcelPanel = uipanel(app.MainGridLayout);
            app.ExcelPanel.Title = '🏷️ 数据标签';
            app.ExcelPanel.FontWeight = 'bold';
            app.ExcelPanel.FontSize = 12;
            app.ExcelPanel.Layout.Row = 1;
            app.ExcelPanel.Layout.Column = 2;
            
            % 内部布局
            excelLayout = uigridlayout(app.ExcelPanel, [4, 1]);
            excelLayout.RowHeight = {30, '3x', 30, '1x'};
            excelLayout.Padding = [5 5 5 5];
            
            % 试验背景信息标题
            app.BgInfoTitleLabel = uilabel(excelLayout);
            app.BgInfoTitleLabel.Text = '试验背景信息';
            app.BgInfoTitleLabel.FontWeight = 'bold';
            app.BgInfoTitleLabel.FontSize = 11;
            app.BgInfoTitleLabel.HorizontalAlignment = 'left';
            app.BgInfoTitleLabel.FontColor = [0 0 0];  % 黑色
            app.BgInfoTitleLabel.Layout.Row = 1;
            app.BgInfoTitleLabel.Layout.Column = 1;
            
            % Excel表格
            app.ExcelTable = uitable(excelLayout);
            app.ExcelTable.ColumnName = {'字段', '值'};
            app.ExcelTable.ColumnWidth = {'1x', '2x'};
            app.ExcelTable.RowName = {};
            app.ExcelTable.CellSelectionCallback = @(src,event) onExcelDoubleClick(app, event);
            app.ExcelTable.Layout.Row = 2;
            app.ExcelTable.Layout.Column = 1;
            
            % 子目录标题
            app.SubdirTitleLabel = uilabel(excelLayout);
            app.SubdirTitleLabel.Text = '子目录';
            app.SubdirTitleLabel.FontWeight = 'bold';
            app.SubdirTitleLabel.FontSize = 11;
            app.SubdirTitleLabel.HorizontalAlignment = 'left';
            app.SubdirTitleLabel.FontColor = [0 0 0];  % 黑色
            app.SubdirTitleLabel.Layout.Row = 3;
            app.SubdirTitleLabel.Layout.Column = 1;

            % 子目录列表
            app.SubdirListBox = uilistbox(excelLayout);
            app.SubdirListBox.Layout.Row = 4;
            app.SubdirListBox.Layout.Column = 1;
        end
        
        function createRightPanel(app)
            % 创建右侧面板（图像显示 + 字段显示 + 字段勾选）
            
            rightPanel = uipanel(app.MainGridLayout);
            rightPanel.BorderType = 'none';
            rightPanel.Layout.Row = 1;
            rightPanel.Layout.Column = 3;
            
            % 右侧主布局 (1行2列)
            rightLayout = uigridlayout(rightPanel, [1, 2]);
            rightLayout.ColumnWidth = {'5x', '0.8x'};
            rightLayout.Padding = [0 0 0 0];
            rightLayout.ColumnSpacing = 5;
            
            % 左侧：图像+字段显示
            createImageAndFieldArea(app, rightLayout);
            
            % 右侧：字段勾选区
            createFieldSelectionArea(app, rightLayout);
        end
        
        function createImageAndFieldArea(app, parentLayout)
            % 创建图像显示和字段显示区域
            
            leftPanel = uipanel(parentLayout);
            leftPanel.BorderType = 'none';
            leftPanel.Layout.Row = 1;
            leftPanel.Layout.Column = 1;
            
            % 垂直分割 (2行)
            leftLayout = uigridlayout(leftPanel, [2, 1]);
            leftLayout.RowHeight = {'4x', '1x'};
            leftLayout.Padding = [0 0 0 0];
            leftLayout.RowSpacing = 5;
            
            % 上部：图像显示区
            createImageDisplayArea(app, leftLayout);
            
            % 下部：字段显示表格
            createFieldDisplayTable(app, leftLayout);
        end
        
        function createFieldDisplayTable(app, parentLayout)
            % 创建字段显示表格
            
            fieldPanel = uipanel(parentLayout);
            fieldPanel.Title = '帧信息显示区';
            fieldPanel.FontWeight = 'bold';
            fieldPanel.FontSize = 12;
            fieldPanel.Layout.Row = 2;
            fieldPanel.Layout.Column = 1;
            
            fieldLayout = uigridlayout(fieldPanel, [1, 1]);
            fieldLayout.Padding = [5 5 5 5];
            
            app.FieldTable = uitable(fieldLayout);
            app.FieldTable.ColumnName = {'字段', '字段名', '字段值', '数据类型'};
            app.FieldTable.ColumnWidth = {'1x', '1x', '2x', '1x'};
            app.FieldTable.RowName = {};
            app.FieldTable.Layout.Row = 1;
            app.FieldTable.Layout.Column = 1;
            % 添加双击回调
            app.FieldTable.CellSelectionCallback = createCallbackFcn(app, @onFieldTableDoubleClick, true);
        end

        function createFieldSelectionArea(app, parentLayout)  % <--- 插入这里
            % 创建字段勾选区域
            
            app.FieldCheckPanel = uipanel(parentLayout);
            app.FieldCheckPanel.Title = '💾 可配置信息转存区';
            app.FieldCheckPanel.FontWeight = 'bold';
            app.FieldCheckPanel.FontSize = 12;
            app.FieldCheckPanel.Layout.Row = 1;
            app.FieldCheckPanel.Layout.Column = 2;
            
            fieldLayout = uigridlayout(app.FieldCheckPanel, [6, 1]);
            fieldLayout.RowHeight = {40, 40, 30, '1x', 30, 40};
            fieldLayout.Padding = [5 5 5 5];
            
            % 全选/取消全选按钮
            btnLayout = uigridlayout(fieldLayout, [1, 2]);
            btnLayout.ColumnWidth = {'1x', '1x'};
            btnLayout.Layout.Row = 1;
            btnLayout.Layout.Column = 1;
            
            app.SelectAllBtn = uibutton(btnLayout, 'push');
            app.SelectAllBtn.Text = '全选';
            app.SelectAllBtn.Enable = 'off';
            app.SelectAllBtn.Layout.Row = 1;
            app.SelectAllBtn.Layout.Column = 1;
            app.SelectAllBtn.ButtonPushedFcn = @(~,~) selectAllFields(app);
            
            app.DeselectAllBtn = uibutton(btnLayout, 'push');
            app.DeselectAllBtn.Text = '取消全选';
            app.DeselectAllBtn.Enable = 'off';
            app.DeselectAllBtn.Layout.Row = 1;
            app.DeselectAllBtn.Layout.Column = 2;
            app.DeselectAllBtn.ButtonPushedFcn = @(~,~) deselectAllFields(app);
            
            % 帧选择输入
            frameInputLayout = uigridlayout(fieldLayout, [1, 3]);
            frameInputLayout.ColumnWidth = {40, '1x', 20};
            frameInputLayout.Layout.Row = 2;
            frameInputLayout.Layout.Column = 1;
            
            frameLabel = uilabel(frameInputLayout);
            frameLabel.Text = '选择帧:';
            frameLabel.Layout.Row = 1;
            frameLabel.Layout.Column = 1;
            
            app.FrameInputField = uieditfield(frameInputLayout, 'text');
            app.FrameInputField.Placeholder = '例: 1,3-5,8';
            app.FrameInputField.Layout.Row = 1;
            app.FrameInputField.Layout.Column = 2;
            app.FrameInputField.ValueChangedFcn = @(~,~) updateFrameStatus(app);
            
            frameHelpBtn = uibutton(frameInputLayout, 'push');
            frameHelpBtn.Text = '?';
            frameHelpBtn.Layout.Row = 1;
            frameHelpBtn.Layout.Column = 3;
            frameHelpBtn.ButtonPushedFcn = @(~,~) showFrameHelp(app);
            
            % 帧状态标签
            app.FrameStatusLabel = uilabel(fieldLayout);
            app.FrameStatusLabel.Text = '';
            app.FrameStatusLabel.Layout.Row = 3;
            app.FrameStatusLabel.Layout.Column = 1;
            
            % 字段复选框滚动区域
            app.FieldCheckboxPanel = uipanel(fieldLayout);
            app.FieldCheckboxPanel.BorderType = 'none';
            app.FieldCheckboxPanel.Scrollable = 'on';
            app.FieldCheckboxPanel.Layout.Row = 4;
            app.FieldCheckboxPanel.Layout.Column = 1;
            
            % 空白占位
            spacer = uilabel(fieldLayout);
            spacer.Text = '';
            spacer.Layout.Row = 5;
            spacer.Layout.Column = 1;
            
            % 导出按钮
            app.ExportBtn = uibutton(fieldLayout, 'push');
            app.ExportBtn.Text = '转存选中字段';
            app.ExportBtn.Enable = 'off';
            app.ExportBtn.FontWeight = 'bold';
            app.ExportBtn.BackgroundColor = [0.4660 0.6740 0.1880];
            app.ExportBtn.FontColor = [1 1 1];
            app.ExportBtn.Layout.Row = 6;
            app.ExportBtn.Layout.Column = 1;
            app.ExportBtn.ButtonPushedFcn = @(~,~) exportFiles(app);
        end        

        function setupDataDirectory(app)
            % 初始化数据目录
            updatePathDisplay(app);
            refreshDirectory(app);
            
            % 初始化时清空试验背景信息和子目录
            app.ExcelTable.Data = {};
            app.SubdirListBox.Items = {};
        end

        function createImageDisplayArea(app, parentLayout)
            % 创建图像显示区域
            
            app.ImagePanel = uipanel(parentLayout);
            app.ImagePanel.Title = '🖼️ 图像显示区';
            app.ImagePanel.FontWeight = 'bold';
            app.ImagePanel.FontSize = 12;
            app.ImagePanel.Layout.Row = 1;
            app.ImagePanel.Layout.Column = 1;
            
            % 内部布局：5行
            % 第1行: 功能按钮 (30px)
            % 第2行: 预处理控制栏 (35px)
            % 第3行: 信息显示 (45px)
            % 第4行: 图像显示 (弹性)
            % 第5行: 帧控制 (120px)
            imgLayout = uigridlayout(app.ImagePanel, [5, 1]);
            imgLayout.RowHeight = {30, 35, 45, '1x', 120};
            imgLayout.Padding = [5 5 5 5];
            imgLayout.RowSpacing = 3;
            
            % ========== 第1行：功能按钮 ==========
            btnLayout1 = uigridlayout(imgLayout, [1, 8]);
            btnLayout1.ColumnWidth = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};
            btnLayout1.Layout.Row = 1;
            btnLayout1.Layout.Column = 1;
            btnLayout1.Padding = [5 2 5 2];
            btnLayout1.ColumnSpacing = 3;
            
            app.ImportBtn = uibutton(btnLayout1, 'push');
            app.ImportBtn.Text = '导入选中实验数据';
            app.ImportBtn.Layout.Row = 1;
            app.ImportBtn.Layout.Column = 1;
            app.ImportBtn.ButtonPushedFcn = @(~,~) importFiles(app);
            
            app.WaveformBtn = uibutton(btnLayout1, 'push');
            app.WaveformBtn.Text = '时域波形图';
            app.WaveformBtn.Enable = 'off';
            app.WaveformBtn.Layout.Row = 1;
            app.WaveformBtn.Layout.Column = 2;
            app.WaveformBtn.ButtonPushedFcn = @(~,~) showTimeWaveform(app);
            
            app.OriginalBtn = uibutton(btnLayout1, 'push');
            app.OriginalBtn.Text = '原图放大';
            app.OriginalBtn.Enable = 'off';
            app.OriginalBtn.Layout.Row = 1;
            app.OriginalBtn.Layout.Column = 3;
            app.OriginalBtn.ButtonPushedFcn = @(~,~) showOriginalImage(app);
            
            app.DbBtn = uibutton(btnLayout1, 'push');
            app.DbBtn.Text = '原图dB放大';
            app.DbBtn.Enable = 'off';
            app.DbBtn.Layout.Row = 1;
            app.DbBtn.Layout.Column = 4;
            app.DbBtn.ButtonPushedFcn = @(~,~) showDbImage(app);
            
            app.Mesh3DBtn = uibutton(btnLayout1, 'push');
            app.Mesh3DBtn.Text = '3D图像放大';
            app.Mesh3DBtn.Enable = 'off';
            app.Mesh3DBtn.Layout.Row = 1;
            app.Mesh3DBtn.Layout.Column = 5;
            app.Mesh3DBtn.ButtonPushedFcn = @(~,~) show3DMesh(app);
            
            app.DbMesh3DBtn = uibutton(btnLayout1, 'push');
            app.DbMesh3DBtn.Text = '3D图像dB放大';
            app.DbMesh3DBtn.Enable = 'off';
            app.DbMesh3DBtn.Layout.Row = 1;
            app.DbMesh3DBtn.Layout.Column = 6;
            app.DbMesh3DBtn.ButtonPushedFcn = @(~,~) showDb3DMesh(app);
            
            app.SARBtn = uibutton(btnLayout1, 'push');
            app.SARBtn.Text = 'SAR图';
            app.SARBtn.Enable = 'off';
            app.SARBtn.Layout.Row = 1;
            app.SARBtn.Layout.Column = 7;
            app.SARBtn.ButtonPushedFcn = @(~,~) showSARImage(app);
        
            % 状态标签
            app.StatusLabel = uilabel(btnLayout1);
            app.StatusLabel.Text = '请选择具体实验';
            app.StatusLabel.FontColor = [1 0.6 0];
            app.StatusLabel.FontWeight = 'bold';
            app.StatusLabel.HorizontalAlignment = 'right';
            app.StatusLabel.Layout.Row = 1;
            app.StatusLabel.Layout.Column = 8;
            
            % ========== 第2行：预处理控制栏 ==========
            createPreprocessingControlBar(app, imgLayout);
            
            % ========== 第3行：信息显示 ==========
            infoPanel = uipanel(imgLayout);
            infoPanel.BorderType = 'none';
            infoPanel.Layout.Row = 3;
            infoPanel.Layout.Column = 1;
            
            infoLayout = uigridlayout(infoPanel, [2, 1]);
            infoLayout.RowHeight = {22, 23};
            infoLayout.Padding = [10 2 10 0];
            infoLayout.RowSpacing = 0;
            
            % 第一行信息：型号名称-试验时间-试验地点-模式
            app.InfoLine1Label = uilabel(infoLayout);
            app.InfoLine1Label.Text = '';
            app.InfoLine1Label.FontSize = 15;
            app.InfoLine1Label.FontWeight = 'bold';
            app.InfoLine1Label.HorizontalAlignment = 'center';
            app.InfoLine1Label.Layout.Row = 1;
            app.InfoLine1Label.Layout.Column = 1;
            
            % 第二行信息：试验目的
            app.InfoLine2Label = uilabel(infoLayout);
            app.InfoLine2Label.Text = '';
            app.InfoLine2Label.FontSize = 12;
            app.InfoLine2Label.HorizontalAlignment = 'center';
            app.InfoLine2Label.Layout.Row = 2;
            app.InfoLine2Label.Layout.Column = 1;
        
            % ========== 第4行：图像显示区（多视图网格）==========
            app.MultiViewPanel = uipanel(imgLayout);
            app.MultiViewPanel.BorderType = 'line';
            app.MultiViewPanel.Layout.Row = 4;
            app.MultiViewPanel.Layout.Column = 1;
            app.MultiViewPanel.AutoResizeChildren = 'off';  % 允许手动定位
            
            multiViewLayout = uigridlayout(app.MultiViewPanel, [2, 2]);
            multiViewLayout.Padding = [2 2 2 2];
            multiViewLayout.RowSpacing = 3;
            multiViewLayout.ColumnSpacing = 3;
            
            % 创建4个子图区域
            app.ImageAxes1 = uiaxes(multiViewLayout);
            app.ImageAxes1.Layout.Row = 1;
            app.ImageAxes1.Layout.Column = 1;
            app.ImageAxes1.XTick = [];
            app.ImageAxes1.YTick = [];
            app.ImageAxes1.Box = 'on';
            
            app.ImageAxes2 = uiaxes(multiViewLayout);
            app.ImageAxes2.Layout.Row = 1;
            app.ImageAxes2.Layout.Column = 2;
            app.ImageAxes2.XTick = [];
            app.ImageAxes2.YTick = [];
            app.ImageAxes2.Box = 'on';
            app.ImageAxes2.Visible = 'off';
            
            app.ImageAxes3 = uiaxes(multiViewLayout);
            app.ImageAxes3.Layout.Row = 2;
            app.ImageAxes3.Layout.Column = 1;
            app.ImageAxes3.XTick = [];
            app.ImageAxes3.YTick = [];
            app.ImageAxes3.Box = 'on';
            app.ImageAxes3.Visible = 'off';
            
            app.ImageAxes4 = uiaxes(multiViewLayout);
            app.ImageAxes4.Layout.Row = 2;
            app.ImageAxes4.Layout.Column = 2;
            app.ImageAxes4.XTick = [];
            app.ImageAxes4.YTick = [];
            app.ImageAxes4.Box = 'on';
            app.ImageAxes4.Visible = 'off';
            
            % 保持向后兼容
            app.ImageAxes = app.ImageAxes1;

            % ⭐ 创建浮动的关闭按钮（父容器是 MultiViewPanel，不是 gridlayout，按钮会浮动在坐标轴上方
            
            % 关闭按钮2
            app.CloseBtn2 = uibutton(app.MultiViewPanel, 'push');
            app.CloseBtn2.Text = '✕';
            app.CloseBtn2.FontSize = 14;
            app.CloseBtn2.FontWeight = 'bold';
            app.CloseBtn2.BackgroundColor = [1 0.95 0.95];
            app.CloseBtn2.FontColor = [0.8 0 0];
            app.CloseBtn2.Position = [10 10 30 25];  % 临时位置，后续会动态调整
            app.CloseBtn2.Visible = 'off';
            app.CloseBtn2.Tooltip = '关闭此视图';
            app.CloseBtn2.ButtonPushedFcn = createCallbackFcn(app, @(~,~)closeSubView(app, 2), true);
            
            % 关闭按钮3
            app.CloseBtn3 = uibutton(app.MultiViewPanel, 'push');
            app.CloseBtn3.Text = '✕';
            app.CloseBtn3.FontSize = 14;
            app.CloseBtn3.FontWeight = 'bold';
            app.CloseBtn3.BackgroundColor = [1 0.95 0.95];
            app.CloseBtn3.FontColor = [0.8 0 0];
            app.CloseBtn3.Position = [10 10 30 25];
            app.CloseBtn3.Visible = 'off';
            app.CloseBtn3.Tooltip = '关闭此视图';
            app.CloseBtn3.ButtonPushedFcn = createCallbackFcn(app, @(~,~)closeSubView(app, 3), true);
            
            % 关闭按钮4
            app.CloseBtn4 = uibutton(app.MultiViewPanel, 'push');
            app.CloseBtn4.Text = '✕';
            app.CloseBtn4.FontSize = 14;
            app.CloseBtn4.FontWeight = 'bold';
            app.CloseBtn4.BackgroundColor = [1 0.95 0.95];
            app.CloseBtn4.FontColor = [0.8 0 0];
            app.CloseBtn4.Position = [10 10 30 25];
            app.CloseBtn4.Visible = 'off';
            app.CloseBtn4.Tooltip = '关闭此视图';
            app.CloseBtn4.ButtonPushedFcn = createCallbackFcn(app, @(~,~)closeSubView(app, 4), true);
            
            % 监听面板大小变化，动态调整按钮位置
            app.MultiViewPanel.SizeChangedFcn = createCallbackFcn(app, @(src, event)updateCloseButtonPositions(app), true);
            
            % ========== 第5行：帧控制区 ==========
            createFrameControlArea(app, imgLayout);
        end
        
        function createFrameControlArea(app, parentLayout)
            % 创建帧控制区域（图像下方）
            
            framePanel = uipanel(parentLayout);
            framePanel.BorderType = 'none';
            framePanel.Layout.Row = 5;
            framePanel.Layout.Column = 1;
            
            frameLayout = uigridlayout(framePanel, [3, 1]); 
            frameLayout.RowHeight = {30, 30, 45};
            frameLayout.Padding = [1 1 1 1];
            frameLayout.RowSpacing = 5;
            
            % 第一行：播放方式 + 自动播放（左侧） + 播放间隔 + 帧间隔（右侧）
            row1Layout = uigridlayout(frameLayout, [1, 10]);  % 10列
            row1Layout.ColumnWidth = {70, 100, 90, '1x', 70, 50, 25, 70, 50, 25};  % 弹性空间在第4列
            row1Layout.Layout.Row = 1;
            row1Layout.Layout.Column = 1;
            row1Layout.RowHeight = {30};
            row1Layout.Padding = [0 0 0 0];
            row1Layout.ColumnSpacing = 5;
            
            % 左侧：播放方式
            label1 = uilabel(row1Layout);
            label1.Text = '播放方式:';
            label1.Layout.Row = 1;
            label1.Layout.Column = 1;
            
            app.PlayModeCombo = uidropdown(row1Layout);
            app.PlayModeCombo.Items = {'原图', '原图dB', '3D图像', '3D图像dB'};
            app.PlayModeCombo.Value = '原图';  % 默认选择原图
            app.PlayModeCombo.Layout.Row = 1;
            app.PlayModeCombo.Layout.Column = 2;
            app.PlayModeCombo.ValueChangedFcn = @(~,~) onPlayModeChanged(app);  % 添加回调
            
            % 左侧：自动播放按钮
            app.AutoPlayBtn = uibutton(row1Layout, 'push');
            app.AutoPlayBtn.Text = '自动播放';
            app.AutoPlayBtn.Enable = 'off';
            app.AutoPlayBtn.Layout.Row = 1;
            app.AutoPlayBtn.Layout.Column = 3;
            app.AutoPlayBtn.ButtonPushedFcn = @(~,~) toggleAutoPlay(app);
            
            % 中间弹性空间（第4列）
            spacer = uilabel(row1Layout);
            spacer.Text = '';
            spacer.Layout.Row = 1;
            spacer.Layout.Column = 4;
            
            % 右侧：播放间隔
            label2 = uilabel(row1Layout);
            label2.Text = '播放间隔:';
            label2.Layout.Row = 1;
            label2.Layout.Column = 5;
            
            app.IntervalSpinner = uispinner(row1Layout);
            app.IntervalSpinner.Value = 1;
            app.IntervalSpinner.Limits = [0.1 60];
            app.IntervalSpinner.Step = 0.5;
            app.IntervalSpinner.Layout.Row = 1;
            app.IntervalSpinner.Layout.Column = 6;
            app.IntervalSpinner.ValueChangedFcn = @(src,~) updatePlayInterval(app, src.Value);
            
            label2b = uilabel(row1Layout);
            label2b.Text = '秒';
            label2b.Layout.Row = 1;
            label2b.Layout.Column = 7;
            
            % 右侧：帧间隔
            label3 = uilabel(row1Layout);
            label3.Text = '帧间隔:';
            label3.Layout.Row = 1;
            label3.Layout.Column = 8;
            
            app.FrameStepSpinner = uispinner(row1Layout);
            app.FrameStepSpinner.Value = 1;
            app.FrameStepSpinner.Limits = [1 100];
            app.FrameStepSpinner.Step = 1;
            app.FrameStepSpinner.Layout.Row = 1;
            app.FrameStepSpinner.Layout.Column = 9;
            
            label3b = uilabel(row1Layout);
            label3b.Text = '帧';
            label3b.Layout.Row = 1;
            label3b.Layout.Column = 10;
            
            % 第二行：当前帧信息 + 跳转控制
            row2Layout = uigridlayout(frameLayout, [1, 6]);
            row2Layout.ColumnWidth = {'2x', 60, 100, 200, 60, 30};
            row2Layout.Layout.Row = 2;  % 从第3行改为第2行
            row2Layout.Layout.Column = 1;
            row2Layout.RowHeight = {30};
            row2Layout.Padding = [0 0 0 0];
            row2Layout.ColumnSpacing = 5;
            
            app.FrameInfoLabel = uilabel(row2Layout);
            app.FrameInfoLabel.Text = '';
            app.FrameInfoLabel.FontColor = [0 0 1];
            app.FrameInfoLabel.FontWeight = 'bold';
            app.FrameInfoLabel.Layout.Row = 1;
            app.FrameInfoLabel.Layout.Column = 1;
            
            jumpLabel = uilabel(row2Layout);
            jumpLabel.Text = '跳转:';
            jumpLabel.HorizontalAlignment = 'right';
            jumpLabel.Layout.Row = 1;
            jumpLabel.Layout.Column = 2;
            
            app.JumpCombo = uidropdown(row2Layout);
            app.JumpCombo.Items = {'帧号', '文件名'};
            app.JumpCombo.Layout.Row = 1;
            app.JumpCombo.Layout.Column = 3;
            
            app.JumpInput = uieditfield(row2Layout, 'text');
            app.JumpInput.Placeholder = '输入帧号或文件名';
            app.JumpInput.Layout.Row = 1;
            app.JumpInput.Layout.Column = 4;
            % 去掉回车跳转，避免错误弹窗
            % app.JumpInput.ValueChangedFcn = @(~,~) onJumpInputEnter(app);去掉回车跳转，
            
            app.JumpBtn = uibutton(row2Layout, 'push');
            app.JumpBtn.Text = '跳转';
            app.JumpBtn.Enable = 'off';
            app.JumpBtn.Layout.Row = 1;
            app.JumpBtn.Layout.Column = 5;
            app.JumpBtn.ButtonPushedFcn = @(~,~) onJumpToFrame(app);
            
            helpBtn = uibutton(row2Layout, 'push');
            helpBtn.Text = '?';
            helpBtn.Layout.Row = 1;
            helpBtn.Layout.Column = 6;
            helpBtn.ButtonPushedFcn = @(~,~) showJumpHelp(app);
            
            % 第三行：滑动条控制
            row3Layout = uigridlayout(frameLayout, [1, 3]);
            row3Layout.ColumnWidth = {30, '1x', 30};
            row3Layout.Layout.Row = 3;  % 从第4行改为第3行
            row3Layout.Layout.Column = 1;
            row3Layout.Padding = [0 0 0 0];
            
            app.PrevBtn = uibutton(row3Layout, 'push');
            app.PrevBtn.Text = '◀';
            app.PrevBtn.Enable = 'off';
            app.PrevBtn.Layout.Row = 1;
            app.PrevBtn.Layout.Column = 1;
            app.PrevBtn.ButtonPushedFcn = @(~,~) gotoPrevFrame(app);
            
            app.FrameSlider = uislider(row3Layout);
            app.FrameSlider.Enable = 'off';
            app.FrameSlider.Layout.Row = 1;
            app.FrameSlider.Layout.Column = 2;
            app.FrameSlider.ValueChangedFcn = @(~,event) onSliderChange(app, event);
            
            app.NextBtn = uibutton(row3Layout, 'push');
            app.NextBtn.Text = '▶';
            app.NextBtn.Enable = 'off';
            app.NextBtn.Layout.Row = 1;
            app.NextBtn.Layout.Column = 3;
            app.NextBtn.ButtonPushedFcn = @(~,~) gotoNextFrame(app);
        end

        function createPreprocessingControlBar(app, parentLayout)
            % 创建预处理控制栏
            
            prepPanel = uipanel(parentLayout);
            prepPanel.BorderType = 'none';
            prepPanel.Layout.Row = 2;
            prepPanel.Layout.Column = 1;
            
            prepLayout = uigridlayout(prepPanel, [1, 13]);
            prepLayout.ColumnWidth = {50, 70, 90, 90, 90, 90, 90, 90, '1x', 100, 70, 5};
            prepLayout.Padding = [5 2 5 2];
            prepLayout.ColumnSpacing = 5;

            % 标签
            label = uilabel(prepLayout);
            label.Text = '显示:';
            label.FontWeight = 'bold';
            label.FontSize = 12;
            label.Layout.Row = 1;
            label.Layout.Column = 1;

            % 原图复选框
            app.ShowOriginalCheck = uicheckbox(prepLayout);
            app.ShowOriginalCheck.Text = '原图';
            app.ShowOriginalCheck.Value = true;
            app.ShowOriginalCheck.Layout.Row = 1;
            app.ShowOriginalCheck.Layout.Column = 2;
            app.ShowOriginalCheck.ValueChangedFcn = @(~,~) onShowOriginalChanged(app);

            % 非相参积累按钮
            app.ShowPrep2Btn = uibutton(prepLayout, 'push');
            app.ShowPrep2Btn.Text = '非相参积累';
            app.ShowPrep2Btn.Enable = 'off';
            app.ShowPrep2Btn.Layout.Row = 1;
            app.ShowPrep2Btn.Layout.Column = 3;
            app.ShowPrep2Btn.ButtonPushedFcn = createCallbackFcn(app, @(~,~)executeDefaultPrep(app, 1), true);
            app.ShowPrep2Btn.Tooltip = '非相参积累预处理';

            % 非相参识别按钮
            app.ShowCoherentBtn = uibutton(prepLayout, 'push');
            app.ShowCoherentBtn.Text = '非相参识别';
            app.ShowCoherentBtn.Enable = 'off';
            app.ShowCoherentBtn.Layout.Row = 1;
            app.ShowCoherentBtn.Layout.Column = 4;
            app.ShowCoherentBtn.ButtonPushedFcn = createCallbackFcn(app, @(~,~)executeDefaultPrep(app, 2), true);
            app.ShowCoherentBtn.Tooltip = '非相参识别预处理';

            % CFAR检测按钮
            app.ShowPrep1Btn = uibutton(prepLayout, 'push');
            app.ShowPrep1Btn.Text = 'CFAR检测';
            app.ShowPrep1Btn.Enable = 'off';
            app.ShowPrep1Btn.Layout.Row = 1;
            app.ShowPrep1Btn.Layout.Column = 5;
            app.ShowPrep1Btn.ButtonPushedFcn = createCallbackFcn(app, @(~,~)executeDefaultPrep(app, 3), true);
            app.ShowPrep1Btn.Tooltip = 'CFAR检测预处理';

            % 多维识别按钮
            app.ShowDetectionBtn = uibutton(prepLayout, 'push');
            app.ShowDetectionBtn.Text = '多维识别';
            app.ShowDetectionBtn.Enable = 'off';
            app.ShowDetectionBtn.Layout.Row = 1;
            app.ShowDetectionBtn.Layout.Column = 6;
            app.ShowDetectionBtn.ButtonPushedFcn = createCallbackFcn(app, @(~,~)executeDefaultPrep(app, 4), true);
            app.ShowDetectionBtn.Tooltip = '多维识别预处理';

            % 预处理3按钮（预留）
            app.ShowPrep3Btn = uibutton(prepLayout, 'push');
            app.ShowPrep3Btn.Text = '预处理';
            app.ShowPrep3Btn.Enable = 'off';
            app.ShowPrep3Btn.Layout.Row = 1;
            app.ShowPrep3Btn.Layout.Column = 7;
            app.ShowPrep3Btn.ButtonPushedFcn = createCallbackFcn(app, @(~,~)executePrepOnCurrentFrame(app, -1), true);  % -1表示使用最新的预处理
            app.ShowPrep3Btn.Tooltip = '自定义预处理';

            % 动态预处理按钮容器（用于显示自定义预处理按钮）
            app.DynamicPrepPanel = uipanel(prepLayout);
            app.DynamicPrepPanel.BorderType = 'none';
            app.DynamicPrepPanel.Layout.Row = 1;
            app.DynamicPrepPanel.Layout.Column = 9;
            app.DynamicPrepPanel.Scrollable = 'off';

            % 添加预处理按钮
            app.AddPrepBtn = uibutton(prepLayout, 'push');
            app.AddPrepBtn.Text = '➕ 添加预处理';
            app.AddPrepBtn.Layout.Row = 1;
            app.AddPrepBtn.Layout.Column = 10;
            app.AddPrepBtn.Enable = 'off';
            app.AddPrepBtn.ButtonPushedFcn = @(~,~) openPreprocessingDialog(app);
            app.AddPrepBtn.Tooltip = '添加新的预处理';

            % 清除全部按钮
            app.ClearPrepBtn = uibutton(prepLayout, 'push');
            app.ClearPrepBtn.Text = '🗑️ 清除';
            app.ClearPrepBtn.Layout.Row = 1;
            app.ClearPrepBtn.Layout.Column = 11;
            app.ClearPrepBtn.Enable = 'off';
            app.ClearPrepBtn.ButtonPushedFcn = @(~,~) clearAllPreprocessing(app);
            app.ClearPrepBtn.Tooltip = '清除所有预处理';
        end    
        
        function selectDataPath(app)
            % 选择数据路径
            folder = uigetdir(app.CurrentDataPath, '选择数据根目录');

            % 文件选择后置顶UI（无论是否取消）
            figure(app.UIFigure);

            if folder ~= 0
                app.CurrentDataPath = folder;
                updatePathDisplay(app);
                refreshDirectory(app);
            end
        end
        
        function updatePathDisplay(app)
            % 更新路径显示
            if isempty(app.CurrentDataPath)
                app.CurrentPathLabel.Text = '未设置路径';
            else
                app.CurrentPathLabel.Text = app.CurrentDataPath;
            end
        end
        
        function refreshDirectory(app)
            % 刷新目录树 - 支持4层目录结构
            delete(app.DirTree.Children);
            
            if ~isfolder(app.CurrentDataPath)
                return;
            end
            
            % 获取第1层目录
            dirs1 = dir(app.CurrentDataPath);
            dirs1 = dirs1([dirs1.isdir] & ~startsWith({dirs1.name}, '.'));
            
            for i = 1:length(dirs1)
                level1Name = dirs1(i).name;
                level1Path = fullfile(app.CurrentDataPath, level1Name);
                level1Node = uitreenode(app.DirTree, 'Text', level1Name);
                level1Node.NodeData = level1Path;
                
                % 获取第2层目录
                dirs2 = dir(level1Path);
                dirs2 = dirs2([dirs2.isdir] & ~startsWith({dirs2.name}, '.'));
                
                for j = 1:length(dirs2)
                    level2Name = dirs2(j).name;
                    level2Path = fullfile(level1Path, level2Name);
                    level2Node = uitreenode(level1Node, 'Text', level2Name);
                    level2Node.NodeData = level2Path;
                    
                    % 获取第3层目录
                    dirs3 = dir(level2Path);
                    dirs3 = dirs3([dirs3.isdir] & ~startsWith({dirs3.name}, '.'));
                    
                    for k = 1:length(dirs3)
                        level3Name = dirs3(k).name;
                        level3Path = fullfile(level2Path, level3Name);
                        level3Node = uitreenode(level2Node, 'Text', level3Name);
                        level3Node.NodeData = level3Path;
                        
                        % 获取第4层目录
                        dirs4 = dir(level3Path);
                        dirs4 = dirs4([dirs4.isdir] & ~startsWith({dirs4.name}, '.'));
                        
                        for m = 1:length(dirs4)
                            level4Name = dirs4(m).name;
                            level4Path = fullfile(level3Path, level4Name);
                            level4Node = uitreenode(level3Node, 'Text', level4Name);
                            level4Node.NodeData = level4Path;
                        end
                    end
                end
            end

            % 刷新目录树后清空试验背景信息和子目录
            app.ExcelTable.Data = {};
            app.SubdirListBox.Items = {};
        end
        
        function onDirectorySelect(app, event)
            % 目录选择回调
            if isempty(event.SelectedNodes)
                return;
            end
            
            selectedNode = event.SelectedNodes(1);
            selectedPath = selectedNode.NodeData;
            
            if ~isempty(selectedPath) && isfolder(selectedPath)
                
                % ========== 替换为更健壮的路径逻辑 ==========
                if isempty(app.CurrentDataPath)
                    return;
                end
                
                % 规范化路径，统一使用系统分隔符
                currentPath = strrep(selectedPath, '/', filesep);
                currentPath = strrep(currentPath, '\', filesep);
                rootPath = strrep(app.CurrentDataPath, '/', filesep);
                rootPath = strrep(rootPath, '\', filesep);
                
                % 确保根目录路径以分隔符结尾
                if ~endsWith(rootPath, filesep)
                    rootPath = [rootPath, filesep];
                end
                
                % 检查currentPath是否在rootPath下
                if ~startsWith(currentPath, rootPath)
                    % 路径不匹配，可能是用户选择了其他位置的文件夹
                    warning('MatViewerTool:PathMismatch', '当前选择的路径不在数据根目录下');
                    currentLevel = 0; % 设为0，避免后续错误
                    pathParts = {};
                else
                    % 计算相对路径
                    relativePath = strrep(currentPath, rootPath, '');
                    
                    % 移除可能的前导分隔符
                    if startsWith(relativePath, filesep)
                        relativePath = relativePath(2:end);
                    end
                    
                    % 分割路径
                    pathParts = strsplit(relativePath, filesep);
                    pathParts = pathParts(~cellfun(@isempty, pathParts));
                    
                    % 计算当前选中目录的层级
                    currentLevel = length(pathParts);
                end
                % ========== 结束健壮版目录读取 ==========
                
                % 判断是否包含.mat文件（任意层级都可以）
                matFiles = dir(fullfile(selectedPath, '*.mat'));
                
                % 无论是否有MAT文件，都设置选中路径（用于打开文件选择对话框）
                app.SelectedExperiment = selectedPath;
                
                if ~isempty(matFiles)
                    app.StatusLabel.Text = sprintf('已选择: %s (第%d级)', selectedNode.Text, currentLevel);
                    app.StatusLabel.FontColor = [0 0.5 0];
                else
                    app.StatusLabel.Text = sprintf('已选择: %s (第%d级)', selectedNode.Text, currentLevel);
                    app.StatusLabel.FontColor = [0 0.5 0];
                end
                
                % 更新中间区域（原有功能保持不变）
                updateExcelInfo(app, selectedPath);
                updateSubdirList(app, selectedPath);

                % 放开目录层级限制：对所有层级都尝试读取Excel和子目录信息
                % 原来只对3级和4级目录读取，现在对所有层级都读取
                updateBgInfoFromExcel(app, selectedPath);
                updateSubdirDisplay(app, selectedPath);

                % 读取对应第一级目录的Excel字段名和单位（用于帧信息显示区）
                % 如果没有Excel文件，readFieldNamesFromLevel1Excel会返回空数组，会使用默认字段名（字段1、字段2等）
                [app.FieldDisplayNames, app.FieldUnits] = readFieldNamesFromLevel1Excel(app, selectedPath);

                % 将GUI窗口置顶
                figure(app.UIFigure);
                drawnow;

            end
        end
        
        function updateExcelInfo(app, folderPath)
            % 更新Excel信息显示
            excelData = readExcelFile(app, folderPath);
            
            if ~isempty(excelData)
                app.ExcelTable.Data = excelData;
            else
                app.ExcelTable.Data = {};
            end
        end
        
        function excelData = readExcelFile(app, folderPath)
            % 读取试验背景信息Excel文件（只从3级或4级目录读取）
            % 优先读取4级目录的Excel，如果4级没有则读取3级的Excel
            excelData = {};

            if ~isfolder(folderPath)
                return;
            end

            % 计算当前目录层级
            relativePath = strrep(folderPath, app.CurrentDataPath, '');
            pathParts = strsplit(relativePath, filesep);
            pathParts = pathParts(~cellfun(@isempty, pathParts));
            currentLevel = length(pathParts);

            % 只从3级或4级目录读取背景信息
            if currentLevel ~= 3 && currentLevel ~= 4
                return;
            end

            excelFilePath = '';

            % 如果是4级目录，优先在4级查找Excel
            if currentLevel == 4
                excelFiles = dir(fullfile(folderPath, '*.xlsx'));
                if isempty(excelFiles)
                    excelFiles = dir(fullfile(folderPath, '*.xls'));
                end

                if ~isempty(excelFiles)
                    % 4级目录找到Excel
                    excelFilePath = fullfile(folderPath, excelFiles(1).name);
                else
                    % 4级没有，向上找3级目录的Excel
                    parentPath = fileparts(folderPath);
                    parentExcelFiles = dir(fullfile(parentPath, '*.xlsx'));
                    if isempty(parentExcelFiles)
                        parentExcelFiles = dir(fullfile(parentPath, '*.xls'));
                    end

                    if ~isempty(parentExcelFiles)
                        excelFilePath = fullfile(parentPath, parentExcelFiles(1).name);
                    end
                end
            elseif currentLevel == 3
                % 如果是3级目录，直接在3级查找Excel
                excelFiles = dir(fullfile(folderPath, '*.xlsx'));
                if isempty(excelFiles)
                    excelFiles = dir(fullfile(folderPath, '*.xls'));
                end

                if ~isempty(excelFiles)
                    excelFilePath = fullfile(folderPath, excelFiles(1).name);
                end
            end
            
            if isempty(excelFilePath)
                return;
            end
            
            try
                % 读取Excel文件 (使用 readcell 替代 xlsread)
                raw = readcell(excelFilePath);
                
                % Excel格式：第1行从B1开始是字段，第2行从B2开始是值
                if size(raw, 1) >= 2 && size(raw, 2) >= 2
                    % 从第2列（B列）开始读取
                    headers = raw(1, 2:end);
                    values = raw(2, 2:end);
                    
                    % 过滤掉空字段
                    validIdx = ~cellfun(@(x) isempty(x) || ...
                        (ischar(x) && isempty(strtrim(x))) || ...
                        (isnumeric(x) && isnan(x)), headers);
                    
                    if any(validIdx)
                        % 转换为字符串
                        headers = headers(validIdx);
                        values = values(validIdx);
                        
                        % 确保 headers 也是字符串
                        for i = 1:length(headers)
                            if ~ischar(headers{i}) && ~isstring(headers{i})
                                if isnumeric(headers{i})
                                    headers{i} = num2str(headers{i});
                                elseif isdatetime(headers{i})
                                    headers{i} = char(headers{i});
                                else
                                    try
                                        headers{i} = char(string(headers{i}));
                                    catch
                                        headers{i} = sprintf('字段%d', i);
                                    end
                                end
                            end
                        end
                        
                        % 将所有值转换为字符串（处理各种数据类型）
                        for i = 1:length(values)
                            if isempty(values{i})
                                values{i} = '';
                            elseif isnumeric(values{i})
                                if isnan(values{i})
                                    values{i} = '';
                                else
                                    values{i} = num2str(values{i});
                                end
                            elseif isdatetime(values{i})
                                % datetime 类型转换为字符串
                                values{i} = char(values{i});
                            elseif isduration(values{i})
                                % duration 类型转换为字符串
                                values{i} = char(values{i});
                            elseif islogical(values{i})
                                % logical 类型转换为字符串
                                values{i} = char(string(values{i}));
                            elseif iscell(values{i})
                                % 嵌套的 cell，尝试转换
                                values{i} = '{cell}';
                            elseif isstruct(values{i})
                                % struct 类型
                                values{i} = '{struct}';
                            elseif ~ischar(values{i}) && ~isstring(values{i})
                                % 其他未知类型，尝试转换为字符串
                                try
                                    values{i} = char(string(values{i}));
                                catch
                                    values{i} = class(values{i});  % 显示类型名
                                end
                            end
                        end
                        
                        excelData = [headers', values'];
                    end
                end
            catch ME
                % 读取失败，返回空
                warning(['读取Excel文件失败: ', ME.message]);
            end
        end
        
        function updateBgInfoFromExcel(app, folderPath)
            % 更新试验背景信息（从当前目录的Excel文件读取）
            excelData = readExcelFile(app, folderPath);
            
            if ~isempty(excelData)
                app.ExcelTable.Data = excelData;
            else
                app.ExcelTable.Data = {};
            end
        end

        function updateSubdirDisplay(app, folderPath)
            % 更新子目录显示（显示当前目录的下级目录）
            app.SubdirListBox.Items = {};
            
            if ~isfolder(folderPath)
                return;
            end
            
            % 获取当前目录的子目录
            subdirs = dir(folderPath);
            subdirs = subdirs([subdirs.isdir] & ~startsWith({subdirs.name}, '.'));
            
            if ~isempty(subdirs)
                app.SubdirListBox.Items = {subdirs.name};
            else
                app.SubdirListBox.Items = {'(无子目录)'};
            end
        end        

        function updateSubdirList(app, folderPath)
            % 更新子目录列表
            app.SubdirListBox.Items = {};
            
            if ~isfolder(folderPath)
                return;
            end
            
            subdirs = dir(folderPath);
            subdirs = subdirs([subdirs.isdir] & ~startsWith({subdirs.name}, '.'));
            
            if ~isempty(subdirs)
                app.SubdirListBox.Items = {subdirs.name};
            else
                app.SubdirListBox.Items = {'(无子目录)'};
            end
        end
        
        % ==================== 数据导入函数 ====================
        
        function importFiles(app)
            % 导入MAT文件
            if isempty(app.SelectedExperiment)
                uialert(app.UIFigure, '请先在数据目录中选择具体的实验', '提示');
                return;
            end

            % 取消 FieldDisplayNames 为空的检查，允许使用默认字段名（字段1、字段2等）
            % if isempty(app.FieldDisplayNames)
            %     uialert(app.UIFigure, '请先在数据目录中选择一个文件夹，以便读取字段名称配置。', '提示');
            %     return;
            % end

            % 确定起始目录
            if isfolder(app.SelectedExperiment)
                startPath = app.SelectedExperiment;
            elseif isfile(app.SelectedExperiment)
                [startPath, ~, ~] = fileparts(app.SelectedExperiment);
            else
                startPath = pwd;
            end
            
            % 打开文件选择对话框
            [selectedFiles, selectedPath] = uigetfile('*.mat', '选择MAT文件', ...
                startPath, 'MultiSelect', 'on');

            % 文件选择后置顶UI（无论是否取消）
            figure(app.UIFigure);

            if isequal(selectedFiles, 0)
                return;
            end
            
            % 确保files是cell数组
            if ~iscell(selectedFiles)
                selectedFiles = {selectedFiles};
            end
            
            % 清空现有数据
            app.MatFiles = {};
            app.MatData = {};
            app.AllFields = {};
            app.CurrentIndex = 1;

            % 清空预处理相关数据
            app.PreprocessingResults = {};
            app.CurrentPrepIndex = 1;  % 重置为原图

            % 读取第一级目录Excel中的字段显示名称和单位
            [app.FieldDisplayNames, app.FieldUnits] = readFieldNamesFromLevel1Excel(app, selectedPath);

            % 创建进度对话框
            d = uiprogressdlg(app.UIFigure, 'Title', '加载数据', ...
                'Message', '正在加载MAT文件...', 'Cancelable', 'on');
            
            % 加载文件
            successCount = 0;
            
            for i = 1:length(selectedFiles)
                d.Value = i / length(selectedFiles);
                d.Message = sprintf('加载文件 %d/%d: %s', i, length(selectedFiles), selectedFiles{i});
                
                if d.CancelRequested
                    break;
                end
                
                try
                    fullPath = fullfile(selectedPath, selectedFiles{i});
                    
                    if ~isfile(fullPath)
                        continue;
                    end
                    
                    % 容错加载方法
                    loadSuccess = false;
                    data = struct();
                    
                    % 方法1: 尝试 load
                    try
                        data = load(fullPath);
                        loadSuccess = true;
                    catch
                        % load 失败，尝试 matfile
                    end
                    
                    % 方法2: 使用 matfile 逐个读取（跳过损坏变量）
                    if ~loadSuccess
                        try
                            m = matfile(fullPath);
                            varList = who(m);
                            
                            for vIdx = 1:length(varList)
                                varName = varList{vIdx};
                                
                                % 跳过元数据
                                if startsWith(varName, '__')
                                    continue;
                                end
                                
                                try
                                    % 尝试读取该变量
                                    data.(varName) = m.(varName);
                                catch
                                    % 跳过损坏的变量，标记为读取失败
                                    data.(varName) = '(读取失败)';
                                end
                            end
                            
                        catch
                            % matfile 也失败，跳过该文件
                            continue;
                        end
                    end
                    
                    % 查找矩阵字段
                    fieldNames = fieldnames(data);
                    matrixField = '';
                    
                    % 优先级1: 查找 complex_matrix
                    if isfield(data, 'complex_matrix')
                        value = data.complex_matrix;
                        if isnumeric(value) && ~isstruct(value) && numel(value) > 1
                            matrixField = 'complex_matrix';
                        end
                    end
                    
                    % 优先级2: 查找常见变量名
                    if isempty(matrixField)
                        commonNames = {'signal', 'randomMatrix', 'randomVector', 'matrix', 'vector', 'data'};
                        for k = 1:length(commonNames)
                            if isfield(data, commonNames{k})
                                value = data.(commonNames{k});
                                if isnumeric(value) && ~isstruct(value) && numel(value) > 1
                                    matrixField = commonNames{k};
                                    break;
                                end
                            end
                        end
                    end
                    
                    % 优先级3: 遍历所有字段
                    if isempty(matrixField)
                        for j = 1:length(fieldNames)
                            fieldName = fieldNames{j};
                            
                            % 跳过元数据
                            if startsWith(fieldName, '__')
                                continue;
                            end
                            
                            value = data.(fieldName);
                            
                            if isnumeric(value) && ~isstruct(value) && numel(value) > 1
                                matrixField = fieldName;
                                break;
                            end
                        end
                    end
                    
                    if ~isempty(matrixField)
                        % 保存数据
                        complexMatrix = data.(matrixField);
                        if ~isreal(complexMatrix)
                            data.complex_matrix = complex(complexMatrix);
                        else
                            data.complex_matrix = double(complexMatrix);
                        end
                        
                        data.original_matrix_field = matrixField;
                        
                        if ~strcmp(matrixField, 'complex_matrix')
                            data = rmfield(data, matrixField);
                        end
                        
                        % 统一帧信息字段名为 frame_info
                        % 规则：mat文件中只有两个变量，一个是矩阵/向量（绘图用），一个是struct（帧信息）
                        fieldNames = fieldnames(data);
                        structFields = {};
                        
                        % 找出所有struct类型的字段（排除已处理的complex_matrix和特殊字段）
                        for k = 1:length(fieldNames)
                            fieldName = fieldNames{k};
                            if ~strcmp(fieldName, 'complex_matrix') && ...
                               ~strcmp(fieldName, 'original_matrix_field') && ...
                               ~startsWith(fieldName, '__') && ...
                               isfield(data, fieldName) && ...
                               isstruct(data.(fieldName))
                                structFields{end+1} = fieldName;
                            end
                        end
                        
                        % 如果有struct字段且不叫frame_info，统一重命名为frame_info
                        if ~isempty(structFields)
                            % 只处理第一个struct字段（按照规则应该只有一个帧信息）
                            originalName = structFields{1};
                            if ~strcmp(originalName, 'frame_info')
                                data.frame_info = data.(originalName);
                                data = rmfield(data, originalName);
                                % 记录原始字段名
                                % data.original_frame_info_field = originalName;
                            end
                        end

                        app.MatFiles{end+1} = fullPath;
                        app.MatData{end+1} = data;
                        
                        % 收集字段（排除特殊字段和损坏字段）
                        for j = 1:length(fieldNames)
                            fieldName = fieldNames{j};
                            if ~strcmp(fieldName, 'complex_matrix') && ...
                               ~strcmp(fieldName, 'original_matrix_field') && ...
                               ~startsWith(fieldName, '__') && ...
                               isfield(data, fieldName)
                                % 检查是否是损坏标记
                                if ~(ischar(data.(fieldName)) && strcmp(data.(fieldName), '(读取失败)'))
                                    app.AllFields{end+1} = fieldName;
                                end
                            end
                        end
                        
                        successCount = successCount + 1;
                    end
                    
                catch
                    % 静默跳过失败的文件
                    continue;
                end
            end
            
            close(d);
            
            % 去重字段
            app.AllFields = unique(app.AllFields);
            
            if isempty(app.MatData)
                uialert(app.UIFigure, '未能加载有效的MAT文件', '错误');
                return;
            end

            % 更新UI状态
            app.StatusLabel.Text = sprintf('已加载 %d 个文件', length(app.MatData));
            app.StatusLabel.FontColor = [0 0.5 0];
            
            % 启用控件
            numFrames = length(app.MatData);
            app.FrameSlider.Enable = 'on';
            
            if numFrames > 1
                app.FrameSlider.Limits = [1 numFrames];
                
                % 智能计算刻度间隔（目标：显示8-15个刻度）
                targetTickCount = 10;  % 目标刻度数量
                rawInterval = numFrames / targetTickCount;
                
                % 将间隔圆整到合适的值（1, 2, 5, 10, 20, 50, 100, 200, 500, 1000...）
                magnitude = 10^floor(log10(rawInterval));  % 数量级
                normalized = rawInterval / magnitude;       % 归一化到1-10
                
                if normalized < 2
                    tickInterval = 1 * magnitude;
                elseif normalized < 5
                    tickInterval = 2 * magnitude;
                elseif normalized < 10
                    tickInterval = 5 * magnitude;
                else
                    tickInterval = 10 * magnitude;
                end
                
                % 生成刻度
                app.FrameSlider.MajorTicks = unique([1:tickInterval:numFrames, numFrames]);
                
                app.PrevBtn.Enable = 'on';
                app.NextBtn.Enable = 'on';
                app.AutoPlayBtn.Enable = 'on';
            else
                app.FrameSlider.Limits = [1 2];
                app.FrameSlider.MajorTicks = [1 2];
                app.FrameSlider.Enable = 'off';
                app.PrevBtn.Enable = 'off';
                app.NextBtn.Enable = 'off';
                app.AutoPlayBtn.Enable = 'off';
            end
            
            app.FrameSlider.Value = 1;
            app.JumpBtn.Enable = 'on';
            app.SelectAllBtn.Enable = 'on';
            app.DeselectAllBtn.Enable = 'on';
            app.ExportBtn.Enable = 'on';
            
            % 显示第一帧
            app.CurrentIndex = 1;
            app.FrameSlider.Value = 1;
            displayCurrentImage(app);  % 这一行不要误删
            updateFrameInfoDisplay(app);
            updateDisplayButtonsState(app);
            updateImageInfoDisplay(app);

            % 创建字段复选框
            createFieldCheckboxes(app);
            
            % 启用预处理功能
            app.AddPrepBtn.Enable = 'on';
            app.ShowPrep2Btn.Enable = 'on';  % 启用非相参积累按钮
            app.ShowPrep1Btn.Enable = 'on';  % 启用CFAR检测按钮
            app.ShowCoherentBtn.Enable = 'off';  % 非相参识别按钮初始禁用
            app.ShowDetectionBtn.Enable = 'off';  % 多维识别按钮初始禁用

            % 初始化预处理结果存储
            % 列：1=保留, 2=CFAR, 3=非相参积累, 4=自定义, 5=相参积累, 6=检测, 7=识别
            if isempty(app.PreprocessingResults)
                app.PreprocessingResults = cell(length(app.MatData), 7);
            end

            % 更新预处理控件显示（重置为初始状态）
            updatePreprocessingControls(app);

            % 将GUI窗口置顶
            figure(app.UIFigure);
            drawnow;
        end
        
        function updateImageInfoDisplay(app)
            % 更新图像显示区上方的信息
            
            % 从试验背景信息表格中读取数据
            excelData = app.ExcelTable.Data;
            
            if isempty(excelData)
                app.InfoLine1Label.Text = '';
                app.InfoLine2Label.Text = '';
                return;
            end
            
            % 提取需要的字段
            modelName = '';
            testTime = '';
            testLocation = '';
            testPurpose = '';
            
            for i = 1:size(excelData, 1)
                fieldName = excelData{i, 1};
                fieldValue = excelData{i, 2};
                
                if strcmp(fieldName, '型号名称')
                    modelName = fieldValue;
                elseif strcmp(fieldName, '试验时间')
                    testTime = fieldValue;
                elseif strcmp(fieldName, '试验地点')
                    testLocation = fieldValue;
                elseif strcmp(fieldName, '试验目的')
                    testPurpose = fieldValue;
                end
            end
            
            % 判断当前数据模式
            dataMode = '';
            
            if ~isempty(app.MatData) && app.CurrentIndex > 0 && app.CurrentIndex <= length(app.MatData)
                currentData = app.MatData{app.CurrentIndex};
                
                % 获取当前文件名
                [~, filename] = fileparts(app.MatFiles{app.CurrentIndex});
                
                % 判断是否是SAR数据
                if startsWith(lower(filename), 'sar')
                    dataMode = 'SAR模式';
                else
                    % 获取complex_matrix字段
                    if isfield(currentData, 'complex_matrix')
                        complexMatrix = currentData.complex_matrix;
                        
                        % 判断是向量还是矩阵
                        if isvector(complexMatrix) && ~isscalar(complexMatrix)
                            % 向量数据 = PD模式
                            dataMode = 'PD模式';
                        elseif ismatrix(complexMatrix) && ~isvector(complexMatrix)
                            % 矩阵数据 = PC模式
                            dataMode = 'PC模式';
                        end
                    end
                end
            end
            
            % 构建第一行信息
            line1Parts = {};
            if ~isempty(modelName)
                line1Parts{end+1} = modelName;
            end
            if ~isempty(testTime)
                line1Parts{end+1} = testTime;
            end
            if ~isempty(testLocation)
                line1Parts{end+1} = testLocation;
            end
            if ~isempty(dataMode)
                line1Parts{end+1} = dataMode;
            end
            
            if ~isempty(line1Parts)
                app.InfoLine1Label.Text = strjoin(line1Parts, ' - ');
            else
                app.InfoLine1Label.Text = '';
            end
            
            % 构建第二行信息
            if ~isempty(testPurpose)
                app.InfoLine2Label.Text = ['试验目的：', testPurpose];
            else
                app.InfoLine2Label.Text = '';
            end
        end

        % ==================== 显示相关函数 ====================
        
        function displayCurrentImage(app)
            % 显示当前帧图像 - 根据预处理结果自动显示多视图

            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end

            % 自动播放时强制仅显示原图，关闭其他子图
            if app.AutoPlayActive
                displaySingleView(app);
            else
                % 判断当前帧是否有预处理结果
                hasResults = false;
                if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                    % 检查是否有任何预处理结果（第2-4列）
                    for i = 2:4
                        if ~isempty(app.PreprocessingResults{app.CurrentIndex, i})
                            hasResults = true;
                            break;
                        end
                    end
                end

                % 如果有预处理结果，使用多视图显示；否则使用单视图
                if hasResults
                    updateMultiView(app);
                else
                    displaySingleView(app);
                end
            end
            
            % 更新帧信息标签
            [~, filename, ext] = fileparts(app.MatFiles{app.CurrentIndex});
            app.FrameInfoLabel.Text = sprintf('【%d/%d】%s%s', ...
                app.CurrentIndex, length(app.MatData), filename, ext);
        end
        
        function displaySingleView(app)
            % 单视图显示（原有逻辑）
            
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            
            % 判断文件名是否为SAR
            [~, filename] = fileparts(app.MatFiles{app.CurrentIndex});
            isSAR = startsWith(lower(filename), 'sar');
            
            % 获取当前播放方式
            playMode = app.PlayModeCombo.Value;
            
            % === 关键：重置所有axes的布局 ===
            % 隐藏其他axes
            app.ImageAxes2.Visible = 'off';
            app.ImageAxes3.Visible = 'off';
            app.ImageAxes4.Visible = 'off';
            
            % 显示并重置ImageAxes1占满整个区域
            app.ImageAxes1.Visible = 'on';
            app.ImageAxes1.Layout.Row = [1 2];
            app.ImageAxes1.Layout.Column = [1 2];
            
            % 清空所有图像
            cla(app.ImageAxes1);
            cla(app.ImageAxes2);
            cla(app.ImageAxes3);
            cla(app.ImageAxes4);
            
            % 显示图像
            if isSAR
                displaySARPreview(app, complexMatrix);
            elseif isvector(complexMatrix)
                displayWaveformPreview(app, complexMatrix);
            else
                switch playMode
                    case '原图'
                        displayMatrixImagesc(app, complexMatrix, false);
                    case '原图dB'
                        displayMatrixImagesc(app, complexMatrix, true);
                    case '3D图像'
                        displayMatrixMesh(app, complexMatrix, false);
                    case '3D图像dB'
                        displayMatrixMesh(app, complexMatrix, true);
                end
            end
        end
        
        
        function displaySARPreview(app, complexMatrix)
            % 显示SAR预览图
            % ===== 重置为2D视角 =====
            view(app.ImageAxes1, 2);

            amplitudeMatrix = abs(complexMatrix);
            normalizedMatrix = mat2gray(amplitudeMatrix);
            [rows, cols] = size(normalizedMatrix);
            
            imshow(normalizedMatrix, 'Parent', app.ImageAxes1);
            colormap(app.ImageAxes1, gray);
            axis(app.ImageAxes1, 'on');
            
            x_margin = cols * 0.05;
            y_margin = rows * 0.05;
            xlim(app.ImageAxes1, [1 - x_margin, cols + x_margin]);
            ylim(app.ImageAxes1, [1 - y_margin, rows + y_margin]);
            
            set(app.ImageAxes1, 'DataAspectRatioMode', 'auto');
            app.ImageAxes1.Box = 'on';
            app.ImageAxes1.XTickMode = 'auto';
            app.ImageAxes1.YTickMode = 'auto';
        end
        
        function displayWaveformPreview(app, complexMatrix)
            % 显示时域波形预览图
            
            % 重置为2D视角
            view(app.ImageAxes1, 2);
            
            vectorData = complexMatrix(:);
            
            if isreal(vectorData)
                % 实数向量
                plot(app.ImageAxes1, 1:length(vectorData), vectorData, 'b-', 'LineWidth', 1);
                yMin = min(vectorData);
                yMax = max(vectorData);
            else
                % 复数向量
                plot(app.ImageAxes1, 1:length(vectorData), real(vectorData), 'b-', 'DisplayName', '实部');
                hold(app.ImageAxes1, 'on');
                plot(app.ImageAxes1, 1:length(vectorData), imag(vectorData), 'r-', 'DisplayName', '虚部');
                plot(app.ImageAxes1, 1:length(vectorData), abs(vectorData), 'k-', 'LineWidth', 1.5, 'DisplayName', '幅值');
                hold(app.ImageAxes1, 'off');
                legend(app.ImageAxes1, 'Location', 'best');
                
                absData = abs(vectorData);
                yMin = min([min(real(vectorData)), min(imag(vectorData)), min(absData)]);
                yMax = max([max(real(vectorData)), max(imag(vectorData)), max(absData)]);
            end
            
            xlabel(app.ImageAxes1, '样本点');
            ylabel(app.ImageAxes1, '幅值');

            grid(app.ImageAxes1, 'on');
            
            % 设置Y轴范围（留10%边距）
            yRange = yMax - yMin;
            if yRange > 0
                ylim(app.ImageAxes1, [yMin - 0.1*yRange, yMax + 0.1*yRange]);
            else
                ylim(app.ImageAxes1, [yMin - 0.1, yMax + 0.1]);
            end
            
            % X轴也留边距
            xlim(app.ImageAxes1, [1 - length(vectorData)*0.02, length(vectorData) + length(vectorData)*0.02]);
            
            % ===== 关键：显示坐标轴刻度和标签 =====
            app.ImageAxes1.XAxisLocation = 'bottom';
            app.ImageAxes1.YAxisLocation = 'left';
            app.ImageAxes1.XTickMode = 'auto';
            app.ImageAxes1.YTickMode = 'auto';
            app.ImageAxes1.XTickLabelMode = 'auto';
            app.ImageAxes1.YTickLabelMode = 'auto';
            app.ImageAxes1.Box = 'on';
            app.ImageAxes1.YDir = 'normal'; % Y轴方向
            app.ImageAxes1.Visible = 'on';  % 确保坐标轴可见
        end
        
        function displayMatrixImagesc(app, complexMatrix, useDB)
            % ===== 重置为2D视角 =====
            view(app.ImageAxes1, 2);  % 强制设置为2D视角（从3D切换回来的时候）
            
            % 显示矩阵的imagesc图像
            amplitudeMatrix = abs(complexMatrix);
            
            if useDB
                % dB处理
                displayMatrix = 20 * log10(amplitudeMatrix + eps);
            else
                displayMatrix = amplitudeMatrix;
            end
            
            [rows, cols] = size(displayMatrix);
            
            imagesc(app.ImageAxes1, [1 cols], [1 rows], displayMatrix);
            colormap(app.ImageAxes1, parula);
            
            % ===== 关键修复：强制重置颜色映射范围 =====
            caxis(app.ImageAxes1, [min(displayMatrix(:)), max(displayMatrix(:))]);
            % 或者使用自动范围
            % caxis(app.ImageAxes1, 'auto');
            
            xlabel(app.ImageAxes1, '距离');
            ylabel(app.ImageAxes1, '多普勒');
            
            axis(app.ImageAxes1, 'tight');
            set(app.ImageAxes1, 'DataAspectRatioMode', 'auto');
            app.ImageAxes1.Box = 'on';
        
            % ===== 添加：显示坐标轴刻度 =====
            app.ImageAxes1.XTickMode = 'auto';
            app.ImageAxes1.YTickMode = 'auto';
            app.ImageAxes1.XTickLabelMode = 'auto';
            app.ImageAxes1.YTickLabelMode = 'auto';
            
            x_margin = cols * 0.05;
            y_margin = rows * 0.05;
            xlim(app.ImageAxes1, [1 - x_margin, cols + x_margin]);
            ylim(app.ImageAxes1, [1 - y_margin, rows + y_margin]);
            app.ImageAxes1.YDir = 'normal';  % 添加：Y轴方向从下到上
            app.ImageAxes1.Visible = 'on';    % 添加：确保坐标轴可见
        end
        
        function displayMatrixMesh(app, complexMatrix, useDB)
            % 显示矩阵的mesh图像
            amplitudeMatrix = abs(complexMatrix);
            
            if useDB
                % dB处理
                displayMatrix = 20 * log10(amplitudeMatrix + eps);
                zlabelStr = '幅值 (dB)';
            else
                displayMatrix = amplitudeMatrix;
                zlabelStr = '幅值';
            end
            
            [rows, cols] = size(displayMatrix);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            % 清空axes并重新设置为3D
            cla(app.ImageAxes1);
            view(app.ImageAxes1, 3);  % 设置为3D视角
            
            % 绘制mesh
            mesh(app.ImageAxes1, X, Y, displayMatrix);
            colormap(app.ImageAxes1, parula);
            
            xlabel(app.ImageAxes1, '距离');
            ylabel(app.ImageAxes1, '多普勒');
            zlabel(app.ImageAxes1, zlabelStr);
            
            view(app.ImageAxes1, 45, 30);
            grid(app.ImageAxes1, 'on');
            app.ImageAxes1.Box = 'on';
            app.ImageAxes1.Visible = 'on';  % 添加：确保坐标轴可见

            % ===== 添加：显示坐标轴刻度 =====
            app.ImageAxes1.XTickMode = 'auto';
            app.ImageAxes1.YTickMode = 'auto';
            app.ImageAxes1.ZTickMode = 'auto';
            app.ImageAxes1.XTickLabelMode = 'auto';
            app.ImageAxes1.YTickLabelMode = 'auto';
            app.ImageAxes1.ZTickLabelMode = 'auto';
        end
        
        function updateFrameInfoDisplay(app)
            % 更新帧信息显示（表格方式）
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                app.FieldTable.Data = {};
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            fieldNames = fieldnames(data);
            
            % 构建表格数据
            tableData = {};
            rowIndex = 1;
            
            % 遍历所有字段
            for i = 1:length(fieldNames)
                fieldName = fieldNames{i};
                
                % 跳过 complex_matrix 和 original_matrix_field
                if strcmp(fieldName, 'complex_matrix') || strcmp(fieldName, 'original_matrix_field')
                    continue;
                end
                
                value = data.(fieldName);
                
                % 如果是frame_info且是struct，展开显示其字段（但不递归展开）
                if strcmp(fieldName, 'frame_info') && isstruct(value)
                    structFields = fieldnames(value);
                    for j = 1:length(structFields)
                        subFieldName = structFields{j};
                        subValue = value.(subFieldName);
                        
                        % 格式化字段值
                        [valueStr, dataType] = formatFieldValueForTable(app, subValue);

                        % 使用从Excel读取的字段名称
                        if rowIndex <= length(app.FieldDisplayNames)
                            tableData{rowIndex, 1} = app.FieldDisplayNames{rowIndex};
                        else
                            tableData{rowIndex, 1} = sprintf('字段%d', rowIndex);
                        end

                        % 追加单位到字段值（如果有的话）
                        if rowIndex <= length(app.FieldUnits) && ~isempty(app.FieldUnits{rowIndex})
                            valueStr = [valueStr, app.FieldUnits{rowIndex}];
                        end

                        tableData{rowIndex, 2} = subFieldName;  % 只显示字段名，不带frame_info前缀
                        tableData{rowIndex, 3} = valueStr;
                        tableData{rowIndex, 4} = dataType;
                        
                        rowIndex = rowIndex + 1;
                    end
                else
                    % 其他字段正常显示
                    [valueStr, dataType] = formatFieldValueForTable(app, value);

                    if rowIndex <= length(app.FieldDisplayNames)
                        tableData{rowIndex, 1} = app.FieldDisplayNames{rowIndex};
                    else
                        tableData{rowIndex, 1} = sprintf('字段%d', rowIndex);
                    end

                    % 追加单位到字段值（如果有的话）
                    if rowIndex <= length(app.FieldUnits) && ~isempty(app.FieldUnits{rowIndex})
                        valueStr = [valueStr, app.FieldUnits{rowIndex}];
                    end

                    tableData{rowIndex, 2} = fieldName;
                    tableData{rowIndex, 3} = valueStr;
                    tableData{rowIndex, 4} = dataType;
                    rowIndex = rowIndex + 1;
                end
            end
            
            % 更新表格显示
            app.FieldTable.Data = tableData;
        end
        
        function onFieldTableDoubleClick(app, event)
            % 处理字段表格双击事件，显示struct详细信息
            
            % MATLAB的uitable不直接支持双击事件，需要用定时器模拟
            % 简化方案：单击即可查看
            
            if isempty(event.Indices) || isempty(app.MatData)
                return;
            end
            
            row = event.Indices(1);
            tableData = app.FieldTable.Data;
            
            if row > size(tableData, 1)
                return;
            end
            
            % 获取字段信息
            fieldName = tableData{row, 2};
            dataType = tableData{row, 4};
            
            % 只对struct类型响应
            if ~strcmp(dataType, 'struct')
                return;
            end
            
            % 获取当前数据
            currentData = app.MatData{app.CurrentIndex};
            
            % 获取struct值
            if isfield(currentData, 'frame_info') && isfield(currentData.frame_info, fieldName)
                structValue = currentData.frame_info.(fieldName);
            elseif isfield(currentData, fieldName)
                structValue = currentData.(fieldName);
            else
                return;
            end
            
            if ~isstruct(structValue)
                return;
            end
            
            % 显示struct详情窗口
            showStructDetailDialog(app, fieldName, structValue);
        end
        
        function showStructDetailDialog(app, structName, structValue)
            % 显示struct详情对话框
            
            % 创建对话框（先设置为不可见，避免显示移动过程）
            dlg = uifigure('Name', ['结构体详情: ' structName], ...
                'Position', [100 100 500 400], ...
                'WindowStyle', 'modal', ...
                'Visible', 'off');

            % 居中显示弹窗
            movegui(dlg, 'center');

            % 设置为可见
            dlg.Visible = 'on';

            % 置顶弹窗
            figure(app.UIFigure);  % 先置顶主UI
            figure(dlg);           % 再置顶弹窗

            % 创建布局
            mainLayout = uigridlayout(dlg, [2, 1]);
            mainLayout.RowHeight = {'1x', 50};
            mainLayout.Padding = [10 10 10 10];
            
            % 创建表格显示struct字段
            structTable = uitable(mainLayout);
            structTable.Layout.Row = 1;
            structTable.Layout.Column = 1;
            structTable.ColumnName = {'字段', '值'};
            structTable.RowName = {};
            structTable.ColumnWidth = {200, 'auto'};
            structTable.ColumnEditable = false;
            
            % 填充数据
            fieldNames = fieldnames(structValue);
            tableData = cell(length(fieldNames), 2);
            
            for i = 1:length(fieldNames)
                fieldName = fieldNames{i};
                fieldValue = structValue.(fieldName);
                
                % 格式化值
                if isnumeric(fieldValue)
                    if isscalar(fieldValue)
                        if isreal(fieldValue)
                            valueStr = sprintf('%.6g', fieldValue);
                        else
                            valueStr = sprintf('%.6g + %.6gi', real(fieldValue), imag(fieldValue));
                        end
                    else
                        valueStr = sprintf('[%s]', mat2str(size(fieldValue)));
                    end
                elseif ischar(fieldValue) || isstring(fieldValue)
                    valueStr = char(fieldValue);
                elseif islogical(fieldValue)
                    valueStr = char(string(fieldValue));
                elseif isstruct(fieldValue)
                    valueStr = sprintf('%dx%d struct', size(fieldValue, 1), size(fieldValue, 2));
                elseif iscell(fieldValue)
                    valueStr = sprintf('{%s}', mat2str(size(fieldValue)));
                else
                    valueStr = sprintf('[%s]', class(fieldValue));
                end
                
                tableData{i, 1} = fieldName;
                tableData{i, 2} = valueStr;
            end
            
            structTable.Data = tableData;
            
            % 创建关闭按钮
            btnLayout = uigridlayout(mainLayout, [1, 3]);
            btnLayout.Layout.Row = 2;
            btnLayout.Layout.Column = 1;
            btnLayout.ColumnWidth = {'1x', 100, '1x'};
            
            closeBtn = uibutton(btnLayout, 'push');
            closeBtn.Text = '关闭';
            closeBtn.Layout.Row = 1;
            closeBtn.Layout.Column = 2;
            closeBtn.ButtonPushedFcn = @(~,~) close(dlg);
        end

        function tableData = addStructFieldsToTable(app, tableData, structValue, prefix, startRow, level)
            % 递归添加struct的所有字段
            structFields = fieldnames(structValue);
            
            for j = 1:length(structFields)
                fieldName = structFields{j};
                fieldValue = structValue.(fieldName);
                
                % 构建完整字段名
                if isempty(prefix)
                    fullFieldName = fieldName;
                else
                    fullFieldName = sprintf('%s.%s', prefix, fieldName);
                end
                
                % 格式化字段值
                [valueStr, dataType] = formatFieldValueForTable(app, fieldValue);
                
                rowIndex = size(tableData, 1) + 1;
                
                % 使用缩进表示层级
                indent = repmat('  ', 1, level);
                
                % 显示名称列（从Excel读取或默认）
                if rowIndex <= length(app.FieldDisplayNames)
                    tableData{rowIndex, 1} = app.FieldDisplayNames{rowIndex};
                else
                    tableData{rowIndex, 1} = sprintf('字段%d', rowIndex);
                end
                
                % 字段名列
                tableData{rowIndex, 2} = [indent, fieldName];
                
                % 值列
                if isstruct(fieldValue)
                    tableData{rowIndex, 3} = sprintf('[struct %d字段]', length(fieldnames(fieldValue)));
                else
                    tableData{rowIndex, 3} = valueStr;
                end
                
                % 类型列
                tableData{rowIndex, 4} = dataType;
                
                % 如果是struct，递归添加子字段
                if isstruct(fieldValue)
                    tableData = addStructFieldsToTable(app, tableData, fieldValue, fullFieldName, rowIndex + 1, level + 1);
                end
            end
        end
        
        function [tableData, nextRow] = addFieldToTable(app, tableData, fieldName, value, rowIndex, level)
            % 添加单个字段到表格
            [valueStr, dataType] = formatFieldValueForTable(app, value);
            
            indent = repmat('  ', 1, level);
            
            if rowIndex <= length(app.FieldDisplayNames)
                tableData{rowIndex, 1} = app.FieldDisplayNames{rowIndex};
            else
                tableData{rowIndex, 1} = sprintf('字段%d', rowIndex);
            end
            
            tableData{rowIndex, 2} = [indent, fieldName];
            
            if isstruct(value)
                tableData{rowIndex, 3} = sprintf('[struct %d字段]', length(fieldnames(value)));
            else
                tableData{rowIndex, 3} = valueStr;
            end
            
            tableData{rowIndex, 4} = dataType;
            
            nextRow = rowIndex + 1;
            
            % 如果是struct，递归添加
            if isstruct(value)
                tableData = addStructFieldsToTable(app, tableData, value, fieldName, nextRow, level + 1);
                nextRow = size(tableData, 1) + 1;
            end
        end
        
        function [valueStr, dataType] = formatFieldValueForTable(app, value)
            % 格式化字段值用于表格显示
            % 返回：[值的字符串表示, 数据类型]
            
            if ischar(value) || isstring(value)
                % 字符串
                valueStr = char(value);
                if contains(class(value), 'string')
                    dataType = 'string';
                else
                    dataType = sprintf('char[%d]', length(value));
                end
                
            elseif isnumeric(value)
                if isscalar(value)
                    % 标量数值
                    if isreal(value)
                        valueStr = sprintf('%.6g', value);
                    else
                        valueStr = sprintf('%.6g + %.6gi', real(value), imag(value));
                    end
                    dataType = class(value);
                else
                    % 数组
                    sz = size(value);
                    if length(sz) == 2 && (sz(1) == 1 || sz(2) == 1)
                        % 向量
                        if length(value) <= 5
                            % 短向量：显示所有值
                            if isreal(value)
                                valueStr = sprintf('[%s]', num2str(value(:)', '%.4g '));
                            else
                                valueStr = sprintf('[复数向量 %d个元素]', length(value));
                            end
                        else
                            % 长向量：显示大小
                            valueStr = sprintf('[向量 %d个元素]', length(value));
                        end
                    else
                        % 矩阵
                        valueStr = sprintf('[矩阵 %s]', mat2str(sz));
                    end
                    dataType = sprintf('%s[]', class(value));
                end
                
            elseif iscell(value)
                % 单元数组
                if numel(value) == 1
                    cellContent = value{1};
                    if ischar(cellContent) || isstring(cellContent)
                        valueStr = char(cellContent);
                    else
                        valueStr = sprintf('{%s}', class(cellContent));
                    end
                else
                    valueStr = sprintf('{单元数组 %s}', mat2str(size(value)));
                end
                dataType = 'cell';
                
            elseif isstruct(value)
                % 结构体：显示简要信息
                numFields = length(fieldnames(value));
                if numFields > 0
                    valueStr = sprintf('%dx%d struct', size(value, 1), size(value, 2));
                else
                    valueStr = 'struct (空)';
                end
                dataType = 'struct';
                
            else
                % 其他类型
                valueStr = sprintf('(%s)', class(value));
                dataType = class(value);
            end
        end
        
        function updateDisplayButtonsState(app)
            % 根据当前帧数据类型更新按钮状态
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                % 没有数据时，所有按钮禁用
                app.WaveformBtn.Enable = 'off';
                app.OriginalBtn.Enable = 'off';
                app.DbBtn.Enable = 'off';
                app.Mesh3DBtn.Enable = 'off';
                app.DbMesh3DBtn.Enable = 'off';
                app.SARBtn.Enable = 'off';
                return;
            end
            
            % 判断文件名是否为SAR
            [~, filename] = fileparts(app.MatFiles{app.CurrentIndex});
            isSAR = startsWith(lower(filename), 'sar');
            
            % 获取当前矩阵
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            isVector = isvector(complexMatrix);
            
            if isSAR
                % ===== 第一类：SAR文件 - 只有SAR图按钮可用 =====
                app.WaveformBtn.Enable = 'off';
                app.OriginalBtn.Enable = 'off';
                app.DbBtn.Enable = 'off';
                app.Mesh3DBtn.Enable = 'off';
                app.DbMesh3DBtn.Enable = 'off';
                app.SARBtn.Enable = 'on';
                
            elseif isVector
                % ===== 第二类：向量数据 - 只有时域波形图可用 =====
                app.WaveformBtn.Enable = 'on';
                app.OriginalBtn.Enable = 'off';
                app.DbBtn.Enable = 'off';
                app.Mesh3DBtn.Enable = 'off';
                app.DbMesh3DBtn.Enable = 'off';
                app.SARBtn.Enable = 'off';
                
            else
                % ===== 第三类：矩阵数据 - 原图和3D按钮可用 =====
                app.WaveformBtn.Enable = 'off';
                app.OriginalBtn.Enable = 'on';
                app.DbBtn.Enable = 'on';
                app.Mesh3DBtn.Enable = 'on';
                app.DbMesh3DBtn.Enable = 'on';
                app.SARBtn.Enable = 'off';
            end
        end
        
        % ==================== 帧控制函数 ====================
        
        function onSliderChange(app, event)
            % 滑动条变化回调
            app.CurrentIndex = round(event.Value);
            displayCurrentImage(app);
            updateFrameInfoDisplay(app);
            updateDisplayButtonsState(app);
            updateImageInfoDisplay(app);  % 更新图像信息显示
        end
        
        function gotoPrevFrame(app)
            % 上一帧
            if app.CurrentIndex > 1
                app.CurrentIndex = app.CurrentIndex - 1;
                app.FrameSlider.Value = app.CurrentIndex;
                displayCurrentImage(app);
                updateFrameInfoDisplay(app);
                updateDisplayButtonsState(app);
                updateImageInfoDisplay(app);  % 更新图像信息显示
            end
        end
        
        function gotoNextFrame(app)
            % 下一帧 - 循环播放
            if app.CurrentIndex < length(app.MatData)
                app.CurrentIndex = app.CurrentIndex + 1;
            else
                % 到末尾后循环到第一帧
                app.CurrentIndex = 1;
            end
            
            app.FrameSlider.Value = app.CurrentIndex;
            displayCurrentImage(app);
            updateFrameInfoDisplay(app);
            updateDisplayButtonsState(app);
            updateImageInfoDisplay(app);  % 更新图像信息显示
        end
        
        function onPlayModeChanged(app) 
            % 播放方式改变时重新显示当前帧
            displayCurrentImage(app);
        end

        function onJumpInputEnter(app)
            % 回车键跳转 - 只有输入框非空时才执行
            if ~isempty(strtrim(app.JumpInput.Value))
                onJumpToFrame(app);
            end
        end
        
        function onJumpToFrame(app)
            % 跳转到指定帧
            if isempty(app.MatData)
                uialert(app.UIFigure, '请先导入数据', '提示');
                return;
            end
            
            jumpType = app.JumpCombo.Value;
            jumpValue = strtrim(app.JumpInput.Value);
            
            if isempty(jumpValue)
                uialert(app.UIFigure, '请输入跳转目标', '提示');
                return;
            end
            
            targetIndex = -1;
            
            if strcmp(jumpType, '帧号')
                % 按帧号跳转
                frameNum = str2double(jumpValue);
                if ~isnan(frameNum) && frameNum >= 1 && frameNum <= length(app.MatData)
                    targetIndex = round(frameNum);
                else
                    uialert(app.UIFigure, sprintf('帧号超出范围！有效范围: 1-%d', ...
                        length(app.MatData)), '错误');
                    return;
                end
            else
                % 按文件名跳转
                matchedFiles = {};
                for i = 1:length(app.MatFiles)
                    [~, name, ext] = fileparts(app.MatFiles{i});
                    filename = [name ext];
                    if strcmp(filename, jumpValue) || startsWith(filename, jumpValue)
                        matchedFiles{end+1} = i;
                    end
                end
                
                if isempty(matchedFiles)
                    uialert(app.UIFigure, sprintf('未找到文件名: %s', jumpValue), '错误');
                    return;
                elseif length(matchedFiles) > 1
                    uialert(app.UIFigure, sprintf('匹配到 %d 个文件，将跳转到第一个', ...
                        length(matchedFiles)), '提示');
                    targetIndex = matchedFiles{1};
                else
                    targetIndex = matchedFiles{1};
                end
            end
            
            % 执行跳转
            if targetIndex > 0
                app.CurrentIndex = targetIndex;
                app.FrameSlider.Value = targetIndex;
                displayCurrentImage(app);
                updateFrameInfoDisplay(app);
                updateDisplayButtonsState(app);
                updateImageInfoDisplay(app);
                
                % 暂时移除回调，避免清空输入框时触发
                originalCallback = app.JumpInput.ValueChangedFcn;
                app.JumpInput.ValueChangedFcn = [];  % 使用 [] 而不是 ''
                app.JumpInput.Value = '';
                drawnow;  % 强制UI更新
                app.JumpInput.ValueChangedFcn = originalCallback;
            end
        end
        
        function showJumpHelp(app)
            % 显示跳转帮助
            helpText = sprintf(['帧跳转功能说明:\n\n' ...
                '【按帧号跳转】\n' ...
                '- 输入1到总帧数之间的数字\n' ...
                '- 例如: 输入 "5" 跳转到第5帧\n\n' ...
                '【按文件名跳转】\n' ...
                '- 输入完整的文件名（包含扩展名）\n' ...
                '- 例如: radar_data_003.mat\n' ...
                '- 支持部分匹配：输入文件名开头部分即可\n\n' ...
                '提示:\n' ...
                '- 输入后按回车或点击"跳转"按钮']);
            
            uialert(app.UIFigure, helpText, '跳转功能帮助');
        end
        
        % ==================== 自动播放函数 ====================
        
        function toggleAutoPlay(app)
            % 切换自动播放状态
            if app.AutoPlayActive
                % 停止播放
                stop(app.AutoPlayTimer);
                app.AutoPlayActive = false;
                app.AutoPlayBtn.Text = '自动播放';
                app.AutoPlayBtn.BackgroundColor = [0.96 0.96 0.96];
            else
                % 开始播放
                if isempty(app.AutoPlayTimer) || ~isvalid(app.AutoPlayTimer)
                    app.AutoPlayTimer = timer('ExecutionMode', 'fixedRate', ...
                        'Period', app.AutoPlayInterval, ...
                        'TimerFcn', @(~,~) autoPlayNext(app));
                end

                % 进入自动播放时关闭所有预处理子图，仅保留原图
                closeAllPreprocessingSubViews(app);

                start(app.AutoPlayTimer);
                app.AutoPlayActive = true;
                app.AutoPlayBtn.Text = '停止播放';
                app.AutoPlayBtn.BackgroundColor = [1 0.4 0.4];
            end
        end
        
        function autoPlayNext(app)
            % 自动播放下一帧 - 使用帧间隔
            frameStep = app.FrameStepSpinner.Value;  % 获取帧间隔

            % 计算下一帧位置
            nextIndex = app.CurrentIndex + frameStep;
            
            if nextIndex <= length(app.MatData)
                % 未超出范围，跳转到下一帧
                app.CurrentIndex = nextIndex;
            else
                % 超出范围，循环到开头
                app.CurrentIndex = 1;
            end
            
            app.FrameSlider.Value = app.CurrentIndex;
            displayCurrentImage(app);
            updateFrameInfoDisplay(app);
            updateDisplayButtonsState(app);
            updateImageInfoDisplay(app);  % 更新图像信息
        end

        function closeAllPreprocessingSubViews(app)
            % 关闭所有预处理子图，仅保留原图显示

            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end

            % 确保原图保持显示
            app.ShowOriginalCheck.Value = true;

            % 清空并隐藏其他axes内容
            cla(app.ImageAxes2, 'reset');
            cla(app.ImageAxes3, 'reset');
            cla(app.ImageAxes4, 'reset');
            app.ImageAxes2.Visible = 'off';
            app.ImageAxes3.Visible = 'off';
            app.ImageAxes4.Visible = 'off';

            % 刷新当前帧显示为单图模式
            displaySingleView(app);
        end

        % ==================== 字段勾选相关函数 ====================
        
        function createFieldCheckboxes(app)
            % 创建字段复选框（从帧信息显示区读取字段名）
            
            % 清空现有复选框
            if isfield(app, 'FieldCheckboxes') && ~isempty(app.FieldCheckboxes)
                for i = 1:length(app.FieldCheckboxes)
                    if isvalid(app.FieldCheckboxes{i})
                        delete(app.FieldCheckboxes{i});
                    end
                end
            end
            
            % 初始化为空 cell 数组
            app.FieldCheckboxes = {};
            
            % 从 FieldTable 的第二列读取字段名
            if isempty(app.FieldTable.Data)
                return;
            end
            
            tableData = app.FieldTable.Data;
            numFields = size(tableData, 1);
            
            % 使用 uigridlayout 自动布局（去除上下空白）
            % 清空现有布局
            delete(app.FieldCheckboxPanel.Children);
            
            % 创建新的网格布局
            checkboxLayout = uigridlayout(app.FieldCheckboxPanel, [numFields, 1]);
            checkboxLayout.RowHeight = repmat({25}, 1, numFields);  % 每行25像素
            checkboxLayout.Padding = [5 5 5 5];
            checkboxLayout.RowSpacing = 2;
            
            % 从上到下创建复选框（顺序正确）
            for i = 1:numFields
                displayName = tableData{i, 1};  % 第1列：显示名称
                fieldName = tableData{i, 2};    % 第2列：字段名
                
                if ~isempty(fieldName)
                    checkbox = uicheckbox(checkboxLayout);
                    
                    % 使用 "显示名称 (字段名)" 的格式
                    if ~isempty(displayName) && ~strcmp(displayName, fieldName)
                        checkbox.Text = sprintf('%s (%s)', displayName, fieldName);
                    else
                        checkbox.Text = fieldName;
                    end
                    
                    checkbox.Layout.Row = i;  % 按顺序排列
                    checkbox.Layout.Column = 1;
                    checkbox.Value = true;  % 默认勾选
                    checkbox.UserData = fieldName;  % 将实际字段名存在 UserData 中
                    
                    % 添加到 cell 数组
                    app.FieldCheckboxes{end+1} = checkbox;
                end
            end
        end
        
        function selectAllFields(app)
            % 全选字段
            for i = 1:length(app.FieldCheckboxes)
                app.FieldCheckboxes{i}.Value = true;
            end
        end
        
        function deselectAllFields(app)
            % 取消全选字段
            for i = 1:length(app.FieldCheckboxes)
                app.FieldCheckboxes{i}.Value = false;
            end
        end
        
        function updateFrameStatus(app)
            % 更新帧状态显示
            frameInput = strtrim(app.FrameInputField.Value);
            
            if isempty(frameInput)
                app.FrameStatusLabel.Text = '';
                return;
            end
            
            try
                frameList = parseFrameInput(app, frameInput);
                app.FrameStatusLabel.Text = sprintf('将导出 %d 帧', length(frameList));
                app.FrameStatusLabel.FontColor = [0 0.5 0];
            catch
                app.FrameStatusLabel.Text = '格式错误';
                app.FrameStatusLabel.FontColor = [1 0 0];
            end
        end
        
        function frameList = parseFrameInput(app, inputStr)
            % 解析帧输入字符串（例：1,3-5,8）
            frameList = [];
            parts = strsplit(inputStr, ',');
            
            for i = 1:length(parts)
                part = strtrim(parts{i});
                if contains(part, '-')
                    range = strsplit(part, '-');
                    startFrame = str2double(range{1});
                    endFrame = str2double(range{2});
                    frameList = [frameList, startFrame:endFrame];
                else
                    frameList = [frameList, str2double(part)];
                end
            end
            
            % 去重并排序
            frameList = unique(frameList);
            frameList = frameList(frameList >= 1 & frameList <= length(app.MatData));
        end
        
        function showFrameHelp(app)
            % 显示帧选择帮助
            helpText = sprintf(['帧选择格式说明:\n\n' ...
                '- 单个帧: 1\n' ...
                '- 多个帧: 1,3,5\n' ...
                '- 范围: 1-5\n' ...
                '- 混合: 1,3-5,8\n\n' ...
                '留空表示导出所有帧']);
            
            uialert(app.UIFigure, helpText, '帧选择帮助');
        end
        
        % ==================== 导出函数 ====================
        
        function exportFiles(app)
            % 导出选中字段
            if isempty(app.MatData)
                uialert(app.UIFigure, '请先导入数据', '提示');
                return;
            end
            
            % 获取选中的字段（从 UserData 读取实际字段名）
            selectedFields = {};
            for i = 1:length(app.FieldCheckboxes)
                checkbox = app.FieldCheckboxes{i};
                if checkbox.Value
                    % 从 UserData 获取实际字段名
                    fieldName = checkbox.UserData;
                    selectedFields{end+1} = fieldName;
                end
            end
            
            if isempty(selectedFields)
                uialert(app.UIFigure, '请至少选择一个字段', '提示');
                return;
            end
            
            % 获取要导出的帧
            frameInput = strtrim(app.FrameInputField.Value);
            if isempty(frameInput)
                frameList = 1:length(app.MatData);
            else
                try
                    frameList = parseFrameInput(app, frameInput);
                catch
                    uialert(app.UIFigure, '帧格式错误', '错误');
                    return;
                end
            end
            
            % 选择输出目录
            outputDir = uigetdir('', '选择输出目录');
            if outputDir == 0
                return;
            end
            
            % 创建时间戳子目录
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            exportDir = fullfile(outputDir, sprintf('export_%s', timestamp));
            mkdir(exportDir);
            
            % 导出数据
            d = uiprogressdlg(app.UIFigure, 'Title', '导出数据', ...
                'Message', '正在导出...', 'Cancelable', 'on');
            
            for i = 1:length(frameList)
                d.Value = i / length(frameList);
                d.Message = sprintf('导出帧 %d/%d', i, length(frameList));
                
                if d.CancelRequested
                    break;
                end
                
                frameIdx = frameList(i);
                if frameIdx < 1 || frameIdx > length(app.MatData)
                    continue;
                end
                
                data = app.MatData{frameIdx};
                exportData = struct();
                
                % 1. 复制 complex_matrix（绘图变量）
                if isfield(data, 'complex_matrix')
                    exportData.complex_matrix = data.complex_matrix;
                end
                
                % 2. 创建新的 frame_info，只包含选中的字段
                if isfield(data, 'frame_info')
                    newFrameInfo = struct();
                    
                    for j = 1:length(selectedFields)
                        fieldName = selectedFields{j};
                        if isfield(data.frame_info, fieldName)
                            newFrameInfo.(fieldName) = data.frame_info.(fieldName);
                        end
                    end
                    
                    % 只有在有字段时才添加 frame_info
                    if ~isempty(fieldnames(newFrameInfo))
                        exportData.frame_info = newFrameInfo;
                    end
                end
                
                
                % 保存文件
                [~, name] = fileparts(app.MatFiles{frameIdx});
                outputFile = fullfile(exportDir, sprintf('%s_exported.mat', name));
                save(outputFile, '-struct', 'exportData');
            end
            
            close(d);

            uialert(app.UIFigure, sprintf('成功导出 %d 个文件到:\n%s', ...
                length(frameList), exportDir), '导出完成');

            % 将GUI窗口置顶
            figure(app.UIFigure);
            drawnow;
        end
        
        % ==================== 显示窗口函数 ====================
        
        function showTimeWaveform(app)
            % 显示时域波形图 - 使用plot
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            vectorData = complexMatrix(:);  % 转为列向量
            
            % 创建新窗口（先设置为不可见，避免显示移动过程）
            fig = uifigure('Name', '时域波形图', 'Visible', 'off');
            fig.Position = [100 100 1000 600];

            % 居中显示窗口
            movegui(fig, 'center');

            % 设置为可见
            fig.Visible = 'on';

            % 置顶窗口
            figure(app.UIFigure);  % 先置顶主UI
            figure(fig);           % 再置顶新窗口

            ax = uiaxes(fig);
            ax.Position = [80 80 850 480];
            
            % 绘制波形
            if isreal(vectorData)
                % 实数向量
                plot(ax, 1:length(vectorData), vectorData, 'b-', 'LineWidth', 1);
            else
                % 复数向量
                plot(ax, 1:length(vectorData), real(vectorData), 'b-', 'DisplayName', '实部');
                hold(ax, 'on');
                plot(ax, 1:length(vectorData), imag(vectorData), 'r-', 'DisplayName', '虚部');
                plot(ax, 1:length(vectorData), abs(vectorData), 'k-', 'LineWidth', 1.5, 'DisplayName', '幅值');
                hold(ax, 'off');
                legend(ax, 'Location', 'best');
            end
            
            xlabel(ax, '样本点');
            ylabel(ax, '幅值');
            grid(ax, 'on');
            ax.Box = 'on';
        end
        
        function showOriginalImage(app)
            % 显示原图放大 - 使用imagesc
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            amplitudeMatrix = abs(complexMatrix);
            
            % 创建新窗口（先设置为不可见，避免显示移动过程）
            fig = uifigure('Name', '原图放大', 'Visible', 'off');
            fig.Position = [100 100 1000 800];

            % 居中显示窗口
            movegui(fig, 'center');

            % 设置为可见
            fig.Visible = 'on';

            % 置顶窗口
            figure(app.UIFigure);  % 先置顶主UI
            figure(fig);           % 再置顶新窗口

            ax = uiaxes(fig);
            ax.Position = [80 80 850 680];
            
            [rows, cols] = size(amplitudeMatrix);
            
            % 使用imagesc绘制
            imagesc(ax, [1 cols], [1 rows], amplitudeMatrix);
            ax.YDir = 'normal';  % 必须在imagesc之后立即设置
            colormap(ax, parula);
            colorbar(ax);
            
            xlabel(ax, '距离');
            ylabel(ax, '多普勒');
            
            axis(ax, 'tight');
            set(ax, 'DataAspectRatioMode', 'auto');
            ax.Box = 'on';
            
            x_margin = cols * 0.05;
            y_margin = rows * 0.05;
            xlim(ax, [1 - x_margin, cols + x_margin]);
            ylim(ax, [1 - y_margin, rows + y_margin]);
            ax.Visible = 'on';
            ax.XTickLabelMode = 'auto';
            ax.YTickLabelMode = 'auto';
        end
        
        function showDbImage(app)
            % 显示dB图放大 - 对矩阵进行dB处理后使用imagesc
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            amplitudeMatrix = abs(complexMatrix);
            
            % dB处理
            dbMatrix = 20 * log10(amplitudeMatrix + eps);
            
            % 创建新窗口（先设置为不可见，避免显示移动过程）
            fig = uifigure('Name', 'dB图放大', 'Visible', 'off');
            fig.Position = [100 100 1000 800];

            % 居中显示窗口
            movegui(fig, 'center');

            % 设置为可见
            fig.Visible = 'on';

            % 置顶窗口
            figure(app.UIFigure);  % 先置顶主UI
            figure(fig);           % 再置顶新窗口

            ax = uiaxes(fig);
            ax.Position = [80 80 850 680];
            
            [rows, cols] = size(dbMatrix);
            
            % 使用imagesc绘制
            imagesc(ax, [1 cols], [1 rows], dbMatrix);
            ax.YDir = 'normal';
            colormap(ax, parula);
            colorbar(ax);
            
            xlabel(ax, '距离');
            ylabel(ax, '多普勒');
            
            axis(ax, 'tight');
            set(ax, 'DataAspectRatioMode', 'auto');
            ax.Box = 'on';
            
            x_margin = cols * 0.05;
            y_margin = rows * 0.05;
            xlim(ax, [1 - x_margin, cols + x_margin]);
            ylim(ax, [1 - y_margin, rows + y_margin]);
            ax.Visible = 'on';
        end
        
        function show3DMesh(app)
            % 显示3D Mesh图 - 对矩阵使用mesh
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            amplitudeMatrix = abs(complexMatrix);
            
            % 创建新窗口（使用传统figure）
            fig = figure('Name', '3D Mesh图', 'NumberTitle', 'off');
            fig.Position = [100 100 1000 800];
            
            ax = axes(fig);
            
            [rows, cols] = size(amplitudeMatrix);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            % 使用mesh绘制
            mesh(ax, X, Y, amplitudeMatrix);
            colormap(ax, parula);
            colorbar(ax);
            
            xlabel(ax, '距离');
            ylabel(ax, '多普勒');
            zlabel(ax, '幅值');
            
            view(ax, 45, 30);
            grid(ax, 'on');
            ax.Box = 'on';
            shading(ax, 'faceted');
        end
        
        function showDb3DMesh(app)
            % 显示dB 3D Mesh图 - 对矩阵进行dB处理后使用mesh
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            amplitudeMatrix = abs(complexMatrix);
            
            % dB处理
            dbMatrix = 20 * log10(amplitudeMatrix + eps);
            
            % 创建新窗口（使用传统figure）
            fig = figure('Name', 'dB 3D Mesh图', 'NumberTitle', 'off');
            fig.Position = [100 100 1000 800];
            
            ax = axes(fig);
            
            [rows, cols] = size(dbMatrix);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            % 使用mesh绘制
            mesh(ax, X, Y, dbMatrix);
            colormap(ax, parula);
            colorbar(ax);
            
            xlabel(ax, '距离');
            ylabel(ax, '多普勒');
            zlabel(ax, '幅值 (dB)');
            
            view(ax, 45, 30);
            grid(ax, 'on');
            ax.Box = 'on';
            shading(ax, 'faceted');
        end
        
        function showSARImage(app)
            % 显示SAR图 - 使用imshow
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            data = app.MatData{app.CurrentIndex};
            complexMatrix = data.complex_matrix;
            amplitudeMatrix = abs(complexMatrix);
            
            % 归一化到[0,1]
            normalizedMatrix = mat2gray(amplitudeMatrix);
            
            % 获取矩阵尺寸
            [rows, cols] = size(normalizedMatrix);
            
            % 创建新窗口（先设置为不可见，避免显示移动过程）
            fig = uifigure('Name', 'SAR图', 'Visible', 'off');
            fig.Position = [100 100 1000 800];

            % 居中显示窗口
            movegui(fig, 'center');

            % 设置为可见
            fig.Visible = 'on';

            % 置顶窗口
            figure(app.UIFigure);  % 先置顶主UI
            figure(fig);           % 再置顶新窗口

            ax = uiaxes(fig);
            ax.Position = [80 80 850 680];
            
            % 使用imshow显示
            imshow(normalizedMatrix, 'Parent', ax);
            colormap(ax, gray);
            
            % imshow会隐藏坐标轴，需要重新启用
            axis(ax, 'on');
            
            % 设置坐标轴标签
            title(ax, sprintf('帧 %d', app.CurrentIndex));
            
            % 设置坐标轴范围和边距（5%）
            x_margin = cols * 0.05;
            y_margin = rows * 0.05;
            xlim(ax, [1 - x_margin, cols + x_margin]);
            ylim(ax, [1 - y_margin, rows + y_margin]);
            
            % 设置显示模式
            set(ax, 'DataAspectRatioMode', 'auto');
            ax.Box = 'on';
            ax.XTickMode = 'auto';
            ax.YTickMode = 'auto';
        end
        
        function onExcelDoubleClick(app, event)
            % Excel表格双击事件
            if isempty(event.Indices)
                return;
            end
            
            row = event.Indices(1);
            data = app.ExcelTable.Data;
            
            if row > size(data, 1)
                return;
            end
            
            fieldName = data{row, 1};
            fieldValue = data{row, 2};
            
            % 创建详情对话框（先设置为不可见，避免显示移动过程）
            fig = uifigure('Name', sprintf('字段详情: %s', fieldName), 'Visible', 'off');
            fig.Position = [200 200 600 400];

            % 居中显示窗口
            movegui(fig, 'center');

            % 设置为可见
            fig.Visible = 'on';

            % 置顶窗口
            figure(app.UIFigure);  % 先置顶主UI
            figure(fig);           % 再置顶新窗口

            layout = uigridlayout(fig, [3, 1]);
            layout.RowHeight = {30, '1x', 40};
            
            titleLabel = uilabel(layout);
            titleLabel.Text = sprintf('字段名: %s', fieldName);
            titleLabel.FontWeight = 'bold';
            titleLabel.Layout.Row = 1;
            
            textArea = uitextarea(layout);
            textArea.Value = sprintf('%s', fieldValue);
            textArea.Editable = 'off';
            textArea.Layout.Row = 2;
            
            closeBtn = uibutton(layout, 'push');
            closeBtn.Text = '关闭';
            closeBtn.Layout.Row = 3;
            closeBtn.ButtonPushedFcn = @(~,~) close(fig);
        end

        function updatePlayInterval(app, newInterval)  % <--- 插入在这里
            % 更新播放间隔
            app.AutoPlayInterval = newInterval;
            if ~isempty(app.AutoPlayTimer) && isvalid(app.AutoPlayTimer)
                app.AutoPlayTimer.Period = newInterval;
            end
        end 

        function valueStr = formatDisplayValue(app, value, indent)
            % 格式化值的显示（通用方法）
            % indent: 缩进空格数
            
            indentStr = repmat(' ', 1, indent);
            
            if ischar(value) || isstring(value)
                % 字符串
                valueStr = sprintf('%s%s', indentStr, char(value));
                
            elseif isnumeric(value)
                if isscalar(value)
                    % 标量数值
                    if isreal(value)
                        valueStr = sprintf('%s%.6g', indentStr, value);
                    else
                        valueStr = sprintf('%s%.6g + %.6gi', indentStr, real(value), imag(value));
                    end
                else
                    % 数组
                    sz = size(value);
                    if length(sz) == 2 && (sz(1) == 1 || sz(2) == 1)
                        % 向量
                        if length(value) <= 5
                            % 短向量：显示所有值
                            if isreal(value)
                                valueStr = sprintf('%s[%s]', indentStr, num2str(value(:)', '%.4g '));
                            else
                                valueStr = sprintf('%s[复数向量 %d个元素]', indentStr, length(value));
                            end
                        else
                            % 长向量：显示大小
                            valueStr = sprintf('%s[向量 %dx%d]', indentStr, sz(1), sz(2));
                        end
                    else
                        % 矩阵
                        valueStr = sprintf('%s[矩阵 %s]', indentStr, mat2str(sz));
                    end
                end
                
            elseif iscell(value)
                % 单元数组
                if numel(value) == 1
                    % 单个单元：显示内容
                    cellContent = value{1};
                    if ischar(cellContent) || isstring(cellContent)
                        valueStr = sprintf('%s%s', indentStr, char(cellContent));
                    else
                        valueStr = sprintf('%s{单元数组 1个元素: %s}', indentStr, class(cellContent));
                    end
                else
                    valueStr = sprintf('%s{单元数组 %s}', indentStr, mat2str(size(value)));
                end
                
            elseif isstruct(value)
                % 嵌套结构体
                valueStr = sprintf('%s(嵌套结构体 %d个字段)', indentStr, length(fieldnames(value)));
                
            else
                % 其他类型
                valueStr = sprintf('%s(%s)', indentStr, class(value));
            end
        end

        % ==================== 预处理功能函数 ====================
        
        function openPreprocessingDialog(app)
            % 打开预处理配置对话框（支持添加多个预处理）
            
            % 创建对话框（先设置为不可见，避免显示移动过程）
            dlg = uifigure('Name', '添加预处理', 'Position', [200 100 750 680], 'Visible', 'off');
            dlg.WindowStyle = 'modal';

            % 设置关闭请求回调函数，确保关闭后主UI置顶
            dlg.CloseRequestFcn = @(~,~) closeDlgAndFocusMain();

            % 居中显示弹窗
            movegui(dlg, 'center');

            % 设置为可见
            dlg.Visible = 'on';

            % 置顶弹窗
            figure(app.UIFigure);  % 先置顶主UI
            figure(dlg);           % 再置顶预处理弹窗

            % 关闭对话框并置顶主UI的函数
            function closeDlgAndFocusMain()
                delete(dlg);
                figure(app.UIFigure);  % 置顶主UI
            end

            % 添加帮助按钮到对话框右上角
            helpBtn = uibutton(dlg, 'push');
            helpBtn.Text = '❓';
            helpBtn.Position = [705 635 30 30];  % 右上角位置
            helpBtn.Tooltip = '查看脚本接口规范';
            helpBtn.ButtonPushedFcn = @(~,~) showScriptHelp();
            helpBtn.BackgroundColor = [0.95 0.95 0.95];

            mainLayout = uigridlayout(dlg, [4, 1]);
            mainLayout.RowHeight = {50, '1x', 1, 50};
            mainLayout.Padding = [15 15 15 15];
            mainLayout.RowSpacing = 10;
            
            % ========== 第1行：提示信息 ==========
            infoPanel = uipanel(mainLayout);
            infoPanel.Layout.Row = 1;
            infoPanel.BackgroundColor = [0.95 0.97 1];
            infoPanel.BorderType = 'none';
            
            infoLayout = uigridlayout(infoPanel, [1, 3]);
            infoLayout.ColumnWidth = {35, '1x', 35};  % 改为3列，最后一列放帮助按钮
            infoLayout.Padding = [10 8 10 8];

            iconLabel = uilabel(infoLayout);
            iconLabel.Text = '💡';
            iconLabel.FontSize = 20;
            iconLabel.HorizontalAlignment = 'center';
            iconLabel.Layout.Row = 1;
            iconLabel.Layout.Column = 1;
            
            textLabel = uilabel(infoLayout);
            textLabel.Text = '提示：请选择预处理类型并配置参数，系统将自动检测脚本所需参数';
            textLabel.WordWrap = 'on';
            textLabel.FontSize = 11;
            textLabel.Layout.Row = 1;
            textLabel.Layout.Column = 2;
            
            % 帮助按钮
            helpBtn = uibutton(infoLayout, 'push');
            helpBtn.Text = '❓';
            helpBtn.Layout.Row = 1;
            helpBtn.Layout.Column = 3;
            helpBtn.Tooltip = '查看脚本接口规范';
            helpBtn.ButtonPushedFcn = @(~,~) showScriptHelp();
            helpBtn.BackgroundColor = [0.85 0.90 1];
            helpBtn.FontSize = 14;
            
            % ========== 第2行：内容区域 ==========
            contentPanel = uipanel(mainLayout);
            contentPanel.Layout.Row = 2;
            contentPanel.BorderType = 'none';
            
            contentLayout = uigridlayout(contentPanel, [5, 1]);
            contentLayout.RowHeight = {65, 55, 55, 105, '1x'};  % 处理对象行高
            contentLayout.Padding = [5 5 5 5];
            contentLayout.RowSpacing = 8;
            
            % ========== 处理对象 ==========
            processObjPanel = uipanel(contentLayout);
            processObjPanel.Layout.Row = 1;
            processObjPanel.Title = '处理对象';
            processObjPanel.FontWeight = 'bold';
            processObjPanel.FontSize = 11;

            % 1行1列布局（仅下拉框）
            processObjLayout = uigridlayout(processObjPanel, [1, 1]);
            processObjLayout.RowSpacing = 5;
            processObjLayout.Padding = [10 5 10 5];

            % 处理对象下拉框
            objDropdown = uidropdown(processObjLayout);
            % 初始化下拉项：默认选项 + 当前帧原图
            objDropdown.Items = {'-- 请选择 --', '当前帧原图'};
            objDropdown.Value = '-- 请选择 --';
            objDropdown.Layout.Row = 1;
            objDropdown.Layout.Column = 1;
            objDropdown.FontSize = 12;
            objDropdown.ValueChangedFcn = @(~,~) updateProcessObjControls();

            % 初始化时更新处理对象下拉列表，添加已操作过的预处理
            updateProcessObjDropdown();

            % 初始化时检查是否有当前帧数据，有则默认选择"当前帧原图"
            if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                objDropdown.Value = '当前帧原图';
            end
            
            % ========== 预处理类型 ==========
            typePanel = uipanel(contentLayout);
            typePanel.Layout.Row = 2;
            typePanel.Title = '预处理类型';
            typePanel.FontWeight = 'bold';
            typePanel.FontSize = 11;

            typeLayout = uigridlayout(typePanel, [1, 1]);
            typeLayout.Padding = [10 5 10 5];

            prepTypeDropdown = uidropdown(typeLayout);
            % 所有可用的预处理类型（新规则：只有4种+自定义）
            allPrepTypes = {'-- 请选择 --', '非相参积累', '非相参识别', 'CFAR检测', '多维识别', '自定义...'};
            prepTypeDropdown.Items = allPrepTypes;
            prepTypeDropdown.Value = '-- 请选择 --';
            prepTypeDropdown.Layout.Row = 1;
            prepTypeDropdown.Layout.Column = 1;
            prepTypeDropdown.FontSize = 12;
            prepTypeDropdown.ValueChangedFcn = createCallbackFcn(app, @onTypeChanged, true);
            
            % ========== 自定义名称（初始隐藏）==========
            customNamePanel = uipanel(contentLayout);
            customNamePanel.Layout.Row = 3;
            customNamePanel.Title = '自定义名称';
            customNamePanel.FontWeight = 'bold';
            customNamePanel.FontSize = 11;
            customNamePanel.Visible = 'off';

            customLayout = uigridlayout(customNamePanel, [1, 1]);
            customLayout.Padding = [10 5 10 5];

            customNameField = uieditfield(customLayout, 'text');
            customNameField.Placeholder = '请输入预处理名称';
            customNameField.Layout.Row = 1;
            customNameField.Layout.Column = 1;
            customNameField.FontSize = 12;
            
            % ========== 脚本选择 ==========
            scriptPanel = uipanel(contentLayout);
            scriptPanel.Layout.Row = 4;
            scriptPanel.Title = '脚本选择';
            scriptPanel.FontWeight = 'bold';
            scriptPanel.FontSize = 11;

            % 使用grid layout布局脚本选择面板（2行1列）
            scriptLayout = uigridlayout(scriptPanel, [2, 1]);
            scriptLayout.RowHeight = {28, 38};
            scriptLayout.Padding = [10 5 10 5];
            scriptLayout.RowSpacing = 10;

            % 第1行：单选按钮组
            bg = uibuttongroup(scriptLayout);
            bg.BorderType = 'none';
            bg.Layout.Row = 1;
            bg.Layout.Column = 1;
            bg.SelectionChangedFcn = createCallbackFcn(app, @onSourceChanged, true);

            defaultScriptRadio = uiradiobutton(bg);
            defaultScriptRadio.Text = '使用默认脚本';
            defaultScriptRadio.Position = [10 5 150 20];
            defaultScriptRadio.Value = true;
            defaultScriptRadio.FontSize = 11;

            customScriptRadio = uiradiobutton(bg);
            customScriptRadio.Text = '导入自定义脚本';
            customScriptRadio.Position = [250 5 150 20];
            customScriptRadio.FontSize = 11;

            % 第2行：文件选择区域（初始隐藏）
            fileSelectionPanel = uipanel(scriptLayout);
            fileSelectionPanel.Layout.Row = 2;
            fileSelectionPanel.Layout.Column = 1;
            fileSelectionPanel.BorderType = 'none';
            fileSelectionPanel.Visible = 'off';

            % 文件选择区域内部布局：文件路径框 + 浏览按钮并排
            fileSelectionLayout = uigridlayout(fileSelectionPanel, [1, 2]);
            fileSelectionLayout.ColumnWidth = {'1x', 100};
            fileSelectionLayout.Padding = [0 0 0 0];

            % 文件路径显示框
            scriptPathField = uieditfield(fileSelectionLayout, 'text');
            scriptPathField.Layout.Row = 1;
            scriptPathField.Layout.Column = 1;
            scriptPathField.Placeholder = '未选择文件';
            scriptPathField.Editable = 'off';
            scriptPathField.FontSize = 12;

            % 浏览按钮（与处理对象按钮格式统一）
            browseBtn = uibutton(fileSelectionLayout, 'push');
            browseBtn.Text = '浏览文件';
            browseBtn.Layout.Row = 1;
            browseBtn.Layout.Column = 2;
            browseBtn.Tooltip = '选择自定义脚本文件';
            browseBtn.FontWeight = 'bold';
            browseBtn.FontSize = 10;
            browseBtn.FontColor = [0 0 0.8];
            browseBtn.ButtonPushedFcn = createCallbackFcn(app, @selectFile, true);
            
            % ========== 参数配置 ==========
            paramPanel = uipanel(contentLayout);
            paramPanel.Layout.Row = 5;
            paramPanel.Title = '参数配置';
            paramPanel.FontWeight = 'bold';
            paramPanel.FontSize = 11;

            paramLayout = uigridlayout(paramPanel, [2, 1]);
            paramLayout.RowHeight = {30, '1x'};
            paramLayout.Padding = [10 5 10 5];
            
            % 工具栏
            paramToolLayout = uigridlayout(paramLayout, [1, 1]);
            paramToolLayout.Layout.Row = 1;
            paramToolLayout.Padding = [5 5 5 5];
            
            paramHintLabel = uilabel(paramToolLayout);
            paramHintLabel.Text = '注意：预处理脚本需要遵循标准接口规范,参数将自动检测并填充，双击表格单元格可编辑参数值';
            paramHintLabel.FontSize = 11;
            paramHintLabel.FontColor = [0.5 0.5 0.5];
            paramHintLabel.Layout.Row = 1;
            paramHintLabel.Layout.Column = 1;
            
            % 参数表格
            paramTable = uitable(paramLayout);
            paramTable.Layout.Row = 2;
            paramTable.Layout.Column = 1;
            paramTable.ColumnName = {'展开', '参数名称', '参数值', '数据类型', '操作'};
            paramTable.ColumnWidth = {60, 150, 200, 100, 80};  % 增大展开列宽度，方便点击
            paramTable.RowName = {};
            paramTable.Data = cell(0, 5);
            paramTable.ColumnEditable = [false true true true false];
            paramTable.CellSelectionCallback = @handleTableClick;  % 不使用 createCallbackFcn
            paramTable.CellEditCallback = @checkFrameInfoField;
            
            % ========== 第3行：分隔线 ==========
            sep = uipanel(mainLayout);
            sep.Layout.Row = 3;
            sep.BorderType = 'line';
            sep.BackgroundColor = [0.85 0.85 0.85];
            
            % ========== 第4行：按钮区 ==========
            btnLayout = uigridlayout(mainLayout, [1, 4]);
            btnLayout.Layout.Row = 4;
            btnLayout.ColumnWidth = {'1x', 150, 100, 80};
            btnLayout.ColumnSpacing = 12;

            % 左侧：应用到所有帧复选框 + 选择帧输入框
            leftControlLayout = uigridlayout(btnLayout);
            leftControlLayout.Layout.Row = 1;
            leftControlLayout.Layout.Column = 1;
            leftControlLayout.RowHeight = {'1x'};
            leftControlLayout.ColumnWidth = {100, 60, '1x', 25};
            leftControlLayout.ColumnSpacing = 5;
            leftControlLayout.Padding = [0 5 0 5];

            % 应用到所有帧复选框
            batchApplyCheck = uicheckbox(leftControlLayout);
            batchApplyCheck.Text = '应用到所有帧';
            batchApplyCheck.Value = false;
            batchApplyCheck.Layout.Row = 1;
            batchApplyCheck.Layout.Column = 1;
            batchApplyCheck.Tooltip = '勾选后将对所有导入的数据应用此预处理';
            batchApplyCheck.FontSize = 11;

            frameSelLabel = uilabel(leftControlLayout);
            frameSelLabel.Text = '选择帧:';
            frameSelLabel.Layout.Row = 1;
            frameSelLabel.Layout.Column = 2;
            frameSelLabel.FontSize = 11;

            frameSelectionField = uieditfield(leftControlLayout, 'text');
            frameSelectionField.Placeholder = '例: 1,3-5,8';
            frameSelectionField.Layout.Row = 1;
            frameSelectionField.Layout.Column = 3;
            frameSelectionField.FontSize = 11;
            frameSelectionField.Tooltip = '输入要应用预处理的帧范围，留空则使用"应用到所有帧"选项';

            frameSelHelpBtn = uibutton(leftControlLayout, 'push');
            frameSelHelpBtn.Text = '?';
            frameSelHelpBtn.Layout.Row = 1;
            frameSelHelpBtn.Layout.Column = 4;
            frameSelHelpBtn.FontSize = 10;
            frameSelHelpBtn.Tooltip = '查看帧范围格式说明';
            frameSelHelpBtn.ButtonPushedFcn = @(~,~) showFrameSelectionHelp();
            
            applyBtn = uibutton(btnLayout, 'push');
            applyBtn.Text = '✅ 应用';
            applyBtn.Layout.Row = 1;
            applyBtn.Layout.Column = 2;
            applyBtn.BackgroundColor = [0.2 0.6 1];
            applyBtn.FontColor = [1 1 1];
            applyBtn.FontWeight = 'bold';
            applyBtn.FontSize = 13;
            applyBtn.ButtonPushedFcn = @(~,~) applyPreprocessingAndClose();
            
            cancelBtn = uibutton(btnLayout, 'push');
            cancelBtn.Text = '取消';
            cancelBtn.Layout.Row = 1;
            cancelBtn.Layout.Column = 3;
            cancelBtn.FontSize = 13;
            cancelBtn.ButtonPushedFcn = @(~,~) closeDlgAndFocusMain();
            
            % ========== 回调函数 ==========
            
            function processedItems = getProcessedPreprocessingItems(app)
                % 获取已操作过的预处理项
                processedItems = {};

                % 遍历PreprocessingList，获取已添加的预处理名称
                if ~isempty(app.PreprocessingList)
                    for i = 1:length(app.PreprocessingList)
                        prepName = app.PreprocessingList{i}.name;
                        % 避免重复添加
                        if ~any(strcmp(processedItems, prepName))
                            processedItems{end+1} = prepName;
                        end
                    end
                end

                % 也从PreprocessingResults中获取（已经执行过的预处理）
                % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                    % 检查CFAR检测列（第2列）
                    if size(app.PreprocessingResults, 2) >= 2 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 2})
                        if ~any(strcmp(processedItems, 'CFAR检测'))
                            processedItems{end+1} = 'CFAR检测';
                        end
                    end
                    % 检查非相参积累列（第3列）
                    if size(app.PreprocessingResults, 2) >= 3 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 3})
                        if ~any(strcmp(processedItems, '非相参积累'))
                            processedItems{end+1} = '非相参积累';
                        end
                    end
                    % 检查非相参识别列（第4列）
                    if size(app.PreprocessingResults, 2) >= 4 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 4})
                        result = app.PreprocessingResults{app.CurrentIndex, 4};
                        % 检查是否是非相参识别（通过type判断）
                        if isfield(result, 'preprocessing_info') && isfield(result.preprocessing_info, 'type')
                            if strcmp(result.preprocessing_info.type, '非相参识别')
                                if ~any(strcmp(processedItems, '非相参识别'))
                                    processedItems{end+1} = '非相参识别';
                                end
                            else
                                % 自定义预处理
                                prepName = result.preprocessing_info.name;
                                if ~any(strcmp(processedItems, prepName))
                                    processedItems{end+1} = prepName;
                                end
                            end
                        end
                    end
                    % 检查多维识别列（第5列）
                    if size(app.PreprocessingResults, 2) >= 5 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 5})
                        result = app.PreprocessingResults{app.CurrentIndex, 5};
                        % 检查是否是多维识别（通过type判断）
                        if isfield(result, 'preprocessing_info') && isfield(result.preprocessing_info, 'type')
                            if strcmp(result.preprocessing_info.type, '多维识别')
                                if ~any(strcmp(processedItems, '多维识别'))
                                    processedItems{end+1} = '多维识别';
                                end
                            else
                                % 自定义预处理
                                prepName = result.preprocessing_info.name;
                                if ~any(strcmp(processedItems, prepName))
                                    processedItems{end+1} = prepName;
                                end
                            end
                        end
                    end
                    % 检查第6-7列的自定义预处理
                    for col = 6:min(7, size(app.PreprocessingResults, 2))
                        if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                            result = app.PreprocessingResults{app.CurrentIndex, col};
                            % 从preprocessing_info中获取名称
                            if isfield(result, 'preprocessing_info') && isfield(result.preprocessing_info, 'name')
                                prepName = result.preprocessing_info.name;
                                if ~any(strcmp(processedItems, prepName))
                                    processedItems{end+1} = prepName;
                                end
                            end
                        end
                    end
                end
            end

            function updateProcessObjDropdown()
                % 更新处理对象下拉框，添加已操作过的预处理
                baseItems = {'-- 请选择 --', '当前帧原图'};
                processedItems = getProcessedPreprocessingItems(app);
                allItems = [baseItems, processedItems];

                % 保存当前选择
                currentValue = objDropdown.Value;

                % 更新下拉列表
                objDropdown.Items = allItems;

                % 尝试恢复之前的选择
                if any(strcmp(allItems, currentValue))
                    objDropdown.Value = currentValue;
                else
                    objDropdown.Value = '-- 请选择 --';
                end
            end

            function updateProcessObjControls()
                % 更新处理对象相关控件的状态
                selectedObj = objDropdown.Value;

                % 检查当前帧原图的有效性
                if strcmp(selectedObj, '当前帧原图') && isempty(app.MatData)
                    uialert(dlg, '当前没有加载任何数据！', '提示');
                    objDropdown.Value = '-- 请选择 --';
                    return;
                end

                % 根据处理对象更新预处理类型下拉框
                updatePrepTypeByObject();

                % 如果选择的是预处理结果，加载其输出变量到参数表格
                loadPreprocessingOutputs();
            end

            function updatePrepTypeByObject()
                % 根据处理对象过滤预处理类型（新规则：两条预处理链）
                selectedObj = objDropdown.Value;
                currentType = prepTypeDropdown.Value;

                % 根据处理对象确定可用的预处理类型
                if strcmp(selectedObj, '-- 请选择 --')
                    % 未选择处理对象时，显示提示
                    availableTypes = {'-- 请选择 --'};
                elseif strcmp(selectedObj, '当前帧原图')
                    % 处理对象是"当前帧原图"时，只能选两条链的第一步：非相参积累、CFAR检测、自定义
                    availableTypes = {'-- 请选择 --', '非相参积累', 'CFAR检测', '自定义...'};
                elseif strcmp(selectedObj, '非相参积累')
                    % 处理对象是"非相参积累"时，只能选非相参识别或自定义
                    availableTypes = {'-- 请选择 --', '非相参识别', '自定义...'};
                elseif strcmp(selectedObj, 'CFAR检测')
                    % 处理对象是"CFAR检测"时，只能选多维识别或自定义
                    availableTypes = {'-- 请选择 --', '多维识别', '自定义...'};
                else
                    % 其他已处理的预处理结果，只能选自定义
                    availableTypes = {'-- 请选择 --', '自定义...'};
                end

                % 更新下拉框选项
                prepTypeDropdown.Items = availableTypes;

                % 如果当前选择的类型不在新的列表中，重置为"-- 请选择 --"
                if ~any(strcmp(availableTypes, currentType))
                    prepTypeDropdown.Value = '-- 请选择 --';
                else
                    prepTypeDropdown.Value = currentType;
                end
            end

            % 用于存储当前输出变量的实际数据（支持展开/折叠）
            currentOutputVars = struct();

            function loadPreprocessingOutputs()
                % 当选择预处理对象时，加载其输出变量到参数表格
                selectedObj = objDropdown.Value;

                % 如果选择的是"-- 请选择 --"或"当前帧原图"，清空参数表格
                if strcmp(selectedObj, '-- 请选择 --') || strcmp(selectedObj, '当前帧原图')
                    return;
                end

                % 检查是否有预处理结果数据
                if isempty(app.PreprocessingResults) || app.CurrentIndex > size(app.PreprocessingResults, 1)
                    return;
                end

                % 查找对应的预处理结果
                prepData = [];

                % 检查是否是CFAR检测
                if strcmp(selectedObj, 'CFAR检测') && size(app.PreprocessingResults, 2) >= 2 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 2})
                    prepData = app.PreprocessingResults{app.CurrentIndex, 2};
                % 检查是否是非相参积累
                elseif strcmp(selectedObj, '非相参积累') && size(app.PreprocessingResults, 2) >= 3 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 3})
                    prepData = app.PreprocessingResults{app.CurrentIndex, 3};
                % 检查是否是非相参识别
                elseif strcmp(selectedObj, '非相参识别') && size(app.PreprocessingResults, 2) >= 4 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 4})
                    prepData = app.PreprocessingResults{app.CurrentIndex, 4};
                % 检查是否是多维识别
                elseif strcmp(selectedObj, '多维识别') && size(app.PreprocessingResults, 2) >= 5 && ~isempty(app.PreprocessingResults{app.CurrentIndex, 5})
                    prepData = app.PreprocessingResults{app.CurrentIndex, 5};
                % 检查其他自定义预处理
                else
                    for col = 4:size(app.PreprocessingResults, 2)
                        if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                            result = app.PreprocessingResults{app.CurrentIndex, col};
                            if isfield(result, 'preprocessing_info') && ...
                               isfield(result.preprocessing_info, 'name') && ...
                               strcmp(result.preprocessing_info.name, selectedObj)
                                prepData = result;
                                break;
                            end
                        end
                    end
                end

                % 如果没有找到预处理数据，给出提示
                if isempty(prepData)
                    uialert(dlg, sprintf('当前帧未找到预处理结果"%s"，请确认上一步是否进行处理！', selectedObj), '提示', 'Icon', 'warning');
                    % 清空参数表格
                    paramTable.Data = cell(0, 5);
                    return;
                end

                % 清空当前参数表格
                paramTable.Data = cell(0, 5);

                % 提取所有输出变量（只包含原先的params和additional_outputs）
                outputVars = struct();
                currentOutputVars = struct();  % 重置输出变量存储

                % 1. 添加原先保存的params参数
                if isfield(prepData, 'preprocessing_info') && isfield(prepData.preprocessing_info, 'params')
                    params = prepData.preprocessing_info.params;
                    paramFields = fieldnames(params);
                    for i = 1:length(paramFields)
                        fieldName = paramFields{i};
                        outputVars.(fieldName) = params.(fieldName);
                    end
                end

                % 2. 添加additional_outputs里的参数
                if isfield(prepData, 'additional_outputs')
                    addOutputs = prepData.additional_outputs;
                    addFields = fieldnames(addOutputs);
                    for i = 1:length(addFields)
                        fieldName = addFields{i};
                        outputVars.(fieldName) = addOutputs.(fieldName);
                    end
                end

                % 将输出变量添加到参数表格
                outputFields = fieldnames(outputVars);
                for i = 1:length(outputFields)
                    fieldName = outputFields{i};
                    fieldValue = outputVars.(fieldName);

                    % 存储实际数据到 currentOutputVars
                    currentOutputVars.(fieldName) = fieldValue;

                    % 确定数据类型
                    if isstruct(fieldValue)
                        dataType = 'struct';
                        valueStr = sprintf('<struct: %d fields>', length(fieldnames(fieldValue)));
                        expandIcon = '+';  % struct类型显示+号
                    elseif isnumeric(fieldValue)
                        if isscalar(fieldValue)
                            dataType = class(fieldValue);
                            valueStr = num2str(fieldValue);
                        else
                            dataType = sprintf('%s [%s]', class(fieldValue), mat2str(size(fieldValue)));
                            valueStr = sprintf('[%s]', mat2str(size(fieldValue)));
                        end
                        expandIcon = '';
                    elseif ischar(fieldValue) || isstring(fieldValue)
                        dataType = 'string';
                        valueStr = char(fieldValue);
                        expandIcon = '';
                    elseif islogical(fieldValue)
                        dataType = 'logical';
                        valueStr = char(string(fieldValue));
                        expandIcon = '';
                    else
                        dataType = class(fieldValue);
                        valueStr = sprintf('<%s>', class(fieldValue));
                        expandIcon = '';
                    end

                    % 添加到表格，操作列留空（输出变量不可删除）
                    newRow = {expandIcon, fieldName, valueStr, dataType, ''};
                    paramTable.Data = [paramTable.Data; newRow];
                end
            end

            function showFrameSelectionHelp()
                % 显示帧范围选择帮助
                helpMsg = ['帧范围格式说明：', newline, newline, ...
                    '• 留空：只应用到当前帧', newline, ...
                    '• 单个帧：1', newline, ...
                    '• 多个帧：1,3,5', newline, ...
                    '• 连续帧：1-5', newline, ...
                    '• 组合：1,3-5,8-10', newline, newline, ...
                    '示例：', newline, ...
                    '  1,3-5,8  表示第1、3、4、5、8帧'];
                uialert(dlg, helpMsg, '帧范围格式说明');
            end

            function onTypeChanged(~, ~)
                prepType = prepTypeDropdown.Value;

                if strcmp(prepType, '自定义...')
                    customNamePanel.Visible = 'on';
                    contentLayout.RowHeight = {65, 55, 55, 105, '1x'};
                else
                    customNamePanel.Visible = 'off';
                    contentLayout.RowHeight = {65, 55, 0, 105, '1x'};

                    % 如果选择四个默认预处理类型，且默认选择"使用默认脚本"，自动加载
                    if (strcmp(prepType, 'CFAR检测') || strcmp(prepType, '非相参积累') || ...
                        strcmp(prepType, '非相参识别') || strcmp(prepType, '多维识别')) && defaultScriptRadio.Value
                        loadDefaultScript(prepType);
                    end
                end
            end
            
            function onSourceChanged(~, event)
                if strcmp(event.NewValue.Text, '导入自定义脚本')
                    fileSelectionPanel.Visible = 'on';
                else
                    fileSelectionPanel.Visible = 'off';
                    scriptPathField.Value = '';

                    % 如果选择"使用默认脚本"且预处理类型是四个默认类型之一，自动加载默认脚本
                    prepType = prepTypeDropdown.Value;
                    if strcmp(prepType, 'CFAR检测') || strcmp(prepType, '非相参积累') || ...
                       strcmp(prepType, '非相参识别') || strcmp(prepType, '多维识别')
                        loadDefaultScript(prepType);
                    end
                end
            end
            
            function selectFile(~, ~)
                [file, path] = uigetfile({'*.m', 'MATLAB脚本 (*.m)'}, '选择预处理脚本');

                % 文件选择后置顶窗口
                figure(app.UIFigure);  % 先置顶主UI
                figure(dlg);           % 再置顶预处理弹窗

                if file ~= 0
                    fullPath = fullfile(path, file);
                    scriptPathField.Value = fullPath;
                    tryAutoDetectFromScript(fullPath);

                    % 将预处理对话框置顶
                    figure(dlg);
                    drawnow;
                end
            end
            
            function tryAutoDetectFromScript(scriptPath)
                try
                    fid = fopen(scriptPath, 'r');
                    if fid == -1
                        return;
                    end
                    content = fread(fid, '*char')';
                    fclose(fid);
                    
                    % 检查当前是否有加载的数据和帧信息
                    hasFrameInfo = false;
                    frameInfoData = struct();
                    if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                        currentData = app.MatData{app.CurrentIndex};
                        if isfield(currentData, 'frame_info')
                            hasFrameInfo = true;
                            frameInfoData = currentData.frame_info;
                        end
                    end
                    
                    % 匹配PARAM注释（支持有无默认值两种格式）
                    % 由于MATLAB的可选捕获组在未匹配时不会出现在结果中，需要分两次匹配

                    % 模式1: 有默认值（3个捕获组）
                    % 使用 [^\n\r]+ 确保只匹配到行尾，避免贪婪匹配
                    patternWithDefault = '%%?\s*PARAM:\s*(\w+)\s*,\s*(\w+)\s*,\s*([^\n\r]+)';
                    matchesWithDefault = regexp(content, patternWithDefault, 'tokens');

                    % 模式2: 无默认值（2个捕获组）
                    patternWithoutDefault = '%%?\s*PARAM:\s*(\w+)\s*,\s*(\w+)\s*$';
                    matchesWithoutDefault = regexp(content, patternWithoutDefault, 'tokens', 'lineanchors');

                    % 合并结果：将无默认值的匹配添加空字符串作为第3组
                    paramMatches = matchesWithDefault;
                    for i = 1:length(matchesWithoutDefault)
                        % 为无默认值的参数添加空字符串作为第3组
                        paramMatches{end+1} = {matchesWithoutDefault{i}{1}, matchesWithoutDefault{i}{2}, ''};
                    end

                    % DEBUG: 打印匹配结果
                    fprintf('\n=== 参数解析调试信息 ===\n');
                    fprintf('有默认值的参数: %d 个\n', length(matchesWithDefault));
                    fprintf('无默认值的参数: %d 个\n', length(matchesWithoutDefault));
                    fprintf('总共参数: %d 个\n', length(paramMatches));
                    fprintf('hasFrameInfo = %d\n', hasFrameInfo);

                    if ~isempty(paramMatches)
                        paramTable.Data = cell(0, 5);
                        fromFrameInfoCount = 0;
                        fromDefaultValueCount = 0;

                        for i = 1:length(paramMatches)
                            fprintf('\n--- 参数 %d ---\n', i);
                            fprintf('匹配元素个数: %d\n', length(paramMatches{i}));

                            paramName = strtrim(paramMatches{i}{1});
                            paramType = strtrim(paramMatches{i}{2});

                            fprintf('参数名: %s\n', paramName);
                            fprintf('参数类型: %s\n', paramType);

                            % 检查是否有第三个元素（默认值）
                            % 注意：现在所有参数都有3组，无默认值的第3组为空字符串
                            defaultValueStr = strtrim(paramMatches{i}{3});
                            hasDefaultValue = ~isempty(defaultValueStr);
                            fprintf('第3个元素原始值: ''%s''\n', paramMatches{i}{3});
                            fprintf('第3个元素trim后: ''%s''\n', defaultValueStr);
                            fprintf('是否有默认值: %d\n', hasDefaultValue);

                            % 默认参数值
                            paramValue = '';
                            usedFrameInfo = false;  % 标记是否成功使用了帧信息

                            % 优先从帧信息中获取
                            if hasFrameInfo && isfield(frameInfoData, paramName)
                                fprintf('在frame_info中找到参数: %s\n', paramName);
                                fieldValue = frameInfoData.(paramName);

                                % 根据类型格式化显示值
                                if isstruct(fieldValue)
                                    % struct类型：转为JSON字符串显示
                                    try
                                        paramValue = jsonencode(fieldValue);
                                        usedFrameInfo = true;
                                        fprintf('从frame_info获取struct值（JSON）\n');
                                    catch
                                        paramValue = '<struct>';
                                        usedFrameInfo = true;
                                        fprintf('从frame_info获取struct值（标记）\n');
                                    end
                                elseif isnumeric(fieldValue)
                                    if isscalar(fieldValue)
                                        paramValue = num2str(fieldValue);
                                    else
                                        paramValue = mat2str(fieldValue);
                                    end
                                    usedFrameInfo = true;
                                    fprintf('从frame_info获取数值: %s\n', paramValue);
                                elseif ischar(fieldValue) || isstring(fieldValue)
                                    paramValue = char(fieldValue);
                                    usedFrameInfo = true;
                                    fprintf('从frame_info获取字符串: %s\n', paramValue);
                                elseif islogical(fieldValue)
                                    paramValue = char(string(fieldValue));
                                    usedFrameInfo = true;
                                    fprintf('从frame_info获取逻辑值: %s\n', paramValue);
                                else
                                    % 帧信息值类型无法识别，fallback到默认值
                                    usedFrameInfo = false;
                                    fprintf('frame_info值类型无法识别，fallback到默认值\n');
                                end
                            else
                                if hasFrameInfo
                                    fprintf('frame_info中未找到参数: %s\n', paramName);
                                end
                            end

                            % 如果帧信息未使用或无法转换，使用脚本默认值
                            fprintf('usedFrameInfo = %d\n', usedFrameInfo);
                            if ~usedFrameInfo
                                if hasDefaultValue
                                    % 使用脚本中定义的默认值
                                    paramValue = defaultValueStr;
                                    fromDefaultValueCount = fromDefaultValueCount + 1;
                                    fprintf('使用脚本默认值: ''%s''\n', paramValue);
                                else
                                    % 无默认值也无有效帧信息，保持为空
                                    paramValue = '';
                                    fprintf('无默认值，参数值为空\n');
                                end
                            else
                                fromFrameInfoCount = fromFrameInfoCount + 1;
                            end

                            fprintf('最终参数值: ''%s''\n', paramValue);

                            % 根据参数类型确定是否显示展开图标
                            if strcmpi(paramType, 'struct')
                                expandIcon = '+';
                                % 如果有struct默认值，立即解析并存储到currentOutputVars
                                if ~isempty(paramValue) && ~strcmp(paramValue, '<struct>')
                                    try
                                        structValue = eval(paramValue);
                                        if isstruct(structValue)
                                            currentOutputVars.(paramName) = structValue;
                                            fprintf('已解析并存储struct默认值\n');
                                        end
                                    catch
                                        fprintf('struct默认值解析失败，将在展开时再次尝试\n');
                                    end
                                end
                            else
                                expandIcon = '';
                            end

                            newRow = {expandIcon, paramName, paramValue, paramType, '删除'};
                            paramTable.Data = [paramTable.Data; newRow];
                        end

                        fprintf('\n=== 参数解析完成 ===\n');
                        fprintf('从frame_info获取: %d 个\n', fromFrameInfoCount);
                        fprintf('从默认值获取: %d 个\n', fromDefaultValueCount);
                        fprintf('========================\n\n');

                        % 提示信息
                        if fromFrameInfoCount > 0 && fromDefaultValueCount > 0
                            uialert(dlg, sprintf('已从脚本中检测到 %d 个参数！\n其中 %d 个参数值从当前帧信息中自动填充，%d 个参数使用了默认值。', ...
                                length(paramMatches), fromFrameInfoCount, fromDefaultValueCount), '成功', 'Icon', 'success');
                        elseif fromFrameInfoCount > 0
                            uialert(dlg, sprintf('已从脚本中检测到 %d 个参数！\n其中 %d 个参数值从当前帧信息中自动填充。', ...
                                length(paramMatches), fromFrameInfoCount), '成功', 'Icon', 'success');
                        elseif fromDefaultValueCount > 0
                            uialert(dlg, sprintf('已从脚本中检测到 %d 个参数！\n其中 %d 个参数已使用默认值自动填充。', ...
                                length(paramMatches), fromDefaultValueCount), '成功', 'Icon', 'success');
                        else
                            uialert(dlg, sprintf('已从脚本中检测到 %d 个参数！\n请手动配置参数值。', ...
                                length(paramMatches)), '成功', 'Icon', 'success');
                        end
                    else
                        uialert(dlg, sprintf('未在脚本中找到参数定义。\n\n参数定义格式：\n%% PARAM: 参数名, 类型\n%% PARAM: 参数名, 类型, 默认值\n\n示例：\n%% PARAM: threshold, double\n%% PARAM: window_size, double, 5'), '提示');
                    end
                catch ME
                    uialert(dlg, sprintf('读取脚本失败：\n%s', ME.message), '错误', 'Icon', 'error');
                end
            end

            function loadDefaultScript(prepType)
                % 加载默认预处理脚本
                % 获取当前脚本所在目录
                scriptPath = fileparts(mfilename('fullpath'));

                % 根据类型选择默认脚本
                if strcmp(prepType, 'CFAR检测')
                    scriptFile = fullfile(scriptPath, 'default_cfar.m');
                elseif strcmp(prepType, '非相参积累')
                    scriptFile = fullfile(scriptPath, 'default_noncoherent_integration.m');
                elseif strcmp(prepType, '非相参识别')
                    scriptFile = fullfile(scriptPath, 'default_noncoherent_recognition.m');
                elseif strcmp(prepType, '多维识别')
                    scriptFile = fullfile(scriptPath, 'default_multidim_recognition.m');
                else
                    return;
                end

                % 检查脚本文件是否存在
                if ~exist(scriptFile, 'file')
                    uialert(dlg, sprintf('默认预处理脚本不存在：\n%s', scriptFile), '错误');
                    return;
                end

                % 自动加载脚本参数
                tryAutoDetectFromScript(scriptFile);
            end

            function autoDetectParams(~, ~)
                prepType = prepTypeDropdown.Value;
                
                if strcmp(prepType, '-- 请选择 --')
                    uialert(dlg, '请先选择预处理类型！', '提示');
                    return;
                end
                
                if strcmp(prepType, '自定义...')
                    if customScriptRadio.Value && ~isempty(scriptPathField.Value)
                        tryAutoDetectFromScript(scriptPathField.Value);
                    else
                        uialert(dlg, '请先选择自定义脚本文件！', '提示');
                    end
                elseif strcmp(prepType, 'CFAR检测') || strcmp(prepType, '非相参积累') || ...
                       strcmp(prepType, '非相参识别') || strcmp(prepType, '多维识别')
                    % 对于四个默认预处理类型，如果选择"使用默认脚本"，则从默认脚本文件加载
                    if defaultScriptRadio.Value
                        loadDefaultScript(prepType);
                    elseif customScriptRadio.Value && ~isempty(scriptPathField.Value)
                        tryAutoDetectFromScript(scriptPathField.Value);
                    else
                        uialert(dlg, '请先选择脚本来源！', '提示');
                    end
                else
                    % 从默认参数模板加载（保留旧的逻辑以防万一）
                    defaultParams = getDefaultParams(prepType);
                    if ~isempty(defaultParams)
                        % 检查是否有帧信息
                        hasFrameInfo = false;
                        frameInfoData = struct();
                        if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                            currentData = app.MatData{app.CurrentIndex};
                            if isfield(currentData, 'frame_info')
                                hasFrameInfo = true;
                                frameInfoData = currentData.frame_info;
                            end
                        end
                        
                        paramTable.Data = cell(0, 5);
                        fromFrameInfoCount = 0;

                        for i = 1:size(defaultParams, 1)
                            paramName = defaultParams{i, 1};
                            paramType = defaultParams{i, 3};
                            paramValue = '';

                            % 优先从帧信息获取
                            if hasFrameInfo && isfield(frameInfoData, paramName)
                                fieldValue = frameInfoData.(paramName);

                                if isstruct(fieldValue)
                                    try
                                        paramValue = jsonencode(fieldValue);
                                    catch
                                        paramValue = '<struct>';
                                    end
                                elseif isnumeric(fieldValue)
                                    paramValue = num2str(fieldValue);
                                elseif ischar(fieldValue) || isstring(fieldValue)
                                    paramValue = char(fieldValue);
                                elseif islogical(fieldValue)
                                    paramValue = char(string(fieldValue));
                                else
                                    paramValue = defaultParams{i, 2};  % 使用默认值
                                end
                                fromFrameInfoCount = fromFrameInfoCount + 1;
                            else
                                % 使用默认值
                                paramValue = defaultParams{i, 2};
                            end

                            % 根据参数类型确定是否显示展开图标
                            if strcmpi(paramType, 'struct')
                                expandIcon = '+';
                                % 如果有struct默认值，立即解析并存储到currentOutputVars
                                if ~isempty(paramValue) && ~strcmp(paramValue, '<struct>')
                                    try
                                        structValue = eval(paramValue);
                                        if isstruct(structValue)
                                            currentOutputVars.(paramName) = structValue;
                                        end
                                    catch
                                        % 解析失败，将在展开时再次尝试
                                    end
                                end
                            else
                                expandIcon = '';
                            end

                            newRow = {expandIcon, paramName, paramValue, paramType, '删除'};
                            paramTable.Data = [paramTable.Data; newRow];
                        end

                        if fromFrameInfoCount > 0
                            uialert(dlg, sprintf('已加载 %d 个默认参数！\n其中 %d 个参数值从当前帧信息中自动填充。', ...
                                size(defaultParams, 1), fromFrameInfoCount), '成功', 'Icon', 'success');
                        else
                            uialert(dlg, sprintf('已加载 %d 个默认参数！', size(defaultParams, 1)), '成功', 'Icon', 'success');
                        end
                    else
                        uialert(dlg, '该预处理类型暂无默认参数模板', '提示');
                    end
                end
            end
            
            function addParameter(~, ~)
                newRow = {'', 'param_name', '0', 'double', '删除'};
                paramTable.Data = [paramTable.Data; newRow];
            end
            
            function handleTableClick(~, event)
                if ~isempty(event.Indices)
                    row = event.Indices(1);
                    col = event.Indices(2);

                    try
                        % 点击第5列（操作列）：删除行
                        if col == 5
                            % 只删除手动添加的参数，不删除输出变量（操作列为空的）
                            if row <= size(paramTable.Data, 1) && ~isempty(paramTable.Data{row, 5})
                                paramTable.Data(row, :) = [];
                            end
                        % 点击第1列或第2列：展开/折叠struct（让操作更灵敏）
                        elseif col == 1 || col == 2
                            if row <= size(paramTable.Data, 1)
                                expandIcon = paramTable.Data{row, 1};
                                paramName = paramTable.Data{row, 2};

                                % 检查是否是struct类型（有展开图标）
                                if strcmp(expandIcon, '+')
                                    % 展开struct
                                    fprintf('展开struct: %s\n', paramName);
                                    expandStructRow(row);
                                elseif strcmp(expandIcon, '-')
                                    % 折叠struct
                                    fprintf('折叠struct: %s\n', paramName);
                                    collapseStructRow(row);
                                end
                                % 忽略空图标和子字段的点击
                            end
                        end
                    catch ME
                        fprintf('表格点击处理出错: %s\n', ME.message);
                    end
                end
            end

            function expandStructRow(row)
                % 展开struct类型的行
                try
                    % 边界检查
                    if row > size(paramTable.Data, 1)
                        fprintf('展开失败：行索引超出范围\n');
                        return;
                    end

                    paramName = paramTable.Data{row, 2};
                    paramValue = paramTable.Data{row, 3};
                    paramType = paramTable.Data{row, 4};

                    fprintf('尝试展开struct参数: %s, 类型: %s\n', paramName, paramType);

                    % 获取struct数据
                    structData = [];
                    if isfield(currentOutputVars, paramName)
                        % 从输出变量获取
                        structData = currentOutputVars.(paramName);
                        fprintf('从currentOutputVars获取struct数据\n');
                    elseif strcmpi(paramType, 'struct') || contains(paramType, 'struct')
                        % 尝试从参数值解析struct
                        if isstruct(paramValue)
                            structData = paramValue;
                            fprintf('参数值本身就是struct\n');
                        else
                            try
                                % 尝试从字符串解析
                                fprintf('尝试解析struct字符串: %s\n', paramValue);
                                structData = eval(paramValue);
                                fprintf('eval解析成功\n');
                            catch ME1
                                fprintf('eval解析失败: %s\n', ME1.message);
                                try
                                    structData = jsondecode(paramValue);
                                    fprintf('jsondecode解析成功\n');
                                catch ME2
                                    fprintf('jsondecode解析失败: %s\n', ME2.message);
                                    uialert(dlg, sprintf('无法解析struct参数！\n\n请确保格式正确，例如：\nstruct(''field1'', value1, ''field2'', value2)\n\n错误信息：%s', ME2.message), '错误', 'Icon', 'error');
                                    return;
                                end
                            end
                        end
                        % 存储到currentOutputVars供后续使用
                        currentOutputVars.(paramName) = structData;
                    end

                    if ~isempty(structData) && isstruct(structData)
                        fprintf('展开struct成功，包含 %d 个字段\n', length(fieldnames(structData)));

                        % 将+改为-
                        paramTable.Data{row, 1} = '-';

                        % 获取struct的字段
                        structFields = fieldnames(structData);

                        % 在当前行后插入子行
                        insertIdx = row + 1;
                        for i = 1:length(structFields)
                            fieldName = structFields{i};
                            fieldValue = structData.(fieldName);

                            % 确定数据类型和值字符串
                            if isstruct(fieldValue)
                                dataType = 'struct';
                                valueStr = sprintf('<struct: %d fields>', length(fieldnames(fieldValue)));
                                expandIcon = '+';
                                % 存储嵌套struct的数据
                                nestedFieldName = sprintf('%s.%s', paramName, fieldName);
                                currentOutputVars.(nestedFieldName) = fieldValue;
                            elseif isnumeric(fieldValue)
                                expandIcon = '';
                                if isscalar(fieldValue)
                                    dataType = class(fieldValue);
                                    valueStr = num2str(fieldValue);
                                else
                                    dataType = sprintf('%s [%s]', class(fieldValue), mat2str(size(fieldValue)));
                                    valueStr = sprintf('[%s]', mat2str(size(fieldValue)));
                                end
                            elseif ischar(fieldValue) || isstring(fieldValue)
                                dataType = 'string';
                                valueStr = char(fieldValue);
                                expandIcon = '';
                            elseif islogical(fieldValue)
                                dataType = 'logical';
                                valueStr = char(string(fieldValue));
                                expandIcon = '';
                            else
                                dataType = class(fieldValue);
                                valueStr = sprintf('<%s>', class(fieldValue));
                                expandIcon = '';
                            end

                            % 创建子行，参数名称前加缩进
                            newRow = {expandIcon, sprintf('  %s', fieldName), valueStr, dataType, ''};

                            % 插入行
                            if insertIdx <= size(paramTable.Data, 1)
                                paramTable.Data = [paramTable.Data(1:insertIdx-1, :); newRow; paramTable.Data(insertIdx:end, :)];
                            else
                                paramTable.Data = [paramTable.Data; newRow];
                            end

                            insertIdx = insertIdx + 1;
                        end
                    else
                        fprintf('展开失败：structData为空或不是struct类型\n');
                    end
                catch ME
                    fprintf('展开struct出错: %s\n', ME.message);
                    uialert(dlg, sprintf('展开struct失败：%s', ME.message), '错误', 'Icon', 'error');
                end
            end

            function collapseStructRow(row)
                % 折叠struct类型的行
                try
                    % 边界检查
                    if row > size(paramTable.Data, 1)
                        fprintf('折叠失败：行索引超出范围\n');
                        return;
                    end

                    % 将-改为+
                    paramTable.Data{row, 1} = '+';
                    fprintf('折叠struct，删除子行...\n');

                    % 删除所有子行（以两个空格开头的行）
                    deletedCount = 0;
                    i = row + 1;
                    while i <= size(paramTable.Data, 1)
                        % 检查是否是子行（参数名称以两个或更多空格开头）
                        paramName = paramTable.Data{i, 2};
                        if ischar(paramName) && length(paramName) >= 2 && strcmp(paramName(1:2), '  ')
                            paramTable.Data(i, :) = [];
                            deletedCount = deletedCount + 1;
                        else
                            break;  % 遇到非子行，停止删除
                        end
                    end
                    fprintf('已删除 %d 个子行\n', deletedCount);
                catch ME
                    fprintf('折叠struct出错: %s\n', ME.message);
                    uialert(dlg, sprintf('折叠struct失败：%s', ME.message), '错误', 'Icon', 'error');
                end
            end

            function checkFrameInfoField(src, event)
                % 检查参数名是否为帧信息字段，并处理参数编辑
                if isempty(event.Indices)
                    return;
                end

                row = event.Indices(1);
                col = event.Indices(2);

                % 处理参数名称编辑（第2列）
                if col == 2
                    oldParamName = strtrim(event.PreviousData);
                    newParamName = strtrim(event.NewData);
                    operationCol = src.Data{row, 5};

                    % 如果是输出变量，需要在currentOutputVars中重命名
                    if isempty(operationCol) && isfield(currentOutputVars, oldParamName)
                        % 保存值
                        paramValue = currentOutputVars.(oldParamName);
                        % 删除旧名称
                        currentOutputVars = rmfield(currentOutputVars, oldParamName);
                        % 添加新名称
                        currentOutputVars.(newParamName) = paramValue;
                        fprintf('已重命名输出变量: %s -> %s\n', oldParamName, newParamName);
                    end

                    % 检查是否为帧信息字段
                    if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                        currentData = app.MatData{app.CurrentIndex};
                        if isfield(currentData, 'frame_info') && isfield(currentData.frame_info, newParamName)
                            src.Data{row, 3} = '将使用帧信息中的参数值';
                            uialert(dlg, sprintf('检测到参数"%s"与帧信息字段匹配！\n应用到全部数据时将使用每帧的对应字段值。', newParamName), '提示', 'Icon', 'info');
                        end
                    end

                % 处理参数值编辑（第3列）
                elseif col == 3
                    paramName = src.Data{row, 2};
                    newValue = event.NewData;
                    paramType = src.Data{row, 4};
                    operationCol = src.Data{row, 5};  % 操作列

                    % 检查是否是struct的子字段（参数名以空格开头）
                    if ischar(paramName) && length(paramName) >= 2 && strcmp(paramName(1:2), '  ')
                        % 这是一个子字段，需要更新父struct
                        updateParentStruct(row, newValue, paramType);
                    elseif isempty(operationCol)
                        % 操作列为空，说明是输出变量，需要更新到currentOutputVars
                        updateOutputVar(paramName, newValue, paramType);
                    end
                    % 如果操作列是"删除"，则是手动添加的参数，不需要特殊处理

                % 处理数据类型编辑（第4列）
                elseif col == 4
                    paramName = src.Data{row, 2};
                    paramValue = src.Data{row, 3};
                    newType = event.NewData;
                    operationCol = src.Data{row, 5};

                    % 如果是输出变量，根据新类型重新转换值
                    if isempty(operationCol) && ~isempty(paramValue)
                        try
                            convertedValue = app.convertParamValue(paramValue, newType);
                            currentOutputVars.(paramName) = convertedValue;
                            fprintf('已更新输出变量类型 %s: %s\n', paramName, newType);
                        catch ME
                            fprintf('更新类型失败: %s\n', ME.message);
                        end
                    end
                end
            end

            function updateOutputVar(paramName, newValue, paramType)
                % 更新输出变量到currentOutputVars
                try
                    % 转换新值到正确的类型
                    convertedValue = app.convertParamValue(newValue, paramType);

                    % 保存到currentOutputVars
                    currentOutputVars.(paramName) = convertedValue;

                    fprintf('已更新输出变量 %s = %s\n', paramName, newValue);
                catch ME
                    uialert(dlg, sprintf('更新参数"%s"失败：%s', paramName, ME.message), '错误', 'Icon', 'error');
                end
            end

            function updateParentStruct(childRow, newValue, paramType)
                % 更新父struct中的子字段值
                % 找到父行
                parentRow = childRow - 1;
                while parentRow > 0
                    parentName = paramTable.Data{parentRow, 2};
                    if ischar(parentName) && (length(parentName) < 2 || ~strcmp(parentName(1:2), '  '))
                        % 找到父行（不以空格开头）
                        break;
                    end
                    parentRow = parentRow - 1;
                end

                if parentRow > 0
                    parentParamName = paramTable.Data{parentRow, 2};
                    childFieldName = strtrim(paramTable.Data{childRow, 2});  % 去除前导空格

                    % 获取父struct
                    if isfield(currentOutputVars, parentParamName)
                        parentStruct = currentOutputVars.(parentParamName);

                        % 转换新值到正确的类型
                        try
                            convertedValue = app.convertParamValue(newValue, paramType);

                            % 更新struct字段
                            parentStruct.(childFieldName) = convertedValue;

                            % 保存回currentOutputVars
                            currentOutputVars.(parentParamName) = parentStruct;

                            % 更新父行的值显示
                            paramTable.Data{parentRow, 3} = sprintf('<struct: %d fields>', length(fieldnames(parentStruct)));
                        catch ME
                            uialert(dlg, sprintf('更新struct字段失败：%s', ME.message), '错误', 'Icon', 'error');
                        end
                    end
                end
            end            
            
            function applyPreprocessingAndClose()
                applyPrep([], []);
            end

            function applyPrep(~, ~)
                % ===== 读取复选框和帧范围 =====
                applyToAll = batchApplyCheck.Value;
                frameRangeStr = frameSelectionField.Value;

                % 检查处理对象
                selectedObj = objDropdown.Value;
                if strcmp(selectedObj, '-- 请选择 --')
                    uialert(dlg, '请选择处理对象！', '提示');
                    return;
                end

                % 检查处理对象有效性
                if strcmp(selectedObj, '当前帧原图') && (isempty(app.MatData) || app.CurrentIndex > length(app.MatData))
                    uialert(dlg, '当前没有有效的帧数据！', '错误', 'Icon', 'error');
                    return;
                end

                % 解析帧范围
                frameIndices = [];
                if ~isempty(strtrim(frameRangeStr))
                    % 如果输入了帧范围，优先使用帧范围
                    frameIndices = parseFrameRange(frameRangeStr, length(app.MatData));
                    if isempty(frameIndices)
                        uialert(dlg, '帧范围格式错误！请检查输入。', '错误', 'Icon', 'error');
                        return;
                    end
                elseif applyToAll
                    % 应用到所有帧
                    frameIndices = 1:length(app.MatData);
                else
                    % 默认当前帧
                    frameIndices = app.CurrentIndex;
                end
                
                % 检查预处理类型
                prepType = prepTypeDropdown.Value;
                if strcmp(prepType, '-- 请选择 --')
                    uialert(dlg, '请选择预处理类型！', '提示');
                    return;
                end
                
                % 确定名称
                if strcmp(prepType, '自定义...')
                    prepName = strtrim(customNameField.Value);
                    if isempty(prepName)
                        uialert(dlg, '请输入自定义名称！', '提示');
                        return;
                    end
                else
                    prepName = prepType;
                end
                
                % 确定脚本路径
                if customScriptRadio.Value
                    scriptPath = scriptPathField.Value;
                    if isempty(scriptPath)
                        uialert(dlg, '请选择脚本文件！', '提示');
                        return;
                    end
                    if ~isfile(scriptPath)
                        uialert(dlg, '脚本文件不存在！', '错误', 'Icon', 'error');
                        return;
                    end
                else
                    % 使用默认脚本
                    scriptDir = fileparts(mfilename('fullpath'));

                    if strcmp(prepType, 'CFAR检测')
                        scriptPath = fullfile(scriptDir, 'default_cfar.m');
                    elseif strcmp(prepType, '非相参积累')
                        scriptPath = fullfile(scriptDir, 'default_noncoherent_integration.m');
                    elseif strcmp(prepType, '非相参识别')
                        scriptPath = fullfile(scriptDir, 'default_noncoherent_recognition.m');
                    elseif strcmp(prepType, '多维识别')
                        scriptPath = fullfile(scriptDir, 'default_multidim_recognition.m');
                    else
                        scriptPath = 'default';
                    end

                    % 检查默认脚本是否存在
                    if ~strcmp(scriptPath, 'default') && ~isfile(scriptPath)
                        uialert(dlg, sprintf('默认预处理脚本不存在：\n%s', scriptPath), '错误', 'Icon', 'error');
                        return;
                    end
                end
                
                % 获取参数
                params = struct();
                paramData = paramTable.Data;
                frameInfoParams = {};  % 记录需要从帧信息获取的参数
                
                if ~isempty(paramData)
                    % 检查是否有frame_info
                    hasFrameInfo = false;
                    if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                        currentData = app.MatData{app.CurrentIndex};
                        if isfield(currentData, 'frame_info')
                            hasFrameInfo = true;
                        end
                    end

                    for i = 1:size(paramData, 1)
                        % 跳过子行（缩进的struct字段）
                        if ischar(paramData{i, 2}) && length(paramData{i, 2}) >= 2 && strcmp(paramData{i, 2}(1:2), '  ')
                            continue;
                        end

                        paramName = strtrim(paramData{i, 2});  % 第2列是参数名称
                        paramValue = paramData{i, 3};          % 第3列是参数值
                        paramType = paramData{i, 4};           % 第4列是数据类型

                        if isempty(paramName) || strcmp(paramName, 'param_name')
                            continue;
                        end
                        
                        % 检查是否为帧信息字段
                        isFrameInfoParam = hasFrameInfo && isfield(currentData.frame_info, paramName);

                        % 判断用户是否提供了显式的参数值（非空且不是"将使用帧信息中的参数值"提示）
                        hasUserValue = true;
                        if isempty(paramValue)
                            hasUserValue = false;
                        elseif ischar(paramValue) || isstring(paramValue)
                            hasUserValue = ~contains(char(paramValue), '将使用帧信息中的参数值');
                        end

                        try
                            if exist('currentOutputVars', 'var') && isfield(currentOutputVars, paramName)
                                % 从输出变量中获取原始值（避免字符串转换错误）
                                params.(paramName) = currentOutputVars.(paramName);
                            elseif isFrameInfoParam && ~hasUserValue
                                % 仅在未手动配置时，才从帧信息动态获取
                                frameInfoParams{end+1} = paramName;
                                params.(paramName) = '__FROM_FRAME_INFO__';
                            else
                                % 手动输入的参数：从字符串转换为对应类型（优先级最高）
                                params.(paramName) = app.convertParamValue(paramValue, paramType);
                            end
                        catch ME
                            uialert(dlg, sprintf('参数 "%s" 的值格式错误！\n%s', paramName, ME.message), '错误', 'Icon', 'error');
                            return;
                        end
                    end                        

                end
                
                % 创建预处理配置，添加处理对象信息
                prepConfig = struct();
                prepConfig.name = prepName;
                prepConfig.type = prepType;
                prepConfig.scriptPath = scriptPath;
                prepConfig.params = params;
                prepConfig.timestamp = datetime('now');
                prepConfig.frameInfoParams = frameInfoParams;
                prepConfig.paramTypes = struct();  % 保存参数类型信息
                
                % 添加处理对象信息
                prepConfig.processing_object = selectedObj;
                prepConfig.frame_indices = frameIndices;

                % 保存参数类型信息
                for i = 1:size(paramData, 1)
                    % 跳过子行（缩进的struct字段）
                    if ischar(paramData{i, 2}) && length(paramData{i, 2}) >= 2 && strcmp(paramData{i, 2}(1:2), '  ')
                        continue;
                    end

                    paramName = strtrim(paramData{i, 2});  % 第2列是参数名称
                    paramType = paramData{i, 4};           % 第4列是数据类型
                    if ~isempty(paramName) && ~strcmp(paramName, 'param_name')
                        prepConfig.paramTypes.(paramName) = paramType;
                    end
                end

                % 添加到列表
                app.PreprocessingList{end+1} = prepConfig;
                updatePreprocessingControls(app);

                % 检查当前视图数量（只检查当前帧）
                if ismember(app.CurrentIndex, frameIndices)
                    numCurrentViews = checkCurrentViewCount(app);

                    % 检查是否会替换现有视图
                    willReplaceExisting = false;
                    if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                        % 根据预处理类型确定目标列
                        % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                        targetColumn = [];
                        if strcmp(prepConfig.type, 'CFAR检测')
                            targetColumn = 2;
                        elseif strcmp(prepConfig.type, '非相参积累')
                            targetColumn = 3;
                        elseif strcmp(prepConfig.type, '非相参识别')
                            targetColumn = 4;
                        elseif strcmp(prepConfig.type, '多维识别')
                            targetColumn = 5;
                        else
                            % 自定义预处理，检查是否已存在同名结果
                            for col = 4:size(app.PreprocessingResults, 2)
                                if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                                    result = app.PreprocessingResults{app.CurrentIndex, col};
                                    if isfield(result, 'preprocessing_info') && ...
                                       isfield(result.preprocessing_info, 'name') && ...
                                       strcmp(result.preprocessing_info.name, prepConfig.name)
                                        targetColumn = col;
                                        break;
                                    end
                                end
                            end
                        end

                        if ~isempty(targetColumn) && targetColumn <= size(app.PreprocessingResults, 2)
                            willReplaceExisting = ~isempty(app.PreprocessingResults{app.CurrentIndex, targetColumn});
                        end
                    end

                    % 如果已经有4个视图且不是替换现有的，需要让用户选择关闭哪个
                    if numCurrentViews >= 4 && ~willReplaceExisting
                        % 弹窗让用户选择关闭哪个视图
                        viewCloseSuccess = promptToCloseView(app);
                        if ~viewCloseSuccess
                            % 用户取消了操作，移除刚添加的预处理
                            app.PreprocessingList(end) = [];
                            updatePreprocessingControls(app);
                            return;
                        end
                    end
                end

                % 执行预处理
                success = executePreprocessingWithFrameRange(app, prepConfig, frameIndices);

                if success
                    updateMultiView(app);
                    closeDlgAndFocusMain();

                    if length(frameIndices) > 1
                        uialert(app.UIFigure, sprintf('预处理 "%s" 已应用到 %d 帧数据！', prepName, length(frameIndices)), '成功', 'Icon', 'success');
                    else
                        uialert(app.UIFigure, sprintf('预处理 "%s" 已添加成功！', prepName), '成功', 'Icon', 'success');
                    end
                else
                    app.PreprocessingList(end) = [];
                    updatePreprocessingControls(app);
                end
            end

            function indices = parseFrameRange(rangeStr, maxFrames)
                % 解析帧范围字符串，返回帧索引数组
                indices = [];

                if isempty(rangeStr) || isempty(strtrim(rangeStr))
                    return;  % 返回空数组，调用者将使用当前帧
                end

                try
                    % 去除空格
                    rangeStr = strrep(rangeStr, ' ', '');

                    % 分割逗号
                    parts = strsplit(rangeStr, ',');

                    for i = 1:length(parts)
                        part = parts{i};

                        if contains(part, '-')
                            % 范围 (e.g., "3-5")
                            rangeParts = strsplit(part, '-');
                            if length(rangeParts) == 2
                                startIdx = str2double(rangeParts{1});
                                endIdx = str2double(rangeParts{2});

                                if ~isnan(startIdx) && ~isnan(endIdx) && startIdx >= 1 && endIdx <= maxFrames && startIdx <= endIdx
                                    indices = [indices, startIdx:endIdx];
                                end
                            end
                        else
                            % 单个索引
                            idx = str2double(part);
                            if ~isnan(idx) && idx >= 1 && idx <= maxFrames
                                indices = [indices, idx];
                            end
                        end
                    end

                    % 去重并排序
                    indices = unique(indices);
                catch
                    indices = [];
                end
            end

            function success = executePreprocessingWithFrameRange(app, prepConfig, frameIndices)
                % 在指定帧范围内执行预处理
                success = true;

                try
                    % 判断是应用到所有帧还是特定帧范围
                    if length(frameIndices) == length(app.MatData)
                        % 应用到所有帧
                        success = executePreprocessingOnAllData(app, prepConfig);
                    elseif length(frameIndices) == 1
                        % 应用到单帧
                        success = executePreprocessingOnCurrentData(app, prepConfig);
                    else
                        % 应用到指定帧范围（未来可以扩展）
                        % 暂时使用当前帧的逻辑
                        success = executePreprocessingOnCurrentData(app, prepConfig);
                    end
                catch ME
                    uialert(app.UIFigure, sprintf('预处理执行失败：\n%s', ME.message), '错误', 'Icon', 'error');
                    success = false;
                end
            end

            function resultMatrix = getPreprocessingResult(app, frameIdx, prepName)
                % 从预处理结果中获取指定预处理的结果
                resultMatrix = [];

                if isempty(app.PreprocessingResults) || frameIdx > size(app.PreprocessingResults, 1)
                    return;
                end

                % 根据预处理名称查找对应的列
                % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                if strcmp(prepName, 'CFAR检测')
                    col = 2;
                elseif strcmp(prepName, '非相参积累')
                    col = 3;
                elseif strcmp(prepName, '非相参识别')
                    col = 4;
                elseif strcmp(prepName, '多维识别')
                    col = 5;
                else
                    % 在其他列中查找（自定义预处理）
                    for col = 4:size(app.PreprocessingResults, 2)
                        result = app.PreprocessingResults{frameIdx, col};
                        if ~isempty(result) && isfield(result, 'name') && strcmp(result.name, prepName)
                            if isfield(result, 'processedMatrix')
                                resultMatrix = result.processedMatrix;
                            end
                            return;
                        end
                    end
                    return;
                end

                if ~isempty(app.PreprocessingResults{frameIdx, col})
                    result = app.PreprocessingResults{frameIdx, col};
                    if isfield(result, 'processedMatrix')
                        resultMatrix = result.processedMatrix;
                    end
                end
            end
        
            function showScriptHelp()
                    % 显示脚本接口规范帮助
                    
                    helpDlg = uifigure('Name', '脚本接口规范说明', 'Position', [300 150 700 650]);
                    helpDlg.WindowStyle = 'modal';
                    
                    helpLayout = uigridlayout(helpDlg, [2, 1]);
                    helpLayout.RowHeight = {'1x', 50};
                    helpLayout.Padding = [20 20 20 20];
                    
                    % 文本区域
                    helpText = uitextarea(helpLayout);
                    helpText.Layout.Row = 1;
                    helpText.Layout.Column = 1;
                    helpText.Editable = 'off';
                    helpText.FontName = 'Consolas';
                    helpText.FontSize = 12;
                    
                    helpContent = sprintf([...
                        '═══════════════════════════════════════════════════════════\n', ...
                        '                   预处理脚本接口规范\n', ...
                        '═══════════════════════════════════════════════════════════\n\n', ...
                        '【1. 函数签名】\n\n', ...
                        '    function output_data = your_script_name(input_data, params)\n\n', ...
                        '    • input_data: 输入的复数矩阵或向量\n', ...
                        '    • params: 参数结构体，包含配置的所有参数\n', ...
                        '    • output_data: 处理后的复数矩阵或向量\n\n', ...
                        '───────────────────────────────────────────────────────────\n\n', ...
                        '【2. 参数定义格式】\n\n', ...
                        '在脚本顶部注释中使用以下格式声明参数：\n\n', ...
                        '    %% PARAM: 参数名, 数据类型\n', ...
                        '    %% PARAM: 参数名, 数据类型, 默认值\n\n', ...
                        '如果有默认值，在导入脚本时会自动填充。\n', ...
                        '如果参数名在帧信息中存在，会优先使用帧信息中的值。\n\n', ...
                        '支持的数据类型：\n', ...
                        '    • double  - 双精度浮点数\n', ...
                        '    • int     - 整数\n', ...
                        '    • string  - 字符串\n', ...
                        '    • bool    - 布尔值（true/false）\n', ...
                        '    • struct  - 结构体（JSON或MATLAB表达式）\n\n', ...
                        '───────────────────────────────────────────────────────────\n\n', ...
                        '【3. 完整示例】\n\n', ...
                        'function output_data = my_filter(input_data, params)\n', ...
                        '%% MY_FILTER 自定义滤波器\n', ...
                        '%%\n', ...
                        '%% 参数定义：\n', ...
                        '%% PARAM: threshold, double, 0.5\n', ...
                        '%% PARAM: window_size, int, 16\n', ...
                        '%% PARAM: method, string, gaussian\n', ...
                        '%% PARAM: config, struct\n', ...
                        '%% PARAM: enable_filter, bool, true\n\n', ...
                        '    %% 获取参数\n', ...
                        '    threshold = getParam(params, ''threshold'', 0.5);\n', ...
                        '    window_size = getParam(params, ''window_size'', 16);\n', ...
                        '    method = getParam(params, ''method'', ''gaussian'');\n', ...
                        '    enable_filter = getParam(params, ''enable_filter'', true);\n\n', ...
                        '    config = getParam(params, ''config'', struct(''alpha'', 0.5, ''beta'', 1.0));\n\n', ...
                        '    %% 数据处理\n', ...
                        '    output_data = input_data;  %% 初始化\n', ...
                        '    \n', ...
                        '    if enable_filter\n', ...
                        '        %% 执行滤波处理\n', ...
                        '        amplitude = abs(output_data);\n', ...
                        '        mask = amplitude > threshold;\n', ...
                        '        output_data = output_data .* mask;\n', ...
                        '    end\n\n', ...
                        'end\n\n', ...
                        'function value = getParam(params, name, default)\n', ...
                        '    if isfield(params, name)\n', ...
                        '        value = params.(name);\n', ...
                        '    else\n', ...
                        '        value = default;\n', ...
                        '    end\n', ...
                        'end\n\n', ...
                        '───────────────────────────────────────────────────────────\n\n', ...
                        '【4. 重要提示】\n\n', ...
                        '✓ 参数名必须与代码中 getParam 使用的名称一致\n', ...
                        '✓ PARAM 声明必须在注释中，格式严格遵守\n', ...
                        '✓ 工具会自动解析 PARAM 注释并生成参数配置界面\n', ...
                        '✓ 必须包含 getParam 辅助函数\n\n', ...
                        '═══════════════════════════════════════════════════════════\n']);
                    
                    helpText.Value = helpContent;
                    
                    % 关闭按钮
                    closeBtn = uibutton(helpLayout, 'push');
                    closeBtn.Text = '关闭';
                    closeBtn.Layout.Row = 2;
                    closeBtn.Layout.Column = 1;
                    closeBtn.ButtonPushedFcn = @(~,~) close(helpDlg);
            end

            function value = convertParamValue(paramValue, paramType)
                % 统一的参数类型转换函数
                % 将字符串或任意值转换为指定类型
                
                switch lower(paramType)
                    case 'double'
                        if isnumeric(paramValue)
                            value = double(paramValue);
                        else
                            value = str2double(paramValue);
                        end
                        
                    case 'int'
                    % int类型统一转为double（MATLAB函数兼容性更好）
                    if isnumeric(paramValue)
                        % 如果是复数，保留完整的复数信息
                        if iscomplex(paramValue)
                            value = double(paramValue); % 保留复数，不进行取整
                        else
                            value = round(double(paramValue));
                        end
                    else
                        value = round(str2double(paramValue));
                    end
                        
                    case 'string'
                        value = char(paramValue);
                        
                    case 'bool'
                        if islogical(paramValue)
                            value = paramValue;
                        elseif isnumeric(paramValue)
                            value = logical(paramValue);
                        else
                            value = strcmpi(paramValue, 'true') || strcmp(paramValue, '1');
                        end
                        
                    case 'struct'
                        if isstruct(paramValue)
                            value = paramValue;
                        else
                            % 尝试从JSON或MATLAB表达式解析
                            try
                                value = jsondecode(paramValue);
                            catch
                                value = eval(paramValue);
                                if ~isstruct(value)
                                    error('无法转换为struct类型');
                                end
                            end
                        end
                        
                    otherwise
                        value = paramValue;
                end
            end

        end
        
        function success = executePreprocessingOnAllData(app, prepConfig)
            % 对所有数据批量执行预处理
            
            success = false;
            
            if isempty(app.MatData)
                return;
            end
            
            try
                % 创建进度对话框
                progressDlg = uiprogressdlg(app.UIFigure, 'Title', '批量预处理', ...
                    'Message', '正在处理第 1 帧...', 'Cancelable', 'on');
                
                totalFrames = length(app.MatData);
                prepIndex = length(app.PreprocessingList);
                
                % 初始化结果缓存
                if isempty(app.PreprocessingResults)
                    app.PreprocessingResults = cell(totalFrames, 7);
                end
                
                % 遍历所有帧
                for frameIdx = 1:totalFrames
                    % 检查是否取消
                    if progressDlg.CancelRequested
                        close(progressDlg);
                        uialert(app.UIFigure, '批量预处理已取消！', '提示');
                        success = false;
                        return;
                    end
                    
                    % 更新进度
                    progressDlg.Value = frameIdx / totalFrames;
                    progressDlg.Message = sprintf('正在处理第 %d/%d 帧...', frameIdx, totalFrames);
                    
                    % 获取当前帧数据
                    currentData = app.MatData{frameIdx};

                    % 根据处理对象获取输入矩阵
                    inputMatrix = [];
                    processingObject = prepConfig.processing_object;

                    if strcmp(processingObject, '当前帧原图')
                        % 从原始数据获取complex_matrix
                        % 首先检查直接字段
                        if isfield(currentData, 'complex_matrix')
                            inputMatrix = currentData.complex_matrix;
                        else
                            % 如果没有直接字段，查找是否有包含complex_matrix的结构体
                            dataFields = fieldnames(currentData);
                            for i = 1:length(dataFields)
                                fieldName = dataFields{i};
                                fieldValue = currentData.(fieldName);
                                if isstruct(fieldValue) && isfield(fieldValue, 'complex_matrix')
                                    inputMatrix = fieldValue.complex_matrix;
                                    break;
                                end
                            end
                        end

                        if isempty(inputMatrix)
                            fprintf('警告：第 %d 帧不包含complex_matrix字段，跳过处理\n', frameIdx);
                            continue;
                        end
                    else
                        % 从预处理结果获取complex_matrix
                        if isempty(app.PreprocessingResults) || frameIdx > size(app.PreprocessingResults, 1)
                            fprintf('警告：第 %d 帧未找到预处理结果"%s"，跳过处理\n', frameIdx, processingObject);
                            continue;
                        end

                        % 查找对应的预处理结果
                        % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                        prepData = [];
                        if strcmp(processingObject, 'CFAR检测')
                            prepData = app.PreprocessingResults{frameIdx, 2};
                        elseif strcmp(processingObject, '非相参积累')
                            prepData = app.PreprocessingResults{frameIdx, 3};
                        elseif strcmp(processingObject, '非相参识别')
                            prepData = app.PreprocessingResults{frameIdx, 4};
                        elseif strcmp(processingObject, '多维识别')
                            prepData = app.PreprocessingResults{frameIdx, 5};
                        else
                            % 在自定义预处理列（第4列及之后）中查找
                            for col = 4:size(app.PreprocessingResults, 2)
                                if ~isempty(app.PreprocessingResults{frameIdx, col})
                                    result = app.PreprocessingResults{frameIdx, col};
                                    if isfield(result, 'preprocessing_info') && ...
                                       isfield(result.preprocessing_info, 'name') && ...
                                       strcmp(result.preprocessing_info.name, processingObject)
                                        prepData = result;
                                        break;
                                    end
                                end
                            end
                        end

                        if isempty(prepData)
                            fprintf('警告：第 %d 帧未找到预处理结果"%s"，跳过处理\n', frameIdx, processingObject);
                            continue;
                        end

                        % 从预处理结果获取complex_matrix（而非raw_matrix）
                        % 注意：预处理始终使用complex_matrix作为输入
                        % raw_matrix是保存的预处理前原始数据，需要时可在脚本中手动使用
                        if isfield(prepData, 'complex_matrix')
                            inputMatrix = prepData.complex_matrix;
                        else
                            fprintf('警告：第 %d 帧的预处理结果"%s"不包含complex_matrix字段，跳过处理\n', frameIdx, processingObject);
                            continue;
                        end
                    end

                    % 保存原始矩阵（用于后续可能的预处理）
                    % 这将保存为raw_matrix到输出文件，供需要时使用
                    rawMatrix = inputMatrix;
                    
                    % 创建输出目录（在调用脚本之前）
                    [dataPath, ~, ~] = fileparts(app.MatFiles{frameIdx});
                    outputDir = fullfile(dataPath, prepConfig.name);
                    if ~exist(outputDir, 'dir')
                        mkdir(outputDir);
                    end
                    [~, originalName, ~] = fileparts(app.MatFiles{frameIdx});

                    % 执行预处理
                    try
                        additionalOutputs = struct();  % 初始化额外输出变量

                        if strcmp(prepConfig.scriptPath, 'default')
                            % 使用默认处理
                            processedMatrix = inputMatrix;
                        else
                            % 调用自定义脚本
                            [scriptPath, scriptName, ~] = fileparts(prepConfig.scriptPath);
                            oldPath = addpath(scriptPath);

                            try
                                % 动态替换帧信息参数
                                actualParams = prepConfig.params;
                                if isfield(prepConfig, 'frameInfoParams') && ~isempty(prepConfig.frameInfoParams)
                                    if isfield(currentData, 'frame_info')
                                        for k = 1:length(prepConfig.frameInfoParams)
                                            paramName = prepConfig.frameInfoParams{k};
                                            if isfield(currentData.frame_info, paramName)
                                                % 获取原始值
                                                rawValue = currentData.frame_info.(paramName);
                                                % 根据参数类型转换
                                                if isfield(prepConfig, 'paramTypes') && isfield(prepConfig.paramTypes, paramName)
                                                    paramType = prepConfig.paramTypes.(paramName);
                                                    actualParams.(paramName) = app.convertParamValue(rawValue, paramType);
                                                else
                                                    % 没有类型信息，直接使用
                                                    actualParams.(paramName) = rawValue;
                                                end
                                            end
                                        end
                                    end
                                end

                                % 添加输出目录和文件名到参数中（供脚本使用）
                                actualParams.output_dir = outputDir;
                                actualParams.file_name = originalName;

                                scriptFunc = str2func(scriptName);
                                scriptOutput = scriptFunc(inputMatrix, actualParams);
                                
                                % 处理脚本输出 - 支持结构体和直接数值矩阵
                                additionalOutputs = struct();
                                if isstruct(scriptOutput)
                                    % 如果输出是结构体，检查是否包含complex_matrix字段
                                    if isfield(scriptOutput, 'complex_matrix')
                                        processedMatrix = scriptOutput.complex_matrix;
                                        % 保存其他字段作为额外输出
                                        allFields = fieldnames(scriptOutput);
                                        for i = 1:length(allFields)
                                            fieldName = allFields{i};
                                            if ~strcmp(fieldName, 'complex_matrix')
                                                additionalOutputs.(fieldName) = scriptOutput.(fieldName);
                                            end
                                        end
                                    else
                                        error('脚本返回的结构体必须包含complex_matrix字段！');
                                    end
                                else
                                    % 如果输出是数值矩阵，直接使用
                                    if ~isnumeric(scriptOutput)
                                        error('脚本输出必须是数值矩阵/向量或包含complex_matrix字段的结构体！');
                                    end
                                    processedMatrix = scriptOutput;
                                end
                            catch ME
                                path(oldPath);
                                error('处理第 %d 帧失败：%s', frameIdx, ME.message);
                            end
                            
                            path(oldPath);
                        end
                        
                        % 创建输出数据（内存缓存保留完整数据）
                        processedData = currentData;
                        processedData.complex_matrix = processedMatrix;
                        processedData.preprocessing_info = prepConfig;
                        processedData.preprocessing_time = datetime('now');
                        processedData.frame_index = frameIdx;
                        
                        % 保存额外的输出信息（如果有）
                        if ~isempty(fieldnames(additionalOutputs))
                            processedData.additional_outputs = additionalOutputs;
                        end

                        % 保存到本地（只保存必要字段）
                        outputFile = fullfile(outputDir, sprintf('%s_processed.mat', originalName));

                        % 准备保存数据：包含绘图变量、帧信息和额外输出
                        saveData = struct();
                        saveData.complex_matrix = processedMatrix;
                        saveData.raw_matrix = rawMatrix;  % 保存预处理前的原始矩阵
                        if isfield(currentData, 'frame_info')
                            saveData.frame_info = currentData.frame_info;
                        end
                        % 保存额外的输出信息（如果有）
                        if ~isempty(fieldnames(additionalOutputs))
                            saveData.additional_outputs = additionalOutputs;
                        end

                        save(outputFile, '-struct', 'saveData');

                        % 根据预处理类型保存到对应的列
                        % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                        cacheColumn = 6;  % 默认为自定义列（第6列）
                        if strcmp(prepConfig.type, 'CFAR检测')
                            cacheColumn = 2;
                        elseif strcmp(prepConfig.type, '非相参积累')
                            cacheColumn = 3;
                        elseif strcmp(prepConfig.type, '非相参识别')
                            cacheColumn = 4;
                        elseif strcmp(prepConfig.type, '多维识别')
                            cacheColumn = 5;
                        end

                        % 保存到内存缓存
                        app.PreprocessingResults{frameIdx, cacheColumn} = processedData;
                        
                    catch ME
                        fprintf('警告：第 %d 帧处理失败 - %s\n', frameIdx, ME.message);
                        continue;
                    end
                end
                
                close(progressDlg);
                success = true;
                
            catch ME
                if exist('progressDlg', 'var') && isvalid(progressDlg)
                    close(progressDlg);
                end
                uialert(app.UIFigure, sprintf('批量预处理失败：\n%s', ME.message), '错误', 'Icon', 'error');
                success = false;
            end
        end        
        

        
        function updatePreprocessingControls(app)
            % 更新预处理控件状态

            numPreps = length(app.PreprocessingList);

            if numPreps > 0
                app.ShowPrep3Btn.Enable = 'on';
                app.ShowPrep3Btn.Text = app.PreprocessingList{end}.name;  % 最新添加的预处理
            else
                app.ShowPrep3Btn.Enable = 'off';
                app.ShowPrep3Btn.Text = '预处理';
            end

            % 更新按钮状态 - 现在支持添加多个预处理，不再限制数量

            app.AddPrepBtn.Enable = 'on';

            % 检查是否有任何预处理结果
            hasAnyPrep = false;
            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                for i = 2:7  % 检查所有预处理列
                    if ~isempty(app.PreprocessingResults{app.CurrentIndex, i})
                        hasAnyPrep = true;
                        break;
                    end
                end
            end

            if hasAnyPrep || numPreps > 0
                app.ClearPrepBtn.Enable = 'on';
            else
                app.ClearPrepBtn.Enable = 'off';
            end
        end
        
        
        function success = executePreprocessingOnCurrentData(app, prepConfig)
            % 在当前数据上执行预处理
            
            success = false;
            
            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end
            
            try
                % 获取当前帧数据
                currentData = app.MatData{app.CurrentIndex};

                % 根据处理对象获取输入矩阵
                inputMatrix = [];
                processingObject = prepConfig.processing_object;
                previousPrepData = [];  % 保存上一步预处理数据（用于参数传递）

                if strcmp(processingObject, '当前帧原图')
                    % 从原始数据获取complex_matrix
                    % 首先检查直接字段
                    if isfield(currentData, 'complex_matrix')
                        inputMatrix = currentData.complex_matrix;
                    else
                        % 如果没有直接字段，查找是否有包含complex_matrix的结构体
                        dataFields = fieldnames(currentData);
                        for i = 1:length(dataFields)
                            fieldName = dataFields{i};
                            fieldValue = currentData.(fieldName);
                            if isstruct(fieldValue) && isfield(fieldValue, 'complex_matrix')
                                inputMatrix = fieldValue.complex_matrix;
                                break;
                            end
                        end
                    end

                    if isempty(inputMatrix)
                        uialert(app.UIFigure, '当前数据不包含complex_matrix字段！', '错误', 'Icon', 'error');
                        return;
                    end
                else
                    % 从预处理结果获取complex_matrix
                    if isempty(app.PreprocessingResults) || app.CurrentIndex > size(app.PreprocessingResults, 1)
                        uialert(app.UIFigure, sprintf('当前帧未找到预处理结果"%s"，请确认上一步是否进行处理！', processingObject), '错误', 'Icon', 'error');
                        return;
                    end

                    % 查找对应的预处理结果
                    % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                    prepData = [];
                    if strcmp(processingObject, 'CFAR检测')
                        prepData = app.PreprocessingResults{app.CurrentIndex, 2};
                    elseif strcmp(processingObject, '非相参积累')
                        prepData = app.PreprocessingResults{app.CurrentIndex, 3};
                    elseif strcmp(processingObject, '非相参识别')
                        prepData = app.PreprocessingResults{app.CurrentIndex, 4};
                    elseif strcmp(processingObject, '多维识别')
                        prepData = app.PreprocessingResults{app.CurrentIndex, 5};
                    else
                        % 在自定义预处理列（第4列及之后）中查找
                        for col = 4:size(app.PreprocessingResults, 2)
                            if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                                result = app.PreprocessingResults{app.CurrentIndex, col};
                                if isfield(result, 'preprocessing_info') && ...
                                   isfield(result.preprocessing_info, 'name') && ...
                                   strcmp(result.preprocessing_info.name, processingObject)
                                    prepData = result;
                                    break;
                                end
                            end
                        end
                    end

                    if isempty(prepData)
                        uialert(app.UIFigure, sprintf('当前帧未找到预处理结果"%s"，请确认上一步是否进行处理！', processingObject), '错误', 'Icon', 'error');
                        return;
                    end

                    % 从预处理结果获取complex_matrix（而非raw_matrix）
                    % 注意：预处理始终使用complex_matrix作为输入
                    % raw_matrix是保存的预处理前原始数据，需要时可在脚本中手动使用
                    if isfield(prepData, 'complex_matrix')
                        inputMatrix = prepData.complex_matrix;
                        % 保存上一步的预处理数据，用于参数传递
                        previousPrepData = prepData;
                    else
                        uialert(app.UIFigure, sprintf('预处理结果"%s"不包含complex_matrix字段！', processingObject), '错误', 'Icon', 'error');
                        return;
                    end
                end

                % 保存原始矩阵（始终保存最初的原图）
                % 如果是第二步及以后，继承第一步保存的raw_matrix（原图）
                % 如果是第一步，使用当前输入作为原图
                if ~isempty(previousPrepData) && isfield(previousPrepData, 'raw_matrix')
                    % 第二步及以后：继承第一步的raw_matrix
                    rawMatrix = previousPrepData.raw_matrix;
                else
                    % 第一步：使用当前输入作为raw_matrix
                    rawMatrix = inputMatrix;
                end
                
                % 创建输出目录
                [dataPath, ~, ~] = fileparts(app.MatFiles{app.CurrentIndex});
                outputDir = fullfile(dataPath, prepConfig.name);
                if ~exist(outputDir, 'dir')
                    mkdir(outputDir);
                end
                [~, originalName, ~] = fileparts(app.MatFiles{app.CurrentIndex});

                % 执行预处理
                additionalOutputs = struct();  % 初始化额外输出变量

                if strcmp(prepConfig.scriptPath, 'default')
                    % 使用默认处理（暂时返回原数据）
                    processedMatrix = inputMatrix;
                    uialert(app.UIFigure, '默认脚本功能暂未实现，已保存原始数据。', '提示');
                else
                    % 调用自定义脚本
                    [scriptPath, scriptName, ~] = fileparts(prepConfig.scriptPath);

                    % 临时添加脚本路径
                    oldPath = addpath(scriptPath);

                    try

                        % 动态替换帧信息参数
                        actualParams = prepConfig.params;
                        if isfield(prepConfig, 'frameInfoParams') && ~isempty(prepConfig.frameInfoParams)
                            if isfield(currentData, 'frame_info')
                                for k = 1:length(prepConfig.frameInfoParams)
                                    paramName = prepConfig.frameInfoParams{k};
                                    if isfield(currentData.frame_info, paramName)
                                        % 获取原始值
                                        rawValue = currentData.frame_info.(paramName);
                                        % 根据参数类型转换
                                        if isfield(prepConfig, 'paramTypes') && isfield(prepConfig.paramTypes, paramName)
                                            paramType = prepConfig.paramTypes.(paramName);
                                            actualParams.(paramName) = app.convertParamValue(rawValue, paramType);
                                        else
                                            % 没有类型信息，直接使用
                                            actualParams.(paramName) = rawValue;
                                        end
                                    end
                                end
                            end
                        end

                        % 添加输出目录和文件名到参数中（供脚本使用）
                        actualParams.output_dir = outputDir;
                        actualParams.file_name = originalName;

                        % 如果是对预处理结果进行二次处理，传递第一步的输出参数
                        % 直接使用第一步的输出字段名（不加前缀），方便脚本中直接访问
                        if ~isempty(previousPrepData)
                            % 传递第一步的raw_matrix（第一步处理前的原始数据）
                            % 可通过 params.raw_matrix 访问
                            if isfield(previousPrepData, 'raw_matrix')
                                actualParams.raw_matrix = previousPrepData.raw_matrix;
                            end

                            % 传递第一步的frame_info
                            % 可通过 params.frame_info 访问
                            if isfield(previousPrepData, 'frame_info')
                                actualParams.frame_info = previousPrepData.frame_info;
                            end

                            % 传递第一步的preprocessing_info
                            % 可通过 params.preprocessing_info 访问
                            if isfield(previousPrepData, 'preprocessing_info')
                                actualParams.preprocessing_info = previousPrepData.preprocessing_info;
                            end

                            % 传递第一步的additional_outputs中的所有字段（展平到params）
                            % 例如第一步输出了 thresholds, detection_mask 等
                            % 第二步可直接通过 params.thresholds, params.detection_mask 访问
                            if isfield(previousPrepData, 'additional_outputs')
                                additionalFields = fieldnames(previousPrepData.additional_outputs);
                                for i = 1:length(additionalFields)
                                    fieldName = additionalFields{i};
                                    % 避免覆盖脚本自定义参数
                                    if ~isfield(actualParams, fieldName)
                                        actualParams.(fieldName) = previousPrepData.additional_outputs.(fieldName);
                                    end
                                end
                            end
                        end

                        % 调用脚本函数
                        scriptFunc = str2func(scriptName);
                        scriptOutput = scriptFunc(inputMatrix, actualParams);
                        
                        % 处理脚本输出 - 支持结构体和直接数值矩阵
                        additionalOutputs = struct();
                        if isstruct(scriptOutput)
                            % 如果输出是结构体，检查是否包含complex_matrix字段
                            if isfield(scriptOutput, 'complex_matrix')
                                processedMatrix = scriptOutput.complex_matrix;
                                % 保存其他字段
                                allFields = fieldnames(scriptOutput);
                                for i = 1:length(allFields)
                                    fieldName = allFields{i};
                                    if ~strcmp(fieldName, 'complex_matrix')
                                        additionalOutputs.(fieldName) = scriptOutput.(fieldName);
                                    end
                                end
                            else
                                error('脚本返回的结构体必须包含complex_matrix字段！');
                            end
                        else
                            % 如果输出是数值矩阵，直接使用
                            if ~isnumeric(scriptOutput)
                                error('脚本输出必须是数值矩阵/向量或包含complex_matrix字段的结构体！');
                            end
                            processedMatrix = scriptOutput;
                        end
                        
                    catch ME
                        path(oldPath);  % 恢复路径
                        uialert(app.UIFigure, sprintf('执行预处理脚本失败：\n%s', ME.message), '错误', 'Icon', 'error');
                        return;
                    end
                    
                    % 恢复路径
                    path(oldPath);
                end

                % 保存处理后的数据（内存中保留完整数据）
                processedData = currentData;
                processedData.complex_matrix = processedMatrix;
                processedData.preprocessing_info = prepConfig;
                processedData.preprocessing_time = datetime('now');

                % 保存额外输出（如阈值矩阵、训练均值等）到内存
                if ~isempty(fieldnames(additionalOutputs))
                    processedData.additional_outputs = additionalOutputs;
                end

                % 准备保存数据：包含绘图变量、帧信息和额外输出
                saveData = struct();
                saveData.complex_matrix = processedMatrix;
                saveData.raw_matrix = rawMatrix;  % 保存预处理前的原始矩阵
                if isfield(currentData, 'frame_info')
                    saveData.frame_info = currentData.frame_info;
                end
                % 添加额外输出
                if ~isempty(fieldnames(additionalOutputs))
                    saveData.additional_outputs = additionalOutputs;
                end

                outputFile = fullfile(outputDir, sprintf('%s_processed.mat', originalName));
                save(outputFile, '-struct', 'saveData');

                % 保存到结果缓存
                % 缓存布局：1=保留, 2=CFAR, 3=非相参积累, 4=自定义, 5=相参积累, 6=检测, 7=识别
                if isempty(app.PreprocessingResults)
                    app.PreprocessingResults = cell(length(app.MatData), 7);
                end

                % 根据预处理类型保存到对应的列
                % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                cacheColumn = 6;  % 默认为自定义列（第6列）
                if strcmp(prepConfig.type, 'CFAR检测')
                    cacheColumn = 2;
                elseif strcmp(prepConfig.type, '非相参积累')
                    cacheColumn = 3;
                elseif strcmp(prepConfig.type, '非相参识别')
                    cacheColumn = 4;
                elseif strcmp(prepConfig.type, '多维识别')
                    cacheColumn = 5;
                end

                app.PreprocessingResults{app.CurrentIndex, cacheColumn} = processedData;

                success = true;
                
            catch ME
                uialert(app.UIFigure, sprintf('预处理失败：\n%s', ME.message), '错误', 'Icon', 'error');
                success = false;
            end
        end
        
        function value = convertParamValue(app, paramValue, paramType, paramTypeMap)
            % 统一的参数类型转换函数
            % paramTypeMap: 可选，用于struct内部字段的类型映射
            
            if nargin < 4
                paramTypeMap = struct();
            end
            
            switch lower(paramType)
                case 'double'
                    if isnumeric(paramValue)
                        value = double(paramValue);
                    else
                        value = str2double(paramValue);
                    end
                    
                case 'int'
                    % int类型统一转为double
                    if isnumeric(paramValue)
                        % 如果是复数，保留完整的复数信息
                        if iscomplex(paramValue)
                            value = double(paramValue); % 保留复数，不进行取整
                        else
                            value = round(double(paramValue));
                        end
                    else
                        value = round(str2double(paramValue));
                    end
                    
                case 'string'
                    if ischar(paramValue) || isstring(paramValue)
                        value = char(paramValue);
                    else
                        value = char(string(paramValue));
                    end
                    
                case 'bool'
                    if islogical(paramValue)
                        value = paramValue;
                    elseif isnumeric(paramValue)
                        value = logical(paramValue);
                    else
                        value = strcmpi(paramValue, 'true') || strcmp(paramValue, '1');
                    end
                    
                case 'struct'
                    if isstruct(paramValue)
                        % 递归转换struct内部字段
                        value = convertStructFields(app, paramValue, paramTypeMap);
                    else
                        % 尝试从JSON或MATLAB表达式解析
                        try
                            value = jsondecode(paramValue);
                            value = convertStructFields(app, value, paramTypeMap);
                        catch
                            value = eval(paramValue);
                            if ~isstruct(value)
                                error('无法转换为struct类型');
                            end
                            value = convertStructFields(app, value, paramTypeMap);
                        end
                    end
                    
                otherwise
                    value = paramValue;
            end
        end
        
        function convertedStruct = convertStructFields(app, structValue, typeMap)
            % 递归转换struct内部所有数值字段为double
            % typeMap: 字段类型映射（可选）
            
            convertedStruct = structValue;
            fieldNames = fieldnames(structValue);
            
            for i = 1:length(fieldNames)
                fieldName = fieldNames{i};
                fieldValue = structValue.(fieldName);
                
                % 如果有类型映射，按照映射转换
                if isfield(typeMap, fieldName)
                    fieldType = typeMap.(fieldName);
                    convertedStruct.(fieldName) = app.convertParamValue(fieldValue, fieldType);
                else
                    % 没有类型映射，根据值的类型智能转换
                    if isnumeric(fieldValue)
                        % 所有数值统一转为double
                        convertedStruct.(fieldName) = double(fieldValue);
                    elseif isstruct(fieldValue)
                        % 递归处理嵌套struct
                        convertedStruct.(fieldName) = convertStructFields(app, fieldValue, struct());
                    else
                        % 其他类型保持不变
                        convertedStruct.(fieldName) = fieldValue;
                    end
                end
            end
        end
        
        function success = executePreprocessingOnExternalFile(app, prepConfig)
            % 对外部文件执行预处理
            
            success = false;
            
            if ~isfield(prepConfig, 'external_file_path') || isempty(prepConfig.external_file_path)
                uialert(app.UIFigure, '未指定输入文件路径！', '错误', 'Icon', 'error');
                return;
            end
            
            inputFilePath = prepConfig.external_file_path;
            
            if ~isfile(inputFilePath)
                uialert(app.UIFigure, '输入文件不存在！', '错误', 'Icon', 'error');
                return;
            end
            
            try
                % 加载外部文件
                fileData = load(inputFilePath);
                
                % 尝试查找complex_matrix字段（支持直接字段和嵌套在结构体中的情况）
                inputMatrix = [];
                
                % 首先检查直接字段
                if isfield(fileData, 'complex_matrix')
                    inputMatrix = fileData.complex_matrix;
                else
                    % 如果没有直接字段，查找是否有包含complex_matrix的结构体
                    fileFields = fieldnames(fileData);
                    for i = 1:length(fileFields)
                        fieldName = fileFields{i};
                        fieldValue = fileData.(fieldName);
                        if isstruct(fieldValue) && isfield(fieldValue, 'complex_matrix')
                            inputMatrix = fieldValue.complex_matrix;
                            break;
                        end
                    end
                end
                
                if isempty(inputMatrix)
                    uialert(app.UIFigure, '外部文件不包含complex_matrix字段！', '错误', 'Icon', 'error');
                    return;
                end
                
                % 显示处理中状态
                oldStatus = app.StatusLabel.Text;
                app.StatusLabel.Text = sprintf('正在处理外部文件: %s ...', prepConfig.name);
                app.StatusLabel.FontColor = [1 0.6 0];
                drawnow;
                
                % 执行预处理
                if strcmp(prepConfig.scriptPath, 'default')
                    % 使用默认处理
                    processedMatrix = inputMatrix;
                else
                    % 调用自定义脚本
                    [scriptPath, scriptName, ~] = fileparts(prepConfig.scriptPath);
                    oldPath = addpath(scriptPath);
                    
                    try
                        % 准备参数（外部文件没有帧信息，只使用默认参数）
                        actualParams = prepConfig.params;

                        % 获取输出目录和文件名
                        [filePath, fileName, ~] = fileparts(inputFilePath);
                        outputDir = fullfile(filePath, prepConfig.name);
                        if ~exist(outputDir, 'dir')
                            mkdir(outputDir);
                        end

                        % 添加输出目录和文件名到参数中（供脚本使用）
                        actualParams.output_dir = outputDir;
                        actualParams.file_name = fileName;

                        % 如果外部文件包含frame_info，也尝试使用
                        if isfield(fileData, 'frame_info') && ...
                           isfield(prepConfig, 'frameInfoParams') && ...
                           ~isempty(prepConfig.frameInfoParams)

                            for k = 1:length(prepConfig.frameInfoParams)
                                paramName = prepConfig.frameInfoParams{k};
                                if isfield(fileData.frame_info, paramName)
                                    rawValue = fileData.frame_info.(paramName);
                                    if isfield(prepConfig, 'paramTypes') && isfield(prepConfig.paramTypes, paramName)
                                        paramType = prepConfig.paramTypes.(paramName);
                                        actualParams.(paramName) = app.convertParamValue(rawValue, paramType);
                                    else
                                        actualParams.(paramName) = rawValue;
                                    end
                                end
                            end
                        end

                        scriptFunc = str2func(scriptName);
                        processedMatrix = scriptFunc(inputMatrix, actualParams);
                        
                        % 检查脚本输出
                        if ~isnumeric(processedMatrix)
                            % 如果输出不是数值类型，检查是否是包含complex_matrix的结构体
                            if isstruct(processedMatrix) && isfield(processedMatrix, 'complex_matrix') && isnumeric(processedMatrix.complex_matrix)
                                % 初始化additionalOutputs
                                additionalOutputs = struct();
                                
                                % 收集所有额外输出字段（除了complex_matrix）
                                allFields = fieldnames(processedMatrix);
                                for i = 1:length(allFields)
                                    fieldName = allFields{i};
                                    if ~strcmp(fieldName, 'complex_matrix')
                                        additionalOutputs.(fieldName) = processedMatrix.(fieldName);
                                    end
                                end
                                
                                % 从结构体中提取complex_matrix
                                processedMatrix = processedMatrix.complex_matrix;
                            else
                                % 如果不是数值且不包含有效的complex_matrix字段，报错
                                error('脚本输出必须是数值矩阵或向量！');
                            end
                        else
                            % 如果输出是数值类型，确保additionalOutputs已初始化
                            additionalOutputs = struct();
                        end
                    catch ME
                        path(oldPath);
                        app.StatusLabel.Text = oldStatus;
                        app.StatusLabel.FontColor = [0 0.5 0];
                        uialert(app.UIFigure, sprintf('处理外部文件失败：\n%s', ME.message), '错误', 'Icon', 'error');
                        return;
                    end
                    
                    path(oldPath);
                end
                
                % ⭐ 关键修复：保存逻辑与当前帧处理保持一致
                % 1. 获取外部文件所在目录
                [filePath, fileName, ~] = fileparts(inputFilePath);
                
                % 2. 创建预处理名称的输出目录
                outputDir = fullfile(filePath, prepConfig.name);
                
                if ~exist(outputDir, 'dir')
                    mkdir(outputDir);
                end
                
                % 3. 准备保存数据：包含绘图变量、帧信息和额外输出
                saveData = struct();
                saveData.complex_matrix = processedMatrix;
                if isfield(fileData, 'frame_info')
                    saveData.frame_info = fileData.frame_info;
                end
                
                % 保存额外的输出信息（如果有）
                if ~isempty(fieldnames(additionalOutputs))
                    saveData.additional_outputs = additionalOutputs;
                end
                
                % 4. 生成输出文件名：原文件名_processed.mat
                outputFile = fullfile(outputDir, sprintf('%s_processed.mat', fileName));
                
                % 5. 保存文件
                save(outputFile, '-struct', 'saveData');

                % 创建处理后的数据结构，用于显示
                processedData = struct();
                processedData.complex_matrix = processedMatrix;
                processedData.preprocessing_info = prepConfig;
                processedData.preprocessing_time = datetime('now');

                % 保存额外的输出信息（如果有）
                if ~isempty(fieldnames(additionalOutputs))
                    processedData.additional_outputs = additionalOutputs;
                end
                
                % 如果文件中有帧信息，也保存
                if isfield(fileData, 'frame_info')
                    processedData.frame_info = fileData.frame_info;
                end
                
                % 保存到结果缓存，用于显示
                % 确保缓存已初始化
                if isempty(app.PreprocessingResults)
                    % 根据当前索引创建足够大的缓存
                    app.PreprocessingResults = cell(max(1, app.CurrentIndex), 7);
                elseif app.CurrentIndex > size(app.PreprocessingResults, 1)
                    % 扩展缓存以适应当前索引
                    app.PreprocessingResults = [app.PreprocessingResults; cell(app.CurrentIndex - size(app.PreprocessingResults, 1), 7)];
                end
                
                % 保存到预处理结果缓存的第4列（自定义预处理列），使用当前索引作为行索引
                app.PreprocessingResults{app.CurrentIndex, 4} = processedData;
                
                % 更新显示
                updateMultiView(app);
                
                % 恢复状态
                app.StatusLabel.Text = oldStatus;
                app.StatusLabel.FontColor = [0 0.5 0];
                
                % 显示成功信息
                uialert(app.UIFigure, sprintf('处理完成！\n输出文件: %s\n图像已更新显示', outputFile), '成功', 'Icon', 'success');
                
                success = true;
                
            catch ME
                if exist('oldStatus', 'var')
                    app.StatusLabel.Text = oldStatus;
                    app.StatusLabel.FontColor = [0 0.5 0];
                end
                uialert(app.UIFigure, sprintf('处理外部文件失败：\n%s', ME.message), '错误', 'Icon', 'error');
                success = false;
            end
        end
        
        function [processedMatrix, success] = executePreprocessingLogic(app, inputMatrix, prepConfig)
            % 通用的预处理执行逻辑
            processedMatrix = [];
            success = false;
            
            try
                % 处理参数
                actualParams = prepConfig.params;
                
                % 动态替换帧信息参数（与executePreprocessingOnCurrentData保持一致）
                if isfield(prepConfig, 'frameInfoParams') && ~isempty(prepConfig.frameInfoParams)
                    if isfield(prepConfig, 'currentData') && isfield(prepConfig.currentData, 'frame_info')
                        currentData = prepConfig.currentData;
                        for k = 1:length(prepConfig.frameInfoParams)
                            paramName = prepConfig.frameInfoParams{k};
                            if isfield(currentData.frame_info, paramName)
                                % 获取原始值
                                rawValue = currentData.frame_info.(paramName);
                                % 根据参数类型转换
                                if isfield(prepConfig, 'paramTypes') && isfield(prepConfig.paramTypes, paramName)
                                    paramType = prepConfig.paramTypes.(paramName);
                                    actualParams.(paramName) = app.convertParamValue(rawValue, paramType);
                                else
                                    % 没有类型信息，直接使用
                                    actualParams.(paramName) = rawValue;
                                end
                            end
                        end
                    end
                end
                
                % 执行预处理
                if strcmp(prepConfig.scriptPath, 'default')
                    % 使用默认处理（暂时返回原数据）
                    processedMatrix = inputMatrix;
                    uialert(app.UIFigure, '默认脚本功能暂未实现，已保存原始数据。', '提示');
                    success = true;
                else
                    % 调用自定义脚本
                    [scriptPath, scriptName, ~] = fileparts(prepConfig.scriptPath);
                    
                    % 临时添加脚本路径
                    oldPath = addpath(scriptPath);
                    
                    try
                        % 调用脚本函数
                        scriptFunc = str2func(scriptName);
                        processedMatrix = scriptFunc(inputMatrix, actualParams);
                        
                        % 验证输出
                        if ~isnumeric(processedMatrix)
                            % 如果输出不是数值类型，检查是否是包含complex_matrix的结构体
                            if isstruct(processedMatrix) && isfield(processedMatrix, 'complex_matrix') && isnumeric(processedMatrix.complex_matrix)
                                % 初始化additionalOutputs
                                additionalOutputs = struct();
                                
                                % 收集所有额外输出字段（除了complex_matrix）
                                allFields = fieldnames(processedMatrix);
                                for i = 1:length(allFields)
                                    fieldName = allFields{i};
                                    if ~strcmp(fieldName, 'complex_matrix')
                                        additionalOutputs.(fieldName) = processedMatrix.(fieldName);
                                    end
                                end
                                
                                % 从结构体中提取complex_matrix
                                processedMatrix = processedMatrix.complex_matrix;
                            else
                                % 如果不是数值且不包含有效的complex_matrix字段，报错
                                error('脚本输出必须是数值矩阵或向量！');
                            end
                        else
                            % 如果输出是数值类型，确保additionalOutputs已初始化
                            additionalOutputs = struct();
                        end
                        
                        success = true;
                        
                    catch ME
                        path(oldPath);  % 恢复路径
                        uialert(app.UIFigure, sprintf('执行预处理脚本失败：\n%s', ME.message), '错误', 'Icon', 'error');
                        return;
                    end
                    
                    % 恢复路径
                    path(oldPath);
                end
                
            catch ME
                uialert(app.UIFigure, sprintf('预处理逻辑执行失败！\n错误信息：%s', ME.message), '错误', 'Icon', 'error');
            end
        end

        function updateMultiView(app)
            % 更新多视图显示（动态映射关系，按预处理顺序对应ImageAxes）

            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                return;
            end

            % 清空所有axes（彻底清除包括文字、图例等所有元素）
            cla(app.ImageAxes1, 'reset');
            cla(app.ImageAxes2, 'reset');
            cla(app.ImageAxes3, 'reset');
            cla(app.ImageAxes4, 'reset');

            % 清除可能残留的colorbar和legend
            try
                colorbar(app.ImageAxes1, 'off');
                colorbar(app.ImageAxes2, 'off');
                colorbar(app.ImageAxes3, 'off');
                colorbar(app.ImageAxes4, 'off');
            catch
                % 忽略错误
            end

            % 默认隐藏所有视图
            app.ImageAxes1.Visible = 'off';
            app.ImageAxes2.Visible = 'off';
            app.ImageAxes3.Visible = 'off';
            app.ImageAxes4.Visible = 'off';

            % 动态收集所有要显示的视图数据
            viewList = {};  % {data, title, sourceColumn}的cell数组

            % 1. 收集原图
            if app.ShowOriginalCheck.Value
                viewList{end+1} = struct('data', app.MatData{app.CurrentIndex}, 'title', '原图', 'sourceColumn', 0);
            end

            % 2. 收集所有预处理结果（按顺序遍历所有列）
            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                % 遍历PreprocessingResults的第2-7列
                for col = 2:min(7, size(app.PreprocessingResults, 2))
                    if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                        result = app.PreprocessingResults{app.CurrentIndex, col};

                        % 获取标题（优先从结果中的name字段获取）
                        if isstruct(result) && isfield(result, 'name')
                            title = result.name;
                        elseif isstruct(result) && isfield(result, 'preprocessing_info') && isfield(result.preprocessing_info, 'name')
                            title = result.preprocessing_info.name;
                        else
                            % 如果没有name字段，使用默认标题
                            % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                            if col == 2
                                title = 'CFAR检测';
                            elseif col == 3
                                title = '非相参积累';
                            elseif col == 4
                                title = '非相参识别';
                            elseif col == 5
                                title = '多维识别';
                            elseif col == 6 || col == 7
                                title = sprintf('自定义预处理%d', col-5);
                            else
                                title = sprintf('预处理%d', col-1);
                            end
                        end

                        viewList{end+1} = struct('data', result, 'title', title, 'sourceColumn', col);
                    end
                end
            end

            % 如果没有任何视图，至少显示原图
            if isempty(viewList)
                viewList{end+1} = struct('data', app.MatData{app.CurrentIndex}, 'title', '原图', 'sourceColumn', 0);
            end

            % 统计需要显示的视图数量
            numViews = length(viewList);

            % 所有axes的引用（按顺序分配）
            allAxes = {app.ImageAxes1, app.ImageAxes2, app.ImageAxes3, app.ImageAxes4};

            % 限制最多显示4个视图
            if numViews > 4
                numViews = 4;
                viewList = viewList(1:4);
            end

            % 根据需要显示的视图数量调整布局
            switch numViews
                case 1
                    % 单图全屏
                    ax = allAxes{1};
                    ax.Visible = 'on';
                    ax.Layout.Row = [1 2];
                    ax.Layout.Column = [1 2];
                    displayImageInAxes(app, ax, viewList{1}.data, viewList{1}.title, viewList{1}.sourceColumn);

                case 2
                    % 两图横向排列
                    for i = 1:2
                        ax = allAxes{i};
                        ax.Visible = 'on';
                        ax.Layout.Row = [1 2];
                        ax.Layout.Column = i;
                        displayImageInAxes(app, ax, viewList{i}.data, viewList{i}.title, viewList{i}.sourceColumn);
                    end

                case 3
                    % 三图：上面2个，左下1个
                    for i = 1:3
                        ax = allAxes{i};
                        ax.Visible = 'on';
                        if i <= 2
                            ax.Layout.Row = 1;
                            ax.Layout.Column = i;
                        else
                            ax.Layout.Row = 2;
                            ax.Layout.Column = 1;
                        end
                        displayImageInAxes(app, ax, viewList{i}.data, viewList{i}.title, viewList{i}.sourceColumn);
                    end

                case 4
                    % 四图：2x2
                    for i = 1:4
                        ax = allAxes{i};
                        ax.Visible = 'on';
                        ax.Layout.Row = ceil(i/2);
                        ax.Layout.Column = mod(i-1, 2) + 1;
                        displayImageInAxes(app, ax, viewList{i}.data, viewList{i}.title, viewList{i}.sourceColumn);
                    end
            end

            % 更新关闭按钮位置
            updateCloseButtonPositions(app);
        end
        
        function displayImageInAxes(app, ax, data, titleStr, sourceColumn)
            % 在指定axes中显示图像
            % ax: 要显示的axes
            % data: 要显示的数据
            % titleStr: 标题字符串
            % sourceColumn: 数据来源列（0=原图, 2=CFAR, 3=非相参积累, 4=自定义预处理）

            % 彻底清空axes（包括文字、图例、colorbar等所有元素）
            cla(ax, 'reset');

            % 清除可能残留的colorbar
            try
                colorbar(ax, 'off');
            catch
                % 忽略错误
            end
            
            % 优先检查是否有cached_figure（figure缓存）
            if isfield(data, 'additional_outputs') && isfield(data.additional_outputs, 'cached_figure')
                % 从缓存的figure复制内容到UI axes
                try
                    cachedFig = data.additional_outputs.cached_figure;

                    % 获取cached figure中的axes
                    figAxes = findobj(cachedFig, 'Type', 'axes');

                    if ~isempty(figAxes)
                        % 获取第一个axes
                        sourceAx = figAxes(1);

                        % 复制所有图形对象（包括text、line、image、surface等）
                        copyobj(allchild(sourceAx), ax);

                        % 复制axes属性
                        ax.XLim = sourceAx.XLim;
                        ax.YLim = sourceAx.YLim;
                        if ~isempty(sourceAx.ZLim)
                            ax.ZLim = sourceAx.ZLim;
                        end
                        ax.XLabel.String = sourceAx.XLabel.String;
                        ax.YLabel.String = sourceAx.YLabel.String;
                        if ~isempty(sourceAx.ZLabel.String)
                            ax.ZLabel.String = sourceAx.ZLabel.String;
                        end

                        % 复制Title（包括其字体、颜色等属性）
                        if ~isempty(sourceAx.Title.String)
                            ax.Title.String = sourceAx.Title.String;
                            ax.Title.FontSize = sourceAx.Title.FontSize;
                            ax.Title.FontWeight = sourceAx.Title.FontWeight;
                            ax.Title.Color = sourceAx.Title.Color;
                            ax.Title.Interpreter = sourceAx.Title.Interpreter;
                        end

                        % 复制XLabel、YLabel、ZLabel的字体属性
                        ax.XLabel.FontSize = sourceAx.XLabel.FontSize;
                        ax.XLabel.Color = sourceAx.XLabel.Color;
                        ax.YLabel.FontSize = sourceAx.YLabel.FontSize;
                        ax.YLabel.Color = sourceAx.YLabel.Color;
                        if ~isempty(sourceAx.ZLabel.String)
                            ax.ZLabel.FontSize = sourceAx.ZLabel.FontSize;
                            ax.ZLabel.Color = sourceAx.ZLabel.Color;
                        end

                        % 复制网格线设置
                        ax.XGrid = sourceAx.XGrid;
                        ax.YGrid = sourceAx.YGrid;
                        ax.ZGrid = sourceAx.ZGrid;
                        ax.GridLineStyle = sourceAx.GridLineStyle;
                        ax.GridColor = sourceAx.GridColor;
                        ax.GridAlpha = sourceAx.GridAlpha;

                        % 复制colormap
                        if ~isempty(sourceAx.Colormap)
                            colormap(ax, sourceAx.Colormap);
                        end

                        % 检查是否有colorbar，如果有则复制
                        cb = findobj(cachedFig, 'Type', 'colorbar');
                        if ~isempty(cb)
                            newCb = colorbar(ax);
                            % 复制colorbar的标签
                            if ~isempty(cb(1).Label.String)
                                newCb.Label.String = cb(1).Label.String;
                                newCb.Label.FontSize = cb(1).Label.FontSize;
                            end
                        end

                        % 检查是否有legend，如果有则复制
                        leg = findobj(cachedFig, 'Type', 'legend');
                        if ~isempty(leg)
                            % 获取legend的字符串和位置
                            legStrings = leg(1).String;
                            legLocation = leg(1).Location;
                            if ~isempty(legStrings)
                                newLeg = legend(ax, legStrings);
                                newLeg.Location = legLocation;
                                newLeg.FontSize = leg(1).FontSize;
                            end
                        end
                    end

                catch ME
                    % 如果使用缓存失败，回退到显示complex_matrix
                    warning('使用cached_figure失败：%s，将显示复数矩阵', ME.message);

                    if ~isfield(data, 'complex_matrix')
                        return;
                    end

                    complexMatrix = data.complex_matrix;
                    displayDefaultImage(app, ax, complexMatrix, titleStr);
                end
            % 向后兼容：检查是否有.fig文件需要显示（旧方式）
            elseif isfield(data, 'figure_file') && ~isempty(data.figure_file) && isfile(data.figure_file)
                % 加载并显示.fig文件
                try
                    % 加载.fig文件
                    figHandle = openfig(data.figure_file, 'invisible');

                    % 获取figure中的axes
                    figAxes = findobj(figHandle, 'Type', 'axes');

                    if ~isempty(figAxes)
                        % 获取第一个axes（应该只有一个）
                        sourceAx = figAxes(1);

                        % 复制所有图形对象（包括text、line、image、surface等）
                        copyobj(allchild(sourceAx), ax);

                        % 复制axes属性
                        ax.XLim = sourceAx.XLim;
                        ax.YLim = sourceAx.YLim;
                        if ~isempty(sourceAx.ZLim)
                            ax.ZLim = sourceAx.ZLim;
                        end
                        ax.XLabel.String = sourceAx.XLabel.String;
                        ax.YLabel.String = sourceAx.YLabel.String;
                        if ~isempty(sourceAx.ZLabel.String)
                            ax.ZLabel.String = sourceAx.ZLabel.String;
                        end

                        % 复制Title（包括其字体、颜色等属性）
                        if ~isempty(sourceAx.Title.String)
                            ax.Title.String = sourceAx.Title.String;
                            ax.Title.FontSize = sourceAx.Title.FontSize;
                            ax.Title.FontWeight = sourceAx.Title.FontWeight;
                            ax.Title.Color = sourceAx.Title.Color;
                            ax.Title.Interpreter = sourceAx.Title.Interpreter;
                        end

                        % 复制XLabel、YLabel、ZLabel的字体属性
                        ax.XLabel.FontSize = sourceAx.XLabel.FontSize;
                        ax.XLabel.Color = sourceAx.XLabel.Color;
                        ax.YLabel.FontSize = sourceAx.YLabel.FontSize;
                        ax.YLabel.Color = sourceAx.YLabel.Color;
                        if ~isempty(sourceAx.ZLabel.String)
                            ax.ZLabel.FontSize = sourceAx.ZLabel.FontSize;
                            ax.ZLabel.Color = sourceAx.ZLabel.Color;
                        end

                        % 复制网格线设置
                        ax.XGrid = sourceAx.XGrid;
                        ax.YGrid = sourceAx.YGrid;
                        ax.ZGrid = sourceAx.ZGrid;
                        ax.GridLineStyle = sourceAx.GridLineStyle;
                        ax.GridColor = sourceAx.GridColor;
                        ax.GridAlpha = sourceAx.GridAlpha;

                        % 复制colormap
                        if ~isempty(sourceAx.Colormap)
                            colormap(ax, sourceAx.Colormap);
                        end

                        % 检查是否有colorbar，如果有则复制
                        cb = findobj(figHandle, 'Type', 'colorbar');
                        if ~isempty(cb)
                            newCb = colorbar(ax);
                            % 复制colorbar的标签
                            if ~isempty(cb(1).Label.String)
                                newCb.Label.String = cb(1).Label.String;
                                newCb.Label.FontSize = cb(1).Label.FontSize;
                            end
                        end

                        % 检查是否有legend，如果有则复制
                        leg = findobj(figHandle, 'Type', 'legend');
                        if ~isempty(leg)
                            % 获取legend的字符串和位置
                            legStrings = leg(1).String;
                            legLocation = leg(1).Location;
                            if ~isempty(legStrings)
                                newLeg = legend(ax, legStrings);
                                newLeg.Location = legLocation;
                                newLeg.FontSize = leg(1).FontSize;
                            end
                        end
                    end

                    % 关闭临时figure
                    close(figHandle);

                catch ME
                    % 如果加载.fig文件失败，回退到显示complex_matrix
                    warning('加载.fig文件失败：%s，将显示复数矩阵', ME.message);

                    if ~isfield(data, 'complex_matrix')
                        return;
                    end

                    complexMatrix = data.complex_matrix;
                    displayDefaultImage(app, ax, complexMatrix, titleStr);
                end
            else
                % 没有额外输出也没有.fig文件，显示图像（使用现有的显示逻辑）
                if ~isfield(data, 'complex_matrix')
                    return;
                end

                complexMatrix = data.complex_matrix;
                displayDefaultImage(app, ax, complexMatrix, titleStr);
            end
            % 设置标题功能
            if sourceColumn == 0
                % 原图：普通标题
                title(ax, titleStr, 'FontSize', 10, 'Interpreter', 'none');
            else
                % 预处理视图：添加关闭功能
                titleText = sprintf('%s  [关闭×]', titleStr);
                t = title(ax, titleText, 'FontSize', 10, 'Interpreter', 'none');

                % 标题文本添加点击事件，使用sourceColumn而不是viewIndex
                t.ButtonDownFcn = @(~,~)closeSubView(app, sourceColumn);

                % 改变鼠标指针为手型（提示可点击）
                ax.ButtonDownFcn = @(~,~)closeSubView(app, sourceColumn);
            end
        end

        function displayDefaultImage(app, ax, complexMatrix, titleStr)
            % 显示默认图像（复数矩阵）
            % 判断数据类型并显示
            [~, filename] = fileparts(app.MatFiles{app.CurrentIndex});
            isSAR = startsWith(lower(filename), 'sar');

            if isSAR
                displaySARInAxes(app, ax, complexMatrix, titleStr);
            elseif isvector(complexMatrix)
                displayWaveformInAxes(app, ax, complexMatrix, titleStr);
            else
                % 使用当前播放模式
                playMode = app.PlayModeCombo.Value;
                switch playMode
                    case '原图'
                        displayMatrixImagescInAxes(app, ax, complexMatrix, false, titleStr);
                    case '原图dB'
                        displayMatrixImagescInAxes(app, ax, complexMatrix, true, titleStr);
                    case '3D图像'
                        displayMatrixMeshInAxes(app, ax, complexMatrix, false, titleStr);
                    case '3D图像dB'
                        displayMatrixMeshInAxes(app, ax, complexMatrix, true, titleStr);
                end
            end
        end

        function displayMatrixImagescInAxes(app, ax, complexMatrix, useDB, titleStr)
            % 在指定axes中显示imagesc图像
            view(ax, 2);
            ax.Visible = 'on';  % 强制显示坐标轴
            amplitudeMatrix = abs(complexMatrix);
            
            if useDB
                displayMatrix = 20 * log10(amplitudeMatrix + eps);
            else
                displayMatrix = amplitudeMatrix;
            end
            
            [rows, cols] = size(displayMatrix);
            imagesc(ax, [1 cols], [1 rows], displayMatrix);
            ax.YDir = 'normal';
            colormap(ax, parula);

            % 设置颜色范围，处理min=max的情况
            minVal = min(displayMatrix(:));
            maxVal = max(displayMatrix(:));
            if maxVal > minVal
                caxis(ax, [minVal, maxVal]);
            else
                % 所有值相同，设置一个小范围
                caxis(ax, [minVal-eps, minVal+eps]);
            end
            
            title(ax, titleStr, 'FontSize', 10);
            xlabel(ax, '距离');
            ylabel(ax, '多普勒');
            
            axis(ax, 'tight');
            set(ax, 'DataAspectRatioMode', 'auto');
            ax.Box = 'on';
            ax.XTickMode = 'auto';
            ax.YTickMode = 'auto';
            ax.YDir = 'normal';  % 添加
            ax.Visible = 'on';    % 添加
        end
        
        function displayMatrixMeshInAxes(app, ax, complexMatrix, useDB, titleStr)
            % 在指定axes中显示mesh图像
            amplitudeMatrix = abs(complexMatrix);
            
            if useDB
                displayMatrix = 20 * log10(amplitudeMatrix + eps);
                zlabelStr = '幅值 (dB)';
            else
                displayMatrix = amplitudeMatrix;
                zlabelStr = '幅值';
            end
            
            [rows, cols] = size(displayMatrix);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            cla(ax);
            view(ax, 3);
            mesh(ax, X, Y, displayMatrix);
            colormap(ax, parula);
            
            title(ax, titleStr, 'FontSize', 10);
            xlabel(ax, '距离');
            ylabel(ax, '多普勒');
            zlabel(ax, zlabelStr);
            
            view(ax, 45, 30);
            grid(ax, 'on');
            ax.Box = 'on';
            ax.Visible = 'on';  % 添加：确保坐标轴可见
        end
        
        function displaySARInAxes(app, ax, complexMatrix, titleStr)
            % 在指定axes中显示SAR图像
            view(ax, 2);
            amplitudeMatrix = abs(complexMatrix);
            normalizedMatrix = mat2gray(amplitudeMatrix);
            
            imshow(normalizedMatrix, 'Parent', ax);
            colormap(ax, gray);
            axis(ax, 'on');
            
            title(ax, titleStr, 'FontSize', 10);
            
            [rows, cols] = size(normalizedMatrix);
            x_margin = cols * 0.05;
            y_margin = rows * 0.05;
            xlim(ax, [1 - x_margin, cols + x_margin]);
            ylim(ax, [1 - y_margin, rows + y_margin]);
            
            set(ax, 'DataAspectRatioMode', 'auto');
            ax.Box = 'on';
        end
        
        function displayWaveformInAxes(app, ax, complexMatrix, titleStr)
            % 在指定axes中显示波形图
            view(ax, 2);
            vectorData = complexMatrix(:);
            
            if isreal(vectorData)
                plot(ax, 1:length(vectorData), vectorData, 'b-', 'LineWidth', 1);
            else
                plot(ax, 1:length(vectorData), real(vectorData), 'b-', 'DisplayName', '实部');
                hold(ax, 'on');
                plot(ax, 1:length(vectorData), imag(vectorData), 'r-', 'DisplayName', '虚部');
                plot(ax, 1:length(vectorData), abs(vectorData), 'k-', 'LineWidth', 1.5, 'DisplayName', '幅值');
                hold(ax, 'off');
                legend(ax, 'Location', 'best');
            end
            
            title(ax, titleStr, 'FontSize', 10);
            xlabel(ax, '样本点');
            ylabel(ax, '幅值');
            grid(ax, 'on');
            ax.Box = 'on';
            ax.YDir = 'normal';  % 添加
            ax.Visible = 'on';    % 添加
        end
        
        function clearAllPreprocessing(app)
            % 清除所有预处理
            
            answer = uiconfirm(app.UIFigure, '确定要清除所有预处理吗？', '确认', ...
                'Options', {'确定', '取消'}, 'DefaultOption', 1, 'CancelOption', 2);
            
            if strcmp(answer, '确定')
                % 清空预处理列表和结果
                app.PreprocessingList = {};
                app.PreprocessingResults = {};
                
                % 重置按钮状态（保留默认预处理按钮）
                app.ShowOriginalCheck.Value = true;
                app.ShowPrep3Btn.Enable = 'off';
                app.ShowPrep3Btn.Text = '预处理';
                % 默认预处理按钮保持启用和文本不变
                % 非相参积累、非相参识别、CFAR检测、多维识别按钮是默认预处理，不清除

                % 重置识别按钮状态：只有第一步按钮可用，识别按钮置灰
                app.ShowPrep2Btn.Enable = 'on';  % 非相参积累
                app.ShowPrep1Btn.Enable = 'on';  % CFAR检测
                app.ShowCoherentBtn.Enable = 'off';  % 非相参识别（置灰）
                app.ShowDetectionBtn.Enable = 'off';  % 多维识别（置灰）

                % 更新按钮状态
                app.AddPrepBtn.Enable = 'on';
                app.ClearPrepBtn.Enable = 'off';
                
                % 强制使用单视图显示
                if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                    displaySingleView(app);

                    % 更新帧信息
                    [~, filename, ext] = fileparts(app.MatFiles{app.CurrentIndex});
                    app.FrameInfoLabel.Text = sprintf('【%d/%d】%s%s', ...
                        app.CurrentIndex, length(app.MatData), filename, ext);
                end

                % 将GUI窗口置顶
                figure(app.UIFigure);
                drawnow;
            end
        end


        function onShowOriginalChanged(app)
            % 原图复选框改变回调
            if ~app.ShowOriginalCheck.Value
                % 原图不能取消，强制选中
                app.ShowOriginalCheck.Value = true;
                return;
            end
            
            % 重新显示
            updateMultiView(app);
        end

        function params = getDefaultParams(prepType)
            % 获取预处理类型的默认参数
            
            switch prepType
                case 'CFAR检测'
                    params = {
                        'pfa', '1e-6', 'double';
                        'window_size', '16', 'int';
                        'guard_cells', '4', 'int';
                        'method', 'CA', 'string'
                    };
                    
                case '自适应滤波'
                    params = {
                        'filter_type', 'gaussian', 'string';
                        'kernel_size', '5', 'int';
                        'sigma', '1.0', 'double'
                    };
                    
                case 'MTI处理'
                    params = {
                        'num_pulses', '8', 'int';
                        'clutter_threshold', '0.1', 'double';
                        'filter_order', '2', 'int'
                    };
                    
                case '门限检测'
                    params = {
                        'threshold', '0.5', 'double';
                        'method', 'adaptive', 'string';
                        'scale_factor', '1.5', 'double'
                    };
                    
                otherwise
                    params = {};
            end
        end
        
        function [fieldNames, fieldUnits] = readFieldNamesFromLevel1Excel(app, currentPath)
            % 从一级目录的Excel文件读取帧信息字段显示名称和单位
            % 总是从一级目录读取Excel文件的第1行（带单位的字段名）
            % 同时提取字段名中的单位（如"高度(m)"中的"(m)"）

            fieldNames = {};
            fieldUnits = {};  % 存储每个字段的单位

            if isempty(app.CurrentDataPath) || isempty(currentPath)
                return;
            end

            % ⭐ 规范化路径，统一使用系统分隔符
            currentPath = strrep(currentPath, '/', filesep);
            currentPath = strrep(currentPath, '\', filesep);
            rootPath = strrep(app.CurrentDataPath, '/', filesep);
            rootPath = strrep(rootPath, '\', filesep);

            % 确保根目录路径以分隔符结尾，便于后续替换
            if ~endsWith(rootPath, filesep)
                rootPath = [rootPath, filesep];
            end

            % ⭐ 检查currentPath是否在rootPath下
            if ~startsWith(currentPath, rootPath)
                % 路径不匹配，可能是用户选择了其他位置的文件夹
                warning('MatViewerTool:PathMismatch', ...
                    '当前选择的路径不在数据根目录下\n数据根目录: %s\n当前路径: %s', ...
                    app.CurrentDataPath, currentPath);
                return;
            end

            % ⭐ 计算一级目录路径
            relativePath = strrep(currentPath, rootPath, '');
            pathParts = strsplit(relativePath, filesep);
            pathParts = pathParts(~cellfun(@isempty, pathParts));

            % 如果没有路径部分，说明currentPath就是根目录
            if isempty(pathParts)
                level1Path = currentPath;
            else
                % 获取第一级目录
                level1Path = fullfile(rootPath, pathParts{1});
            end

            % 在一级目录查找Excel文件
            excelPath = '';
            excelFiles = dir(fullfile(level1Path, '*.xlsx'));
            if isempty(excelFiles)
                excelFiles = dir(fullfile(level1Path, '*.xls'));
            end

            if ~isempty(excelFiles)
                % 一级目录找到Excel文件
                excelPath = fullfile(level1Path, excelFiles(1).name);
            end

            % 如果没有找到Excel文件，返回空（将使用默认字段名）
            if isempty(excelPath)
                return;
            end

            % 读取Excel文件
            try
                % 读取Excel数据 (使用 readcell 替代 xlsread)
                raw = readcell(excelPath);

                if size(raw, 1) < 1
                    warning('MatViewerTool:InsufficientRows', ...
                        'Excel文件行数不足（需要至少1行）: %s', excelPath);
                    return;
                end

                % ⭐ 读取第1行（带单位的字段名），从第2列（B列）开始
                row1Data = raw(1, 2:end);

                % 提取非空单元格的值
                for i = 1:length(row1Data)
                    cellValue = row1Data{i};

                    % 检查是否为空
                    isEmpty = false;
                    if isempty(cellValue)
                        isEmpty = true;
                    elseif isnumeric(cellValue)
                        if isnan(cellValue)
                            isEmpty = true;
                        end
                    elseif ischar(cellValue) || isstring(cellValue)
                        if isempty(strtrim(char(cellValue)))
                            isEmpty = true;
                        end
                    end

                    % 如果非空，添加到列表
                    if ~isEmpty
                        fieldNameStr = '';
                        if isnumeric(cellValue)
                            fieldNameStr = num2str(cellValue);
                        elseif ischar(cellValue) || isstring(cellValue)
                            fieldNameStr = char(cellValue);
                        else
                            % 其他类型转换为字符串
                            fieldNameStr = char(string(cellValue));
                        end

                        % 提取单位（括号中的内容，如"高度(m)"中的"(m)"）
                        unitStr = '';
                        cleanFieldName = fieldNameStr;  % 默认使用原字段名
                        unitMatch = regexp(fieldNameStr, '\([^)]+\)', 'match');
                        if ~isempty(unitMatch)
                            unitStr = unitMatch{1};  % 保留完整括号，如"(m)"
                            % 从字段名中移除单位部分，如"高度(m)" -> "高度"
                            cleanFieldName = regexprep(fieldNameStr, '\([^)]+\)', '');
                        end

                        fieldNames{end+1} = cleanFieldName;
                        fieldUnits{end+1} = unitStr;
                    end
                end

            catch ME
                warning('MatViewerTool:ReadExcelError', ...
                    '读取Excel文件失败: %s\n文件路径: %s', ...
                    ME.message, excelPath);
            end
        end

        function executePrepOnCurrentFrame(app, prepIndex)
            % 对当前帧执行预处理并显示
            % prepIndex: 1, 2, 3, 或 -1表示使用最新的预处理

            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                uialert(app.UIFigure, '请先导入数据', '提示');
                return;
            end

            % 如果prepIndex <= 0，使用最新的预处理
            if prepIndex <= 0
                if isempty(app.PreprocessingList)
                    uialert(app.UIFigure, '未配置任何预处理', '提示');
                    return;
                end
                prepIndex = length(app.PreprocessingList);
            end

            if prepIndex > length(app.PreprocessingList)
                uialert(app.UIFigure, sprintf('预处理%d未配置', prepIndex), '提示');
                return;
            end

            prepConfig = app.PreprocessingList{prepIndex};

            % 检查当前显示的视图数量
            numCurrentViews = checkCurrentViewCount(app);

            % 检查即将添加的处理是否已经存在（会替换现有视图）
            willReplaceExisting = false;
            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                % 根据预处理类型确定目标列
                % 缓存映射：1=保留, 2=CFAR检测, 3=非相参积累, 4=非相参识别, 5=多维识别, 6-7=自定义
                targetColumn = [];
                if strcmp(prepConfig.type, 'CFAR检测')
                    targetColumn = 2;
                elseif strcmp(prepConfig.type, '非相参积累')
                    targetColumn = 3;
                elseif strcmp(prepConfig.type, '非相参识别')
                    targetColumn = 4;
                elseif strcmp(prepConfig.type, '多维识别')
                    targetColumn = 5;
                else
                    % 自定义预处理，检查是否已存在同名结果
                    for col = 4:size(app.PreprocessingResults, 2)
                        if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                            result = app.PreprocessingResults{app.CurrentIndex, col};
                            if isfield(result, 'preprocessing_info') && ...
                               isfield(result.preprocessing_info, 'name') && ...
                               strcmp(result.preprocessing_info.name, prepConfig.name)
                                targetColumn = col;
                                break;
                            end
                        end
                    end
                end

                if ~isempty(targetColumn) && targetColumn <= size(app.PreprocessingResults, 2)
                    willReplaceExisting = ~isempty(app.PreprocessingResults{app.CurrentIndex, targetColumn});
                end
            end

            % 如果已经有4个视图且不是替换现有的，需要让用户选择关闭哪个
            if numCurrentViews >= 4 && ~willReplaceExisting
                % 弹窗让用户选择关闭哪个视图
                success = promptToCloseView(app);
                if ~success
                    % 用户取消了操作
                    return;
                end
            end

            % 显示处理中状态
            oldStatus = app.StatusLabel.Text;
            app.StatusLabel.Text = sprintf('正在执行 %s ...', prepConfig.name);
            app.StatusLabel.FontColor = [1 0.6 0];
            drawnow;

            % 执行预处理
            success = executePreprocessingOnCurrentData(app, prepConfig);

            % 恢复状态
            app.StatusLabel.Text = oldStatus;
            app.StatusLabel.FontColor = [0 0.5 0];

            if success
                % 更新多视图显示
                updateMultiView(app);
            else
                uialert(app.UIFigure, sprintf('执行 %s 失败', prepConfig.name), '错误');
            end
        end

        function executeDefaultPrep(app, defaultPrepIndex)
            % 执行默认预处理
            % defaultPrepIndex: 1=非相参积累, 2=非相参识别, 3=CFAR检测, 4=多维识别

            if isempty(app.MatData) || app.CurrentIndex > length(app.MatData)
                uialert(app.UIFigure, '请先导入数据', '提示');
                return;
            end

            % 检查当前显示的视图数量
            numCurrentViews = checkCurrentViewCount(app);

            % 检查即将添加的处理是否已经存在
            cacheIndexMap = [3, 4, 2, 5];  % 1=非相参积累→列3, 2=非相参识别→列4, 3=CFAR检测→列2, 4=多维识别→列5
            targetCacheIndex = cacheIndexMap(defaultPrepIndex);
            willReplaceExisting = false;

            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                if targetCacheIndex <= size(app.PreprocessingResults, 2)
                    willReplaceExisting = ~isempty(app.PreprocessingResults{app.CurrentIndex, targetCacheIndex});
                end
            end

            % 如果已经有4个视图且不是替换现有的，需要让用户选择关闭哪个
            if numCurrentViews >= 4 && ~willReplaceExisting
                % 弹窗让用户选择关闭哪个视图
                success = promptToCloseView(app);
                if ~success
                    % 用户取消了操作
                    return;
                end
            end

            % 获取当前脚本所在目录
            scriptPath = fileparts(mfilename('fullpath'));

            % 根据索引选择默认脚本
            if defaultPrepIndex == 1
                % 非相参积累
                scriptFile = fullfile(scriptPath, 'default_noncoherent_integration.m');
                prepName = '非相参积累';
                prepType = '非相参积累';
            elseif defaultPrepIndex == 2
                % 非相参识别
                scriptFile = fullfile(scriptPath, 'default_noncoherent_recognition.m');
                prepName = '非相参识别';
                prepType = '非相参识别';
            elseif defaultPrepIndex == 3
                % CFAR检测
                scriptFile = fullfile(scriptPath, 'default_cfar.m');
                prepName = 'CFAR检测';
                prepType = 'CFAR检测';
            elseif defaultPrepIndex == 4
                % 多维识别
                scriptFile = fullfile(scriptPath, 'default_multidim_recognition.m');
                prepName = '多维识别';
                prepType = '多维识别';
            else
                return;
            end

            % 检查脚本文件是否存在
            if ~exist(scriptFile, 'file')
                uialert(app.UIFigure, sprintf('默认预处理脚本不存在：\n%s', scriptFile), '错误');
                return;
            end

            % 读取脚本内容并解析参数
            try
                fid = fopen(scriptFile, 'r');
                if fid == -1
                    uialert(app.UIFigure, '无法打开默认预处理脚本', '错误');
                    return;
                end
                content = fread(fid, '*char')';
                fclose(fid);

                % 解析参数
                % 由于MATLAB的可选捕获组在未匹配时不会出现在结果中，需要分两次匹配

                % 模式1: 有默认值（3个捕获组）
                % 使用 [^\n\r]+ 确保只匹配到行尾，避免贪婪匹配
                patternWithDefault = '%%?\s*PARAM:\s*(\w+)\s*,\s*(\w+)\s*,\s*([^\n\r]+)';
                matchesWithDefault = regexp(content, patternWithDefault, 'tokens');

                % 模式2: 无默认值（2个捕获组）
                patternWithoutDefault = '%%?\s*PARAM:\s*(\w+)\s*,\s*(\w+)\s*$';
                matchesWithoutDefault = regexp(content, patternWithoutDefault, 'tokens', 'lineanchors');

                % 合并结果：将无默认值的匹配添加空字符串作为第3组
                paramMatches = matchesWithDefault;
                for i = 1:length(matchesWithoutDefault)
                    % 为无默认值的参数添加空字符串作为第3组
                    paramMatches{end+1} = {matchesWithoutDefault{i}{1}, matchesWithoutDefault{i}{2}, ''};
                end

                % DEBUG: 打印匹配结果
                fprintf('\n=== executeDefaultPrep 参数解析调试信息 ===\n');
                fprintf('预处理类型: %s\n', prepName);
                fprintf('有默认值的参数: %d 个\n', length(matchesWithDefault));
                fprintf('无默认值的参数: %d 个\n', length(matchesWithoutDefault));
                fprintf('总共参数: %d 个\n', length(paramMatches));

                % 构建参数结构
                params = struct();

                % 获取当前帧信息
                hasFrameInfo = false;
                frameInfoData = struct();
                if ~isempty(app.MatData) && app.CurrentIndex <= length(app.MatData)
                    currentData = app.MatData{app.CurrentIndex};
                    if isfield(currentData, 'frame_info')
                        hasFrameInfo = true;
                        frameInfoData = currentData.frame_info;
                    end
                end

                fprintf('hasFrameInfo = %d\n', hasFrameInfo);

                % 填充参数值
                if ~isempty(paramMatches)
                    for i = 1:length(paramMatches)
                        fprintf('\n--- 参数 %d ---\n', i);

                        paramName = strtrim(paramMatches{i}{1});
                        paramType = strtrim(paramMatches{i}{2});
                        defaultValueStr = strtrim(paramMatches{i}{3});
                        hasDefaultValue = ~isempty(defaultValueStr);

                        fprintf('参数名: %s\n', paramName);
                        fprintf('参数类型: %s\n', paramType);
                        fprintf('默认值: ''%s''\n', defaultValueStr);
                        fprintf('是否有默认值: %d\n', hasDefaultValue);

                        % 优先从帧信息中获取
                        if hasFrameInfo && isfield(frameInfoData, paramName)
                            rawValue = frameInfoData.(paramName);
                            fprintf('从frame_info获取参数值 (原始类型: %s)\n', class(rawValue));
                            % 进行类型转换（确保类型正确，如int64→double）
                            paramValue = app.convertParamValue(rawValue, paramType);
                            fprintf('类型转换后 (类型: %s)\n', class(paramValue));
                        elseif hasDefaultValue
                            % 使用默认值
                            fprintf('使用脚本默认值: ''%s''\n', defaultValueStr);
                            paramValue = MatViewerTool.parseParamValue(defaultValueStr, paramType);
                            try
                                fprintf('解析后的值: %s (类型: %s)\n', mat2str(paramValue), class(paramValue));
                            catch
                                fprintf('解析后的值: [复杂类型] (类型: %s)\n', class(paramValue));
                            end
                        else
                            % 无默认值，使用类型默认值
                            paramValue = MatViewerTool.getTypeDefaultValue(paramType);
                            try
                                fprintf('使用类型默认值: %s (类型: %s)\n', mat2str(paramValue), class(paramValue));
                            catch
                                fprintf('使用类型默认值: [复杂类型] (类型: %s)\n', class(paramValue));
                            end
                        end

                        params.(paramName) = paramValue;
                        fprintf('最终存入params.%s (类型: %s)\n', paramName, class(paramValue));
                    end
                end

                fprintf('\n=== executeDefaultPrep 参数解析完成 ===\n');
                fprintf('params结构体字段:\n');
                disp(params);
                fprintf('==========================================\n\n');

                % 创建预处理配置
                prepConfig = struct();
                prepConfig.name = prepName;
                prepConfig.type = prepType;
                prepConfig.scriptPath = scriptFile;
                prepConfig.params = params;
                prepConfig.isDefault = true;  % 标记为默认预处理

                % 显示处理中状态
                oldStatus = app.StatusLabel.Text;
                app.StatusLabel.Text = sprintf('正在执行 %s ...', prepName);
                app.StatusLabel.FontColor = [1 0.6 0];
                drawnow;

                % 获取当前帧数据
                currentData = app.MatData{app.CurrentIndex};

                % 默认使用当前数据作为输入
                inputMatrix = [];
                complexMatrixFound = false;
                previousPrepData = [];

                % 如果当前步骤依赖上一步的默认预处理，优先从缓存中获取
                if defaultPrepIndex == 2
                    % 非相参识别依赖“非相参积累”结果（列3）
                    if ~isempty(app.PreprocessingResults) && ...
                       app.CurrentIndex <= size(app.PreprocessingResults, 1) && ...
                       size(app.PreprocessingResults, 2) >= 3 && ...
                       ~isempty(app.PreprocessingResults{app.CurrentIndex, 3})
                        previousPrepData = app.PreprocessingResults{app.CurrentIndex, 3};
                        if isfield(previousPrepData, 'complex_matrix')
                            inputMatrix = previousPrepData.complex_matrix;
                            complexMatrixFound = true;
                        end
                    end
                elseif defaultPrepIndex == 4
                    % 多维识别依赖“CFAR检测”结果（列2）
                    if ~isempty(app.PreprocessingResults) && ...
                       app.CurrentIndex <= size(app.PreprocessingResults, 1) && ...
                       size(app.PreprocessingResults, 2) >= 2 && ...
                       ~isempty(app.PreprocessingResults{app.CurrentIndex, 2})
                        previousPrepData = app.PreprocessingResults{app.CurrentIndex, 2};
                        if isfield(previousPrepData, 'complex_matrix')
                            inputMatrix = previousPrepData.complex_matrix;
                            complexMatrixFound = true;
                        end
                    end
                end

                % 如果未找到上一步输出，则回退到原始数据
                if ~complexMatrixFound
                    if isfield(currentData, 'complex_matrix')
                        inputMatrix = currentData.complex_matrix;
                        complexMatrixFound = true;
                    else
                        % 遍历所有结构体字段查找嵌套的complex_matrix
                        fields = fieldnames(currentData);
                        for i = 1:length(fields)
                            fieldName = fields{i};
                            fieldValue = currentData.(fieldName);
                            if isstruct(fieldValue) && isfield(fieldValue, 'complex_matrix')
                                inputMatrix = fieldValue.complex_matrix;
                                complexMatrixFound = true;
                                break;
                            end
                        end
                    end
                end

                if ~complexMatrixFound
                    uialert(app.UIFigure, '当前数据不包含complex_matrix字段！', '错误', 'Icon', 'error');
                    return;
                end

                % 保存原始矩阵（用于后续可能的预处理）
                if ~isempty(previousPrepData) && isfield(previousPrepData, 'raw_matrix')
                    rawMatrix = previousPrepData.raw_matrix;
                else
                    rawMatrix = inputMatrix;
                end

                % 创建输出目录
                [dataPath, ~, ~] = fileparts(app.MatFiles{app.CurrentIndex});
                outputDir = fullfile(dataPath, prepConfig.name);
                if ~exist(outputDir, 'dir')
                    mkdir(outputDir);
                end
                [~, originalName, ~] = fileparts(app.MatFiles{app.CurrentIndex});

                % 调用默认脚本
                [scriptDir, scriptName, ~] = fileparts(scriptFile);

                % 临时添加脚本路径
                oldPath = addpath(scriptDir);

                try
                    % 添加输出目录和文件名到参数中（供脚本使用）
                    actualParams = params;
                    actualParams.output_dir = outputDir;
                    actualParams.file_name = originalName;
                    actualParams.raw_matrix = rawMatrix;  % 始终传递原始输入，便于下游读取

                    % 如果存在上一步结果，将其中的关键字段传递到参数中
                    if ~isempty(previousPrepData)
                        if isfield(previousPrepData, 'frame_info')
                            actualParams.frame_info = previousPrepData.frame_info;
                        elseif isfield(currentData, 'frame_info')
                            % 如果上一步没有frame_info，则回退当前帧信息
                            actualParams.frame_info = currentData.frame_info;
                        end
                        if isfield(previousPrepData, 'preprocessing_info')
                            actualParams.preprocessing_info = previousPrepData.preprocessing_info;
                        end
                        if isfield(previousPrepData, 'additional_outputs')
                            addFields = fieldnames(previousPrepData.additional_outputs);
                            for i = 1:length(addFields)
                                fieldName = addFields{i};
                                if ~isfield(actualParams, fieldName)
                                    actualParams.(fieldName) = previousPrepData.additional_outputs.(fieldName);
                                end
                            end
                            % 同时提供一个集合字段，方便脚本整体读取
                            actualParams.additional_outputs = previousPrepData.additional_outputs;
                        end
                    else
                        % 没有上一步结果时也传入当前帧信息（若存在）
                        if isfield(currentData, 'frame_info')
                            actualParams.frame_info = currentData.frame_info;
                        end
                    end

                    % 调用脚本函数
                    scriptFunc = str2func(scriptName);
                    processedMatrix = scriptFunc(inputMatrix, actualParams);

                    % 验证输出
                    if ~isnumeric(processedMatrix)
                        % 如果输出不是数值类型，检查是否是包含complex_matrix的结构体
                        if isstruct(processedMatrix) && isfield(processedMatrix, 'complex_matrix') && isnumeric(processedMatrix.complex_matrix)
                            % 初始化additionalOutputs
                            additionalOutputs = struct();
                            
                            % 收集所有额外输出字段（除了complex_matrix）
                            allFields = fieldnames(processedMatrix);
                            for i = 1:length(allFields)
                                fieldName = allFields{i};
                                if ~strcmp(fieldName, 'complex_matrix')
                                    additionalOutputs.(fieldName) = processedMatrix.(fieldName);
                                end
                            end
                            
                            % 从结构体中提取complex_matrix
                            processedMatrix = processedMatrix.complex_matrix;
                        else
                            % 如果不是数值且不包含有效的complex_matrix字段，报错
                            error('脚本输出必须是数值矩阵或向量！');
                        end
                    else
                        % 如果输出是数值类型，确保additionalOutputs已初始化
                        additionalOutputs = struct();
                    end

                catch ME
                    path(oldPath);  % 恢复路径
                    app.StatusLabel.Text = oldStatus;
                    app.StatusLabel.FontColor = [0 0.5 0];
                    uialert(app.UIFigure, sprintf('执行预处理脚本失败：\n%s', ME.message), '错误', 'Icon', 'error');
                    return;
                end

                % 恢复路径
                path(oldPath);

                % 创建处理后的数据
                processedData = currentData;
                processedData.complex_matrix = processedMatrix;
                processedData.raw_matrix = rawMatrix;
                processedData.preprocessing_info = prepConfig;
                processedData.preprocessing_time = datetime('now');

                % 保存额外输出（如阈值矩阵、训练均值等）
                if ~isempty(fieldnames(additionalOutputs))
                    processedData.additional_outputs = additionalOutputs;
                end

                % 准备保存数据：包含绘图变量、帧信息和额外输出
                saveData = struct();
                saveData.complex_matrix = processedMatrix;
                saveData.raw_matrix = rawMatrix;  % 保存预处理前的原始矩阵
                if isfield(currentData, 'frame_info')
                    saveData.frame_info = currentData.frame_info;
                end
                % 添加额外输出
                if ~isempty(fieldnames(additionalOutputs))
                    saveData.additional_outputs = additionalOutputs;
                end

                % 保存到本地文件
                outputFile = fullfile(outputDir, sprintf('%s_processed.mat', originalName));
                save(outputFile, '-struct', 'saveData');

                % 初始化预处理结果缓存
                if isempty(app.PreprocessingResults)
                    app.PreprocessingResults = cell(length(app.MatData), 7);
                end

                % 保存到结果缓存（固定位置映射）
                % 映射：1=非相参积累→列3, 2=非相参识别→列4, 3=CFAR检测→列2, 4=多维识别→列5
                cacheIndexMap = [3, 4, 2, 5];
                if defaultPrepIndex >= 1 && defaultPrepIndex <= 4
                    cacheIndex = cacheIndexMap(defaultPrepIndex);
                    app.PreprocessingResults{app.CurrentIndex, cacheIndex} = processedData;
                end

                % 恢复状态
                app.StatusLabel.Text = oldStatus;
                app.StatusLabel.FontColor = [0 0.5 0];

                % 更新多视图显示
                updateMultiView(app);

                % 更新预处理控件状态（包括清除按钮）
                updatePreprocessingControls(app);

                % 根据执行的预处理类型，启用对应的下一步按钮
                if defaultPrepIndex == 1
                    % 执行了"非相参积累"，启用"非相参识别"按钮
                    app.ShowCoherentBtn.Enable = 'on';
                elseif defaultPrepIndex == 3
                    % 执行了"CFAR检测"，启用"多维识别"按钮
                    app.ShowDetectionBtn.Enable = 'on';
                end

            catch ME
                uialert(app.UIFigure, sprintf('加载默认预处理失败：\n%s', ME.message), '错误');
            end
        end

        function numViews = checkCurrentViewCount(app)
            % 统计当前显示的视图数量
            numViews = 0;

            % 检查是否显示原图
            if app.ShowOriginalCheck.Value
                numViews = numViews + 1;
            end

            % 检查所有预处理结果
            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                for col = 2:min(7, size(app.PreprocessingResults, 2))
                    if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                        numViews = numViews + 1;
                    end
                end
            end
        end

        function success = promptToCloseView(app)
            % 弹窗让用户选择关闭哪个视图
            success = false;

            % 收集当前所有显示的视图信息
            viewOptions = {};
            viewColumns = [];

            % 检查原图
            if app.ShowOriginalCheck.Value
                viewOptions{end+1} = '原图';
                viewColumns(end+1) = 0;
            end

            % 检查所有预处理结果
            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                for col = 2:min(7, size(app.PreprocessingResults, 2))
                    if ~isempty(app.PreprocessingResults{app.CurrentIndex, col})
                        result = app.PreprocessingResults{app.CurrentIndex, col};

                        % 获取显示名称
                        if isstruct(result) && isfield(result, 'name')
                            title = result.name;
                        elseif isstruct(result) && isfield(result, 'preprocessing_info') && isfield(result.preprocessing_info, 'name')
                            title = result.preprocessing_info.name;
                        else
                            % 使用默认标题
                            if col == 2
                                title = 'CFAR';
                            elseif col == 3
                                title = '非相参积累';
                            elseif col == 4
                                title = '自定义预处理';
                            elseif col == 5
                                title = '相参积累';
                            elseif col == 6
                                title = '检测';
                            elseif col == 7
                                title = '识别';
                            else
                                title = sprintf('预处理%d', col-1);
                            end
                        end

                        viewOptions{end+1} = title;
                        viewColumns(end+1) = col;
                    end
                end
            end

            % 弹出选择对话框
            if isempty(viewOptions)
                success = true;
                return;
            end

            % 创建自定义对话框（替代listdlg，支持居中和置顶）
            dlg = uifigure('Name', '关闭视图', 'Position', [100 100 350 250], 'Visible', 'off');
            dlg.WindowStyle = 'modal';

            % 存储选择结果的变量
            selectedIndex = [];
            userClickedOK = false;

            % 设置关闭请求回调函数，确保关闭后主UI置顶
            dlg.CloseRequestFcn = @(~,~) closeDlgAndFocusMain();

            % 居中显示弹窗
            movegui(dlg, 'center');

            % 创建布局
            mainLayout = uigridlayout(dlg, [3, 1]);
            mainLayout.RowHeight = {60, '1x', 50};
            mainLayout.Padding = [15 15 15 15];

            % 提示文本
            promptLabel = uilabel(mainLayout);
            promptLabel.Layout.Row = 1;
            promptLabel.Text = sprintf('当前已有4个视图，无法添加更多。\n请选择要关闭的视图：');
            promptLabel.WordWrap = 'on';
            promptLabel.FontSize = 12;
            promptLabel.VerticalAlignment = 'top';

            % 列表框
            listBox = uilistbox(mainLayout);
            listBox.Layout.Row = 2;
            listBox.Items = viewOptions;
            listBox.FontSize = 11;
            if ~isempty(viewOptions)
                listBox.Value = viewOptions{1};
            end

            % 按钮布局
            btnLayout = uigridlayout(mainLayout, [1, 3]);
            btnLayout.Layout.Row = 3;
            btnLayout.ColumnWidth = {'1x', 80, 80};
            btnLayout.Padding = [0 0 0 0];

            % 占位
            uilabel(btnLayout);

            % 确定按钮
            okBtn = uibutton(btnLayout, 'push');
            okBtn.Text = '确定';
            okBtn.ButtonPushedFcn = @(~,~) confirmSelection();

            % 取消按钮
            cancelBtn = uibutton(btnLayout, 'push');
            cancelBtn.Text = '取消';
            cancelBtn.ButtonPushedFcn = @(~,~) closeDlgAndFocusMain();

            % 显示对话框
            dlg.Visible = 'on';

            % 等待对话框关闭
            uiwait(dlg);

            % 处理结果
            if userClickedOK && ~isempty(selectedIndex)
                % 关闭选中的视图
                columnToClose = viewColumns(selectedIndex);
                if columnToClose == 0
                    % 关闭原图
                    app.ShowOriginalCheck.Value = false;
                else
                    % 关闭预处理结果
                    app.PreprocessingResults{app.CurrentIndex, columnToClose} = [];
                end

                % 更新显示
                updateMultiView(app);
                success = true;
            end

            % 确保主UI置顶
            figure(app.UIFigure);

            % 嵌套函数
            function confirmSelection()
                % 获取选择的索引
                selectedValue = listBox.Value;
                selectedIndex = find(strcmp(viewOptions, selectedValue), 1);
                userClickedOK = true;
                closeDlgAndFocusMain();
            end

            function closeDlgAndFocusMain()
                if isvalid(dlg)
                    delete(dlg);
                end
                figure(app.UIFigure);  % 置顶主UI
            end
        end

        function closeSubView(app, sourceColumn)
            % 关闭指定的子视图
            % sourceColumn: 数据来源列（0=原图不能关闭, 2=CFAR, 3=非相参积累, 4=自定义预处理）

            if sourceColumn == 0
                % 原图不能关闭
                return;
            end

            % 清除该帧的预处理结果缓存
            if ~isempty(app.PreprocessingResults) && app.CurrentIndex <= size(app.PreprocessingResults, 1)
                if sourceColumn >= 2 && sourceColumn <= size(app.PreprocessingResults, 2)
                    app.PreprocessingResults{app.CurrentIndex, sourceColumn} = [];
                end
            end

            % 重新计算布局（updateMultiView会自动处理所有显示/隐藏逻辑）
            updateMultiView(app);
        end

        function handleAxesClick(app, src, event, viewIndex)
            % 处理坐标轴点击事件
            % 只有右键点击才关闭视图
            
            if strcmp(event.Button, 'alt')  % 右键
                closeSubView(app, viewIndex);
            end
        end

        function updateCloseButtonPositions(app)
            % 动态更新关闭按钮的位置
            % 在新的动态映射方案中，使用标题点击关闭功能，浮动关闭按钮不再使用

            % 隐藏所有浮动关闭按钮
            if isvalid(app.CloseBtn2)
                app.CloseBtn2.Visible = 'off';
            end
            if isvalid(app.CloseBtn3)
                app.CloseBtn3.Visible = 'off';
            end
            if isvalid(app.CloseBtn4)
                app.CloseBtn4.Visible = 'off';
            end
        end

    end

    methods (Static)
        function value = parseParamValue(valueStr, paramType)
            % 解析参数值字符串（用于从脚本默认值字符串解析）
            % valueStr: 参数值字符串
            % paramType: 参数类型 (double, int, string, bool, struct)

            % 如果已经是数值类型，直接返回
            if isnumeric(valueStr)
                switch lower(paramType)
                    case 'double'
                        value = double(valueStr);
                    case 'int'
                        value = round(double(valueStr));
                    otherwise
                        value = valueStr;
                end
                return;
            end

            % 处理字符串输入
            switch lower(paramType)
                case 'double'
                    value = str2double(strtrim(valueStr));
                    if isnan(value)
                        value = 0;
                    end

                case 'int'
                    value = round(str2double(strtrim(valueStr)));
                    if isnan(value)
                        value = 0;
                    end

                case 'string'
                    % 去除可能的引号
                    value = strtrim(valueStr);
                    if (startsWith(value, '''') && endsWith(value, '''')) || ...
                       (startsWith(value, '"') && endsWith(value, '"'))
                        value = value(2:end-1);
                    end

                case 'bool'
                    valueStr = strtrim(valueStr);
                    if strcmpi(valueStr, 'true') || strcmp(valueStr, '1')
                        value = true;
                    elseif strcmpi(valueStr, 'false') || strcmp(valueStr, '0')
                        value = false;
                    else
                        value = logical(str2double(valueStr));
                    end

                case 'struct'
                    try
                        value = jsondecode(valueStr);
                    catch
                        try
                            value = eval(valueStr);
                        catch
                            value = struct();
                        end
                    end

                otherwise
                    value = valueStr;
            end
        end

        function value = getTypeDefaultValue(paramType)
            % 获取参数类型的默认值
            switch lower(paramType)
                case 'double'
                    value = 0;
                case 'int'
                    value = 0;
                case 'string'
                    value = '';
                case 'bool'
                    value = false;
                case 'struct'
                    value = struct();
                otherwise
                    value = '';
            end
        end
    end
end