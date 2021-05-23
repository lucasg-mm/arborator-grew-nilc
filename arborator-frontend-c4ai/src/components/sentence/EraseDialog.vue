<template>
  <!-------------------- Start eraseDialog -------------------->
  <q-dialog v-model="eraseDialogOpened">
    <!-- @hide="ondialoghide()" -->
    <!-- :maximized="maximizedToggle" -->
    <q-card style="height: 260px">
      <q-bar class="bg-primary text-white">
        <div class="text-weight-bold">
          Erase annotation
        </div>
        <q-space />
        <q-btn flat dense icon="close" v-close-popup />
      </q-bar>
      <q-card-section style="height: 160px">
        <q-checkbox v-model="relations" label="Relations" />
        <br />
        <q-checkbox v-model="category" label="Category" />
        <br />
        <q-checkbox v-model="features" label="Features" />
      </q-card-section>
      <q-separator />
      <q-card-actions>
        <q-btn
          flat
          label="Cancel"
          v-close-popup
          style="margin-left: auto; margin-right: auto"
        />
        <q-space />

        <!-- @click="ondialoghide()" -->
        <q-btn
          color="negative"
          @click="onDeleteErase()"
          label="Delete"
          v-close-popup
          style="margin-left: auto; margin-right: auto"
        />
        <!-- :disabled="snap.currentcategory == snap.category" -->
      </q-card-actions>
    </q-card>
  </q-dialog>

  <!----------------- End eraseDialog ------------------->
</template>

<script>
export default {
  props: ["sentenceBus"],
  data() {
    return {
      eraseDialogOpened: false,
      token: {},
      userId: "",
      relations: false,
      category: false,
      features: false,
    };
  },
  computed: {
    annotationFeatures() {
      return this.$store.getters["config/annotationFeatures"];
    },
  },
  mounted() {
    this.sentenceBus.$on("open:eraseDialog", () => {
      this.eraseDialogOpened = true;
    });
  },
  beforeDestroy() {
    this.sentenceBus.$off("open:eraseDialog");
  },
  methods: {
    onDeleteErase() {
      // objects indicating which annotations to erase
      const elementsToErase = {
        relations: this.relations,
        category: this.category,
        features: this.features,
      };

      this.$emit("erase-annotation", elementsToErase);
    },
  },
};
</script>
<style></style>
