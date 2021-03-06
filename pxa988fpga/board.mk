ABS_BUILD_DEVICES ?= pxa988fpga:pxa988fpga
BOARD:=pxa988fpga
ANDROID_VERSION:=ics
PRODUCT_CODE:=$(BOARD)-$(ANDROID_VERSION)

#
# Include goal for build android and kernels.
#
include $(ABS_SOC)/build-droid-kernel.mk

#define the combined goal to include all build goals
build: build_device
#build: build_swd

.PHONY:build_device
define define-build-device
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )

build_device_$$(product): private_product:=$$(product)
build_device_$$(product): private_device:=$$(device)
build_device_$$(product): build_droid_kernel_$$(product)
build_device: build_device_$$(product)
endef

$(foreach bv1, $(ABS_BUILD_DEVICES), $(eval $(call define-build-device,$(bv1) ) ))

.PHONY:clean
clean:clean_device clean_swd clean_wtpsp

define define-clean-device
tw:=$$(subst :,  , $(1) )
product:=$$(word 1, $$(tw) )
device:=$$(word 2, $$(tw) )
clean_device_$$(product): private_product:=$$(product)
clean_device_$$(product): private_device:=$$(device)
clean_device_$$(product): clean_droid_kernel_$$(product)
clean_device:clean_device_$$(product)
endef
$(foreach bv, $(ABS_BUILD_DEVICES), $(eval $(call define-clean-device,$(bv) ) ) )



