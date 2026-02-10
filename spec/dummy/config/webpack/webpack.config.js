// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const path = require("path");
const { generateWebpackConfig } = require("shakapacker");

const webpackConfig = generateWebpackConfig();

webpackConfig.resolve = webpackConfig.resolve || {};
webpackConfig.resolve.alias = {
  ...(webpackConfig.resolve.alias || {}),
  react: path.resolve(__dirname, "../../node_modules/react"),
  "react-dom": path.resolve(__dirname, "../../node_modules/react-dom"),
  "react-native$": "react-native-web",
  "react-native-vector-icons/FontAwesome": path.resolve(__dirname, "../../app/javascript/src/shims/font-awesome.jsx")
};
webpackConfig.resolve.extensions = [
  ".jsx",
  ".js",
  ...(webpackConfig.resolve.extensions || [])
];
webpackConfig.module = webpackConfig.module || {};
webpackConfig.module.rules = [
  ...(webpackConfig.module.rules || []),
  {
    test: /\.m?js$/,
    resolve: {
      fullySpecified: false
    }
  }
];

module.exports = webpackConfig;
