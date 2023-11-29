module.exports = {
  root: true,
  // env: {
  //   es6: true,
  //   node: true,
  // },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: "CloudFunctions/functions/tsconfig.json",

    // sourceType: "module",
  },
  plugins: [
    "@typescript-eslint"
  ],

  ignorePatterns: [
    "lib/**/*", // Ignore built files.
    ".eslintrc.js",
  ],
  // extends: [
  //   // "eslint:recommended",
  //   "google",
  // ],
  // rules: {
  //   "quotes": ["error", "double"],
  //   "arrow-body-style": ["error", "always"],
  //   "max-len": 0,
  //   "indent": 0,
  //   "noTab": 0,
  // },
};
