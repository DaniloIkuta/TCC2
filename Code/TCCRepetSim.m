%REPET-SIM (Matrizes de similaridade)
function [bg, outPath] = TCCRepetSim(spectrogram, nSamples, params, filename, outPath, preset)
	global binMax = floor(params(5) / params(9) * params(6));
	global binMin = floor(params(4) / params(9) * params(6)) + 1;

	%Configs
	if(preset == 0)
		[minThresh, minDist, maxRep, plotMat, plotBg, plotMel] = ... 
			textread("ConfigRepetSim.txt", "minThresh = %f\n minDist = %f\n maxRep = %f\n plotMat = %f\n plotBg = %f\n plotMel = %f", 6, "commentstyle", "shell");
	else
		[minThresh, minDist, maxRep, plotMat, plotBg, plotMel] = ... 
			textread(strcat("ConfigRepetSim", num2str(preset), ".txt"), "minThresh = %f\n minDist = %f\n maxRep = %f\n plotMat = %f\n plotBg = %f\n plotMel = %f", 6, "commentstyle", "shell");
	endif

	% specSim = zeros(size(spectrogram, 1) / 2, size(spectrogram, 2));
	% specSim(binMin:binMax, :) = abs(spectrogram(binMin:binMax, :));
	specSim = abs(spectrogram);
	simMat = similarityMatrix(specSim);
	minDistInd = round(minDist*params(9)/params(2));

	disp("Indices");
	simIndices = similarityIndices(simMat, minThresh, minDistInd, maxRep);

	disp("Mask");
	mask = repMask(specSim, simIndices);
	mask(1:(binMin - 1), :) = 1;
	mask((binMax + 1):size(mask, 1), :) = 1;

	bg = zeros(nSamples);
	bg = TCCIstft(mask .* spectrogram, params);
	bg = bg(1:nSamples);

	repetOutPath = char(cstrcat("REPET-SIM(", num2str(minThresh), " ", num2str(minDist), " ", num2str(maxRep), ")"));
	mkdir(outPath, repetOutPath);
	outPath = char(strcat(outPath, repetOutPath, "/"));

	%Plot
	if(plotMat == true)
		figure(1);
		set(1, "paperunits", "points");
		set(1, "paperposition", [0, 0, 1024, 1024]);

		colormap(flipud(gray()));

		imagesc([1:rows(simMat)], [1:columns(simMat)], simMat);
		set(gca (), "ydir", "normal");
		colorbar();
		xlabel("Spectrogram");
		ylabel("Spectrogram\'");

		saveas(1, char(strcat(outPath, filename, "-SimMat.png")));
		close(1);
	endif

	if(plotBg == true)
		bgSpecPlot = abs(mask(binMin:binMax, :) .* spectrogram(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-bgSpec.png"));
		TCCPlotSpec(bgSpecPlot, params, saveName, 1);

		audiowrite(strcat(outPath, filename, "-bg.wav"), bg, params(9));

		% maskPlot = abs(mask(binMin:binMax, :));

		% saveName = char(strcat(outPath, filename, "-bgMask.png"));
		% TCCPlotSpec(maskPlot, params, saveName, 2);
	endif

	if(plotMel == true)
		melSpecPlot = abs(spectrogram(binMin:binMax, :) - mask(binMin:binMax, :) .* spectrogram(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-melSpec.png"));
		TCCPlotSpec(melSpecPlot, params, saveName, 1);

		mel = TCCIstft(spectrogram - mask .* spectrogram, params);
		audiowrite(strcat(outPath, filename, "-mel.wav"), mel,params(9));
	endif

	clear global
	clear -x bg outPath
endfunction

function simMat = similarityMatrix(spectrogram)
	global binMin;
	global binMax;

	for j = 1:size(spectrogram, 2)
		spectrogram(binMin:binMax, j) = spectrogram(binMin:binMax, j) / (norm(spectrogram(binMin:binMax, j), 2) + eps);
	endfor

	simMat = spectrogram' * spectrogram;
endfunction

function simIndices = similarityIndices(simMat, minThresh, minDist, maxRep)
	m = size(simMat, 1);
	simIndices = cell(1, m);

	for j = 1:m
		if(mod(j, 250) == 0) printf("%d/%d\n", j, m); endif

		%GOTTA GO FASTER!
		[~, si] = findpeaks(simMat(:, j), ...
			"MinPeakHeight", minThresh, ...
			"MinPeakDistance", minDist);

		if(!isempty(si))
			si = sortrows(si, -1);

			if(size(si) > maxRep)
				resize(si, [, maxRep]);
			endif
		endif

		simIndices(j) = si;
	endfor
endfunction

function mask = repMask(spectrogram, simIndices)
	global binMin;
	global binMax;

	mask = zeros(size(spectrogram));

	for j = 1:size(spectrogram, 2)
		i = simIndices{j};

		%i = 0?
		if(!isempty(spectrogram(binMin:binMax, i)))
			mask(binMin:binMax, j) = median(spectrogram(binMin:binMax, i), 2);
		endif
		
	endfor

	mask = min(spectrogram, mask);
	mask(binMin:binMax, :) = (mask(binMin:binMax, :) + eps) ./ (spectrogram(binMin:binMax, :) + eps);
endfunction