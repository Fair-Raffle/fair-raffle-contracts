module.exports = {
	mode: 'jit',
	content: ['./src/**/*.{html,jsx}'],
	theme: {
		extend: {
			fontFamily: {
        'bebas': ['Bebas Neue', 'sans-serif'],
        'bourgeois': ['Bourgeois Rounded', 'sans-serif'],
      },
      boxShadow: {
        'step': '16px 1px 92px 10px rgba(46,51,87, 0.5) inset, 0px 2px 11px 3px rgba(1,2,12, 0.468531)',
        'step-hover': '16px 1px 92px 10px rgba(46,51,87, 0.5) inset, 0px 2px 11px 3px rgba(95,109,255, 0.468531)',
        'step-head': '0px 1px 5px 1px rgba(66,99,206, 0.5) inset'
      },
      backgroundImage: {
        'step': 'linear-gradient(90deg, rgba(26, 28, 42, 1) 0%, rgba(11, 12, 17, 1) 100%)',
        'step-head': 'radial-gradient(rgba(17, 20, 43, 1) 0%, rgba(9, 11, 23, 1) 100%)',
      },
		},
	},
	plugins: [],
}