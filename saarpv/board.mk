ifeq ($(strip $(BUILD_VARIANTS)),)
	BUILD_VARIANTS:=droid-gcc
endif

include core/main.mk

#
# Include goal for repo source code
#
include core/repo-source.mk

#
# Include goal for generate changelog
#
include core/changelog.mk

#
# Include goal for package source code.
#
include $(BOARD)/pkg-source.mk

#
# Include goal for build android and kernels.
#
include $(BOARD)/build-droid-kernel.mk

# Include goal for build UBoot and OBM
include $(BOARD)/build-uboot-obm.mk

#define the combined goal to include all build goals
define define-build
build_$(1): build_droid_kernel_$(1) build_uboot_obm_$(1)
endef
$(foreach bv, $(BUILD_VARIANTS), $(eval $(call define-build,$(bv) ) ) )

clean:clean_droid_kernel clean_uboot_obm

#
# Include publish goal
#
include core/publish.mk

