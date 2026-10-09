function fig = plotresults_AM4_16M_LTE_TC(resultsInput)
% plot_AM4_16M_LTE Az LTE kódok BER görbéinek közös ábrázolása.

if nargin < 1 || isempty(resultsInput)
    resultsInput = 'AM4_16M_LTE_results.mat';
end

if ischar(resultsInput) || (isstring(resultsInput) && isscalar(resultsInput))
    loaded = load(char(resultsInput), 'results');
    results = loaded.results;
elseif isstruct(resultsInput)
    results = resultsInput;
else
    error('Ervenytelen bemeneti tipus.');
end

fig = figure('Color', 'w', 'Name', 'AM4_16M LTE Turbo Code BER');
ax = axes(fig);
hold(ax, 'on');

colors = lines(numel(results.codes));
lineStyles = {'-o', '-s', '-^'};

for codeIdx = 1:numel(results.codes)
    ber = results.codes(codeIdx).ber;
    labelStr = results.codes(codeIdx).label;

    semilogy(ax, results.oneBitPart, ber(:).', lineStyles{codeIdx}, ...
        'Color', colors(codeIdx,:), ...
        'LineWidth', 1.5, ...
        'MarkerSize', 6, ...
        'DisplayName', labelStr);
end

grid(ax, 'on');
box(ax, 'on');
xlim(ax, [-1 1]);
xticks(ax, -1:0.1:1);
xlabel(ax, 'oneBitPart');
ylabel(ax, 'Bithibaarány (BER)');
title(ax, sprintf('LTE Turbo Code 4-QAM/16-QAM: noise = %g dBm, async SNR = %g dB', ...
    results.noiseDbm, results.asyncSnrDb));
legend(ax, 'Location', 'best');
hold(ax, 'off');
end
