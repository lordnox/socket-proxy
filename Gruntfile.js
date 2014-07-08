var project = {
  server: {}
}

var Path = require('path');

module.exports = function(grunt) {

  require('matchdep').filterDev('grunt-*').forEach(function(dep) {
    grunt.log.ok(dep);
    grunt.loadNpmTasks(dep);
  });

  grunt.initConfig({

    connect: {
      options: {
        base: 'app/'
      },
      webserver: {
        options: {
          port: project.server.devPort,
          keepalive: true
        }
      },
      devserver: {
        options: {
          port: project.server.devPort
        }
      },
      testserver: {
        options: {
          port: project.server.testPort
        }
      },
      coverage: {
        options: {
          base: 'coverage/',
          port: project.server.coveragePort,
          keepalive: true
        }
      }
    },

    clean: {
      build: project.buildpath,
      templates: project.templatesPath
    },

    copy: {
      build: {
        files: [
        {
          expand: true,
          cwd: project.appbase,
          src: [
          '**',
//          '!' + Path.join(project.assetspath, '**'),
          '**/*.html'
          ],
//          dest: Path.join(project.buildpath, project.client),
        },
        ]
      }
    },

    'gh-pages': {
      options: {
//        base: Path.join(project.buildpath, project.client)
      },
      src: ['**']
    },

    jasmine_node: {
      projectRoot: "./tests",
      matchall: true,
      useCoffee: true,
      specNameMatcher: '',
      autotest: true,
      extensions: ['coffee', 'js', 'json'].join('|')
    },

    karma: {
      unit: {
        configFile: './test/karma-unit.conf.js',
        autoWatch: false,
        singleRun: true
      },
      unit_auto: {
        configFile: './test/karma-unit.conf.js'
      },
      midway: {
        configFile: './test/karma-midway.conf.js',
        autoWatch: false,
        singleRun: true
      },
      midway_auto: {
        configFile: './test/karma-midway.conf.js'
      },
      e2e: {
        configFile: './test/karma-e2e.conf.js',
        autoWatch: false,
        singleRun: true
      },
      e2e_auto: {
        configFile: './test/karma-e2e.conf.js'
      }
    },

    open: {
      devserver: {
        path: 'http://localhost:' + project.server.devPort
      },
      coverage: {
        path: 'http://localhost:' + project.server.coveragePort
      }
    },

    shell: {
      options : {
        stdout: true
      },
      npm_install: {
        command: 'npm install'
      },
      bower_install: {
        command: './node_modules/.bin/bower install'
      },
      font_awesome_fonts: {
        command: 'cp -R bower_components/components-font-awesome/font app'
      }
    },

    watch: {
      assets: {
        files: ['app/styles/**/*.css','app/scripts/**'],
        tasks: ['module-templates', 'concat']
      },
      test: {
        files: ['tests/**', 'src/**'],
        tasks: ['test:unit']
      }
    },

    simplemocha: {
      options: {
        globals: ['should', 'mock'],
        timeout: 500,
        ignoreLeaks: false,
        grep: '*-test',
        ui: 'bdd',
        reporter: 'spec'
      },

      test: {
        src: ['tests/unit/*.coffee']
      }
    }
  });

  grunt.registerTask('test',        ['test:unit']);
  grunt.registerTask('test:unit',   ['simplemocha:test']);

  grunt.registerTask('autotest',        ['autotest:unit']);
  grunt.registerTask('autotest:unit',   ['test:unit', 'watch:test']);

  grunt.loadNpmTasks('grunt-contrib-jshint');

  grunt.registerTask('default', ['jshint' ,'test']);

/*
  grunt.registerTask('kx-preprocess:dev', function() {
    process.env.TASK = 'preprocess-dev';

    var base, files;


    base = "app/";
    files = grunt.file.expand(bowerFiles.concat(jsFiles)).map(function(v) {
      return "        <script src='" + v.substr(base.length) + "'></script>";
    });

    process.env.script_tags = files.join("\n");
    base = "app/";
    files = grunt.file.expand(cssFiles).map(function(v) {
      return "    <link rel=\"stylesheet\" type=\"text/css\" href=\"" + v.substr(base.length) + "\"/>";
    });
    process.env.style_tags = files.join("\n");

    grunt.task.run('preprocess:dev');
  });
  grunt.registerTask('kx-preprocess:prod', function() {
    var task = {
      "appjs_hash": 'dist/assets/app.*.js',
      "vendorjs_hash": 'dist/assets/vendor.*.js',
      "appcss_hash": 'dist/assets/app.*.css'
    };
    var file;
    Object.keys(task).forEach(function(v) {
      file = grunt.file.expand(task[v])[0];
      process.env[v] = Path.basename(file);
    });
    process.env.TASK = 'preprocess-prod';
    grunt.task.run('preprocess:prod');
  });
/***/
};
