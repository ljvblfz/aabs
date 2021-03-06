ifneq ($(strip $(ABS_VIRTUAL_BUILD) ),true)
#check if the required variables have been set.
$(call check-variables,ABS_MANIFEST_BRANCH GIT_MANIFEST GIT_REPO)
#ABS_MANIFEST_FILE is optional

#get source code from GIT by repo
.PHONY: source
source: output_dir
	$(hide)if [ ! -d "$(SRC_DIR)" ]; then \
	    mkdir $(SRC_DIR); \
	fi
	$(log) "starting get source code from GIT server:$(GIT_SERVER), branch:$(ABS_MANIFEST_BRANCH), manifest:$(MANIFEST_FILE) ..."
	$(log) "ANDROID_SOURCE_DIR: $(SRC_DIR)"
	$(hide)cd $(SRC_DIR) && \
	if [ -z "$(GIT_LOCAL_MIRROR)" ]; then \
		repo init -u ssh://$(GIT_MANIFEST) -b $(ABS_MANIFEST_BRANCH) --repo-url ssh://$(GIT_REPO); \
	else \
		repo init -u ssh://$(GIT_MANIFEST) -b $(ABS_MANIFEST_BRANCH) --repo-url ssh://$(GIT_REPO) --reference $(GIT_LOCAL_MIRROR); \
	fi && \
	if [ -n "$(ABS_MANIFEST_FILE)" ]; then \
		cp ${ABS_BUILD_MANIFEST} .repo/manifests/; \
		repo init -m $(ABS_MANIFEST_FILE); \
	fi && \
	repo sync -c -d -q --jobs 8
	$(log) "saving manifest file..."
	$(hide)if [ "$(FLAG_DISTRIBUTED_BUILD)" = "true" ]; then \
		cp $(ABS_BUILD_MANIFEST) $(OUTPUT_DIR)/manifest.xml; \
	else \
		cd $(SRC_DIR); \
		repo manifest -r -o $(OUTPUT_DIR)/manifest.xml; \
	fi
#if an expection happened, repo doesn't exit with a non-zero value, we use below command to make sure the manifest.xml is generated.
	$(hide)ls $(OUTPUT_DIR)/manifest.xml > /dev/null
	$(hide)git rev-parse HEAD >$(OUTPUT_DIR)/abs.commit
	$(hide)cd $(SRC_DIR)/.repo/manifests && git rev-parse HEAD >$(OUTPUT_DIR)/manifest.commit
	$(hide)cd $(SRC_DIR)
	$(hide)$(ABS_TOP_DIR)/core/automerge.sh $(OUTPUT_DIR) $(SRC_DIR) $(ABS_MANIFEST_BRANCH) $(LAST_BUILD_LOC)
	$(log) "  done."


#format: <file name>:[m|o]:[md5]
#m:means mandatory
#o:means optional
#md5: need to generate md5 sum
PUBLISHING_FILES+=manifest.xml:m
PUBLISHING_FILES+=abs.commit:m
PUBLISHING_FILES+=manifest.commit:m
PUBLISHING_FILES+=changelog.automerge:o
BACKUP_FILES+=manifest.xml
BACKUP_FILES+=abs.commit
BACKUP_FILES+=manifest.commit
endif
