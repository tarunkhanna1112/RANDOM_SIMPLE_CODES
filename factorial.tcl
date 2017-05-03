# EXECUTION tclsh factorial.tcl $number $base

set base [lindex $::argv 1]
set num [lindex $::argv 0]

set power 0
set value 1.0
for {set i $num} {$i > 0.0} {set i [expr { $i - 1.0 }]} {
	set value [expr { $i*$value }] 
	if { $value > $base } {
		while { $value > $base } {
			set value [expr { $value / $base }]
			incr power
		}
	}
}
set value [format "%0.6f" $value]
puts "$value X $base^$power"
