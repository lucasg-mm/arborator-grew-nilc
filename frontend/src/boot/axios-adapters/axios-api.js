import axios from "axios";
import urls from "../../../urls";

export const API = axios.create({
  baseURL:
    process.env.DEV_MODE === "1" ? urls.devUrl + "/api" : urls.prodUrl + "/api",
  timeout: 50000,
  withCredentials: true,
});

export const ROOT_API = axios.create({
  baseURL: process.env.DEV_MODE === "1" ? urls.devUrl : urls.prodUrl,
  timeout: 50000,
  withCredentials: true,
});
