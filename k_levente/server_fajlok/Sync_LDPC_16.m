function [Ldpc_ErrP, n, BlockLengthHalf] = Sync_LDPC_16(H, maxFrames, snrRange)
% SYNC_LDPC_16 Szinkron 16-QAM referencia átvitel (Worker-Chunking / Memóriabiztos)

    if nargin < 3 || isempty(snrRange),  snrRange  = 10:20;  end
    if nargin < 2 || isempty(maxFrames), maxFrames = 2000;   end

    [M, BlockLength] = size(H);
    n               = BlockLength - M;
    BlockLengthHalf = BlockLength / 2;

    if mod(BlockLength, 4) ~= 0
        error('Sync_LDPC_16:invalidLength', 'A kódszóhossz nem osztható 4-gyel!');
    end

    nSym = BlockLength / 4;
    Ldpc_ErrP = zeros(1, length(snrRange));

    poolObj = gcp('nocreate');
    if isempty(poolObj)
        numWorkers = 1;
    else
        numWorkers = poolObj.NumWorkers;
    end

    framesPerWorker = repmat(floor(maxFrames / numWorkers), 1, numWorkers);
    framesPerWorker(1:mod(maxFrames, numWorkers)) = framesPerWorker(1:mod(maxFrames, numWorkers)) + 1;

    for s_idx = 1:length(snrRange)
        snr = snrRange(s_idx);
        N0  = 10^(-snr / 10);
        workerErrors = zeros(1, numWorkers);

        parfor w = 1:numWorkers
            % Az objektumok CSAK EGYSZER jönnek létre munkaszálanként
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

                cD1 = reshape(codedData, [4, nSym])';
                input1 = double(bi2de(cD1, 'left-msb'));
                input = qammod(input1, 16, 'UnitAveragePower', true);

                output = awgn(input, snr, 'measured');
                output1 = qamdemod(output, 16, 'UnitAveragePower', true, ...
                                   'OutputType', 'llr', 'NoiseVariance', N0);

                decodedData = double(localDec(output1));
                localHiba = localHiba + biterr(data, decodedData);
            end

            workerErrors(w) = localHiba;
        end

        Ldpc_ErrP(s_idx) = sum(workerErrors) / (maxFrames * n);
    end
end