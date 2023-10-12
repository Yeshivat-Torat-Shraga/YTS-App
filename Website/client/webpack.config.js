export const plugins = [
  new webpack.DefinePlugin({
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    'process.env.REACT_APP_FIREBASE_APPCHECK_TOKEN': JSON.stringify(process.env.REACT_APP_FIREBASE_APPCHECK_TOKEN),
    // ...
  }),
];