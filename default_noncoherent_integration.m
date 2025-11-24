function output_data = default_noncoherent_integration(input_data, params)
% DEFAULT_NONCOHERENT_INTEGRATION 默认非相参积累预处理
%
% 对雷达数据进行非相参积累处理，提高信噪比
%
% 参数定义：
% PARAM: num_pulses, int, 4
% PARAM: method, string, linear

    % 获取参数
    num_pulses = getParam(params, 'num_pulses', 4);
    method = getParam(params, 'method', 'linear');

    % 确保输入为复数矩阵
    if ~isnumeric(input_data)
        error('输入数据必须是数值类型');
    end

    % 获取数据大小
    [rows, cols] = size(input_data);

    % 计算积累后的大小
    num_groups = floor(cols / num_pulses);
    if num_groups == 0
        error('数据列数不足以进行非相参积累');
    end

    % 初始化输出矩阵
    integrated_data = zeros(rows, num_groups);

    % 保存原始幅度用于可视化
    original_magnitude = abs(input_data);

    % 执行非相参积累
    for group = 1:num_groups
        start_col = (group - 1) * num_pulses + 1;
        end_col = start_col + num_pulses - 1;

        % 提取当前组的数据
        group_data = input_data(:, start_col:end_col);

        % 根据方法进行积累
        if strcmp(method, 'linear')
            % 线性积累（幅度累加）
            integrated_data(:, group) = sum(abs(group_data), 2);
        elseif strcmp(method, 'square')
            % 平方积累
            integrated_data(:, group) = sum(abs(group_data).^2, 2);
        else
            % 默认使用线性积累
            integrated_data(:, group) = sum(abs(group_data), 2);
        end
    end

    % 归一化
    if strcmp(method, 'linear')
        integrated_data = integrated_data / num_pulses;
    elseif strcmp(method, 'square')
        integrated_data = sqrt(integrated_data / num_pulses);
    end

    % 创建输出结构体
    output_data = struct();
    output_data.complex_matrix = integrated_data;  % 用于显示的处理结果
    output_data.original_magnitude = original_magnitude;  % 原始幅度
    output_data.num_pulses = num_pulses;  % 积累脉冲数
    output_data.num_groups = num_groups;  % 积累组数
    output_data.processing_params = params;  % 使用的处理参数
    output_data.method = method;  % 积累方法
    output_data.timestamp = datetime('now');  % 处理时间戳

end

function value = getParam(params, name, default_value)
    % 辅助函数：从params结构体中获取参数值
    if isfield(params, name)
        value = params.(name);
    else
        value = default_value;
    end
end