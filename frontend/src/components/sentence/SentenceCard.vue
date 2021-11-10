<template>
  <q-card :id="index">
    <q-card-section>
      <div class="row items-center">
        <!-- icon="textsms"  ref="self" -->
        <span class="text-grey">{{ index + 1 }}</span>
        <q-chip
          class="text-center"
          :color="$q.dark.isActive ? 'primary' : ''"
          dense
        >
          {{ sentenceId }}</q-chip
        >&nbsp;&nbsp;&nbsp;
        <template>
          <q-input
            style="width: 65%"
            class="row items-center justify-center"
            :value="sentenceData.sentence"
            v-on="$listeners"
            v-bind="$attrs"
            @select="ttselect"
          >
            <template v-slot:prepend>
              <q-icon name="chat_bubble_outline" /><!-- 言 -->
            </template>
          </q-input>
        </template>
        <q-space />

        <q-btn
          flat
          round
          dense
          icon="remove"
          @click="decreaseSpace"
          :disable="spaceBetween === 30"
        >
          <q-tooltip v-if="spaceBetween !== 30"
            >Decrease space between tokens</q-tooltip
          >
        </q-btn>

        <q-btn
          flat
          round
          dense
          icon="add"
          @click="increaseSpace"
          :disable="spaceBetween === 0"
        >
          <q-tooltip v-if="spaceBetween !== 0"
            >Increase space between tokens</q-tooltip
          >
        </q-btn>

        <q-btn
          v-if="
            isLoggedIn &&
            exerciseLevel <= 3 &&
            !$store.getters['config/isTeacher']
          "
          flat
          round
          dense
          icon="assessment"
          @click="openStatisticsDialog"
          :disable="tab == ''"
          ><q-tooltip>See your annotation errors</q-tooltip>
        </q-btn>

        <q-btn
          v-if="$store.getters['config/isTeacher']"
          flat
          round
          dense
          icon="school"
          :disable="tab == ''"
          @click="save('teacher')"
        >
          <q-tooltip>Save as teacher</q-tooltip>
        </q-btn>

        <q-btn
          v-if="$store.getters['config/isTeacher']"
          flat
          round
          dense
          icon="linear_scale"
          :disable="tab == ''"
          @click="save('base_tree')"
        >
          <q-tooltip>Save as base_tree</q-tooltip>
        </q-btn>

        <q-btn
          v-if="isBernardCaron"
          flat
          round
          dense
          icon="face"
          :disable="tab == ''"
          @click="save(EMMETT)"
        >
          <q-tooltip>Save as Emmett</q-tooltip>
        </q-btn>

        <q-btn
          v-if="isLoggedIn && !$store.getters['config/isTeacher']"
          flat
          round
          dense
          icon="save"
          :disable="tab == '' || !canSave"
          @click="save('')"
        >
          <q-tooltip>Save this tree {{ this.tab }}</q-tooltip>
        </q-btn>

        <!-- TODO : still display the metadata when the user is not logged in, but hide all the buttons for deleting and saving them -->
        <q-btn
          v-if="isLoggedIn"
          flat
          round
          dense
          icon="post_add"
          :disable="tab == ''"
          @click="openMetaDialog()"
        >
          <q-tooltip>Edit this tree's metadata</q-tooltip>
        </q-btn>

        <q-btn
          v-if="isLoggedIn && $store.getters['config/isTeacher']"
          flat
          round
          dense
          icon="filter_9_plus"
          :disable="tab == ''"
          @click="openMultiEditDialog"
        >
          <q-tooltip>multi edit dialog</q-tooltip>
        </q-btn>

        <q-btn-dropdown :disable="tab == ''" icon="more_vert" flat dense>
          <q-tooltip>More</q-tooltip>
          <q-list>
            <q-item
              v-if="!exerciseMode"
              clickable
              v-close-popup
              @click="toggleDiffMode()"
            >
              <q-item-section avatar>
                <q-avatar
                  icon="ion-git-network"
                  color="primary"
                  text-color="white"
                />
              </q-item-section>
              <q-item-section>
                <q-item-label
                  >{{ diffMode ? "Leave" : "Enter" }} Diff Mode</q-item-label
                >
              </q-item-section>
            </q-item>

            <q-item clickable v-close-popup @click="getlink()">
              <q-item-section avatar>
                <q-avatar
                  icon="ion-md-link"
                  color="primary"
                  text-color="white"
                />
              </q-item-section>
              <q-item-section>
                <q-item-label>Get direct link to this tree</q-item-label>
              </q-item-section>
            </q-item>

            <q-item clickable v-close-popup @click="openConllDialog()">
              <q-item-section avatar>
                <q-avatar
                  icon="format_list_numbered"
                  color="primary"
                  text-color="white"
                />
              </q-item-section>
              <q-item-section>
                <q-item-label>Get CoNLL-U of this tree</q-item-label>
              </q-item-section>
            </q-item>

            <q-item clickable v-close-popup @click="exportSVG()">
              <q-item-section avatar>
                <q-avatar
                  icon="ion-md-color-palette"
                  color="primary"
                  text-color="white"
                />
              </q-item-section>
              <q-item-section>
                <q-item-label>Get SVG of this tree</q-item-label>
              </q-item-section>
            </q-item>

            <q-item clickable v-close-popup @click="exportPNG()">
              <q-item-section avatar>
                <q-avatar
                  icon="ion-md-image"
                  color="primary"
                  text-color="white"
                />
              </q-item-section>
              <q-item-section>
                <q-item-label>Get PNG of this tree</q-item-label>
              </q-item-section>
            </q-item>
          </q-list>
        </q-btn-dropdown>
        <q-btn
          v-if="isLoggedIn"
          flat
          round
          dense
          icon="undo"
          :disable="tab == '' || !canUndo"
          @click="undo('user')"
          v-bind:class="'undo-button'"
        >
        </q-btn>
        <q-btn
          v-if="isLoggedIn"
          flat
          round
          dense
          icon="ion-redo"
          :disable="tab == '' || !canRedo"
          @click="redo('user')"
          v-bind:class="'redo-button'"
        >
        </q-btn>
      </div>

      <div class="full-width row justify-end">
        <q-input
          ref="linkinput"
          dense
          v-show="sentenceLink.length != 0"
          class="col-4 self-stretch"
          :value="sentenceLink"
        >
          <template v-slot:prepend>
            <q-icon name="ion-md-link" />
          </template>
        </q-input>
      </div>

      <q-tabs
        v-model="tab"
        :class="{
          'text-grey-5': $q.dark.isActive,
          'text-grey-8': !$q.dark.isActive,
          'not-checked': !isChecked && !canSave && isLoggedIn,
          checked: isChecked && !canSave && isLoggedIn,
          'can-save': canSave,
          'shadow-2': true,
        }"
        dense
        :active-color="$q.dark.isActive ? 'info' : 'accent'"
        :active-bg-color="$q.dark.isActive ? '' : 'grey-2'"
      >
        <!-- v-for="(tree, user) in filteredConlls" -->
        <q-tab
          :class="{
            'checked-tab':
              isChecked && !canSave && isLoggedIn && !isMarked(user),
            'not-checked-tab':
              !isChecked && !canSave && isLoggedIn && !isMarked(user),
            'can-save-tab': canSave && !isMarked(user),
            'marked-tab': isMarked(user),
          }"
          v-for="(tree, user) in orderedConlls"
          :key="user"
          :props="user"
          :label="user"
          :name="user"
          :alert="hasPendingChanges[user] ? 'orange' : ''"
          :alert-icon="hasPendingChanges[user] ? 'save' : ''"
          :icon="diffMode && user === diffUserId ? 'school' : 'person'"
          no-caps
          :ripple="false"
          :ref="'tab' + user"
          @click="handleTabChange"
          ><q-tooltip v-if="hasPendingChanges[user]"
            >The tree has some pendings modifications not saved</q-tooltip
          ></q-tab
        >
      </q-tabs>
      <q-separator />
      <q-tab-panels
        v-model="tab"
        keep-alive
        @transition="transitioned"
        :animated="animated ? true : false"
        :class="animated ? 'easeOutSine' : ''"
      >
        <q-tab-panel
          v-for="(tree, user) in filteredConlls"
          :key="user"
          :props="tree"
          :name="user"
        >
          <q-btn-group v-if="isLoggedIn" class="action-buttons" outline>
            <q-btn
              outline
              icon="check_circle"
              v-if="isLoggedIn"
              :disable="tab == '' || isChecked"
              label="Check"
              class="check-button"
              @click="save('', true)"
            >
            </q-btn>
            <q-btn
              outline
              icon="remove_circle"
              v-if="isLoggedIn"
              :disable="tab == ''"
              label="Erase Annotation"
              class="erase-button"
              @click="openEraseDial()"
            >
            </q-btn>
            <q-btn
              outline
              icon="error"
              v-if="isLoggedIn && isTabFromUser"
              :disable="tab == ''"
              :label="isMarked(userId) ? 'Unmark attention' : 'Mark attention'"
              class="mark-button"
              @click="toggleAttention()"
            >
            </q-btn>
          </q-btn-group>
          <q-card flat>
            <q-card-section
              :class="($q.dark.isActive ? '' : '') + ' scrollable'"
            >
              <VueDepTree
                v-if="reactiveSentencesObj"
                v-on:statusChanged="handleStatusChange"
                :cardId="index"
                :conll="tree"
                :reactiveSentence="reactiveSentencesObj[user]"
                :teacherReactiveSentence="
                  showDiffTeacher
                    ? reactiveSentencesObj['teacher']
                    : diffMode
                    ? reactiveSentencesObj[diffUserId]
                    : {}
                "
                :sentenceId="sentenceId"
                :sentenceBus="sentenceBus"
                :userId="user"
                :conllSavedCounter="conllSavedCounter"
                :hasPendingChanges="hasPendingChanges"
                :matches="sentence.matches"
                :spaceBetween="spaceBetween"
                @setShownFeatures="setShownFeatures"
              ></VueDepTree>
            </q-card-section>
          </q-card>
        </q-tab-panel>
      </q-tab-panels>
      <q-list class="sentence__meta-features" v-if="tab" dense>
        <q-item v-for="meta in shownmeta" :key="meta">
          <q-chip dense size="xs">{{ meta }}</q-chip
          >{{ reactiveSentencesObj[tab].metaJson[meta] }}
        </q-item>
      </q-list>
    </q-card-section>
    <RelationDialog :sentenceBus="sentenceBus" />
    <UposDialog :sentenceBus="sentenceBus" />
    <MultipleUposDialog :sentenceBus="sentenceBus" />
    <EraseDialog
      :sentenceBus="sentenceBus"
      @erase-annotation="eraseAnnotation"
    />
    <FeaturesDialog :sentenceBus="sentenceBus" />
    <MetaDialog :sentenceBus="sentenceBus" />
    <ConlluDialog :sentenceBus="sentenceBus" />
    <ExportSVG :sentenceBus="sentenceBus" />
    <TokenDialog
      :sentenceBus="sentenceBus"
      :reactiveSentencesObj="reactiveSentencesObj"
      @changed:metaText="changeMetaText"
    />
    <MultiEditDialog
      :sentenceBus="sentenceBus"
      :reactiveSentencesObj="reactiveSentencesObj"
    />
    <StatisticsDialog
      :sentenceBus="sentenceBus"
      :conlls="sentenceData.conlls"
    />
  </q-card>
</template>

<script>
import Vue from "vue";

import { mapGetters } from "vuex";

import { LocalStorage } from "quasar";

import api from "../../boot/backend-api";

import { ReactiveSentence } from "../../helpers/ReactiveSentence"; // for test ony at the moment

import VueDepTree from "./VueDepTree.vue";
import RelationDialog from "./RelationDialog.vue";
import UposDialog from "./UposDialog.vue";
import MultipleUposDialog from "./MultipleUposDialog.vue";
import EraseDialog from "./EraseDialog.vue";
import FeaturesDialog from "./FeaturesDialog.vue";
import MetaDialog from "./MetaDialog.vue";
import ConlluDialog from "./ConlluDialog.vue";
import ExportSVG from "./ExportSVG.vue";
import TokenDialog from "./TokenDialog.vue";
import StatisticsDialog from "./StatisticsDialog.vue";
import MultiEditDialog from "./MultiEditDialog.vue";
import user from "src/store/modules/user";

export default {
  name: "SentenceCard",
  components: {
    VueDepTree,
    RelationDialog,
    UposDialog,
    MultipleUposDialog,
    FeaturesDialog,
    MetaDialog,
    ConlluDialog,
    ExportSVG,
    TokenDialog,
    StatisticsDialog,
    MultiEditDialog,
    EraseDialog,
  },
  props: [
    "index",
    "sentence",
    "sentenceId",
    "searchResult",
    "exerciseLevel",
    "isResult",
  ],
  data() {
    return {
      spaceBetween: 0,
      shownFeatures: [],
      sentenceBus: new Vue(), // Event/Object Bus that communicate between all components
      reactiveSentencesObj: {},
      tab: "",
      animated: false,
      sentenceData: this.$props.sentence,
      EMMETT: "emmett.strickland",
      graphInfo: { conllGraph: null, dirty: false, redo: false, user: "" },
      alerts: {
        markSuccess: { color: "positive", message: "Marked!" },
        saveSuccess: { color: "positive", message: "Saved!" },
        saveFail: {
          color: "negative",
          message: "Oops, could not save...",
          icon: "report_problem",
        },
      },
      conllSavedCounter: 0,
      shownmetanames: [],
      shownmetas: {},
      view: null,
      sentenceLink: "",
      diffMode: false,
      canUndo: false,
      canRedo: false,
      canSave: false,
      hasPendingChanges: {},
      isChecked: false,
    };
  },

  computed: {
    ...mapGetters("config", [
      "isAdmin",
      "isGuest",
      "guests",
      "admins",
      "exerciseMode",
      "shownmeta",
    ]),
    showDiffTeacher() {
      return this.exerciseMode && this.exerciseLevel <= 2;
    },
    currUser() {
      return this.$store.getters["user/getUserInfos"].username;
    },
    isTabFromUser() {
      return this.$store.getters["user/getUserInfos"].username === this.tab;
    },
    /**
     * Never used ?!
     * Check if the graph is dirty (I.E. modified but not saved) or open to see if it's supposed to be possible to save
     * @returns {Boolean}
     */
    cannotSave() {
      let dirty = this.graphInfo.dirty;
      return !dirty;
    },
    /**
     * Check the store to see if a user is logged in or not
     * @returns {Boolean}
     */
    isLoggedIn() {
      return this.$store.getters["user/isLoggedIn"];
    },
    filteredConlls() {
      Object.filter = (obj, predicate) =>
        Object.fromEntries(Object.entries(obj).filter(predicate));

      if (this.exerciseLevel != 1 && !this.isAdmin && this.exerciseMode) {
        return Object.filter(
          this.sentenceData.conlls,
          ([user, conll]) => user != "teacher"
        );
      } else {
        return this.sentenceData.conlls;
      }
    },
    orderedConlls() {
      let users = Object.keys(this.filteredConlls);
      let sortedUsers = users.sort();

      const orderedConlls = {};
      for (const user of sortedUsers) {
        orderedConlls[user] = this.filteredConlls[user];
      }
      return orderedConlls;
    },
    userId() {
      return this.$store.getters["user/getUserInfos"].username;
    },
    isBernardCaron() {
      return (
        this.$store.getters["user/getUserInfos"].username ==
          "bernard.l.caron" ||
        this.$store.getters["user/getUserInfos"].username == "kirianguiller"
      );
    },
    diffUserId() {
      let value = this.$store.getters["config/diffUserId"];
      return value ? value : this.userId;
    },
  },
  mounted() {
    // open a tab if it's search
    if (this.isResult) {
      this.tab = Object.keys(this.filteredConlls)[0];
    }
    // defines the color of the cards
    if (
      this.userId in this.reactiveSentencesObj &&
      "is_done" in this.reactiveSentencesObj[this.userId].metaJson &&
      this.reactiveSentencesObj[this.userId].metaJson.is_done === "1"
    ) {
      // green if it's checked
      this.isChecked = true;
    } else {
      // red if it's not checked
      this.isChecked = false;
    }

    // -- DESCRIPTION:
    // Event for saving the current tree by the defined shortcut.
    this.$root.$on("save-by-shortcut", () => {
      // saves the changes using the shortcut, if it's possible!
      if (this.tab !== "" && this.canSave && this.isLoggedIn) {
        this.save("");
      }
    });

    // -- DESCRIPTION:
    // Event for saving the current tree by the defined shortcut.
    this.$root.$on("check-by-shortcut", () => {
      // saves the changes using the shortcut, if it's possible!
      if (this.tab !== "" && !this.isChecked && this.isLoggedIn) {
        this.save("", true);
      }
    });

    // -- DESCRIPTION:
    // Event for undoing the last change in the current tree.
    this.$root.$on("undo-by-shortcut", () => {
      // saves the changes using the shortcut, if it's possible!
      if (this.tab !== "" && this.canUndo && this.isLoggedIn) {
        this.undo("user");
      }
    });

    // -- DESCRIPTION:
    // Event for redoing the last change in the current tree.
    this.$root.$on("redo-by-shortcut", () => {
      // saves the changes using the shortcut, if it's possible!
      if (this.tab !== "" && this.canRedo && this.isLoggedIn) {
        this.redo("user");
      }
    });
  },
  // -- DESCRIPTION:
  // Before destroying this component, eliminates every
  // tracked change and defines the possibility to save
  // changes as false.
  beforeDestroy() {
    this.canSave = false;
  },
  created() {
    this.shownmetanames =
      this.$store.getters["config/getProjectConfig"].shownmeta;

    for (const [userId, conll] of Object.entries(this.sentence.conlls)) {
      const reactiveSentence = new ReactiveSentence();
      reactiveSentence.fromConll(conll);
      this.reactiveSentencesObj[userId] = reactiveSentence;
      this.hasPendingChanges[userId] = false;
    }

    this.diffMode = !!this.$store.getters["config/diffMode"];
  },
  methods: {
    isMarked(user) {
      return (
        user in this.reactiveSentencesObj &&
        "is_marked" in this.reactiveSentencesObj[user].metaJson &&
        this.reactiveSentencesObj[user].metaJson.is_marked === "1"
      );
    },

    // updates sentence's metadata
    updateMeta(user, newMeta) {
      this.reactiveSentencesObj[user].updateMeta(newMeta);
      this.sentenceData.conlls[user] =
        this.reactiveSentencesObj[user].sentenceConll;
    },

    toggleAttention() {
      // gets the name of the user toggling the attention
      const user = this.$store.getters["user/getUserInfos"].username;

      // new meta
      const newMeta = {
        user_id: user,
        timestamp: Math.round(Date.now()),
        is_marked: this.isMarked(user) ? "0" : "1",
      };

      // gets the new CoNLL-U
      const newConll =
        this.reactiveSentencesObj[user].exportNonReactiveConll(newMeta);

      // action done by the user
      const action = this.isMarked(user) ? "Unmarked" : "Marked";

      // new data to save
      const data = {
        sent_id: this.sentenceId,
        conll: newConll,
        user_id: user,
        changes: [`${action} attention in the sentence.`],
        project_name: this.$route.params.projectname,
      };

      // saves new metadata
      api
        .updateTree(
          this.$route.params.projectname,
          this.$props.sentence.sample_name,
          data
        )
        .then((response) => {
          if (response.status == 200) {
            // updates trees (well, just its metadata)
            this.updateMeta(user, newMeta);

            // shows success message
            this.showNotif("top", "markSuccess");
          }
        })
        .catch((error) => {
          // show error message
          this.$store.dispatch("notifyError", { error: error });
        });
    },
    decreaseSpace() {
      this.spaceBetween = 30;
    },
    increaseSpace() {
      this.spaceBetween = 0;
    },
    // -- DESCRIPTION:
    // Updates the shown features in the drawing.
    setShownFeatures(shownFeatures) {
      this.shownFeatures = shownFeatures;
    },
    // -- DESCRIPTION:
    // Erase annotations of the sentence.
    eraseAnnotation(elementsToErase) {
      let wasModified = false;

      for (let token in this.reactiveSentencesObj[this.tab].treeJson) {
        // erases part of speech
        if (elementsToErase.category) {
          // erases in the object
          this.reactiveSentencesObj[this.tab].treeJson[token].UPOS = "_";
          wasModified = true;
        }

        // erases relations
        if (elementsToErase.relations) {
          // erases in the object
          this.reactiveSentencesObj[this.tab].treeJson[token].DEPREL = "_";
          this.reactiveSentencesObj[this.tab].treeJson[token].HEAD = NaN;
          wasModified = true;
        }

        // erases features
        if (elementsToErase.features) {
          // erases in the object
          this.reactiveSentencesObj[this.tab].treeJson[token].LEMMA = "_";
          this.reactiveSentencesObj[this.tab].treeJson[token].MISC = {};
          this.reactiveSentencesObj[this.tab].treeJson[token].FEATS = {};
          wasModified = true;
        }
      }

      // if the tree was modified, saves it and re-renders it
      if (wasModified) {
        // re-renders sentence
        this.conllSavedCounter += 1;
        // saves in the server
        this.sentenceBus.$emit("tree-update:tree", {
          tree: this.reactiveSentencesObj[this.tab].treeJson,
          userId: this.tab,
        });
      }
    },

    // -- DESCRIPTION:
    // Open the erase annotations dialog.
    openEraseDial() {
      this.sentenceBus.$emit("open:eraseDialog");
    },

    // -- DESCRIPTION:
    // Event handler to uncheck this sentence
    unchecks() {
      if (
        this.userId in this.reactiveSentencesObj &&
        "is_done" in this.reactiveSentencesObj[this.userId].metaJson
      ) {
        this.isChecked = false;
      }
    },

    // -- DESCRIPTION:
    // Executes a save of the tree triggered by the save all command.
    saveBySaveAll() {
      return new Promise((resolve, reject) => {
        if (this.canSave && this.isLoggedIn) {
          this.tab = this.userId;
          this.save("");
        }

        resolve();
      });
    },

    // to delete KK
    refresh() {
      this.$emit("refresh:trees");
      this.$forceUpdate();
    },
    /**
     * Set the sentence link and copy it after 500 ms
     *
     * @returns void
     */
    getlink() {
      this.sentenceLink =
        window.location.href.split(
          "/projects/" + this.$route.params.projectname
        )[0] +
        "/projects/" +
        this.$route.params.projectname +
        "/" +
        this.sentence.sample_name +
        "/" +
        (this.index + 1) +
        "/" +
        this.graphInfo.user;
      setTimeout(() => {
        this.$refs.linkinput.select();
        document.execCommand("copy");
      }, 500);
    },
    openStatisticsDialog() {
      this.sentenceBus.$emit("open:statisticsDialog", { userId: this.tab });
    },
    /**
     * Show the conll graph
     *
     * @returns void
     */
    openConllDialog() {
      this.sentenceBus.$emit("open:conlluDialog", { userId: this.tab });
    },
    openMultiEditDialog() {
      this.sentenceBus.$emit("open:openMultiEditDialog", { userId: this.tab });
    },
    /**
     * Get the SVG by creating it using snap arborator plugin and then replacing the placeholder in the current DOM
     * @todo instead of this long string, read the actual css file and put it there.
     *
     * @returns void
     */
    exportSVG() {
      // todo: instead of this long string, read the actual css file and put it there.
      this.sentenceBus.$emit("export:SVG", { userId: this.tab });
    },

    /**
     * Get the SVG by creating it using snap arborator plugin and then replacing the placeholder in the current DOM
     * @todo instead of this long string, read the actual css file and put it there.
     *
     * @returns void
     */
    exportPNG() {
      // todo: instead of this long string, read the actual css file and put it there.
      this.sentenceBus.$emit("export:PNG", { userId: this.tab });
    },
    /**
     * Handle token click event to display the related dialog
     *
     * @param {Event} event
     * @returns void
     */
    ttselect(event) {
      // only if a tab is open
      if (this.tab !== "") {
        this.sentenceBus.$emit("open:tokenDialog", {
          userId: this.tab,
          event: event,
        });
      }
    },
    /**
     * @todo undo
     */
    undo(mode) {
      if (this.tab !== "") {
        this.sentenceBus.$emit("action:undo", {
          userId: this.tab,
        });
      }
    },
    /**
     * @todo redo
     */
    redo(mode) {
      if (this.tab !== "") {
        this.sentenceBus.$emit("action:redo", {
          userId: this.tab,
        });
      }
    },
    /**
     * Receive canUndo, canRedo status from VueDepTree child component and
     * decide whether to disable undo, redo buttons or not
     */
    handleStatusChange(event) {
      this.canUndo = event.canUndo;
      this.canRedo = event.canRedo;
      this.canSave = event.canSave;
    },
    /**
     * triggers when the user selects another tab, and update canUndo, canRedo,
     * canSave status
     */
    handleTabChange() {
      // this line hides the tab panel if the user
      // clicked in the tab's name he's currently in
      this.tab = "";

      // wait for 10ms until this.tab get changed
      setTimeout(() => {
        this.sentenceBus.$emit("action:tabSelected", {
          userId: this.tab,
        });
      }, 10);
    },

    // DESCRIPTION:
    // If the sentence doesn't have a relation involving the
    // ROOT, notifies the user.
    async detectAndShowRootWarning(saveMultiple = false) {
      // looks up for a token which has the ROOT as it's head
      // exits the function, if it finds one
      for (let token_id in this.reactiveSentencesObj[this.tab].treeJson) {
        if (this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD === 0) {
          return;
        }
      }

      // warning notification
      this.$q.notify({
        type: "warning",
        timeout: 6000,
        position: "bottom",
        message:
          "This sentence does not have a dependency relation involving the ROOT!",
      });
    },

    // -- DESCRIPTION:
    // Tells whether the sentence tree is projective or not.
    // -- RETURNS:
    // [true, token's form, token's id] - if the sentence tree is projective.
    // [false] - if the sentence tree iisn't projective.
    isProjective() {
      // analyses every relation between every token
      for (let token_id in this.reactiveSentencesObj[this.tab].treeJson) {
        token_id = Number(token_id);
        // the relation between a token and the root doesn't count
        if (
          !this.isNullOrNaN(
            this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD
          ) &&
          this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD !== 0
        ) {
          // creates a set containing tokens which are successful
          const success = new Set();

          // adds the dep and the head in the successful set
          success.add(token_id);
          success.add(
            this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD
          );

          // calculates which one is the bigger and the smallest between
          // the dep and the head
          let upper = Math.max(
            token_id,
            this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD
          );
          let lower = Math.min(
            token_id,
            this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD
          );

          // for every token between the dep and the head...
          for (let middle = lower + 1; middle < upper; middle++) {
            let visitedToken =
              this.reactiveSentencesObj[this.tab].treeJson[middle].HEAD;

            // goes up the tree and verifies if there is a connection with a
            // successful token

            // creates a visited set to avoid infinite loops
            const visited = new Set();
            while (
              !this.isNullOrNaN(visitedToken) &&
              visitedToken !== 0 &&
              !success.has(visitedToken) &&
              !visited.has(visitedToken)
            ) {
              visited.add(visitedToken);
              visitedToken =
                this.reactiveSentencesObj[this.tab].treeJson[visitedToken].HEAD;
            }

            if (
              (this.isNullOrNaN(visitedToken) ||
                visitedToken === 0 ||
                visited.has(visitedToken)) &&
              !success.has(visitedToken)
            ) {
              // there isn't a connection with a successful token
              return [
                false,
                this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD,
                token_id,
              ];
            }

            // if a token is connected with a successful token, it is
            // successfull too!
            success.add(visitedToken);
          }
        }
      }
      return [true];
    },

    // -- DESCRIPTION:
    // Detects if it needs to fire the non-projectivity warning.
    // Fires it, if it needs to.
    async detectAndShowNonProjectivityWarning() {
      let isProjective = this.isProjective();
      if (!isProjective[0]) {
        // warning notification
        this.$q.notify({
          type: "warning",
          timeout: 6000,
          position: "bottom",
          message: `The "${
            this.reactiveSentencesObj[this.tab].treeJson[isProjective[1]].FORM
          }" (${isProjective[1]}) ----> "${
            this.reactiveSentencesObj[this.tab].treeJson[isProjective[2]].FORM
          }" (${isProjective[2]}) relation is non-projective!`,
        });
      }
    },

    // -- DESCRIPTION:
    // Detects if the sentence has multiple ROOTs
    // - Returns:
    //  true: if there are multiple ROOTs.
    //  false: if there are not multiple ROOTs.
    areThereMultipleRoots() {
      let headsNumber = 0;
      // counts the number of ROOTs
      for (let token_id in this.reactiveSentencesObj[this.tab].treeJson) {
        if (this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD === 0) {
          headsNumber++;
        }

        if (headsNumber > 1) {
          // if there is more than one root, returns true
          return true;
        }
      }
      // if there is more than one root, returns false
      return false;
    },

    // -- DESCRIPTION:
    // Detects if it needs to fire the multiple roots warning.
    // Fires it, if it needs to.
    async detectAndShowMultipleRootsWarning() {
      if (this.areThereMultipleRoots()) {
        // warning notification
        this.$q.notify({
          type: "warning",
          timeout: 6000,
          position: "bottom",
          message: "There are multiple ROOTs in this sentence!",
        });
      }
    },

    // -- DESCRIPTION:
    // Tells whether there are tokens without a HEAD in
    // the drawing.
    // -- RETURNS:
    // [true, token's form (first occurrence), token's id (first occurrence)]
    //    if there are.
    // [false] - if there are not.
    areThereNoHeadTokens() {
      for (let token_id in this.reactiveSentencesObj[this.tab].treeJson) {
        // gets the head value of the token with id token_id
        let headValue =
          this.reactiveSentencesObj[this.tab].treeJson[token_id].HEAD;

        // checks if the head is NaN
        // because a NaN head means the token does not have a head at all!
        if (this.isNullOrNaN(headValue)) {
          // returns an array with a boolean indicating
          // if there are disconnected tokens
          // the other element is the id of the disconnected token
          return [
            true,
            this.reactiveSentencesObj[this.tab].treeJson[token_id].FORM,
            token_id,
          ];
        }
      }
      return [false];
    },

    // -- DESCRIPTION:
    // Detects if it needs to fire the multiple roots warning.
    // Fires it, if it needs to.
    async detectAndShowNoHeadWarning() {
      let answer = this.areThereNoHeadTokens();
      if (answer[0]) {
        // warning notification
        this.$q.notify({
          type: "warning",
          timeout: 6000,
          position: "bottom",
          message: `The token ${answer[1]} (${answer[2]}) does not have a HEAD!`,
        });
      }
    },

    // -- DESCRIPTION:
    // Returns a boolean telling if the passed
    // value is null or NaN.
    isNullOrNaN(value) {
      return isNaN(value) || value === null;
    },

    /**
     * Save the graph to backend after modifying its metadata and changing it into an object
     *
     * @returns void
     */
    save(mode, isChecking = false) {
      let openedTreeUser = this.tab;

      // var conll = this.sentenceBus[currentTreeUser].exportConll();

      var changedConllUser = this.$store.getters["user/getUserInfos"].username;
      // if (mode == "teacher") {
      //   changedConllUser = "teacher";
      // }
      // if (mode == this.EMMETT) {
      //   changedConllUser = this.EMMETT;
      // }
      if (mode) {
        changedConllUser = mode;
      }

      // changes the status depending if it's checking
      // or not
      let status;
      if (isChecking) {
        status = "The user checked this sentence.";
      } else {
        status = "The user saved this sentence.";
      }

      let metaToReplace = {
        user_id: changedConllUser,
        timestamp: Math.round(Date.now()),
        is_done: 1, // mark as done every time the user saves
        status: status,
      };

      const exportedConll =
        this.reactiveSentencesObj[openedTreeUser].exportConllWithModifiedMeta(
          metaToReplace
        );

      // retrieves the changes made up until this moment (after the previous save)
      const changesToBeSaved =
        this.reactiveSentencesObj[openedTreeUser].changesBeforeSave;

      if (isChecking) {
        changesToBeSaved.push("Checked the sentence");
      }

      var data = {
        sent_id: this.sentenceId,
        conll: exportedConll,
        user_id: changedConllUser,
        changes: changesToBeSaved,
        project_name: this.$route.params.projectname,
      };

      // detects and triggers warnings
      if (this.shownFeatures.includes("TREE")) {
        // but just do it if the tree is visible, because
        // these warnings are all related to the tree
        this.detectAndShowRootWarning();
        this.detectAndShowNonProjectivityWarning();
        this.detectAndShowMultipleRootsWarning();
        this.detectAndShowNoHeadWarning();
      }

      api
        .updateTree(
          this.$route.params.projectname,
          this.$props.sentence.sample_name,
          data
        )
        .then((response) => {
          if (response.status == 200) {
            // live update fo the CoNLL-U's status
            this.sentenceBus[openedTreeUser].metaJson.status = status;
            this.$store.commit("empty_pending_modification");

            // when saved, define the sentence as checked
            this.isChecked = true;

            this.sentenceBus.$emit("action:saved", {
              userId: this.tab,
            });
            this.hasPendingChanges[this.tab] = false;
            if (this.sentenceData.conlls[changedConllUser]) {
              // the user already had a tree
              this.hasPendingChanges[changedConllUser] = false;
              this.sentenceData.conlls[changedConllUser] = exportedConll;
              this.reactiveSentencesObj[changedConllUser].sentenceConll =
                exportedConll;
              this.reactiveSentencesObj[
                changedConllUser
              ].updateNonReactiveTree();
            } else {
              // user still don't have a tree for this sentence, creating it.
              Vue.set(
                this.sentenceData.conlls,
                changedConllUser,
                exportedConll
              );
              const reactiveSentence = new ReactiveSentence();
              reactiveSentence.fromConll(exportedConll);
              Vue.set(
                this.reactiveSentencesObj,
                changedConllUser,
                reactiveSentence
              );
            }

            if (this.tab !== changedConllUser) {
              this.reactiveSentencesObj[this.tab].changesBeforeSave = [];
              this.reactiveSentencesObj[this.tab].fromConll(
                this.sentenceData.conlls[this.tab]
              );
              this.tab = changedConllUser;
              this.changedConllUser = changedConllUser;
              this.exportedConll = exportedConll;
            }

            this.graphInfo.dirty = false;
            this.showNotif("top", "saveSuccess");

            // if all the changes were saved successfully, clean the changes array
            this.reactiveSentencesObj[openedTreeUser].changesBeforeSave = [];
          }
        })
        .catch((error) => {
          this.$store.dispatch("notifyError", { error: error });
        });
    },
    transitioned() {
      if (this.exportedConll) {
        this.reactiveSentencesObj[this.changedConllUser].fromConll(
          this.exportedConll
        );
        this.exportedConll = "";
      }
    },
    /**
     * Set the graph infos according to the event payload. This event shoudl be trigerred from the ConllGraph
     *
     * @returns void
     */
    onConllGraphUpdate(payload) {
      this.graphInfo = payload;
      if (this.graphInfo.dirty == true)
        this.$store.commit("add_pending_modification", this.sentenceId);
      else this.$store.commit("remove_pending_modification", this.sentenceId);
    },
    openMetaDialog() {
      // "this.tab" contains the user name
      this.sentenceBus.$emit("open:metaDialog", { userId: this.tab });
    },
    /**
     * Show a notification. Wrapper considering parameters
     * @deprecated should use this.$q.notify instead. Global params are already set
     *
     * @param {String} position 'top-right' etc
     * @param {String} alert 'warn', ect.
     * @returns void
     */
    changeMetaText(newMetaText) {
      this.sentenceData.sentence = newMetaText;
    },

    toggleDiffMode() {
      this.diffMode = !this.diffMode;
      for (const otherUserId in this.reactiveSentencesObj) {
        if (otherUserId != this.diffUserId) {
          if (this.sentenceBus[otherUserId]) {
            this.sentenceBus[otherUserId].plugDiffTree(
              this.diffMode ? this.reactiveSentencesObj[this.diffUserId] : {}
            );
            // this.sentenceBus[otherUserId].drawTree()
          }
          this.conllSavedCounter += 1;
        }
      }
    },

    showNotif(position, alert) {
      const { color, textColor, multiLine, icon, message, avatar, actions } =
        this.alerts[alert];
      const buttonColor = color ? "white" : void 0;
      this.$q.notify({
        color,
        textColor,
        icon: icon,
        message,
        position,
        avatar,
        multiLine,
        actions: actions,
        timeout: 2000,
      });
    },
  },
};
</script>

<style>
.action-buttons {
  padding-left: 16px;
  border-radius: 5px;
}

.can-save {
  background-color: #ffff99;
}

.not-checked {
  background-color: #ffcccb;
}

.checked {
  background-color: #90ee90;
}

.checked-tab {
  background: #90ee90 !important;
}

.marked-tab {
  background: #9fb7ff !important;
}

.not-checked-tab {
  background: #ffcccb !important;
}

.can-save-tab {
  background: #ffff99 !important;
}

.sentence-table {
  position: relative;
  width: 100%;
}

.check-button {
  color: green;
}

.erase-button {
  color: purple;
}

.mark-button {
  color: #000099;
}

.scrollable {
  overflow: scroll;
}

.custom-fade-enter-active {
  transition: all 0.3s ease;
}
.custom-fade-leave-active {
  transition: all 0.8s cubic-bezier(1, 0.5, 0.8, 1);
}
.custom-fade-enter, .custom-fade-leave-to
/* .slide-fade-leave-active below version 2.1.8 */ {
  transform: translateX(10px);
  opacity: 0;
}

.easeOutSine.q-transition--slide-right-leave-active,
.easeOutSine.q-transition--slide-left-leave-active {
  transition: opacity 1s !important;
}

.easeOutSine.q-transition--slide-right-enter-active,
.easeOutSine.q-transition--slide-left-enter-active {
  transition: opacity 1s !important;
}
/* transition-delay: 2s !important; */

.easeOutSine.q-transition--slide-right-enter,
.easeOutSine.q-transition--slide-left-enter {
  opacity: 0 !important;
  transition-delay: 2s !important;
}

.easeOutSine.q-transition--slide-right-leave-to,
.easeOutSine.q-transition--slide-left-leave-to {
  opacity: 0 !important;
}

.easeOutSine .q-transition--slide-right-leave-from,
.easeOutSine .q-transition--slide-left-leave-from {
  opacity: 1 !important;
}

/* .easeOutCubic .q-transition--slide-right-enter-active,
.easeOutCubic .q-transition--slide-left-enter-active,
.easeOutCubic .q-transition--slide-up-enter-active,
.easeOutCubic .q-transition--slide-down-enter-active,
.easeOutCubic .q-transition--slide-right-leave-active,
.easeOutCubic .q-transition--slide-left-leave-active,
.easeOutCubic .q-transition--slide-up-leave-active,
.easeOutCubic .q-transition--slide-down-leave-active { */
/* easeOutCubic */
/* transition: transform 0.3s cubic-bezier(0.215, 0.61, 0.355, 1) !important;
} */
</style>
