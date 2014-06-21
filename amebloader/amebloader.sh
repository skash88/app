#!/bin/bash
#
#   Aebloader - Ameba blog downloader

get_entry() {
    blog_top_url=$1
    entry_num=$2
    if [ -f $entry_num/download_completed ]; then
	echo "Entry $entry_num is already downloaded"
	return
    fi
    echo "Downloading entry $entry_num.."
    mkdir -p $entry_num
    cd $entry_num
    wget --recursive \
	--level 3 \
	--no-directories \
	--convert-links \
	--random-wait \
	--no-verbose \
	--page-requisites \
	--span-hosts \
	--accept-regex "($blog_top_url/(entry|image)-$entry_num)|user_images" \
	$blog_top_url/entry-$entry_num.html

    for image_file in image-*.html ; do
	get_image_file $image_file
	update_entry_image entry-$entry_num.html $image_file 
    done
    touch download_completed
    cd ..
}

get_image_file() {
    image_file=$1
    image_url=$( perl -ne '/(.*current.*),$/ && print qq<{$1}>' $image_file \
	| jq .current.imgList[].imgUrl \
	| perl -pe 's/"(.*)"/http:\/\/stat001.ameba.jp$1/' )
    wget --no-verbose $image_url
}

update_entry_image() {
    entry_file=$1
    image_file=$2
    image_num=$(echo $image_file | perl -pe 's/image-(\d+)-(\d+).html/$2/')
		 big_jpg_file=$(ls o*$image_num.jpg)
    if [ "$big_jpg_file" ]; then
	echo Replacing $image_file with $big_jpg_file ..
	perl -i.orig -pe "s/$image_file/$big_jpg_file/g" $entry_file
    else
	echo 'No big jpeg file found'
    fi
}

get_entries() {
    blog_top_url=$1
    year=$2
    month=$3
    entrylist_file=$4

    echo "Parsing $entrylist_file"
    entry_nums=$(perl -nle 'm|contentTitle.*entry-(\d+).html| && print qq{$1\n}' \
	$entrylist_file | sort | uniq)

    for entry_num in $entry_nums; do
	get_entry $blog_top_url $entry_num
    done
}

get_archive_entry_lists() {
    blog_top_url=$1
    year=$2
    month=$3

    echo "Get archive entry lists for $year/$month"
    mkdir -p $year/$month
    cd $year/$month

    wget --recursive \
	--level 10 \
	--random-wait \
	--convert-links \
	--no-host-directories --cut-dirs=1\
	--no-verbose \
	--accept-regex "^$blog_top_url/archiveentrylist-$year$month" \
	${blog_top_url}/archiveentrylist-${year}${month}.html 

    for archive_entry_list_file in archiveentrylist-${year}${month}* ; do
	get_entries $blog_top_url $year $month $archive_entry_list_file
    done

    cd ../..
}

get_all_archive() {
    blog_top_url=$1

    for year in {2010..2014}; do
	for month in 01 02 03 04 05 06 07 08 09 10 11 12 ; do
	    get_archive_entry_lists $blog_top_url $year $month
	done
    done
}

blog_top_url=$1
mkdir -p data
cd data
get_all_archive $blog_top_url

