#!/usr/bin/bash
#
# this script requires mu2etools, mu2efiletools and dhtools be setup
# It also requires the SimEfficiencies for the beam campaign be entered in the database
# $1 is the name of the primary (ie CeEndpoint, etc).
# $2 is the dataset description
# $3 is the campaign version of the input (primary) file
# $4 is the campaign version of the output (digi) file.
# $5 is the number of input collections to merge (merge factor)
# $6 is the digitization type (OnSpill, OffSpill, NoField, Extracted)
# $7 is the database version
primary=$1
name=$primary.$2$3
conf=$2$4
merge=$5
digitype=$6
digout=${primary}${digitype}
dbpurpose=$2_DIGI
dbver=$7
#
#NoField and Extracted require consistency with the primary
#
usage() { echo "Usage:
  source Production/Scripts/gen_Digitize.sh [primaryName] [datasetDescription] \
    [primary version] [output version] [nmerge] [digitype] [database version]

  This script will produce the fcl files needed for a digitization stage. You must provide in order:
  - the name of the primary [primaryName]
  - the dataset description [datasetDescription],
  - the campaign version of the input file [campaignInput],
  - the campaign version of the output file [campaignOutput],
  - the database version
  Example:
  gen_Digitize.sh CeEndpoint MDC2020 k m 1 OnSpill v2_0
  This will produce the fcl files for digitizing CeEndpoint primaries
  from MDC2020m according to onspill timing, using v2_0 of the database for digitization parameters"
}

if [[ $# -lt 7 ]] ; then
  usage
  return 1
fi

if [[ "${digitype}" == "Extracted" || "${digitype}" == "NoField" ]]; then
  if [[ "${primary}" != *"${digitype}"* ]]; then
    echo "Primary ${primary} doesn't match digitization type ${digitype}; aborting"
    return 1
  else
    # no need for redundant labels
    digout=$primary
  fi
else
  if [[ "${primary}" == *"Extracted"* || "${primary}" == *"NoField"* ]]; then
    echo "Primary ${primary} incompatible with digitization type ${digitype}; aborting"
    return 1
  fi
fi
echo "Generating digitization scripts for $primary conf $conf output $digout database puppose, version $dbpurpose, $dbver"

rm digitize.fcl
samweb list-file-locations --schema=root --defname="dts.mu2e.${name}.art"  | cut -f1 > $name.txt
echo \#include \"Production/JobConfig/digitize/Digitize.fcl\" >> digitize.fcl
echo \#include \"Production/JobConfig/digitize/${digitype}.fcl\" >> digitize.fcl
# turn off streams according to the digitization type.
if [[ "${digitype}" == "Extracted" || "${digitype}" == "NoField" ]]; then
  echo outputs.TrkOutput.fileName: \"dig.owner.${digout}Trk.version.sequencer.art\" >> digitize.fcl
  echo outputs.CaloOutput.fileName: \"dig.owner.${digout}Calo.version.sequencer.art\" >> digitize.fcl
  echo outputs.UntriggeredOutput.fileName: \"dig.owner.${digout}Untriggered.version.sequencer.art\" >> digitize.fcl
else
  # keep all streams
  echo outputs.SignalOutput.fileName: \"dig.owner.${digout}Signal.version.sequencer.art\" >> digitize.fcl
  echo outputs.DiagOutput.fileName: \"dig.owner.${digout}Diag.version.sequencer.art\" >> digitize.fcl
  echo outputs.TrkOutput.fileName: \"dig.owner.${digout}Trk.version.sequencer.art\" >> digitize.fcl
  echo outputs.CaloOutput.fileName: \"dig.owner.${digout}Calo.version.sequencer.art\" >> digitize.fcl
  echo outputs.UntriggeredOutput.fileName: \"dig.owner.${digout}Untriggered.version.sequencer.art\" >> digitize.fcl
fi
# setup database access for digi parameters
echo services.DbService.purpose: $dbpurpose >> digitize.fcl
echo services.DbService.version: $dbver >> digitize.fcl
echo services.DbService.verbose : 1 >> digitize.fcl

generate_fcl --dsconf="$conf" --dsowner=mu2e --description="${digout}Digi" --embed digitize.fcl \
  --inputs="$name.txt" --merge-factor=$merge
for dirname in 000 001 002 003 004 005 006 007 008 009; do
  if test -d $dirname; then
    echo "found dir $dirname"
    rm -rf "${digout}_$dirname"
    echo "moving $dirname to ${digout}_${dirname}"
    mv $dirname "${digout}_$dirname"
  fi
done

