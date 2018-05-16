#ifndef PLOT_COMMAND_H
    #define PLOT_COMMAND_H

char * commandsForGnuplot[] = {
    "set terminal postscript eps enhanced color font 'Helvetica,15'",
    "set output 'temp.eps' ",
    "set style line 1 lc rgb \"red\"        lt 1 lw 2 pt 4  ps 1.5",
    "set style line 2 lc rgb \"blue\"       lt 1 lw 2 pt 6  ps 1.5", 
    "set style line 3 lc rgb \"green\"      lt 1 lw 2 pt 10 ps 1.5",
    "set style line 4 lc rgb '#8B008B'     lt 1 lw 2 pt 14 ps 1.5",//darkmagenta
    "set style line 5 lc rgb '#B8860B'     lt 1 lw 2 pt 2  ps 1.5", //darkgoldenrod
    "set style line 6 lc rgb \"gold\"     lt 1 lw 2 pt 3  ps 1.5",
    "set style line 7 lc rgb '#FF8C00'     lt 1 lw 2 pt 10 ps 1.5",//darkorange
    "set style line 8 lc rgb \"black\"     lt 1 lw 2 pt 1  ps 1.5",
    "set style line 9 lc rgb \"spring-green\"     lt 1 lw 2 pt 8  ps 1.5",
    "set style line 10 lc rgb \"yellow4\"     lt 1 lw 2 pt 0  ps 1.5",
"set style fill transparent solid 0.5 border",
    "set yrange [0:45]",
    "set xrange [0:]",
    
    0
};

#endif

