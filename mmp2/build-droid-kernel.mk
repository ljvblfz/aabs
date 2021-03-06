#check if the required variables have been set.
#$(call check-variables,BUILD_VARIANTS)

#
# Include goal for build UBoot and obm
#
include $(ABS_SOC)/build-uboot-obm.mk

DROID_TYPE:=release
KERNELSRC_TOPDIR:=kernel

define define-clean-droid-kernel
tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

.PHONY:clean_droid_kernel_$$(product)
clean_droid_kernel_$$(product): clean_droid_$$(product)
clean_droid_kernel_$$(product): clean_kernel_$$(product)

.PHONY:clean_droid_$$(product)
clean_droid_$$(product): private_product:=$$(product)
clean_droid_$$(product): private_device:=$$(device)
clean_droid_$$(product):
	$(log) "clean android ..."
	$(hide)cd $(SRC_DIR) && \
	. $(ABS_TOP_DIR)/tools/apb $$(private_product) && \
	choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	make clean
	$(log) "    done"

.PHONY:clean_kernel_$$(product)
clean_kernel_$$(product): private_product:=$$(product)
clean_kernel_$$(product): private_device:=$$(device)
clean_kernel_$$(product):
	$(log) "clean kernel ..."
	$(hide)cd $(SRC_DIR)/$(KERNELSRC_TOPDIR) && \
	. $(ABS_TOP_DIR)/tools/apb $$(private_product) && \
	choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	make clean
	$(log) "    done"
endef

#$1:build device
define define-build-droid-kernel
tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

build_droid_kernel_$$(product): build_kernel_$$(product)
build_droid_kernel_$$(product): build_droid_root_$$(product)
build_droid_kernel_$$(product): build_uboot_obm_$$(product)
build_droid_kernel_$$(product): build_droid_pkgs_$$(product)
endef

#$1:build device
define define-build-droid-root
tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

.PHONY: build_droid_root_$$(product)
build_droid_root_$$(product): private_product:=$$(product)
build_droid_root_$$(product): private_device:=$$(device)
build_droid_root_$$(product): build_kernel_$$(product)
build_droid_root_$$(product): output_dir
	$$(log) "[$$(private_product)]updating the modules..."
	$$(hide)rm -fr $$(OUTPUT_DIR)/$$(private_product)/modules
	$$(hide)mkdir -p $$(OUTPUT_DIR)/$$(private_product)
	$$(hide)cd $$(OUTPUT_DIR)/$$(private_product) && tar xzf modules_android_mmc.tgz
	$$(log) "[$$(private_product)]building android source code ..."
	$$(hide)cd $$(SRC_DIR) && \
	. $$(ABS_TOP_DIR)/tools/apb $$(private_product) && \
	choosetype $$(DROID_TYPE) && choosevariant $$(DROID_VARIANT) && \
	make -j$$(MAKE_JOBS)
	echo "    copy GPT files..." && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/primary_gpt_8g $$(OUTPUT_DIR)/$$(private_product)/ && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/secondary_gpt_8g $$(OUTPUT_DIR)/$$(private_product)
	echo "    copy ramfs files..." && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/ramdisk.img $$(OUTPUT_DIR)/$$(private_product) && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/ramdisk_recovery.img $$(OUTPUT_DIR)/$$(private_product)
	echo "    copy system.img ..." && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/system.img $$(OUTPUT_DIR)/$$(private_product)
	$$(hide)if [ -f $(SRC_DIR)/out/target/product/$$(private_device)/userdata.img ]; then \
		echo "    copy userdata.img ..." && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/userdata.img $$(OUTPUT_DIR)/$$(private_product); \
	fi
	echo "    generating symbols_lib.tgz..." && \
		cp -a $$(SRC_DIR)/out/target/product/$$(private_device)/symbols/system/lib $$(OUTPUT_DIR)/$$(private_product) && \
		cd $$(OUTPUT_DIR)/$$(private_product) && tar czf symbols_lib.tgz lib && rm lib -rf
	$(log) "  done"

PUBLISHING_FILES+=$$(product)/primary_gpt_8g:m:md5
PUBLISHING_FILES+=$$(product)/secondary_gpt_8g:m:md5
PUBLISHING_FILES+=$$(product)/ramdisk.img:m:md5
PUBLISHING_FILES+=$$(product)/ramdisk_recovery.img:m:md5
PUBLISHING_FILES+=$$(product)/system.img:m:md5
PUBLISHING_FILES+=$$(product)/userdata.img:o:md5
PUBLISHING_FILES+=$$(product)/symbols_lib.tgz:o:md5
endef

#$1:build device
define define-build-droid-pkgs
tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

PUBLISHING_FILES+=$$(product)/trusted/update_droid.zip:m:md5
PUBLISHING_FILES+=$$(product)/nontrusted/update_droid.zip:m:md5
PUBLISHING_FILES+=$$(product)/trusted/update_recovery.zip:o:md5
PUBLISHING_FILES+=$$(product)/nontrusted/update_recovery.zip:o:md5

.PHONY:build_droid_pkgs_$$(product)
build_droid_pkgs_$$(product): build_droid_update_pkgs_$$(product)

build_droid_update_pkgs_$$(product): private_product:=$$(product)
build_droid_update_pkgs_$$(product): private_device:=$$(device)
build_droid_update_pkgs_$$(product): output_dir
	$$(log) "[$$(private_product)]generating update packages..."
	$$(hide)cd $$(SRC_DIR) && \
	. $$(ABS_TOP_DIR)/tools/apb $$(private_product) && \
	choosetype $$(DROID_TYPE) && choosevariant $$(DROID_VARIANT) && \
	make droidupdate
	echo "    copy update packages..." && \
		mkdir -p $$(OUTPUT_DIR)/$$(private_product)/trusted && \
		mkdir -p $$(OUTPUT_DIR)/$$(private_product)/nontrusted && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/update_droid_trusted.zip $$(OUTPUT_DIR)/$$(private_product)/trusted/update_droid.zip && \
		cp -p $(SRC_DIR)/out/target/product/$$(private_device)/update_droid_nontrusted.zip $$(OUTPUT_DIR)/$$(private_product)/nontrusted/update_droid.zip && \
		if [ -f $(SRC_DIR)/out/target/product/$$(private_device)/update_recovery_trusted.zip ]; then \
			cp -p $(SRC_DIR)/out/target/product/$$(private_device)/update_recovery_trusted.zip $$(OUTPUT_DIR)/$$(private_product)/trusted/update_recovery.zip; \
		fi && \
		if [ -f $(SRC_DIR)/out/target/product/$$(private_device)/update_recovery_nontrusted.zip ]; then \
			cp -p $(SRC_DIR)/out/target/product/$$(private_device)/update_recovery_nontrusted.zip $$(OUTPUT_DIR)/$$(private_product)/nontrusted/update_recovery.zip; \
		fi
	$(log) "  done"
endef

#$1: build device
#$2: internal or external
define define-build-droid-config

tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

build_droid_pkgs_$$(product): build_droid_$$(product)_$(2)

.PHONY: build_droid_$$(product)_$(2)
build_droid_$$(product)_$(2): private_product:=$$(product)
build_droid_$$(product)_$(2): private_device:=$$(device)
build_droid_$$(product)_$(2): package_droid_nfs_$$(product)_$(2)
	$$(log) "build_droid_$$(private_product)_$(2) is done, reseting the source code."
	$$(hide)cd $$(SRC_DIR)/device/marvell/$$(private_device)/ &&\
		git reset --hard
	$$(log) "  done"
endef

#$1:build device
#$2:internal or external
define package-droid-nfs-config
tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

PUBLISHING_FILES+=$$(product)/root_nfs_$(2).tgz:m:md5

.PHONY: package_droid_nfs_$$(product)_$(2)
package_droid_nfs_$$(product)_$(2): private_product:=$$(product)
package_droid_nfs_$$(product)_$(2): private_device:=$$(device)
package_droid_nfs_$$(product)_$(2):
	$$(log) "[$$(private_product)]package root file system for booting android from SD card or NFS for $(2)."
	$$(hide)if [ -d $$(OUTPUT_DIR)/$$(private_product)/root_nfs ]; then rm -fr $$(OUTPUT_DIR)/$$(private_product)/root_nfs; fi
	$$(hide)cp -r -p $$(SRC_DIR)/out/target/product/$$(private_device)/root $$(OUTPUT_DIR)/$$(private_product)/root_nfs && \
	cp -p -r $$(SRC_DIR)/out/target/product/$$(private_device)/system $$(OUTPUT_DIR)/$$(private_product)/root_nfs
	$$(log) "  updating the modules..."
	$$(hide)if [ -d $$(OUTPUT_DIR)/$$(private_product)/modules ]; then rm -fr $$(OUTPUT_DIR)/$$(private_product)/modules; fi
	$$(hide)cd $$(OUTPUT_DIR)/$$(private_product) && tar xzf modules_android_mmc.tgz && cp -r modules $$(OUTPUT_DIR)/$$(private_product)/root_nfs/system/lib/
	$$(log) "  modifying root nfs folder..."
	$$(hide)cd $$(OUTPUT_DIR)/$$(private_product)/root_nfs && $$(ABS_TOP_DIR)/$$(private_device)/twist_root_nfs.sh
	$$(log) "  packaging the root_nfs.tgz..."
	$$(hide)cd $$(OUTPUT_DIR)/$$(private_product) && tar czf root_nfs_$(2).tgz root_nfs/
	$$(log) "  done for package_droid_nfs_$$(private_product)_$(2)."
endef

#<os>:<storage>:<kernel_cfg>:<root>
# os: the operating system
# storage: the OS will startup from which storage
# kernel_cfg:kernel config file used to build the kernel
# root: optional. If specified, indicating that the kernel ?Image has a root RAM file system.
#example: android:mlc:pxa168_android_mlc_defconfig:root
# kernel_configs:=
#
kernel_configs:=android:mmc:mmp2_android_defconfig 

export MAKE_JOBS

#$1:kernel_config
#$2:build device
define define-kernel-target
tw:=$$(subst :,  , $(1))
product:=$$(word 1, $$(tw))
device:=$$(word 2, $$(tw))

tw:=$$(subst :,  , $(2))
os:=$$(word 1, $$(tw))
storage:=$$(word 2, $$(tw))
kernel_cfg:=$$(word 3, $$(tw))
root:=$$(word 4, $$(tw))

#make sure that PUBLISHING_FILES_XXX is a simply expanded variable
PUBLISHING_FILES+=$$(product)/zImage.$$(os):o:md5
PUBLISHING_FILES+=$$(product)/zImage_recovery.$$(os):o:md5
PUBLISHING_FILES+=$$(product)/uImage.$$(os):o:md5
PUBLISHING_FILES+=$$(product)/uImage_recovery.$$(os):o:md5
PUBLISHING_FILES+=$$(product)/vmlinux:o:md5
PUBLISHING_FILES+=$$(product)/System.map:o:md5
PUBLISHING_FILES+=$$(product)/modules_$$(os)_$$(storage).tgz:m:md5

build_kernel_$$(product): build_kernel_$$(os)_$$(storage)_$$(product)

.PHONY: build_kernel_$$(os)_$$(storage)_$$(product)
build_kernel_$$(os)_$$(storage)_$$(product): private_os:=$$(os)
build_kernel_$$(os)_$$(storage)_$$(product): private_storage:=$$(storage)
build_kernel_$$(os)_$$(storage)_$$(product): private_root:=$$(root)
build_kernel_$$(os)_$$(storage)_$$(product): private_kernel_cfg:=$$(kernel_cfg)
build_kernel_$$(os)_$$(storage)_$$(product): private_root:=$$(root)
build_kernel_$$(os)_$$(storage)_$$(product): output_dir
	$$(log) "[$$(private_product)]starting to build kernel for booting $$(private_os) from $$(private_storage) ..."
	$$(log) "    kernel_config: $$(private_kernel_cfg): ..."
	$$(hide)cd $$(SRC_DIR)/ && \
	. $(ABS_TOP_DIR)/tools/apb $$(private_product) && \
	choosetype $(DROID_TYPE) && choosevariant $(DROID_VARIANT) && \
	cd $$(KERNELSRC_TOPDIR) && \
	KERNEL_CONFIG=$$(private_kernel_cfg) make clean all 
	$$(hide)mkdir -p $$(OUTPUT_DIR)/$$(private_product)
	$$(log) "    copy kernel and module files ..."
	$$(hide)if [ -f $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/zImage ]; then cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/zImage $$(OUTPUT_DIR)/$$(private_product)/zImage.$$(private_os); fi
	$$(hide)if [ -f $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/zImage_recovery ]; then cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/zImage_recovery $$(OUTPUT_DIR)/$$(private_product)/zImage_recovery.$$(private_os); fi
	$$(hide)if [ -f $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/uImage ]; then cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/uImage $$(OUTPUT_DIR)/$$(private_product)/uImage.$$(private_os); fi
	$$(hide)if [ -f $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/uImage_recovery ]; then cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/uImage_recovery $$(OUTPUT_DIR)/$$(private_product)/uImage_recovery.$$(private_os); fi
	$$(hide)cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/kernel/vmlinux $$(OUTPUT_DIR)/$$(private_product)
	$$(hide)cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/kernel/System.map $$(OUTPUT_DIR)/$$(private_product)
	$$(hide)if [ -d $$(OUTPUT_DIR)/$$(private_product)/modules ]; then rm -fr $$(OUTPUT_DIR)/$$(private_product)/modules; fi &&\
	mkdir -p $$(OUTPUT_DIR)/$$(private_product)/modules
	$$(hide)cp $$(SRC_DIR)/$$(KERNELSRC_TOPDIR)/out/modules/* $$(OUTPUT_DIR)/$$(private_product)/modules
	$$(hide)cd $$(OUTPUT_DIR)/$$(private_product) && tar czf modules_$$(private_os)_$$(private_storage).tgz modules/ 
	$(log) "  done."
endef

$(foreach bd,$(ABS_BUILD_DEVICES),\
	$(eval $(call define-build-droid-kernel,$(bd))) \
	$(foreach kc,$(kernel_configs), \
		$(eval $(call define-kernel-target,$(bd),$(kc)))) \
		$(eval $(call define-build-droid-root,$(bd))) \
		$(eval $(call define-build-uboot-obm,$(bd))) \
		$(eval $(call define-build-droid-pkgs,$(bd))) \
		$(eval $(call define-clean-droid-kernel,$(bd))) \
		$(eval $(call define-clean-uboot-obm,$(bd))) \
		$(eval $(call define-build-droid-config,$(bd),internal)) \
		$(eval $(call package-droid-nfs-config,$(bd),internal)) \
	)

