%esi
function [melSignal, outPath] = TCCEsiPE(spectrogram, fpk, params, outPath, filename, nSamples, preset)
	%Config
	if(preset == 0)
		[minSemi, maxSemi, plotESI, plotMel, plotBg, smoothness] = ...
			textread("ConfigEsi.txt", "minSemi = %f\n maxSemi = %f\n plotESI = %d\n plotMel = %d\n plotBg = %d\n smoothness = %f", 6, "commentstyle", "shell");
	else
		[minSemi, maxSemi, plotESI, plotMel, plotBg, smoothness] = ...
			textread(strcat("ConfigEsi", num2str(preset), ".txt"), "minSemi = %f\n maxSemi = %f\n plotESI = %d\n plotMel = %d\n plotBg = %d\n smoothness = %f", 6, "commentstyle", "shell");
	endif

	binMin = floor((params(4) / params(9) * params(6))) + 1;
	binMax = floor((params(5) / params(9) * params(6)));

	fSemi = [(minSemi-1) : (maxSemi+1)];
	% fSemi = [TCCHz2Semi(params(4)):TCCHz2Semi(params(5))];
	% disp(max(fSemi));
	% disp(min(fSemi));
	fSemi = TCCSemi2Hz(fSemi)';

	esi = zeros(size(fSemi, 1), size(spectrogram, 2));

	n = 2:(size(fSemi)-1);
	n = n';
	f = [fSemi(n) - ((fSemi(n) - fSemi(n-1)) / 2), fSemi(n) + ((fSemi(n+1) - fSemi(n)) / 2)];
	f = floor(f * size(spectrogram, 1) / params(9)) + 1;
	f = f .* (f <= (binMax - binMin));

	for t = 1:size(spectrogram, 2)
		for in = 1:size(f, 2)
			%abs?
			x(:, in) = abs(spectrogram(f(:, in) + binMin, t));
		endfor

		[y, iy] = max(x, [], 2);
		esi(n-1, t) = y;

		for k = 1:(size(iy))
			maxF(n, t) = floor(abs(fpk(f(:, iy(k)) + binMin, t)) * params(6) / params(9) + 1) .* (y != 0);
		endfor
	endfor

	%DP
	disp("dp");
	scores = paths = zeros(size(esi));
	scores(:, 1) = esi(:, 1);
	scores(:, 2:size(esi, 2)) = -inf;
	paths(:, 1) = 0;

	k = 1:size(scores, 1);
	for t = 2:size(scores, 2)
		for f = 1:size(scores, 1)
			[ks, ki] = max(scores(k, t-1) - smoothness .* abs(k - f)', [], 1);
			scores(f, t) = ks;
			paths(f, t) = ki;
			scores(f, t) += esi(f, t);
		endfor
	endfor

	[optSc, optInd] = max(scores(:, size(esi, 2)));

	melSpec = zeros(size(spectrogram));

	for t = size(esi, 2):-1:1
		optSemi = esi(optInd, t);

		if(maxF(optInd, t) != 0)
			mf = maxF(optInd, t);
			% mf = floor(mf * params(6) / params(9)) + 1;
			% printf("optInd = %d\n mf = %d\n\n", optInd, mf);
			% melSpec(mf, t) = optSemi;
			melSpec(mf, t) = spectrogram(mf, t);
		endif

		optInd = paths(optInd, t);
	endfor

	melSpec = max(max(melSpec)) .* (melSpec > 0);

	melSignal = TCCIstft(melSpec, params, params(9));
	melSignal = melSignal(1:nSamples);

	%plots
	fSemi = fSemi';
	esiOutPath = char(cstrcat("EsiPE(", num2str(minSemi), " ", num2str(maxSemi), " ", num2str(smoothness), ")"));
	mkdir(outPath, esiOutPath);
	outPath = char(strcat(outPath, esiOutPath, "/"));

	if(plotESI == true)
		%ESI
		esiPlot = abs(esi(:, :));

		figure(1);
		set(1, "paperunits", "points");
		%Force scale
		if(columns(esiPlot) > 2048)
			set(1, "paperposition", [0, 0, 2048, rows(esiPlot) * 2]);
		else
			set(1, "paperposition", [0, 0, columns(esiPlot), rows(esiPlot) * 2]);
		endif
		colormap(flipud(gray()));

		imagesc([0:columns(esiPlot)] / params(9) * params(2), [0:rows(esiPlot)], log(esiPlot));

		set(gca (), "ydir", "normal");
		colorbar();
		xlabel("Time");
		ylabel("Semitone");

		saveas(1, char(strcat(outPath, filename, "-ESI.png")));

		close all force
	endif

	if(plotMel == true)
		melPlot = abs(melSpec(binMin:binMax, :));
		% if(params(7) == 0)
		% 	melPlot = melPlot(1:round(size(melPlot, 1)/2), :);
		% endif

		saveName = char(strcat(outPath, filename, "-Mel.png"));
		TCCPlotSpec(melPlot, params, saveName, 2);

		audiowrite(strcat(outPath, filename, "-Mel.wav"), melSignal, params(9));
	endif

	if(plotBg == true)
		%Vocal/Melodia
		bgPlot = abs(spectrogram(binMin:binMax, :) .* (melSpec(binMin:binMax, :) == 0));

		% if(params(7) == 0)
		% 	melPlot = melPlot(1:round(size(melPlot, 1)/2), :);
		% endif

		saveName = char(strcat(outPath, filename, "-Bg.png"));
		TCCPlotSpec(bgPlot, params, saveName, 1);

		bg = TCCIstft(spectrogram - melSpec, params);
		audiowrite(strcat(outPath, filename, "-Bg.wav"), bg, params(9));
	endif

	clear -x melSignal outPath
endfunction