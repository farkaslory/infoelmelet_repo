clear
LdpcErr_2=[]
parpool(15) %Hány példányban fusson párhuzamosan: magok száma -1 az ajénlott
for snr=1:0.1:10
    error=zeros(1,1000);
    parfor k=1:1000
        error(k)=myfun(k,snr);
    end
    LdpcErr_2(end+1)=mean(error);
    snr
end
semilogy(1:0.1:10,LdpcErr_2)
LdpcErr_2
function output=Code(InfBits,Params)
    output = ldpcEncode(InfBits,Params);
end
function EstimatedInfBits=Decode(LogLikelihoodRation,Params)
    maxnumiter = 10;
    EstimatedInfBits = ldpcDecode(LogLikelihoodRation,Params,maxnumiter);
end
function output=myfun(k,snr)
H = dvbs2ldpc(1/2);
cfgLDPCEnc = ldpcEncoderConfig(H);
numframes = 1;
cfgLDPCDec = ldpcDecoderConfig(H);
n = cfgLDPCEnc.NumInformationBits;
BlockLengthHalf = cfgLDPCDec.BlockLength/2;
K = 20; % Number of codewords to process
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
        LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(20-1)+1:BlockLengthHalf*(20+1)),2,0,OutputType="llr"),[BlockLengthHalf 2]);
        LlrActual=LLR{K}';
        decodedData{K} = Decode(LlrActual(:),cfgLDPCDec);
        for j=1:K
            ErrCount(j)=biterr(data{j},decodedData{j});
        end
        output=sum(ErrCount)/(K*n);
end
