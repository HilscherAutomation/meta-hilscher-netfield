/*
* Create an API to provide a sysfs infrastructure for device data.
*
* device-data-driver.c
*
* (C) Copyright 2014 Hilscher Gesellschaft fuer Systemautomation mbH
* http://www.hilscher.com
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; version 2 of
* the License.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/string.h>

#include <linux/slab.h>

#include "jsmn.h"

static int lock = 0;

struct kobj_ext_attribute {
	struct bin_attribute attr;
	char *val;
};

/**
 * API function of dynamically created object attributes.
 */

static ssize_t dd_new_read(struct file *f, struct kobject *kobj, struct bin_attribute *attr, char *buf, loff_t offs, size_t count)
{
	struct kobj_ext_attribute *ext_attr = container_of(attr, struct kobj_ext_attribute , attr);

	pr_debug("Entering %s (%s) offs=%u, count=%u\n", __func__, attr->attr.name, (unsigned int)offs, (unsigned int)count);
	memcpy(buf, ext_attr->val + offs, count);

	return count;
}

/**
 * Create a file sysfs object.
 */
static int dd_create_sysfs_file_obj(struct kobject *kobj, const char *filename, const char *val)
{
	struct kobj_ext_attribute *new_attr;

	pr_debug("Entering %s\n", __func__);

	new_attr = kzalloc(sizeof(*new_attr), GFP_KERNEL);
	new_attr->attr.attr.name = kzalloc(strlen(filename)+1, GFP_KERNEL);
	snprintf((char*)new_attr->attr.attr.name, strlen(filename)+1, filename);

	new_attr->val = kzalloc(strlen(val)+1, GFP_KERNEL);
	new_attr->attr.size = snprintf(new_attr->val, strlen(val)+1, val);

	new_attr->attr.attr.mode = S_IRUGO;
	new_attr->attr.read = &dd_new_read;

	return sysfs_create_bin_file(kobj, &new_attr->attr);
}

/**
 * Create a directory sysfs object.
 */
static struct kobject *dd_create_sysfs_dir_obj(struct kobject *kobj, const char *dirname)
{
	pr_debug("Entering %s\n", __func__);

	return kobject_create_and_add(dirname, kobj);
}

/**
 * Process a json object and create the related sysfs infrastructure recursively.
 */
static int dd_create_sysfs_entries(struct kobject *kobj, const char* json, jsmntok_t *token, int n, int nObj)
{
	jsmntok_t *t;
	char keyName[64] = {'\0'};
	int fakeDirCnt = 0;
	struct kobject *subkobj;

	pr_debug("Entering %s\n", __func__);

	for(;nObj; n++) {
		t = token + n;
		switch(t->type) {
		case JSMN_ARRAY:
			if (*keyName == '\0')
				sprintf(keyName, "%d", fakeDirCnt++);
			subkobj = dd_create_sysfs_dir_obj(kobj, keyName);
			n = dd_create_sysfs_entries(subkobj, json, token, n + 1, t->size) - 1;
			keyName[0] = '\0';
			nObj--;
			break;
		case JSMN_OBJECT:
			if (*keyName == '\0')
				sprintf(keyName, "%d", fakeDirCnt++);
			subkobj = dd_create_sysfs_dir_obj(kobj, keyName);
			n = dd_create_sysfs_entries(subkobj, json, token, n + 1, t->size) - 1;
			keyName[0] = '\0';
			nObj--;
			break;
		/* Primitives are booleans and numbers and also come as strings */
		case JSMN_PRIMITIVE:
		case JSMN_STRING:
			if (t->size) {
				snprintf(keyName, t->end - t->start + 1, "%s", json + t->start);
			}
			else {
				char *keyValue;
				ssize_t keyValue_len;

				if (*keyName == '\0')
					sprintf(keyName, "%d", fakeDirCnt++);

				keyValue_len = snprintf(NULL, 0, "%s", json + t->start);
				keyValue = kzalloc(keyValue_len, GFP_KERNEL);

				snprintf(keyValue, t->end - t->start + 1, "%s", json + t->start);
				dd_create_sysfs_file_obj(kobj, keyName, keyValue);
				keyName[0] = '\0';
				nObj--;

				kfree(keyValue);
			}
			break;
		default:
			pr_err("Unsupported JSON token type (%d) found!\n", t->type);
			break;
		}
	}

	return n;
}

static int dd_create_kobj_infrastructure_from_json(struct kobject *kobj, const char *json, size_t json_len)
{
	jsmn_parser extParser;
	jsmntok_t *token;
	int nTokens, maxTokens;

	pr_debug("Entering %s\n", __func__);

	/* Prepare parser */
	jsmn_init(&extParser);

	maxTokens=json_len;
	token = kzalloc(maxTokens * sizeof(*token), GFP_KERNEL);

	nTokens = jsmn_parse(&extParser, json, json_len, token, maxTokens);
	if (nTokens < 0) {
		pr_err("Failed to parse device data %d (json_len=%u, token=%px).\n", nTokens, (unsigned int)strlen(json), token);
		return -EINVAL;
	}

	kfree(token);

	return nTokens - dd_create_sysfs_entries(kobj, json, token, 1, token->size);
}

static char json_data[64*1024];
static uint32_t json_data_len;

/**
 * API function of object attribute 'export'.
 */
static ssize_t dd_export_store(struct file *f, struct kobject *kobj, struct bin_attribute *attr, char *buf, loff_t offs, size_t count)
{
	static uint32_t raw_file_counter= 0;
	char raw_file_name[16];

	pr_debug("Entering %s (off=%u, count=%u)\n", __func__, (unsigned int)offs, (unsigned int)count);

	if (lock) {
		pr_err("Error: Driver is locked!");
		return -EPERM;
	}

	if( (offs == 0) && (count > 1) ) {
		memset(json_data, 0, sizeof(json_data));
		json_data_len = 0;
	}


	/* Wait for LF */
	if( (offs == 0) && (count == 1) && (buf[0] == '\n')) {
		pr_debug("Creating raw%u entry from %u chars", raw_file_counter, json_data_len);
		if (dd_create_kobj_infrastructure_from_json(kobj, json_data, json_data_len))
			return -EINVAL;

		/* Offers backward compatibility */
		if (raw_file_counter == 0)
			dd_create_sysfs_file_obj(kobj, "raw", json_data);

		/* Multiple raw file support.
		 * NOTE: raw and raw_o are the same! */
		snprintf(raw_file_name, sizeof(raw_file_name), "raw_%u", raw_file_counter);
		dd_create_sysfs_file_obj(kobj, raw_file_name, json_data);

		raw_file_counter++;
	} else {
		memcpy(json_data + offs, buf, count);
		json_data_len = offs + count;

		if(offs + count > sizeof(json_data))
			return -EINVAL;
	}

	return count;
}

static struct bin_attribute export_attr = __BIN_ATTR(export, S_IWUSR, NULL, dd_export_store, sizeof(json_data));

/**
 * API function of object attribute 'lock'.
 */
static ssize_t dd_lock_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
	pr_debug("Entering %s\n", __func__);

	if (!lock) {
		sscanf(buf,"%u",&lock);
		lock = (lock >= 1) ? 1 : 0;
	}

	return count;
}

static ssize_t dd_lock_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
  pr_debug("Entering %s\n", __func__);

  return sprintf(buf, "%u\n", lock ? 1 : 0);
}

static struct kobj_attribute lock_attr = __ATTR(lock, S_IRUSR|S_IWUSR, dd_lock_show, dd_lock_store);

/**
 * Basic functions for the kernel module.
 */
static int __init dd_init(void)
{
	struct kobject *dd_kobj;
	int rc;

	pr_debug("Entering %s\n", __func__);

	/* create a dir in /sys */
	dd_kobj = kobject_create_and_add("device_data", NULL);
	if (!dd_kobj)
		return -ENOMEM;

	/* create attribute files in /sys/device_data */
	rc = sysfs_create_file(dd_kobj, &lock_attr.attr);
	if (rc)
		goto attr_file_failed;

	rc = sysfs_create_bin_file(dd_kobj, &export_attr);
	if (rc)
		goto attr_file_failed;

	return 0;

attr_file_failed:
	kobject_put(dd_kobj);
	return rc;
}

module_init(dd_init);

/* Information about this module */
MODULE_DESCRIPTION("device data module");
MODULE_AUTHOR("Hilscher Gesellschaft fuer Systemautomation mbH");
MODULE_LICENSE("GPL");
