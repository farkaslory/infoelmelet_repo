function [TurboErr, n, BlockLengthHalf, place] = AM2_4(H, maxFrames, K, snrRange, calcPlace)
% AM2_4 BPSK/QPSK aszinkron lánc (Worker-Chunking / Memóriabiztos)

    if nargin < 5 || isempty(calcPlace), calcPlace = 0; end
    if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:6; end
    if nargin < 3 || isempty(K),         K         = 20; end
    if nargin < 2 || isempty(maxFrames), maxFrames = 1000; end

    [M, BlockLength] = size(H);
    n               = BlockLength - M;
    BlockLengthHalf = BlockLength / 2;

    TurboErr = zeros(1, length(snrRange));
    if calcPlace
        place = zeros(1, K);
    else
        place = [];
    end

    poolObj = gcp('nocreate');
    if isempty(poolObj)
        numWorkers = 1;
    else
        numWorkers = poolObj.NumWorkers;
    end

    framesPerWorker = repmat(floor(maxFrames / numWorkers), 1, numWorkers);
    framesPerWorker(1:mod(maxFrames, numWorkers)) = framesPerWorker(1:mod(maxFrames, numWorkers)) + 1;

    for snr_idx = 1:length(snrRange)
        snr = snrRange(snr_idx);
        N0  = 10^(-snr / 10);

        workerTotalErrors = zeros(1, numWorkers);
        workerPlaceMatrix = zeros(numWorkers, K);

        parfor w = 1:numWorkers
            % Egyetlen inicializálás munkaszálanként
            localEnc = comm.LDPCEncoder(H);
            localDec = comm.LDPCDecoder(H, ...
                'MaximumIterationCount', 10, ...
                'DecisionMethod', 'Hard decision', ...
                'OutputValue', 'Information part');

            numFramesThisWorker = framesPerWorker(w);
            localErrSum = 0;
            localPlace  = zeros(1, K);

            for k_idx = 1:numFramesThisWorker
                data = cell(1, K);
                codedData = cell(1, K);
                cD1 = cell(1, K);

                for j = 1:K
                    data{j} = randi([0 1], n, 1, 'double');
                end

                for j = 1:K
                    codedData{j} = double(localEnc(data{j}));
                    cD1{j} = reshape(codedData{j}, [2, BlockLengthHalf])';
                end

                input = pskmod(double(cD1{1}(:, 1)), 2, 0);
                for j = 1:K-1
                    input1 = double(bi2de(double([cD1{j}(:, 2), cD1{j+1}(:, 1)]), 'left-msb'));
                    input = [input; pskmod(input1, 4, pi/4)];
                end
                input = [input; pskmod(double(cD1{K}(:, 2)), 2, 0)];

                output = awgn(input, snr, 'measured');

                LLR = cell(1, K);
                decodedData = cell(1, K);
                ErrCount = zeros(1, K);

                for j = 1:K-1
                    y1 = output(BlockLengthHalf*(j-1)+1 : BlockLengthHalf*j);
                    LLR1Half = psk_llr_demod(y1, 2, 0, N0);

                    y2 = output(BlockLengthHalf*j+1 : BlockLengthHalf*(j+1));
                    LLR2Half = reshape(psk_llr_demod(y2, 4, pi/4, N0), [2, BlockLengthHalf])';

                    LLR{j} = [LLR1Half, LLR2Half(:, 1)];
                    LlrActual = LLR{j}';

                    decodedData{j} = double(localDec(LlrActual(:)));

                    EstimatedCodeword = double(localEnc(decodedData{j}));
                    EstimatedCodeword = reshape(EstimatedCodeword, [2, BlockLengthHalf])';
                    SecondPartECWinFourier = pskmod(double(EstimatedCodeword(:, 2)), 2, pi/2);
                    output(BlockLengthHalf*j+1 : BlockLengthHalf*(j+1)) = ...
                        output(BlockLengthHalf*j+1 : BlockLengthHalf*(j+1)) - (1/sqrt(2)) * SecondPartECWinFourier;
                end

                yK = output(BlockLengthHalf*(K-1)+1 : BlockLengthHalf*(K+1));
                LLR{K} = reshape(psk_llr_demod(yK, 2, 0, N0), [BlockLengthHalf, 2]);
                LlrActual = LLR{K}';
                decodedData{K} = double(localDec(LlrActual(:)));

                for j = 1:K
                    ErrCount(j) = biterr(data{j}, decodedData{j});
                end

                localErrSum = localErrSum + (sum(ErrCount) / K);

                if calcPlace && any(ErrCount ~= 0)
                    [~, j_max] = max(ErrCount);
                    localPlace(j_max) = localPlace(j_max) + 1;
                end
            end

            workerTotalErrors(w) = localErrSum;
            if calcPlace
                workerPlaceMatrix(w, :) = localPlace;
            end
        end

        if calcPlace
            place = place + sum(workerPlaceMatrix, 1);
        end

        TurboErr(snr_idx) = sum(workerTotalErrors) / (maxFrames * n);
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