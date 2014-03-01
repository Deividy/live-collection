var src = __dirname + "/src",
    source = [ 'wrapper', 'model', 'collection', 'render' ]

var files = [ ];

for (n = 0; n < source.length; n++) {
    files.push(src + "/" + source[n] + ".coffee");
}

module.exports = function (grunt) {
    grunt.initConfig({
        coffee: {
            compile: {
                options: {
                    join: true
                },
                files: {
                    'live-collection.js': files
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

    grunt.registerTask('default', [ 'coffee:compile', 'uglify:prod' ]);
    grunt.registerTask('test', [ 'coffee:compile', 'karma:unit' ]);
};
