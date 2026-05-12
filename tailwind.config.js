// import the tailwind.config.js file in your main CSS file if using Tailwind CSS v4
module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',     // Scans views
    './app/helpers/**/*.rb',                     // Scans helpers
    './app/components/**/*.{rb,html}',           // ViewComponents
    './app/javascript/**/*.js'                   // JS files
  ],
  theme: {
    // ...
  },
  plugins: [
    require('flowbite-typography'),
    // ...
  ],
}
