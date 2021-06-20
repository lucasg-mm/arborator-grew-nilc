<template>
  <!-------------------- Start uposDialog -------------------->
  <q-dialog v-model="uposDialogOpened" @keyup.enter="onChangeUpos()">
    <!-- @hide="ondialoghide()" -->
    <!-- :maximized="maximizedToggle" -->
    <q-card style="height: 300px">
      <q-bar class="bg-primary text-white">
        <div class="text-weight-bold">
          Select a category for the selected tokens
        </div>
        <q-space />
        <q-btn flat dense icon="close" v-close-popup />
      </q-bar>
      <q-card-section style="height: 200px">
        <q-select
          ref="select"
          id="catselect"
          filled
          v-model="chosenUPOS"
          :options="annotationFeatures.UPOS"
          label="Category"
          style="width: 250px"
        />
      </q-card-section>
      <q-separator />
      <q-card-actions>
        <q-btn
          flat
          label="Cancel"
          v-close-popup
          style="width: 25%; margin-left: auto; margin-right: auto"
        />
        <q-space />

        <!-- @click="ondialoghide()" -->
        <q-btn
          color="negative"
          @click="onDeleteUpos()"
          label="Delete"
          v-close-popup
          style="width: 25%; margin-left: auto; margin-right: auto"
        />
        <q-space />
        <q-btn
          id="catselectvalidate"
          color="primary"
          @click="onChangeUpos()"
          label="Ok"
          v-close-popup
          style="width: 25%; margin-left: auto; margin-right: auto"
        />
        <!-- :disabled="snap.currentcategory == snap.category" -->
      </q-card-actions>
    </q-card>
  </q-dialog>

  <!----------------- End uposDialog ------------------->
</template>

<script>
export default {
  props: ["sentenceBus"],
  data() {
    return {
      uposDialogOpened: false,
      chosenUPOS: "",
      idsGroupedTokens: [],
      idOfMostRecentToken: null,
      userId: "",
      tree: {},
    };
  },
  computed: {
    annotationFeatures() {
      return this.$store.getters["config/annotationFeatures"];
    },
  },
  mounted() {
    this.sentenceBus.$on(
      "open:multipleUposDialog",
      (
        { idOfMostRecentToken, idsGroupedTokens, userId, tree },
        isByShortcut = false
      ) => {
        this.idOfMostRecentToken = idOfMostRecentToken;
        this.idsGroupedTokens = idsGroupedTokens;
        this.userId = userId;
        this.uposDialogOpened = true;
        this.tree = tree;

        if (isByShortcut) {
          this.showPopup();
        }
      }
    );
  },
  beforeDestroy() {
    this.sentenceBus.$off("open:multipleUposDialog");
  },
  methods: {
    // -- DESCRIPTION:
    // Opens the popup to choose the Part of Speech tag.
    showPopup() {
      this.$nextTick(() => {
        let selectComponent = this.$refs.select;
        selectComponent.showPopup();
      });
    },
    // -- DESCRIPTION:
    // Changes the UPOS of the selected tokens.
    onChangeUpos() {
      this.uposDialogOpened = false;
      for (const id of this.idsGroupedTokens) {
        this.tree[id].UPOS = this.chosenUPOS;
      }
      this.tree[this.idOfMostRecentToken].UPOS = this.chosenUPOS;
      this.sentenceBus.$emit("tree-update:tree", {
        tree: this.tree,
        userId: this.userId,
      });
    },
    // -- DESCRIPTION:
    // Deletes the UPOS of the selected tokens.
    onDeleteUpos() {
      for (const id of this.idsGroupedTokens) {
        this.tree[id].UPOS = "_";
      }
      this.tree[this.idOfMostRecentToken].UPOS = "_";
      this.sentenceBus.$emit("tree-update:tree", {
        tree: token,
        userId: this.userId,
      });
    },
  },
};
</script>
<style></style>
