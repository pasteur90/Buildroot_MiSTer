################################################################################
#
# aic8800
#
################################################################################

# Out-of-tree AICSemi AIC8800-family Wi-Fi 6 USB driver and firmware.
# aic_load_fw uploads boot firmware, aic8800_fdrv provides Wi-Fi, and
# aic_zlp_quirk applies the upstream VID:PID-specific Bluetooth ZLP fix.
AIC8800_VERSION = b72eea956451d6a351292cd6cd46b44b48e65b8d
AIC8800_SITE = $(call github,shenmintao,aic8800d80,$(AIC8800_VERSION))

# The repository has no license text or source grant. The driver declares
# MODULE_LICENSE("GPL"); the firmware blobs have no separate license text.
AIC8800_LICENSE = GPL-2.0 (driver module declarations; no source grant published), PROPRIETARY (firmware blobs; no separate terms published)

# Build all three modules in one kbuild pass so modpost resolves the loader's
# exported symbols for aic8800_fdrv.
AIC8800_MODULE_SUBDIRS = drivers/aic8800
AIC8800_MODULE_MAKE_OPTS = \
	CONFIG_AIC_LOADFW_SUPPORT=m \
	CONFIG_AIC8800_WLAN_SUPPORT=m \
	CONFIG_AIC_ZLP_QUIRK=m

# The driver opens firmware directly under /lib/firmware/<variant>/ rather
# than using request_firmware(). Fail if upstream changes that contract.
define AIC8800_CHECK_FW_PATH
	grep -Fq 'aic_default_fw_path = "/lib/firmware";' \
		$(@D)/drivers/aic8800/aic_load_fw/aicbluetooth.c || \
		{ echo "aic8800: expected firmware base path /lib/firmware" >&2; exit 1; }
endef
AIC8800_POST_PATCH_HOOKS += AIC8800_CHECK_FW_PATH

AIC8800_FW_VARIANTS = \
	aic8800 \
	aic8800D80 \
	aic8800D80N \
	aic8800D80X2 \
	aic8800DC \
	aic8800DLN

define AIC8800_INSTALL_TARGET_CMDS
	for v in $(AIC8800_FW_VARIANTS); do \
		$(INSTALL) -d $(TARGET_DIR)/lib/firmware/$$v ; \
		$(INSTALL) -m 0644 $(@D)/fw/$$v/* \
			$(TARGET_DIR)/lib/firmware/$$v/ || exit 1 ; \
	done
	$(INSTALL) -D -m 0644 $(@D)/aic.rules \
		$(TARGET_DIR)/usr/lib/udev/rules.d/aic.rules
	$(INSTALL) -D -m 0644 $(@D)/usb_modeswitch/1111_1111 \
		$(TARGET_DIR)/etc/usb_modeswitch.d/1111:1111
endef

$(eval $(kernel-module))
$(eval $(generic-package))
