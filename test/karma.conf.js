// Karma configuration
// Generated on Fri Feb 28 2014 18:38:11 GMT-0300 (BRT)

module.exports = function(config) {
	config.set({
		// base path, that will be used to resolve files and exclude
		basePath: '../',


		// frameworks to use
		frameworks: ['mocha'],

		// list of files / patterns to load in the browser
		files: [
			'node_modules/underscore/underscore.js',
			'node_modules/backbone/backbone.js',
			'node_modules/functoids/functoids.js',
			'live-collection.js',

			'node_modules/should/should.js',
			'test/specs/*.spec.*'
		],


		preprocessors: {
			'test/specs/*.spec.coffee': [ 'coffee' ]
		},

		coffeePreprocessor: {
			options: {
				bare: true,
				sourceMap: false
			},
			transformPath: function (path) {
				return path.replace(/\.coffee$/, '.js');
			}
		},

		// list of files to exclude
		exclude: [
			
		],


		// test results reporter to use
		// possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
		reporters: ['progress'],


		// web server port
		port: 9876,


		// enable / disable colors in the output (reporters and logs)
		colors: true,


		// level of logging
		// possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
		logLevel: config.LOG_INFO,


		// enable / disable watching file and executing tests whenever any file changes
		autoWatch: false,


		// Start these browsers, currently available:
		// - Chrome
		// - ChromeCanary
		// - Firefox
		// - Opera (has to be installed with `npm install karma-opera-launcher`)
		// - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
		// - PhantomJS
		// - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
		browsers: ['Firefox'],


		// If browser does not capture in given timeout [ms], kill it
		captureTimeout: 60000,


		// Continuous Integration mode
		// if true, it capture browsers, run tests and exit
		singleRun: true
	});
};
