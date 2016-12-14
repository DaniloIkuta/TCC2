#! /usr/local/bin/octave -qfH --no-gui
%Test
%Load packages
pkg load control;
pkg load signal;

beep_on_error(true);
ignore_function_time_stamp("all");

load ConfigTest.txt;
load ConfigEsiTest.txt;
load ConfigNshsTest.txt;
load ConfigMrfftTest.txt;
load ConfigRepetSimTest.txt;
load ConfigSingTrendTest.txt;
load ConfigStftTest.txt;
load ConfigTremoloVibratoTest.txt;

%Loop files
for n = 1:size(audio, 1)
	if(exist(strcat(outPath, audio(n, :)), "dir") != 7)
		mkdir(outPath, strcat(audio(n, :), "/"));
	endif

	try
		

	catch err
		beep();
		disp(err.message);
	end_try_catch

	printf("\n");
endfor