<template>
  <q-page :class="$q.dark.isActive ? 'bg-dark' : 'bg-grey-1'">
    <div v-show="!loading" class="q-pa-md row q-gutter-md">
      <q-virtual-scroll
        ref="virtualListRef"
        :items="sentencesFrozen.list"
        style="max-height: 95vh; width: 99vw"
        :virtual-scroll-slice-size="7"
        :virtual-scroll-item-size="200"
      >
        <template v-slot="{ item, index }">
          <SentenceCard
            :key="index"
            :ref="'sc' + index"
            :id="'sc' + index"
            :sentence="sentences[item]"
            :index="index"
            :sentenceId="item"
            searchResult=""
            v-on:refresh:trees="getSampleTrees"
            :exerciseLevel="exerciseLevel"
          >
          </SentenceCard>
        </template>
      </q-virtual-scroll>
    </div>
    <div v-show="loading" class="q-pa-md row justify-center">
      <div class="absolute-center">
        <q-circular-progress
          indeterminate
          size="70px"
          :thickness="0.22"
          color="primary"
          track-color="grey-3"
        />
      </div>
    </div>
    <template
      v-if="
        !(
          $store.getters['config/exerciseMode'] &&
          !$store.getters['config/isTeacher']
        )
      "
    >
      <GrewSearch :sentenceCount="sentenceCount" />
      <RelationTableMain />
      <q-page-sticky
        position="bottom-right"
        :offset="[18, 158]"
        style="z-index: 999"
        v-if="$store.getters['user/isLoggedIn']"
      >
        <q-btn
          size="20px"
          round
          color="primary"
          icon="autorenew"
          class="text-red"
          @click="uncheckAllSentences"
        >
          <q-tooltip content-class="bg-primary" content-style="font-size: 16px">
            Uncheck every sentence
          </q-tooltip>
        </q-btn>
      </q-page-sticky>
    </template>

    <q-dialog v-model="leaveDial">
      <leave :parentAction="leaveCallback" :arg1="leaveArg1"></leave>
    </q-dialog>
  </q-page>
</template>

<script>
import Vue from "vue";

import { mapGetters } from "vuex";

import { LocalStorage, openURL } from "quasar";

import { ReactiveSentence } from "../helpers/ReactiveSentence";

import api from "../boot/backend-api";

import Store from "../store/index";

import SentenceCard from "../components/sentence/SentenceCard";
import GrewSearch from "../components/grewSearch/GrewSearch";
import RelationTableMain from "../components/relationTable/RelationTableMain";
import Leave from "../components/Leave";

var heavyList = [];

export default {
  components: {
    SentenceCard,
    GrewSearch,
    RelationTableMain,
    Leave,
  },
  props: ["projectname", "samplename", "nr", "user"],
  data() {
    return {
      exerciseLevel: 4,
      svg: "",
      tab: "gold",
      loading: true,
      sentences: {},
      sentencesFrozen: { list: [], indexes: {} },
      window: { width: 0, height: 0 },
      virtualListIndex: 15,
      scrolalaTimeStep: 10, // give the scroll 10 seconds
      leaveDial: false,
      leaveCallback: null,
      leaveArg1: "",
    };
  },
  computed: {
    ...mapGetters("config", ["isAdmin", "exerciseMode"]),
    ...mapGetters("user", ["isSuperAdmin"]),
    sentenceCount() {
      return Object.keys(this.sentences).length;
    },
  },
  created() {
    window.addEventListener("resize", this.handleResize);
    this.handleResize();
  },
  destroyed() {
    window.removeEventListener("resize", this.handleResize);
  },
  mounted() {
    this.getSampleTrees();
    document.title =
      this.$route.params.projectname + "/" + this.$route.params.samplename;
    if (this.$route.query.q && this.$route.query.q.length > 0)
      this.searchDialog = true;
    LocalStorage.remove("save_status");
  },
  beforeRouteLeave(to, from, next) {
    // before leaving the route...

    // if there are non saved changes...
    if (this.$store.getters.getPendingModifications.size > 0) {
      // triggers the leave pop-up
      this.triggerLeave((event) => {
        // if the user clicked in the cancel button
        if (event === "cancel") {
          // stay in the route
          next(false);
        }
        // if the user just wants to leave without saving
        else if (event === "dont-save") {
          // empty changes
          this.$store.commit("empty_pending_modification");

          // leaves the route
          next();
        }
        // if the user wants to save all before leaving
        else {
          // empty changes
          this.$store.commit("empty_pending_modification");

          // use promisses to ensure everything was saved!
          this.saveAllUnsaved().then(() => {
            // and then leaves
            next();
          });
        }
      });
    } else {
      next();
    }
  },
  methods: {
    // -- DESCRIPTION
    // Unchecks every sentence in the server.
    async uncheckAllSentences() {
      // gets the logged user's name
      const { username } = this.$store.getters["user/getUserInfos"];
      let index = 0;

      // unchecks every sentence already annotated by the logged
      // user
      for (let sentence in this.sentences) {
        if (username in this.sentences[sentence].conlls) {
          // creates a new ReactiveSentence to manipulate the ConLL-U
          let reactiveSentence = new ReactiveSentence();

          // converts the ConLL-U to an object
          reactiveSentence.fromConll(this.sentences[sentence].conlls[username]);

          // just marks as undone things that are marked as done
          if (reactiveSentence.metaJson.is_done === "1") {
            // defines the new meta (now with is_done defined to 0)
            const metaToReplace = {
              user_id: username,
              timestamp: Math.round(Date.now()),
              is_done: 0, // mark as done every time the user saves
              state: "The user unchecked this sentence.",
            };

            // gets the ConLL-U with updated meta
            const exportedConll =
              reactiveSentence.exportConllWithModifiedMeta(metaToReplace);

            // prepares the data to send to server
            let data = {
              sent_id: sentence,
              conll: exportedConll,
              user_id: username,
              changes: ["Unchecked sentence"],
              project_name: this.projectname,
            };

            try {
              // sends the data to the api
              await api.updateTree(this.projectname, this.samplename, data);

              // changes the card's color
              if (typeof this.$refs["sc" + index] !== "undefined") {
                this.$refs["sc" + index].unchecks();
              }
              this.sentences[sentence].conlls[username] = exportedConll;

              // success message
              this.$q.notify({
                message: "The sentence was succesfully unchecked!",
                position: "top",
              });
            } catch (error) {
              // success message
              this.$q.notify({
                type: "error",
                message: "The sentence couldn't be unchecked!",
                position: "top",
              });
            }
          }
        }

        index++;
      }
    },

    // -- DESCRIPTION:
    // Saves every sentence that is still unsaved.
    saveAllUnsaved() {
      return new Promise(async (resolve, reject) => {
        let index = 0;
        for (let keys in this.sentences) {
          if (typeof this.$refs["sc" + index] !== "undefined") {
            await this.$refs["sc" + index].saveBySaveAll();
          }
          index++;
        }
        resolve();
      });
    },
    handleResize() {
      this.window.width = window.innerWidth;
      this.window.height = window.innerHeight;
    },
    getSampleTrees() {
      this.loading = true;
      api
        .getSampleTrees(this.projectname, this.samplename)
        .then((response) => {
          this.sentences = response.data.sample_trees;
          this.exerciseLevel = response.data.exercise_level;
          this.freezesentences();
          this.$forceUpdate();
          this.loading = false;
          if (this.$refs && this.$refs.virtualListRef && this.$route.params.nr)
            this.intr = setInterval(() => {
              this.scrolala();
            }, 1000);
        })
        .catch((error) => {
          this.$store.dispatch("notifyError", { error: error });
          this.loading = false;
        });
    },
    scrolala() {
      if (
        !this.loading &&
        this.$refs &&
        this.$refs.virtualListRef &&
        this.$route.params.nr != undefined &&
        parseInt(this.$route.params.nr) <= this.sentencesFrozen.list.length
      ) {
        var id = parseInt(this.$route.params.nr) - 1;
        this.$refs.virtualListRef.scrollTo(id);
        clearInterval(this.intr);
        setTimeout(() => {
          if ("sc" + id in this.$refs)
            this.$refs["sc" + id].autoopen(this.$route.params.user);
        }, 2000);
      }
      this.scrolalaTimeStep--;
      if (!this.scrolalaTimeStep) clearInterval(this.intr);
    },
    freezesentences() {
      var index = 0;
      var listsentences = [];
      var index2sentId = {};
      for (let sentId in this.sentences) {
        listsentences.push(sentId);
        index2sentId[index] = sentId;
        index++;
      }
      heavyList = listsentences;
      Object.freeze(heavyList);
      this.sentencesFrozen = { list: heavyList, indexes: index2sentId };
    },
    triggerLeave(method, arg) {
      this.leaveDial = true;
      this.leaveCallback = method;
      this.leaveArg1 = arg;
    },
  },
};
</script>
