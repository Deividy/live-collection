module.exports = function(config) {
    config.set({
        basePath: '../',

        frameworks: ['mocha'],

        files: [
            'node_modules/underscore/underscore.js',
            'node_modules/backbone/backbone.js',
            'node_modules/functoids/functoids.js',
            'node_modules/should/should.js',
            'node_modules/jquery/dist/jquery.js',

            'live-collection.js',
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

        exclude: [ ],
        
        // possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
        reporters: ['progress'],

        port: 9876,
        colors: true,
        logLevel: config.LOG_INFO,
        autoWatch: false,
        
        browsers: ['Firefox', 'PhantomJS'],

        captureTimeout: 60000,
        singleRun: true
    });
};
