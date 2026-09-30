function [Ldpc_ErrP, n, BlockLengthHalf] = Sync_LDPC(H, maxFrames, snrRange, bitsPerSymbol)
% SYNC_LDPC Szinkron referencia átvitel (Worker-Chunking / Memóriabiztos)

    if nargin < 4 || isempty(bitsPerSymbol), bitsPerSymbol = 2; end
    if nargin < 3 || isempty(snrRange),      snrRange      = 1:0.5:6; end
    if nargin < 2 || isempty(maxFrames),     maxFrames     = 2000; end

    if bitsPerSymbol ~= 2 && bitsPerSymbol ~= 4
        error('Sync_LDPC:invalidModulation', 'Csak bitsPerSymbol = 2 (QPSK) vagy 4 (16-QAM) támogatott!');
    end

    [M, BlockLength] = size(H);
    n = BlockLength - M;
    BlockLengthHalf = BlockLength / 2;

    if mod(BlockLength, bitsPerSymbol) ~= 0
        error('Sync_LDPC:invalidBitLength', ...
            'A kódszóhossz (%d) nem osztható bitsPerSymbol-lal (%d)!', BlockLength, bitsPerSymbol);
    end

    nSym = BlockLength / bitsPerSymbol;
    Ldpc_ErrP = zeros(1, length(snrRange));

    % Munkaszálak számának dinamikus felderítése
    poolObj = gcp('nocreate');
    if isempty(poolObj)
        numWorkers = 1;
    else
        numWorkers = poolObj.NumWorkers;
    end

    % Keretek egyenletes elosztása a workerek között (Chunking)
    framesPerWorker = repmat(floor(maxFrames / numWorkers), 1, numWorkers);
    framesPerWorker(1:mod(maxFrames, numWorkers)) = framesPerWorker(1:mod(maxFrames, numWorkers)) + 1;

    % --- 1. ÁG: QPSK MODULÁCIÓ (2 bit/szimbólum) ---
    if bitsPerSymbol == 2
        for s_idx = 1:length(snrRange)
            snr = snrRange(s_idx);
            N0  = 10^(-snr / 10);
            workerErrors = zeros(1, numWorkers);

            parfor w = 1:numWorkers
                % Az objektumok CSAK EGYSZER jönnek létre szálanként!
                localEnc = comm.LDPCEncoder(H);
                localDec = comm.LDPCDecoder(H, ...
                    'MaximumIterationCount', 10, ...
                    'DecisionMethod', 'Hard decision', ...
                    'OutputValue', 'Information part');

                numFramesThisWorker = framesPerWorker(w);
                localHiba = 0;

                for k = 1:numFramesThisWorker
                    data = randi([0 1], n, 1, 'double');
                    codedData = double(localEnc(data));

                    cPairs = reshape(codedData, [2, nSym])';
                    symIdx = double(bi2de(cPairs, 'left-msb'));
                    tx = pskmod(symIdx, 4, pi/4);

                    rx = awgn(tx, snr, 'measured');
                    llr = psk_llr_demod(rx, 4, pi/4, N0);

                    decodedData = double(localDec(llr));
                    localHiba = localHiba + biterr(data, decodedData);
                end

                workerErrors(w) = localHiba;
            end

            Ldpc_ErrP(s_idx) = sum(workerErrors) / (maxFrames * n);
        end

    % --- 2. ÁG: 16-QAM MODULÁCIÓ (4 bit/szimbólum) ---
    else
        for s_idx = 1:length(snrRange)
            snr = snrRange(s_idx);
            N0  = 10^(-snr / 10);
            workerErrors = zeros(1, numWorkers);

            parfor w = 1:numWorkers
                localEnc = comm.LDPCEncoder(H);
                localDec = comm.LDPCDecoder(H, ...
                    'MaximumIterationCount', 10, ...
                    'DecisionMethod', 'Hard decision', ...
                    'OutputValue', 'Information part');

                numFramesThisWorker = framesPerWorker(w);
                localHiba = 0;

                for k = 1:numFramesThisWorker
                    data = randi([0 1], n, 1, 'double');
                    codedData = double(localEnc(data));

                    cQuads = reshape(codedData, [4, nSym])';
                    symIdx = double(bi2de(cQuads, 'left-msb'));
                    tx = qammod(symIdx, 16, 'UnitAveragePower', true);

                    rx = awgn(tx, snr, 'measured');
                    llr = qamdemod(rx, 16, 'UnitAveragePower', true, ...
                                   'OutputType', 'approxllr', 'NoiseVariance', N0);

                    decodedData = double(localDec(llr));
                    localHiba = localHiba + biterr(data, decodedData);
                end

                workerErrors(w) = localHiba;
            end

            Ldpc_ErrP(s_idx) = sum(workerErrors) / (maxFrames * n);
        end
    end
end

function llr = psk_llr_demod(rx, M, ini_phase, N0)
    rx = rx(:);
    const = pskmod((0:M-1)', M, ini_phase);
    dist2 = abs(rx - const.').^2;

    if M == 2
        llr = (dist2(:, 2) - dist2(:, 1)) / N0;
    elseif M == 4
        d_b1_0 = min(dist2(:, 1), dist2(:, 2));
        d_b1_1 = min(dist2(:, 3), dist2(:, 4));
        llr1 = (d_b1_1 - d_b1_0) / N0;

        d_b2_0 = min(dist2(:, 1), dist2(:, 3));
        d_b2_1 = min(dist2(:, 2), dist2(:, 4));
        llr2 = (d_b2_1 - d_b2_0) / N0;

        llr_mat = [llr1, llr2]';
        llr = llr_mat(:);
    end
end