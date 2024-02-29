#!/usr/bin/env python3

import os
import sqlite3
import optparse
import re

global opts
opts : optparse.Values

def unlink(fname):
    if not opts.no_del:
        os.unlink(fname)


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
            f.write("select t from results where solver='{solver}'\n and result!='unknown'".format(solver=solver))
        os.system("sqlite3 results.db < {fname_csv_gen}".format(fname_csv_gen=fname_csv_gen))
        unlink(fname_csv_gen)

        fname_cdf = fname_csv + ".gnuplotdata"
        num_solved = convert_to_cdf(fname_csv, fname_cdf)
        unlink(fname_csv)
        ret.append([fname_cdf, solver, num_solved])
    return ret


# Generates graphs with 2 solvers on X/Y axis and the dots representing problems that were solved
# by the different solvers.
def gen_comparative_graphs() -> None:
    def get_timeout(solver, solver2) -> int:
        with sqlite3.connect("results.db") as cur:
            ret = cur.execute("""
            select tout
            from results
            where solver='{solver}' or solver='{solver2}'
            group by tout""".format(solver=solver, solver2=solver2))
            tout = None
            for line in ret:
                if tout is None:
                    tout = int(line[0])
                else:
                    print("Error, the two solvers, '{solver}' and '{solver2}' are incomparable".format(
                        solver=solver, solver2=solver2))
                    print(" --> they were run with different timeouts")
                    exit(-1)
            if tout is None:
                print("Error, timeout couldn't be found for solvers '{solver}' and '{solver2}'".format(
                    solver=solver, solver2=solver2))
                print("  ---> were they not run?")
                exit(-1)
        return tout
    def genplot(t : str, solver:str, solver2:str) -> str:
        timeout = get_timeout(solver, solver2)
        fname = solver+"-vs-"+solver2+"." + t
        with open(fname_gnuplot, "a") as f:
            if t == "eps":
                if opts.pretty_graphs:
                    f.write("set term postscript eps color lw 1 \"Helvetica\" 16 size 3,2\n")
                else:
                    f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 6,4\n")
            elif t == "png":
                f.write("set term png size 600,400\n")
            else:
                assert False

            f.write("set output \"graphs/"+fname+"\"\n")
            f.write("set notitle\n")
            f.write("set nokey\n")
            f.write("set logscale x\n")
            f.write("set logscale y\n")
            if opts.pretty_graphs:
                solver = re.sub(r"-tstamp.*", "", solver)
                solver2 = re.sub(r"-tstamp.*", "", solver2)
            f.write("set xlabel  \""+solver+"\"\n")
            f.write("set ylabel  \""+solver2+"\"\n")
            f.write("f(x) = x\n")
            f.write("plot[0.001:{tout}][0.001:{tout}] \\\n".format(tout = timeout))
            f.write("\""+fname_gnuplot_data+"\" u 1:2 with points pt 9\\\n")
            f.write(",f(x) with lines ls 2 title \"y=x\"\n")
            f.write("\n")
        return fname

    solvers = get_solvers()
    for solver in solvers:
        for solver2 in solvers:
            if solver == solver2:
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
                    a.solver='{solver}' and b.solver='{solver2}' and a.name=b.name""".format(
                        solver=solver, solver2=solver2))
                fname_gnuplot_data = "graphs/compare-"+solver+"-"+solver2+".gnuplotdata"
                with open(fname_gnuplot_data, "w") as f:
                    for line in ret:
                        solver1_t = line[0]
                        solver2_t = line[1]
                        name = line[2]
                        f.write("%f %f %s\n" % (solver1_t, solver2_t, name))

            # generate plot
            fname_gnuplot = "compare-{solver}-vs-{solver2}.gnuplot".format(
                solver=solver, solver2=solver2)
            os.system("rm -f \"{fname}\"".format(fname=fname_gnuplot))
            if opts.pretty_graphs:
                todo =  ["eps"]
            else:
                todo = ["eps", "png"]
            for t in todo:
                name = genplot(t, solver, solver2)
                print("Generating graph: graphs/{name}".format(name=name))
            os.system("gnuplot "+fname_gnuplot)
            unlink(fname_gnuplot)

            # delete data file
            unlink(fname_gnuplot_data)


# Generates  a Cumulative Distribution Function (CDF) from the data
# See: https://online.stat.psu.edu/stat414/lesson/14/14.2
def gen_cdf_graph() -> None:
    cdf_files = gen_cdf_files()
    fname_gnuplot = "cdf.gnuplot"
    os.system("rm -f \"{fname}\"".format(fname=fname_gnuplot))
    if opts.pretty_graphs:
        todo =  ["eps"]
    else:
        todo = ["eps", "png"]

    for ext in todo:
        with open(fname_gnuplot, "a") as f:
            if ext == "eps":
                if opts.pretty_graphs:
                    f.write("set term postscript eps color lw 1 \"Helvetica\" 13 size 4,2\n")
                else:
                    f.write("set term postscript eps color lw 1 \"Helvetica\" 8 size 4,4\n")
            elif ext == "png":
                f.write("set term png size 800,600\n")
            else:
                assert False

            f.write("set output \"graphs/cdf.{ext}\"\n".format(ext=ext))
            f.write("set title \"Solvers\"\n")
            f.write("set notitle\n")
            f.write("set key bottom right\n")
            f.write("unset logscale x\n")
            f.write("unset logscale y\n")
            f.write("set ylabel  \"Problems solved\"\n")
            f.write("set xlabel \"Wallclock Time (s)\"\n")
            f.write("plot \\\n")
            towrite = ""
            for fname, solver, _ in cdf_files:
                if opts.pretty_graphs:
                    solver = re.sub(r"-tstamp.*", "", solver)
                towrite += "\""+fname+"\" u 2:1 with linespoints  title \""+solver+"\""
                towrite += ",\\\n"
            towrite = towrite[:(len(towrite)-4)]
            f.write(towrite)
            f.write("\n")

    os.system("gnuplot "+fname_gnuplot)
    unlink(fname_gnuplot)
    for fname, _, _ in cdf_files:
        unlink(fname)

    print("graph generated: graphs/cdf.eps")
    print("graph generated: graphs/cdf.png")


def check_all_same_tout() -> None:
    with sqlite3.connect("results.db") as cur:
        ret = cur.execute("""
        select tout
        from results
        group by tout""")
        touts = []
        for line in ret:
            touts.append(line[0])

    if len(touts) > 1:
        print("ERROR. Some systems were ran with differing timeouts: ")
        for t in touts:
            print("timout observed: ", t)
        print("You must delete the results.db database and run all with the same timeouts")
        exit(-1)
    if len(touts) == 0:
        print("ERROR: no data in database!")
        exit(-1)

def gen_boxgraphs() -> None:
    all_instances = []
    with sqlite3.connect("results.db") as cur:
        instances = cur.execute("select name from results group by name")
    for n in instances:
        all_instances.append(n[0])

    all_solvers = []
    with sqlite3.connect("results.db") as cur:
        solvers = cur.execute("select solver from results group by solver")
    for n in solvers:
        all_solvers.append(n[0])

    # generate data
    fname_boxdata = "boxdata.dat"
    tout = None
    with open(fname_boxdata, "w") as f:
        with sqlite3.connect("results.db") as cur:
            solve_time = {}
            for i in range(len(all_instances)):
                instance = all_instances[i]
                ret = cur.execute("""
                select name, solver, (case when result=='unknown' then tout else t end),tout
                from results
                where name='{instance}'""".format(instance=instance))
                for l in ret:
                    assert instance == l[0]
                    solver = l[1]
                    t = l[2]
                    tout = l[3]
                    t = min(t, tout)
                    solve_time[solver] = t
                instance_clean = os.path.basename(instance).replace("_", "\\\\\\_")
                f.write("{i} {instance}".format(instance=instance_clean, i=i+1))
                for solver in all_solvers:
                    assert tout is not None
                    if solver not in solve_time:
                        print("ERROR, solver '{solver}' was not run on instance '{instance}'".format(instance=instance, solver=solver))
                        exit(-1)
                    f.write(" {t}".format(t=solve_time[solver]))
                f.write("\n")

    # generate gnuplot file
    fname_gnuplot = "boxplot.gnuplot"
    w = 0.1
    with open(fname_gnuplot, "w") as f:
        for t in ["eps", "png"]:
            if t == "eps":
                f.write("set term postscript eps color lw 1 \"Helvetica\" 6 size 8,3\n")
            elif t == "png":
                f.write("set term pngcairo font \"Arial,9\" size 1800,900\n")
            f.write("set output \"graphs/boxchart.{t}\"\n".format(t=t))
            print("Generating graphs/boxchart.{t}".format(t=t))
            f.write("set boxwidth {w}\n".format(w=str(w)))
            f.write("set style fill solid\n")
            f.write("set xtics rotate by -45\n")
            f.write("set key outside bottom right\n")
            f.write("set notitle\n")
            f.write("plot [0:] \\\n")
            half = round(len(all_solvers)/2.0)
            for i in range(len(all_solvers)):
                solver = all_solvers[i]
                if i == 0:
                    xtic = ":xtic(2)"
                else:
                    xtic = ""
                if i <= len(all_solvers)/2:
                    f.write("\"{fname_boxdata}\" using ($1-{offs}):{at}{xtic} with boxes t \"{solver}\"".format(
                        fname_boxdata=fname_boxdata, solver=solver, offs = (0.1*(half-i)), at=i+3, xtic=xtic))
                else:
                    f.write("\"{fname_boxdata}\" using ($1+{offs}):{at}{xtic} with boxes t \"{solver}\"".format(
                        fname_boxdata=fname_boxdata, solver=solver, offs = (0.1*(i-half)), at=i+3, xtic=xtic))

                if i < len(all_solvers)-1:
                    f.write(", \\\n")
            f.write("\n")
    os.system("gnuplot "+fname_gnuplot)
    unlink(fname_gnuplot)
    unlink(fname_boxdata)


# Set up options for main
def set_up_parser() -> optparse.OptionParser:
    usage = "usage: %prog [options]"
    desc = """Generate all graphs
    """

    parser = optparse.OptionParser(usage=usage, description=desc)
    parser.add_option("--verbose", "-v", action="store_true", default=False,
                      dest="verbose", help="More verbose output. Default: %default")
    parser.add_option("--nodel", action="store_true", default=False,
                      dest="no_del", help="Don't delete intermediate files. Allows you to run your own graphing tools on the raw datafiles, or edit the graphviz files to match your requirements")
    parser.add_option("--box", action="store_true", default=False,
                      dest="box_only", help="Only generate box graph")
    parser.add_option("--cdf", action="store_true", default=False,
                      dest="cdf_only", help="Only generate CDF graph")
    parser.add_option("--comp", action="store_true", default=False,
                      dest="comp_only", help="Only generate comparative graph(s)")
    parser.add_option("--pretty", action="store_true", default=False,
                      dest="pretty_graphs", help="Generate pretty, less cluttered graph(s)")

    return parser


def main() -> None:
    try:
        os.mkdir("graphs")
    except FileExistsError:
        pass

    parser = set_up_parser()
    global opts
    (opts, _) = parser.parse_args()
    only_some : bool = opts.cdf_only or opts.box_only or opts.comp_only

    check_all_same_tout()
    if not only_some or opts.cdf_only:
        gen_cdf_graph()
    if not only_some or opts.box_only:
        gen_boxgraphs()
    if not only_some or opts.comp_only:
        gen_comparative_graphs()


if __name__ == "__main__":
    main()
