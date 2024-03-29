<template>
  <q-page :class="$q.dark.isActive ? 'bg-dark' : 'bg-grey-1'">
    <div class="q-pa-md row items-start q-gutter-md flex flex-center">
      <q-card flat>
        <q-card-section class="q-pa-md row items-start q-gutter-md">
          <q-toolbar class="text-center">
            <q-btn
              :disable="!isLoggedIn"
              id="createproject"
              color="primary"
              round
              dense
              icon="add"
              @click="creaProjectDial = true"
            >
              <q-tooltip :delay="300" content-class="text-white bg-primary">{{
                $t("projectHub").tooltipCreaProject
              }}</q-tooltip>
            </q-btn>
            <q-toolbar-title
              :class="($q.dark.isActive ? '' : 'text-primary') + ' text-bold'"
            >
              {{ $t("projectHub").title }}
            </q-toolbar-title>
            <q-btn
              flat
              round
              dense
              :icon="listMode ? 'view_module' : 'list'"
              @click="toggleProjectView()"
            >
              <q-tooltip :delay="300" content-class="text-white bg-primary">{{
                $t("projectHub").tooltipChangeView
              }}</q-tooltip>
            </q-btn>
          </q-toolbar>
          <q-toolbar class="text-center">
            <q-toolbar-title>
              <!-- <span :class="($q.dark.isActive?'':'text-primary') + ' text-bold'">Projects</span> -->
              <q-input
                filled
                bottom-slots
                v-model="search"
                label="Search Project"
                type="text"
                @input="searchProject(search)"
                @keyup.enter="searchProject(search)"
              >
                <template v-slot:append>
                  <q-icon name="search" />
                </template>
              </q-input>
            </q-toolbar-title>
          </q-toolbar>
        </q-card-section>
        <q-card-section
          v-if="initLoading"
          class="row q-pa-md items-start q-gutter-md"
          style="width: 90vw; height: 60vh"
        >
          <q-card
            style="max-width: 250px; width: 250px"
            v-for="i in skelNumber"
            :key="i"
          >
            <q-skeleton height="150px" square />
            <q-item>
              <q-item-section>
                <q-item-label>
                  <q-skeleton type="text" />
                </q-item-label>
                <q-item-label caption>
                  <q-skeleton type="text" />
                </q-item-label>
              </q-item-section>
            </q-item>
          </q-card>
        </q-card-section>
        <q-card-section v-if="!listMode" style="width: 90vw; height: 60vh">
          <q-virtual-scroll
            v-if="$q.platform.is.mobile"
            :items="visibleProjects"
            style="max-height: 60vh; width: 80vw"
            :virtual-scroll-slice-size="30"
            :virtual-scroll-item-size="200"
          >
            <template v-slot="{ item, index }">
              <ProjectCard
                style="max-width: 80vw"
                :props="item"
                :parentDeleteProject="deleteProject"
                :parentProjectSettings="showProjectSettings"
                :key="item.id"
              ></ProjectCard>
            </template>
          </q-virtual-scroll>
          <div
            v-if="!$q.platform.is.mobile"
            class="q-pa-md row items-start q-gutter-md"
          >
            <div class="text-h6 col-12" v-if="isLoggedIn && myProjects.length">
              <q-chip color="primary" class="category" text-color="white">
                My projects
              </q-chip>
            </div>
            <ProjectCard
              style="max-width: 250px"
              v-for="project in myProjects"
              :props="project"
              :parentDeleteProject="deleteProject"
              :parentProjectSettings="showProjectSettings"
              :key="project.id"
            ></ProjectCard>
            <div
              class="text-h6 col-12"
              v-if="isLoggedIn && otherProjects.length"
            >
              <q-chip color="primary" class="category" text-color="white">
                Other projects
              </q-chip>
            </div>
            <ProjectCard
              style="max-width: 250px"
              v-for="project in otherProjects"
              :props="project"
              :parentDeleteProject="deleteProject"
              :parentProjectSettings="showProjectSettings"
              :key="project.id"
            ></ProjectCard>
          </div>
        </q-card-section>
        <q-card-section v-if="listMode" style="width: 90vw; height: 60vh">
          <q-list style="width: 100%" bordered>
            <q-virtual-scroll
              :items="visibleProjects"
              style="max-height: 60vh; width: 100%"
              :virtual-scroll-slice-size="30"
              :virtual-scroll-item-size="200"
            >
              <template v-slot="{ item, index }">
                <ProjectItem
                  :props="item"
                  :parentDeleteProject="deleteProject"
                  :parentProjectSettings="showProjectSettings"
                  :key="item.id"
                ></ProjectItem>
              </template>
            </q-virtual-scroll>
          </q-list>
        </q-card-section>
      </q-card>
    </div>

    <q-dialog
      v-model="creaProjectDial"
      transition-show="fade"
      transition-hide="fade"
    >
      <CreaProjectCard :parentGetProjects="getProjects"></CreaProjectCard>
    </q-dialog>

    <q-dialog
      v-model="projectSettingsDial"
      transition-show="slide-up"
      transition-hide="slide-down"
    >
      <ProjectSettingsView
        :projectname="projectnameTarget"
        style="width: 90vw"
      ></ProjectSettingsView>
    </q-dialog>

    <q-dialog v-model="confirmActionDial">
      <confirm-action
        :parentAction="confirmActionCallback"
        :arg1="confirmActionArg1"
      ></confirm-action>
    </q-dialog>
  </q-page>
</template>

<style scoped lang="stylus">
.clickable:hover {
  cursor: pointer;
}

.grid-style-transition {
  transition: transform 0.28s, background-color 0.28s;
}

.category {
  width: fit-content;
  padding: 2px 11px;
  font-size: 18px;
}
</style>

<script>
import { openURL } from "quasar";
import api from "../boot/backend-api";
import Store from "../store/index";
import ProjectCard from "../components/ProjectCard.vue";
import ProjectItem from "../components/ProjectItem.vue";
import CreaProjectCard from "../components/CreaProjectCard.vue";
import ProjectSettingsView from "../components/ProjectSettingsView.vue";
import ConfirmAction from "../components/ConfirmAction";

export default {
  components: {
    ProjectCard,
    ProjectItem,
    CreaProjectCard,
    ProjectSettingsView,
    ConfirmAction,
  },
  name: "ProjectHub",
  data() {
    return {
      lorem:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      projects: [],
      visibleProjects: [],
      projectDifference: false,
      hover: false,
      search: "",
      listMode: true,
      creaProjectDial: false,
      projectSettingsDial: false,
      projectnameTarget: "",
      initLoading: false,
      loadingProjects: true,
      skelNumber: [...Array(5).keys()],
      confirmActionDial: false,
      confirmActionCallback: null,
      confirmActionArg1: "",
    };
  },
  mounted() {
    this.initLoading = true;
    this.listMode = this.$ls.get("project_view", false);
    this.getProjects();
  },
  computed: {
    isLoggedIn() {
      return this.$store.getters["user/isLoggedIn"];
    },
    myProjects() {
      return this.visibleProjects.filter((project) =>
        this.isCreatedByMe(project)
      );
    },
    otherProjects() {
      return this.visibleProjects.filter(
        (project) => !this.isCreatedByMe(project)
      );
    },
    avatar() {
      return this.$store.getters["user/getUserInfos"].picture_url;
    },
  },
  methods: {
    openURL,
    getProjects() {
      this.loadingProjects = true;
      api
        .getProjects()
        .then((response) => {
          this.projects = response.data;
          this.visibleProjects = response.data;
          this.sortProjects();
          // this.projectDifference = response.data.difference;
          this.loadingProjects = false;
          this.initLoading = false;
          // }
        })
        .catch((error) => {
          this.$store.dispatch("notifyError", { error: error });
          this.loadingProjects = false;
        });
    },
    searchProject(pattern) {
      var filteredProjects = this.projects.filter(function (project) {
        if (
          project.project_name.toLowerCase().includes(pattern.toLowerCase())
        ) {
          return project;
        }
      });
      this.visibleProjects = filteredProjects;
    },
    sortProjects() {
      if (!this.isLoggedIn) return;
      this.visibleProjects.sort((a, b) => {
        const my_a = this.isCreatedByMe(a);
        const my_b = this.isCreatedByMe(b);
        if (my_a && my_b) return 0;
        if (my_a) return -1;
        return 1;
      });
    },
    isCreatedByMe(project) {
      const user_id = this.$store.getters["user/getUserInfos"].id;
      return project.admins[0] == user_id;
    },
    toggleProjectView() {
      this.listMode = !this.listMode;
      this.$ls.set("project_view", this.listMode);
    },
    showProjectSettings(projectName) {
      this.projectnameTarget = projectName;
      this.projectSettingsDial = true;
    },
    deleteProject(projectName) {
      api
        .deleteProject(projectName)
        .then((response) => {
          this.$q.notify({ message: `Project ${projectName} deleted` });
          this.getProjects();
        })
        .catch((error) => {
          this.$store.dispatch("notifyError", { error: error });
        });
    },
    triggerConfirm(method, arg) {
      this.confirmActionDial = true;
      this.confirmActionCallback = method;
      this.confirmActionArg1 = arg;
    },
  },
};
</script>
