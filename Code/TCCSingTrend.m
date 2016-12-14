%Estimativa de tendencia de vocal
function [confSpec] = TCCSingTrend(spectrogram, nshsSpec, HTSpec, params, outPath, filename)
	[trSize, frSize, trHopSize, frHopSize, smoothness, plotHR, plotTF, plotVoc, plotIns] = ... 
		textread("ConfigSingTrend.txt", "trSize = %f\n frSize = %f\n trHopSize = %f\n frHopSize = %f\n smoothness = %f\n plotHR = %f\n plotTF = %f\n plotVoc = %f\n plotIns = %f", 9, "commentstyle", "shell");

	wsm = params(1) * 1000 / params(9);
	ts = floor(trSize / wsm);
	ths = floor(trHopSize / wsm);
	maxSemi = TCCHz2Semi(params(5));

	indT = [1 : ths : (size(spectrogram, 2) - ts)];
	%Como 1o bin pega entre 0~21.533 hZ...
	indF = 1:frHopSize:(maxSemi - frSize);
	fs = indF + frSize;		%ultimo semitom de cada regiao de freq.
	indF = TCCSemi2Hz(indF);
	fs = TCCSemi2Hz(fs);
	indF = floor(indF * size(spectrogram, 1) / params(9));
	fs = floor(fs * size(spectrogram, 1) / params(9));
	fs = fs - indF;		%Binsize de cada regiao de freq.
	fhs = [0, indF(1, 2:size(indF, 2)) - indF(1, 1:(size(indF, 2) - 1))];

	if(indF(1) == 0) indF(1) = 1; endif

	%Remocao parcial de instrumental
	binMax = floor(params(5) / params(9) * params(6));
	binMin = floor(params(4) / params(9) * params(6)) + 1;
	insRem(binMin:binMax, :) = spectrogram(binMin:binMax, :) .* (HTSpec(binMin:binMax, :) > 0);
	hRem = sumHar = zeros(binMax, size(spectrogram, 2));

	%Remover harmônicas (quantas?)
	for f = binMin:binMax
		Nf = floor(size(HTSpec, 1)*.5 / f);
		sumHar(f, :) = sum(spectrogram((indF(1):Nf) * f, :) .* (insRem(f, :) > 0), 1);
		% sumHar(f, :) = sum(HTSpec((indF(1):Nf) * f, :), 1);
	endfor

	[maxf, maxi] = max(sumHar(:, (1:size(HTSpec, 2))));
	for l = 1:(size(HTSpec, 2));
		hRem(maxi(l), l) = maxf(l);
	endfor

	%Energia em cada regiao T-F
	tfRegions = zeros(size(indF, 2), size(indT, 2));
	for t = 0:(ts - 1)
		for fb = 1:size(indF, 2)
			f = [0:(fs(fb)-1)];
			if(isempty(f)) f = 0; endif
			f = f';

			if(indF(fb) <= binMax - max(f))
				tfRegions(fb, :) += max(hRem(f + indF(fb) + 1, t + (0:(size(indT, 2)-1)) * ths + 1), [], 1);
			endif
		endfor
	endfor

	%path(DP)
	disp("path");
	scores = zeros(size(tfRegions));
	paths = zeros(size(tfRegions));
	scores(:, 1) = tfRegions(:, 1);
	scores(:, 2:size(scores, 2)) = -inf;
	paths(:, 1) = 0;

	k = 1:size(scores, 1);
	for t = 2:size(scores, 2)
		if(mod(t, 500) == 0) printf("%d/%d\n", t, size(spectrogram, 2)); endif
		for f = 1:size(scores, 1)
			[ks, ki] = max(scores(k, t-1) - smoothness .* abs(k - f)', [], 1);

			scores(f, t) = ks;
			paths(f, t) = ki;
			scores(f, t) += tfRegions(f, t);
		endfor
	endfor

	[optSc, optInd] = max(scores(:, size(tfRegions, 2)));

	%confine
	confSpec = zeros(size(spectrogram));
	for t = size(tfRegions, 2):-1:1
		rf = [indF(optInd) : (indF(optInd) + fs(optInd))];
		rt = [((t-1) * ths + 1) : ((t-1) * ths + ts + 1)];
		confSpec(rf, rt) = spectrogram(rf, rt) .* (nshsSpec(rf, rt) > 0);
		optInd = paths(optInd, t);
	endfor

	%plots
	stOutPath = char(cstrcat("SingTrend(", num2str(trSize), " ", num2str(frSize), " ", num2str(trHopSize), " ", num2str(frHopSize), " ", num2str(smoothness), ")"));

	if(exist(strcat(char(outPath, stOutPath)), "dir") != 7)
		mkdir(outPath, stOutPath);
	endif
	outPath = char(strcat(outPath, stOutPath, "/"));

	if(plotHR == true && nargin() == 6)
		%Remocao de harmonicas
		hrPlot = abs(hRem(binMin:binMax, :));
		if(params(7) == 0)
			hrPlot = hrPlot(1:round(size(hrPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-hRem.png"));
		TCCPlotSpec(hrPlot, params, saveName, 1);

		sig = TCCIstft(hRem, params, params(9));
		audiowrite(strcat(outPath, filename, "-hRem.wav"), sig, params(9));
	endif

	if(plotTF == true && nargin() == 6)
		%Regioes T-F
		%!!!!!!
		figure(1);
		set(1, "paperunits", "points");
		set(1, "paperposition", [0, 0, round(params(8) / params(9) * 50), round((params(5) - params(4)) / 10)]);
		colormap(flipud(gray()));

		imagesc([1:columns(tfRegions)], [1:rows(tfRegions)], abs(tfRegions));

		set(gca (), "ydir", "normal");
		xlabel("Time Region");
		ylabel("Frequency Region");

		saveas(1, char(strcat(outPath, filename, "-TFRegions.png")));

		close(1);
	endif

	if(plotVoc == true && nargin() == 6)
		%confSpec
		confSpecPlot = abs(confSpec(binMin:binMax, :));
		if(params(7) == 0)
			confSpecPlot = confSpecPlot(1:round(size(confSpecPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-ConfSpec.png"));
		TCCPlotSpec(confSpecPlot, params, saveName, 2);

		sig = TCCIstft(confSpec, params, params(9));
		audiowrite(strcat(outPath, filename, "-Voice.wav"), sig, params(9));
	endif

	if(plotIns == true && nargin() == 6)
		insSpecPlot = abs(spectrogram(binMin:binMax, :) - confSpec(binMin:binMax, :));
		if(params(7) == 0)
			confSpecPlot = confSpecPlot(1:round(size(confSpecPlot, 1)/2), :);
		endif

		saveName = char(strcat(outPath, filename, "-Ins.png"));
		TCCPlotSpec(insSpecPlot, params, saveName, 2);

		ins = TCCIstft(spectrogram - confSpec, params, params(9));
		audiowrite(strcat(outPath, filename, "-Inst.wav"), ins, params(9));
	endif

	clear -x confSpec
endfunction

% function [] = MaxScore(f, t, smoothness)
% 	global scores;
% 	global paths;
% 	global tfRegions;

% 	%Split
% 	if(t > 1 && scores(f, t) == -inf)
% 		scores(f, t) = 0;
% 		for k = 1:size(scores, 1)
% 			MaxScore(k, t-1, smoothness);
% 			ks = scores(k, t-1) - smoothness * abs(k-f);
% 			if(ks > scores(f, t))
% 				scores(f, t) = ks;
% 				paths(f, t) = k;
% 			endif
% 		endfor
% 		scores(f, t) += tfRegions(f, t);
% 	endif
% endfunction