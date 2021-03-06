INTERNAL_PROJECTS :=vendor/marvell/external/helix
INTERNAL_PROJECTS +=vendor/marvell/external/flash
INTERNAL_PROJECTS +=vendor/marvell/$(DROID_PRODUCT)/.git
INTERNAL_PROJECTS +=vendor/marvell/$(DROID_PRODUCT)/libsensor/src
#INTERNAL_PROJECTS +=vendor/marvell/generic/apps/CmmbPlayer
#INTERNAL_PROJECTS +=vendor/marvell/generic/apps/CmmbStack
CHECKIN_PREBUILTLIB :=libyamaha_utils

EXCLUDE_VCS=--exclude-vcs --exclude=.repo

UBOOT_BASE_COMMIT:=aced78d852d0b009e8aaa1445af8cb40861ee549
ifeq ($(ANDROID_VERSION),eclair)
	KERNEL_BASE_COMMIT:=8e0ee43bc2c3e19db56a4adaa9a9b04ce885cd84
else
ifeq ($(ANDROID_VERSION),froyo)
	KERNEL_BASE_COMMIT:=f6320db51173e3b94f54b87944b88d3b363c4487
else
ifeq ($(ANDROID_VERSION),gingerbread)
	KERNEL_BASE_COMMIT:=49e8954d66ce9ccf75f951a5adb217209ae6f78f
else
	KERNEL_BASE_COMMIT:=5e4fcd2c556e25e1b6787dcd0c97b06e29e42292
endif
endif
endif

ifeq ($(ANDROID_VERSION),donut)
	DROID_BASE:=shgit/donut-release
else
ifeq ($(ANDROID_VERSION),eclair)
	DROID_BASE:=android-2.1_r2
else
ifeq ($(ANDROID_VERSION),froyo)
	DROID_BASE:=android-2.2.2_r1
else
ifeq ($(ANDROID_VERSION),gingerbread)
	DROID_BASE:=android-2.3.7_r1
else
	DROID_BASE:=android-4.0.3_r1
endif
endif
endif
endif

.PHONY:pkgsrc
pkgsrc: output_dir get_source_for_pkg
	$(hide)echo "  save project list"
	$(hide)cd $(OUTPUT_DIR)/source && repo forall -c "echo -n \$$(pwd):;echo \$$REPO_PROJECT" > $(OUTPUT_DIR)/prjlist

	$(hide)echo "  remove internal source code..."
	$(hide)cd $(OUTPUT_DIR)/source && for prj in $(INTERNAL_PROJECTS); do rm -fr $$prj; done

	$(hide)echo "  check in prebuilt libs..."
	$(hide)mkdir -p $(OUTPUT_DIR)/source/vendor/marvell/$(DROID_PRODUCT)/libsensor/prebuild/

	$(hide)if [ -f $(SRC_DIR)/out/target/product/$(DROID_PRODUCT)/obj/STATIC_LIBRARIES/$(CHECKIN_PREBUILTLIB)_intermediates/$(CHECKIN_PREBUILTLIB).a ]; then \
	$(hide)cp $(SRC_DIR)/out/target/product/$(DROID_PRODUCT)/obj/STATIC_LIBRARIES/$(CHECKIN_PREBUILTLIB)_intermediates/$(CHECKIN_PREBUILTLIB).a $(OUTPUT_DIR)/source/vendor/marvell/$(DROID_PRODUCT)/libsensor/prebuild/; fi
	$(hide)if [ -f $(SRC_DIR)/out/target/product/$(DROID_PRODUCT)/system/bin/geomagneticd ]; then \
	$(hide)cp $(SRC_DIR)/out/target/product/$(DROID_PRODUCT)/system/bin/geomagneticd $(OUTPUT_DIR)/source/vendor/marvell/$(DROID_PRODUCT)/libsensor/prebuild/; fi
	$(hide)if [ if $(SRC_DIR)/out/target/product/$(DROID_PRODUCT)/system/bin/orientationd ]; then \
	$(hide)cp $(SRC_DIR)/out/target/product/$(DROID_PRODUCT)/system/bin/orientationd $(OUTPUT_DIR)/source/vendor/marvell/$(DROID_PRODUCT)/libsensor/prebuild/; fi

	$(hide)echo "  package all source code..."
	$(hide)cd $(OUTPUT_DIR) && tar czf droid_all_src.tgz $(EXCLUDE_VCS) source/

	$(hide)echo "  package kernel source code..."
	$(hide)cd $(OUTPUT_DIR) && $(ABS_TOP_DIR)/core/gen_kernel_src_patch.sh $(KERNEL_BASE_COMMIT)

	$(hide)echo "  package uboot obm source code..."
	$(hide)cd $(OUTPUT_DIR) && $(ABS_TOP_DIR)/core/gen_uboot_obm_src_patch.sh $(UBOOT_BASE_COMMIT)

	$(hide)echo "  package android source code..."
	$(hide)cd $(OUTPUT_DIR) && $(ABS_TOP_DIR)/core/gen_droid_src_patch.sh $(DROID_BASE) $(ABS_TOP_DIR)/core

	$(hide)cp $(ABS_TOP_DIR)/core/setup_android.sh $(OUTPUT_DIR)
	$(hide)cp $(BOARD)/ReleaseNotes-$(ANDROID_VERSION).txt $(OUTPUT_DIR)/ReleaseNotes.txt
	$(log) "  done."


#format: <file name>:[m|o]:[md5]
#m:means mandatory
#o:means optional
#md5: need to generate md5 sum
PUBLISHING_FILES+=droid_all_src.tgz:o:md5 
PUBLISHING_FILES+=android_src.tgz:m:md5 
PUBLISHING_FILES+=android_patches.tgz:m:md5 
PUBLISHING_FILES+=kernel_src.tgz:m:md5 
PUBLISHING_FILES+=kernel_patches.tgz:m:md5 
PUBLISHING_FILES+=uboot_src.tgz:m:md5 
PUBLISHING_FILES+=uboot_patches.tgz:m:md5 
PUBLISHING_FILES+=obm_src.tgz:m:md5 
PUBLISHING_FILES+=marvell_manifest.xml:m
PUBLISHING_FILES+=setup_android.sh:m
PUBLISHING_FILES+=ReleaseNotes.txt:m

