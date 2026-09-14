function [TurboErr, n, BlockLengthHalf, place] = AM4_16(H, maxFrames, K, snrRange, calcPlace)
% AM4_16 Szimulációs mag az AAC lánchoz, 4-QAM / 16-QAM modulációval. (Párhuzamosított)

if nargin < 5 || isempty(calcPlace), calcPlace = 0;        end
if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:5;  end
if nargin < 3 || isempty(K),         K         = 20;       end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;     end

maxIter = 10;   

cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;
BlockLengthHalf = BlockLength / 2;     
nSym            = BlockLengthHalf / 2; 

if mod(BlockLength,4) ~= 0
    error('AM4_16:blockLength', ...
        'A kodszohossz (%d) nem oszthato 4-gyel.', BlockLength);
end
if K < 1
    error('AM4_16:K','K legalabb 1 kell legyen.');
end

symOrd4  = buildSymOrder(4);
symOrd16 = buildSymOrder(16);

FINE_SCALE  = 1/sqrt(10);
CLEAN_GAIN  = sqrt(5)/2;
CLEAN_NVFAC = 5/4;

TurboErr = zeros(1, numel(snrRange));
if calcPlace
    place = zeros(1, K);
else
    place = [];
end

for snr_idx = 1:numel(snrRange)
    snr = snrRange(snr_idx);
    N0 = 10^(-snr/10);

    error_count = zeros(1, maxFrames);
    max_err_pos = zeros(1, maxFrames);

    parfor k_idx = 1:maxFrames
        % Lokális előfoglalások a worker szálak számára
        data        = cell(1, K);
        half1IQ     = cell(1, K);
        half2IQ     = cell(1, K);
        decodedData = cell(1, K);

        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            cw      = double(ldpcEncode(data{j}, cfgLDPCEnc));
            cD      = reshape(cw, [2 BlockLengthHalf])';
            half1IQ{j} = reshape(cD(:,1), [2 nSym])';
            half2IQ{j} = reshape(cD(:,2), [2 nSym])';
        end

        input = zeros((K+1)*nSym, 1);
        input(1:nSym) = qammod(idx4(half1IQ{1}), 4, symOrd4, 'UnitAveragePower', true);

        for j = 1:K-1
            input(nSym*j+1 : nSym*(j+1)) = ...
                qammod(idx16(half1IQ{j+1}, half2IQ{j}), 16, symOrd16, 'UnitAveragePower', true);
        end
        input(nSym*K+1 : nSym*(K+1)) = qammod(idx4(half2IQ{K}), 4, symOrd4, 'UnitAveragePower', true);

        output = awgn(input, snr, 'measured');
        ErrCount = zeros(1, K);

        for j = 1:K-1
            if j == 1
                nvA = N0;
            else
                nvA = N0 * CLEAN_NVFAC;
            end
            yA = output(nSym*(j-1)+1 : nSym*j);
            llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', nvA);

            yB   = output(nSym*j+1 : nSym*(j+1));
            llrB = qamdemod(yB, 16, symOrd16, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
            llrB = reshape(llrB, 4, nSym);              
            llrFine = reshape(llrB([2 4], :), [], 1);   

            LlrActual = [llrA, llrFine]';
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

            cwEst = double(ldpcEncode(decodedData{j}, cfgLDPCEnc));
            cDe   = reshape(cwEst, [2 BlockLengthHalf])';
            fIQ   = reshape(cDe(:,2), [2 nSym])';
            knownFine = ((1 - 2*fIQ(:,1)) + 1i*(1 - 2*fIQ(:,2))) * FINE_SCALE;

            output(nSym*j+1 : nSym*(j+1)) = (yB - knownFine) * CLEAN_GAIN;
        end

        if K == 1
            nvA = N0;                 
        else
            nvA = N0 * CLEAN_NVFAC;   
        end
        yA = output(nSym*(K-1)+1 : nSym*K);
        yB = output(nSym*K+1     : nSym*(K+1));
        llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', nvA);
        llrB = qamdemod(yB, 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', N0);
        LlrActual = [llrA, llrB]';
        decodedData{K} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxIter);

        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
        end
        error_count(k_idx) = sum(ErrCount) / K;

        if calcPlace && any(ErrCount ~= 0)
            [~, j_max] = max(ErrCount);
            max_err_pos(k_idx) = j_max;
        end
    end

    if calcPlace
        for k_idx = 1:maxFrames
            if max_err_pos(k_idx) > 0
                place(max_err_pos(k_idx)) = place(max_err_pos(k_idx)) + 1;
            end
        end
    end

    TurboErr(snr_idx) = mean(error_count) / n;
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
    labels = (0:M-1)';
    switch M
        case 4
            bI = bitget(labels, 2);  bQ = bitget(labels, 1);
            wanted = (s(bI) + 1i*s(bQ)) / sqrt(2);
        case 16
            cI = bitget(labels, 4);  fI = bitget(labels, 3);
            cQ = bitget(labels, 2);  fQ = bitget(labels, 1);
            wanted = ((2*s(cI) + s(fI)) + 1i*(2*s(cQ) + s(fQ))) / sqrt(10);
        otherwise
            error('AM4_16:buildSymOrder','Csak M = 4 es M = 16 tamogatott.');
    end
    C0 = qammod(labels, M, 0:M-1, 'UnitAveragePower', true);
    pos = zeros(M,1);
    for x = 0:M-1
        [d, p] = min(abs(C0 - wanted(x+1)));
        if d > 1e-9
            error('AM4_16:buildSymOrder', 'Hiba (M=%d).', M);
        end
        pos(x+1) = p;
    end
    symOrd = zeros(1, M);
    symOrd(pos(:)') = 0:M-1;
    if maxdev(symOrd, M, wanted) > 1e-9
        symOrd = (pos - 1)';
        if maxdev(symOrd, M, wanted) > 1e-9
            error('AM4_16:buildSymOrder', 'Hiba (M=%d).', M);
        end
    end
end

function d = maxdev(symOrd, M, wanted)
    chk = qammod((0:M-1)', M, symOrd, 'UnitAveragePower', true);
    d = max(abs(chk - wanted));
end