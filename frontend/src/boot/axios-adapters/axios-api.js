import axios from "axios";
export const API = axios.create({
  // baseURL: 'https://arboratorgrew.elizia.net/api',
  // baseURL: `/api`,
  baseURL: process.env.DEV ? "/api" : process.env.APP_URL + "/api",
  timeout: 50000,
  withCredentials: true,
});

export const ROOT_API = axios.create({
  // baseURL: 'https://arboratorgrew.elizia.net/api',
  // baseURL: `/api`,
  baseURL: process.env.APP_URL,
  timeout: 50000,
  withCredentials: true,
});
