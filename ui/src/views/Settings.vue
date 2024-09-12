<!--
  Copyright (C) 2022 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.lamp_fqdn')"
              placeholder="lamp.example.org"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="host"
            >
            </cv-text-input>
            <cv-toggle
              value="letsEncrypt"
              :label="$t('settings.lets_encrypt')"
              v-model="isLetsEncryptEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-toggle
              value="httpToHttps"
              :label="$t('settings.http_to_https')"
              v-model="isHttpToHttpsEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <NsTextInput
              :label="$t('settings.mysql_admin_pass')"
              v-model="mysql_admin_pass"
              type="password"
              :placeholder="$t('settings.mysql_admin_pass_placeholder')"
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                !firstConfig
              "
              :invalid-message="$t(error.mysql_admin_pass)"
              ref="mysql_admin_pass"
              :helper-text="$t('settings.mysql_admin_pass_helper')"
            >
              <template #tooltip>{{
                $t("settings.mysql_admin_pass_tooltip")
              }}</template>
            </NsTextInput>
            <!-- advanced options -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{ $t("settings.advanced") }}</template>
                <template slot="content">
                  <cv-toggle
                    value="phpmyadmin_enabled"
                    :label="$t('settings.phpmyadmin_enabled')"
                    v-model="phpmyadmin_enabled"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <cv-toggle
                    value="create_mysql_user"
                    :label="$t('settings.create_mysql_user')"
                    v-model="create_mysql_user"
                    :disabled="
                      loading.getConfiguration ||
                      loading.configureModule ||
                      !firstConfig
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <template v-if="create_mysql_user">
                    <NsTextInput
                      :label="$t('settings.mysql_user_name')"
                      v-model="mysql_user_name"
                      :placeholder="$t('settings.mysql_user_name_placeholder')"
                      :disabled="
                        loading.getConfiguration ||
                        loading.configureModule ||
                        !firstConfig
                      "
                      :invalid-message="$t(error.mysql_user_name)"
                      ref="mysql_user_name"
                      :helper-text="$t('settings.mysql_user_name_helper')"
                    >
                      <template #tooltip>{{
                        $t("settings.mysql_user_name_tooltip")
                      }}</template>
                    </NsTextInput>
                    <NsTextInput
                      :label="$t('settings.mysql_user_pass')"
                      v-model="mysql_user_pass"
                      :placeholder="$t('settings.mysql_user_pass_placeholder')"
                      type="password"
                      :disabled="
                        loading.getConfiguration ||
                        loading.configureModule ||
                        !firstConfig
                      "
                      :invalid-message="$t(error.mysql_user_pass)"
                      ref="mysql_user_pass"
                      :helper-text="$t('settings.mysql_user_pass_helper')"
                    >
                      <template #tooltip>{{
                        $t("settings.mysql_user_pass_tooltip")
                      }}</template>
                    </NsTextInput>
                    <NsTextInput
                      :label="$t('settings.mysql_user_db')"
                      v-model="mysql_user_db"
                      :placeholder="$t('settings.mysql_user_db_placeholder')"
                      :disabled="
                        loading.getConfiguration ||
                        loading.configureModule ||
                        !firstConfig
                      "
                      :invalid-message="$t(error.mysql_user_db)"
                      ref="mysql_user_db"
                      :helper-text="$t('settings.mysql_user_db_helper')"
                    >
                      <template #tooltip>{{
                        $t("settings.mysql_user_db_tooltip")
                      }}</template>
                    </NsTextInput>
                  </template>
                  <NsTextInput
                    :label="$t('settings.php_upload_max_filesize')"
                    v-model="php_upload_max_filesize"
                    type="number"
                    :placeholder="
                      $t('settings.php_upload_max_filesize_placeholder')
                    "
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    :invalid-message="$t(error.php_upload_max_filesize)"
                    ref="php_upload_max_filesize"
                    :helper-text="$t('settings.php_upload_max_filesize_helper')"
                  >
                    <template #tooltip>{{
                      $t("settings.php_upload_max_filesize_tooltip")
                    }}</template>
                  </NsTextInput>
                </template>
              </cv-accordion-item>
            </cv-accordion>
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      host: "",
      isLetsEncryptEnabled: false,
      isHttpToHttpsEnabled: true,
      phpmyadmin_enabled: true,
      create_mysql_user: false,
      php_upload_max_filesize: "100",
      mysql_user_name: "",
      mysql_user_db: "",
      mysql_user_pass: "",
      mysql_admin_pass: "",
      firstConfig: true,
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        mysql_user_name: "",
        mysql_user_db: "",
        mysql_user_pass: "",
        mysql_admin_pass: "",
        php_upload_max_filesize: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
  created() {
    this.getConfiguration();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.isHttpToHttpsEnabled = config.http2https;
      this.mysql_user_name = config.mysql_user_name;
      this.mysql_user_db = config.mysql_user_db;
      this.mysql_user_pass = config.mysql_user_pass;
      this.mysql_admin_pass = config.mysql_admin_pass;
      this.firstConfig = config.firstConfig;
      this.loading.getConfiguration = false;
      this.create_mysql_user = config.create_mysql_user;
      this.php_upload_max_filesize = config.php_upload_max_filesize;
      this.phpmyadmin_enabled = config.phpmyadmin_enabled;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);

      let isValidationOk = true;
      if (!this.host) {
        this.error.host = "common.required";

        if (isValidationOk) {
          this.focusElement("host");
        }
        isValidationOk = false;
      }
      if (!this.mysql_admin_pass) {
        this.error.mysql_admin_pass = "common.required";

        if (isValidationOk) {
          this.focusElement("mysql_admin_pass");
        }
        isValidationOk = false;
      }
      if (this.mysql_admin_pass && this.mysql_admin_pass.length < 8) {
        this.error.mysql_admin_pass = "common.required_min_length8";

        if (isValidationOk) {
          this.focusElement("mysql_admin_pass");
        }
        isValidationOk = false;
      }
      if (this.create_mysql_user && !this.mysql_user_name) {
        this.error.mysql_user_name = "common.required";

        if (isValidationOk) {
          this.focusElement("mysql_user_name");
        }
        isValidationOk = false;
      }
      if (this.create_mysql_user && !this.mysql_user_pass) {
        this.error.mysql_user_pass = "common.required";

        if (isValidationOk) {
          this.focusElement("mysql_user_pass");
        }
        isValidationOk = false;
      }
      if (this.create_mysql_user && this.mysql_user_pass.length < 8) {
        this.error.mysql_user_pass = "common.required_min_length8";

        if (isValidationOk) {
          this.focusElement("mysql_user_pass");
        }
        isValidationOk = false;
      }
      if (this.create_mysql_user && !this.mysql_user_db) {
        this.error.mysql_user_db = "common.required";

        if (isValidationOk) {
          this.focusElement("mysql_user_db");
        }
        isValidationOk = false;
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        // set i18n error message
        this.error[param] = this.$t("settings." + validationError.error);

        if (!focusAlreadySet) {
          this.focusElement(param);
          focusAlreadySet = true;
        }
      }
    },
    async configureModule() {
      this.error.test_imap = false;
      this.error.test_smtp = false;
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            http2https: this.isHttpToHttpsEnabled,
            mysql_user_name: this.mysql_user_name,
            mysql_user_db: this.mysql_user_db,
            mysql_user_pass: this.mysql_user_pass,
            mysql_admin_pass: this.mysql_admin_pass,
            create_mysql_user: this.create_mysql_user,
            php_upload_max_filesize: this.php_upload_max_filesize,
            phpmyadmin_enabled: this.phpmyadmin_enabled,
          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-bottom {
  margin-bottom: $spacing-06;
}

.maxwidth {
  max-width: 38rem;
}
</style>
