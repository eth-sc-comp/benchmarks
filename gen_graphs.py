#!/bin/python3

import os
import sqlite3

# Converts file to ascending space-delimited file that shows
# the number of problems solved and the timeout it took to solve the next
# file. Returns the number of problems solved in total
# CDF stands for Cumulative Distribution Function
def convert_to_cdf(fname: str, fname2: str) -> int:
    f = open(fname, "r")
    f2 = open(fname2, "w")
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

# convert T1, T2, TOUT to make T1/T1 into TOUT in case they are empty
def convert_to_tout(fname: str, fname2: str):
    f = open(fname, "r")
    f2 = open(fname2, "w")
    for line in f:
        out: list[float] = []
        line = line.strip().split(",")
        tout = float(line[2])
        if line[0].strip() == "":
            out.append(tout)
        else:
            out.append(min(float(line[0]), tout))
        if line[1].strip() == "":
            out.append(tout)
        else:
            out.append(min(float(line[1]), tout))
        f2.write("%s %s\n" % (out[0], out[1]))
    f.close()
    f2.close()


# Get all solvers in the DB
def get_solvers() -> list[str]:
    ret = []
    with sqlite3.connect("results.db") as con:
        cur = con.cursor()
        res = cur.execute("SELECT solver FROM results group by solver")
        for a in res: ret.append(a[0])
    return ret


# generates files for GNU to plot for each solver
def gen_cdf_files() ->list[tuple[str, str, int]]:
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
        os.system("sqlite3 results.db < gencsv.sqlite")

        fname2 = fname + ".gnuplotdata"
        num_solved = convert_to_cdf(fname, fname2)
        os.unlink(fname)
        ret.append([fname2, solver, num_solved])
    return ret


def gen_comparative_graphs() ->list[tuple[str, str, int]]:
    ret = []
    solvers = get_solvers()
    for solver in solvers:
        for solver2 in solvers:
            if solver2 == solver: continue
            # create data file
            fname = "graphs/compare-"+solver+"-"+solver2+".csv"
            with open("gencsv.sqlite", "w") as f:
                f.write(".headers off\n")
                f.write(".mode csv\n");
                f.write(".output "+fname+"\n")
                f.write("select (case when a.result=='unknown' then a.tout else a.t end),(case when b.result=='unknown' then b.tout else b.t end),a.tout from results as a, results as b where a.solver='"+solver+"' and b.solver='"+solver2+"' and a.name=b.name")
            os.system("sqlite3 results.db < gencsv.sqlite")
            fname2 = fname + ".gnuplotdata"
            convert_to_tout(fname, fname2)
            os.unlink(fname)

            # create graph
            gnuplotfn = "run-one.gnuplot"
            outfname = solver+"-vs-"+solver2+".eps"
            with open(gnuplotfn, "w") as f:
                f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 6,4\n")
                f.write("set output \""+outfname+"\"\n")
                f.write("set notitle\n")
                f.write("set nokey\n")
                f.write("set logscale x\n")
                f.write("set logscale y\n")
                f.write("set xlabel  \""+solver+"\"\n")
                f.write("set ylabel  \""+solver2+"\"\n")
                f.write("f(x) = x\n")
                f.write("plot[0.001:] \\\n")
                f.write("\""+fname2+"\" u 1:2 with points\\\n")
                f.write(",f(x) with lines ls 2 title \"y=x\"\n")

            os.system("gnuplot "+gnuplotfn)
            os.unlink(gnuplotfn)
            os.unlink(fname2)
            print("okular %s" % outfname)
    return ret


def gen_cdf_graph():
    files = gen_cdf_files()
    gnuplotfn = "run-all.gnuplot"
    with open(gnuplotfn, "w") as f:
        f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 4,4\n")
        f.write("set output \"cdf.eps\"\n")
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
    os.unlink(gnuplotfn)
    for fname,_,_ in files:
        os.unlink(fname)

    print("okular cdf.eps")


def main():
    gen_cdf_graph()
    gen_comparative_graphs()


if __name__ == "__main__":
    main()
