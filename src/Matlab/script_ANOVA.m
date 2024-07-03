%% Experimental Study for Multi-layer Parameter Configuration of WSN Links
% Songwei Fu; Yan Zhang; Yuming Jiang; Chengchen Hu; Chia-Yen Shih; Pedro J. Marron; 
% In Distributed Computing Systems (ICDCS), 2015 IEEE 35th International Conference on (June 2015), pp. 369-378, doi:10.1109/icdcs.2015.45.
%
% Songwei Fu, Yan Zhang, CRAWDAD dataset due/packet?delivery (v. 2015/04/01), downloaded from https://crawdad.org/due/packet?delivery/20150401, https://doi.org/10.15783/C7NP4Z, Apr 2015.
%
% coded by: Jose Camacho Paez (josecamacho@ugr.es)
% last modification: 28/April/2023
%
% Copyright (C) 2023  University of Granada, Granada
%
%% Introduction
%
% 8064 different configurations per distance, including values for:
% At the PHY layer transmission power level (Ptx). 
% At the MAC layer are the maximum number of transmissions (NmaxTries), the 
% retry delay time for a new retransmission (Dretry), and the maximum
% queue size (Qmax) of the queue on top of the MAC layer used
% to buffer packets when they are waiting for (re-)transmission.
% At the Application layer are the packet inter-arrival time (Tpit)
% and the packet payload size (lD).
% The values are (48384 combinations) :
%   1) Tpit: 10, 15, 20, 25, 30, 35, 40, 50
%   2) lD: 20, 35, 50, 65, 80, 95, 110
%   3) Qmax: 1, 30, 60
%   4) NmaxTries: 1, 3, 5
%   5) Dretry: 30, 60
%   6) Ptx: 3,7,11,15,19,23,27,31
%   7) distance: 10, 15, 20, 25, 30, 35
%
% Each row contains the configuration parameter followed by more than 9 
% runs with 300 measurements each.
%
% There are separated traces per distance and for delay and other measures
% (RSSI, LQI, noise floor, actual queue size, overflow, 
% actual retransmission number, deliver success\/fail and arrival time)
%
% The following analysis is limited to Delay
% 
% %% Load the data
% 
% clear
% close all
% clc
% 
% d = 10:5:35;
% delay = [];
% parameters = [];
% for i=1:length(d)
%     data = importdata(sprintf('delay_%dm.txt',d(i)));
%     parameters = [parameters;data(:,1:7)]; % Factors are in the first seven colums
%     delay = [delay;data(:,8+(1:9*300))]; % The remaining columns contain the delay
% end
% 
% labels = {'Tpit', 'lD', 'Qmax', 'NmaxTries', 'Dretry', 'Ptx', 'distance'}; 
% 
% save data delay parameters labels

%% Prepare Data and (very important) Visualize it
clear all;
close all;
clc;

load data

% Infeasible values: delay values below 0 set to 0
delay(find(delay<0))=0;

% Reduce auto-correlation: simulate "experimental units"
s = 4; % replicates
x = [];
y = [];
sd2 = size(delay,2);
int = round(sd2/s);
for i=1:s
    x = [x;mean(delay(:,(1+(i-1)*int):int*i),2)];
    y = [y;parameters];
end

% Plot examples of auto-correlation
obs = 1;
sd = size(delay,1);
figure, plot(delay(obs,:)), hold on, plot(int/2:int:s*int, x(obs:sd:s*sd),'r*'); ylabel('Delay'); xlabel('Time'); title('Selecting observations')

obs = 1000;
sd = size(delay,1);
figure, plot(delay(obs,:)), hold on, plot(int/2:int:s*int, x(obs:sd:s*sd),'r*'); ylabel('Delay'); xlabel('Time'); title('Selecting observations')


% Boxplot (in LOG scale)
% unlike in anova, in this visualization
for i = 1:7
    res2=[];
    uy = unique(y(:,i));
    for j = 1:length(uy);
        res2 = [res2 x(find(y(:,i)==uy(j)))];
    end
    figure, boxplot(res2), set(gca, 'YScale', 'log'), ylabel('Delay'), xlabel(labels{i})
end

% Plot delay (in LOG scale) in terms of distance (subfigure), replicates and power (red)
% we see an artifact for d=10m, bias caused by lack of random
% experimentation
dist = unique(y(:,7));
figure
for i=1:length(dist),
    subplot(length(dist),1,i)
    ind = find(y(:,7)==dist(i));
    rep = round(length(ind)/s);
    plot(log(x(ind))), hold on,
    plot(y(ind,6)/4,'r')
    ylabel(sprintf('%d m',dist(i)))
    for j=rep:rep:length(ind)
        plot([j,j],[0, 12],'k--');
    end
    axis([0 length(ind) 0 12])
end
xlabel('Measurements')
set(gcf, 'Position', get(0, 'Screensize'));

% Delete the artifact (optional, otherwise comment)
ind = find(y(:,7)==10);
x(ind) = [];
y(ind,:) = [];

save data x y -APPEND

%% Compute ANOVA in raw data and check results
% ANOVA (análisis de varianza) es separar la respuesta obtenida (en este caso el delay) en varios
% factores. Por ejemplo: altura en personas, separar en factores tales
% como: color de ojos, sexo, raza, y ver qué factores tienen más impacto en
% la respuesta. Dependiendo del factor unos tendrán más que otro.

% El factor más importante es la suma de cuadrados más grandes. El grado de
% libertad da una idea de la importancia que tendrá cada factor. La columna
% F es un RATIO (división entre la mean square entre la mean square de los
% errores) si es más grande que 1 es relevante, sino no. La columna Prob>F
% es el p-valor. Si el p-valor es <0.05 es relevante, sino no. En este
% caso, la distancia es lo más relevante seguido de la potencia de transmisión, de acuerdo con el experimento.
[P,T,STATS]=anovan(x,y,'varnames',labels);

sk = skewness(STATS.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS.resid,0) % should be close to or less than 3
figure,normplot(STATS.resid(1:100:end)) % should look like a line


%% Use transformation to meet assumptions: log

[P,T,STATS_L]=anovan(log(x),y,'varnames',labels);

sk = skewness(STATS_L.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_L.resid,0) % should be close to or less than 3
figure,normplot(STATS_L.resid(1:100:end)) % should look like a line


%% Use transformation to meet assumptions: boxcox

[P,T,STATS_B]=anovan(boxcox(x),y,'varnames',labels);

sk = skewness(STATS_B.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_B.resid,0) % should be close to or less than 3
figure,normplot(STATS_B.resid(1:100:end)) % should look like a line


%% Use transformation to meet assumptions: rank

[P,T,STATS_R]=anovan(rank_transform(x),y,'varnames',labels);

sk = skewness(STATS_R.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_R.resid,0) % should be close to or less than 3
figure,normplot(STATS_R.resid(1:100:end)) % should look like a line

%% Use permutation testing: equivalent p-values

[T,parglmo] = parglm(boxcox(x),y);
T{2:8,1} = labels'

sk = skewness(parglmo.residuals,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(parglmo.residuals,0) % should be close to or less than 3
figure,normplot(parglmo.residuals(1:100:end)) % should look like a line


%% compute posthoc (according to effect size, limit to statistical significant results)
% only categorical factors

figure,multcompare(STATS_B,'alpha',0.05,'display','on','dimension',1); % Tpit: Choose (probably) 25
figure,multcompare(STATS_B,'alpha',0.05,'display','on','dimension',7); % distance: Weird behavior at 20 meters
figure,multcompare(STATS_B,'alpha',0.05,'display','on','dimension',6); % Ptx: Choose 15 or less

%% Factors: Categorical or Continuos? 
% Higher relevance for lD while distance is not so relevant (we are
% filtering out the behaviour at 20m)

[P,T,STATS_B2]=anovan(boxcox(x),y,'continuous',1:7,'varnames',labels);

sk = skewness(STATS_B2.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_B2.resid,0) % should be close to or less than 3
figure,normplot(STATS_B2.resid(1:100:end)) % should look like a line


%% Add interactions

[P,T,STATS_B3]=anovan(boxcox(x),y,'varnames',labels, 'model', 'interaction');

sk = skewness(STATS_B3.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_B3.resid,0) % should be close to or less than 3
figure,normplot(STATS_B3.resid(1:100:end)) % should look like a line


%% compute posthoc (according to effect size, limit to statistical significant results)
% only interactions between categorical factors

figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',[6,7]); % Ptx * distance: weird behaviour (especially for 10m included)

