% dc1 = dual network fusion, configuration 1 (alexnet + vgg16)

for(k=1:1)

clear

imds = imageDatastore('./Fusion Images/GT',...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

imds2 = imageDatastore('./Fusion Images/NF',...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

imds = shuffle(imds);
imds2 = shuffle(imds2);
tbl = countEachLabel(imds);
tbl2 = countEachLabel(imds2);

% numImgs = 40;
imdsTrimmed = imds;
imdsTrimmed2 = imdsTrimmed;


imdsTrimmed3 = imds2;
imdsTrimmed4 = imdsTrimmed3;

% Alexnet and vgg16/19 use different sized input images.
% Use splitEachLabel method to trim two sets, for Alexnet and VGG based nets.
imdsTrimmed.ReadFcn = @(filename)readAndPreprocessImageA(filename);

[s1, x] = size(imdsTrimmed.Files);
[imdsTrainA] = splitEachLabel(imdsTrimmed,tbl.Count(1),'randomized');


imdsTrimmed2.ReadFcn = @(filename)readAndPreprocessImageV(filename);
[s2, x] = size(imdsTrimmed2.Files);

[imdsTrainV] = splitEachLabel(imdsTrimmed2,tbl.Count(1),'randomized');


imdsTrimmed3.ReadFcn = @(filename)readAndPreprocessImageA(filename);
[s3, x] = size(imdsTrimmed3.Files);
[imdsTestA] = splitEachLabel(imdsTrimmed3,tbl2.Count(1),'randomized');


imdsTrimmed4.ReadFcn = @(filename)readAndPreprocessImageV(filename);
[s4, x] = size(imdsTrimmed4.Files);
[imdsTestV] = splitEachLabel(imdsTrimmed4,tbl2.Count(1),'randomized');


% select three pretrained networks
net1 = alexnet;
net2 = vgg16;
net3 = vgg19;


tic;
disp("Extracting Features");

% set layer to fc7
layer = 'fc7';

% extract training features from 3 pretrained networks
featuresTrainA = activations(net1,imdsTrainA,layer,...
    'MiniBatchSize', 1,'OutputAs','rows',...
    'ExecutionEnvironment','gpu');

featuresTrainB = activations(net2,imdsTrainV,layer,...
    'MiniBatchSize', 1,'OutputAs','rows',...
    'ExecutionEnvironment','gpu');

featuresTrainC = activations(net3,imdsTrainV,layer,...
    'MiniBatchSize', 1,'OutputAs','rows',...
    'ExecutionEnvironment','gpu');

featuresFused = (featuresTrainA +featuresTrainB + featuresTrainC)  ;
[TrainM, TrainN] = size(featuresTrainA);

for(i = 1:numel(featuresTrainA))
    featuresMax(i) = max(featuresTrainA(i), featuresTrainB(i));
    featuresMax(i) = max(featuresMax(i), featuresTrainC(i));
end

featuresMax = reshape(featuresMax, [TrainM, TrainN]);


for(i = 1:numel(featuresTrainA))
    featuresMin(i) = min(featuresTrainA(i), featuresTrainB(i));
    featuresMin(i) = min(featuresMin(i), featuresTrainC(i));
end


featuresMin = reshape(featuresMin, [TrainM, TrainN]);

for(i = 1:numel(featuresTrainA))
    featuresAvg(i) = (featuresTrainA(i) + featuresTrainB(i) + featuresTrainC(i) ) / 3;
end
featuresAvg = reshape(featuresAvg, [TrainM, TrainN]);

featuresTestA = activations(net1,imdsTestA,layer,...
    'MiniBatchSize', 1,'OutputAs','rows',...
    'ExecutionEnvironment','gpu');

test.ReadFcn = @(filename)readAndPreprocessImageV(filename);

featuresTestV1 = activations(net2,imdsTestV,layer,...
    'MiniBatchSize', 1,'OutputAs','rows',...
    'ExecutionEnvironment','gpu');

featuresTestV2 = activations(net3,imdsTestV,layer,...
    'MiniBatchSize', 1,'OutputAs','rows',...
    'ExecutionEnvironment','gpu');

featuresTestFused = featuresTestA + featuresTestV1 + featuresTestV2;

[TestM, TestN] = size(featuresTestA);

for(i = 1:numel(featuresTestA))
    featuresTestMax(i) = max(featuresTestA(i), featuresTestV1(i));
    featuresTestMax(i) = max(featuresTestMax(i), featuresTestV2(i));
end

featuresTestMax = reshape(featuresTestMax, [TestM, TestN]);

for(i = 1:numel(featuresTestA))
    featuresTestMin(i) = min(featuresTestA(i), featuresTestV1(i));
    featuresTestMin(i) = min(featuresTestMin(i), featuresTestV2(i));
end

featuresTestMin = reshape(featuresTestMin,[TestM, TestN]);

for(i = 1:numel(featuresTestA))
    featuresTestAvg(i) = (featuresTestA(i) + featuresTestV1(i) + featuresTestV2(i) ) / 3;
end

featuresTestAvg = reshape(featuresTestAvg,[TestM, TestN]);


YTrain = imdsTrainA.Labels;
YTest = imdsTestA.Labels;

disp("Training SVM from Features");


classifier = fitcecoc(featuresFused,YTrain,'Learners', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'rows');

classifierMax = fitcecoc(featuresMax,YTrain,'Learners', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'rows');
classifierMin = fitcecoc(featuresMin,YTrain,'Learners', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'rows');
classifierAvg = fitcecoc(featuresAvg,YTrain,'Learners', 'Linear', 'Coding', 'onevsall', 'ObservationsIn', 'rows');

disp("Predictions:GAN&VAE");
disp("Alexnet Features:");

YPred = predict(classifier,featuresTestA);

accuracy1 = mean(YPred == YTest)

disp("VGG16 Features:");

YPred = predict(classifier,featuresTestV1);

accuracy2 = mean(YPred == YTest)

disp("VGG19 Features:");
YPred = predict(classifier,featuresTestV2);
accuracy3 = mean(YPred == YTest)

disp("Fused Features(Sum):");
YPred = predict(classifier,featuresTestFused);
accuracySum = mean(YPred == YTest)

disp("Fused Features(Max):");
YPred = predict(classifierMax,featuresTestMax);
accuracyMax = mean(YPred == YTest)

disp("Fused Features(Min):");
YPred = predict(classifierMin,featuresTestMin);
accuracyMin = mean(YPred == YTest)

disp("Fused Features(Avg):");
YPred = predict(classifierAvg,featuresTestAvg);
accuracyAvg = mean(YPred == YTest)


%accuracy = [accuracy1, accuracy2, accuracy3];
%dlmwrite('Results.csv',accuracy,'delimiter',',','-append');
%fusionAccuracy = [accuracySum, accuracyMax, accuracyMin, accuracyAvg];

t = toc;

 A = [accuracy1, accuracy2, accuracy3, accuracySum, accuracyMax, accuracyMin, accuracyAvg, t];

dlmwrite('Results.csv',A,'delimiter',',','-append');
end

function Iout = readAndPreprocessImageA(filename)

        I = imread(filename);

        % Some images may be grayscale. Replicate the image 3 times to
        % create an RGB image.
        if ismatrix(I)
            I = cat(3,I,I,I);
        end

        % Resize the image as required for Alexnet.
        Iout = imresize(I, [227 227]);

        % Note that the aspect ratio is not preserved. In Caltech 101, the
        % object of interest is centered in the image and occupies a
        % majority of the image scene. Therefore, preserving the aspect
        % ratio is not critical. However, for other data sets, it may prove
        % beneficial to preserve the aspect ratio of the original image
        % when resizing.
end

function Iout = readAndPreprocessImageV(filename)

        I = imread(filename);

        % Some images may be grayscale. Replicate the image 3 times to
        % create an RGB image.
        if ismatrix(I)
            I = cat(3,I,I,I);
        end

        % Resize the image as required for VGG.
        Iout = imresize(I, [224 224]);

        % Note that the aspect ratio is not preserved. In Caltech 101, the
        % object of interest is centered in the image and occupies a
        % majority of the image scene. Therefore, preserving the aspect
        % ratio is not critical. However, for other data sets, it may prove
        % beneficial to preserve the aspect ratio of the original image
        % when resizing.
end