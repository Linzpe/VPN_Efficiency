%% Prepare Data and (very important) Visualize it
clear all;
close all;
clc;


load Delay2.mat
load Jitter.mat
load Factores_str.mat

labels = {'Servidor','VPN','Dia','Hora'};
colors = {[1 1 1], [0.5 0.5 0.5], [0.7 0.7 1]}; % Blanco, Gris y Azul claro

niveles_Servidor = {'aipg', 'bmgs', 'gettec'};
niveles_VPN = {'NO VPN', 'EEUU-Denver', 'Australia-Sydney'};
niveles_Dia = {'Lunes', 'Martes','Miercoles','Jueves','Viernes'};
niveles_Hora = {'12:30 pm', '11:30 pm'}; 

% Boxplot (in LOG scale)
% unlike in anova, in this visualization
% factores = y
% delay = x
colors = {'r', 'g', 'b', 'c', 'm', 'y', 'k'};

for i = 1:4
    res2=[];

    if i == 1
        uy = ["aipg-tx.org","bmgs.com.au","gettec.es"];
    elseif i == 2
        uy = ["NO", "EEUU-Denver", "Australia-Sydney"];
    elseif i == 3
        uy = ["lunes", "martes", "miércoles", "jueves", "viernes"];
    elseif i == 4
        uy = ["11:30:00", "11:30:00"];
    end

    for j = 1:length(uy)
        % Obtenemos todas las filas que coinciden con el valor del factor
        % que sea. Por ejemplo, si estamos mirando el factor "servidor"
        % en primer lugar obtendremos todas las posiciones de la matriz
        % "Delay" en las que aparezcan los 20 replicates asociados al valor
        % "gettec" o "aipg".
        aux = find(factores_str(:,i)==uy(j));
        res2_concatenado = [];
        for k = 1:length(aux)
            % Lo que hacemos en ese bucle es concatenar el vector de 20
            % posiciones de la primera ocurrencia de "gettec" en la matriz
            % delay, con el vector para la segunda ocurrencia de "gettec" y
            % así sucesivamente.
            res2_concatenado = [res2_concatenado delay(aux(k),:)];
        end
        
        res2 = [res2 res2_concatenado'];
    end
    %figure, boxplot(res2), set(gca, 'YScale', 'log'), ylabel('Delay'), xlabel(labels{i})

    figure;
    h = boxplot(res2, 'Colors', 'k'); % Crear boxplot con contornos negros
    set(gca, 'YScale', 'log');
    ylabel('Delay');
    xlabel(labels{i});
    
    % Personalizar los colores de cada box
    boxes = findobj(gca, 'Tag', 'Box');
    for j = 1:length(boxes)
        patch(get(boxes(j), 'XData'), get(boxes(j), 'YData'), colors{j}, 'FaceAlpha', 0.5);
    end
    
    % Añadir la leyenda
    if i == 1
        niveles = flip(niveles_Servidor);
    elseif i == 2
        niveles = flip(niveles_VPN);
    elseif i == 3
        niveles = flip(niveles_Dia);
    elseif i == 4
        niveles = flip(niveles_Hora);
    end

    legend(niveles, 'Location', 'Best');
end

% ANOVA
delay_vector = delay(:);
factores_vector = repmat(factores_str,20,1);
factores_vector = {factores_vector(:,1) factores_vector(:,2) factores_vector(:,3) factores_vector(:,4)};

%% Use transformation to meet assumptions: rank

[P,T,STATS_R]=anovan(rank_transform(delay_vector),factores_vector,'varnames',labels);

sk = skewness(STATS_R.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_R.resid,0) % should be close to or less than 3
figure,normplot(STATS_R.resid) % should look like a line

%% Add interactions

[P,T,STATS_B3]=anovan(log(delay_vector),factores_vector,'varnames',labels, 'model', 'interaction');

sk = skewness(STATS_B3.resid,0) % should be close to 0 (entre -1 y 1)
k = kurtosis(STATS_B3.resid,0) % should be close to or less than 3
figure,normplot(STATS_B3.resid) % should look like a line


% compute posthoc (according to effect size, limit to statistical significant results)
% only interactions between categorical factors

figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',[1,2]); % Ptx * distance: weird behaviour (especially for 10m included)
figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',[1,3]);
figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',[2,4]);
figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',[1,3]);
figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',1);
figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',2);
figure,multcompare(STATS_B3,'alpha',0.05,'display','on','dimension',3);

