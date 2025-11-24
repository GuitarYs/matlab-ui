function output_data = default_multidim_recognition(input_data, params)
% 多维识别预处理
%
% 此脚本对CFAR检测的输出进行多维识别处理
% 输入：CFAR检测后的数据
% 输出：多维识别结果
%
% PARAM: feature_dims, int, 2
% PARAM: cluster_threshold, double, 0.3

    % 验证输入
    if ~isnumeric(input_data)
        error('输入数据必须是数值类型');
    end

    % 获取参数
    feature_dims = getParam(params, 'feature_dims', 2);
    cluster_threshold = getParam(params, 'cluster_threshold', 0.3);

    fprintf('\n========================================\n');
    fprintf('多维识别预处理\n');
    fprintf('========================================\n');
    fprintf('输入数据维度: %s\n', mat2str(size(input_data)));
    fprintf('特征维度: %d\n', feature_dims);
    fprintf('聚类阈值: %.2f\n', cluster_threshold);
    fprintf('========================================\n\n');

    % 如果有CFAR检测的掩码，优先使用
    has_detection_mask = false;
    if isfield(params, 'detection_mask')
        detection_mask = params.detection_mask;
        has_detection_mask = true;
        fprintf('检测到 detection_mask，将用于识别\n');
    end

    % 获取输入数据的幅度和相位
    magnitude = abs(input_data);
    phase = angle(input_data);

    % 提取特征
    features = {};
    feature_names = {};

    % 特征1：幅度
    features{end+1} = magnitude;
    feature_names{end+1} = '幅度';

    % 特征2：相位
    if feature_dims >= 2
        features{end+1} = phase;
        feature_names{end+1} = '相位';
    end

    % 特征3：梯度（如果需要更多维度）
    if feature_dims >= 3 && min(size(magnitude)) > 1
        [Gx, Gy] = gradient(magnitude);
        gradient_mag = sqrt(Gx.^2 + Gy.^2);
        features{end+1} = gradient_mag;
        feature_names{end+1} = '梯度幅度';
    end

    % 归一化特征
    normalized_features = cell(size(features));
    for i = 1:length(features)
        feat = features{i};
        feat_min = min(feat(:));
        feat_max = max(feat(:));
        if feat_max > feat_min
            normalized_features{i} = (feat - feat_min) / (feat_max - feat_min);
        else
            normalized_features{i} = feat;
        end
    end

    % 简单的聚类识别（基于特征距离）
    % 计算每个点的综合特征值
    combined_feature = zeros(size(magnitude));
    for i = 1:length(normalized_features)
        combined_feature = combined_feature + normalized_features{i} / length(normalized_features);
    end

    % 如果有检测掩码，只在检测到的区域进行识别
    if has_detection_mask
        combined_feature = combined_feature .* detection_mask;
    end

    % 基于阈值的多类识别
    max_val = max(combined_feature(:));
    min_val = min(combined_feature(:));

    % 定义3个类别
    num_classes = 3;
    labels = zeros(size(combined_feature));

    % 低特征值区域
    labels(combined_feature < min_val + (max_val - min_val) * cluster_threshold) = 1;
    % 中特征值区域
    labels(combined_feature >= min_val + (max_val - min_val) * cluster_threshold & ...
           combined_feature < min_val + (max_val - min_val) * (1 - cluster_threshold)) = 2;
    % 高特征值区域
    labels(combined_feature >= min_val + (max_val - min_val) * (1 - cluster_threshold)) = 3;

    % 统计
    class_counts = zeros(1, num_classes);
    for i = 1:num_classes
        class_counts(i) = sum(labels(:) == i);
    end

    fprintf('识别完成！\n');
    fprintf('使用的特征: ');
    for i = 1:length(feature_names)
        fprintf('%s', feature_names{i});
        if i < length(feature_names)
            fprintf(', ');
        end
    end
    fprintf('\n\n分类统计:\n');
    class_names = {'低响应', '中响应', '高响应'};
    for i = 1:num_classes
        fprintf('  %s (类别%d): %d 个点 (%.2f%%)\n', class_names{i}, i, class_counts(i), 100*class_counts(i)/numel(labels));
    end
    fprintf('========================================\n\n');

    % 构建输出
    output_data = struct();
    output_data.complex_matrix = input_data;  % 保持原始数据
    output_data.labels = labels;  % 识别标签
    output_data.class_counts = class_counts;  % 类别统计
    output_data.feature_dims = feature_dims;  % 特征维度
    output_data.combined_feature = combined_feature;  % 综合特征
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
