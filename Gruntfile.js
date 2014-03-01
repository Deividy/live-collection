module.exports = function (grunt) {
    grunt.initConfig({
        coffee: {
            compile: {
                options: {
                    join: true
                },
                files: {
                    'live-collection.js': [ 'src/*.coffee' ]
                }
            }
        },
        uglify: {
            prod: {
                files: {
                    'live-collection.min.js': [ 'live-collection.js' ]
                }
            }
        },
        karma: {
            unit: {
                configFile: 'karma.conf.js'
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-karma');

    grunt.registerTask('default', [ 'coffee:compile', 'uglify:prod', 'karma:unit' ]);
    grunt.registerTask('test', [ 'coffee:compile', 'karma:unit' ]);
};
