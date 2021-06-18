<template>
  <q-dialog
    v-model="logsDialModel"
    transition-show="fade"
    transition-hide="fade"
  >
    <q-card style="max-width: 100vw">
      <q-card-section class="justify-center">
        <div class="text-blue-grey-8">
          Select a time range to download the log files:
        </div>
        <div class="q-pa-md text-center">
          <q-date mask="DD-MM-YYYY" v-model="model" range />
          <br />
          <q-btn
            @click="closeDial"
            class="logs-buttons"
            outline
            color="red"
            type="submit"
            label="Cancel"
            no-caps
          />
          <q-btn
            @click="downloadLogFiles"
            class="logs-buttons"
            outline
            color="primary"
            type="submit"
            label="Download log files"
            no-caps
          />
        </div>
      </q-card-section>
    </q-card>
  </q-dialog>
</template>

<script>
import api from "../../boot/backend-api.js";

export default {
  props: ["logsDial"],
  data() {
    return {
      model: { from: null, to: null },
    };
  },
  computed: {
    logsDialModel: {
      get() {
        return this.logsDial;
      },
      set(newValue) {
        this.$emit("update:logsDial", newValue);
      },
    },
  },
  mounted() {
    // gets today's date in the appropriate format
    const today = this.getTodayDate();

    // defines today as the initial date of the date picker
    this.model = today;
  },

  methods: {
    // --DESCRIPTION:
    // Gets today's date in the DD-MM-YYYY
    // format.
    getTodayDate() {
      const date = new Date();
      let mm = date.getMonth() + 1; // getMonth() is zero-based
      let dd = date.getDate();

      return [
        (dd > 9 ? "" : "0") + dd,
        (mm > 9 ? "" : "0") + mm,
        date.getFullYear(),
      ].join("-");
    },
    // --DESCRIPTION:
    // Closes the dialogue window.
    closeDial() {
      this.logsDialModel = false;
    },
    // --DESCRIPTION:
    // oi
    downloadLogFiles() {
      let dateRangeData;
      if (typeof this.model === "string") {
        dateRangeData = {
          from: this.model,
          to: this.model,
        };
      } else {
        dateRangeData = {
          from: this.model.from,
          to: this.model.to,
        };
      }

      api
        .downloadLogs(this.$route.params.projectname, dateRangeData)
        .then((response) => {
          const url = window.URL.createObjectURL(
            new Blob([response.data], { type: "application/zip" })
          );
          const link = document.createElement("a");
          link.href = url;
          link.setAttribute(
            "download",
            this.$route.params.projectname + ".zip"
          );
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
          this.$q.notify({ message: `Files downloaded` });
          return [];
        })
        .catch((err) => {
          console.log(err);
        });
    },
  },
};
</script>

<style>
.logs-buttons {
  margin-top: 30px;
  margin-left: 12px;
  margin-right: 12px;
}
</style>
