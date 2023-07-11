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
    for line in mylines:
        time.append(float(line.split()[0]))

    lastnum = -1
    for a in range(0, 3600, 1):
        num = 0
        for t in time:
            if (t < a):
                num += 1

        if (lastnum != num):
            f2.write("%d \t%d\n" % (num, a))
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
        for a in res:
            ret.append(a[0])
    return ret


# generates files for GNU to plot for each solver
def gen_cdf_files() -> list[tuple[str, str, int]]:
    ret = []
    solvers = get_solvers()
    print("Solvers: ", solvers)
    for solver in solvers:
        fname_csv = "graphs/run-"+solver+".csv"
        fname_csv_gen = "gencsv.sqlite"
        with open(fname_csv_gen, "w") as f:
            f.write(".headers off\n")
            f.write(".mode csv\n")
            f.write(".output "+fname_csv+"\n")
            f.write("select t from results where solver='"+solver+"'\n and result!='unknown'")
        os.system("sqlite3 results.db < %s" % fname_csv_gen)
        os.unlink(fname_csv_gen)

        fname_cdf = fname_csv + ".gnuplotdata"
        num_solved = convert_to_cdf(fname_csv, fname_cdf)
        os.unlink(fname_csv)
        ret.append([fname_cdf, solver, num_solved])
    return ret


# Generates graphs with 2 solvers on X/Y axis and the dots representing problems that were solved
# by the different solvers.
def gen_comparative_graphs() -> None:
    def genplot(t : str) -> str:
        fname = solver+"-vs-"+solver2+"." + t
        with open(fname_gnuplot, "a") as f:
            if t == "eps":
                f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 6,4\n")
            elif t == "png":
                f.write("set term png size 600,400\n")
            else:
                assert False

            f.write("set output \""+fname+"\"\n")
            f.write("set notitle\n")
            f.write("set nokey\n")
            f.write("set logscale x\n")
            f.write("set logscale y\n")
            f.write("set xlabel  \""+solver+"\"\n")
            f.write("set ylabel  \""+solver2+"\"\n")
            f.write("f(x) = x\n")
            f.write("plot[0.001:] \\\n")
            f.write("\""+fname_gnuplot_data+"\" u 1:2 with points\\\n")
            f.write(",f(x) with lines ls 2 title \"y=x\"\n")
            f.write("\n")
        return fname

    solvers = get_solvers()
    for solver in solvers:
        for solver2 in solvers:
            if solver2 <= solver:
                continue
            # create data file
            with sqlite3.connect("results.db") as cur:
                ret = cur.execute("""
                select
                    (case when a.result=='unknown' then a.tout else a.t end),
                    (case when b.result=='unknown' then b.tout else b.t end),
                    a.name
                from results as a, results as b
                where
                    a.solver='%s' and b.solver='%s' and a.name=b.name""" % (solver, solver2))
                fname_gnuplot_data = "graphs/compare-"+solver+"-"+solver2+".gnuplotdata"
                with open(fname_gnuplot_data, "w") as f:
                    for l in ret:
                        solver1_t = l[0]
                        solver2_t = l[1]
                        name = l[2]
                        f.write("%f %f %s\n" % (solver1_t, solver2_t, name))

            # generate plot
            fname_gnuplot = "compare.gnuplot"
            os.system("rm -f \"%s\"" % fname_gnuplot)
            for t in ["eps", "png"]:
                name = genplot(t)
                print("generating graph: %s" % name)
            os.system("gnuplot "+fname_gnuplot)
            os.unlink(fname_gnuplot)

            # delete data file
            os.unlink(fname_gnuplot_data)


# Generates  a Cumulative Distribution Function (CDF) from the data
# See: https://online.stat.psu.edu/stat414/lesson/14/14.2
def gen_cdf_graph() -> None:
    cdf_files = gen_cdf_files()
    fname_gnuplot = "cdf.gnuplot"
    os.system("rm -f \"%s\"" % fname_gnuplot)
    for t in ["eps", "png"]:
        with open(fname_gnuplot, "a") as f:
            if t == "eps":
                f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 4,4\n")
            elif t == "png":
                f.write("set term png size 800,600\n")
            else:
                assert False

            f.write("set output \"cdf.%s\"\n" % t)
            f.write("set title \"Solvers\"\n")
            f.write("set notitle\n")
            f.write("set key bottom right\n")
            f.write("unset logscale x\n")
            f.write("unset logscale y\n")
            f.write("set ylabel  \"Problems sovled\"\n")
            f.write("set xlabel \"Wallclock Time (s)\"\n")
            f.write("plot \\\n")
            towrite = ""
            for fname, solver, _ in cdf_files:
                towrite += "\""+fname+"\" u 2:1 with linespoints  title \""+solver+"\""
                towrite += ",\\\n"
            towrite = towrite[:(len(towrite)-4)]
            f.write(towrite)
            f.write("\n")

    os.system("gnuplot "+fname_gnuplot)
    os.unlink(fname_gnuplot)
    for fname, _, _ in cdf_files:
        os.unlink(fname)

    print("graph generated: cdf.eps")
    print("graph generated: cdf.png")


def main() -> None:
    try:
        os.mkdir("graphs")
    except FileExistsError:
        pass
    gen_cdf_graph()
    gen_comparative_graphs()
    # TODO other functions


if __name__ == "__main__":
    main()
