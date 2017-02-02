%Semitons para hertz
function [hZ] = TCCSemi2Hz(semi)
	f0 = 21.83;
	a = 2 ^ (1/12);
	hZ = f0 * a .^ semi;
endfunction