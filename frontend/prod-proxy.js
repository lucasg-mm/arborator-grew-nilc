const source = "https://backend:5000";
const prodSource = "arborator.icmc.usp.br";

module.exports = [
  {
    path: "/api",
    rule: {
      target: source,
      ws: true,
      changeOrigin: false,
      secure: false,
      headers: { host: prodSource },
    },
  },
  {
    path: "/login",
    rule: {
      target: source,
      ws: true,
      changeOrigin: false,
      secure: false,
      headers: { host: prodSource },
    },
  },
  {
    path: "/logout",
    rule: {
      target: source,
      ws: true,
      changeOrigin: false,
      secure: false,
      headers: { host: prodSource },
    },
  },
];
