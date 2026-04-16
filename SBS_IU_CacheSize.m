clc;
close all;
clear;

tic;

%% 参数设置
h = 3;
user_per_community = 50;
total_users = h * user_per_community;
F = 200;
Per_m = 0.3;
iu_count_per_community = round(user_per_community * Per_m);
nf = 100;
chi = [1.5 , 2 , 5 , 10 , 12];
chi_star = chi(end);
Delta_t = 1;
v_chi_star = chi_star * Delta_t / 8;

region_size = 1500;
sbs_coverage = 150;
iu_coverage = 50;
community_radius = 150;
max_movement_dist = 2;

T_small = 100;
gamma_m = 0.9;

alpha = 0.2;
beta = 0.7;
gamma = 0.1;

B = 2;
P_sbs = 1;
P_iu = 0.3;
N0 = 1e-7;
K = 1;
epsilon = 3;
slowfading_dB = 3;

alpha_qoe = 0.45;
beta_qoe = 0.05;
gamma_qoe = 0.3;
delta_qoe = 0.2;

D_eg = 30 * nf * v_chi_star;
D_iu = 10 * nf * v_chi_star;

p_sbs = 100;
p_iu = 10;
D_bf = 10;
t_cloud = 2;
t_propagation = 0.5;

target_community = 1;

eta = 0.01;
epsilon_conv = 0.1;
max_iterations = 100;
run_num = 1000;

filePath = 'ml-100k/u.data';
data = readmatrix(filePath, 'FileType', 'text');
item_file_path = 'ml-100k/u.item';
theta_sigmoid  = 10.0;
beta_fuse      = 0.6;

%% 加载固定位置数据
pos_data = load('matlab.mat', 'sbs_positions', 'per_user_positions', 'now_user_positions', 'user_community');
sbs_positions      = pos_data.sbs_positions;
per_user_positions  = pos_data.per_user_positions;
now_user_positions  = pos_data.now_user_positions;
user_community      = pos_data.user_community;

qoe_algorithm_number = zeros(10, 10);
for x = 1:10
    D_eg = 5*x * nf * v_chi_star;
    for y = 1:10
        D_iu = 2*y * nf * v_chi_star;
        qoe_results = zeros(run_num, 1);
        parfor run_now = 1:run_num
            try
                [final_alltime_qoe,~,~] = algorithm_MOIS( ...
            h, user_per_community, total_users, F, iu_count_per_community, ...
            nf, chi, Delta_t, v_chi_star, region_size, sbs_coverage, iu_coverage, ...
            community_radius, max_movement_dist, D_eg, D_iu, T_small, gamma_m, ...
            alpha, beta, gamma, B, P_sbs, P_iu, N0, K, epsilon, slowfading_dB, ...
            alpha_qoe, beta_qoe, gamma_qoe, delta_qoe, p_sbs, p_iu, D_bf, ...
            t_cloud, t_propagation, target_community, eta, epsilon_conv, ...
            max_iterations, data, item_file_path, theta_sigmoid, beta_fuse, ...
            sbs_positions, per_user_positions, now_user_positions, user_community);
                qoe_results(run_now) = final_alltime_qoe;
            catch ME
                warning('运行 %d 出错: %s', run_now, ME.message);
                qoe_results(run_now) = 0;
            end
        end
        qoe_algorithm_number(x,y) = mean(qoe_results);
        fprintf('SBS=%d Files, IU=%d Files, QoE=%.4f\n', x*5, y*2, qoe_algorithm_number(x,y));
    end
end

figure('Position', [100, 100, 900, 700]);
Z = qoe_algorithm_number;
hb = bar3(Z);
for k = 1:length(hb)
    zdata = get(hb(k),'ZData');
    set(hb(k),'CData',zdata,'FaceColor','interp');
end
yticklabels(2*(1:10));
xticklabels(5*(1:10));
ylabel('Cache size of SBS (Files)', 'FontSize', 18);
xlabel('Cache size of IU (Files)', 'FontSize', 18);
zlabel('QoE', 'FontSize', 18);
grid on; colormap(jet); colorbar; view(-135, 15);
saveas(gcf,'Figure/SBS_IU_CacheSize.fig');
toc;
