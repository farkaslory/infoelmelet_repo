clear
trellis = poly2trellis(7,[115 147],147);
numframes = 1;
K = 20;
n = 700;
BlockLengthHalf = n;
Err_2=[]
place=zeros(1,20);
for snr=1:0.1:10
    error=zeros(1,1000);
    for k=1:100
        for j=1:K
            data{j} = randi([0 1],n,numframes,'int8');
        end
        for j=1:K
            codedData{j} = Code(data{j},trellis);
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
            decodedData{j} = Decode(LlrActual(:),trellis);
            EstimatedCodeword = Code(decodedData{j},trellis);
            EstimatedCodeword = reshape(EstimatedCodeword,[2 BlockLengthHalf])';
            SecondPartECWinFourier = pskmod(EstimatedCodeword(:,2),2,pi/2);
            output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1))=output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1))-1/sqrt(2)*SecondPartECWinFourier;    
        end
        LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(20-1)+1:BlockLengthHalf*(20+1)),2,0,OutputType="llr"),[BlockLengthHalf 2]);
        LlrActual=LLR{K}';
        decodedData{K} = Decode(LlrActual(:),trellis);
        for j=1:K
            ErrCount(j)=biterr(data{j},decodedData{j});
        end
        error(k)=sum(ErrCount)/K;
        if ErrCount ~= 0
            [m,j]=max(ErrCount);
            place(j)=place(j)+1;
        end
    end
    Err_2(end+1)=mean(error)/n;
    snr
end
plot(snr,Err_2)
bar(place)

function output=Code(InfBits,Params)
    output = convenc(InfBits,Params);
end
function EstimatedInfBits=Decode(LogLikelihoodRation,Params)
    tbdepth = 60; % Traceback depth for Viterbi decoder
    EstimatedInfBits = vitdec(LogLikelihoodRation,Params,tbdepth,'trunc','unquant');
end