#!/bin/bash
#
# Example: bash test.sh "${HOME}" "$(date +%Y%m%d).txt" "cat ~/Desktop/temp.txt" "hive"
# test.sh <output_location> <output_filename> <execution cmd> <warehouse>
#


set -a                 #Explicitly mark variables as export to allow access in sub-shell                                      #Testing for usage
set -f                 #Disable filename expansion
set -m                 #Enabling Job Control. Should assign child processes to one group and SIG handling easier              #Testing for purpose
set -o pipefail        #Exit pipe on first cmd failure and print exit status
set -e                 #Exit immediately on error

## set user variable
OUTPUT_PATH=${1}
OUTPUT_FILE=${2}
CMD_TO_EXECUTE=${3}
WAREHOUSE=${4}


## some almost useless stuff
if [[ -f "${OUTPUT_PATH}/${OUTPUT_FILE}" ]] 
then
  HEADER_CHECK=$(grep "Warehouse" "${OUTPUT_PATH}/${OUTPUT_FILE}")
  if [[ -z ${HEADER_CHECK} ]] 
  then 
    env printf "%-30s\t%-15s\t%-50s\t%-10s\t%s\n" Date Warehouse DBName Size "Consumed Space" > "${OUTPUT_PATH}/${OUTPUT_FILE}"
  fi
else
  touch "${OUTPUT_PATH}/${OUTPUT_FILE}"
  env printf "%-30s\t%-15s\t%-50s\t%-10s\t%s\n" Date Warehouse DBName Size "Consumed Space" > "${OUTPUT_PATH}/${OUTPUT_FILE}" 
fi


## Read a command input and store in output
eval ${CMD_TO_EXECUTE} | while read var; do
  DB_NAME=$(echo "${var}" | rev | cut -d "/" -f1 | rev)
  DB_SIZE_CHECK=$(echo "${var}" | tr -s " " | rev | cut -d " " -f3 | rev)
  DB_SIZE_CHECK=$(bc <<< "${DB_SIZE_CHECK} == 0")
  if (( DB_SIZE_CHECK == 1 ))
  then
    SIZE="0"
    CONSUMED_SPACE="0"
  else
    SIZE=$(echo "${var}" | tr -s " " | rev | cut -d " " -f2,3 | rev)
    CONSUMED_SPACE=$(echo "${var}" | tr -s " " | rev | cut -d " " -f4,5 | rev)
  fi
  env printf "%-30s\t%-15s\t%-50s\t%-10s\t%s\n" "$(date)" "${WAREHOUSE}" "${DB_NAME}" "${SIZE}" "${CONSUMED_SPACE}" >> "${OUTPUT_PATH}/${OUTPUT_FILE}"
done
