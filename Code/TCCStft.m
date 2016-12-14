%STFT
function [spectrogram, params] = TCCStft (audio, outPath, filename, sampleRate)
	%Carregar configs
	[winSize, hopSize, bins, winType, plot, minF, maxF] = ...
		textread("ConfigStft.txt", "winSize = %f\n hopSize = %f\n bins = %f\n winType = %f\n plot = %f\n minF = %f\n maxF = %f", 7, "commentstyle", "shell");

	%zero-pad
	zpFrames = ceil((winSize - hopSize + size(audio, 1)) / hopSize);
	audio = [zeros(winSize - hopSize, 1); audio; zeros(zpFrames * hopSize - size(audio, 1), 1)];

	%Win
	switch (winType)
        case 1  win = hanning (winSize);
        case 2  win = hamming (winSize);
        case 3  win = ones (winSize, 1);
    endswitch

	%Função padrão do octave
	spectrogram = zeros(winSize, zpFrames);
	[spectrogram, params] = stft(audio, winSize, hopSize, bins, winType);

	%Via fft
	% for j = 1:zpFrames
		% spectrogram(:, j) = fft(audio(1:winSize) + hopSize * (j-1) .* win);
	% endfor

	params = [params, minF, maxF, bins, 0, size(audio, 1), sampleRate];
	% params = [winSize, hopSize, winType, minF, maxF, bins, 0];

	%Cortar frequencias
	binMin = floor(minF/sampleRate * bins) + 1;
	binMax = floor(maxF/sampleRate * bins);

	spectrogram(1:(binMin-1), :) = 0;
	spectrogram((binMax+1):bins, :) = 0;

	stftOutPath = char(cstrcat("STFT(", num2str(winSize), " ", num2str(hopSize), " ", num2str(bins), " ", num2str(winType), " ", num2str(minF), " ", num2str(maxF), ")"));

	if(exist(strcat(char(stftOutPath, stftOutPath)), "dir") != 7)
		mkdir(outPath, stftOutPath);
	endif
	outPath = char(strcat(outPath, stftOutPath, "/"));
	
	%Plot de espectrograma(opcional)
	if(plot == true && nargin() == 4)
		specPlot = abs(spectrogram(binMin:binMax, :));

		saveName = char(strcat(outPath, filename, "-STFT.png"));
		TCCPlotSpec(specPlot, params, saveName, 1);

		sig = TCCIstft(spectrogram, params, sampleRate);
		audiowrite(strcat(outPath, filename, "-STFT.wav"), sig, sampleRate);
	endif

	clear -x spectrogram params
endfunction