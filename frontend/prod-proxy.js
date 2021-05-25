const source = "https://backend:5000";

module.exports = [
  {
    path: "/api",
    rule: { target: source, ws: true, changeOrigin: false, secure: false },
  },
  {
    path: "/login",
    rule: { target: source, ws: true, changeOrigin: false, secure: false },
  },
  {
    path: "/logout",
    rule: { target: source, ws: true, changeOrigin: false, secure: false },
  },
  {
    path: "/media",
    rule: { target: source, ws: true, changeOrigin: false, secure: false },
  },
];
