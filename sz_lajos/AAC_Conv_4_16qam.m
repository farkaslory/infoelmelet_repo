clear
%% =====================================================================
%  AAC szimuláció -- 4-QAM/16-QAM, konvolúciós kóddal, MODULÁRIS FELÉPÍTÉS
%
%  Ez az eredeti (BPSK/QPSK) AAC_Conv.m general­izálása 4-QAM/16-QAM-ra,
%  a szabadalom 3. ábrája ("A doboz" / "B doboz") alapján. A kód szándékosan
%  van szétszedve MODULOKRA (helyi függvényekre), hogy:
%    - könnyű legyen később más kódolásra (pl. LDPC) vagy más QAM-rendre
%      (pl. 64-QAM) általánosítani -- csak az adott modult kell cserélni,
%    - könnyű legyen debuggolni (minden modul önmagában is tesztelhető,
%      pl. egy adott bemenetre lefuttatva megnézhető a kimenete).
%
%  A LÁNC LOGIKÁJA :
%   1) Az 1. kódszó ELSŐ n bitje -> önálló 4-QAM (a lánc legelső blokkja).
%   2) A j. kódszó MARADÉK n bitje ("finom" rész) + a (j+1). kódszó ELSŐ
%      n bitje ("durva" rész) -> együtt egy 16-QAM blokk. A durva bit
%      MINDIG ugyanazt a negyedet választja ki, FÜGGETLENÜL attól, mi a
%      finom bit értéke -- ezt garantálja, hogy a durva bit hozzájárulása
%      (±2) mindig nagyobb, mint a finomé (±1) (lásd mod16QAM modul lent).
%   3) Az utolsó (K.) kódszó MARADÉK n bitje -> megint önálló 4-QAM.
%   4) VEVŐ: elsőként demoduláljuk az önálló 4-QAM blokkot (LLR), majd a
%      16-QAM blokkból kinyerjük a FINOM bit LLR-jét (a durva bitre
%      marginalizálva, mert azt még nem ismerjük) -> a kettőből összeáll
%      a j. kódszó teljes LLR-je -> dekódolunk -> a becslésünk hibajavító
%      kódolás miatt (remélhetőleg) helyes -> újrakódoljuk -> a finom rész
%      pontosan ismert hozzájárulását LEVONJUK a 16-QAM blokkból -> a
%      maradék immár egy tiszta 4-QAM jel, ami a KÖVETKEZŐ kódszó elejét
%      hordozza -> szukcesszíven folytatjuk.
%
%% =====================================================================

trellis = poly2trellis(7,[147 115],147);   %ugyanaz a konvolúciós kód, mint az eredeti szkriptben
numframes = 1;
K = 10;      %hány kódszó egy csomagban
n = 700;     %infobit/kódszó -- PÁROSNAK kell lennie (2 bit/tengely csoportosítás miatt)
assert(mod(n,2)==0,'n-nek párosnak kell lennie a 4-QAM/16-QAM csoportosításhoz!');

Err = [];            %BER görbe
place = zeros(1,K);  %debug: melyik kódszó-index hibázik legtöbbet

for snr = 7:0.1:10
    sigma2 = noiseVarianceFromSNR(snr);   %MODUL: zajvariancia az adott SNR-hez

    error = zeros(1,100);
    for k = 1:100
        %--- Adatgenerálás + kódolás ---
        [data,codedData] = generateAndEncode(K,n,numframes,trellis);

        %--- ADÓ MODUL ---
        txSymbols = transmitAAC(codedData,K,n);

        %--- CSATORNA ---
        %rxSymbols = txSymbols;   % TESZT: zaj kikapcsolva       
        rxSymbols = awgn(txSymbols,snr);

        %--- VEVŐ MODUL (szukcesszív dekódolás) ---
        decodedData = receiveAAC(rxSymbols,K,n,sigma2,trellis);

        %--- Hibaszámítás ---
        ErrCount = zeros(1,K);
        for j=1:K
            ErrCount(j) = biterr(data{j},decodedData{j});
        end
        error(k) = sum(ErrCount)/K;
        if any(ErrCount~=0)
            [~,idx] = max(ErrCount);
            place(idx) = place(idx)+1;
        end
    end
    Err(end+1) = mean(error)/n;
    fprintf('snr=%.2f   BER=%.4e\n',snr,Err(end));
end

figure
plot(7:0.1:10,Err)
xlabel('SNR [dB]'); ylabel('BER'); grid on
title('AAC 4-QAM/16-QAM BER görbe')

figure
bar(place)
xlabel('kódszó index a láncban'); ylabel('"legtöbb hiba" előfordulások száma')
title('Hibaeloszlás a láncban (debug)')


%% #######################################################################
%  MODULOK (helyi függvények -- MATLAB scriptben a fájl végén kell lenniük)
%% #######################################################################

%% --- MODUL: TELJESÍTMÉNY / ZAJ ---
function sigma2 = noiseVarianceFromSNR(snrDB)
    %awgn(x,snr) 0 dBW (=1 W) jelteljesítményt feltételez; mivel minden
    %szimbólumunk egységnyi átlag-teljesítményre van normálva, 
    % ebből számolható a valós/képzetes
    %tengelyenkénti zajvariancia.
    sigma2 = 1/(2*10^(snrDB/10));
end

%% --- MODUL: ADATGENERÁLÁS + KÜLSŐ (jelenleg konvolúciós) KÓDOLÁS ---
function [data,codedData] = generateAndEncode(K,n,numframes,trellis)
    for j=1:K
        data{j} = randi([0 1],n,numframes,'int8');
        codedData{j} = Code(data{j},trellis);
    end
end

%% --- MODUL: ADÓ ---
function txSymbols = transmitAAC(codedData,K,n)
    nSym = n/2;
    for j=1:K
        cD1 = reshape(codedData{j},[2 n])';
        half1IQ{j} = reshape(cD1(:,1),[2 nSym])';   %"1. fél" (páratlan kódolt bitek) I/Q-párokra bontva
        half2IQ{j} = reshape(cD1(:,2),[2 nSym])';   %"2. fél" (páros kódolt bitek) I/Q-párokra bontva
    end

    txSymbols = mod4QAM(half1IQ{1});                %1. blokk: önálló 4-QAM (1. kódszó eleje)
    for j=1:K-1
        %DURVA = (j+1). kódszó eleje, FINOM = j. kódszó vége
        %(lásd a szabadalom 3. ábrája: "B doboz" = durva, "A doboz" = finom)
        txSymbols = [txSymbols; mod16QAM(half1IQ{j+1}, half2IQ{j})];
    end
    txSymbols = [txSymbols; mod4QAM(half2IQ{K})];   %utolsó blokk: önálló 4-QAM (K. kódszó vége)
end

function sym = mod4QAM(bitsIQ)
    %Önálló, "ritkás" 4-QAM.  bitsIQ: nSym x 2 (oszlop1=I-bit, oszlop2=Q-bit)
    s = @(b) 1-2*b;
    sym = (s(bitsIQ(:,1)) + 1i*s(bitsIQ(:,2)))/sqrt(2);   %egységnyi átlagteljesítmény
end

function sym = mod16QAM(coarseIQ,fineIQ)
    %Kombinált 16-QAM: coarseIQ (a KÖVETKEZŐ kódszóból) választja ki, melyik
    %"negyedbe" (B doboz) essen a pont, fineIQ (az AKTUÁLIS kódszóból) a
    %pontos pozíciót a negyeden belül (A doboz).
    % coarseIQ/fineIQ: nSym x 2 (oszlop1=I-bit, oszlop2=Q-bit)
    s = @(b) 1-2*b;   %bit(0/1) -> +-1, ugyanaz a konvenció, mint a BPSK-nál (pskmod(...,2,0))
    levelI = 2*s(coarseIQ(:,1)) + s(fineIQ(:,1));   %{-3,-1,1,3}
    levelQ = 2*s(coarseIQ(:,2)) + s(fineIQ(:,2));

    sym = (levelI + 1i*levelQ)/sqrt(10);   %POWER KORREKCIÓ: egységnyi átlagteljesítményre normál
end

%% --- MODUL: VEVŐ (szukcesszív / lánc-dekódolás) ---
function decodedData = receiveAAC(output,K,n,sigma2,trellis)
    nSym = n/2;
    for j=1:K-1
        %POWER KORREKCIÓ: az 1. blokk sosem volt "tisztítva" (eredeti
        %zajvariancia érvényes rá), minden későbbi blokk viszont átesett a
        %cleanBlock() újraskálázásán, ami a ZAJT is (sqrt(5)/2)^2=5/4-
        %szeresére növeli -- enélkül a dekódolt LLR-ek rosszul lennének kalibrálva
    
        if j==1
            nv = sigma2;
        else
            nv = sigma2*5/4;
        end
        LLR1Half = demod4QAM_LLR(output(nSym*(j-1)+1:nSym*j), nv);

        yBlock = output(nSym*j+1:nSym*(j+1));   %MÉG kombinált, nem tisztított 16-QAM blokk
        [LLRfineI,LLRfineQ] = demod16QAM_fineLLR(real(yBlock),imag(yBlock),sigma2);

        Full1 = interleaveIQ(LLR1Half(:,1),LLR1Half(:,2),n);
        Full2 = interleaveIQ(LLRfineI,LLRfineQ,n);
        LlrActual = [Full1,Full2]';
        decodedData{j} = Decode(LlrActual(:),trellis);

        %Tisztítás (lásd cleanBlock modul): a most dekódolt kódszó FINOM
        %bitjeinek pontosan ismert hozzájárulását levonjuk, és visszaskálázzuk.

        EstimatedCodeword = Code(decodedData{j},trellis);
        EstCD1 = reshape(EstimatedCodeword,[2 n])';
        EstHalf2IQ = reshape(EstCD1(:,2),[2 nSym])';
        output(nSym*j+1:nSym*(j+1)) = cleanBlock(yBlock,EstHalf2IQ);
    end
    %Az utolsó (K.) kódszó: mindkét blokkja (K. és K+1.) mostanra tiszta 4-QAM 
    %(a K. blokk a fenti ciklusban lett megtisztítva, a K+1. sosem volt kombinálva).
    LLRlastFirst  = demod4QAM_LLR(output(nSym*(K-1)+1:nSym*K), sigma2*5/4);
    LLRlastSecond = demod4QAM_LLR(output(nSym*K+1:nSym*(K+1)), sigma2);
    Full1 = interleaveIQ(LLRlastFirst(:,1),LLRlastFirst(:,2),n);
    Full2 = interleaveIQ(LLRlastSecond(:,1),LLRlastSecond(:,2),n);
    LlrActual = [Full1,Full2]';
    decodedData{K} = Decode(LlrActual(:),trellis);
end

function LLR = demod4QAM_LLR(y,sigma2)
    %Egy önálló/tisztított 4-QAM blokk LLR-je -> nSym x 2 (oszlop1=I-bit, oszlop2=Q-bit LLR-je)
    LLR = [sqrt(2)*real(y)/sigma2, sqrt(2)*imag(y)/sigma2];
end

function [llrFineI,llrFineQ] = demod16QAM_fineLLR(yI,yQ,sigma2)
    %A FINOM bit LLR-je egy kombinált 16-QAM blokkból, a DURVA bitre
    %marginalizálva (log-sum-exp), mert az a vevő számára ekkor még ismeretlen.
    %Szint <-> (durva,finom) párosítás: 3<->(0,0), 1<->(0,1), -1<->(1,0), -3<->(1,1)
    levels = [-3 -1 1 3]/sqrt(10);
    llrFineI = logSumExpGauss(yI,[levels(4) levels(2)],sigma2) - logSumExpGauss(yI,[levels(3) levels(1)],sigma2);
    llrFineQ = logSumExpGauss(yQ,[levels(4) levels(2)],sigma2) - logSumExpGauss(yQ,[levels(3) levels(1)],sigma2);
end

function cleaned = cleanBlock(yBlock,knownFineIQ)
    %POWER KORREKCIÓ + TISZTÍTÁS: levonjuk a most megismert finom bitek
    %pontos hozzájárulását, majd sqrt(5)/2-vel visszaskálázzuk, hogy a
    %maradék jel amplitúdója megegyezzen egy önálló 4-QAM jelével.
    knownFine = ((1-2*knownFineIQ(:,1)) + 1i*(1-2*knownFineIQ(:,2)))/sqrt(10);
    residual = yBlock - knownFine;
    cleaned = residual* sqrt(5)/2;
end

function v = interleaveIQ(colI,colQ,n)
    %Az I/Q LLR-oszlopokat visszafésüli az eredeti páratlan/páros bitsorrendbe.
    v = zeros(n,1);
    v(1:2:end) = colI;
    v(2:2:end) = colQ;
end

function out = logSumExpGauss(y,muVals,sigma2)
    %log( sum_i exp( -(y-mu_i)^2 / (2*sigma2) ) ), numerikusan stabil módon
    d = -(y - muVals).^2/(2*sigma2);
    m = max(d,[],2);
    out = m + log(sum(exp(d-m),2));
end

%% --- MODUL: KÜLSŐ KÓD (jelenleg konvolúciós -- ide kerülne pl. az LDPC verzió is) ---
function output = Code(InfBits,Params)
    output = double(convenc(InfBits,Params));   %double(): hogy később 1i-vel kombinálható legyen (int8 * complex hibát dobna)
end
function EstimatedInfBits = Decode(LogLikelihoodRatio,Params)
    tbdepth = 60;   %Traceback depth a Viterbi-dekódernek
    EstimatedInfBits = vitdec(LogLikelihoodRatio,Params,tbdepth,'trunc','unquant');
end
