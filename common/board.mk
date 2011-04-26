BOARD:=$(ABS_BOARD)
ANDROID_VERSION:=$(ABS_DROID_BRANCH)
PRODUCT_CODE:=$(ABS_BOARD)-$(ANDROID_VERSION)
MANIFEST_BRANCH:=$(PRODUCT_CODE)

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
# Include goal for build uboot, obm, android and kernels.
#
include $(BOARD)/build-droid-kernel.mk

#define the combined goal to include all build goals
define define-build
build_$(1): build_droid_kernel_$(1)
endef
$(foreach bv, $(BUILD_VARIANTS), $(eval $(call define-build,$(bv) ) ) )

clean:clean_droid_kernel clean_uboot

#
# Include publish goal
#
include core/publish.mk

