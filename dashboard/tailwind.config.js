/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        liberation: {
          50: '#f0f9f9',
          100: '#ccecec',
          200: '#99d9d9',
          300: '#66c6c6',
          400: '#33b3b3',
          500: '#00a0a0',
          600: '#008080',
          700: '#006060',
          800: '#004040',
          900: '#002020',
        }
      }
    },
  },
  plugins: [],
}