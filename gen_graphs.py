#!/bin/python3

import os
import sqlite3

# Converts file to ascending space-delimited file that shows
# the number of problems solved and the timeout it took to solve the next
# file. Returns the number of problems solved in total
def convert_to_cactus(fname: str, fname2: str) -> int:
    f2 = open(fname2, "w")
    f = open(fname, "r")
    text = f.read()
    mylines = text.splitlines()
    time = []
    for line in mylines :
      time.append(float(line.split()[0]))

    lastnum = -1
    for a in range(0, 3600, 1):
      num = 0
      for t in time:
        if (t < a) :
          num += 1

      if (lastnum != num) :
          f2.write("%d \t%d\n" %(num, a))
      lastnum = num
    f.close()
    f2.close()
    return len(mylines)

# Get all solvers in the DB
def get_solvers() -> list[str]:
    ret = []
    with sqlite3.connect("results.db") as con:
        cur = con.cursor()
        res = cur.execute("SELECT solver FROM results group by solver")
        for a in res: ret.append([a[0]])
    return ret


# generates files for GNU to plot for each solver
def gen_files() ->list[tuple[str, str, int]]:
    ret = []
    solvers = get_solvers()
    for solver in solvers:
        print("solver:", solver)
        fname = "graphs/run-"+solver+".csv"
        with open("gencsv.sqlite", "w") as f:
            f.write(".headers off\n")
            f.write(".mode csv\n");
            f.write(".output "+fname+"\n")
            f.write("select t from results where solver='"+solver+"'\n and result!='unknown'")
        os.system("sqlite3 mydb.sql < gencsv.sqlite")

        fname2 = fname + ".gnuplotdata"
        num_solved = convert_to_cactus(fname, fname2)
        ret.append([fname2, solver, num_solved])
    return ret

def main():
    files = gen_files()
    gnuplotfn = "run-all.gnuplot"
    with open(gnuplotfn, "w") as f:
        f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 6,4\n")
        f.write("set output \"run.eps\"\n")
        f.write("set title \"Solvers\"\n")
        f.write("set notitle\n")
        f.write("set key bottom right\n")
        f.write("unset logscale x\n")
        f.write("unset logscale y\n")
        f.write("set ylabel  \"Problems sovled\"\n")
        f.write("set xlabel \"Wallclock Time (s)\"\n")
        f.write("plot \\\n")
        towrite = ""
        for fname,solver,_ in files:
            towrite +="\""+fname+"\" u 2:1 with linespoints  title \""+solver+"\""
            towrite +=",\\\n"
        towrite = towrite[:(len(towrite)-4)]
        f.write(towrite)

    os.system("gnuplot "+gnuplotfn)
    print("okular run.eps")
    os.system("okular run.eps")


if __name__ == "__main__":
    main()
