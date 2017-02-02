%Hertz para semitons
function [semi] = TCCHz2Semi(hZ)
	f0 = 21.83;
	% hZ = f0 * a ^ semi;
	semi = log2(hZ/f0) * 12;
endfunction