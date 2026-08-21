function [TurboErr, n, OneBitPartLength, place] = AM2_4M(H, maxFrames, K, snrRange, calcPlace, oneBitPart)
% AM2_4 Szimulacios mag az LDPC kodolashoz, vegyes BPSK/QPSK modulacioval.

% Alapertelmezett ertekek
if nargin < 6 || isempty(oneBitPart), oneBitPart = 0.5; end
if nargin < 5 || isempty(calcPlace), calcPlace = 0; end
if nargin < 4 || isempty(snrRange), snrRange = 1:0.5:5; end
if nargin < 3 || isempty(K), K = 20; end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000; end

% --- MÁTRIX TÍPUSKORREKCIÓ (A dekóder sparse logical típusú mátrixot igényel) ---
if ~issparse(H) || ~islogical(H)
  H = sparse(logical(H));
end

% Kodolo- es dekodoloobjektumok inicializalasa
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n = cfgLDPCEnc.NumInformationBits;
blockLength = cfgLDPCDec.BlockLength;

% A megadott arany/bitszam atalakitasa konkret kodolt bitszamma.
if ~isscalar(oneBitPart) || ~isnumeric(oneBitPart) || ~isreal(oneBitPart) || ...
    isnan(oneBitPart) || isinf(oneBitPart)
  error('AM2_4:InvalidOneBitPart', ...
    'A oneBitPart ertekenek veges numerikus skalarnak kell lennie.');
elseif oneBitPart > 0 && oneBitPart < 1
  OneBitPartLength = round(blockLength * oneBitPart);
elseif oneBitPart >= 1 && oneBitPart == floor(oneBitPart)
  OneBitPartLength = double(oneBitPart);
else
  error('AM2_4:InvalidOneBitPart', ...
    'A oneBitPart 0 es 1 kozotti arany vagy pozitiv egesz bitszam lehet.');
end

if OneBitPartLength < 1 || OneBitPartLength >= blockLength
  error('AM2_4:InvalidOneBitPartLength', ...
    'A BPSK-resz hosszanak 1 es BlockLength-1 koze kell esnie.');
end

% Az egymast koveto kodszavak reszhosszai valtakoznak.
oneBitLengths = repmat(OneBitPartLength, 1, K);
oneBitLengths(2:2:end) = blockLength - OneBitPartLength;
twoBitLengths = blockLength - oneBitLengths;

% Az atviteli jel K+1 szakasza: kezdo BPSK, K-1 QPSK, zaro BPSK.
segmentLengths = [oneBitLengths(1), twoBitLengths];
segmentStarts = cumsum([1, segmentLengths(1:end-1)]);
segmentEnds = cumsum(segmentLengths);

numframes = 1;
TurboErr = zeros(1, length(snrRange));

if calcPlace
  place = zeros(1, K);
else
  place = [];
end

for snr_idx = 1:length(snrRange)
  snr = snrRange(snr_idx);
  error_count = zeros(1, maxFrames);

  for k_idx = 1:maxFrames
    data = cell(1, K);
    codedData = cell(1, K);

    for j = 1:K
      data{j} = randi([0 1], n, numframes, 'int8');
      codedData{j} = ldpcEncode(data{j}, cfgLDPCEnc);
      codedData{j} = codedData{j}(:);
    end

    % Az elso kodszo BPSK-modulalt resze
    input = complex(zeros(sum(segmentLengths), 1));
    firstIndices = segmentStarts(1):segmentEnds(1);
    input(firstIndices) = pskmod( ...
      codedData{1}(1:oneBitLengths(1)), 2, 0);

    % QPSK szakaszok
    for j = 1:K-1
      currentRemainder = codedData{j}(oneBitLengths(j)+1:end);
      nextOneBitPart = codedData{j+1}(1:oneBitLengths(j+1));
      qpskInput = bi2de([currentRemainder, nextOneBitPart], "left-msb");
      qpskIndices = segmentStarts(j+1):segmentEnds(j+1);
      input(qpskIndices) = pskmod(qpskInput, 4, pi/4);
    end

    % Utolso BPSK szakasz
    lastRemainder = codedData{K}(oneBitLengths(K)+1:end);
    lastIndices = segmentStarts(K+1):segmentEnds(K+1);
    input(lastIndices) = pskmod(lastRemainder, 2, 0);

    output = awgn(input, snr, 'measured');

    decodedData = cell(1, K);
    ErrCount = zeros(1, K);

    % Szekvencialis dekodolas es interferencia-kivonas
    for j = 1:K-1
      oneBitIndices = segmentStarts(j):segmentEnds(j);
      twoBitIndices = segmentStarts(j+1):segmentEnds(j+1);

      llrOneBitPart = pskdemod(output(oneBitIndices), 2, 0, OutputType="llr");
      qpskLLR = pskdemod(output(twoBitIndices), 4, pi/4, OutputType="llr");
      qpskLLR = reshape(qpskLLR, [2, twoBitLengths(j)])';

      llrActual = [llrOneBitPart(:); qpskLLR(:, 1)];
      decodedData{j} = ldpcDecode(llrActual, cfgLDPCDec, 10);

      estimatedCodeword = ldpcEncode(decodedData{j}, cfgLDPCEnc);
      estimatedRemainder = estimatedCodeword(oneBitLengths(j)+1:end);
      estimatedContribution = 1/sqrt(2) * pskmod(estimatedRemainder, 2, pi/2);

      output(twoBitIndices) = output(twoBitIndices) - estimatedContribution;
    end

    % Utolso kodszo dekodolasa
    firstIndices = segmentStarts(K):segmentEnds(K);
    lastIndices = segmentStarts(K+1):segmentEnds(K+1);
    llrFirstPart = pskdemod(output(firstIndices), 2, 0, OutputType="llr");
    llrLastPart = pskdemod(output(lastIndices), 2, 0, OutputType="llr");
    llrActual = [llrFirstPart(:); llrLastPart(:)];
    decodedData{K} = ldpcDecode(llrActual, cfgLDPCDec, 10);

    for j = 1:K
      ErrCount(j) = biterr(data{j}, decodedData{j});
    end

    error_count(k_idx) = sum(ErrCount) / K;

    if calcPlace && any(ErrCount ~= 0)
      [~, j_max] = max(ErrCount);
      place(j_max) = place(j_max) + 1;
    end
  end

  TurboErr(snr_idx) = mean(error_count) / n;
end

end
