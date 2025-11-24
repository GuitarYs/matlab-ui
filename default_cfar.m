function output_data = default_cfar(input_data, params)
% DEFAULT_CFAR 默认CFAR检测预处理
%
%
% 使用CFAR算法对雷达数据进行检测处理，并返回额外的处理结果
%
% 参数定义：
% PARAM: threshold_factor, double, 3.0
% PARAM: guard_cells, int, 4
% PARAM: training_cells, int, 16
% PARAM: method, string, CA
% PARAM: apply_log, bool, true


    % 获取参数
    threshold_factor = getParam(params, 'threshold_factor', 3.0);
    guard_cells = getParam(params, 'guard_cells', 4);
    training_cells = getParam(params, 'training_cells', 16);
    method = getParam(params, 'method', 'CA');
    apply_log = getParam(params, 'apply_log', true);
    

    % 确保输入为复数矩阵
    if ~isnumeric(input_data)
        error('输入数据必须是数值类型');
    end

    % 转换为double类型（解决复整数不支持的问题）
    input_data = double(input_data);

    % 计算幅度
    magnitude = abs(input_data);

    % 如果需要，应用对数变换
    if apply_log
        magnitude = 20 * log10(magnitude + eps);
    end

    % 获取数据大小
    [rows, cols] = size(magnitude);

    % 初始化输出
    detected = zeros(size(magnitude));
    % 新增：保存阈值矩阵
    thresholds = zeros(size(magnitude));
    % 新增：保存训练窗口均值
    training_means = zeros(size(magnitude));

    % CFAR处理
    window_size = 2 * (guard_cells + training_cells) + 1;

    % 对每一列进行CFAR检测
    for col = 1:cols
        for row = 1:rows
            % 计算窗口范围
            start_idx = max(1, row - training_cells - guard_cells);
            end_idx = min(rows, row + training_cells + guard_cells);

            % 提取训练窗口
            training_window = magnitude(start_idx:end_idx, col);

            % 排除保护单元和测试单元
            guard_start = max(1, row - guard_cells);
            guard_end = min(rows, row + guard_cells);
            guard_indices = (guard_start:guard_end) - start_idx + 1;
            guard_indices = guard_indices(guard_indices > 0 & guard_indices <= length(training_window));
            training_window(guard_indices) = [];

            % 计算训练窗口均值
            mean_value = mean(training_window);
            training_means(row, col) = mean_value;

            % 计算阈值
            if strcmp(method, 'CA')
                % Cell Averaging CFAR
                threshold = mean_value * threshold_factor;
            elseif strcmp(method, 'GO')
                % Greatest Of CFAR
                half = floor(length(training_window) / 2);
                threshold = max(mean(training_window(1:half)), mean(training_window(half+1:end))) * threshold_factor;
            elseif strcmp(method, 'SO')
                % Smallest Of CFAR
                half = floor(length(training_window) / 2);
                threshold = min(mean(training_window(1:half)), mean(training_window(half+1:end))) * threshold_factor;
            else
                threshold = mean_value * threshold_factor;
            end

            % 保存阈值
            thresholds(row, col) = threshold;

            % 检测
            if magnitude(row, col) > threshold
                detected(row, col) = 1;
            end
        end
    end

    % 新增：创建输出结构体，包含处理后的复数矩阵和额外的输出数据
    output_data = struct();
    output_data.complex_matrix = input_data .* detected;  % 用于显示的复数矩阵
    output_data.detection_mask = detected;  % 检测掩码
    output_data.thresholds = thresholds;  % 阈值矩阵
    output_data.training_means = training_means;  % 训练窗口均值
    output_data.processing_params = params;  % 使用的处理参数
    output_data.method = method;  % CFAR方法
    output_data.apply_log = apply_log;  % 是否应用了对数变换
    output_data.timestamp = datetime('now');  % 处理时间戳

    % 创建figure并缓存（不保存到文件）
    try
        fig = figure('Visible', 'off');

        % 绘制CFAR检测结果
        ax = axes('Parent', fig);
        imagesc(ax, abs(output_data.complex_matrix));
        axis(ax, 'on');
        title(ax, sprintf('CFAR检测结果 - 方法:%s, 阈值因子:%.1f', method, threshold_factor));
        xlabel(ax, '距离单元啥时');
        ylabel(ax, '多普勒单元收拾收拾');

        % 将figure缓存到变量中
        output_data.cached_figure = fig;

    catch ME
        warning('创建figure失败：%s', ME.message);
    end

end

function value = getParam(params, name, default_value)
    % 辅助函数：从params结构体中获取参数值
    if isfield(params, name)
        value = params.(name);
    else
        value = default_value;
    end
end