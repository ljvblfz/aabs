#!/bin/bash
# $1: output_dir

function remove_internal_apps()
{
  cd $OUTPUT_DIR/source/vendor/marvell/generic/apps
  subdirs=$(find -maxdepth 1 -type d)
  for dir in $subdirs
  do
    if [[ $dir == "." ]] || [[ $dir == ".." ]]; then
      continue
    fi
    rm -fr $dir
  done
  cd - >/dev/null
}

OUTPUT_DIR=$1

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "output dir ($OUTPUT_DIR): doesn't exist"
  exit 1
fi
PKGSRC_EXCLUDE=./.git

cd $OUTPUT_DIR/source &&
echo "  packaging kernel source code:" &&
tar czf kernel_src.tgz --exclude=$PKGSRC_EXCLUDE kernel/ &&
mv kernel_src.tgz $OUTPUT_DIR &&
rm -fr kernel &&

echo "  packaging android source code:" &&
remove_internal_apps &&
cd $OUTPUT_DIR &&
tar czf droid_src.tgz --exclude=$PKGSRC_EXCLUDE source/
