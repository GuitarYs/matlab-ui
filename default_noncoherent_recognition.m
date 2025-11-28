function output_data = default_noncoherent_recognition(input_data, params)
% 非相参识别预处理
%
% 此脚本对非相参积累的输出进行识别处理
% 输入：非相参积累后的数据
% 输出：识别结果
%
% PARAM: num_classes, int, 3
% PARAM: threshold_factor, double, 0.5

    % 验证输入
    if ~isnumeric(input_data)
        error('输入数据必须是数值类型');
    end

    % 获取参数
    num_classes = getParam(params, 'num_classes', 3);
    threshold_factor = getParam(params, 'threshold_factor', 0.5);

    % 读取上一步的上下文（若有）
    hasRawMatrix = isfield(params, 'raw_matrix') && isnumeric(params.raw_matrix);
    hasAdditional = isfield(params, 'additional_outputs') && isstruct(params.additional_outputs);
    hasFrameInfo = isfield(params, 'frame_info');

    fprintf('\n========================================\n');
    fprintf('非相参识别预处理\n');
    fprintf('========================================\n');
    fprintf('输入数据维度: %s\n', mat2str(size(input_data)));
    fprintf('分类数量: %d\n', num_classes);
    fprintf('阈值因子: %.2f\n', threshold_factor);
    if hasRawMatrix
        fprintf('可访问原始输入 raw_matrix，尺寸: %s\n', mat2str(size(params.raw_matrix)));
    end
    if hasAdditional
        extraFields = fieldnames(params.additional_outputs);
        fprintf('附加输出字段: %s\n', strjoin(extraFields, ', '));
    end
    if hasFrameInfo
        fprintf('收到 frame_info，可用于参数推断。\n');
    end
    fprintf('========================================\n\n');

    % 获取输入数据的幅度
    magnitude = abs(input_data);

    % 基于幅度的简单分类
    % 计算阈值
    max_val = max(magnitude(:));
    min_val = min(magnitude(:));
    range_val = max_val - min_val;

    % 为每个类别设置阈值
    thresholds = zeros(1, num_classes - 1);
    for i = 1:(num_classes - 1)
        thresholds(i) = min_val + (range_val * i / num_classes) * threshold_factor;
    end

    % 分类
    labels = zeros(size(magnitude));
    for i = 1:num_classes
        if i == 1
            % 第一类：小于第一个阈值
            labels(magnitude < thresholds(1)) = 1;
        elseif i == num_classes
            % 最后一类：大于最后一个阈值
            labels(magnitude >= thresholds(end)) = num_classes;
        else
            % 中间类别
            labels(magnitude >= thresholds(i-1) & magnitude < thresholds(i)) = i;
        end
    end

    % 统计每个类别的数量
    class_counts = zeros(1, num_classes);
    for i = 1:num_classes
        class_counts(i) = sum(labels(:) == i);
    end

    fprintf('识别完成！\n');
    fprintf('分类统计:\n');
    for i = 1:num_classes
        fprintf('  类别 %d: %d 个点 (%.2f%%)\n', i, class_counts(i), 100*class_counts(i)/numel(labels));
    end
    fprintf('========================================\n\n');

    % 构建输出
    output_data = struct();
    output_data.complex_matrix = input_data;  % 保持原始数据
    output_data.labels = labels;  % 识别标签
    output_data.class_counts = class_counts;  % 类别统计
    output_data.thresholds = thresholds;  % 分类阈值
    output_data.num_classes = num_classes;

end

% 辅助函数：获取参数值
function value = getParam(params, name, default_value)
    if isfield(params, name)
        value = params.(name);
    else
        value = default_value;
    end
end
