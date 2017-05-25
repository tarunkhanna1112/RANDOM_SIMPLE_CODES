package require csv

# Executing ncdump to get the number of frames

# REQUIRES NETCDF INSTALLATION

set nframes 0.0
set filesize 0.0

set top [lindex $::argv 0]
set inpfile [lindex $::argv 1]

set filesize [expr { [file size $inpfile] / 1000000.00 }]

puts ""
puts "SIZE OF THE BINARIES IS $filesize megabytes"

exec ncdump -h $inpfile | tee log1
set f [open "log1" "r"]
set data [read $f]
close $f

set k 0 

while { [lindex $data 2 $k] != "frame" } {
 incr k
}

if { [lindex $data 2 [expr { $k + 2 }]] == "UNLIMITED" } {
 set dum [lindex $data 2 [expr { $k + 5 }]]
 set nframes [string range $dum 1 [string length $dum]]
} else {
 puts "ERROR:: can't determine the number of frames automatically"
 puts ""
 puts " ENTER THE NUMBER OF FRAMES MANUALLY"
 set nframes [gets stdin]
}
set nframes [format "%.0f" $nframes]
puts ""
puts "NUMER OF FRAMES IN THE FILE = $nframes"
puts ""

set size_per_frame [expr { $filesize / $nframes }]
set size_per_frame [format "%.2f" $size_per_frame]

puts "FILE SIZE PER FRAME IS APPROXIMATELY EQUALS $size_per_frame megabytes"
puts ""

# Using mdconvert (from MDTRAJ) to divide the input netcdf file into chunks of less than 5Mb

set test 0

set k 0

while { $test < 5.0 } { 
 set test [expr { $test + $size_per_frame }]
 incr k
}
set frame_per_file $k

if { $frame_per_file > 0 } {
 set numfiles [expr { $nframes / $frame_per_file }]
 puts "DIVIDING THE INPUT FILE INTO $numfiles EACH CONTAING INFORMATION ABOUT $frame_per_file FRAMES"
 puts ""
 puts "DO YOU WISH TO CONTINUE WITH THE CONVERSION? (y/n)"
 set inp1 [gets stdin]
 puts ""
 if { $inp1 == "y" || $inp1 == "Y" } {
  set lostframes [expr { $nframes - ($numfiles * $frame_per_file) }]
  puts "$lostframes FRAMES WILL BE LOST"
  puts ""
  if { $lostframes > 0 } {
   puts "DO YOU WANT TO BACK STRETCH (BS) OR FORWARD STRTCH (FS) THE FRAMES"
   set inp2 [gets stdin]
   puts ""
   if { $inp2 == "BS" || $inp2 == "Bs" || $inp2 == "bS" || $inp2 == "bs" } {
    set start 1
    set end [expr { $nframes - $lostframes }]
   } else {
    set start $lostframes
    set end $nframes
   }
  } else {
   set start 1
   set end $nframes
  }

  # CONVERSION TO ASCII FORMAT

  set k 1
  for {set i $start} {$i < $end} {incr i $frame_per_file} {
   puts ""
   puts "    #### GENERATING FILE $k ####"
   set j [expr { $i + $frame_per_file }]
   exec -ignorestderr mdconvert -o $k.nc -f -i $i:$j -t $top $inpfile | tee log2
   exec ncdump $k.nc | tee $k.dat
   file delete $k.nc
   incr k
  }

 } else {
  puts "THANK YOU FOR USING THE CODE"
  puts ""
 }
} else {
 puts "TOO LARGE FILE FOR HARDWIRED SELECTION CRITERION"
 puts ""
}

# DETERMING THE START AND END STRING FOR COORDINATES

set f [open "1.dat" "r"]
set data1 [read $f]
close $f

set data2 [lindex $data1 2]
set term [string first "atom" $data2]
incr term 7
set term2 [string first "cell_spatial" $data2]
set term2 [expr { $term2 - 5 }]

set natoms [string range $data2 $term $term2]
set start_string "coordinates"
set end_string ";"

# Genarating CSV files with no. of atoms as rows and frames as columns

puts "    #### BY DEFAULT THE CODE WILL GENERATE THE CSV FILE FOR THE WHOLE SYSTEM ####"
puts ""
puts "		#### DO YOU WANT TO SPECIFY THE RANGE OF ATOMS? (Y/N) ####"
set div [gets stdin]
puts ""
if { $div == "y" || $div == "Y" } {
	puts "		#### ENTER THE LOWER ATOM ID ####"
	set lai [gets stdin]

	puts ""
	puts "		#### ENTER THE UPPER ATOM ID ####"
	set uai [gets stdin]
} else { 
	set lai 0
	set uai $natoms
}

set m 1
set n 1
set nf $start
for {set i 1} {$i <= $natoms} {incr i} {
 set l($i) ""
}

for {set i $start} {$i < $end} {incr i $frame_per_file} {
 puts ""
 puts "    #### READING FILE $m ####"
 set k 0
 set f [open "$m.dat" "r"]
 set data1 [read $f]
 close $f

 set data2 [lindex $data1 2]

 set term [string first "coordinates =" $data2]
 set data [string range $data2 $term [string length $data2]]

 while { [lindex $data $k] != $start_string } {
  incr k
 }

 incr k 2

 while { [lindex $data $k] != $end_string } {
  if { $n >= $lai && $n <= $uai } {
		set x [lindex $data $k]
		set x [string range $x 0 [expr { [string length $x] - 2 }]]
		set y [lindex $data [expr { $k + 1 }]]
		set y [string range $y 0 [expr { [string length $x] - 2 }]]
		set z [lindex $data [expr { $k + 2 }]]
		set z [string range $z 0 [expr { [string length $z] - 2 }]]

		lappend l($n) $x $y $z
	}

  if { $n == $natoms } {
	 puts "   ### READING FRAME $nf ###"
	 incr nf
   set n 1
  } else {
   incr n
  }
  incr k 3
 }
 incr m
}

set all_list ""
for {set i 1} {$i <= $natoms} {incr i} {
 if { $l($i) != "" } {
 	lappend all_list $l($i)
 }
}

set g [open "data.csv" "w"]
puts $g [csv::joinlist $all_list]
close $g



















