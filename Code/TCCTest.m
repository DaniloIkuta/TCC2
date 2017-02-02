#! /usr/local/bin/octave -qfH --no-gui
%Main

%Load packages
pkg load control
pkg load signal

beep_on_error(true);
ignore_function_time_stamp("all");

%Carrega configs
[samplesPath, outPath, STFTPresets, MRFFTPresets, TVPresets, NSHSPresets, SingTrendPresets, ESIPresets, REPETPresets, audioList] = ...
	textread("ConfigTest.txt", "samplesPath = %s\n outPath = %s\n STFTPresets = %f\n MRFFTPresets = %f\n TVPresets = %f\n NSHSPresets = %f\n SingTrendPresets = %f\n ESIPresets = %f\n REPETPresets = %f\n audioList = %f", 10, "commentstyle", "shell");

samplesPath = samplesPath{1};
outPath(1) = outPath{1};

%Obter nome do áudio
if(audioList > 0)
	filenames = textread(strcat("AudioList", num2str(audioList), ".txt"), "%s\n", "delimiter", "\n", "commentstyle", "shell");
else
	filenames = textread("AudioList.txt", "%s\n", "delimiter", "\n", "commentstyle", "shell");
endif

for i = 1:size(filenames, 1)
	disp(filenames{i});

	mkdir(char(outPath(1)), filenames{i});
	outPath(i+1) = strcat(char(outPath(1)), filenames{i}, "/");

	try
		%Abrir áudio
		[origAudio, sampleRate] = audioread(strcat(samplesPath, filenames{i}, ".wav"));

		%Funções
		for specPreset = [1, 9:STFTPresets]
			printf("STFT %d/%d\n", specPreset, STFTPresets);
			[spectrogram, specParams, specOutPath] = TCCStft(origAudio, char(outPath(i+1)), filenames{i}, sampleRate, specPreset);

			disp("Identificacao de senoides");
			[fpk, apk] = TCCSinId(spectrogram, specParams);

			%Detecção de voz
			for tvPreset = 1:TVPresets
				printf(" TV %d/%d\n", tvPreset, TVPresets);
				[LTSpectrogram, HTSpectrogram, tvOutPath] = TCCTremVib(spectrogram, fpk, apk, specParams, char(specOutPath), filenames{i}, tvPreset);

				for nshsPreset = 1:NSHSPresets
					printf("  NSHS %d/%d\n", nshsPreset, NSHSPresets);
					[nshsSpec, nshsOutPath] = TCCNshs(spectrogram, LTSpectrogram, specParams, char(tvOutPath), filenames{i}, nshsPreset);

					for stPreset = 1:SingTrendPresets
						printf("   ST %d/%d\n", stPreset, SingTrendPresets);
						[stSpectrogram, stOutPath] = TCCSingTrend(spectrogram, nshsSpec, HTSpectrogram, specParams, char(nshsOutPath), filenames{i}, stPreset);

						% Melodia
						for repetPreset = 1:REPETPresets
							printf("    REPET/Voc %d/%d\n", repetPreset, REPETPresets);
							[bg, repetOutPath] = TCCRepetSim(spectrogram - stSpectrogram, size(origAudio), specParams, filenames{i}, char(stOutPath), repetPreset);
						endfor

						for esiPreset = 1:ESIPresets
							printf("    ESI/Voc %d/%d\n", esiPreset, ESIPresets);
							[melody, esiOutPath] = TCCEsiPE(stSpectrogram, fpk, specParams, char(stOutPath), filenames{i}, size(origAudio), esiPreset);
						endfor
					endfor
				endfor
			endfor

			%Melodia
			for repetPreset = 1:REPETPresets
				printf(" REPET %d/%d\n", repetPreset, REPETPresets);
				[bg, repetOutPath] = TCCRepetSim(spectrogram, size(origAudio), specParams, filenames{i}, char(specOutPath), repetPreset);
			endfor

			for esiPreset = 1:ESIPresets
				printf(" ESI %d/%d\n", esiPreset, ESIPresets);
				[melody, esiOutPath] = TCCEsiPE(spectrogram, fpk, specParams, char(specOutPath), filenames{i}, size(origAudio), esiPreset);
			endfor
		endfor

		for specPreset = 1:MRFFTPresets
			printf("MR-FFT %d/%d\n", specPreset, MRFFTPresets);
			[spectrogram, specParams, specOutPath] = TCCMrfft(origAudio, char(outPath(i+1)), filenames{i}, sampleRate, specPreset);

			disp("Identificacao de senoides");
			[fpk, apk] = TCCSinId(spectrogram, specParams);

			%Detecção de voz
			for tvPreset = 1:TVPresets
				printf(" TV %d/%d\n", tvPreset, TVPresets);
				[LTSpectrogram, HTSpectrogram, tvOutPath] = TCCTremVib(spectrogram, fpk, apk, specParams, char(specOutPath), filenames{i}, tvPreset);

				for nshsPreset = 1:NSHSPresets
					printf("  NSHS %d/%d\n", nshsPreset, NSHSPresets);
					[nshsSpec, nshsOutPath] = TCCNshs(spectrogram, LTSpectrogram, specParams, char(tvOutPath), filenames{i}, nshsPreset);

					for stPreset = 1:SingTrendPresets
						printf("   ST %d/%d\n", stPreset, SingTrendPresets);
						[stSpectrogram, stOutPath] = TCCSingTrend(spectrogram, nshsSpec, HTSpectrogram, specParams, char(nshsOutPath), filenames{i}, stPreset);

						%Melodia
						for repetPreset = 1:REPETPresets
							printf("    REPET/Voc %d/%d\n", repetPreset, REPETPresets);
							[bg, repetOutPath] = TCCRepetSim(spectrogram - stSpectrogram, size(origAudio), specParams, filenames{i}, char(stOutPath), repetPreset);
						endfor

						for esiPreset = 1:ESIPresets
							printf("    ESI/Voc %d/%d\n", esiPreset, ESIPresets);
							[melody, esiOutPath] = TCCEsiPE(stSpectrogram, fpk, specParams, char(stOutPath), filenames{i}, size(origAudio), esiPreset);
						endfor
					endfor
				endfor
			endfor

			%Melodia
			for repetPreset = 1:REPETPresets
				printf(" REPET %d/%d\n", repetPreset, REPETPresets);
				[bg, repetOutPath] = TCCRepetSim(spectrogram, size(origAudio), specParams, filenames{i}, char(specOutPath), repetPreset);
			endfor

			for esiPreset = 1:ESIPresets
				printf(" ESI %d/%d\n", esiPreset, ESIPresets);
				[melody, esiOutPath] = TCCEsiPE(spectrogram, fpk, specParams, char(specOutPath), filenames{i}, size(origAudio), esiPreset);
			endfor
		endfor

		%zero-pad
		% zpFrames = ceil((specParams(1) - specParams(2) + size(origAudio, 1)) / specParams(2));
		% origAudio = [zeros(specParams(1) - specParams(2), 1); origAudio; zeros(zpFrames * specParams(2) - size(origAudio, 1), 1)];

		clear -x samplesPath outPath spectrogramMethod voiceDetection melodyExtraction filenames

	catch erro
		beep();
		disp(erro.message);
		disp(erro.identifier);
		for errInd = 1:size(erro.stack, 1)
			disp(erro.stack(errInd));
		endfor
	end_try_catch

	printf("\n");
endfor