ifneq ($(strip $(ABS_VIRTUAL_BUILD) ),true)
#check if the required variables have been set.
$(call check-variables, ABS_PRODUCT_CODE ABS_MANIFEST_BRANCH)

#format: <file name>:[m|o]:[md5]
#m:means mandatory
#o:means optional
#md5: need to generate md5 sum
#PUBLISHING_FILES:=

PUBLISHING_FILES+=changelog.day:m
PUBLISHING_FILES+=changelog.week:m
PUBLISHING_FILES+=changelog.biweek:m
PUBLISHING_FILES+=changelog.month:m
PUBLISHING_FILES+=changelog.build:m
PUBLISHING_FILES+=changelog_rel.csv:o
PUBLISHING_FILES+=changelog.ms1:o
PUBLISHING_FILES+=changelog.ms2:o

ifeq ($(strip $(LAST_BUILD_LOC)),)
ifneq ($(filter changelog, $(MAKECMDGOALS)),)
$(warning LAST_BUILD_LOC is not set, changelog.build and changlog.rel won't be generated)
endif
endif

.PHONY:changelog
changelog:
	$(log) "starting to generate change logs..."
	$(hide)$(ABS_TOP_DIR)/core/gen_chglog.sh $(OUTPUT_DIR) $(SRC_DIR) $(ABS_MANIFEST_BRANCH) $(LAST_BUILD_LOC)
	$(log) "  done"

.PHONY:get_changelog_build
get_changelog_build:
	$(hide)echo $(OUTPUT_DIR)/changelog.build

#
# AABS stands for Android Auto Build System which means these build scripts and make file.
# Sometimes changing AABS doesn't require to rebuild the project, for example, add a guy to announce_list.
# But some does, such as modify the README, scripts.
# And if you modidfy the README or script for one project, it shouldn't affect the other project.
# So if a commit does require rebuild the project, you can put "product-code need rebuild." in the commit message.
# e.g: avlite-cupcake need rebuild.
#      avlite-* need rebuild. which means all product of avlite need rebuild
#      *-cupcake need rebuild. which means all product based on cupcake need rebuild
#      *-* need rebuild/all need rebuild. which means all products need rebuild.

AABS_PRJ:=aabs
SOC:=$(word 1, $(subst -,  , $(ABS_PRODUCT_CODE) ))
DROID_BRANCH:=$(word 2, $(subst -,  , $(ABS_PRODUCT_CODE) ))

.PHONY:get_change_summary_since_last_build
get_change_summary_since_last_build:
	@PRJS=$$(sed -n "/^--------/,/^--------/ s/-prj:\(.*\):.*/\1/p" < $(OUTPUT_DIR)/changelog.build) && \
	PRJS=$${PRJS/$(AABS_PRJ)/} && \
	AABS_PRODUCT=$$(sed -n "/^-prj:$(AABS_PRJ):/,/^-prj:.*:/ s/$(ABS_PRODCUT_CODE) need rebuild/$(AABS_PRJ)/p" < $(OUTPUT_DIR)/changelog.build ) && \
	AABS_PRODUCT+=$$(sed -n "/^-prj:$(AABS_PRJ):/,/^-prj:.*:/ s/$(SOC)-\* need rebuild/$(AABS_PRJ)/p" < $(OUTPUT_DIR)/changelog.build ) && \
	AABS_PRODUCT+=$$(sed -n "/^-prj:$(AABS_PRJ):/,/^-prj:.*:/ s/\*-$(DROID_BRANCH) need rebuild/$(AABS_PRJ)/p" < $(OUTPUT_DIR)/changelog.build ) && \
	AABS_PRODUCT+=$$(sed -n "/^-prj:$(AABS_PRJ):/,/^-prj:.*:/ s/\*-\* need rebuild/$(AABS_PRJ)/p" < $(OUTPUT_DIR)/changelog.build ) && \
	AABS=$$(sed -n "/^-prj:$(AABS_PRJ):/,/^-prj:.*:/ s/all projects need rebuild/$(AABS_PRJ)/p" < $(OUTPUT_DIR)/changelog.build ) && \
	if [ ! -z "$$AABS_PRODUCT" ] || [ ! -z "$$AABS" ]; then PRJS="$(AABS_PRJ) $$PRJS"; fi && \
	echo $$PRJS 

endif
