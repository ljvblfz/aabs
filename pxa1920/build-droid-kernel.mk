#check if the required variables have been set.
$(call check-variables, ABS_SOC ABS_DROID_BRANCH)

include $(ABS_SOC)/tools-list.mk

MY_SCRIPT_DIR:=$(ABS_TOP_DIR)/$(ABS_SOC)

DROID_TYPE:=release

ifneq ($(PLATFORM_ANDROID_VARIANT),)
       DROID_VARIANT:=$(PLATFORM_ANDROID_VARIANT)
else
       DROID_VARIANT:=userdebug
endif

KERNELSRC_TOPDIR:=kernel
DROID_OUT:=out/target/product

MAKE_EXT4FS := out/host/linux-x86/bin/make_ext4fs
MKBOOTFS := out/host/linux-x86/bin/mkbootfs
MINIGZIP := out/host/linux-x86/bin/minigzip

define define-clean-droid-kernel-target
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY:clean_droid_kernel_$$(product)
clean_droid_kernel_$$(product): clean_droid_$$(product) clean_kernel_$$(product)

.PHONY:clean_droid_$$(product)
clean_droid_$$(product): private_product:=$$(product)
clean_droid_$$(product): private_device:=$$(device)
clean_droid_$$(product):
	$(log) "clean android ..."
	$(hide)cd $(SRC_DIR) && \
	source ./build/envsetup.sh &&
	chooseproduct $(private_product) && choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	make clean
	$(log) "    done"

.PHONY:clean_kernel_$$(product)
clean_kernel_$$(product): private_product:=$$(product)
clean_kernel_$$(product): private_device:=$$(device)
clean_kernel_$$(product):
	$(log) "clean kernel ..."
	$(hide)cd $(SRC_DIR)/$(KERNELSRC_TOPDIR) && make clean
	$(log) "    done"
endef

#we need first build the android, so we get the root dir 
# and then we build the kernel images with the root dir and get the package of corresponding modules
# and then we use those module package to build corresponding android package.

define define-build-droid-kernel-target
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY:build_droid_kernel_$$(product)
build_droid_kernel_$$(product): build_droid_$$(product) build_droid_otapackage_$$(product)
endef

export KERNEL_TOOLCHAIN_PREFIX
export MAKE_JOBS

#$1:kernel_config
#$2:build variant
define define-build-kernel-target
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY: build_kernel_$$(product)

#make sure that PUBLISHING_FILES_XXX is a simply expanded variable
PUBLISHING_FILES2+=$$(product)/uImage:./$$(product)/debug/:m:md5
build_kernel_$$(product): private_product:=$$(product)
build_kernel_$$(product): private_device:=$$(device)
build_kernel_$$(product): output_dir
	$(log) "[$$(private_product)]starting to build kernel ..."
	$(hide)cd $(SRC_DIR) && \
	source ./build/envsetup.sh && \
	chooseproduct $$(private_product) && choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	cd $(SRC_DIR)/$(KERNELSRC_TOPDIR) && \
	make kernel
	$(log) "[$$(private_product)]starting to build modules ..."
	$(hide)cd $(SRC_DIR) && \
	source ./build/envsetup.sh && \
	chooseproduct $$(private_product) && choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	cd $(SRC_DIR)/$(KERNELSRC_TOPDIR) && \
	make modules
	$(hide)mkdir -p $(OUTPUT_DIR)/$$(private_product)
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/kernel/uImage $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/kernel/vmlinux $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/kernel/System.map $(OUTPUT_DIR)/$$(private_product)/
	$(hide)if [ -d $(OUTPUT_DIR)/$$(private_product)/modules ]; then rm -fr $(OUTPUT_DIR)/$$(private_product)/modules; fi &&\
	mkdir -p $(OUTPUT_DIR)/$$(private_product)/modules
	$(hide)cp -af $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/kernel/modules  $(OUTPUT_DIR)/$$(private_product)/

	$(hide)if [ -d $(OUTPUT_DIR)/$$(private_product)/dtb ]; then rm -fr $(OUTPUT_DIR)/$$(private_product)/dtb; fi &&\
	mkdir -p $(OUTPUT_DIR)/$$(private_product)/dtb
	$(hide)cp -af $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/*.dtb  $(OUTPUT_DIR)/$$(private_product)/dtb/

	$(log) "  done."
endef

##!!## build rootfs for android, make -j4 android, copy root, copy ramdisk/userdata/system.img to outdir XXX
#$1:build variant
define define-build-droid-target
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY: build_droid_$$(product)
build_droid_$$(product): private_product:=$$(product)
build_droid_$$(product): private_device:=$$(device)
build_droid_$$(product): 
	$(log) "[$$(private_product)] building android source code ..."
	$(hide)if [ -d $(SRC_DIR)/$(DROID_OUT)/$$(private_device) ]; then rm -fr $(SRC_DIR)/$(DROID_OUT)/$$(private_device); fi
	mkdir -p $(OUTPUT_DIR)/$$(private_product)
	$(hide)cd $(SRC_DIR) && \
	source ./build/envsetup.sh && \
	chooseproduct $$(private_product) && choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	make -j$$(MAKE_JOBS) && \
	tar zcf $(OUTPUT_DIR)/$$(private_product)/symbols_system.tgz -C $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ symbols

	$(hide)if [ -d $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/debug_kmodules ]; then tar zcf $(OUTPUT_DIR)/$$(private_product)/modules.tgz -C $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/debug_kmodules/lib modules; fi
	$(hide)if [ -d $(OUTPUT_DIR)/$$(private_product)/root ]; then rm -fr $(OUTPUT_DIR)/$$(private_product)/root; fi
	$(hide)echo "  copy root directory ..." 
	$(hide)mkdir -p $(OUTPUT_DIR)/$$(private_product)
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/root $(OUTPUT_DIR)/$$(private_product)
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ramdisk.img $(OUTPUT_DIR)/$$(private_product)
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ramdisk-recovery.img ]; then \
	cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ramdisk-recovery.img $(OUTPUT_DIR)/$$(private_product); \
	else \
	cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ramdisk.img $(OUTPUT_DIR)/$$(private_product)/ramdisk-recovery.img; fi
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/userdata.img $(OUTPUT_DIR)/$$(private_product)
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/userdata_4g.img ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/userdata_4g.img $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/userdata_8g.img ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/userdata_8g.img $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/primary_gpt_8g ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/primary_gpt_8g $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/secondary_gpt_8g ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/secondary_gpt_8g $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/system.img $(OUTPUT_DIR)/$$(private_product)
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/system/build.prop $(OUTPUT_DIR)/$$(private_product)
	$(hide)if [ -d $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/telephony/ ]; then \
	cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/telephony/* $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -d $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/security/ ]; then \
	cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/security/* $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -d $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/blf/ ]; then \
	cp -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/blf $(OUTPUT_DIR)/$$(private_product)/; fi

	$(hide)if [ -d $(OUTPUT_DIR)/$$(private_product)/dtb ]; then rm -fr $(OUTPUT_DIR)/$$(private_product)/dtb; fi &&\
	mkdir -p $(OUTPUT_DIR)/$$(private_product)/dtb
	$(hide)cp -af $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/*.dtb  $(OUTPUT_DIR)/$$(private_product)/dtb/

	$(hide)find  $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ -iname radio*img |xargs -i cp {} $(OUTPUT_DIR)/$$(private_product)
	$(hide)find  $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ -iname *gpt* |xargs -i cp {} $(OUTPUT_DIR)/$$(private_product)
	$(log) "  done"

	$(hide)if [ "$(PLATFORM_ANDROID_VARIANT)" = "user" ]; then \
	sed -i "s/ro.secure=1/ro.secure=0/" $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/root/default.prop  && \
	sed -i "s/ro.debuggable=0/ro.debuggable=1/" $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/root/default.prop  && \
	cd $(SRC_DIR)/$(DROID_OUT)/$$(private_device) && \
	$(SRC_DIR)/$(MKBOOTFS) root | $(SRC_DIR)/$(MINIGZIP) > ramdisk-rooted.img && \
	cat ramdisk-rooted.img < /dev/zero | head -c 1048576 > ramdisk-rooted.img.pad && \
	cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/ramdisk-rooted.img.pad $(OUTPUT_DIR)/$$(private_product)/ramdisk-rooted.img && \
	touch $(OUTPUT_DIR)/product_mode_build.txt; fi
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/obm*bin $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/uImage $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/zImage $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/boot.img $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/recovery.img $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/vmlinux $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/System.map $(OUTPUT_DIR)/$$(private_product)/
	$(hide)cp $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/Software_Downloader.zip $(OUTPUT_DIR)/
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/u-boot.bin ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/u-boot.bin $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/WTM.bin ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/WTM.bin $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/HLN2_NonTLoader_eMMC_DDR.bin ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/HLN2_NonTLoader_eMMC_DDR.bin $(OUTPUT_DIR)/$$(private_product)/; fi
	$(hide)if [ -e $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/Software_Downloader_Helan2.zip ]; then cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/Software_Downloader_Helan2.zip $(OUTPUT_DIR)/; fi
	$(hide)if [ -d $(OUTPUT_DIR)/$$(private_product)/modules ]; then rm -fr $(OUTPUT_DIR)/$$(private_product)/modules; fi &&\
	mkdir -p $(OUTPUT_DIR)/$$(private_product)/modules
	$(hide)cp -af $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/root/lib/modules  $(OUTPUT_DIR)/$$(private_product)/


##!!## first time publish: all for two
PUBLISHING_FILES2+=Software_Downloader.zip:./:m:md5
PUBLISHING_FILES2+=Software_Downloader_Helan2.zip:./:o:md5
PUBLISHING_FILES2+=$$(product)/WTM.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HLN2_NonTLoader_eMMC_DDR.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/obm.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/obm_auto.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/obm_trusted_tz.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/obm_trusted_ntz.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/u-boot.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/boot.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/recovery.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/uImage:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/zImage:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/vmlinux:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/System.map:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/primary_gpt_4g:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/secondary_gpt_4g:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/primary_gpt:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/secondary_gpt:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/userdata.img:./$$(product)/flash/:m:md5
PUBLISHING_FILES2+=$$(product)/userdata_4g.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/userdata_8g.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/primary_gpt_8g:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/secondary_gpt_8g:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/system.img:./$$(product)/flash/:m:md5
PUBLISHING_FILES2+=$$(product)/ramdisk.img:./$$(product)/debug/:m:md5
PUBLISHING_FILES2+=$$(product)/ramdisk-rooted.img:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/symbols_system.tgz:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/ramdisk-recovery.img:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/build.prop:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/modules.tgz:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=product_mode_build.txt:./$$(product)/debug/:o

##!!## blf files
#PUBLISHING_FILES2+=$$(product)/blf:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/blf/*:./$$(product)/flash/:o:md5

##!!## dtb files
PUBLISHING_FILES2+=$$(product)/dtb:./$$(product)/debug/:o:md5

##!!## security image
PUBLISHING_FILES2+=$$(product)/tee_tw.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/teesst.img:./$$(product)/flash/:o:md5

PUBLISHING_FILES2+=$$(product)/radio.img:./$$(product)/flash/:o:md5

PUBLISHING_FILES2+=$$(product)/nvm-wb.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/nvm-td.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/nvm.img:./$$(product)/flash/:o:md5

PUBLISHING_FILES2+=$$(product)/HL_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/EM_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/EM_CP_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/EM_CP_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/EM_M08_AI_Z1_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_M08_AI_Z1_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/KL_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/KL_CP_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/KL_CP_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/KUNLUN_Z0_M14_AI_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/KUNLUN_A0_M15_AI_Flash.bin:./$$(product)/flash/:o:md5

PUBLISHING_FILES2+=$$(product)/KUNLUN_Arbel.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/KUNLUN_Arbel_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/KUNLUN_Arbel_NVM.mdb:./$$(product)/debug/:o:md5

PUBLISHING_FILES2+=$$(product)/HL_TD_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_TD_CP_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_TD_CP_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_TD_M08_AI_A0_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/radio-helan-td.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HELAN_A0_M16_AI_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_WB_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_WB_CP_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_WB_CP_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HLWT_TD_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HLWT_TD_CP_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HLWT_TD_CP_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HLWT_TD_M08_AI_A0_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/nvm-helan-wb.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/nvm-helan-wt.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/radio-helan-wb.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/radio-helan-wt.img:./$$(product)/flash/:o:md5

PUBLISHING_FILES2+=$$(product)/TABLET_CP.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/TABLET_MSA.bin:./$$(product)/flash/:o:md5

PUBLISHING_FILES2+=$$(product)/radio-helanlte-ltg.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_DL_M09_Y0_AI_SKL_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_DL.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/nvm-helanlte-ltg.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_DL_M09_Y0_AI_SKL_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_DL_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_DL_DKB.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_DL_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LWG_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LWG_DKB.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LWG_M09_B0_SKL_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LWG_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/nvm-helanlte.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Skylark_LTG.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Skylark_LWG.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/radio-helanlte.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_SS_M09_Y0_AI_SKL_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_SL_DKB_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_SL_DKB.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/HL_LTG_SL_DKB_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/Skylark_LTG_V11.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Skylark_LTG_V13.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Skylark_LWG_V11.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Skylark_LWG_V13.bin:./$$(product)/flash/:o:md5


PUBLISHING_FILES2+=$$(product)/WK_CP_2CHIP_SPRW_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/WK_CP_2CHIP_SPRW_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/Boerne_DIAG.mdb.txt:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/ReliableData.bin:./$$(product)/flash/:o:md5
ifeq ($(product),pxa988dkb_def)
PUBLISHING_FILES2+=$$(product)/Arbel_DIGRF3_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/Arbel_DIGRF3.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Arbel_DIGRF3_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/Arbel_DKB_SKWS.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/Arbel_DKB_SKWS_NVM.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/Arbel_DKB_SKWS_DIAG.mdb:./$$(product)/debug/:o:md5
PUBLISHING_FILES2+=$$(product)/TTD_M06_AI_A0_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/TTD_M06_AI_A1_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/TTD_M06_AI_Y0_Flash.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/WK_CP_2CHIP_SPRW.bin:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/WK_M08_AI_Y1_removelo_Y0_Flash.bin:./$$(product)/flash/:o:md5
endif
endef

ifeq ($(ABS_DROID_BRANCH),lpre)
define define-build-droid-otapackage
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY: build_droid_otapackage_$$(product)
build_droid_otapackage_$$(product): private_product:=$$(product)
build_droid_otapackage_$$(product): private_device:=$$(device)
build_droid_otapackage_$$(product):
	$(log) "[$$(private_product)] no android OTA package build ..."
endef
else
define define-build-droid-otapackage
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY: build_droid_otapackage_$$(product)
build_droid_otapackage_$$(product): private_product:=$$(product)
build_droid_otapackage_$$(product): private_device:=$$(device)
build_droid_otapackage_$$(product): 
	$(log) "[$$(private_product)] building android OTA package ..."
	$(hide)cd $(SRC_DIR) && \
	source ./build/envsetup.sh && \
	chooseproduct $$(private_product) && choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	make mrvlotapackage
	$(hide)echo "  copy OTA package ..."

	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/$$(private_product)-ota-mrvl.zip $(OUTPUT_DIR)/$$(private_product)
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/$$(private_product)-ota-mrvl-recovery.zip $(OUTPUT_DIR)/$$(private_product)
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/obj/PACKAGING/target_files_intermediates/$$(private_product)-target_files*.zip $(OUTPUT_DIR)/$$(private_product)/$$(private_product)-ota-mrvl-intermediates.zip
	$(log) "  done for OTA package build."

PUBLISHING_FILES2+=$$(product)/$$(product)-ota-mrvl.zip:./$$(product)/ota/:o:md5
PUBLISHING_FILES2+=$$(product)/$$(product)-ota-mrvl-recovery.zip:./$$(product)/ota/:o:md5
PUBLISHING_FILES2+=$$(product)/$$(product)-ota-mrvl-intermediates.zip:./$$(product)/ota/:o:md5
PUBLISHING_FILES2+=$$(product)/target_files-package.zip:./$$(product)/ota/:o:md5

endef
endif

define define-build-droid-tool
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
.PHONY: build_droid_tool_$$(product)
build_droid_tool_$$(product): private_product:=$$(product)
build_droid_tool_$$(product): private_device:=$$(device)
build_droid_tool_$$(product): build_droid_$$(product)
	$(log) "[$$(private_product)] rebuilding android source code with eng for tools ..."
	$(hide)cd $(SRC_DIR) && \
	source ./build/envsetup.sh && \
	chooseproduct $$(private_product) && choosetype $(DROID_TYPE) && choosevariant eng && \
	make -j8
	$(hide)if [ -d $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools ]; then rm -fr $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools; fi
	$(hide)echo "  copy and make tools image ..."
	$(hide)mkdir -p $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools/bin
	$(hide)cd $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/symbols/system && \
	cp -af $(TOOLS_LIST) $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools/bin
	$(hide)$(SRC_DIR)/$(MAKE_EXT4FS) -s -l 65536k -b 1024 -L tool $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools.img $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools
	$(hide)cp -p -r $(SRC_DIR)/$(DROID_OUT)/$$(private_device)/tools.img $(OUTPUT_DIR)/$$(private_product)/
	tar zcvf $(OUTPUT_DIR)/$$(private_product)/tools.tgz -C $(SRC_DIR)/$(DROID_OUT)/$$(private_device) tools

PUBLISHING_FILES2+=$$(product)/tools.img:./$$(product)/flash/:o:md5
PUBLISHING_FILES2+=$$(product)/tools.tgz:./$$(product)/flash/:o:md5

endef

$(foreach bv,$(ABS_BUILD_DEVICES), $(eval $(call define-build-droid-kernel-target,$(bv)) )\
				$(eval $(call define-build-kernel-target,$(bv)) ) \
				$(eval $(call define-build-droid-target,$(bv)) ) \
				$(eval $(call define-clean-droid-kernel-target,$(bv)) ) \
				$(eval $(call define-build-droid-otapackage,$(bv)) ) \
)
