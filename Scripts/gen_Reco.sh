#!/usr/bin/bash

# this script requires mu2etools and dhtools be setup
# $1 is the name of the digi (ie CeEndpointMixTriggered, etc) file.
# $2 is the dataset description (ie MDC2020).
# $3 is the campaign version of the input (digi) file.
# $4 is the campaign version of the output (reco) file.
# $5 is the database purpose
# $6 is the database version
# $7 is the number of input collections to merge (merge factor)

if [[ $# -eq 0 ]] ; then
    usage='Usage:
gen_Reco.sh [primaryName] [datasetDescription] [digiInput] \
           [recoOutput] [purpose] [version] [mergeFactor]

This script will produce the fcl files needed for a mixing stage. It
is necessary to provide, in order:
- the name of the primary [primaryName]
- the dataset description [datasetDescription],
- the campaign version of the input digi file [digiInput],
- the campaign version of the output reco file [recoOutput],
- the name of the DB purpose (perfect, best, startup) [purpose]
- the DB version [version]
- the number of input collections to merge into 1 output [mergeFactor]

Example:
    gen_Reco.sh CeEndpointMixTriggered MDC2020 k m perfect v1_0 10

This will produce the fcl files for a reco stage
on CeEndpointMixTriggered digis, merging 10 inputs per output. The output
files will have the MDC2020m description.'
    echo "$usage"
    exit 0
fi
samweb list-file-locations --schema=root --defname="dig.mu2e.$1.$2$3.art"  | cut -f1 > Digis.txt

echo '#include "Production/JobConfig/reco/Reco.fcl"' > template.fcl
echo 'services.DbService.purpose:' $5 >> template.fcl
echo 'services.DbService.version:' $6 >> template.fcl

generate_fcl --dsowner=mu2e --override-outputs --auto-description --embed template.fcl --dsconf "$2$4_$5_$6" \
--inputs "Digis.txt" --merge-factor=$7

for dirname in 000 001 002 003 004 005 006 007 008 009; do
 if test -d $dirname; then
  echo "found dir $dirname"
  rm -rf $1Reco$4_$dirname
  mv $dirname $1Reco$4_$dirname
 fi
done

