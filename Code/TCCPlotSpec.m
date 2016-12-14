function TCCPlotSpec(spec, params, saveName, cm)
	figure(1);
	set(1, "paperunits", "points");
	set(1, "paperposition", [0, 0, round(params(8) / params(9) * 100), round((params(5) - params(4)) / 10)]);

	switch(cm)
		case 1
			colormap(jet());
		case 2
			colormap(flipud(gray()));
	endswitch
	
	imagesc([0:(params(8)/params(9))], [params(4):params(5)], log(spec));
	set(gca (), "ydir", "normal");
	xlabel("Time");
	ylabel("Frequency");

	saveas(1, saveName);
	close(1);

	clear -v
endfunction