<template>
  <q-card>
    <q-bar class="bg-primary text-white">
      <q-space />
      <div class="text-weight-bold">Are you sure?</div>
      <q-space />
      <q-btn flat dense icon="close" v-close-popup />
    </q-bar>
    <q-card-section>
      Do you really want to leave? You have unsaved changes!
    </q-card-section>
    <q-card-actions align="around">
      <q-btn
        flat
        label="Cancel"
        v-close-popup
        @click="parentAction('cancel')"
      ></q-btn>
      <q-btn
        flat
        label="Leave without saving"
        v-close-popup
        @click="parentAction('dont-save')"
      ></q-btn>
      <q-btn
        @keyup.enter="parentAction('save-all')"
        @click="parentAction('save-all')"
        color="primary"
        label="Save all and leave"
        v-close-popup
      ></q-btn>
    </q-card-actions>
  </q-card>
</template>

<script>
export default {
  name: "confirm-action",
  props: ["parentAction", "arg1"],
  data() {
    return {};
  },
  methods: {},
};
</script>
