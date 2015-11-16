//log = log_base(number)
function integer log;
	input [31 : 0] base, number;
	
	integer i;
	integer tmp;
begin
	tmp = 1;
	for (i = 0; (number > tmp) && (i < 32); i = i + 1) begin
		tmp = tmp * base;
	end
	log = i;
end
endfunction