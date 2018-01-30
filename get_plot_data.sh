#!/bin/bash


# I sort of pieced this together from two existing scripts, should probably
# clean it up eventually.

if [ ! -z $1 ] 
then 
    : # $1 was given
	current_date=$1
else
    : # $1 was not given
	current_date=`date +%Y%m%d`
fi


echo "Parsing ... " ${current_date}

MYDATE=${current_date}
SCANFILE=/home/lattice/scan_lists/${current_date}/scan_list_${current_date}
LATTICE_DATA_FOLDER=/home/lattice/data/
LOCAL_DATA_FOLDER=/home/lattice/data/

LOCAL_PYPLOT_FOLDER=/home/lattice/.webplots_pyplot
LOCAL_GNU_FOLDER=/home/lattice/.webplots_gnu

mkdir $LOCAL_PYPLOT_FOLDER/$MYDATE
mkdir $LOCAL_GNU_FOLDER/$MYDATE 

plot_list=() 
time_list=()

hlp_last_scan="-1"

# Remove last couple files to make sure that updated
# data files are replotted.
cd $LOCAL_GNU_FOLDER/$MYDATE

files=$(shopt -s nullglob dotglob; `echo $LOCAL_GNU_FOLDER/$MYDATE/*`)
if [ ${#files[@]} -gt 1 ]; then
  ls -t | head -n 1 | xargs rm -f
fi

cd $LOCAL_PYPLOT_FOLDER 

while read line; do	

	# loop over file omitting white lines
	if [ ! -z "$line" ]; then
		
		# replace the lattice folder with the local data folder
		result_string="${line//${LATTICE_DATA_FOLDER}/$LOCAL_DATA_FOLDER}"

		substring="Excitation729"
		if [[ "$line" == *"$substring"* ]]; then
			continue
		fi

		# cut the first column
		mypath=`echo $result_string | cut -c 9-`
		mytime=`echo $result_string | cut -c 1-7`

		# check if file was already plotted
		# i.e. check if out<mytime>.png exists already
		if [ -f ${MYDATE}/out${mytime}.info ]; then
			continue
		fi

		# reset the internal file separator to be able to read filenames with spaces in them
		OLDIFS=$IFS
		IFS=$'\n'
		# find csv file and plot it		
		myfile_arr=($(find ${mypath}/*.csv))

		for i in "${myfile_arr[@]}"
		do
			# check if filename has Readout or Histogram in it
			if [[ "$i" == *"Readout"* ]]; then
				continue
			else
				if [[ "$i" == *"Histogram"* ]]; then
					continue
				fi
			fi

			
			SCAN_INFO=`echo $i | cut -c 29-`
			
			# cut the scan info in parts with / as delimiter
			arr=($(echo $SCAN_INFO | tr "/" "\n"))

			# cut the .dir
			mytitle=`echo "${arr[1]::-4}"``echo " - ${arr[2]::-4}"``echo " - ${arr[3]::-4}"`
         
			# get the column numbers with the separator ,
			no_of_columns=`awk -F, 'NR==1{print NF}' "${i}"`

			# check if file exists in case time tags are double
			if [ ! -f "${MYDATE}/out${mytime}.info" ]; then
				outfile="out"$mytime".png"
				hlp_last_scan="${MYDATE}/$outfile"

				# write info in separate file
				echo $mytitle > "${MYDATE}/out${mytime}.info"
				echo $i >> "${MYDATE}/out${mytime}.info"

				echo $mytitle > "$LOCAL_GNU_FOLDER/${MYDATE}/out${mytime}.info"
				echo $i >> "$LOCAL_GNU_FOLDER/${MYDATE}/out${mytime}.info"
				
				# add the plot we just made to the list
				time_list+=(${MYDATE}/${mytime})
				plot_list+=(${outfile})
			   
				#generate plots for the lablog
           
			   myfile="\""${i}"\""
			   no_of_columns="'"$no_of_columns"'"
			   outfile="'"$LOCAL_GNU_FOLDER/${MYDATE}/$outfile"'"
			   mytitle="'"$mytitle"'"
			   gnuplot -e "filename=${myfile}" -e "N=${no_of_columns}" -e "mytitle=${mytitle}" -e "outfile=${outfile}" $LOCAL_GNU_FOLDER/plotter.plg
			else
				outfile="out"$mytime"_1.png"
				hlp_last_scan="${MYDATE}/$outfile"

				# write info in separate file
				echo $mytitle > "${MYDATE}/out${mytime}_1.info"
				echo $i >> "${MYDATE}/out${mytime}_1.info"

				echo $mytitle > "$LOCAL_GNU_FOLDER/${MYDATE}/out${mytime}_1.info"
				echo $i >> "$LOCAL_GNU_FOLDER/${MYDATE}/out${mytime}_1.info"

				# add the plot we just made to the list
				time_list+=(${MYDATE}/${mytime}_1)
				plot_list+=(${outfile})
			
			   #generate plots for the lablog
           
			   myfile="\""${i}"\""
			   no_of_columns="'"$no_of_columns"'"
			   outfile="'"$LOCAL_GNU_FOLDER/${MYDATE}/$outfile"'"
			   mytitle="'"$mytitle"'"
			   gnuplot -e "filename=${myfile}" -e "N=${no_of_columns}" -e "mytitle=${mytitle}" -e "outfile=${outfile}" $LOCAL_GNU_FOLDER/plotter.plg
			
			fi


		done

		IFS=$OLDIFS
	
	fi

done <$SCANFILE

# make index.html file

# find all html files of the form 20160415.html
folder_arr=($(find . -maxdepth 1 -type d -printf '%P\n' | sort --reverse))

HTMLFILE=index.html

# Might as well not rewrite the file if it already exists
if [ ! -f $HTMLFILE ]
then
  echo "<html>
  <link rel="stylesheet" type="text/css" href="mytheme.css">
  <body>
  <h1>Lattice Data</h1>
  <br><hr><br>
  </body></html>
  " > $HTMLFILE

fi

for ((i=${#folder_arr[@]}-1 ; i>=0 ; i--));
do
  # Might as well just add the dates which are new since last update
  mylink_name=`echo ${folder_arr[i]}`
  if grep -xq "<h2><a href='${folder_arr[i]}'>${mylink_name}</a></h2>" $HTMLFILE
  then
    #echo "${mylink_name} already written"
    continue
  else
    sed -i -e "\@<br><hr><br>@a\<h2><a href='${folder_arr[i]}'>${mylink_name}</a></h2>" $HTMLFILE
  fi
done


# Now for the lablog plots
cd $LOCAL_GNU_FOLDER

pngfile_arr=($(find ${MYDATE}/*.png | sort -r))

HTMLFILE=${MYDATE}.html

echo "<html>
<body>" > $HTMLFILE

for ((i=0;i<${#pngfile_arr[@]};++i));
		do
			time_str=`echo ${pngfile_arr[i]} | cut -c 13- | cut -c -7`
			infofile="${MYDATE}/out${time_str}.info"
			info_file_content=`cat $infofile`
			echo "<b>${info_file_content}</b><br><img src="${pngfile_arr[i]}"><br><br><hr><br>" >> $HTMLFILE
done

echo "</body>
</html>
" >> $HTMLFILE

