function [Ldpc_ErrP, n, BlockLengthHalf, FER] = Sync_LDPC_16_V2(H, maxFrames, snrRange, useAacLabeling)
% SYNC_LDPC_16  Szinkron referencia átvitel 16-QAM modulációval és LDPC/BP dekódolással.

%
% Ez az a referencia, amihez az AAC láncot hasonlítjuk. Itt minden kódszó
% önállóan van modulálva, nincs átlapolás a szomszédos kódszavak között.
%
% Bemenetek:
%   H              - Paritásellenőrző mátrix (sparse logical)
%   maxFrames      - Keretek száma SNR pontonként   (alapértelmezett: 1000)
%   snrRange       - SNR vektor [dB], Es/N0         (alapértelmezett: 2:0.5:8)
%   useAacLabeling - 
%                    Szabványos GRAY leképezés -- ez a
%                    valódi, tisztességes referencia.
%                    Ugyanaz a NEM Gray leképezés, amit az AAC lánc
%                    kénytelen használni (buildSymOrder). Ez a kontrollgörbe
%                    választja szét, hogy egy esetleges AAC-vs-szinkron
%                    különbségből mennyi származik pusztán a leképezésből, és
%                    mennyi a SIC szerkezetéből.
%
% Kimenetek:
%   Ldpc_ErrP       - Átlagos bithibaarány (BER) vektor
%   n               - Információs bitek száma blokkonként
%   BlockLengthHalf - Fél kódszóhossz bitben
%   FER             - Keret-hibaarány vektor       


if nargin < 4 || isempty(useAacLabeling), useAacLabeling = false;  end   
if nargin < 3 || isempty(snrRange),       snrRange  = 2:0.5:8;     end
if nargin < 2 || isempty(maxFrames),      maxFrames = 1000;        end

cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;        
BlockLengthHalf = BlockLength / 2;
maxnumiter      = 10; % Belief Propagation iterációszám (megegyezik az AM4_16-tal)

% . A 16-QAM csoportosítás 4 bitet igényel
% szimbólumonként, ezért BlockLength/4-nek egésznek kell lennie.
if mod(BlockLength, 4) ~= 0
    error('Sync_LDPC_16:blockLength', ...
        'A kódszóhossz (%d) nem osztható 4-gyel, így a 16-QAM csoportosítás nem megy ki.', ...
        BlockLength);
end

% szimbólumsorrend választása.
% A 'gray' a qammod alapértelmezett leképezése; egyébként az AAC lánc saját,
% nem Gray sorrendje, ugyanúgy felépítve és ellenőrizve, mint az AM4_16-ban.
if useAacLabeling
    symOrd = buildSymOrder16();
else
    symOrd = 'gray';
end

Ldpc_ErrP = zeros(1, length(snrRange));
FER       = zeros(1, length(snrRange));          

for s_idx = 1:length(snrRange)
    snr = snrRange(s_idx);
    hiba      = zeros(1, maxFrames);
    hibaKeret = zeros(1, maxFrames);            
    N0 = 10^(-snr/10);

    parfor k = 1:maxFrames
        data = randi([0 1], n, 1, 'int8');
        codedData = ldpcEncode(data, cfgLDPCEnc);


        cD1 = reshape(double(codedData), 4, []);
        input1 = bit2int(cD1, 4).';
        input = qammod(input1, 16, symOrd, "UnitAveragePower", true);   

        output = awgn(input, snr, 'measured');
        output1 = qamdemod(output, 16, symOrd, 'UnitAveragePower', true, 
                            'OutputType', 'llr', 'NoiseVariance', N0);  

        decodedData = ldpcDecode(output1, cfgLDPCDec, maxnumiter);

        hiba(k)      = biterr(data, decodedData);
        hibaKeret(k) = hiba(k) > 0;              
    end

    Ldpc_ErrP(s_idx) = mean(hiba) / n;
    FER(s_idx)       = mean(hibaKeret);         
end
end


%% ########################################################################
%  SEGÉDFÜGGVÉNYEK                                 
%% ########################################################################

function symOrd = buildSymOrder16()
% Azt a symOrder vektort adja vissza, amellyel a qammod az AAC lánc NEM Gray
% leképezését használja:
%   x     = 8cI + 4fI + 2cQ + fQ
%   pont  = ((2*s(cI)+s(fI)) + 1i*(2*s(cQ)+s(fQ)))/sqrt(10)
%
% Viselkedésében azonos az AM4_16-beli buildSymOrder(16)-tal; azért van itt
% megduplázva, hogy ez a fájl önállóan is futtatható maradjon. A vektort nem
% égetjük be, hanem megkeressük és ellenőrizzük -- így egy esetleges
% MATLAB-verziófüggő symOrder-szemantika hangosan elhasal, nem csendben ad
% rossz eredményt.

    s = @(b) 1 - 2*b;
    labels = (0:15)';

    cI = bitget(labels, 4);  fI = bitget(labels, 3);
    cQ = bitget(labels, 2);  fQ = bitget(labels, 1);
    wanted = ((2*s(cI) + s(fI)) + 1i*(2*s(cQ) + s(fQ))) / sqrt(10);

    % Referencia: identitás-permutációval a qammod a saját rácssorrendjét adja.
    C0 = qammod(labels, 16, 0:15, 'UnitAveragePower', true);

    % Minden saját címkéhez megkeressük, melyik rácspozícióra esik.
    pos = zeros(16,1);
    for x = 0:15
        [d, p] = min(abs(C0 - wanted(x+1)));
        if d > 1e-9
            error('Sync_LDPC_16:buildSymOrder16', ...
                'A kívánt konstellációs pont nem szerepel a qammod rácsán.');
        end
        pos(x+1) = p;
    end
    if numel(unique(pos)) ~= 16
        error('Sync_LDPC_16:buildSymOrder16','A hozzárendelés nem bijektív.');
    end

    % 1. jelölt: symOrder(pozíció) = címke  (dokumentált szemantika)
    symOrd = zeros(1, 16);
    symOrd(pos(:)') = 0:15;

    if maxdev(symOrd, wanted) > 1e-9
        % 2. jelölt: az inverz permutáció, ha a szemantika fordított lenne
        symOrd = (pos - 1)';
        if maxdev(symOrd, wanted) > 1e-9
            error('Sync_LDPC_16:buildSymOrder16', ...
                ['Nem sikerült olyan symOrder-t találni, amellyel a qammod a kívánt ' ...
                 '(nem Gray) leképezést adja. Ellenőrizd a Communications Toolbox verzióját.']);
        end
    end
end

function d = maxdev(symOrd, wanted)
% A jelölt symOrder-rel előálló konstelláció eltérése a kívánttól.
    chk = qammod((0:15)', 16, symOrd, 'UnitAveragePower', true);
    d = max(abs(chk - wanted));
end