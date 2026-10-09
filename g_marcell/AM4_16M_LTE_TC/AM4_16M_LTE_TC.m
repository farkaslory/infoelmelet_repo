function [TurboErr, n, OneBitPartLength, place] = AM4_16M_LTE_TC( ...
        BlockLength, n, maxFrames, K, noiseDbm, calcPlace, oneBitPart, asyncSnrDb)
% AM4_16M_LTE Valtozo 4-QAM/16-QAM felosztasu LTE Turbo Kod szimulacio.
%
% [TurboErr, n, OneBitPartLength, place] = AM4_16M_LTE( ...
%     BlockLength, n, maxFrames, K, noiseDbm, calcPlace, oneBitPart, asyncSnrDb)
%
% Bemenetek:
%   BlockLength - A Turbo kódolt blokk hossza (N).
%   n           - Információs bitek száma kódszavanként (K_info).
%   maxFrames   - Szimulált keretek száma (alapértelmezett: 1000).
%   K           - Egymás után dekódot kódszavak száma (alapért.: 20).
%   noiseDbm    - Rögzített komplex AWGN zajteljesítmény [dBm] (-80 dBm).
%   calcPlace   - Hibapozíció-számlálás kapcsolója (0 vagy 1).
%   oneBitPart  - Normalizált 4-QAM-részhossz, -1 és +1 között.
%   asyncSnrDb  - Az aszinkron kapcsolat átlagos SNR-je [dB] (alapért.: 18 dB).
%
% Kimenetek:
%   TurboErr         - A rögzített zajszinthez tartozó skalár BER.
%   n                - Információs bitek száma kódszavanként.
%   OneBitPartLength - A 4-QAM-mal továbbított első rész bitszáma.
%   place            - A legnagyobb hibájú kódszó pozíciójának számlálói.

if nargin < 8 || isempty(asyncSnrDb), asyncSnrDb = 18;     end
if nargin < 7 || isempty(oneBitPart), oneBitPart = 0;      end
if nargin < 6 || isempty(calcPlace),  calcPlace = 0;      end
if nargin < 5 || isempty(noiseDbm),   noiseDbm = -80;     end
if nargin < 4 || isempty(K),          K = 20;             end
if nargin < 3 || isempty(maxFrames),  maxFrames = 1000;   end

validateattributes(BlockLength, {'numeric'}, {'scalar','integer','positive'}, mfilename, 'BlockLength', 1);
validateattributes(n, {'numeric'}, {'scalar','integer','positive'}, mfilename, 'n', 2);
validateattributes(maxFrames, {'numeric'}, {'scalar','integer','positive'}, mfilename, 'maxFrames', 3);
validateattributes(K, {'numeric'}, {'scalar','integer','positive'}, mfilename, 'K', 4);

maxIter = 6; % Turbo dekódoló iterációk száma
BlockLengthHalf = BlockLength / 2;

if mod(BlockLength, 4) ~= 0
    error('AM4_16M_LTE:blockLength', 'A kodszohossz (%d) nem oszthato 4-gyel.', BlockLength);
end

% A 4-QAM két bitet hordoz, ezért L csak páros lehet.
OneBitPartLength = 2 * round((BlockLengthHalf * (double(oneBitPart) + 1)) / 2);
OneBitPartLength = min(max(OneBitPartLength, 0), BlockLength);

oneBitLengths = repmat(OneBitPartLength, 1, K);
oneBitLengths(2:2:end) = BlockLength - OneBitPartLength;
fineBitLengths = BlockLength - oneBitLengths;

% K+1 átviteli szakasz
segmentSymbolLengths = [oneBitLengths(1), fineBitLengths] / 2;
segmentStarts = cumsum([1, segmentSymbolLengths(1:end-1)]);
segmentEnds = cumsum(segmentSymbolLengths);

symOrd4 = buildSymOrder(4);
symOrd16 = buildSymOrder(16);

FINE_SCALE = 1 / sqrt(10);
CLEAN_GAIN = sqrt(5) / 2;
CLEAN_NVFAC = 5 / 4;

noisePowerWatts = 10^((double(noiseDbm) - 30) / 10);
signalPowerWatts = noisePowerWatts * 10^(double(asyncSnrDb) / 10);

if ~(isfinite(noisePowerWatts) && noisePowerWatts > 0 && ...
        isfinite(signalPowerWatts) && signalPowerWatts > 0)
    error('AM4_16M_LTE:physicalPower', 'A noiseDbm/asyncSnrDb ertekekbol nem kepezheto pozitiv teljesitmeny.');
end

TurboErr = 0;
if calcPlace
    place = zeros(1, K);
else
    place = [];
end

errorCount = zeros(1, maxFrames);
maxErrPos = zeros(1, maxFrames);

% Trellis struktúra LTE Turbo kódhoz (szabványos LTE polinomok)
hTrellis = poly2trellis(4, [13 15], 13);
intrlvrIndices = randperm(n); % Interleaver mátrix indexei

parfor frameIdx = 1:maxFrames
    data = cell(1, K);
    codedData = cell(1, K);
    decodedData = cell(1, K);

    for j = 1:K
        data{j} = randi([0 1], n, 1, 'int8');
        % Turbo kódolás (Rate 1/3 kódolás + méretezés/kivágás a BlockLength-hez)
        rawCoded = step(comm.TurboEncoder('TrellisStructure', hTrellis, ...
            'InterleaverIndices', intrlvrIndices), double(data{j}));
        
        % Rate-matching szimulálása (vágás vagy ismétlés BlockLength méretre)
        if length(rawCoded) >= BlockLength
            codedData{j} = rawCoded(1:BlockLength);
        else
            codedData{j} = repmat(rawCoded, ceil(BlockLength/length(rawCoded)), 1);
            codedData{j} = codedData{j}(1:BlockLength);
        end
    end

    inputSignal = complex(zeros(sum(segmentSymbolLengths), 1));

    % Első kódszó első, 4-QAM része
    idx = segmentRange(segmentStarts(1), segmentEnds(1));
    if ~isempty(idx)
        bitsIQ = reshape(codedData{1}(1:oneBitLengths(1)), 2, []).';
        inputSignal(idx) = qammod(idx4(bitsIQ), 4, symOrd4, 'UnitAveragePower', true);
    end

    % Közös 16-QAM szakaszok
    for j = 1:K-1
        fineBits = codedData{j}(oneBitLengths(j)+1:end);
        coarseBits = codedData{j+1}(1:oneBitLengths(j+1));
        idx = segmentRange(segmentStarts(j+1), segmentEnds(j+1));

        if ~isempty(idx)
            fineIQ = reshape(fineBits, 2, []).';
            coarseIQ = reshape(coarseBits, 2, []).';
            inputSignal(idx) = qammod(idx16(coarseIQ, fineIQ), 16, symOrd16, 'UnitAveragePower', true);
        end
    end

    % Utolsó kódszó megmaradó, 4-QAM része
    lastBits = codedData{K}(oneBitLengths(K)+1:end);
    idx = segmentRange(segmentStarts(K+1), segmentEnds(K+1));
    if ~isempty(idx)
        bitsIQ = reshape(lastBits, 2, []).';
        inputSignal(idx) = qammod(idx4(bitsIQ), 4, symOrd4, 'UnitAveragePower', true);
    end

    % Zaj szimuláció
    measuredBasebandPower = mean(abs(inputSignal).^2);
    txScale = sqrt(signalPowerWatts / measuredBasebandPower);
    transmittedSignal = inputSignal * txScale;
    physicalNoise = sqrt(noisePowerWatts/2) .* ...
        (randn(size(inputSignal)) + 1i*randn(size(inputSignal)));
    receivedSignal = transmittedSignal + physicalNoise;

    outputSignal = receivedSignal / txScale;
    totalNoiseVariance = noisePowerWatts / (txScale^2);

    ErrCount = zeros(1, K);

    % Szekvenciális dekódolás
    for j = 1:K-1
        coarseIdx = segmentRange(segmentStarts(j), segmentEnds(j));
        mixedIdx = segmentRange(segmentStarts(j+1), segmentEnds(j+1));

        if j == 1
            coarseNoiseVariance = totalNoiseVariance;
        else
            coarseNoiseVariance = totalNoiseVariance * CLEAN_NVFAC;
        end

        llrCoarse = demod4Llr(outputSignal(coarseIdx), symOrd4, coarseNoiseVariance);
        llrFine = demodFine16Llr(outputSignal(mixedIdx), symOrd16, totalNoiseVariance);

        llrActual = [llrCoarse(:); llrFine(:)];
        
        % LLR kiegészítése a Turbo dekódoló kódolt blokkméretére
        llrTurbo = zeros(3*n + 12, 1);
        llrTurbo(1:min(length(llrActual), length(llrTurbo))) = llrActual(1:min(length(llrActual), length(llrTurbo)));
        
        % LTE Turbo Dekódolás
        decObj = comm.TurboDecoder('TrellisStructure', hTrellis, ...
            'InterleaverIndices', intrlvrIndices, 'NumIterations', maxIter);
        decodedData{j} = step(decObj, -llrTurbo);

        if ~isempty(mixedIdx)
            rawCodedEst = step(comm.TurboEncoder('TrellisStructure', hTrellis, ...
                'InterleaverIndices', intrlvrIndices), double(decodedData{j}));
            if length(rawCodedEst) >= BlockLength
                cwEst = rawCodedEst(1:BlockLength);
            else
                cwEst = repmat(rawCodedEst, ceil(BlockLength/length(rawCodedEst)), 1);
                cwEst = cwEst(1:BlockLength);
            end
            
            fineEst = cwEst(oneBitLengths(j)+1:end);
            fineIQ = reshape(fineEst, 2, []).';
            knownFine = ((1 - 2*fineIQ(:,1)) + 1i*(1 - 2*fineIQ(:,2))) * FINE_SCALE;
            outputSignal(mixedIdx) = (outputSignal(mixedIdx) - knownFine) * CLEAN_GAIN;
        end
    end

    % Utolsó kódszó
    coarseIdx = segmentRange(segmentStarts(K), segmentEnds(K));
    lastIdx = segmentRange(segmentStarts(K+1), segmentEnds(K+1));
    if K == 1
        coarseNoiseVariance = totalNoiseVariance;
    else
        coarseNoiseVariance = totalNoiseVariance * CLEAN_NVFAC;
    end
    llrCoarse = demod4Llr(outputSignal(coarseIdx), symOrd4, coarseNoiseVariance);
    llrLast = demod4Llr(outputSignal(lastIdx), symOrd4, totalNoiseVariance);
    
    llrActual = [llrCoarse(:); llrLast(:)];
    llrTurbo = zeros(3*n + 12, 1);
    llrTurbo(1:min(length(llrActual), length(llrTurbo))) = llrActual(1:min(length(llrActual), length(llrTurbo)));
    
    decObj = comm.TurboDecoder('TrellisStructure', hTrellis, ...
        'InterleaverIndices', intrlvrIndices, 'NumIterations', maxIter);
    decodedData{K} = step(decObj, -llrTurbo);

    for j = 1:K
        ErrCount(j) = biterr(data{j}, decodedData{K});
    end
    errorCount(frameIdx) = sum(ErrCount) / K;

    if calcPlace && any(ErrCount ~= 0)
        [~, jMax] = max(ErrCount);
        maxErrPos(frameIdx) = jMax;
    end
end

if calcPlace
    for frameIdx = 1:maxFrames
        if maxErrPos(frameIdx) > 0
            place(maxErrPos(frameIdx)) = place(maxErrPos(frameIdx)) + 1;
        end
    end
end

TurboErr = mean(errorCount) / n;

end

% Segédfüggvények
function idx = segmentRange(firstIndex, lastIndex)
if lastIndex < firstIndex
    idx = zeros(1, 0);
else
    idx = firstIndex:lastIndex;
end
end

function llr = demod4Llr(y, symOrd4, noiseVariance)
if isempty(y)
    llr = zeros(0, 1);
else
    llr = qamdemod(y, 4, symOrd4, 'UnitAveragePower', true, ...
        'OutputType', 'llr', 'NoiseVariance', noiseVariance);
    llr = llr(:);
end
end

function llrFine = demodFine16Llr(y, symOrd16, noiseVariance)
if isempty(y)
    llrFine = zeros(0, 1);
else
    llr = qamdemod(y, 16, symOrd16, 'UnitAveragePower', true, ...
        'OutputType', 'llr', 'NoiseVariance', noiseVariance);
    llr = reshape(llr, 4, []);
    llrFine = reshape(llr([2 4], :), [], 1);
end
end

function x = idx4(bitsIQ)
x = 2*bitsIQ(:,1) + bitsIQ(:,2);
end

function x = idx16(coarseIQ, fineIQ)
x = 8*coarseIQ(:,1) + 4*fineIQ(:,1) + 2*coarseIQ(:,2) + fineIQ(:,2);
end

function symOrd = buildSymOrder(M)
s = @(b) 1 - 2*b;
labels = (0:M-1).';
switch M
    case 4
        bI = bitget(labels, 2);
        bQ = bitget(labels, 1);
        wanted = (s(bI) + 1i*s(bQ)) / sqrt(2);
    case 16
        cI = bitget(labels, 4);
        fI = bitget(labels, 3);
        cQ = bitget(labels, 2);
        fQ = bitget(labels, 1);
        wanted = ((2*s(cI) + s(fI)) + 1i*(2*s(cQ) + s(fQ))) / sqrt(10);
    otherwise
        error('AM4_16M_LTE:buildSymOrder', 'Csak M = 4 es M = 16 tamogatott.');
end

C0 = qammod(labels, M, 0:M-1, 'UnitAveragePower', true);
pos = zeros(M, 1);
for x = 0:M-1
    [d, p] = min(abs(C0 - wanted(x+1)));
    if d > 1e-9
        error('AM4_16M_LTE:buildSymOrder', 'Konstellacios hiba (M=%d).', M);
    end
    pos(x+1) = p;
end

symOrd = zeros(1, M);
symOrd(pos(:).') = 0:M-1;
end
