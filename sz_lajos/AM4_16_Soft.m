function [TurboErr, n, BlockLengthHalf, place] = AM4_16_Soft(H, maxFrames, K, snrRange, calcPlace)
% AM4_16_Soft  
%
% Az ADO es a cimkezes pontosan az AM4_16-e (sajat, hierarchikus 16-QAM):
%   blokk 1      : 4-QAM,  1. kodszo elso fele
%   blokk j+1    : 16-QAM, DURVA = (j+1). kodszo eleje, FINOM = j. kodszo vege
%   blokk K+1    : 4-QAM,  K. kodszo masodik fele
%   level = 2*s(c) + s(f)   tengelyenkent,  pont = (levelI + 1i*levelQ)/sqrt(10)
%
% A VEVO ket ponton ter el az AM4_16-tol:
%   1) A j. kodszo ELSO felenek LLR-je (j > 1) nem kivonas + 4-QAM demod, hanem
%      A PRIORI DEMAPPING az erintetlen j. blokkon: az ugyanabban a szimbolumban
%      ulo f bitek valoszinuseget az elozo kodszo dekoderenek extrinsic LLR-je adja:
%        P0 = 1/(1+exp(-Le)),  P1 = 1/(1+exp(Le))
%        L(c) = ln[ P0*p(y|0,0) + P1*p(y|0,1) ] - ln[ P0*p(y|1,0) + P1*p(y|1,1) ]
%      Biztos f-nel ez a kemeny tisztitas (d = 4), bizonytalannal visszaesik
%      a tisztitas nelkuli LLR-re -> nincs magabiztosan rossz LLR, nincs
%      hibaterjedes.
%   2) A kodszavak kozott kemeny f helyett EXTRINSIC LLR megy at:
%        Lpost = ldpcDecode(..., 'DecisionType','soft', 'OutputFormat','whole')
%        Le    = Lpost(f poziciok) - Lin(f poziciok)
%      A csatorna-LLR-t levonjuk, mert a kovetkezo korben a demapper ugyanazt
%      az y-t ujra latja (kulonben ketszer szamolnank).
% Kikerul: ujrakodolas a vevoben, az output feluliras, CLEAN_GAIN, CLEAN_NVFAC.
%
% Be- es kimenetek: azonosak az AM4_16-tal.
%   H, maxFrames (1000), K (20), snrRange (1:0.5:5), calcPlace (0)
%   TurboErr, n, BlockLengthHalf, place
%
% Drop-in csere, pl.:
%   [TurboErr,n,BlockLengthHalf,place] = AM4_16_Soft(H_sparse, maxFrames, K, snrRange, 1);

%% --- Alapertelmezett parameterek ----------------------------------------
if nargin < 5 || isempty(calcPlace), calcPlace = 0;        end
if nargin < 4 || isempty(snrRange),  snrRange  = 1:0.5:5;  end
if nargin < 3 || isempty(K),         K         = 20;       end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000;     end

maxIter = 10;   % belief propagation iteracioszam (mint az AM4_16-ban)
LE_CLIP = 30;   % extrinsic LLR vagasa (numerikus biztonsag)

%% --- Kodolo / dekodolo konfiguracio -------------------------------------
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n               = cfgLDPCEnc.NumInformationBits;
BlockLength     = cfgLDPCDec.BlockLength;
BlockLengthHalf = BlockLength / 2;     % fel kodszo BITben (AM2_4-kompatibilis)
nSym            = BlockLengthHalf / 2; % SZIMBOLUM blokkonkent

if mod(BlockLength,4) ~= 0
    error('AM4_16_Soft:blockLength', ...
        'A kodszohossz (%d) nem oszthato 4-gyel.', BlockLength);
end
if K < 1
    error('AM4_16_Soft:K','K legalabb 1 kell legyen.');
end

% A soft dekoder-kimenet konvenciojanak ellenorzese (pozitiv LLR = 0 bit,
% az infobitek a kodszo elso n poziciojan). Ha nem igy van, hangosan elhasal.
checkSoftDecoder(cfgLDPCEnc, cfgLDPCDec, n);

%% --- Konstellaciok: sajat (NEM Gray) cimkezes, mint az AM4_16-ban -------
symOrd4  = buildSymOrder(4);
symOrd16 = buildSymOrder(16);

%% --- Elofoglalas --------------------------------------------------------
TurboErr = zeros(1, numel(snrRange));
if calcPlace
    place = zeros(1, K);
else
    place = [];
end

data        = cell(1, K);
half1IQ     = cell(1, K);
half2IQ     = cell(1, K);
decodedData = cell(1, K);

%% --- Fo ciklus ----------------------------------------------------------
for snr_idx = 1:numel(snrRange)
    snr = snrRange(snr_idx);
    N0  = 10^(-snr/10);          % teljes komplex zajvariancia (mint az AM4_16-ban)

    error_count = zeros(1, maxFrames);

    for k_idx = 1:maxFrames
        %% ---- Adatgeneralas + LDPC kodolas + I/Q csoportositas ----------
        for j = 1:K
            data{j} = randi([0 1], n, 1, 'int8');
            cw      = double(ldpcEncode(data{j}, cfgLDPCEnc));
            cD      = reshape(cw, [2 BlockLengthHalf])';         % oszlop1 = paratlan, oszlop2 = paros
            half1IQ{j} = reshape(cD(:,1), [2 nSym])';            % nSym x 2 (oszlop1 = I bit, oszlop2 = Q bit)
            half2IQ{j} = reshape(cD(:,2), [2 nSym])';
        end

        %% ---- ADO: 4-QAM | 16-QAM x (K-1) | 4-QAM (valtozatlan) ---------
        input = zeros((K+1)*nSym, 1);
        input(1:nSym) = qammod(idx4(half1IQ{1}), 4, symOrd4, 'UnitAveragePower', true);
        for j = 1:K-1
            input(nSym*j+1 : nSym*(j+1)) = ...
                qammod(idx16(half1IQ{j+1}, half2IQ{j}), 16, symOrd16, 'UnitAveragePower', true);
        end
        input(nSym*K+1 : nSym*(K+1)) = qammod(idx4(half2IQ{K}), 4, symOrd4, 'UnitAveragePower', true);

        %% ---- CSATORNA -------------------------------------------------
        output = awgn(input, snr, 'measured');

        %% ---- VEVO: szukcessziv lanc-dekodolas, soft tisztitassal --------
        ErrCount = zeros(1, K);
        LeIQ     = [];               % az elozo kodszo FINOM bitjeinek extrinsic LLR-je (nSym x 2)

        for j = 1:K-1
            % 1. LEPES -- elso fel (a j. kodszo durva bitjei) a j. blokkbol.
            %   j = 1 : onallo 4-QAM, sima qamdemod.
            %   j > 1 : a priori demapping az ERINTETLEN j. blokkon, az f bitek
            %           valoszinuseget az elozo kor LeIQ-ja adja.
            yA = output(nSym*(j-1)+1 : nSym*j);
            if j == 1
                llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                                'OutputType', 'llr', 'NoiseVariance', N0);   % [I;Q] szimbolumonkent
            else
                llrA = coarseLlrPrior(yA, LeIQ, N0);
            end

            % 2. LEPES -- masodik fel (a j. kodszo finom bitjei) a (j+1). blokkbol,
            % a durva bitekre marginalizalva (valtozatlan). Ez L_be(f).
            yB   = output(nSym*j+1 : nSym*(j+1));
            llrB = qamdemod(yB, 16, symOrd16, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
            llrB = reshape(llrB, 4, nSym);              % sorok: cI, fI, cQ, fQ
            llrFine = reshape(llrB([2 4], :), [], 1);   % [fI; fQ] szimbolumonkent

            % 3. LEPES -- osszefesules (paratlan: elso fel, paros: masodik fel)
            Lin = reshape([llrA, llrFine]', [], 1);

            % 4. LEPES -- soft LDPC dekodolas: a posteriori LLR a teljes kodszora
            Lpost = ldpcDecode(Lin, cfgLDPCDec, maxIter, ...
                               'DecisionType', 'soft', 'OutputFormat', 'whole');

            % 5. LEPES -- adatbitek (negativ LLR = 1-es bit)
            decodedData{j} = int8(Lpost(1:n) < 0);

            % 6. LEPES -- extrinsic a finom bitekre (paros poziciok), a kovetkezo
            % kor a priori informacioja. Nincs ujrakodolas, nincs kivonas a jelbol.
            Le   = Lpost(2:2:end) - Lin(2:2:end);
            LeIQ = max(min(reshape(Le, [2 nSym])', LE_CLIP), -LE_CLIP);
        end

        % Utolso kodszo: elso fele a K. blokkbol (a priori demapping, ha K > 1),
        % masodik fele a K+1. blokk onallo 4-QAM-jabol.
        yA = output(nSym*(K-1)+1 : nSym*K);
        yB = output(nSym*K+1     : nSym*(K+1));
        if K == 1
            llrA = qamdemod(yA, 4, symOrd4, 'UnitAveragePower', true, ...
                            'OutputType', 'llr', 'NoiseVariance', N0);
        else
            llrA = coarseLlrPrior(yA, LeIQ, N0);
        end
        llrB = qamdemod(yB, 4, symOrd4, 'UnitAveragePower', true, ...
                        'OutputType', 'llr', 'NoiseVariance', N0);
        Lin   = reshape([llrA, llrB]', [], 1);
        Lpost = ldpcDecode(Lin, cfgLDPCDec, maxIter, ...
                           'DecisionType', 'soft', 'OutputFormat', 'whole');
        decodedData{K} = int8(Lpost(1:n) < 0);

        %% ---- Hibaszamitas ---------------------------------------------
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

end % ===================== AM4_16_Soft vege ==============================


%% ########################################################################
%  SEGEDFUGGVENYEK
%% ########################################################################

function llr = coarseLlrPrior(y, LeIQ, N0)
% Durva bitek LLR-je egy sajat cimkezesu 16-QAM blokkbol, a priori f-informacioval.
%   y    : nSym x 1 komplex vett jel (UnitAveragePower skalan, ERINTETLEN blokk)
%   LeIQ : nSym x 2 extrinsic LLR a finom bitekre [fI fQ] (pozitiv = 0 bit)
%   N0   : teljes komplex zajvariancia, tengelyenkent sigma^2 = N0/2
% Kimenet: [cI; cQ] szimbolumonkent, oszlopvektorban -- ugyanabban a sorrendben,
% ahogy a 4-QAM qamdemod adja. Elojel: pozitiv LLR = 0 bit.
    x  = [3 1; -1 -3] / sqrt(10);              % x(c+1, f+1) = (2*s(c) + s(f))/sqrt(10)
    LI = axisLlr(real(y), LeIQ(:,1), x, N0);
    LQ = axisLlr(imag(y), LeIQ(:,2), x, N0);
    llr = reshape([LI, LQ].', [], 1);
end

function L = axisLlr(y, Le, x, N0)
% Egy tengely: L(c) = lse(d00+lnP0, d01+lnP1) - lse(d10+lnP0, d11+lnP1)
    lp0 = -softplus(-Le);                       % ln P(f=0) = -ln(1+exp(-Le))
    lp1 = -softplus( Le);                       % ln P(f=1) = -ln(1+exp(+Le))
    d   = @(c,f) -(y - x(c+1,f+1)).^2 / N0;     % -(y-x)^2/(2*sigma^2), 2*sigma^2 = N0
    L   = lse(d(0,0)+lp0, d(0,1)+lp1) - lse(d(1,0)+lp0, d(1,1)+lp1);
end

function z = softplus(a)
% ln(1 + exp(a)), numerikusan stabilan
    z = max(a, 0) + log1p(exp(-abs(a)));
end

function z = lse(a, b)
% ln(exp(a) + exp(b)), numerikusan stabilan
    z = max(a, b) + log1p(exp(-abs(a - b)));
end

function checkSoftDecoder(cfgEnc, cfgDec, n)
% Zajmentes probakodszon ellenorzi, hogy az ldpcDecode soft kimenete
% (1) pozitiv LLR = 0 bit konvencioju, es (2) az infobitek az elso n poziciot
% foglaljak el. Mindket feltevesre epul a fenti vevo.
    u  = randi([0 1], n, 1, 'int8');
    cw = double(ldpcEncode(u, cfgEnc));
    Lp = ldpcDecode(10 * (1 - 2*cw), cfgDec, 5, ...
                    'DecisionType', 'soft', 'OutputFormat', 'whole');
    if any(double(Lp < 0) ~= cw) || any(int8(Lp(1:n) < 0) ~= u)
        error('AM4_16_Soft:softDecoder', ...
            ['Az ldpcDecode soft kimenete nem a vart konvencioju (elojel vagy ' ...
             'infobit-pozicio). Ellenorizd a Communications Toolbox verziojat.']);
    end
end

function x = idx4(bitsIQ)
% Onallo 4-QAM szimbolumindex: x = 2*bI + bQ
    x = 2*bitsIQ(:,1) + bitsIQ(:,2);
end

function x = idx16(coarseIQ, fineIQ)
% Kombinalt 16-QAM szimbolumindex: x = 8*cI + 4*fI + 2*cQ + fQ
    x = 8*coarseIQ(:,1) + 4*fineIQ(:,1) + 2*coarseIQ(:,2) + fineIQ(:,2);
end

function symOrd = buildSymOrder(M)
% Azonos az AM4_16 buildSymOrder-evel (sajat, nem Gray cimkezes, ellenorizve).
%   M = 4  : x = 2*bI + bQ            -> (s(bI) + 1i*s(bQ))/sqrt(2)
%   M = 16 : x = 8cI + 4fI + 2cQ + fQ -> ((2s(cI)+s(fI)) + 1i*(2s(cQ)+s(fQ)))/sqrt(10)
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
            error('AM4_16_Soft:buildSymOrder','Csak M = 4 es M = 16 tamogatott.');
    end

    C0 = qammod(labels, M, 0:M-1, 'UnitAveragePower', true);

    pos = zeros(M,1);
    for x = 0:M-1
        [d, p] = min(abs(C0 - wanted(x+1)));
        if d > 1e-9
            error('AM4_16_Soft:buildSymOrder', ...
                'A kivant konstellacios pont nem szerepel a qammod raccsan (M=%d).', M);
        end
        pos(x+1) = p;
    end
    if numel(unique(pos)) ~= M
        error('AM4_16_Soft:buildSymOrder','A hozzarendeles nem bijektiv (M=%d).', M);
    end

    symOrd = zeros(1, M);
    symOrd(pos(:)') = 0:M-1;

    if maxdev(symOrd, M, wanted) > 1e-9
        symOrd = (pos - 1)';
        if maxdev(symOrd, M, wanted) > 1e-9
            error('AM4_16_Soft:buildSymOrder', ...
                'Nem sikerult megfelelo symOrder-t talalni (M=%d).', M);
        end
    end
end

function d = maxdev(symOrd, M, wanted)
    chk = qammod((0:M-1)', M, symOrd, 'UnitAveragePower', true);
    d = max(abs(chk - wanted));
end