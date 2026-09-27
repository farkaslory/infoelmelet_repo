

function [TurboErr, n, OneBitPartLength, place] = AM4_16M( ...
        H, maxFrames, K, noiseDbm, calcPlace, oneBitPart, asyncSnrDb)
% AM4_16M Valtozo 4-QAM/16-QAM felosztasu LDPC szimulacio.
%
% [TurboErr,n,OneBitPartLength,place] = AM4_16M( ...
%     H,maxFrames,K,noiseDbm,calcPlace,oneBitPart,asyncSnrDb)
%
% Bemenetek:
%   H           - LDPC paritasellenorzo matrix.
%   maxFrames   - Szimulalt keretek szama (alapertelmezett: 1000).
%   K           - Egymas utan dekodolt kodszavak szama (alapert.: 20).
%   noiseDbm    - Rogzitett komplex AWGN zajteljesitmeny [dBm].
%                 Alapertelmezett: -80 dBm.
%   calcPlace   - Hibapozicio-szamlalas kapcsoloja (0 vagy 1).
%   oneBitPart  - Normalizalt 4-QAM-reszhossz, -1 es +1 kozott:
%                   -1 -> L = 0,
%                    0 -> L = BlockLength/2,
%                   +1 -> L = BlockLength.
%                 Az atszamitas: L = BlockLengthHalf*(oneBitPart+1).
%                 L a legkozelebbi paros bitszamra kerekedik.
%   asyncSnrDb - Az aszinkron kapcsolat atlagos SNR-je [dB].
%                Alapertelmezett: 8 dB. Egysegnyi csatornaerositesnel a
%                jelteljesitmeny noiseDbm + asyncSnrDb dBm.
%
% Kimenetek:
%   TurboErr          - A rogzitett zajszinthez tartozo skalár BER.
%   n                 - Informacios bitek szama kodszavankent.
%   OneBitPartLength  - A 4-QAM-mal tovabbitott elso resz bitszama.
%   place             - A legnagyobb hibaju kodszo poziciojanak szamlaloi;
%                       [] ha calcPlace == 0.
%
% A j-edik kodszo elso resze 4-QAM-mal megy at. A maradek resz a
% (j+1)-edik kodszo elso reszevel alkot 16-QAM-szimbolumokat. Emiatt a
% 4-QAM-reszhossz kodszavankent L es BlockLength-L kozott valtakozik.

if nargin < 7 || isempty(asyncSnrDb), asyncSnrDb = 8;     end
if nargin < 6 || isempty(oneBitPart), oneBitPart = 0;     end
if nargin < 5 || isempty(calcPlace),  calcPlace = 0;      end
if nargin < 4 || isempty(noiseDbm),   noiseDbm = -80;     end
if nargin < 3 || isempty(K),          K = 20;             end
if nargin < 2 || isempty(maxFrames),  maxFrames = 1000;   end

validateattributes(H, {'numeric','logical'}, {'2d','nonempty'}, ...
    mfilename, 'H', 1);
validateattributes(maxFrames, {'numeric'}, ...
    {'scalar','real','finite','integer','positive'}, mfilename, 'maxFrames', 2);
validateattributes(K, {'numeric'}, ...
    {'scalar','real','finite','integer','positive'}, mfilename, 'K', 3);
validateattributes(noiseDbm, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'noiseDbm', 4);
validateattributes(calcPlace, {'numeric','logical'}, ...
    {'scalar','binary'}, mfilename, 'calcPlace', 5);
validateattributes(oneBitPart, {'numeric'}, ...
    {'scalar','real','finite','>=',-1,'<=',1}, mfilename, 'oneBitPart', 6);
validateattributes(asyncSnrDb, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'asyncSnrDb', 7);

maxIter = 10;
H = sparse(logical(H));
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n = cfgLDPCEnc.NumInformationBits;
BlockLength = cfgLDPCDec.BlockLength;
BlockLengthHalf = BlockLength / 2;

if mod(BlockLength, 4) ~= 0
    error('AM4_16M:blockLength', ...
        'A kodszohossz (%d) nem oszthato 4-gyel.', BlockLength);
end

% A 4-QAM ket bitet hordoz, ezert L csak paros lehet.
OneBitPartLength = 2 * round( ...
    (BlockLengthHalf * (double(oneBitPart) + 1)) / 2);
OneBitPartLength = min(max(OneBitPartLength, 0), BlockLength);

oneBitLengths = repmat(OneBitPartLength, 1, K);
oneBitLengths(2:2:end) = BlockLength - OneBitPartLength;
fineBitLengths = BlockLength - oneBitLengths;

% K+1 atviteli szakasz: kezdo 4-QAM, K-1 kozos 16-QAM, zaro 4-QAM.
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
    error('AM4_16M:physicalPower', ...
        'A noiseDbm/asyncSnrDb ertekekbol nem kepezheto pozitiv teljesitmeny.');
end

TurboErr = 0;
if calcPlace
    place = zeros(1, K);
else
    place = [];
end

errorCount = zeros(1, maxFrames);
maxErrPos = zeros(1, maxFrames);

    parfor frameIdx = 1:maxFrames
        data = cell(1, K);
        codedData = cell(1, K);
        decodedData = cell(1, K);

        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            codedData{j} = double(ldpcEncode(data{j}, cfgLDPCEnc));
            codedData{j} = codedData{j}(:);
        end

        inputSignal = complex(zeros(sum(segmentSymbolLengths), 1));

        % Elso kodszo elso, 4-QAM resze.
        idx = segmentRange(segmentStarts(1), segmentEnds(1));
        if ~isempty(idx)
            bitsIQ = reshape(codedData{1}(1:oneBitLengths(1)), 2, []).';
            inputSignal(idx) = qammod(idx4(bitsIQ), 4, symOrd4, ...
                'UnitAveragePower', true);
        end

        % Kozos 16-QAM szakaszok: aktualis finom + kovetkezo durva bitek.
        for j = 1:K-1
            fineBits = codedData{j}(oneBitLengths(j)+1:end);
            coarseBits = codedData{j+1}(1:oneBitLengths(j+1));
            idx = segmentRange(segmentStarts(j+1), segmentEnds(j+1));

            if numel(fineBits) ~= numel(coarseBits)
                error('AM4_16M:internalLength', ...
                    'A 16-QAM bitfolyamok hossza nem egyezik.');
            end
            if ~isempty(idx)
                fineIQ = reshape(fineBits, 2, []).';
                coarseIQ = reshape(coarseBits, 2, []).';
                inputSignal(idx) = qammod(idx16(coarseIQ, fineIQ), 16, ...
                    symOrd16, 'UnitAveragePower', true);
            end
        end

        % Utolso kodszo megmarado, 4-QAM resze.
        lastBits = codedData{K}(oneBitLengths(K)+1:end);
        idx = segmentRange(segmentStarts(K+1), segmentEnds(K+1));
        if ~isempty(idx)
            bitsIQ = reshape(lastBits, 2, []).';
            inputSignal(idx) = qammod(idx4(bitsIQ), 4, symOrd4, ...
                'UnitAveragePower', true);
        end

        % Fizikai teljesitmenyskala: noiseDbm rogzitett, az atlagos
        % jelteljesitmeny pedig noiseDbm + asyncSnrDb dBm.
        measuredBasebandPower = mean(abs(inputSignal).^2);
        txScale = sqrt(signalPowerWatts / measuredBasebandPower);
        transmittedSignal = inputSignal * txScale;
        physicalNoise = sqrt(noisePowerWatts/2) .* ...
            (randn(size(inputSignal)) + 1i*randn(size(inputSignal)));
        receivedSignal = transmittedSignal + physicalNoise;

        % Visszaskalazas a UnitAveragePower QAM-konstellaciora. Ez a
        % variancia kerul az LLR demodulatorokba.
        outputSignal = receivedSignal / txScale;
        totalNoiseVariance = noisePowerWatts / (txScale^2);

        ErrCount = zeros(1, K);

        % Szekvencialis dekodolas es a finom komponens kivonasa.
        for j = 1:K-1
            coarseIdx = segmentRange(segmentStarts(j), segmentEnds(j));
            mixedIdx = segmentRange(segmentStarts(j+1), segmentEnds(j+1));

            if j == 1
                coarseNoiseVariance = totalNoiseVariance;
            else
                coarseNoiseVariance = totalNoiseVariance * CLEAN_NVFAC;
            end

            llrCoarse = demod4Llr(outputSignal(coarseIdx), symOrd4, ...
                coarseNoiseVariance);
            llrFine = demodFine16Llr(outputSignal(mixedIdx), symOrd16, ...
                totalNoiseVariance);

            llrActual = [llrCoarse(:); llrFine(:)];
            decodedData{j} = ldpcDecode(llrActual, cfgLDPCDec, maxIter);

            % A becsult finom 16-QAM komponens eltavolitasa utan a kovetkezo
            % kodszo durva komponense szabvanyos, egysegatlagteljesitmenyu
            % 4-QAM konstellaciora skalazodik.
            if ~isempty(mixedIdx)
                cwEst = double(ldpcEncode(decodedData{j}, cfgLDPCEnc));
                fineEst = cwEst(oneBitLengths(j)+1:end);
                fineIQ = reshape(fineEst, 2, []).';
                knownFine = ((1 - 2*fineIQ(:,1)) + ...
                    1i*(1 - 2*fineIQ(:,2))) * FINE_SCALE;
                outputSignal(mixedIdx) = ...
                    (outputSignal(mixedIdx) - knownFine) * CLEAN_GAIN;
            end
        end

        % Utolso kodszo: megtisztitott elso resz + kozvetlen zaro resz.
        coarseIdx = segmentRange(segmentStarts(K), segmentEnds(K));
        lastIdx = segmentRange(segmentStarts(K+1), segmentEnds(K+1));
        if K == 1
            coarseNoiseVariance = totalNoiseVariance;
        else
            coarseNoiseVariance = totalNoiseVariance * CLEAN_NVFAC;
        end
        llrCoarse = demod4Llr(outputSignal(coarseIdx), symOrd4, ...
            coarseNoiseVariance);
        llrLast = demod4Llr(outputSignal(lastIdx), symOrd4, ...
            totalNoiseVariance);
        decodedData{K} = ldpcDecode([llrCoarse(:); llrLast(:)], ...
            cfgLDPCDec, maxIter);

        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
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
x = 8*coarseIQ(:,1) + 4*fineIQ(:,1) + ...
    2*coarseIQ(:,2) + fineIQ(:,2);
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
        wanted = ((2*s(cI) + s(fI)) + ...
            1i*(2*s(cQ) + s(fQ))) / sqrt(10);
    otherwise
        error('AM4_16M:buildSymOrder', ...
            'Csak M = 4 es M = 16 tamogatott.');
end

C0 = qammod(labels, M, 0:M-1, 'UnitAveragePower', true);
pos = zeros(M, 1);
for x = 0:M-1
    [d, p] = min(abs(C0 - wanted(x+1)));
    if d > 1e-9
        error('AM4_16M:buildSymOrder', 'Konstellacios hiba (M=%d).', M);
    end
    pos(x+1) = p;
end

symOrd = zeros(1, M);
symOrd(pos(:).') = 0:M-1;
if maxdev(symOrd, M, wanted) > 1e-9
    symOrd = (pos - 1).';
    if maxdev(symOrd, M, wanted) > 1e-9
        error('AM4_16M:buildSymOrder', ...
            'A szimbolumsorrend nem allithato elo (M=%d).', M);
    end
end
end

function d = maxdev(symOrd, M, wanted)
chk = qammod((0:M-1).', M, symOrd, 'UnitAveragePower', true);
d = max(abs(chk - wanted));
end

