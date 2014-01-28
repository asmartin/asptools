#!/bin/bash
###############################################################################
# Title:	asp2ps: Aftershot Pro to WINE Photoshop Launcher
# Date:		1/26/14
# Author: 	Andrew Martin <amartin@avidandrew.com>
# Depend: 	Y: drive in wine prefix must point to / (root of linux filesystem)
# 		lib32-lcms zenity wine
###############################################################################
export WINEPREFIX=/path/to/your/wine/prefix
export PHOTOSHOP_VERSION=5.1
RAW_FILETYPE_UPPERCASE=CR2
RAW_FILETYPE_LOWERCASE=$(echo "$RAW_FILETYPE_UPPERCASE" | tr '[:upper:]' '[:lower:]')
file="$1"		# the file to open in Photoshop
debug=0			# set to 1 to enable debug output to $debug_log
debug_log=/tmp/debug	# path to the debug log file

# Zenity menu options
cr2xmp="$RAW_FILETYPE_UPPERCASE + XMP"
cr2="$RAW_FILETYPE_UPPERCASE"
tiff="TIFF"

# Write the header to the specified file
# $1 filename to append to
function writeHeader() {
cat << EOF > $1
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Adobe XMP Core 5.2-c004 1.136881, 2010/06/10-18:11:35        ">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/">
   <photoshop:SidecarForExtension>$RAW_FILETYPE_UPPERCASE</photoshop:SidecarForExtension>
  </rdf:Description>
  <rdf:Description rdf:about=""
    xmlns:crs="http://ns.adobe.com/camera-raw-settings/1.0/">
   <crs:Version>6.3</crs:Version>
EOF
}

# Write the footer to the specified file
# $1 filename to append to
function writeFooter() {
cat << EOF >> $1
   <crs:HasSettings>True</crs:HasSettings>
  </rdf:Description>
 </rdf:RDF>
</x:xmpmeta>
EOF
}

# writes debug messages to a debug log file
# $1 the message to write
function log() {
	if [ $debug -ne 0 ]; then
		echo "$*" >> $debug_log
	fi
}

# gets the value from inside the ASP tag
# $1 name of ASP attribute
# $2 ASP raw file (source)
function getXMPValue() {
	grep -oPm1 "(?<=bopt:$1=\")[^\"]+" $2
}

# evaluates a math expression and returns the integer format
function convertValue() {
	decimal=$(echo "scale=2; $1" | bc)
	log "expression: $1 = $decimal"
	echo "$decimal"
}

# converts ASP metadata values to Photoshop metadata in these steps:
#   - get XMP value from ASP XMP File
#   - converts value to PS scale (if necessary)
#   - echos PS tag with PS value
function asp2ps() {
	src="$2"
	case $1 in
		temp)		aspval=$(getXMPValue "kelvin" "$src")
				# no conversion needed
				echo "<crs:Temperature>$aspval</crs:Temperature>"
				;;
		tint)   	aspval=$(getXMPValue "tint" "$src")
				# no conversion needed
				echo "<crs:Tint>$aspval</crs:Tint>"
				;;
		exposure)	aspval=$(getXMPValue "exposureval" "$src")
				# no conversion needed
				echo "<crs:Exposure>$aspval</crs:Exposure>"
				;;
		highlights)	aspval=$(getXMPValue "highlightrecval" "$src")
				# no conversion needed
				echo "<crs:HighlightRecovery>$aspval</crs:HighlightRecovery>"
				;;
		fill)	        aspval=$(getXMPValue "fillamount" "$src")
				psval=$(convertValue "($aspval/2.5)*100")
				echo "<crs:FillLight>$psval</crs:FillLight>"
				;;
		blacks)		aspval=$(getXMPValue "blackPoint" "$src")
				psval=$(convertValue "(($aspval+10)/110)*100")
				echo "<crs:Shadows>$psval</crs:Shadows>"
				;;
		contrast)	aspval=$(getXMPValue "cont" "$src")
				psval=$(convertValue "(($aspval+100)/200*150)-50")
				echo "<crs:Contrast>$psval</crs:Contrast>"
				;;
		saturation)	aspval=$(getXMPValue "sat" "$src")
				# no conversion needed
				echo "<crs:Saturation>$aspval</crs:Saturation>"
				;;
		vibrance)	aspval=$(getXMPValue "vibe" "$src")
				# no conversion needed
				echo "<crs:Vibrance>$aspval</crs:Vibrance>"
				;;
	esac
}

# if a filename was passed (otherwise just launch Photoshop)
if [ $# -gt 0 ]; then

	# prompt for the type of file to pass to Photoshop
	chosen=$(zenity --height=275 --list --radiolist --text 'Select the format to transfer to Photoshop:' --column 'Select...' --column 'Image Format' TRUE "$cr2xmp" FALSE "$cr2" FALSE "$tiff")
	if [ "$chosen" == "$cr2xmp" ] || [ "$chosen" == "$cr2" ]; then
		cr2found=0
		log "try to use $RAW_FILETYPE_UPPERCASE instead of TIFF"
		cr2file=$(readlink -f "$file" | sed "s/_edit.*\.tif$/\.$RAW_FILETYPE_LOWERCASE/g")
		if [ ! -f "$cr2file" ]; then
			log "lowercase $RAW_FILETYPE_LOWERCASE file $cr2file doesn't exist, try the uppercase version"
			cr2file=$(echo "$cr2file" | sed "s/$RAW_FILETYPE_LOWERCASE/$RAW_FILETYPE_UPPERCASE/g")

			if [ ! -f "$cr2file" ]; then
				log "can't find $RAW_FILETYPE_UPPERCASE either ($cr2file), opening TIFF instead"
				zenity --error --text="Can't find the $RAW_FILETYPE_UPPERCASE file, opening TIFF instead..." --title='Error: Cannot Find $RAW_FILETYPE_UPPERCASE'
			else
				cr2found=1
			fi
		else    
			cr2found=1
		fi

		if [ $cr2found -ne 0 ]; then
			if [ "$chosen" == "$cr2xmp" ]; then
				# convert XMP data
				xmpfile="${cr2file}.xmp"
				standardxmp=$(readlink -f "$file" | sed 's/_edit.*\.tif$/\.xmp/g')
				if [ -f "$xmpfile" ]; then
					log "Converting XMP data..."
					log "xmpfile: $xmpfile"
					log "standardxmp: $standardxmp"
					# create temporary file, put standard xmp contents into it (skip last 2 lines since they're the footer)
					tmp=$(mktemp)
					log "temporary file is $tmp"

					# write Photoshop header information
					writeHeader $tmp

					# get each value from ASP XMP file
					tempVal=$(asp2ps temp "$xmpfile")
					tintVal=$(asp2ps tint "$xmpfile")
					exposureVal=$(asp2ps exposure "$xmpfile")
					highlightsVal=$(asp2ps highlights "$xmpfile")
					fillVal=$(asp2ps fill "$xmpfile")
					blacksVal=$(asp2ps blacks "$xmpfile")
					contrastVal=$(asp2ps contrast "$xmpfile")
					saturationVal=$(asp2ps saturation "$xmpfile")
					vibranceVal=$(asp2ps vibrance "$xmpfile")

					# echo out each tag from above
					echo -e "   $tempVal" >> $tmp
					echo -e "   $tintVal" >> $tmp
					echo -e "   $exposureVal" >> $tmp
					echo -e "   $highlightsVal" >> $tmp
					echo -e "   $fillVal" >> $tmp
					echo -e "   $blacksVal" >> $tmp
					echo -e "   $contrastVal" >> $tmp
					echo -e "   $saturationVal" >> $tmp
					echo -e "   $vibranceVal" >> $tmp

					# echo out footer
					writeFooter $tmp

					# replace standard xmp with this modified version (that contains Photoshop tags)
					if [ $debug -ne 0 ]; then
						cp $tmp $standardxmp
					else
						mv $tmp $standardxmp
					fi
				else
					log "Cannot find ASP XMP file ($xmpfile), skipping XMP conversion"
				fi
			fi

			# remove the tiff file
			log "$RAW_FILETYPE_UPPERCASE found ($cr2file), removing the tiff ($file)"
			rm -f "$file"
			file="$cr2file"
		fi
	fi


	# change the file path to be suitable for Photoshop
	file=$(echo "Y:$file" | sed 's/\//\\/g')
	log "File path changed for Windows: $file"
fi

wine $WINEPREFIX/drive_c/Program\ Files\ \(x86\)/Adobe/Adobe\ Photoshop\ CS$PHOTOSHOP_VERSION/Photoshop.exe  "$file"
