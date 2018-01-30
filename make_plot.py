import time
import cPickle as pickle
import os
import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import mpld3
import csv
import sys
import glob
from mpld3 import plugins


def make_html_plot_for_file(filename, my_title):
    my_fontsize = 20
    
    # read in csv file
    if os.stat(filename).st_size:
        data = np.genfromtxt(filename, delimiter=',')
    else:
        # empty data file 
        data = np.zeros([2, 2])

    if len(data.shape) == 1:
        return "<h2> " + my_title + " has no data </h2>"

    x = data[:, 0]
    fig, ax = plt.subplots(figsize=(10, 5))

    for k in range(1, data.shape[1]):
        y = data[:, k]
        
        # sort data
        x_sorted = [x1 for (x1,y1) in sorted(zip(x, y))]
        y_sorted = [y1 for (x1,y1) in sorted(zip(x, y))]
        
        lines = ax.plot(x_sorted, y_sorted, '.-', markersize=15, label = 'ion ' + str(k-1))

    plt.legend(fontsize = my_fontsize, loc = 'best')
    plt.title(my_title, fontsize = my_fontsize)
    ax.grid()
    plt.xticks(fontsize = my_fontsize)
    plt.yticks(fontsize = my_fontsize)
    plt.xlim([np.min(x), np.max(x)])
    
    #90% of the time that this function takes is taken up after this line
    plugins.clear(fig)
    plugins.connect(fig, plugins.Reset(), plugins.BoxZoom(), plugins.Zoom(enabled = True), 
                    plugins.MousePosition(fontsize = my_fontsize))
    java_txt = mpld3.fig_to_html(fig)
    plt.close()
     
    return java_txt



################################################################# 
#                        main program                           #
#################################################################



if len(sys.argv) == 1:
        current_date = time.strftime("%Y%m%d")
else:
        current_date = sys.argv[1]


list_of_files = glob.glob(current_date + '/*.info')
for i,j in enumerate(list_of_files):
    # remove any duplicates
    name = j.split("_")
    if len(name) > 2:
        del list_of_files[i]
list_of_files = sorted(list_of_files, reverse=True)
no_of_files = len(list_of_files)
current_file_no = no_of_files/5
print "LENGTH: ", no_of_files 
print "\ncurrent_file_no: ", current_file_no


no_of_graphs_plotted = 5 - no_of_files%5 
if no_of_graphs_plotted == 5 and current_file_no != 0:
    no_of_graphs_plotted = 0
    current_file_no -= 1


main_file = open(current_date + '/index.html', 'w')

html_text = '\
            <html>\
            <frameset cols="20%,80%">\
            <frame src="list_of_files.html">\
            <frame src="data_{}.html", name="data_frame">\
            </frameset>\
            </html>\
            '.format(current_file_no)

main_file.write(html_text)
main_file.close()


cwd = os.getcwd()
html_text = "<html><body>\n"


try:
    os.remove(current_date + "/data_" + str(current_file_no) + ".html")
except OSError:
    print "File doesn't exist"


file = open(current_date + '/data_' + str(current_file_no) + '.html', 'w')
file.write(html_text)


list_file = open(current_date + '/list_of_files.html', 'w')


# keep a list of files for which plots have
# already been generated
list_of_files_pickle = cwd + "/" + current_date \
                       + "/list_of_files.pickle"
try:
    with open(list_of_files_pickle, "rb") as pickle_in:
        pickle_list = pickle.load(pickle_in)
except IOError:
    pickle_list = ["last"]

list_file_txt = ""
plotted_count = 0
print "no_of_graphs_plotted initially: ", no_of_graphs_plotted
for k in range(no_of_files):
    
    no_of_graphs_plotted += 1
    info_filename = list_of_files[k]
    my_file = open(info_filename, 'r')
    
    # lines[0] is the title
    # lines[1] is the path to the file
    lines = my_file.read().split("\n")

    # write scan number into table of contents file
    target_id = lines[0].split(" - ")[2]
    list_file_txt += '<a href="data_' + str(current_file_no) + '.html#' + target_id \
                     + '" target="data_frame">' + lines[0] + '</a><br><br>\n'

    # Don't make a new plot if it already exists
    if lines[0] in pickle_list:
        if no_of_graphs_plotted == 5:
            no_of_graphs_plotted = 0
            current_file_no -= 1
            print "made it here\n"
        continue
    else:
        pickle_list.insert(0, lines[0])

    java_text = make_html_plot_for_file(lines[1], lines[0]) + "\n"
    plotted_count += 1
    
    # write graph into main file
    file.write('<br id = ' + target_id + ">\n")
    file.write(java_text)
    file.write("<br><hr>\n")

    print "no_of_graphs_plotted: ", no_of_graphs_plotted
    

    if no_of_graphs_plotted == 5:
        no_of_graphs_plotted = 0
        current_file_no -= 1 
        
        try:
            temp_file = open(list_of_files[k+1], "r")
            lines_temp = temp_file.read().split("\n")
            temp_file.close()
            if lines_temp[0] in pickle_list:
                continue 
        except IndexError:
            print "Reached last element"

        # change the file
        if current_file_no < 0:
           continue 

        html_text = "</body>\</html>\n"
        file.write(html_text)
        file.close()
        
        print "no_of_graphs_plotted, finishing a run: ", no_of_graphs_plotted
        print "current_file_no: ", current_file_no
        
        # open new file
        file = open(current_date + '/data_' + str(current_file_no) + '.html', 'w')
        html_text = "<html><body>\n"
        file.write(html_text)

try:
    pickle_list = pickle_list[5+no_of_files%5:]
except:
    pickle_list = ["last"]
list_file.write(list_file_txt)
list_file.close()
print "TOTAL PLOTTED: ", plotted_count


html_text = "</body>\</html>\n"
file.write(html_text + "\n")
file.close()
with open(list_of_files_pickle, "wb") as pickle_out:
    pickle.dump(pickle_list, pickle_out)

