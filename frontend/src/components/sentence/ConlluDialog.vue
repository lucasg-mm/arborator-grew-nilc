<template>
  <!----------------- Start ConllDialog ------------------->
  <q-dialog
    :maximized="maximizedToggle"
    v-model="conlluDialogOpened"
    full-width
  >
    <q-layout view="Lhh lpR fff" container class="bg-white">
      <q-header class="bg-primary">
        <q-toolbar>
          <q-toolbar-title>CoNLL of the sentence</q-toolbar-title>
          <q-btn
            dense
            flat
            icon="minimize"
            @click="toggleSize"
            :disable="!maximizedToggle"
          >
          </q-btn>
          <q-btn
            dense
            flat
            icon="crop_square"
            @click="toggleSize"
            :disable="maximizedToggle"
          >
          </q-btn>
          <q-btn flat v-close-popup round dense icon="close" />
        </q-toolbar>
      </q-header>
      <q-page-container>
        <codemirror
          ref="conlluEditor"
          v-model="conllContent"
          :options="cmOption"
          class="CodeMirror"
          style="height: 100%"
          @focus="codefocus"
        >
        </codemirror>
      </q-page-container>
      <q-footer>
        <q-toolbar inset>
          <!-- <q-toolbar-title>Footer</q-toolbar-title> --><q-space />
          <q-btn flat no-caps label="Cancel" v-close-popup />
          <q-btn
            color="primary"
            @click="onConllDialogOk()"
            label="Ok"
            v-close-popup
            :disabled="currentConllContent == conllContent"
          />
        </q-toolbar>
      </q-footer>
    </q-layout>
  </q-dialog>
  <!----------------- End ConllDialog ------------------->
</template>

<script>
import { conllToJson } from "../../helpers/Conll";
import { codemirror } from "vue-codemirror";
import CodeMirror from "codemirror";

CodeMirror.defineMode("tsv", function (_config, parserConfig) {
  function tokenBase(stream, state) {
    if (stream.string.match(/^#.+/)) {
      stream.skipToEnd();
      return "comment";
    }

    var ch = stream.next();

    if (/\d/.test(ch)) {
      stream.eatWhile(/[\d]/);
      if (stream.eat(".")) {
        stream.eatWhile(/[\d]/);
      }
      return "number";
    }
    if (/[+\-*&%=<>!?|:]/.test(ch)) {
      return "operator";
    }
    stream.eatWhile(/\w/);
    var cur = stream.current();
    return "variable";
  }

  // function tokenString(stream, state) {	}

  return {
    startState: function () {
      return { tokenize: tokenBase, commentLevel: 0 };
    },
    token: function (stream, state) {
      if (stream.eatSpace()) return null;
      return state.tokenize(stream, state);
    },
    lineComment: "#",
  };
}); // end codemirror

export default {
  components: { codemirror },
  props: ["sentenceBus"],
  data() {
    return {
      maximizedToggle: true,
      conlluDialogOpened: false,
      currentConllContent: "",
      conllContent: "",
      cmOption: {
        tabSize: 8,
        styleActiveLine: true,
        // lineNumbers: true,
        lineWrapping: true,
        line: true,
        mode: "tsv",

        theme: "default",
      },
    };
  },
  computed: {},
  mounted() {
    this.sentenceBus.$on("open:conlluDialog", ({ userId }) => {
      this.userId = userId;
      this.conlluDialogOpened = true;
      this.currentConllContent = this.sentenceBus[this.userId].exportConll();
      this.conllContent = this.sentenceBus[this.userId].exportConll();
      this.$nextTick(function () {
        // updates the height
        this.$refs.conlluEditor.cminstance.setSize(null, "100%");
      });
    });
  },
  methods: {
    // -- DESCRIPTION:
    // Blocks appropriate buttons and emit an event
    // telling the parent to maximize/minimize de dialogue.
    toggleSize() {
      this.maximizedToggle = !this.maximizedToggle;
      // this.$emit("maximizedToggle");
    },
    codefocus(cm, ev) {
      cm.refresh();
      cm.execCommand("selectAll");
    },
    onConllDialogOk() {
      const sentenceJson = conllToJson(this.conllContent);
      const oldMeta = this.sentenceBus[this.userId].metaJson;
      const newMeta = sentenceJson.metaJson;

      var isMetaChanged = 0;
      for (const [metaKey, metaValue] of Object.entries(newMeta)) {
        if (metaValue != oldMeta[metaKey]) {
          isMetaChanged = 1;
        }
      }
      if (!isMetaChanged) {
        this.sentenceBus[this.userId].treeJson = sentenceJson.treeJson;
        this.sentenceBus[this.userId].metaJson = sentenceJson.metaJson;
        this.sentenceBus[this.userId].refresh();

        this.sentenceBus.$emit("tree-update:tree", {
          tree: sentenceJson.treeJson,
          userId: this.userId,
        });

        this.$q.notify({
          message: `Conllu changed`,
        });
      } else {
        this.$store.dispatch("notifyError", {
          error: "Changing meta this way is not allowed (yet)",
        });
      }
    },
  },
};
</script>

<style></style>
