#!/bin/bash

if [ ! -z $1 ]; then
	current_date=$1
else
	current_date=`date +%Y%m%d`
fi

rm -r ~/.webplots_pyplot/${current_date}
rm -r ~/.webplots_gnu/${current_date}
rm "/home/lattice/.webplots_gnu/${current_date}.html" 


cd ~/.webplots_pyplot

bash ~/server_scripts/get_plot_data.sh ${current_date}  && python ~/server_scripts/make_plot.py ${current_date} 
