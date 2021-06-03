<template>
  <div>
    <div
      :class="{ focused: hasFocus }"
      @click="
        manageFocus();
        clearGroupedTokens($event);
      "
      v-hotkey.prevent="keymap"
      class="sentencebox"
      style="min-width: max-content"
    >
      <svg :id="svgID" />
    </div>
  </div>
</template>

<script>
import { LocalStorage } from "quasar";
import { conllToJson } from "../../helpers/Conll";
import { SentenceSVG } from "../../helpers/SentenceSVG";

export default {
  props: [
    "sentenceId",
    "conll",
    "sentenceBus",
    "userId",
    "conllSavedCounter",
    "reactiveSentence",
    "teacherReactiveSentence",
    "cardId",
    "hasPendingChanges",
    "matches",
  ],
  watch: {
    conllSavedCounter() {
      this.sentenceSVG.drawTree();
    },
  },
  data() {
    return {
      sentenceSVG: null,
      sentenceJson: {},
      usermatches: [],
      history: [],
      history_index: -1,
      history_end: -1,
      history_saveIndex: -1,

      // boolean indicating if the tree has the focus right now
      hasFocus: false,
    };
  },
  computed: {
    svgID() {
      return `svg-${this.sentenceId}-${
        this.userId
      }-${new Date().getTime()}`.replaceAll(".", "-");
    },
    shownFeatures() {
      return this.$store.getters["config/shownfeatures"];
    },
    keymap() {
      if (this.hasFocus) {
        return {
          // ctrl+click: select many UPOS
          "shift+r": this.repeatPOS,
          "shift+s": this.saveTreeByShortcut,
          "shift+u": this.undoChangeByShortcut,
          "shift+d": this.redoChangeByShortcut,
          "shift+n": this.setsNextHighlightedUPOS,
          "shift+p": this.setsPreviousHighlightedUPOS,
          space: this.openUPOSWindow,
        };
      } else {
        return {};
      }
    },
  },
  mounted() {
    const sentenceJson = conllToJson(this.conll);
    let interactive = true;
    if (
      this.$store.getters["config/isStudent"] == true &&
      this.userId == this.$store.getters["config/TEACHER"]
    ) {
      interactive = false;
    }

    // the id of the most recent token is used by the
    // SentenceSVG to render the current token highlighted
    // by the cursor in a different color
    this.reactiveSentence.idOfMostRecentToken = 1;

    // we should also store the previous most recent token
    // to restore its original style after it's not the
    // most recent anymore
    this.reactiveSentence.prevIdOfMostRecentToken = null;

    // array of ids of tokens grouped by the user
    // a group can be formed in order to change the
    // tags of the grouped tokens in a simultaneous way
    this.reactiveSentence.groupedTokens = [];

    // we should also store the previous grouped tokens
    // to restore their original style after they're not
    // in the group anymore
    this.reactiveSentence.prevGroupedTokens = [];

    this.sentenceSVG = new SentenceSVG({
      svgID: this.svgID,
      reactiveSentence: this.reactiveSentence,
      usermatches: this.matches[this.userId],
      shownFeatures: this.shownFeatures,
      teacherReactiveSentence: this.teacherReactiveSentence,
      interactive: interactive,
    });
    this.sentenceSVG.plugDiffTree(this.teacherReactiveSentence);
    this.sentenceSVG.updateHighlighted();

    this.sentenceBus[this.userId] = this.sentenceSVG;

    this.sentenceSVG.addEventListener("svg-click", (e) => {
      this.svgClickHandler(e);
    });

    this.sentenceSVG.addEventListener("svg-drop", (e) => {
      this.svgDropHandler(e);
    });

    // -- Description:
    // Unfocus tree if it's not the tree that
    // emmited the unfocus 'event'.
    this.$root.$on("unfocus", (source) => {
      if (source !== this) {
        this.hasFocus = false;
      }
    });

    this.sentenceBus.$on("tree-update:token", ({ token, userId }) => {
      if (userId == this.userId) {
        let prevToken = this.reactiveSentence.getToken(token.ID);

        this.history[++this.history_index] = {
          old: [{ ...prevToken }],
          new: [{ ...token }],
        };

        // saves the id of the token that the user interacted with
        // most recently
        this.reactiveSentence.prevIdOfMostRecentToken =
          this.reactiveSentence.idOfMostRecentToken;
        this.reactiveSentence.idOfMostRecentToken = token.ID;

        // tracks modification in this sentence (vuex store)
        this.$store.commit(
          "add_pending_modification",
          this.reactiveSentence.metaJson.sent_id
        );

        // tracks changes in the token
        this.reactiveSentence.changesBeforeSave.push(
          ...this.detectChangesToken(prevToken, token, sentenceJson)
        );

        this.history_end = this.history_index;
        this.reactiveSentence.updateToken(token);
        this.statusChangeHadler();
      }
    });

    this.sentenceBus.$on("tree-update:tree", ({ tree, userId }) => {
      if (userId == this.userId) {
        // store current tree into prevToken
        let prevToken = [],
          newToken = [];
        for (const index in tree) {
          prevToken.push(this.reactiveSentence.getToken(index));
        }
        //update tree
        this.reactiveSentence.updateTree(tree);

        // tracks modification in this sentence (vuex store)
        this.$store.commit(
          "add_pending_modification",
          this.reactiveSentence.metaJson.sent_id
        );
        // store updated tree into newToken and add into history
        for (const index in tree) {
          newToken.push(this.reactiveSentence.getToken(index));

          // tracks changes in the token
          this.reactiveSentence.changesBeforeSave.push(
            ...this.detectChangesToken(
              prevToken[index - 1],
              newToken[index - 1],
              sentenceJson
            )
          );
        }
        this.history[++this.history_index] = {
          old: [...prevToken],
          new: [...newToken],
        };
        this.history_end = this.history_index;

        this.statusChangeHadler();
      }
    });
    this.sentenceBus.$on("action:undo", ({ userId }) => {
      if (userId == this.userId && this.history_index != -1) {
        const oldToken = this.history[this.history_index].old;
        const newToken = this.history[this.history_index].new;

        // tracks changes in the token
        for (let i = 0; i < newToken.length && i < oldToken.length; i++) {
          this.reactiveSentence.changesBeforeSave.push(
            ...this.detectChangesToken(newToken[i], oldToken[i], sentenceJson)
          );
        }

        const length = oldToken.length;
        let index;
        // this is to avoid unneccessary drawing
        // when updating multiple tokens
        for (index = 0; index < length - 1; index++)
          this.reactiveSentence.updateToken(oldToken[index], false);
        // draw the whole tree when last token is updated
        this.reactiveSentence.updateToken(oldToken[index]);
        this.history_index--;
        this.statusChangeHadler();
      }
    });
    this.sentenceBus.$on("action:redo", ({ userId }) => {
      if (userId == this.userId && this.history_index != this.history_end) {
        const newToken = this.history[++this.history_index].new;
        const oldToken = this.history[this.history_index].old;
        const length = newToken.length;
        let index;
        // this is to avoid unneccessary drawing
        // when updating multiple tokens

        // tracks changes in the token
        for (let i = 0; i < newToken.length && i < oldToken.length; i++) {
          this.reactiveSentence.changesBeforeSave.push(
            ...this.detectChangesToken(oldToken[i], newToken[i], sentenceJson)
          );
        }

        for (index = 0; index < length - 1; index++) {
          this.reactiveSentence.updateToken(newToken[index], false);
        }
        // draw the whole tree when last token is updated
        this.reactiveSentence.updateToken(newToken[index]);
        this.statusChangeHadler();
      }
    });
    this.sentenceBus.$on("action:saved", ({ userId }) => {
      if (userId == this.userId) {
        this.history_saveIndex = this.history_index;
        this.statusChangeHadler();
      }
    });

    this.sentenceBus.$on("action:tabSelected", ({ userId }) => {
      if (userId == this.userId) {
        this.statusChangeHadler();
      }
    });

    this.statusChangeHadler();
  },
  activated() {
    // every time the component is activated,
    // switch the focus to it.
    this.manageFocus();
  },
  methods: {
    // -- Description:
    // Opens the UPOS window of the highlighted UPOS.
    openUPOSWindow() {
      // gets the user's id
      const userId = this.userId;

      // gets the number of grouped tokens
      const numberOfGroupedTokens = this.reactiveSentence.groupedTokens.length;

      // if the number of grouped items is zero or one, just changes the most
      // recent token
      if (numberOfGroupedTokens >= 0 && numberOfGroupedTokens <= 1) {
        // gets the id of the highlighted upos
        const idSelected = this.reactiveSentence.idOfMostRecentToken;

        // gets the token of the highlighted upos
        const token = this.reactiveSentence.treeJson[idSelected];

        // opens the UPOS dialog window
        this.sentenceBus.$emit("open:uposDialog", { token, userId }, true);
      } else {
        // if the number of grouped items more than one, changes every
        // grouped token

        // gets the array of IDs of grouped tokens
        const idsGroupedTokens = this.reactiveSentence.groupedTokens;

        // this array shall store every grouped token
        const tokens = [];

        // put every token in the array
        for (const id of idsGroupedTokens) {
          tokens.push(this.reactiveSentence.treeJson[id]);
        }

        // opens the UPOS dialog window
        this.sentenceBus.$emit(
          "open:multipleUposDialog",
          { tokens, userId },
          true
        );
      }
    },

    // -- Description:
    // defines the highlighted upos as the next one
    // (the one in the right)
    setsNextHighlightedUPOS() {
      // gets the number of grouped tokens
      const numberOfGroupedTokens = this.reactiveSentence.groupedTokens.length;

      // this shortcut only works ith the number of grouped
      // items is either 0 or 1
      if (numberOfGroupedTokens <= 1) {
        // gets the nummber of tokens in the sentence
        const numberOfTokens = Object.keys(
          this.reactiveSentence.treeJson
        ).length;

        if (this.reactiveSentence.idOfMostRecentToken >= numberOfTokens) {
          // if the current highlighted token is the last,
          // the next is the first one
          this.reactiveSentence.prevIdOfMostRecentToken =
            this.reactiveSentence.idOfMostRecentToken;
          this.reactiveSentence.idOfMostRecentToken = 1;
        } else {
          // if the current highlighted token is one in the middle,
          // the next is the one in the right
          this.reactiveSentence.prevIdOfMostRecentToken =
            this.reactiveSentence.idOfMostRecentToken;
          this.reactiveSentence.idOfMostRecentToken++;
        }

        // updates the drawing to highlight the marked UPOS
        this.sentenceSVG.updateHighlighted();
      }
    },

    // -- Description:
    // defines the highlighted upos as the previous one
    // (the one in the left)
    setsPreviousHighlightedUPOS() {
      // gets the number of grouped tokens
      const numberOfGroupedTokens = this.reactiveSentence.groupedTokens.length;

      // this shortcut only works ith the number of grouped
      // items is either 0 or 1
      if (numberOfGroupedTokens <= 1) {
        // gets the number of tokens in the sentence
        const numberOfTokens = Object.keys(
          this.reactiveSentence.treeJson
        ).length;

        if (this.reactiveSentence.idOfMostRecentToken <= 1) {
          // if the current highlighted token is the first,
          // the next is the last one
          this.reactiveSentence.prevIdOfMostRecentToken =
            this.reactiveSentence.idOfMostRecentToken;
          this.reactiveSentence.idOfMostRecentToken = numberOfTokens;
        } else {
          // if the current highlighted token is in the middle,
          // the next is the one in the left
          this.reactiveSentence.prevIdOfMostRecentToken =
            this.reactiveSentence.idOfMostRecentToken;
          this.reactiveSentence.idOfMostRecentToken--;
        }

        // updates the drawing to highlighted the marked UPOS
        this.sentenceSVG.updateHighlighted();
      }
    },

    // -- Description:
    // Redoes the last change on the current tree. Gets triggered by
    // the defined shortcut.
    redoChangeByShortcut() {
      // emits event to save
      this.$root.$emit("redo-by-shortcut");
    },

    // -- Description:
    // Undoes the last change on the current tree. Gets triggered by
    // the defined shortcut.
    undoChangeByShortcut() {
      // emits event to save
      this.$root.$emit("undo-by-shortcut");
    },

    // -- Description:
    // Saves the current tree. Gets triggered by
    // the defined shortcut.
    saveTreeByShortcut() {
      // emits event to save
      this.$root.$emit("save-by-shortcut");
    },

    // -- Description:
    // Manages the focus of a tree.
    // If a sentence has the focus, the user
    // is able to use the shortcuts in it.
    manageFocus() {
      // focus this tree
      this.hasFocus = true;

      // unfocus every other tree
      this.$root.$emit("unfocus", this);
    },

    // -- Description:
    // Clears the array of grouped items
    // when the users clicks in the svg
    // without pressing the modifier key
    clearGroupedTokens(e) {
      if (!e.ctrlKey) {
        // clears the array of grouped tokens
        this.reactiveSentence.prevGroupedTokens =
          this.reactiveSentence.groupedTokens;
        this.reactiveSentence.groupedTokens = [];

        // updates the drawing
        this.sentenceSVG.updateHighlighted();
      }
    },

    // -- Description:
    // Repeats the Part of Speech for the token on the
    // right of the last one that the user interacted with
    repeatPOS() {
      // gets the number of grouped tokens
      const numberOfGroupedTokens = this.reactiveSentence.groupedTokens.length;

      // this shortcut only works ith the number of grouped
      // items is either 0 or 1
      if (numberOfGroupedTokens <= 1) {
        const treeJson = this.reactiveSentence.treeJson;
        const numberOfTokens = Object.keys(treeJson).length;
        const newPOS = treeJson[this.reactiveSentence.idOfMostRecentToken].UPOS;

        // checks if the id of the token that the user interacted with
        // most recently is the last one in the sentence
        if (this.reactiveSentence.idOfMostRecentToken >= numberOfTokens) {
          // defines the POS of the first token the same as the last token
          treeJson[1].UPOS = newPOS;
          this.sentenceBus.$emit("tree-update:token", {
            token: treeJson[1],
            userId: this.userId,
          });
        } else {
          // defines the POS of the token on the right the same as the last token
          // the user interacted with.
          treeJson[1 + this.reactiveSentence.idOfMostRecentToken].UPOS = newPOS;

          this.sentenceBus.$emit("tree-update:token", {
            token: treeJson[1 + this.reactiveSentence.idOfMostRecentToken],
            userId: this.userId,
          });
        }
      }
    },

    // -- Description:
    // Returns an array describing the removal of a universal/miscellaneous feature in a token.
    // -- Parameters:
    // prev - Object with keys (name of the feature) and values (value of the feature) before
    //        the change was made
    // curr - Object with keys (name of the feature) and values (value of the feature) after
    //        the change was made
    // featureName - Name of the feature to be analyzed. It can be 'miscellaneous feature'
    //               or 'universal feature'
    // tokenName - Name of the token to which the removed feature is from.
    // -- Returns:
    // removes - List of strings describing the removals.
    detectRemoveFeature(prev, curr, featureName, tokenName) {
      let removes = [];

      for (const key in prev) {
        if (!(key in curr)) {
          removes.push(
            `Removed the following ${featureName} of ${tokenName}: "${key}"`
          );
        }
      }

      return removes;
    },

    // -- Description:
    // Returns an array describing creation of a universal/miscellaneous feature in a token.
    // -- Parameters:
    // prev - Object with keys (name of the feature) and values (value of the feature) before
    //        the change was made
    // curr - Object with keys (name of the feature) and values (value of the feature) after
    //        the change was made
    // featureName - Name of the type of feature to be analyzed. It's either 'miscellaneous
    //               feature' or 'universal feature'
    // tokenName - Name of the token to which the removed feature is from.
    // -- Returns:
    // creates - List of strings describing the creations
    detectCreateFeature(prev, curr, featureName, tokenName) {
      let creates = [];

      for (const key in curr) {
        if (!(key in prev)) {
          creates.push(
            `Created the following ${featureName} of ${tokenName}: "${key}" with the value of "${curr[key]}"`
          );
        }
      }

      return creates;
    },

    // -- Description:
    // Returns an array describing the update of a universal/miscellaneous feature in a token.
    // -- Parameters:
    // prev - Object with keys (name of the feature) and values (value of the feature) before
    //        the change was made
    // curr - Object with keys (name of the feature) and values (value of the feature) after
    //        the change was made
    // featureName - Name of the type of feature to be analyzed. It's either 'miscellaneous
    //               feature' or 'universal feature'
    // tokenName - Name of the token to which the removed feature is from.
    // -- Returns:
    // updates - List of strings describing the updates
    detectUpdateFeature(prev, curr, featureName, tokenName) {
      let updates = [];

      for (const key in curr) {
        if (key in prev && curr[key] !== prev[key]) {
          updates.push(
            `Updated the following ${featureName} of ${tokenName}: "${key}" is now "${curr[key]}"`
          );
        }
      }

      return updates;
    },

    // -- Description:
    // Applies the previous the three abore function in a token.
    // -- Parameters:
    // prev - Object with keys (name of the feature) and values (value of the feature) before
    //        the change was made
    // curr - Object with keys (name of the feature) and values (value of the feature) after
    //        the change was made
    // featureName - Name of the type of feature to be analyzed. It's either 'miscellaneous
    //               feature' or 'universal feature'
    // tokenName - Name of the token to which the removed feature is from.
    // -- Returns:
    // changes - List of strings describing the changes
    detectChangesFeature(prev, curr, featureName, tokenName) {
      let changes = [];

      changes.push(
        ...this.detectRemoveFeature(prev, curr, featureName, tokenName)
      );
      changes.push(
        ...this.detectCreateFeature(prev, curr, featureName, tokenName)
      );
      changes.push(
        ...this.detectUpdateFeature(prev, curr, featureName, tokenName)
      );

      return changes;
    },

    // -- Description:
    // Detect changes in a token.
    // -- Parameters:
    // prevToken - Object representing the previous state of the token (before the changes).
    // token - Object representing the current state of the token (after the changes).
    // sentenceJson - Ordered array of objects representing the tokens of a sequence.
    // -- Returns:
    // changes - List of strings describing the changes
    detectChangesToken(prevToken, token, sentenceJson) {
      let changes = [];
      // define the token and it's head's name followed by the id (between parenthesis)
      const tokenName = `"${token.FORM}" (${token.ID})`;

      // --- DETECTING CHANGES THAT ARE RELATED TO DEPENDENCY RELATIONS ---
      // detects if a dependency relation was removed
      if (
        (token.HEAD === null || isNaN(token.HEAD)) &&
        prevToken.HEAD !== null &&
        !isNaN(prevToken.HEAD)
      ) {
        // a dependency relation was removed

        if (prevToken.HEAD !== 0) {
          changes.push(
            `Removed the "${sentenceJson.treeJson[prevToken.HEAD].FORM}" (${
              sentenceJson.treeJson[prevToken.HEAD].ID
            }) ---> "${prevToken.FORM}" (${prevToken.ID}) dependency relation`
          );
        } else {
          changes.push(
            `Removed the ROOT (0) ---> "${prevToken.FORM}" (${prevToken.ID}) dependency relation`
          );
        }
      } else if (
        (token.HEAD !== null && !isNaN(token.HEAD)) ||
        (prevToken.HEAD !== null && !isNaN(prevToken.HEAD))
      ) {
        let headName;

        if (token.HEAD === 0) {
          headName = "ROOT (0)";
        } else {
          headName = `"${sentenceJson.treeJson[token.HEAD].FORM}" (${
            sentenceJson.treeJson[token.HEAD].ID
          })`;
        }

        // detects changes in the head of a token and changes of the label of
        // a dependecy relation
        if (token.HEAD !== prevToken.HEAD) {
          changes.push(`Defined ${headName} as the head of ${tokenName}`);
          changes.push(
            `Defined "${token.DEPREL}" as the dependency relation of ${headName} ---> ${tokenName}`
          );
        } else if (token.DEPREL !== prevToken.DEPREL) {
          changes.push(
            `Defined "${token.DEPREL}" as the dependency relation of ${headName} ---> ${tokenName}`
          );
        }
      }

      // --- DETECTING CHANGES THAT AREN'T RELATED TO DEPENDENCY RELATIONS ---
      // detects changes in the part of speech of a token
      if (token.UPOS !== prevToken.UPOS) {
        changes.push(
          `Defined the part of speech of ${tokenName} as "${token.UPOS}"`
        );
      }

      // detects changes in the lemma of a token
      if (token.LEMMA !== prevToken.LEMMA) {
        changes.push(`Defined the lemma of ${tokenName} as "${token.LEMMA}"`);
      }

      // detects changes in the universal features
      changes.push(
        ...this.detectChangesFeature(
          prevToken.FEATS,
          token.FEATS,
          "universal feature",
          tokenName
        )
      );

      // detects changes in the miscellaneous features
      changes.push(
        ...this.detectChangesFeature(
          prevToken.MISC,
          token.MISC,
          "miscellaneous feature",
          tokenName
        )
      );

      return changes;
    },

    svgClickHandler(e) {
      const clickedId = e.detail.clicked;
      const clickedToken = this.sentenceSVG.treeJson[clickedId];
      const targetLabel = e.detail.targetLabel;

      if (targetLabel == "DEPREL") {
        const dep = clickedToken;
        const gov = this.sentenceSVG.treeJson[dep.HEAD] || {
          FORM: "ROOT",
          ID: 0,
        }; // handle if head is root
        this.sentenceBus.$emit("open:relationDialog", {
          gov,
          dep,
          userId: this.userId,
        });
      } else if (
        targetLabel == "FORM" ||
        ["MISC.", "FEATS", "LEMMA"].includes(targetLabel.slice(0, 5))
      ) {
        this.sentenceBus.$emit(`open:featuresDialog`, {
          token: clickedToken,
          userId: this.userId,
        });
      } else {
        // when the user clicks in a part of speech tag, he has a choice
        // 1 - he can do it while pressing a modifier key
        // 2 - he can do it without pressing a modifier key
        // the modifier key is pressed when the use wants to group
        // tags of various tokens in order to change them all at once
        // later

        // get's a boolean indicating if the user pressed the modifier
        const isModifierPressed = e.detail.event.ctrlKey;

        if (isModifierPressed) {
          // clicks without the modifier

          // gets the id of the token clicked
          const clickedTokenID = clickedToken.ID;

          // only adds the token to the group if it already
          // isn't a part of it
          if (!this.reactiveSentence.groupedTokens.includes(clickedTokenID)) {
            // redefines the most recent token as the one clicked
            this.reactiveSentence.prevIdOfMostRecentToken =
              this.reactiveSentence.idOfMostRecentToken;
            this.reactiveSentence.idOfMostRecentToken = clickedTokenID;

            // add the token to the group
            this.reactiveSentence.groupedTokens.push(clickedTokenID);

            // highlights the new member of the group
            this.sentenceSVG.updateHighlighted();
          }
        } else {
          // clicks without the modifier

          // opens the part of speech tag change window
          this.sentenceBus.$emit(`open:${targetLabel.toLowerCase()}Dialog`, {
            token: clickedToken,
            userId: this.userId,
          });
        }
      }
    },

    svgDropHandler(e) {
      const draggedId = e.detail.dragged;
      const hoveredId = e.detail.hovered;

      var gov = {};
      var dep = {};
      // if the area being hovered is the root (circle on top of the svg), assign the gov object to root
      if (e.detail.isRoot) {
        gov = { ID: 0, FORM: "ROOT" };
        dep = this.sentenceSVG.treeJson[draggedId];
      } else {
        gov = this.sentenceSVG.treeJson[draggedId];
        dep = this.sentenceSVG.treeJson[hoveredId];
      }

      // emit only if dep is defined. If the token is being dragged on nothing, nothing will happen
      if (dep) {
        this.sentenceBus.$emit("open:relationDialog", {
          gov,
          dep,
          userId: this.userId,
        });
      }
    },
    /**
     * Update the undo, redo and save status each time user makes changes.
     */
    statusChangeHadler() {
      const canUndo = this.history_index != -1;
      const canRedo = this.history_index != this.history_end;
      const needSave = this.history_saveIndex != this.history_index;
      const status_str = LocalStorage.getItem("save_status");
      let status_obj = status_str ? JSON.parse(status_str) : {};
      let card = status_obj[this.cardId];
      this.hasPendingChanges[this.userId] = needSave;
      this.$emit("statusChanged", {
        canUndo: canUndo,
        canRedo: canRedo,
        canSave: needSave,
        userId: this.userId,
      });
      if (!card) card = {};
      card[this.userId] = needSave;
      status_obj[this.cardId] = card;
      LocalStorage.set("save_status", JSON.stringify(status_obj));
      this.checkSaveStatus();
    },
    checkSaveStatus() {
      const status_str = LocalStorage.getItem("save_status");
      const status_obj = JSON.parse(status_str);
      const card_keys = Object.keys(status_obj);
      for (let i in card_keys) {
        const card = status_obj[card_keys[i]];
        const userIds = Object.keys(card);
        for (let j in userIds) {
          if (card[userIds[j]] == true) {
            window.onbeforeunload = function (e) {
              return `You have some unsaved changes left,
               please save them before you leave this page`;
            };
            return;
          }
        }
      }
      window.onbeforeunload = function (e) {
        delete e["returnValue"];
      };
    },
  },
};
</script>

<style>
* {
  --depLevelHeight: 30;
}

.focused {
  background-color: #f5f5f5 !important;
  border-radius: 5px;
}
</style>
