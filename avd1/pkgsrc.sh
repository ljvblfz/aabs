#!/bin/bash
# $1: output_dir
# assuming the source code locates at <output_dir>/source

OUTPUT_DIR=$1

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "output dir ($OUTPUT_DIR): doesn't exist"
  exit 1
fi

EXCLUDE_VCS="--exclude-vcs --exclude=.repo"

cd $OUTPUT_DIR/source &&
(
  echo "  packaging kernel source code:" &&
  cd kernel &&

  tar czf kernel_src.tgz $EXCLUDE_VCS kernel/ &&
  mv kernel_src.tgz $OUTPUT_DIR &&

  echo "   copy gc600 driver source code: " &&
  cp -p -r ../vendor/marvell/generic/gc600 . &&
  echo "   copy bmm driver source code: " &&
  cp -p -r ../vendor/marvell/generic/bmm-lib . &&
  echo "   copy usb8786 driver source code: " &&
  cp -p -r ../vendor/marvell/generic/usb8786 . &&

  tar czf drivers_src.tgz $EXCLUDE_VCS gc600/ bmm-lib/ usb8786/ &&
  mv drivers_src.tgz $OUTPUT_DIR &&

  cd - &&
  rm -fr kernel &&

#  echo "  packaging uboot and obm source code:" &&
#  tar czf boot_src.tgz $EXCLUDE_VCS boot/ &&
#  mv boot_src.tgz $OUTPUT_DIR &&
#  rm -fr boot &&
   echo 
) &&

echo "  packaging android source code:" &&
  rm -fr $OUTPUT_DIR/source/vendor/marvell/generic/apps &&
  rm -fr $OUTPUT_DIR/source/vendor/marvell/external/helix &&
  rm -fr $OUTPUT_DIR/source/vendor/marvell/external/flash &&

cd $OUTPUT_DIR &&
tar czf droid_src.tgz $EXCLUDE_VCS source/
