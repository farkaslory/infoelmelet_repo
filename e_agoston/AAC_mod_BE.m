clear;
inputFolderName = 'WiMax alist';% a file nevének a formátumának olyannak kell lennie, hogy:
%"*File neve* alist", ez azért kell hogy majd az output file lehessen ugyan ilyen néven, csupán az mat
outputFolderName = strrep(inputFolderName, 'alist', 'mat');
if ~exist(outputFolderName, 'dir')
    mkdir(outputFolderName);
end
fileList = dir(fullfile(inputFolderName, '*.alist.txt'));
folderSize = length(fileList);
for i = 1:folderSize
    % A file létrehozása:
    currentFileName = fileList(i).name;
    inputPath = fullfile(inputFolderName, currentFileName);
    [~,baseName,~] = fileparts(currentFileName);% itt leválasztjuk afile nevét, pl hogy wimax_0.75A
    baseName = strrep(baseName,'.alist','');
    outputPath = fullfile(outputFolderName, [char(baseName), '.mat']);

    %Ez az algo
    [H, N, M] = read_alist(inputPath); % jekk ehhez a read_alist() function
    cfgLDPCEnc = ldpcEncoderConfig(H);
    numframes = 1;
    cfgLDPCDec = ldpcDecoderConfig(H);
    n = N-M;
    BlockLengthHalf = N/2;
    K = 20; % Number of codewords to process
    LdpcErr_2=[];
    place=zeros(1,K);% Itt eredetileg az volt, hogy place zeros(1,20)
    % Pici módosításokat tettem a kódba.
    snr_range = 1:0.1:10;% Hogy ne legyen 2 órás a futás idő, ezt érdemes sok file esetén (2+) lejjebb venni.
    for snr=snr_range
        error=zeros(1,1000);
        for k=1:1000
            for j=1:K
                data{j} = randi([0 1],n,numframes,'int8');
            end
            for j=1:K
                codedData{j} = Code(data{j},cfgLDPCEnc);
                cD1{j}=reshape(codedData{j},[2 BlockLengthHalf])';
            end
            input=pskmod(cD1{1}(:,1),2,0);
            for j=1:K-1
                input1 = bi2de([cD1{j}(:,2),cD1{j+1}(:,1)],"left-msb");
                input = [input;pskmod(input1,4,pi/4)];
            end
            input = [input;pskmod(cD1{K}(:,2),2,0)];
            output = awgn(input,snr);
            for j=1:K-1
                LLR1Half{j} = pskdemod(output(BlockLengthHalf*(j-1)+1:BlockLengthHalf*j),2,0,OutputType="llr");
                LLR2Half = reshape(pskdemod(output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)),4,pi/4,OutputType="llr"),[2 BlockLengthHalf])';
                LLR{j} = [LLR1Half{j},LLR2Half(:,1)];
                LlrActual=LLR{j}';
                decodedData{j} = Decode(LlrActual(:),cfgLDPCDec);
                EstimatedCodeword = Code(decodedData{j},cfgLDPCEnc);
                EstimatedCodeword = reshape(EstimatedCodeword,[2 BlockLengthHalf])';
                SecondPartECWinFourier = pskmod(EstimatedCodeword(:,2),2,pi/2);
                output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1))=output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1))-1/sqrt(2)*SecondPartECWinFourier;    
            end
            LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(K-1)+1:BlockLengthHalf*(K+1)),2,0,OutputType="llr"),[BlockLengthHalf 2]);% Itt eredetileg a K-k helyett 20-asok voltak.
            LlrActual=LLR{K}';
            decodedData{K} = Decode(LlrActual(:),cfgLDPCDec);
            for j=1:K
                ErrCount(j)=biterr(data{j},decodedData{j});
            end
            error(k)=sum(ErrCount)/K;
            if any(ErrCount)% ErrCount ~= 0-ot kicseréltem erre, nemtudom hogy így jobb/rosszabb e, de nem dob hibát    
                [m,j]=max(ErrCount);
                place(j)=place(j)+1;
            end
        end
        LdpcErr_2(end+1)=mean(error)/n;
        snr
    end
    save(outputPath, 'BlockLengthHalf', 'n','K','LdpcErr_2');
    fprintf("Mentve %s.mat\n", baseName);
    subplot(2,1,1);%ezt ide raktam, hogy külön legyen a plot és a bar
    plot(snr_range,LdpcErr_2);

    subplot(2,1,2);
    bar(place);
    %hold on
    %de nem tudom, hogyan csináljam meghogy a bar-ok ne legyenek egymáson.
    
end
function output=Code(InfBits,Params)
output = ldpcEncode(InfBits,Params);
end
function EstimatedInfBits=Decode(LogLikelihoodRation,Params)
maxnumiter = 10;
EstimatedInfBits = ldpcDecode(LogLikelihoodRation,Params,maxnumiter);
end
